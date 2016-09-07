/*
 * This software is Copyright by the Board of Trustees of Michigan
 * State University (c) Copyright 2015.
 */
#include <errno.h>
#include <string.h>
#include <math.h>
#include <stdio.h>

#include <iomanip>
#include <iostream>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "pico.h"

PicoDevice::PicoDevice(const std::string &fname)
    :devname(fname)
    ,readerT(*this, "Reader",
             epicsThreadGetStackSize(epicsThreadStackSmall),
             epicsThreadPriorityHigh)
    ,cur_state(Idle)
    ,target_state(Idle)
    ,mode(Single)
    ,reload(true)
    ,running(true)
    ,debug_lvl(0)
    ,ranges(0)
    ,trig_level(0.0)
    ,nsamp(100)
    ,ndecim(1)
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

    readerT.start();
    coreNotify.wait();
}

void
PicoDevice::open()
{
    fd.open(devname.c_str());
}

void
PicoDevice::run()
{
    DPRINTF(1, "Working started\n");
    coreNotify.signal();
    Guard G(lock);

    PicoDevice::data_t dbuf;
    PicoDevice::data_t prep[NCHANS];
    epicsTimeStamp now;

    while(running) {
    try {
        DPRINTF(4, "Worker %u -> %u\n", (unsigned)cur_state, (unsigned)target_state);
        if(target_state != cur_state) scanIoRequest(stsupdate);
        state_t T = target_state;
        cur_state = T;

        coreNotify.signal();

        switch(T) {
        case Error:
        case Idle:
        {
            UnGuard U(G);
            DPRINTF(5, "Working gone idle\n");
            workerNotify.wait();
            DPRINTF(5, "Working done idle\n");
        }
            break;
        case Reading:
            ssize_t ret;
        {
            const unsigned usize  = this->nsamp,
                           decim  = this->ndecim,
                           hwsize = usize*decim;
            double S[NCHANS], O[NCHANS];

            // copy scale factors for use w/o lock
            memcpy(S, scale, sizeof(scale));
            memcpy(O, offset, sizeof(offset));

            if(trig.nr_samp != hwsize) {
                // nr_samp only seems to matter for external trig, but keep it in sync regardless
                trig.nr_samp = hwsize;

                fd.ioctl(SET_TRG, &trig);
            }

            {
                assert(trig.ch_sel<NCHANS);
                double A = scale[trig.ch_sel], B = offset[trig.ch_sel];

                // cooked = A*raw + B
                double raw = (trig_level-B)/A;

                if(!isfinite(raw)) {
                    lasterror = "Computed trigger level is not finite";
                    target_state = Error;
                    continue;
                }

                if(raw!=trig.limit) {
                    trig.limit = raw;
                    fd.ioctl(SET_TRG, &trig);
                }
            }

            UnGuard U(G);
            // ======= unlock

            dbuf.resize(hwsize*NCHANS);
            for(unsigned i=0; i<NCHANS; i++)
                prep[i].resize(usize);

            DPRINTF(5, "Working enter read()\n");
            ret = fd.read(&dbuf[0], 4*dbuf.size());
            epicsTimeGetCurrent(&now);
            DPRINTF(5, "Working done read() -> %u\n", (unsigned)ret);

            // demux and average by decim
            for(unsigned i=0; i<NCHANS; i++) {
                const double Scale = S[i], Offset = O[i];
                PicoDevice::data_t& D = prep[i];

                for(size_t s=0; s<usize; s++) {
                    const size_t index = s*NCHANS*decim + i;
                    double sum=0.0;
                    for(unsigned d=0; d<decim; d++) {
                        sum += Offset + Scale*dbuf[index + d*NCHANS];
                    }
                    D[s] = sum/decim;
                }
            }

            // ======= relock
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
                DPRINTF(2, "Data ready\n");
                if(mode==Single)
                    target_state = Idle;
                for(unsigned i=0; i<NCHANS; i++) {
                    data[i].swap(prep[i]);
                }
                updatetime = now;
                scanIoRequest(dataupdate);
            }
        }
    } catch(std::exception& e) {
        target_state = Error;
        lasterror = e.what();
    }
    }

    DPRINTF(1, "Working stopping\n");
}

#ifdef BUILD_FRIB

// maximum allowed difference between host and device timestamps
double picoSlewLimit = 4.0; // sec
// expected difference in consecuative capture timestamps
double picoStepDiff = 0.01; // sec
// maximum difference from expected difference between consecuative capture timestamps
double picoStepLimit = 0.004; // sec

