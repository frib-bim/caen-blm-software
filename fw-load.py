#!/usr/bin/env python

from __future__ import print_function

import logging, sys
_log = logging.getLogger(__name__)
import struct

def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('-d','--debug',action='store_true')
    P.add_argument('bitfile', help='FPGA bit file')
    P.add_argument('pv', help='Prefix of FW loading PVs')
    return P.parse_args()

def readbitfile(args):
    """
    an almost understandable header.
    0x0009 looks like a length, but doesn't include the trailing '\x00\x01'

    after the header, a single byte ID code followed by a length (16 or 32 bit) in MSB.
    ID codes are ASCII 'a', 'b', 'c', ...
    headers a..d have a 16-bit length.  header 'e' has a 32-bit length

    00000000  00 09 0f f0 0f f0 0f f0  0f f0 00 00 01 61 00 38  |.............a.8|
    00000010  46 52 49 42 52 65 63 65  69 76 65 72 5f 74 6f 70  |FRIBReceiver_top|
    00000020  2e 6e 63 64 3b 48 57 5f  54 49 4d 45 4f 55 54 3d  |.ncd;HW_TIMEOUT=|
    00000030  46 41 4c 53 45 3b 55 73  65 72 49 44 3d 30 78 46  |FALSE;UserID=0xF|
    00000040  46 46 46 46 46 46 46 00  62 00 0f 36 73 6c 78 31  |FFFFFFF.b..6slx1|
    00000050  35 30 74 66 67 67 39 30  30 00 63 00 0b 32 30 31  |50tfgg900.c..201|
    00000060  37 2f 30 33 2f 30 37 00  64 00 09 31 36 3a 30 37  |7/03/07.d..16:07|
    00000070  3a 30 37 00 65 00 40 68  b8 ff ff ff ff ff ff ff  |:07.e.@h........|
    00000080  ff ff ff ff ff ff ff ff  ff aa 99 55 66 31 e1 ff  |...........Uf1..|
    """
    info = {}
    with open(args.bitfile, 'rb') as F:
        ID = F.read(13)
        if ID !='\x00\x09\x0f\xf0\x0f\xf0\x0f\xf0\x0f\xf0\x00\x00\x01':
            raise ValueError("Unrecognised file header: %s"%repr(ID))

        while True:
            H = F.read(3)

            if len(H)==0:
                break

            if H[0:1]=='e':
                # 4 byte length for bitstream block
                H += F.read(2)
                idcode, blocklen = struct.unpack('!BI', H)
            else:
                # 2 byte length for others
                idcode, blocklen = struct.unpack('!BH', H)

            _log.debug("Read block 0x%x len 0x%x", idcode, blocklen)

            block = F.read(blocklen)

            if len(block)!=blocklen:
                raise ValueError("Error reading block 0x%x with length 0x%x"%(idcode, blocklen))

            info[idcode] = block

    return info

def loadbit(args, blob):
    from cothread import Event
    from cothread.catools import caput

    print("Load bitfile waveform")
    caput(args.pv+"bitfile", blob, wait=True)

    print("Start flash with: caput %sctrl 1"%args.pv)
    print("monior with: camonitor %ssts"%args.pv)

def main(args):
    info = readbitfile(args)
    if 0x61 in info:
        print("Built from", info.pop(0x61))
    if 0x62 in info:
        print("Target part", info.pop(0x62))
    if 0x63 in info:
        print("Build date", info.pop(0x63))
    if 0x64 in info:
        print("Build time", info.pop(0x64))

    bitstream = info.pop(0x65)
    print("bitstream", repr(bitstream[:16]))
    print("         ", repr(bitstream[16:32]))
    print('bit stream length', len(bitstream))

    if len(info):
        print("Unknown blocks")
        for K, V in info.items():
            print("Block %x"%K, repr(V[:16]), '...')

    loadbit(args, bitstream)

if __name__=='__main__':
    args = getargs()
    logging.basicConfig(level=logging.DEBUG if args.debug else logging.WARN)
    main(args)
