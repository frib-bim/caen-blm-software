/*
 * This software is Copyright by the Board of Trustees of Michigan
 * State University (c) Copyright 2016.
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

void FDHelper::open(const char *name)
{
    if(fd!=-1) close();
    fd = ::open(name, O_RDWR);
    int err = errno;
    if(fd==-1)
        throw system_error(SB()<<"Failed to open '"<<name<<"' error ",err);

    try {
        uint32_t ival=0;
        this->ioctl(GET_VERSION, &ival);
        if(ival!=GET_VERSION_CURRENT)
            throw std::runtime_error(SB()<<"Kernel ABI version mis-match "<<ival<<"!="<<GET_VERSION_CURRENT);
    } catch(...) {
        close();
        throw;
    }
}

void FDHelper::close()
{
    if(fd==-1) return;
    int ret;
    do {
        ret = ::close(fd);
    } while(ret==-1 && errno==EINTR);
    int err = errno;
    if(ret==-1)
        std::cerr<<"Warning: close("<<fd<<") -> "<<strerror(err);
    fd = -1;
}

void FDHelper::ioctl(long req, long arg)
{
    int ret;
    do {
        ret = ::ioctl(fd, req, arg);
    } while(ret==-1 && errno==EINTR);
    int err = errno;
    if(ret==-1)
        throw system_error(SB()<<"ioctl("<<req<<") -> ", err);
}

void FDHelper::ioctl(long req, void *arg)
{
    int ret;
    do {
        ret = ::ioctl(fd, req, arg);
    } while(ret==-1 && errno==EINTR);
    int err = errno;
    if(ret==-1)
        throw system_error(SB()<<"ioctl("<<req<<") -> ", err);
}

off_t FDHelper::seek(off_t o, int w)
{
    off_t ret;
    do {
        ret = ::lseek(fd, o, w);
    } while(ret==(off_t)-1 && errno==EINTR);
    int err = errno;
    if(ret==(off_t)-1)
        throw system_error(SB()<<"seek("<<o<<","<<w<<") -> ", err);
    return ret;
}

ssize_t FDHelper::write(const void *buf, size_t cnt)
{
    ssize_t ret;
    do {
        ret = ::write(fd, buf, cnt);
    } while(ret==-1 && errno==EINTR);
    int err = errno;
    if(ret==-1)
        throw system_error(SB()<<"write("<<buf<<","<<cnt<<") -> ", err);
    return ret;
}

ssize_t FDHelper::read(void *buf, size_t cnt)
{
    ssize_t ret;
    do {
        ret = ::read(fd, buf, cnt);
    } while(ret==-1 && errno==EINTR);
    int err = errno;
    if(ret==-1)
        throw system_error(SB()<<"read("<<buf<<","<<cnt<<") -> ", err);
    return ret;
}

ssize_t FDHelper::write(const void *buf, size_t cnt, off_t o)
{
    ssize_t ret;
    do {
        ret = ::pwrite(fd, buf, cnt, o);
    } while(ret==-1 && errno==EINTR);
    int err = errno;
    if(ret==-1)
        throw system_error(SB()<<"pwrite("<<buf<<","<<cnt<<","<<o<<") -> ", err);
    return ret;
}

ssize_t FDHelper::read(void *buf, size_t cnt, off_t o)
{
    ssize_t ret;
    do {
        ret = ::pread(fd, buf, cnt, o);
    } while(ret==-1 && errno==EINTR);
    int err = errno;
    if(ret==-1)
        throw system_error(SB()<<"pread("<<buf<<","<<cnt<<","<<o<<") -> ", err);
    return ret;
}
