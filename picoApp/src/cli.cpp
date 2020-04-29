/*
 * This software is Copyright by the Board of Trustees of Michigan
 * State University (c) Copyright 2015.
 */
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <inttypes.h>
#include <limits.h>

#include <sstream>
#include <stdexcept>
#include <iostream>
#include <string>

#include "amc_pico.h"

namespace {
class errno_error : public std::runtime_error
{
    static
    std::string buildMsg(int en, const char *msg)
    {
        std::ostringstream strm;
        if(strm)
            strm<<msg<<" : ";
        strm<<strerror(en)<<" ("<<en<<")";
        return strm.str();
    }
public:
    errno_error(int en, const char *msg=0)
        :std::runtime_error(buildMsg(en,msg))
    {}
};

static
unsigned long tolong(const char *s)
{
    char *end = NULL;
    errno = 0;
    unsigned long ret = strtoul(s, &end, 0);
    if(!end || *end!='\0' || (ret==ULONG_MAX && errno!=0)) {
        int e = errno;
        std::ostringstream strm;
        strm << "Failed parse '"<<s<<"' : "<<strerror(e);
        throw std::runtime_error(strm.str());
    }
    return ret;
}

static
double todouble(const char *s)
{
    std::istringstream strm(s);
    double val;
    strm>>val;
    if(strm.fail() || !strm.eof())
        throw std::invalid_argument("Failed to parse real value");
    return val;
}

struct CLI
{
    int fd;
    CLI() :fd(-1) {}
    ~CLI() {
        if(fd!=-1)
            close(fd);
    }

    void open(const char *name)
    {
        fd = ::open(name, O_RDWR);
        if(fd==-1) throw errno_error(errno, "open");
    }

    template<typename A>
    A get(unsigned long req)
    {
        A result;
        if(ioctl(fd, req, &result))
            throw errno_error(errno);
        return result;
    }
    template<typename A>
    void set(unsigned long req, A val)
    {
        if(ioctl(fd, req, &val))
            throw errno_error(errno);
    }
};
}

static
void usage(char *self)
{
    std::cout<<"Usage: "<<self<<" </dev/amc_pico...> <command> [arg ...]\n"
               "Commands\n"
               "  dump\n"
               "  range <8bitmask>\n"
               "  fsamp <divider>\n"
               "  trig <D|P|N|B> <chan#> <nrsamp#> <limit>\n"
               "  dump\n"
               ;
}

int main(int argc, char *argv[])
{
    try{
        if(argc<3) {
            usage(argv[0]);
            return 1;
        }

        CLI proc;
        proc.open(argv[1]);

        std::string cmd(argv[2]);

        if(cmd=="dump") {
            std::cout<<"Version: "<<proc.get<uint32_t>(GET_VERSION)<<"\n"
                       "Ranges : "<<std::hex<<(unsigned)proc.get<uint8_t>(GET_RANGE)<<"\n"
                       "FSamp  : "<<std::dec<<proc.get<uint32_t>(GET_FSAMP)<<"\n";

        } else if(cmd=="range" && argc>=3) {
            unsigned val = tolong(argv[3]);
            proc.set<uint8_t>(SET_RANGE, val);
        } else if(cmd=="fsamp" && argc>=3) {
            unsigned val = tolong(argv[3]);
            proc.set<uint32_t>(SET_FSAMP, val);
        } else if(cmd=="trig" && argc>=6) {
            trg_ctrl S;

            switch(argv[3][0]) {
            case 'D': S.mode = trg_ctrl::DISABLED; break;
            case 'P': S.mode = trg_ctrl::POS_EDGE; break;
            case 'N': S.mode = trg_ctrl::NEG_EDGE; break;
            case 'B': S.mode = trg_ctrl::BOTH_EDGE; break;
            default:
                throw std::invalid_argument("Unknown trigger mode");
            }

            S.ch_sel = tolong(argv[4]);
            S.nr_samp = tolong(argv[5]);
            S.limit = todouble(argv[6]);

            proc.set(SET_TRG, &S);

        } else if(cmd=="ringbuf" && argc>=3) {
            proc.set<uint32_t>(SET_RING_BUF, tolong(argv[3]));
        } else if(cmd=="gate" && argc>=3) {
            proc.set<uint32_t>(SET_GATE_MUX, tolong(argv[3]));
        } else if(cmd=="conf" && argc>=3) {
            proc.set<uint32_t>(SET_CONV_MUX, tolong(argv[3]));
        } else if(cmd=="abort") {
            proc.set<int>(ABORT_READ, 0);
        } else {
            usage(argv[0]);
            std::cerr<<"Unknown command '"<<cmd<<"'\n";
            return 1;
        }

    }catch(std::exception& e){
        std::cerr<<"Error: "<<e.what()<<"\n";
        return 2;
    }
    return 0;
}
