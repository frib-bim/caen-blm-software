/*
 * This software is Copyright by the Board of Trustees of Michigan
 * State University (c) Copyright 2015.
 */
#ifndef PICO_H
#define PICO_H

#include <sys/ioctl.h>

#include <errno.h>

#include <ostream>
#include <stdexcept>
#include <string>
#include <sstream>
#include <vector>

#include <epicsTime.h>
#include <epicsTypes.h>
#include <epicsMutex.h>
#include <epicsEvent.h>
#include <epicsGuard.h>
#include <epicsThread.h>
#include <errlog.h>

#include <dbScan.h>

#include "amc_pico.h"

#if defined(USER_SITE_FRIB) && !defined(SKIP_FRIB)
#define BUILD_FRIB 1
#endif

#define DPRINTF3(D, LVL, fmt, ...) do{ if((D)->debug_lvl>=(LVL)) { \
    errlogPrintf(fmt, ## __VA_ARGS__); \
}} while(0)

#define DPRINTF(LVL, fmt, ...) DPRINTF3(this, LVL, fmt, ## __VA_ARGS__)

struct system_error : public std::exception {
    int num;
    system_error(int e) :num(e) {}
    virtual const char *what() const throw();
};

struct SB {
    std::ostringstream strm;
    SB() {}
    operator std::string() const { return strm.str(); }
    template<typename T>
    SB& operator<<(T i) { strm<<i; return *this; }
};

typedef epicsGuard<epicsMutex> Guard;
typedef epicsGuardRelease<epicsMutex> UnGuard;

struct PicoDevice : public epicsThreadRunable {
    enum {
        NCHANS = 8
    };

    PicoDevice(const std::string& fname);
    virtual ~PicoDevice() {}

    void open();

    virtual void run();

    std::string devname; // "/dev/..."
    int fd;

    epicsThread readerT;
    epicsMutex lock;
    epicsEvent workerNotify, coreNotify;

    enum state_t {
        Idle,
        Reading,
        Error
    } cur_state, target_state;

    enum mode_t {
        Single,
        Normal
    } mode;

    bool reload;
    bool running;

    int debug_lvl;

    IOSCANPVT stsupdate;
    IOSCANPVT dataupdate;

    trg_ctrl trig;
    epicsUInt8 ranges;
    double trig_level;

    //! # of samples requested by user.  data[].size==nsamp after acquisition
    unsigned nsamp;
    //! SW decimation factor.  HW read() is nsamp*ndecim
    unsigned ndecim;

    typedef std::vector<epicsFloat32> data_t;
    data_t data[NCHANS];
    // linear scaling for raw data
    double scale[NCHANS], offset[NCHANS];

    epicsTimeStamp updatetime;

    std::string lasterror;

    template<typename P>
    void ioctl(unsigned long req, P arg)
    {
        int ret = ::ioctl(fd, req, arg);
        if(ret)
            throw system_error(errno);
    }
};

#ifdef BUILD_FRIB

struct PicoFRIBCapture : public epicsThreadRunable
{
    PicoFRIBCapture(const char *fname);
    virtual ~PicoFRIBCapture() {}

    virtual void run();

    int fd;

    IOSCANPVT update;

    epicsThread readerT;
    epicsMutex lock;

    bool running;
    epicsUInt32 count; // # of updates

    bool valid;
    epicsTimeStamp updatetime;

    std::vector<epicsUInt32> buffer;

    std::string lastmsg;
};

#endif // BUILD_FRIB

#endif // PICO_H
