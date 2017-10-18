/*
 * This software is Copyright by the Board of Trustees of Michigan
 * State University (c) Copyright 2015.
 */
#include <map>
#include <iostream>
#include <sstream>
#include <memory>

#include <math.h>
#include <string.h>

#include <devSup.h>
#include <drvSup.h>
#include <recGbl.h>
#include <alarm.h>
#include <dbAccess.h>
#include <dbStaticLib.h>
#include <menuFtype.h>
#include <epicsExit.h>
#include <cvtTable.h>
#include <iocsh.h>
#include <epicsStdlib.h>
#include <postfix.h>

#include <longoutRecord.h>
#include <longinRecord.h>
#include <aoRecord.h>
#include <aiRecord.h>
#include <mbboRecord.h>
#include <mbbiRecord.h>
#include <biRecord.h>
#include <boRecord.h>
#include <stringinRecord.h>
#include <waveformRecord.h>
#include <epicsExport.h>

#include "basecompat.h"
#include "pico.h"
#include "dev.h"

DBLINK* get_dev_link(dbCommon *prec)
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

// Evaluate expression w/ epics calc engine
// eg. "0x1000+0x100" -> 0x1100
double epicsEval(const std::string& expr)
{
    std::vector<char> rpcl(INFIX_TO_POSTFIX_SIZE(expr.size()));
    short err;

    if(postfix(expr.c_str(), &rpcl[0], &err)) {
        throw std::runtime_error(SB()<<"expression \""<<expr<<"\" error "<<calcErrorStr(err));
    }

    std::vector<double> vars(CALCPERFORM_NARGS, 0.0);
    double result;

    if(calcPerform(&vars[0], &result, &rpcl[0])) {
        throw std::runtime_error(SB()<<"expression \""<<expr<<"\" Can't evaluate");
    }
    return result;
}

namespace {

typedef std::map<std::string, PicoDevice*> dev_map_t;
dev_map_t dev_map;
#ifdef BUILD_FRIB
typedef std::map<std::string, PicoFRIBCapture*> dev_cap_map_t;
dev_cap_map_t dev_cap_map;
#endif

#define BEGIN if(!prec->dpvt) return 0; dsetInfo *info = (dsetInfo*)prec->dpvt; try
#define END(N) catch(std::exception& e) { \
    fprintf(stderr, "%s: error %s\n", prec->name, e.what()); \
    (void)recGblSetSevr(prec, READ_ALARM, INVALID_ALARM); \
} return N;

void shutdownPICO(void *raw)
{
    PicoDevice *dev =(PicoDevice*)raw;

    {
        Guard G(dev->lock);
        dev->running = false;
        switch(dev->target_state) {
        case PicoDevice::Error:
        case PicoDevice::Idle:
            dev->workerNotify.signal();
            break;
        case PicoDevice::Reading:
            dev->fd.ioctl(ABORT_READ, (long)0);
            break;
        }
    }

    dev->readerT.exitWait();
}

#ifdef BUILD_FRIB
void shutdownCapture(void *raw)
{
    PicoFRIBCapture *cap = (PicoFRIBCapture*)raw;

    {
        Guard G(cap->lock);
        cap->running = false;
        cap->fd_cap.ioctl(ABORT_READ, 0l);
    }
    cap->readerT.exitWait();
}
#endif // BUILD_FRIB

void createPICO(const std::string& name, const std::string& devname)
{
    try{
        if(dev_map.find(name)!=dev_map.end())
            throw std::invalid_argument("Name already in use");

        PicoDevice *dev = new PicoDevice(devname);

        epicsAtExit(&shutdownPICO, dev);

        dev_map[name] = dev;

#ifdef BUILD_FRIB
        PicoFRIBCapture *cap = new PicoFRIBCapture(devname.c_str());

        epicsAtExit(&shutdownCapture, cap);

        dev_cap_map[name] = cap;
#endif
    }catch(std::exception& e){
        fprintf(stderr, "error %s\n", e.what());
    }
}

void debugPICO(const std::string& name, int lvl)
{
    try{
        dev_map_t::const_iterator it = dev_map.find(name);
        if(it==dev_map.end())
            throw std::invalid_argument("Unknown PICO8 device");

        {
            Guard G(it->second->lock);
            it->second->debug_lvl = lvl;
        }

#ifdef BUILD_FRIB
        dev_cap_map_t::const_iterator it2 = dev_cap_map.find(name);
        if(it2!=dev_cap_map.end()) {
            Guard G(it2->second->lock);
            it2->second->debug_lvl = lvl;
        }
#endif
    }catch(std::exception& e){
        fprintf(stderr, "error %s\n", e.what());
    }
}

