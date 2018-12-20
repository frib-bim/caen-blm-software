/* Time based buffering.
 *
 * Think compressRecord which also stores severity and timestamp along with each value.
 *
 * Supports extraction of the whole fifo as a waveform,
 * or scalar values derived from the fifo (mean, min, ...)
 *
 * Supports decimation by absolute time, to allow sync. of several different
 * devices.
 * Track absolute timestamp modulo some period (eg. 1 second).  Push update
 * when phase rolls over.
 */

#include <stdio.h>

#include <limits>
#include <vector>
#include <map>
#include <string>
#include <stdexcept>
#include <complex>

#include <cmath>

#include <dbAccess.h>
#include <dbScan.h>
#include <dbStaticLib.h>
#include <epicsTime.h>
#include <devSup.h>
#include <drvSup.h>
#include <recGbl.h>
#include <alarm.h>
#include <errlog.h>
#include <epicsMutex.h>
#include <epicsGuard.h>
#include <menuOmsl.h>
#include <menuFtype.h>

#include <mbboRecord.h>
#include <longoutRecord.h>
#include <longinRecord.h>
#include <aoRecord.h>
#include <aiRecord.h>
#include <waveformRecord.h>
#include <epicsExport.h>

#ifndef M_PI
# define M_PI       3.14159265358979323846
#endif

namespace {

static DBLINK* get_dev_link(dbCommon *prec)
{
    DBLINK *ret = NULL;
    DBENTRY ent;

    dbInitEntry(pdbbase, &ent);

    dbFindRecord(&ent, prec->name);
    assert(ent.precnode->precord==(void*)prec);

    if(dbFindField(&ent, "INP") && dbFindField(&ent, "OUT")) {
        fprintf(stderr, "%s: can't find dev link\n", prec->name);
    } else {
        ret = (DBLINK*)((char*)prec + ent.pflddes->offset);
    }

    dbFinishEntry(&ent);
    return ret;
}

typedef epicsGuard<epicsMutex> Guard;
typedef epicsGuardRelease<epicsMutex> UnGuard;

enum reduce_t {
    First,          // FIFO
    Average,
    Stdev,
    Min,
    Max,
    WeightedAvg,
    WeightedStd,
    SpecialAvg,
    MaskedAvg,
    MaskedStd,
    AveragePhase,   // For BPM Phase
    All,            // All values are != 0
    Any,            // At least one value is != 0
};

struct timebuf {
    timebuf(const std::string& n)
        :name(n)
        ,maxsamples(100)
        ,period(1.0)
        ,values(maxsamples)
        ,weights(maxsamples)
        ,times(maxsamples)
        ,severities(maxsamples)
    {
        scanIoInit(&scan);
        reset();
    }

    void reset() {
        pos = cnt = 0;
        lastphase = 0.0;
    }

    inline size_t size() const { return values.size(); }

    inline bool empty() const { return cnt==0; }

    // index of first populated element (assumes empty()==false)
    size_t first() const {
        if(pos>=cnt)
            return pos-cnt;
        else
            return pos+values.size()-cnt;
    }

    // index of last populated element (assumes empty()==false)
    size_t last() const {
        if(pos==0)
            return values.size()-1;
        else
            return pos-1;
    }

    // index of the n'th element
    size_t idx(size_t n) {
        return (first() + n) % size();
    }

    // index of next element to be populated
    inline size_t next() const { return pos; }

    const std::string name;

    mutable epicsMutex lock;

    // config
    size_t maxsamples;
    double period;

    std::vector<double> values;
    std::vector<double> weights;
    std::vector<epicsTimeStamp> times;
    std::vector<short> severities;

    IOSCANPVT scan;

    size_t pos, // next sample to be written
           cnt; // number of valid samples stored

