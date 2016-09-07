/*
 * This software is Copyright by the Board of Trustees of Michigan
 * State University (c) Copyright 2015.
 */
#ifndef PICO_H
#define PICO_H

#include <sys/ioctl.h>
#include <unistd.h>

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

struct system_error : public std::runtime_error {
    int num;
    system_error(const std::string& msg, int e) :std::runtime_error(msg), num(e) {}
    virtual const char *what() const throw();
};

struct SB {
    std::ostringstream strm;
    SB() {}
    operator std::string() const { return strm.str(); }
    template<typename T>
    SB& operator<<(T i) { strm<<i; return *this; }
};

// Mostly translates C error returns to C++ exceptions
struct FDHelper
{
    int fd;
    FDHelper() :fd(-1) {}
    FDHelper(const char *name) :fd(-1) { open(name); }
    ~FDHelper() { close(); }
    void open(const char *name);
    void close();
    void ioctl(long req, long arg);
    void ioctl(long req, void *arg);
    off_t seek(off_t o, int w=SEEK_CUR);
    ssize_t write(const void *buf, size_t cnt);
    ssize_t read(void *buf, size_t cnt);
    ssize_t write(const void *buf, size_t cnt, off_t o);
    ssize_t read(void *buf, size_t cnt, off_t o);
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
    FDHelper fd;

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
};

#ifdef BUILD_FRIB

struct PicoFRIBCapture : public epicsThreadRunable
{
    PicoFRIBCapture(const char *fname);
    virtual ~PicoFRIBCapture() {}

    virtual void run();

    FDHelper fd_cap, fd_reg, fd_ddr;

    IOSCANPVT update;
    IOSCANPVT msgupdate;

    epicsThread readerT;
    epicsEvent sync;
    epicsMutex lock;

    bool running;
    epicsUInt32 count; // # of updates

    int debug_lvl;

    bool valid;
    epicsTimeStamp updatetime;

    std::vector<epicsUInt32> buffer;

    std::string lastmsg;
};

#endif // BUILD_FRIB

#endif // PICO_H
