#! /usr/bin/env python3

""" EEPROM Dumper based on the picogains utility by CAENEls """

import os
import time
import mmap
import struct
import argparse

_ADDR_EEPROM0_CONTROLLER = 0x200
_ADDR_EEPROM1_CONTROLLER = 0x300
_EC_ADDR_STATUS  = 0x0
_EC_ADDR_CONTROL = 0x4
_EC_ADDR_ADDRESS = 0x8
_EC_ADDR_WR_DATA = 0xC
_EC_ADDR_RD_DATA = 0x10

class Pico(object):

    def __init__(self, bar0_path, eeprom):
        self._ADDR_EEPROM_CONTROLLER = eeprom
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

    def read(self, addr):
        data = 0
        self._write_address(addr)
        self._start_operation(read=True)
        time.sleep(0.005)
        data = self._get_read_data()
        self._clear_status_done()
        return data

def dump_eeprom(path):
    for e in (_ADDR_EEPROM0_CONTROLLER, _ADDR_EEPROM1_CONTROLLER):
        pico = Pico(path, e)
        step = 16

        # Assume EEPROM is 512 bytes wide
        for addr in range(0, 0x200, step):
            values = [pico.read(addr + i) for i in range(step)]
            prefix = "EEPROM 0x%03X ADDR 0x%03X = " % (e, addr)
            values_str = ("%02X "*step) % tuple(values)
            print(prefix + values_str)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Pico8 EEPROM Dumper')
    parser.add_argument('addr', type=str, help="PCI Address. Example: 0000:06:00.0")

    args = parser.parse_args()

    dump_eeprom('/sys/bus/pci/devices/'+args.addr+'/resource0')