    double lastphase;
};

struct timedev {
    timedev(): tb(0), reduce(First) {}
    timebuf *tb;
    reduce_t reduce;
};

typedef std::map<std::string, timebuf*> timebufs_t;
timebufs_t timebufs;

static
long init_record_tbuf_common(dbCommon *prec, DBLINK *plink)
{
    timedev *dev = 0;
    try{
        assert(plink->type==INST_IO);

        dev = new timedev;

        std::string name;
        {
            std::string fulllink(plink->value.instio.string);

            size_t a = fulllink.find_first_not_of(" \t"),
                   b = fulllink.find_first_of(" \t", a);

            if(a==fulllink.npos)
                throw std::runtime_error("INP/OUT is blank");

            if(b==name.npos) {
                name = fulllink.substr(a);
            } else {
                name = fulllink.substr(a, b-a);

                a = fulllink.find_first_not_of(" \t", b);
                if(a!=fulllink.npos) {
                    std::string reduce(fulllink.substr(a));

                    if     (reduce=="First")        dev->reduce = First;
                    else if(reduce=="Average")      dev->reduce = Average;
                    else if(reduce=="Stdev")        dev->reduce = Stdev;
                    else if(reduce=="Min")          dev->reduce = Min;
                    else if(reduce=="Max")          dev->reduce = Max;
                    else if(reduce=="WeightedAvg")  dev->reduce = WeightedAvg;
                    else if(reduce=="WeightedStd")  dev->reduce = WeightedStd;
                    else if(reduce=="SpecialAvg")   dev->reduce = SpecialAvg;
                    else if(reduce=="MaskedAvg")    dev->reduce = MaskedAvg;
                    else if(reduce=="MaskedStd")    dev->reduce = MaskedStd;
                    else if(reduce=="MeanPhase")    dev->reduce = AveragePhase;
                    else if(reduce=="All")          dev->reduce = All;
                    else if(reduce=="Any")          dev->reduce = Any;
                    else throw std::runtime_error("Unknown reduction mode "+reduce);
                }
            }

            if(name.empty())
                throw std::runtime_error("INP/OUT no name");
        }

        timebuf *pt;

        timebufs_t::const_iterator tbit = timebufs.find(name);
        if(tbit==timebufs.end()) {
            pt = new timebuf(name);
            timebufs[name] = pt;
        } else {
            pt = tbit->second;
        }

        dev->tb = pt;
        prec->dpvt = (void*)dev;

        return 0;
    } catch(std::exception& e) {
        fprintf(stderr, "%s: error %s\n", prec->name, e.what());
        delete dev;
        return -1;
    }
}

template<long retval, class REC>
long init_record_tbuf(REC *prec)
{
    long ret = init_record_tbuf_common((dbCommon*)prec,
                                       get_dev_link((dbCommon*)prec));
    return ret==0 ? retval : ret;
}

#define TRY timedev *tdev = (timedev*)prec->dpvt; \
            if(!tdev) return -1; \
            timebuf *tb = tdev->tb; \
            try

#define CATCH() catch(std::exception& e) { \
                    errlogPrintf("%s: error '%s'\n", prec->name, e.what()); \
                    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM); return S_db_Blocked; \
                }


long update_scan(int dir, dbCommon *prec, IOSCANPVT *pscan)
{
    TRY {
        *pscan = tb->scan;
        return 0;
    } CATCH()
}

long set_maxsamples(longoutRecord *prec)
{
    TRY {
        if(prec->udf || prec->val<=0) {
            (void)recGblSetSevr(prec, WRITE_ALARM, INVALID_ALARM);
            return S_db_errArg;
        }
        size_t newmax = prec->val;

        Guard G(tb->lock);

        tb->values.resize(newmax);
        tb->weights.resize(newmax);
        tb->severities.resize(newmax);
        tb->times.resize(newmax);

        tb->maxsamples = newmax;

        tb->reset();
        return 0;
    } CATCH()
}

long set_period(aoRecord *prec)
{
    TRY {
        if(prec->udf || !std::isfinite(prec->val)) {
            (void)recGblSetSevr(prec, WRITE_ALARM, INVALID_ALARM);
            return S_db_errArg;
        }

        Guard G(tb->lock);

        tb->period = prec->val;
        return 0;
    } CATCH()
}

