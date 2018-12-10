/*
 * This software is Copyright by the Board of Trustees of Michigan
 * State University (c) Copyright 2015.
 */
#ifndef PICO_H
#define PICO_H

#include <linux/ioctl.h>
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
#include <callback.h>
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
    system_error(const std::string& msg, int e);
    virtual ~system_error() throw() {}
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
    // the pico8 driver follows the convention of encoding the pointed size
    // in the request code.  See <linux/ioctl.h>
    template<long req, typename T>
    void ioctl_check(T* arg) {
        STATIC_ASSERT(sizeof(T)==_IOC_SIZE(req));
        this->ioctl(req, (void*)arg);
    }

    off_t seek(off_t o, int w=SEEK_CUR);
    void write(const void *buf, size_t cnt);
    void read(void *buf, size_t cnt);
    void write(const void *buf, size_t cnt, off_t o);
    void read(void *buf, size_t cnt, off_t o);
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

class PicoFribCaptureMsgLog {

private:
    size_t maxmsgs;  // maximum number of messages
    size_t pos;      // next message to be written
    size_t cnt;      // number of messages stored

    std::vector<std::string> messages;
    std::vector<epicsTimeStamp> times;
    mutable epicsMutex lock;

public:
    PicoFribCaptureMsgLog(size_t maxmsgs=25) :
        maxmsgs(maxmsgs),
        messages(maxmsgs),
        times(maxmsgs)
    {
        reset();
    }

    inline size_t size() const {
        return messages.size();
    }

    inline bool empty() const {
        return cnt == 0;
    }

    inline size_t firstpos() const {
        return pos >= cnt ? pos - cnt : pos + size() - cnt;
    }

    inline size_t lastpos() const {
        return pos ? pos - 1 : messages.size() - 1;
    }

    inline std::string last() const {
        return cnt ? messages[lastpos()] : "";
    }

    /* Add a message to the circular buffer. Ignore empty messages. */
    void add(std::string const & message) {
        if (message.empty())
            return;

        Guard G(lock);

        messages[pos] = message;
        epicsTimeGetCurrent(&times[pos]);

        if (cnt < size())
            ++cnt;

        pos = (pos + 1) % size();
    }

    /* Clear all messages */
    void reset(void) {
        pos = cnt = 0;
    }

    /* Get all messages as a single, new-line separated string */
    std::string get(void) {
        Guard G(lock);

        std::ostringstream log;
        size_t pos, n;

        for (pos = firstpos(), n = cnt; n; n--, pos = (pos + 1) % size()) {
            char timebuf[256];

            epicsTimeToStrftime(timebuf, sizeof(timebuf), "%F %T", &times[pos]);

            log << "[" << timebuf << "] " << messages[pos] << std::endl;
        }

        return log.str();
    }

    void resize(size_t size) {
        Guard G(lock);

        maxmsgs = size;
        messages.resize(size);
        times.resize(size);
        reset();
    }
};

struct PicoFRIBCapture : public epicsThreadRunable
{
    PicoFRIBCapture(const char *fname, std::string const & evt);
    virtual ~PicoFRIBCapture() {}

    virtual void run();

    FDHelper fd_cap, fd_reg, fd_ddr;

    IOSCANPVT update;
    IOSCANPVT msgupdate;
    IOSCANPVT msglogupdate;

    epicsThread readerT;
    epicsEvent sync;
    epicsMutex lock;

    bool running;
    epicsUInt32 count; // # of updates

    int debug_lvl;

    bool valid;
    epicsTimeStamp updatetime;

    std::vector<epicsUInt32> buffer;

    PicoFribCaptureMsgLog msglog;
    std::string lastmsg;

    // DDR RAM access
    epicsUInt32 ddr_start,
                ddr_count;
    dbCommon *ddr_busy; // effectively a flag to ensure that ddr_cb isn't re-used while queued
    CALLBACK ddr_cb;

    std::string eventName;
};

#endif // BUILD_FRIB

#endif // PICO_H
