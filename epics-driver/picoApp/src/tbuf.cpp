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

#include <cmath>

#include <dbAccess.h>
#include <dbScan.h>
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

#include "dev.h"

namespace {

typedef epicsGuard<epicsMutex> Guard;
typedef epicsGuardRelease<epicsMutex> UnGuard;

enum reduce_t {
    First,   // FIFO
    Average,
    Min,
    Max
};

struct timebuf {
    timebuf(const std::string& n)
        :name(n)
        ,maxsamples(100)
        ,period(1.0)
        ,values(maxsamples)
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

    // index of next element to be populated
    inline size_t next() const { return pos; }

    const std::string name;

    mutable epicsMutex lock;

    // config
    size_t maxsamples;
    double period;

    std::vector<double> values;
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

                    if     (reduce=="First")   dev->reduce = First;
                    else if(reduce=="Mean")    dev->reduce = Average;
                    else if(reduce=="Max")     dev->reduce = Max;
                    else if(reduce=="Min")     dev->reduce = Min;
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
                if(delta<=0) {
                    fprintf(stderr, "%s: non-monotonic time (diff=%f).  Clear buffer.\n",
                                 prec->name, delta);
                    tb->reset();
                }
            }

            tb->values[tb->pos]     = newval;
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

void get_value_first(timebuf *tb, aiRecord *prec)
{
    size_t pos = tb->first();

    prec->val = tb->values[pos];
    if(tb->severities[pos])
        recGblSetSevr(prec, READ_ALARM, tb->severities[pos]);

    if(prec->tse==epicsTimeEventDeviceTime) {
        prec->time = tb->times[pos];
    }
}

void get_value_stat(timebuf *tb, aiRecord *prec, reduce_t reduce)
{
    size_t pos = tb->first();

    assert(tb->cnt>0);

    // initialize w/ first sample
    double newval = tb->values[pos];
    short newsevr = tb->severities[pos];

    pos = (pos+1)%tb->size();

    for(size_t n=tb->cnt-1; n; n--, pos = (pos+1)%tb->size()) {
        if(tb->severities[pos]>newsevr)
            newsevr = tb->severities[pos];
        switch(reduce) {
        case First: break;
        case Average:
            newval += tb->values[pos];
            break;
        case Min:
            if(tb->values[pos]<newval)
                newval = tb->values[pos];
            break;
        case Max:
            if(tb->values[pos]>newval)
                newval = tb->values[pos];
            break;
        }
    }

    if(reduce == Average)
        newval /= tb->cnt;

    prec->val = newval;
    if(newsevr)
        (void)recGblSetSevr(prec, READ_ALARM, newsevr);

    if(prec->tse==epicsTimeEventDeviceTime) {
        // always report time of most recent sample

        prec->time = tb->times[tb->last()];
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
            switch(tdev->reduce) {
            case First:
                get_value_first(tb, prec); break;
            case Average:
            case Min:
            case Max:
                get_value_stat(tb, prec, tdev->reduce); break;
            default:
                std::numeric_limits<double>::quiet_NaN();
            }
            prec->udf = !std::isfinite(prec->val);
        }
        return 2;
    } CATCH()
}

long get_buffer(waveformRecord *prec)
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

        ssize_t pos = tb->first();

        short maxsevr = 0;
        for(size_t n=nelm; n; n--, pos = (pos+1)%tb->size()) {
            *buf++ = tb->values[pos];
            if(tb->severities[pos] > maxsevr)
                maxsevr = tb->severities[pos];
        }

        prec->nord = nelm;
        if(maxsevr)
            (void)recGblSetSevr(prec, READ_ALARM, maxsevr);

        if(prec->tse==epicsTimeEventDeviceTime) {
            // always report time of most recent sample

            prec->time = tb->times[tb->last()];
        }

        return 0;
    } CATCH()
}

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

#define DSET6(REC, NAME, INIT, IOINT, RW) \
    static dset6<REC ## Record> NAME = {6, NULL, NULL, INIT, IOINT, RW}; epicsExportAddress(dset, NAME)

DSET6(longout, devTBUFLoSetSamples, &init_record_tbuf<0>, NULL, set_maxsamples);
DSET6(ao, devTBUFAoSetPeriod, &init_record_tbuf<2>, NULL, set_period);
DSET6(ao, devTBUFAoNewSample, &init_record_tbuf<2>, NULL, new_sample);

DSET6(ai, devTBUFAiOutSample, &init_record_tbuf<0>, &update_scan, get_value);
DSET6(waveform, devTBUFWFOutBuffer, &init_record_tbuf<0>, &update_scan, get_buffer);