long new_sample(aoRecord *prec)
{
    TRY {
        double newval = prec->val;
        epicsTimeStamp newtime;
        epicsEnum16 newsevr;
        double newweight = 1.0;

        // Abuse SIOL field
        if (prec->siol.type == CONSTANT)
            dbLoadLink(&prec->siol, DBR_DOUBLE, &newweight);
        else if (dbGetLink(&prec->siol, DBR_DOUBLE, &newweight, 0, 0)) {
            fprintf(stderr, "%s: failed to retrieve sample weight from SIOL field\n",
                    prec->name);
            recGblSetSevr(prec, LINK_ALARM, INVALID_ALARM);
            return 0;
        }

        if(prec->omsl==menuOmslclosed_loop &&
           prec->dol.type!=CONSTANT &&
           dbGetTimeStamp(&prec->dol, &newtime)==0 &&
           dbGetAlarm(&prec->dol, NULL, &newsevr)==0
        ) {
            // severity/time from DOL
        } else {
            // fall back to our severity (assume MS somehow arranged) and time (TSEL or TSE)
            newsevr = prec->nsev;
            recGblGetTimeStamp((void*)prec);
            newtime = prec->time;
        }

        bool notify = false;
        {
            Guard G(tb->lock);

            if(tb->cnt!=0) {
                double delta = epicsTimeDiffInSeconds(&newtime, &tb->times[tb->last()]);
                if (delta == 0.0) {
                    fprintf(stderr, "%s: repeated sample (diff=%f).\n",
                                 prec->name, delta);
                } else if (delta < 0) {
                    fprintf(stderr, "%s: non-monotonic time (diff=%f).  Clear buffer.\n",
                                 prec->name, delta);
                    tb->reset();
                }
            }

            tb->values[tb->pos]     = newval;
            tb->weights[tb->pos]    = newweight;
            tb->times[tb->pos]      = newtime;
            tb->severities[tb->pos] = newsevr;

            if(tb->cnt < tb->size())
                tb->cnt++;

            tb->pos = (tb->pos+1)%tb->size();

            if(tb->period > 0.0) {
                // Trigger update of outputs when phase rolls over (decimation mode)
                double newphase = fmod(newtime.secPastEpoch+newtime.nsec*1e-9, tb->period);

                notify = tb->cnt < 2 || newphase < tb->lastphase;
                tb->lastphase = newphase;
            } else {
                notify = true;
                tb->lastphase = 0.0;
            }
        }

        if(notify)
            scanIoRequest(tb->scan);

        return 0;
    } CATCH()
}

void get_severity(timebuf *tb, aiRecord *prec)
{
    short newsevr = 0;

    for (size_t p = 0; p < tb->cnt; ++p)
        newsevr = std::max(newsevr, tb->severities[tb->idx(p)]);

    if(newsevr)
        (void)recGblSetSevr(prec, READ_ALARM, newsevr);
}

void get_value_first(timebuf *tb, aiRecord *prec)
{
    size_t pos = tb->first();

    prec->val = tb->values[pos];
    if(tb->severities[pos])
        recGblSetSevr(prec, READ_ALARM, tb->severities[pos]);

    if(prec->tse==epicsTimeEventDeviceTime)
        prec->time = tb->times[pos];
}

void get_value_stat(timebuf *tb, aiRecord *prec, reduce_t reduce)
{
    assert(tb->cnt>0);

    double newval = 0.0;
    double totalweight = 0.0;

    // If all weights are zero, then we *are* interested in the noise during
    // TIME_ON=0
    size_t nonzeroweights = 0;

    for (size_t p = 0; p < tb->cnt; ++p)
        nonzeroweights += !!tb->weights[tb->idx(p)];

    bool allweightszero = !nonzeroweights;

    for (size_t p = 0; p < tb->cnt; ++p) {
        size_t pos = tb->idx(p);

        switch(reduce) {
        case Average:
        case Stdev:
            newval += tb->values[pos];
            break;
        case WeightedAvg:
        case WeightedStd:
            newval += tb->weights[pos]*tb->values[pos];
            totalweight += tb->weights[pos];
            break;
        case SpecialAvg:
        case MaskedAvg:
        case MaskedStd:
            if (tb->weights[pos] || allweightszero)
                newval += tb->values[pos];
            break;
        default:
            throw std::runtime_error("invalid reduce");
            break;
        }
    }

    if (reduce == Average || reduce == SpecialAvg)
        newval /= tb->cnt;

    if (reduce == MaskedAvg)
        newval /= allweightszero ? tb->cnt : nonzeroweights;

    if (reduce == WeightedAvg && totalweight != 0.0)
        newval /= totalweight;

    // For Standard deviation, start with average, then loop data again to calculate variance
    if(reduce == Stdev || reduce == WeightedStd || reduce == MaskedStd) {
        double meanval = newval;

        if (reduce == Stdev)
            meanval /= tb->cnt;
        else if(reduce == MaskedStd)
            meanval /= allweightszero ? tb->cnt : nonzeroweights;
        else if (totalweight)
            meanval /= totalweight;

        newval = 0.0;

        for (size_t p = 0; p < tb->cnt; ++p) {
            size_t pos = tb->idx(p);
            double diff = 0.0;

            if (reduce == WeightedStd)
                diff = tb->weights[pos]*tb->values[pos] - meanval;
            else if (reduce == Stdev || allweightszero || tb->weights[pos])
                diff = tb->values[pos] - meanval;

            newval += diff*diff;
        }

        // Convert from sum-of squares to std
        if (reduce == Stdev || reduce == MaskedStd)
            newval = sqrt(newval/tb->cnt);
        else if (totalweight)
            newval = sqrt(newval/totalweight);
    }

    prec->val = newval;
}

