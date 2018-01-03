#! /usr/bin/env python3

import os
import os.path
import time
import mmap
import struct
import pico_test as pt
import numpy as np
#import matplotlib.pyplot as plt

_ADDR_EEPROM0_CONTROLLER = 0x200
_ADDR_EEPROM1_CONTROLLER = 0x300
_EC_ADDR_STATUS  = 0x0
_EC_ADDR_CONTROL = 0x4
_EC_ADDR_ADDRESS = 0x8
_EC_ADDR_WR_DATA = 0xC
_EC_ADDR_RD_DATA = 0x10


BAR0_PATH = '/sys/bus/pci/devices/0000:06:00.0/resource0'
DRIVER_FILE = '/dev/amc_pico'

class Pico(object):
    """docstring for Pico"""

    _ADDR_GAIN_OFFS = 0x100
    _ADDR_EEPROM_CONTROLLER = 0; #_ADDR_EEPROM0_CONTROLLER

    def __init__(self, bar0_path):
        super(Pico, self).__init__()
        self._f = None
        self._mem = None

        fd = os.open(bar0_path, os.O_RDWR)
        self._mem = mmap.mmap(fileno=fd,
                              length=4096,
                              flags=mmap.MAP_SHARED,
                              prot=(mmap.PROT_WRITE | mmap.PROT_READ),
                              offset=0
                              )

    def read_ch_param(self, ch, rng):
        ''' Returns a tupple with gain and offset as a floats '''

        addr = self._ADDR_GAIN_OFFS + ((rng*16) + ch)*4
        gain = struct.unpack('f', self._mem[addr:addr+4])[0]
        offs = struct.unpack('f', self._mem[addr+8*4:addr+8*4+4])[0]
        return (gain, offs)

    def print_all_params(self):
        for rng in (0, 1):
            for ch in range(8):
                gain, offset = self.read_ch_param(ch, rng)
                print('  Range: {rng}, Ch: {ch}, Gain: {gain:1.4e}, Offset: {offs:1.4e}'
                    .format(rng=rng, ch=ch, gain=gain, offs=offset))


    def set_ch_param(self, ch, rng, gain_offset):
        gain, offset = gain_offset
        addr = self._ADDR_GAIN_OFFS + ((rng*16) + ch)*4

        print('  Setting parameter (range: {rng}, Ch: {ch}) to Gain: {gain:1.4e}, Offset: {offs:1.4e}'
            .format(rng=rng, ch=ch, gain=gain, offs=offset))

        bytes_tmp = struct.pack('f', gain)
        self._mem[addr:addr+4] = bytes_tmp

        bytes_tmp = struct.pack('f', offset)
        self._mem[addr+8*4:addr+8*4+4] = bytes_tmp

    def _read_status_done(self):
        addr = self._ADDR_EEPROM_CONTROLLER + _EC_ADDR_STATUS
        tmp = self._mem[addr:addr+4]
        tmp = struct.unpack('I', tmp)[0] & 0x1
        return tmp

    def _clear_status_done(self):
        addr = self._ADDR_EEPROM_CONTROLLER + _EC_ADDR_STATUS
        tmp = struct.pack('I', 0x1)
        self._mem[addr:addr+4] = tmp

    def _write_address(self, address):
        addr = self._ADDR_EEPROM_CONTROLLER + _EC_ADDR_ADDRESS
        tmp = struct.pack('I', address)
        self._mem[addr:addr+4] = tmp

    def _start_operation(self, read):
        addr = self._ADDR_EEPROM_CONTROLLER + _EC_ADDR_CONTROL
        tmp = 0x1 | (0x2 if read else 0x0)
        tmp = struct.pack('I', tmp)
        self._mem[addr:addr+4] = tmp

    def _get_read_data(self):
        addr = self._ADDR_EEPROM_CONTROLLER + _EC_ADDR_RD_DATA
        tmp = self._mem[addr:addr+4]
        tmp = struct.unpack('I', tmp)[0]
        return tmp

    def _set_write_data(self, data):
        addr = self._ADDR_EEPROM_CONTROLLER + _EC_ADDR_WR_DATA
        tmp = struct.pack('I', data)
        self._mem[addr:addr+4] = tmp

    def _get_write_data(self):
        addr = self._ADDR_EEPROM_CONTROLLER + _EC_ADDR_WR_DATA
        tmp = self._mem[addr:addr+4]
        tmp = struct.unpack('I', tmp)[0]
        return tmp

    def read_byte(self, addr):
        print('Status done:', self._read_status_done())
        self._write_address(addr)

        self._start_operation(read=True)
        print('Status done:', self._read_status_done())

        time.sleep(0.01)
        print('Status done:', self._read_status_done())
        print('Read data:', hex(self._get_read_data()))

        self._clear_status_done()
        print('Status done:', self._read_status_done())
        return None

    def read_float(self, addr):
        # Read 4 bytes, pack into float
        data = [0,0,0,0];
        for n in range(4):
            self._write_address(addr+n)
            self._start_operation(read=True)
            time.sleep(0.01)
            data[n] = self._get_read_data();
            self._clear_status_done()
        #  Join bytes into float
        data.reverse();
        b = ''.join(chr(i) for i in data)
        float_val = struct.unpack('>f', b)
        return float_val[0]
        
    def read_uint32(self, addr):
        # Read 4 bytes, pack into float
        data = [0,0,0,0];
        for n in range(4):
            self._write_address(addr+n)
            self._start_operation(read=True)
            time.sleep(0.01)
            data[n] = self._get_read_data();
            self._clear_status_done()
        #  Join bytes into float
        data.reverse();
        b = ''.join(chr(i) for i in data)
        uint_val = struct.unpack('>I', b)
        return uint_val[0]
        
