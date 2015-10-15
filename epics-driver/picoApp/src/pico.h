#ifndef PICO_H
#define PICO_H

#include <sys/ioctl.h>

#include <errno.h>

#include <ostream>
#include <stdexcept>
#include <string>
#include <vector>

#include <epicsTypes.h>
#include <epicsMutex.h>
#include <epicsEvent.h>
#include <epicsGuard.h>
#include <epicsThread.h>

#include <dbScan.h>

#include "amc_pico.h"

struct system_error : public std::exception {
    int num;
    system_error(int e) :num(e) {}
    virtual const char *what() const throw();
};

typedef epicsGuard<epicsMutex> Guard;
typedef epicsGuardRelease<epicsMutex> UnGuard;

struct PicoDevice : public epicsThreadRunable {
    enum {
        NCHANS = 8
    };

    PicoDevice(const std::string& fname);

    void open();
    void halt();
    void resize(unsigned nsamp);
    unsigned readChan(unsigned chan, epicsFloat32 *arr, unsigned nsamp);

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

    int debug_level;
    std::ostream& debug(int lvl);

    IOSCANPVT dataupdate;

    trg_ctrl trig;
    epicsUInt8 ranges;

    std::vector<epicsFloat32> data;

    std::string lasterror;

    template<typename P>
    void ioctl(unsigned long req, P arg)
    {
        int ret = ::ioctl(fd, req, arg);
        if(ret)
            throw system_error(errno);
    }
};

#endif // PICO_H