struct dsetInfo
{
    PicoDevice *dev;
#ifdef BUILD_FRIB
    PicoFRIBCapture *cap;
#endif
    unsigned chan,
             offset,
             step,
             mask,
             shft;
    dsetInfo() :dev(0), chan(0), offset(0), step(0), mask(0), shft(0) {
#ifdef BUILD_FRIB
        cap = 0;
#endif
    }
};

unsigned long parseul(const std::string& s)
{
#if 0
    unsigned long ret;
    int err = epicsParseULong(s.c_str(), &ret, 0, NULL);
    if(err)
        throw std::runtime_error(SB()<<"Failed to parse \""<<s<<"\" as an unsigned integer");
    return ret;
#else
    return epicsEval(s);
#endif
}

/* Common link format
 *
 * @$(DEVNAME) chan=1 offset=0x100 step=4 mask=0xff00
 *   offset and step are expressed in bytes
 *   chan is in [0,7]
 */
long init_record_common(dbCommon *prec)
{
try{
    DBLINK* plink =  get_dev_link(prec);
    if(!plink) return 0;
    assert(plink->type==INST_IO);

    std::istringstream P(plink->value.instio.string);

    std::auto_ptr<dsetInfo> D(new dsetInfo);

    std::string name;
    P>>name;
    while(!P.fail() && !P.eof())
    {
        std::string word;
        P>>word;
        size_t sep(word.find_first_of('='));
        if(sep==name.npos || sep==0 || sep==word.size()-1) {
            fprintf(stderr, "%s: expected 'name=val' instead of \"%s\"\n", prec->name, word.c_str());
            return 0;
        }
        std::string pname(word.substr(0, sep));
        if(pname=="chan")
            D->chan = parseul(word.substr(sep+1));
        else if(pname=="offset")
            D->offset = parseul(word.substr(sep+1));
        else if(pname=="step")
            D->step = parseul(word.substr(sep+1));
        else if(pname=="mask")
            D->mask = parseul(word.substr(sep+1));
        else
            fprintf(stderr, "%s: Unknown parameter \"%s\"\n", prec->name, pname.c_str());
    }

    if(!P.eof() || P.fail()) {
        fprintf(stderr, "%s: unable to parse '%s'\n", prec->name,
                plink->value.instio.string);
        return 0;
    }

    if(D->chan>7) {
        fprintf(stderr, "%s: channel %u out of range\n", prec->name, D->chan);
        return 0;
    }

    if(D->mask && !D->shft) {
        // automatically calculate shift so that lowest mask'd bit becomes bit 0
        for(unsigned mask = D->mask; (mask&1)==0; mask>>=1) D->shft++;
    }

    if(D->mask) {
        DBENTRY ent;
        dbInitEntry(pdbbase, &ent);

        if(dbFindRecord(&ent, prec->name))
            throw std::logic_error(SB()<<prec->name<<" can't find itself");

        // for bo/biRecord, copy D->mask to MASK field if on is set and not the other
        if(!dbFindField(&ent, "MASK") && ent.pflddes->field_type==DBF_ULONG) {
            epicsUInt32 *pfield = (epicsUInt32*)(((char*)prec)+ent.pflddes->offset);
            if(!*pfield) *pfield = D->mask;
        }

        dbFinishEntry(&ent);
    }

    dev_map_t::const_iterator it = dev_map.find(name);
    if(it==dev_map.end()) {
        fprintf(stderr, "%s: unknown device name '%s'\n", prec->name, name.c_str());
        return 0;
    }
    D->dev = it->second;

#ifdef BUILD_FRIB
    dev_cap_map_t::const_iterator it2 = dev_cap_map.find(name);
    if(it2!=dev_cap_map.end()) {
        D->cap = it2->second;
    }
#endif // BUILD_FRIB

    prec->dpvt = D.release();
    return 0;
}catch(std::exception& e) {
    fprintf(stderr, "%s : Error initializing : %s\n", prec->name, e.what());
    return 0;
}
}

long init_record_common2(dbCommon *prec)
{
    init_record_common(prec);
    return 2;
}