#  End of class

def default_gains_offset():
    ''' Sets all gains to 1, all offsets to 0 '''

    params = {
        0: {
            0: (1.0, 0.0),
            1: (1.0, 0.0),
            2: (1.0, 0.0),
            3: (1.0, 0.0),
            4: (1.0, 0.0),
            5: (1.0, 0.0),
            6: (1.0, 0.0),
            7: (1.0, 0.0),
        },
        1: {
            0: (1.0, 0.0),
            1: (1.0, 0.0),
            2: (1.0, 0.0),
            3: (1.0, 0.0),
            4: (1.0, 0.0),
            5: (1.0, 0.0),
            6: (1.0, 0.0),
            7: (1.0, 0.0),
        }
    }

    pico = Pico(BAR0_PATH)

    for rng in (0, 1):
        for ch in range(8):
            gain_offset = params[rng][ch]
            pico.set_ch_param(ch, rng, gain_offset)

    pico.print_all_params()

def printall():
    ''' Prints all gains and offsets '''

    pico = Pico(BAR0_PATH)
    pico.print_all_params()


def update():
    ''' Update gains and offsets '''

    pico = Pico(BAR0_PATH)
    
    rng = int(input("Enter RANGE: "))
    ch  = int(input("Enter CHAN (0-7): "))
    gain   = float(input("Enter GAIN: "))
    offset = float(input("Enter OFFSET: "))
    print('  Setting parameter (range: {rng}, Ch: {ch}) to Gain: {gain:1.4e}, Offset: {offs:1.4e}'
        .format(rng=rng, ch=ch, gain=gain, offs=offset))
    gain_offset = (gain, offset);
    pico.set_ch_param(ch, rng, gain_offset)
    pico.print_all_params()