void get_value_min_max(timebuf *tb, aiRecord *prec, reduce_t reduce)
{
    double newval = tb->values[tb->first()];

    if (reduce == Min)
        for (size_t p = 1; p < tb->cnt; ++p)
            newval = std::min(newval, tb->values[tb->idx(p)]);
    else
        for (size_t p = 1; p < tb->cnt; ++p)
            newval = std::max(newval, tb->values[tb->idx(p)]);

   prec->val = newval;
}

void get_value_avg_phase(timebuf *tb, aiRecord *prec)
{
    /*
     * How to average angles:
     *
     * https://rosettacode.org/wiki/Averages/Mean_angle
     *
     * In this case, phase angles are represented as 80.5MHz, even though the
     * actual phase is calculated at 161, leading to range of +/-90deg instead
     * of +/-180.
     *
     * So the procedure should be:
     *
     *    Multiple angles x 2 (this converts back to 161MHz phase)
     *    Generate polar vector (Real + imaginary) and sum them
     *    Find angle of summed vector (This is @ 161Mhz)
     *    Divide by 2 (report phase @ 80.5MHz)
     *
     *  Thanks,
     *  -Scott C
     */
    assert(tb->cnt > 0);

    std::complex<double> sum(0.0, 0.0);

    // If all weights are zero, then we *are* interested in the noise during
    // TIME_ON=0
    bool allweightszero = true;

    for (size_t p = 0; p < tb->cnt; ++p)
        allweightszero &= !tb->weights[tb->idx(p)];

    for (size_t p = 0; p < tb->cnt; ++p) {
        size_t pos = tb->idx(p);
        double w = allweightszero ? 1.0 : tb->weights[pos];
        sum += std::polar(w, tb->values[pos] * 2.0 * M_PI / 180.0);
    }

    prec->val = std::arg(sum) * 180.0 / M_PI / 2.0;
}

void get_value_any(timebuf *tb, aiRecord *prec)
{
    bool any = false;
    prec->val = 0.0;

    for (size_t p = 0; p < tb->cnt; ++p) {
        any |= tb->values[tb->idx(p)] != 0.0;

        if (any) {
            prec->val = 1.0;
            break;
        }
    }
}

void get_value_all(timebuf *tb, aiRecord *prec)
{
    bool all = true;
    prec->val = 1.0;

    for (size_t p = 0; p < tb->cnt; ++p) {
        all &= tb->values[tb->idx(p)] != 0.0;

        if (!all) {
            prec->val = 0.0;
            break;
        }
    }
}

long get_value(aiRecord *prec)
{
    TRY {
        Guard G(tb->lock);

        if(tb->cnt == 0) { // no data in buffer
            prec->udf = 1;
            (void)recGblSetSevr(prec, UDF_ALARM, INVALID_ALARM);
            return 0;
        } else {
            get_severity(tb, prec);

            // Report time of most recent sample
            if (prec->tse == epicsTimeEventDeviceTime)
                prec->time = tb->times[tb->last()];

            switch(tdev->reduce) {
            case First:
                get_value_first(tb, prec);
                break;
            case Min:
            case Max:
                get_value_min_max(tb, prec, tdev->reduce);
                break;
            case Average:
            case Stdev:
            case SpecialAvg:
            case MaskedStd:
            case WeightedAvg:
            case WeightedStd:
                get_value_stat(tb, prec, tdev->reduce);
                break;
            case AveragePhase:
                get_value_avg_phase(tb, prec);
                break;
            case Any:
                get_value_any(tb, prec);
                break;
            case All:
                get_value_all(tb, prec);
                break;
            default:
                std::numeric_limits<double>::quiet_NaN();
            }

            prec->udf = !std::isfinite(prec->val);
        }
        return 2;
    } CATCH()
}