long read_lastmsg(waveformRecord *prec)
{
    BEGIN{
        assert(prec->ftvl==menuFtypeCHAR);
        assert(prec->nelm>0);

        Guard G(info->dev->lock);

        size_t N = std::min(info->dev->lasterror.size(), (size_t)prec->nelm-1);

        char *S = (char*)prec->bptr;
        memcpy(S, info->dev->lasterror.c_str(), N);
        S[N] = '\0';
        prec->nord = N+1;
    } END(0)
}

long get_data_update(int, dbCommon* prec, IOSCANPVT* scan)
{
    BEGIN {
        *scan = info->dev->dataupdate;
        return 0;
    } END(0)
}

long get_status_update(int, dbCommon* prec, IOSCANPVT* scan)
{
    BEGIN {
        *scan = info->dev->stsupdate;
        return 0;
    } END(0)
}

long get_cap_update(int, dbCommon* prec, IOSCANPVT* scan)
{
    BEGIN {
        if(info->cap) {
            *scan = info->cap->update;
            return 0;
        } else {
            return -S_dev_badSignal;
        }
    } END(0)
}

long get_cap_msgupdate(int, dbCommon* prec, IOSCANPVT* scan)
{
    BEGIN {
        if(info->cap) {
            *scan = info->cap->msgupdate;
            return 0;
        } else {
            return -S_dev_badSignal;
        }
    } END(0)
}

long write_clock(longoutRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = prec->val;

        info->dev->fd.ioctl_check<SET_FSAMP>(&val);

    } END(0)
}

long read_clock(longinRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = 0;

        info->dev->fd.ioctl_check<GET_FSAMP>(&val);

        prec->val = val;
    } END(0)
}

long write_clocksrc(mbboRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = prec->rval;

        info->dev->fd.ioctl_check<SET_CONV_MUX>(&val);
    } END(0)
}

long write_trig_src(mbboRecord *prec)
{
    BEGIN {
        if(prec->rval<0 || prec->rval>12)
            throw std::invalid_argument("invalid trigger source");

        Guard G(info->dev->lock);

        epicsUInt32 gate;
        if(prec->rval==0) { // soft trigger
            gate = 0;
            info->dev->trig.ch_sel = 0;
        } else if(prec->rval>=1 && prec->rval<=8) {
            info->dev->trig.ch_sel = prec->rval-1;
            gate = 2;
        } else if(prec->rval>=9 && prec->rval<=12) {
            gate = prec->rval-9u+3u; // Port 17, rval==9, gate==3
            info->dev->trig.ch_sel = 0;
        } else {
            throw std::logic_error("Invalid trigger source case");
        }

        info->dev->fd.ioctl_check<SET_TRG>(&info->dev->trig);
        info->dev->fd.ioctl_check<SET_GATE_MUX>(&gate);
    } END(0)
}

long write_trig_lvl(aoRecord *prec)
{
    BEGIN {
        if(!isfinite(prec->val))
            throw std::invalid_argument("trigger threshold not finite");

        Guard G(info->dev->lock);

        info->dev->trig_level = readraw(prec);
    } END(0)
}

long write_trig_mode(mbboRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        info->dev->trig.mode = (trg_ctrl::mode_t)prec->rval;

        info->dev->fd.ioctl_check<SET_TRG>(&info->dev->trig);
    } END(0)
}

long write_scale_ao(aoRecord *prec)
{
    BEGIN {
        if(info->chan>=NELEMENTS(info->dev->scale))
            throw std::invalid_argument("Channel out of range");
        info->dev->scale[info->chan] = prec->val;
    } END(0)
}

long write_offset_ao(aoRecord *prec)
{
    BEGIN {
        if(info->chan>=NELEMENTS(info->dev->offset))
            throw std::invalid_argument("Channel out of range");
        info->dev->offset[info->chan] = prec->val;
    } END(0)
}

long write_pre_trig(longoutRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = prec->val;

        info->dev->fd.ioctl_check<SET_RING_BUF>(&val);
    } END(0)
}

long write_nsamp(longoutRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        if(prec->val>0)
            info->dev->nsamp = prec->val;
        else
            (void)recGblSetSevr(prec, WRITE_ALARM, INVALID_ALARM);
    } END(0)
}

long write_ndecim(longoutRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        if(prec->val>0)
            info->dev->ndecim = prec->val;
        else
            (void)recGblSetSevr(prec, WRITE_ALARM, INVALID_ALARM);
    } END(0)
}

long write_chan_range(mbboRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        if(prec->rval)
            info->dev->ranges |= 1<<info->chan;
        else
            info->dev->ranges &= ~(1<<info->chan);

        info->dev->fd.ioctl_check<SET_RANGE>(&info->dev->ranges);
    } END(0)
}

