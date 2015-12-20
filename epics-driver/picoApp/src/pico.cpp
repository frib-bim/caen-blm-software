
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
    ,mode(Single)
    ,reload(true)
    ,running(true)
    ,debug_level(0)
    ,ranges(0)
    ,nsamp(100)
{
    trig.nr_samp = 1;
    trig.ch_sel = 0;
    trig.limit = 0.0;
    trig.mode = trg_ctrl::DISABLED;

    for(unsigned i=0; i<NCHANS; i++) {
        scale[i] = 1.0;
        offset[i] = 0.0;
    }

    open();

    scanIoInit(&stsupdate);
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
    fd = F;
}

void
PicoDevice::resize(unsigned nsamp)
{
    this->nsamp = nsamp;
}

void
PicoDevice::run()
{
    this->debug(1)<<"Working started\n";
    coreNotify.signal();
    Guard G(lock);

    PicoDevice::data_t dbuf;
    PicoDevice::data_t prep[NCHANS];
    epicsTimeStamp now;

    while(running) {
        debug(4)<<"Worker "<<cur_state<<" -> "<<target_state<<"\n";

        if(target_state != cur_state) scanIoRequest(stsupdate);
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
            unsigned dsize = this->nsamp;
            double S[NCHANS], O[NCHANS];
            memcpy(S, scale, sizeof(scale));
            memcpy(O, offset, sizeof(offset));

            UnGuard U(G);

            dbuf.resize(dsize*NCHANS);
            for(unsigned i=0; i<NCHANS; i++)
                prep[i].resize(dsize);

            debug(5)<<"Working enter read()\n";
            ret = ::read(fd, &dbuf[0], 4*dbuf.size());
            epicsTimeGetCurrent(&now);
            debug(5)<<"Working leave read() -> "<<ret<<"\n";

            for(unsigned i=0; i<NCHANS; i++) {
                for(size_t s=0; s<dsize; s++)
                    prep[i][s] = O[i] + S[i]*dbuf[i+NCHANS*s];
            }
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
                for(unsigned i=0; i<NCHANS; i++) {
                    data[i].swap(prep[i]);
                }
                updatetime = now;
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
