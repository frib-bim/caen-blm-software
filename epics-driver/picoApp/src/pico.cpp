
#include <errno.h>
#include <string.h>

#include <iostream>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "pico.h"

PicoDevice::PicoDevice(const std::string &fname)
    :devname(fname)
    ,fd(-1)
    ,readerT(*this, "Reader",
             epicsThreadGetStackSize(epicsThreadStackSmall),
             epicsThreadPriorityHigh)
    ,cur_state(Idle)
    ,target_state(Idle)
    ,reload(true)
    ,running(true)
    ,debug_level(0)
    ,ranges(0)
{
    trig.nr_samp = 1;
    trig.ch_sel = 0;
    trig.limit = 0.0;
    trig.mode = trg_ctrl::DISABLED;

    open();

    scanIoInit(&dataupdate);
    resize(100); // some default size

    readerT.start();
    coreNotify.wait();
}

void
PicoDevice::open()
{
    int F = ::open(devname.c_str(), O_RDWR|O_CLOEXEC);
    if(F==-1)
        throw system_error(errno);
}

void
PicoDevice::resize(unsigned nsamp)
{
    data.resize(NCHANS*nsamp);
}

unsigned
PicoDevice::readChan(unsigned chan, epicsFloat32 *arr, unsigned nsamp)
{
    unsigned N = std::min(nsamp, (unsigned)(data.size()/NCHANS));
    const epicsFloat32 *src = &data[chan];

    while(nsamp--) {
        *arr++ = *src;
        src += NCHANS;
    }
    return N;
}

void
PicoDevice::run()
{
    this->debug(1)<<"Working started\n";
    coreNotify.signal();
    Guard G(lock);

    std::vector<epicsFloat32> dbuf(data.size());

    while(running) {
        debug(4)<<"Worker "<<cur_state<<" -> "<<target_state<<"\n";

        state_t T = target_state;
        cur_state = T;

        coreNotify.signal();

        switch(T) {
        case Error:
        case Idle:
        {
            UnGuard U(G);
            debug(5)<<"Working gone idle\n";
            workerNotify.wait();
            debug(5)<<"Working done idle\n";
        }
            break;
        case Reading:
            ssize_t ret;
        {
            UnGuard U(G);
            debug(5)<<"Working enter read()\n";
            ret = ::read(fd, &dbuf[0], 4*NCHANS*dbuf.size());
            debug(5)<<"Working leave read() -> "<<ret<<"\n";
        }
            if(ret<0) {
                int err = errno;
                switch(err) {
                case EINTR:
                case ECANCELED:
                    continue;
                default:
                    lasterror = "read error: ";
                    lasterror += strerror(err);
                    target_state = Error;
                }
            } else if(ret==0) {
                lasterror = "read zero";
                target_state = Idle;
            } else {
                this->debug(2)<<"Data ready\n";
                if(mode==Single)
                    target_state = Idle;
                scanIoRequest(dataupdate);
            }
        }
    }

    this->debug(1)<<"Working stopping\n";
}

std::ostream&
PicoDevice::debug(int lvl)
{
    return std::cerr;
}

const char *
system_error::what() const throw()
{
    return strerror(num);
}