PicoFRIBCapture::PicoFRIBCapture(const char *fname)
    :readerT(*this, "capture",
             epicsThreadGetStackSize(epicsThreadStackSmall),
             epicsThreadPriorityHigh)
    ,running(true)
    ,count(0)
    ,debug_lvl(0)
    ,valid(false)
{
    scanIoInit(&update);
    scanIoInit(&msgupdate);
    updatetime.secPastEpoch = 0;
    updatetime.nsec = 0;

    fd_cap.open(fname);

    // regular DDR access
    fd_reg.open(fname);
    {
        std::string ddrname = SB()<<fname<<"_ddr";
        fd_ddr.open(ddrname.c_str());
    }

    uint32_t ival = 0;
    fd_cap.ioctl(GET_SITE_ID, &ival);
    if(ival!=USER_SITE_FRIB) {
        throw std::runtime_error("Not FRIB firmware");
    }

    ival = 1; // user register access
    fd_reg.ioctl(SET_SITE_MODE, &ival);
    ival = 2; // capture buffer access
    fd_cap.ioctl(SET_SITE_MODE, &ival);

    fd_reg.seek(0x30000);
    fd_cap.seek(0x30100);

    readerT.start();
    sync.wait();
}

void PicoFRIBCapture::run()
{
    Guard G(lock);
    DPRINTF(1, "Capture worker starting");
    sync.signal();

    std::vector<epicsUInt32> locbuffer;

    while(running) {
        epicsTimeStamp now;

        bool havedata = false;
        {
            UnGuard U(G);

            locbuffer.resize(4+8*5);

            DPRINTF(5, "capture entering read()\n");
            ssize_t ret;
            try {
                ret = fd_cap.read(&locbuffer[0], 4*locbuffer.size());
                DPRINTF(5, "capture return read() -> %lu\n", (unsigned long)ret);
                if((size_t)ret<16) {
                    epicsPrintf("Incomplete capture read %u\n", (unsigned)ret);
                } else {
                    havedata = true;
                }
            } catch(system_error& e){
                if(e.num!=ECANCELED)
                    epicsPrintf("capture read error '%s'\n", e.what());
            }
        }

        if(!havedata) {
            valid = false;
            epicsTimeGetCurrent(&updatetime);
            lastmsg = "I/O Error";
            {
                UnGuard U(G);
                scanIoRequest(update);
                sleep(5);
            }
            continue;
        }

        count++;

        std::ostringstream nextmsg;

        try {
            bool lastvalid = valid; // was last cycle OK?
            valid = true;

            buffer.swap(locbuffer);

            epicsTimeStamp captime;
            captime.secPastEpoch = buffer[0]-POSIX_TIME_AT_EPICS_EPOCH;
            captime.nsec         = buffer[1]/80.5e-3; // ticks of 80.5 MHz clock

            /* we don't believe the device if the captured time stamp
             * differs too much from the host.
             */
            double diff = epicsTimeDiffInSeconds(&now, &captime);
            if(fabs(diff)>picoSlewLimit) {
                nextmsg<<"time slew "<<std::setprecision(3)<<diff*1e3<<" ms, ";
                valid = false;
            }

            if(lastvalid) {
                diff = epicsTimeDiffInSeconds(&captime, &updatetime);
                /* Difference with last valid capture is too large */
                if(captime.secPastEpoch==updatetime.secPastEpoch &&
                   captime.nsec==updatetime.nsec) {
                    nextmsg<<"same time, ";
                    valid = false;
                }
                if(fabs(diff-picoStepDiff)>picoStepLimit) {
                    nextmsg<<"time step "<<std::setprecision(3)<<diff*1e3<<" ms, ";
                    valid = false;
                }
            }

            if(debug_lvl>=5) {
                fprintf(stderr, "Capture record\n");
                size_t i;
                for(i=0; i<buffer.size(); i++) {
                    if(i%4==0)
                        fprintf(stderr, "%04x : ", (unsigned)i);
                    fprintf(stderr, "%08x ", (unsigned)buffer[i]);
                    if(i%4==3)
                        fprintf(stderr, "\n");
                }
                if(i%4!=3)
                    fprintf(stderr, "\n");
            }

            /* if HW time isn't availble, use host time so that INVALID
             * updates can be archived.
             */
            if(valid)
                updatetime = captime;
            else
                updatetime = now;

        }catch(std::exception& e){
            errlogPrintf("Exception in capture run: \"%s\"\n", e.what());
            nextmsg<<"except \""<<e.what()<<"\", ";
            valid = false;
        }

        scanIoRequest(update);

        std::string nextmsg_s = nextmsg.str();
        if(nextmsg_s!=lastmsg) {
            nextmsg_s.swap(lastmsg);
            scanIoRequest(msgupdate);
        }
        if(!lastmsg.empty())
            DPRINTF(1, "Capture message: \"%s\"\n", lastmsg.c_str());

    }

    DPRINTF(1, "Capture worker stopping");
}

#endif // BUILD_FRIB

const char *
system_error::what() const throw()
{
    return strerror(num);
}

#include <epicsExport.h>

epicsExportAddress(double, picoSlewLimit);
epicsExportAddress(double, picoStepDiff);
epicsExportAddress(double, picoStepLimit);