def printeeprom():
    # 0xCD  Magic number 0 (0xCAE2E150)  50 e1 e2 ca 
    # 0xD1  Magic number 1 (0xF22C71C0)  c0 71 2c f2 
    # 0xD5  RNG #0, CH #0 Gain (IEEE754 float)  90 e4 04 31 
    # 0xD9  RNG #0, CH #0 Offset (IEEE754 float)  bd 89 98 32 
    # 0xDD  RNG #0, CH #1 Gain (IEEE754 float)  ea e1 04 31 
    # 0xE1  RNG #0, CH #1 Offset (IEEE754 float)  d4 65 50 b3 
    # 0xE5  RNG #0, CH #2 Gain (IEEE754 float)  4b e1 04 31 
    # 0xE9  RNG #0, CH #2 Offset (IEEE754 float)  fc 50 0c 32 
    # 0xED  RNG #0, CH #3 Gain (IEEE754 float)  9d e1 04 31 
    # 0xF1  RNG #0, CH #3 Offset (IEEE754 float)  7f d1 cd b2 
    # 0xF5  RNG #1, CH #0 Gain (IEEE754 float)  47 72 0c 2c 
    # 0xF9  RNG #1, CH #0 Offset (IEEE754 float)  4d be b0 2c 
    # 0xFD  RNG #1, CH #1 Gain (IEEE754 float)  f4 6d 0c 2c 
    # 0x101  RNG #1, CH #1 Offset (IEEE754 float)  85 54 87 ae 
    # 0x105  RNG #1, CH #2 Gain (IEEE754 float)  f3 6d 0c 2c 
    # 0x109  RNG #1, CH #2 Offset (IEEE754 float)  1e a2 81 ac 
    # 0x10D  RNG #1, CH #3 Gain (IEEE754 float)  1b 71 0c 2c 
    # 0x111  RNG #1, CH #3 Offset (IEEE754 float)  c3 3d 14 ae 
    # 0x115  Calibration timestamp (UNIX time)  c8 84 af 55 
    # 0x119  Hardware revision (2.1)  01 02 00 00 
    pico = Pico(BAR0_PATH)
    gain_r0 = [0,0,0,0,0,0,0,0];
    offs_r0 = [0,0,0,0,0,0,0,0];
    gain_r1 = [0,0,0,0,0,0,0,0];
    offs_r1 = [0,0,0,0,0,0,0,0];
    pico._ADDR_EEPROM_CONTROLLER = _ADDR_EEPROM1_CONTROLLER
    fmc1_magic0 = pico.read_uint32(0xcd)
    fmc1_magic1 = pico.read_uint32(0xd1)
    fmc1_caltim = pico.read_uint32(0x115)
    fmc1_hwrev  = pico.read_uint32(0x119)
    for i in range(4):
        gain_r0[i] = pico.read_float(0xd5 + i*8)
        offs_r0[i] = pico.read_float(0xd5 + i*8+4)
    for i in range(4):
        gain_r1[i] = pico.read_float(0xf5 + i*8)
        offs_r1[i] = pico.read_float(0xf5 + i*8+4)
    pico._ADDR_EEPROM_CONTROLLER = _ADDR_EEPROM0_CONTROLLER
    fmc0_magic0 = pico.read_uint32(0xcd)
    fmc0_magic1 = pico.read_uint32(0xd1)
    fmc0_caltim = pico.read_uint32(0x115)
    fmc0_hwrev  = pico.read_uint32(0x119)
    for i in range(4):
        gain_r0[i+4] = pico.read_float(0xd5 + i*8)
        offs_r0[i+4] = pico.read_float(0xd5 + i*8+4)
    for i in range(4):
        gain_r1[i+4] = pico.read_float(0xf5 + i*8)
        offs_r1[i+4] = pico.read_float(0xf5 + i*8+4)

    print('  FMC1 magic0: 0x{num:08X}'.format(num=fmc1_magic0))
    print('  FMC1 magic1: 0x{num:08X}'.format(num=fmc1_magic1))
    print('  FMC1 cal-time: 0x{cal:08X} hw-vers: 0x{ver:08X}'.format(cal=fmc1_caltim,ver=fmc1_hwrev))
    print('  FMC0 magic0: 0x{num:08X}'.format(num=fmc0_magic0))
    print('  FMC0 magic1: 0x{num:08X}'.format(num=fmc0_magic1))
    print('  FMC0 cal-time: 0x{cal:08X} hw-vers: 0x{ver:08X}'.format(cal=fmc0_caltim,ver=fmc0_hwrev))
                
    for rng in (0, 1):
        for ch in range(8):
            if (rng==0):
                gain, offset = gain_r0[ch], offs_r0[ch]
            else:
                gain, offset = gain_r1[ch], offs_r1[ch]
            print('  Range: {rng}, Ch: {ch}, Gain: {gain:1.4e}, Offset: {offs:1.4e}'
                .format(rng=rng, ch=ch, gain=gain, offs=offset))


def main():
    print('CAENels AMC-Pico8 calibration script')

    #default_gains_offset()
    print('========= FPGA Values =============')
    printall()
    print('========= EEPROM Values =============')
    printeeprom()

if __name__ == '__main__':
    main()