long read_chan_data(waveformRecord *prec)
{
    assert(prec->ftvl==menuFtypeFLOAT);
    float *bptr = (float*)prec->bptr;

    BEGIN {
        if(info->chan>=NELEMENTS(info->dev->data))
            return 0;
        Guard G(info->dev->lock);

        PicoDevice::data_t &cdata = info->dev->data[info->chan];

        size_t N = cdata.size();
        unsigned step = info->step/4u,
                 offset = info->offset/4u;

        if(step==0) step=1;

        if(step<=1) {
            if(offset>N)  N=0;
            else          N-=offset;

            N = std::min(N/step, (size_t)prec->nelm);

            memcpy(bptr, &cdata[offset], sizeof(PicoDevice::data_t::value_type)*N);

            prec->nord = N;
        } else {
            // step>1 is additional decimation
            size_t i, o;
            for(i=offset, o=0; i<cdata.size() && o<(size_t)prec->nelm; i+=step, o++) {
                double val = cdata[i];
                for(unsigned j=1; j<step; j++)
                    val += cdata[i+j];
                bptr[o] = val/step;
            }
            prec->nord = o+1;
        }

        if(prec->tse==epicsTimeEventDeviceTime) {
            prec->time = info->dev->updatetime;
        }
    } END(0)
}

long write_run_mode(mbboRecord *prec)
{
    BEGIN {
        switch(prec->rval) {
        case PicoDevice::Single:
        case PicoDevice::Normal:
            break;
        default:
            throw std::invalid_argument("Invalid run mode");
        }

        Guard G(info->dev->lock);

        info->dev->mode = (PicoDevice::mode_t)prec->rval;

        if(info->dev->target_state!=PicoDevice::Reading)
        {
            DPRINTF3(info->dev, 3, "start reading\n");
            info->dev->target_state = PicoDevice::Reading;
            info->dev->workerNotify.signal();
        }
    } END(0)
}

long read_run_status(mbbiRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        prec->rval = (int)info->dev->target_state;
        return 0;
    } END(0)
}

long read_run_count(longinRecord *prec)
{
    if(prec->val != 0x7fffffff)
        prec->val++;
    else
        prec->val = 0;
    return 0;
}

#undef BEGIN
#define BEGIN if(!prec->dpvt) return 0; dsetInfo *info = (dsetInfo*)prec->dpvt; \
    if(!info->cap) { \
        (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM); \
        return 0; \
    } \
    try