long get_data(waveformRecord *prec, bool weights = false)
{
    TRY {
        if(prec->ftvl!=menuFtypeFLOAT) {
            (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
            return -1;
        }

        float *buf = (float*)prec->bptr;

        Guard G(tb->lock);

        if(tb->cnt==0) {
            // as zero length arrays don't work so well, give [0.0] with undefined alarm
            buf[0] = 0.0;
            prec->nord = 1;
            (void)recGblSetSevr(prec, UDF_ALARM, INVALID_ALARM);
            return 0;
        }

        size_t nelm = prec->nelm;
        if(nelm > tb->cnt)
            nelm = tb->cnt;

        if(prec->tse==epicsTimeEventDeviceTime) {
            // always report time of first sample

            prec->time = tb->times[tb->first()];
        }

        short maxsevr = 0;
        for (size_t p = 0; p < nelm; ++p) {
            size_t pos = tb->idx(p);
            *buf++ = weights ? tb->weights[pos] : tb->values[pos];
            maxsevr = std::max(maxsevr, tb->severities[pos]);
        }

        prec->nord = nelm;
        if(maxsevr)
            (void)recGblSetSevr(prec, READ_ALARM, maxsevr);

        return 0;
    } CATCH()
}

long get_buffer(waveformRecord *prec)
{
    return get_data(prec, false);
}

long get_weights(waveformRecord *prec)
{
    return get_data(prec, true);
}

long tbuf_report(int level)
{
    try {
        printf("%zu TBUFs\n", timebufs.size());
        timebufs_t::const_iterator it, end;
        for(it=timebufs.begin(), end=timebufs.end(); it!=end; ++it)
        {
            const timebuf *tb = it->second;

            if(level<2) {
                printf("TBUF: %s\n", tb->name.c_str());
                continue;
            }

            double period;
            size_t maxn, curn;
            std::vector<double> values;
            std::vector<epicsTimeStamp> times;
            std::vector<short> severities;

            {
                Guard G(tb->lock);
                period = tb->period;
                maxn = tb->size();
                curn = tb->cnt;
            }


            printf("TBUF: %s, period=%f, count %zu/%zu\n",
                   tb->name.c_str(), period, curn, maxn);

            if(level<3)
                continue;

            values.resize(maxn);
            times.resize(maxn);
            severities.resize(maxn);

            {
                Guard G(tb->lock);
                values = tb->values;
                times = tb->times;
                severities = tb->severities;
            }

            for(size_t i=0; i<values.size(); i++) {
                char buf[64];
                epicsTimeToStrftime(buf, sizeof(buf)-1, "%Y-%m-%d %H:%M:%S.%03f", &times[i]);
                printf(" [%zu] %s %u VAL %f\n", i, buf,  severities[i], values[i]);
            }
        }

    }catch(std::exception& e){
        printf("Error: %s\n", e.what());
    }
    return 0;
}

drvet drvtbuf = {2, (DRVSUPFUN)&tbuf_report, NULL};

template<typename T>
struct dset6 {
    long N;
    long (*report)(int);
    long (*init)(int);
    long (*init_record)(T*);
    long (*get_io_intr_info)(int, dbCommon *, IOSCANPVT *);
    long (*read_write)(T*);
};

} // namespace

epicsExportAddress(drvet, drvtbuf);

#define DSET6(REC, NAME, INIT, IOINT, RW) \
    static dset6<REC ## Record> NAME = {6, NULL, NULL, INIT, IOINT, RW}; epicsExportAddress(dset, NAME)

DSET6(longout, devTBUFLoSetSamples, &init_record_tbuf<0>, NULL, set_maxsamples);
DSET6(ao, devTBUFAoSetPeriod, &init_record_tbuf<2>, NULL, set_period);
DSET6(ao, devTBUFAoNewSample, &init_record_tbuf<2>, NULL, new_sample);

DSET6(ai, devTBUFAiOutSample, &init_record_tbuf<0>, &update_scan, get_value);
DSET6(waveform, devTBUFWFOutBuffer, &init_record_tbuf<0>, &update_scan, get_buffer);
DSET6(waveform, devTBUFWFOutWeights, &init_record_tbuf<0>, &update_scan, get_weights);
