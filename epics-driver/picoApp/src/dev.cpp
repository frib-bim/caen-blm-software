
#include <map>
#include <iostream>
#include <sstream>
#include <memory>

#include <string.h>

#include <devSup.h>
#include <drvSup.h>
#include <recGbl.h>
#include <alarm.h>
#include <dbAccess.h>
#include <dbStaticLib.h>
#include <menuFtype.h>
#include <epicsExit.h>
#include <iocsh.h>

#include <longoutRecord.h>
#include <longinRecord.h>
#include <aoRecord.h>
#include <aiRecord.h>
#include <mbboRecord.h>
#include <mbbiRecord.h>
#include <waveformRecord.h>

#include "pico.h"

namespace {

typedef std::map<std::string, PicoDevice*> dev_map_t;
dev_map_t dev_map;

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
            dev->ioctl(ABORT_READ, (long)0);
            break;
        }
    }

    dev->readerT.exitWait();
}

void createPICO(const std::string& name, const std::string& devname)
{
    try{
        if(dev_map.find(name)!=dev_map.end())
            throw std::invalid_argument("Name already in use");

        PicoDevice *dev = new PicoDevice(devname);

        epicsAtExit(&shutdownPICO, dev);

        dev_map[name] = dev;
    }catch(std::exception& e){
        fprintf(stderr, "error %s\n", e.what());
    }
}

struct dsetInfo
{
    PicoDevice *dev;
    unsigned chan;
    dsetInfo() :dev(0), chan(0) {}
};

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

long init_record_common(dbCommon *prec)
{
    DBLINK* plink =  get_dev_link(prec);
    if(!plink) return 0;
    assert(plink->type==INST_IO);

    std::istringstream P(plink->value.instio.string);

    std::auto_ptr<dsetInfo> D(new dsetInfo);

    std::string name;
    P>>name;
    if(!P.fail() && !P.eof())
        P>>D->chan;

    if(!P.eof() || P.fail()) {
        fprintf(stderr, "%s: unable to parse '%s'\n", prec->name,
                plink->value.instio.string);
        return 0;
    }

    if(D->chan>7) {
        fprintf(stderr, "%s: channel %u out of range\n", prec->name, D->chan);
        return 0;
    }

    dev_map_t::const_iterator it = dev_map.find(name);
    if(it==dev_map.end()) {
        fprintf(stderr, "%s: unknown device name '%s'\n", prec->name, name.c_str());
        return 0;
    }
    D->dev = it->second;

    prec->dpvt = D.release();
    return 0;
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

long write_clock(aoRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = prec->rval;

        info->dev->ioctl(SET_FSAMP, &val);
    } END(0)
}

long read_clock(aiRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = 0;

        info->dev->ioctl(GET_FSAMP, &val);

        prec->rval = val;
    } END(0)
}

long write_clocksrc(mbboRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = prec->rval;

        info->dev->ioctl(SET_CONV_MUX, &val);
    } END(0)
}

long write_trig_gate(mbboRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = prec->rval;

        info->dev->ioctl(SET_GATE_MUX, &val);
    } END(0)
}

long write_trig_lvl(aoRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        info->dev->trig.limit = prec->val;

        info->dev->ioctl(SET_TRG, &info->dev->trig);
    } END(0)
}

long write_trig_chan(mbboRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        info->dev->trig.ch_sel = prec->val;

        info->dev->ioctl(SET_TRG, &info->dev->trig);
    } END(0)
}

long write_trig_mode(mbboRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        info->dev->trig.mode = (trg_ctrl::mode_t)prec->rval;

        info->dev->ioctl(SET_TRG, &info->dev->trig);
    } END(0)
}

long write_trig_samples(longoutRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        info->dev->trig.nr_samp = prec->val;

        info->dev->ioctl(SET_TRG, &info->dev->trig);
    } END(0)
}

long write_pre_trig(longoutRecord *prec)
{
    BEGIN {
        Guard G(info->dev->lock);

        epicsUInt32 val = prec->val;

        info->dev->ioctl(SET_RING_BUF, &val);
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

        info->dev->ioctl(SET_RANGE, &info->dev->ranges);
    } END(0)
}

long read_chan_data(waveformRecord *prec)
{
    assert(prec->ftvl==menuFtypeFLOAT);
    BEGIN {
        Guard G(info->dev->lock);

        size_t N = std::min(info->dev->data.size()/PicoDevice::NCHANS,
                            (size_t)prec->nelm);

        prec->nord = info->dev->readChan(info->chan, (epicsFloat32*)prec->bptr, N);
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

        if(info->dev->target_state==PicoDevice::Idle)
        {
            /* start reading */
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
                   "CState: "<<dev->cur_state<<"\n";
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

void pico8registrar()
{
    iocshRegister(&createPICOFuncDef, &createPICOCall);
}

template<typename R>
struct dset5 {
    long N;
    long (*report)(R*);
    long (*init)(int);
    long (*init_record)(dbCommon*);
    long (*get_io_intr_info)(int, dbCommon* prec, IOSCANPVT*);
    long (*readwrite)(R*);
    long (*linconv)(R*);
};

#define DSET(NAME, REC, IOINTR, RW) dset5<REC ## Record> NAME = \
    {6, NULL, NULL, &init_record_common, IOINTR, RW, NULL}

#define DSET2(NAME, REC, IOINTR, RW) dset5<REC ## Record> NAME = \
    {6, NULL, NULL, &init_record_common2, IOINTR, RW, NULL}

DSET(devPico8WfMessage, waveform, &get_data_update, &read_lastmsg);

DSET(devPico8AoClock, ao,  NULL, &write_clock);
DSET(devPico8AiClock, ai,  NULL, &read_clock);
DSET(devPico8MbboClockSrc, mbbo, NULL, &write_clocksrc);

DSET(devPico8MbboRunMode, mbbo, NULL, &write_run_mode);
DSET2(devPico8MbbiStatus, mbbi, NULL, &read_run_status);

DSET(devPico8AoTrigLvl, ao, NULL, &write_trig_lvl);
DSET(devPico8MbboTrigChan, mbbo, NULL, &write_trig_chan);
DSET(devPico8MbboTrigMode, mbbo, NULL, &write_trig_mode);
DSET(devPico8LoTrigSamp, longout, NULL, &write_trig_samples);

DSET(devPico8LoPreSamp, longout, NULL, &write_pre_trig);
DSET(devPico8MbboTrigGate, mbbo, NULL, &write_trig_gate);

DSET(devPico8MbboRange, mbbo, NULL, &write_chan_range);

DSET(devPico8WfChanData, waveform, NULL, &read_chan_data);

} // namespace

#include <epicsExport.h>

epicsExportAddress(drvet, drvpico8);

epicsExportAddress(dset, devPico8WfMessage);
epicsExportAddress(dset, devPico8AoClock);
epicsExportAddress(dset, devPico8AiClock);
epicsExportAddress(dset, devPico8MbboClockSrc);

epicsExportAddress(dset, devPico8MbboRunMode);
epicsExportAddress(dset, devPico8MbbiStatus);

epicsExportAddress(dset, devPico8AoTrigLvl);
epicsExportAddress(dset, devPico8MbboTrigChan);
epicsExportAddress(dset, devPico8MbboTrigMode);
epicsExportAddress(dset, devPico8LoTrigSamp);

epicsExportAddress(dset, devPico8LoPreSamp);
epicsExportAddress(dset, devPico8MbboTrigGate);

epicsExportAddress(dset, devPico8MbboRange);

epicsExportAddress(dset, devPico8WfChanData);

epicsExportRegistrar(pico8registrar);