long read_ddr(waveformRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        size_t reqsize = prec->nelm * dbValueSize(prec->ftvl);

        info->cap->fd_ddr.read(prec->bptr,
                               reqsize,
                               info->offset * dbValueSize(prec->ftvl));

        prec->nord = prec->nelm;

        return 0;
    }END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_cap_valid(biRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        prec->rval = !!info->cap->valid;

        if(prec->tse==epicsTimeEventDeviceTime) {
            prec->time = info->cap->updatetime;
        }

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_cap_count(longinRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        prec->val = info->cap->count;

        if(prec->tse==epicsTimeEventDeviceTime) {
            prec->time = info->cap->updatetime;
        }

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_cap_msg(waveformRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        char *buf = (char*)prec->bptr;
        size_t N = info->cap->lastmsg.size();
        if(N>prec->nelm-1)
            N = prec->nelm-1;
        memcpy(buf, info->cap->lastmsg.c_str(), N);
        buf[N] = '\0';
        prec->nord = N+1;

        if(prec->tse==epicsTimeEventDeviceTime) {
            prec->time = info->cap->updatetime;
        }

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_cap_li(longinRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        unsigned offset = info->offset/4;
        Guard G(info->cap->lock);

        if(info->cap->buffer.size()<offset+1) {
            (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
            return 0;
        }

        prec->val = info->cap->buffer[offset];

        if(info->mask)
            prec->val = (prec->val&info->mask)>>info->shft;

        if(prec->tse==epicsTimeEventDeviceTime) {
            prec->time = info->cap->updatetime;
        }

        if(!info->cap->valid)
            (void)recGblSetSevr(prec, READ_ALARM, INVALID_ALARM);

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_cap_ai(aiRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        unsigned offset = info->offset/4;
        Guard G(info->cap->lock);

        if(info->cap->buffer.size()<offset+1) {
            if(prec->tpro) errlogPrintf("%s: offset out of range %u / %zu\n", prec->name, info->offset, info->cap->buffer.size());
            (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
            return 0;
        }

        double val = i2f(info->cap->buffer[offset]);

        storeraw(prec, val);

        if(prec->tse==epicsTimeEventDeviceTime) {
            prec->time = info->cap->updatetime;
        }

        if(!info->cap->valid)
            (void)recGblSetSevr(prec, READ_ALARM, INVALID_ALARM);

        return 2;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_reg_mbbi(mbbiRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 val;
        info->cap->fd_reg.read(&val, 4, info->offset);

        if(info->mask)
            val = (val&info->mask)>>info->shft;

        prec->rval = val;

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_reg_li(longinRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 val;
        info->cap->fd_reg.read(&val, 4, info->offset);

        if(info->mask)
            val = (val&info->mask)>>info->shft;

        prec->val = val;

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_reg_bi(biRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 val;
        info->cap->fd_reg.read(&val, 4, info->offset);

        prec->rval = val&prec->mask;

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_reg_ai(aiRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 ival;
        info->cap->fd_reg.read(&ival, 4, info->offset);
        double val = i2f(ival);

        storeraw(prec, val);

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long read_regts_si(stringinRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 ival[2] = {0,0};
        info->cap->fd_reg.read(&ival, 8, info->offset);

        epicsTimeStamp ts;
        ts.secPastEpoch = ival[0]-POSIX_TIME_AT_EPICS_EPOCH;
        ts.nsec = double(ival[1])/info->step*1e9; // abuse step = ticks/sec of sub-second counter

        if(ival[1]>=info->step) {
            (void)recGblSetSevr(prec, READ_ALARM, INVALID_ALARM);
            if(prec->tpro>1) errlogPrintf("%s: NS out of range %u\n", prec->name, ival[1]);
        }

        if(prec->tse==epicsTimeEventDeviceTime)
            prec->time = ts;

        epicsTimeToStrftime(prec->val, sizeof(prec->val), "%Y-%m-%d %H:%M:%S.%09f %z", &ts);
        prec->val[sizeof(prec->val)-1] = '\0'; // necesary?

        return 0;
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long write_reg_bo(boRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 val;
        info->cap->fd_reg.read(&val, 4, info->offset);

        if(prec->rval)
            val |= prec->mask;
        else
            val &= ~prec->mask;

        info->cap->fd_reg.write(&val, 4, info->offset);
    }END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long write_reg_mbbo(mbboRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 val = prec->rval<<info->shft;

        if(info->mask) { // RMW
            val &= info->mask;

            epicsUInt32 rbv;
            info->cap->fd_reg.read(&rbv, 4, info->offset);

            val |= rbv&~info->mask;
        }

        info->cap->fd_reg.write(&val, 4, info->offset);
    }END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long write_reg_lo(longoutRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 val = prec->val<<info->shft;

        if(info->mask) { // RMW
            val &= info->mask;

            epicsUInt32 rbv;
            info->cap->fd_reg.read(&rbv, 4, info->offset);

            val |= rbv&~info->mask;
        }

        info->cap->fd_reg.write(&val, 4, info->offset);
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long write_reg_ao(aoRecord *prec)
{
#ifdef BUILD_FRIB
    BEGIN {
        Guard G(info->cap->lock);

        epicsUInt32 val = f2i(readraw(prec));

        info->cap->fd_reg.write(&val, 4, info->offset);
    } END(0)
#else
    (void)recGblSetSevr(prec, COMM_ALARM, INVALID_ALARM);
    return 0;
#endif
}

long pico_report(int lvl)
{
    dev_map_t::const_iterator cur, end;
    for(cur=dev_map.begin(), end=dev_map.end(); cur!=end; ++cur)
    {
        PicoDevice *dev = cur->second;
        Guard G(dev->lock);
        std::cout<<"Pico "<<cur->first<<"\n"
                   "Dev: "<<dev->devname<<"\n"
                   "TState: "<<dev->target_state<<"\n"
                   "CState: "<<dev->cur_state<<"\n"
                   "Mode: "<<dev->mode<<"\n";
    }
    return 0;
}

static drvet drvpico8 = {
    2,
    (DRVSUPFUN)&pico_report,
    NULL
};

const iocshArg createPICOArg0 = {"name", iocshArgString};
const iocshArg createPICOArg1 = {"/dev/...", iocshArgString};
const iocshArg * const createPICOArgs[] = {&createPICOArg0, &createPICOArg1};
const iocshFuncDef createPICOFuncDef = {
    "createPICO8", NELEMENTS(createPICOArgs), createPICOArgs
};

void createPICOCall(const iocshArgBuf *args)
{
    createPICO(args[0].sval, args[1].sval);
}

const iocshArg debugPICOArg0 = {"name", iocshArgString};
const iocshArg debugPICOArg1 = {"lvl", iocshArgInt};
const iocshArg * const debugPICOArgs[] = {&debugPICOArg0, &debugPICOArg1};
const iocshFuncDef debugPICOFuncDef = {
    "debugPICO", NELEMENTS(debugPICOArgs), debugPICOArgs
};

void debugPICOCall(const iocshArgBuf *args)
{
    debugPICO(args[0].sval, args[1].ival);
}

void pico8registrar()
{
    iocshRegister(&createPICOFuncDef, &createPICOCall);
    iocshRegister(&debugPICOFuncDef, &debugPICOCall);
}

template<typename R>
struct dset6 {
    long N;
    long (*report)(R*);
    long (*init)(int);
    long (*init_record)(dbCommon*);
    long (*get_io_intr_info)(int, dbCommon* prec, IOSCANPVT*);
    long (*readwrite)(R*);
    long (*linconv)(R*);
};

} // namespace

#define DSET(NAME, REC, IOINTR, RW) static dset6<REC ## Record> NAME = \
    {6, NULL, NULL, &init_record_common, IOINTR, RW, NULL}; epicsExportAddress(dset, NAME)

#define DSET2(NAME, REC, IOINTR, RW) static dset6<REC ## Record> NAME = \
    {6, NULL, NULL, &init_record_common2, IOINTR, RW, NULL}; epicsExportAddress(dset, NAME)

DSET(devPico8WfMessage, waveform, &get_data_update, &read_lastmsg);

DSET(devPico8LoClock, longout,  NULL, &write_clock);
DSET(devPico8LiClock, longin,  NULL, &read_clock);
DSET(devPico8MbboClockSrc, mbbo, NULL, &write_clocksrc);

DSET(devPico8MbboRunMode, mbbo, NULL, &write_run_mode);
DSET2(devPico8MbbiStatus, mbbi, &get_status_update, &read_run_status);

DSET2(devPico8AoTrigLvl, ao, NULL, &write_trig_lvl);
DSET(devPico8MbboTrigMode, mbbo, NULL, &write_trig_mode);

DSET(devPico8LoNSamp, longout, NULL, &write_nsamp);
DSET(devPico8LoNDecim, longout, NULL, &write_ndecim);
DSET(devPico8LoPreSamp, longout, NULL, &write_pre_trig);
DSET(devPico8MbboTrigSrc, mbbo, NULL, &write_trig_src);

DSET(devPico8MbboRange, mbbo, NULL, &write_chan_range);

DSET2(devPico8AoScale, ao, NULL, &write_scale_ao);
DSET2(devPico8AoOffset, ao, NULL, &write_offset_ao);

DSET(devPico8LiRunCount, longin, &get_data_update, &read_run_count);
DSET(devPico8WfChanData, waveform, &get_data_update, &read_chan_data);

DSET(devPico8WfDDR, waveform, NULL, &read_ddr);

DSET(devPico8BiCapValid, bi, &get_cap_update, &read_cap_valid);
DSET(devPico8LiCapCount, longin, &get_cap_update, &read_cap_count);
DSET(devPico8WfCapMsg, waveform, &get_cap_msgupdate, &read_cap_msg);
DSET(devPico8LiCap, longin, &get_cap_update, &read_cap_li);
DSET(devPico8AiCap, ai, &get_cap_update, &read_cap_ai);

DSET(devPico8MbbiReg, mbbi, NULL, &read_reg_mbbi);
DSET(devPico8LiReg, longin, NULL, &read_reg_li);
DSET(devPico8BiReg, bi, NULL, &read_reg_bi);
DSET(devPico8AiReg, ai, NULL, &read_reg_ai);
DSET(devPico8SiRegTime, stringin, NULL, &read_regts_si);
DSET(devPico8MbboReg, mbbo, NULL, &write_reg_mbbo);
DSET(devPico8BoReg, bo, NULL, &write_reg_bo);
DSET(devPico8LoReg, longout, NULL, &write_reg_lo);
DSET(devPico8AoReg, ao, NULL, &write_reg_ao);

epicsExportAddress(drvet, drvpico8);

epicsExportRegistrar(pico8registrar);
