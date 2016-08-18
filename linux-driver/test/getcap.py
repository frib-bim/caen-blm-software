#!/usr/bin/env python

import numpy, struct, sys, os
import fcntl, sys, ctypes, array, time

# this module is generated with gen_py
import picodefs as defs

def getargs():
    import argparse
    P = argparse.ArgumentParser()
    P.add_argument('devfile', help='A /dev/amc_pico_* path')
    P.add_argument('outfile', help='Name of .npy file where results will be stored')
    P.add_argument('-N', '--count', type=int, default=1, help='Number of records to collect')
    return P.parse_args()

class OP(object):
    def __init__(self, args):
        self.fp = os.open(args.devfile, os.O_RDWR)
        A = array.array('I', [42])

        fcntl.ioctl(self.fp, defs.GET_VERSION, A, 1)
        if A[0]!=defs.GET_VERSION_CURRENT:
            raise RuntimeError("Kernel module ABI mismatch %s %s"%(A[0], defs.GET_VERSION_CURRENT))

        fcntl.ioctl(self.fp, defs.GET_SITE_ID, A, 1)
        if A[0]!=defs.USER_SITE_FRIB:
            raise RuntimeError("Not FRIB firmware %x"%A[0])

        fcntl.ioctl(self.fp, defs.GET_SITE_VERSION, A, 1)
        if A[0]!=0:
            sys.stderr.write('FRIB version is %s'%A[0])

        A[0] = 2 # set to capture buffer
        fcntl.ioctl(self.fp, defs.SET_SITE_MODE, A)
        os.lseek(self.fp, 0x30100, 0)

    def close(self):
        if self.fp:
            os.close(self.fp)
            self.fp = None
    __del__ = close

    def __enter__(self):
        return self
    def __exit__(self, A,B,C):
        self.close()

    def read1(self):
        B = os.read(self.fp, 1024)
        if len(B)<4:
            raise RuntimeError("No data: %s"%repr(B))
        return numpy.frombuffer(B, dtype=numpy.uint32).reshape((1,-1))

def main(args):
    with OP(args) as F:
        bufs = [None]*args.count
        for i in range(args.count):
            bufs[i] = F.read1()
            sys.stderr.write('.')
        sys.stderr.write('\n')

    bufs = numpy.concatenate(bufs, axis=0)
    numpy.save(args.outfile, bufs)

if __name__=='__main__':
    main(getargs())
