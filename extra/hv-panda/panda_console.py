#! /usr/bin/env python2

# -*- coding: utf-8 -*-
"""
@author: jan
"""

import mmap
import numpy as np
import os
import re
import struct
import sys
import threading
# from PyQt4 import QtGui, uic
# from PyQt4.QtCore import QThread, pyqtSlot, pyqtSignal


def getScriptPath():
    return os.path.dirname(os.path.realpath(sys.argv[0]))

###############################################################################
class PandaDriver():
    ''' Class for interfacing with panda board through PCIe '''

    maxV = [4000, 4000, 4000, 4000]
    _VEN_ID = 0x1172
    _DEV_ID = 0x1234

    def __init__(self):
        print 'Panda Interfaca init'

        '''
        # run as sudo
        euid = os.geteuid()
        if euid != 0:
            print "Script not started as root. Running sudo.."
            args = ['sudo', sys.executable] + sys.argv + [os.environ]
            # the next line replaces the currently-running process with the sudo
            os.execlpe('sudo', *args)

        print 'Running. Your euid is', euid
        '''

        # pylint: disable=bad-builtin
        PATHS    = self.get_paths()
        VEN_DEV  = map(self.get_vendor_device, PATHS)
        DEVS     = zip(VEN_DEV, PATHS)

        self.OUR_DEVS = filter(self.is_our_device_filter, DEVS)
        self.regDict  = self.createRegDict()
        print self.regDict

        if len(self.OUR_DEVS) > 0:
            self.mem = self.createMmaping(self.OUR_DEVS[0],
                                          self.regDict['WATCHDOG'][1])


    #==========================================================================
    def get_paths(self):
        ''' Gets all PCI(e) device paths '''

        _paths = []

        for dirname, dirnames, _ in os.walk('/sys/bus/pci/devices'):
            # Get all devices path
            for subdirname in dirnames:
                _paths.append( os.path.join(dirname, subdirname) )

        return _paths


    def get_vendor_device(self, path):
        ''' Get tuple of vendor id and device id given the device path'''
        with open(path+'/vendor','r') as filename:
            vendor = int(filename.read().strip(), 0)

        with open(path+'/device','r') as filename:
            device = int(filename.read().strip(), 0)

        return (vendor, device)


    def is_our_device(self, our_vendor, our_device, dev):
        ''' dev: (vendor, device) '''
        vendor, device = dev

        return (our_device == device) and (our_vendor == vendor)


    def is_our_device_filter(self, vdp):
        ''' Returns true for our devices '''
        dev, _ = vdp
        return self.is_our_device(self._VEN_ID, self._DEV_ID, dev)


    #==========================================================================
    def createRegDict(self):
        _MAP_FILENAME = getScriptPath() + '/panda.map'

        f = open(_MAP_FILENAME, 'r')

        _regDict = {}

        for line in f:
            line = line.strip()

            if len(line) == 0 or line[0] == '#':
                continue

            # Replace tabs with spaces
            line = line.replace('\t', ' ')
            oldLine = ''

            # Replace all multiple spaces with single spaces
            while line != oldLine:
                oldLine = line
                line    = line.replace('  ', ' ')


            lineArray = line.split(' ')

            if (len(lineArray) != 8):
                continue

            # create dictionary with (address, BAR) tuple
            _regDict[lineArray[0]]=(int(lineArray[2], 0), int(lineArray[4], 0))

        return _regDict

    #==========================================================================
    def createMmaping(self, dev, barNr):
        _path = dev[1]+'/resource'+str(barNr)
        print _path
        _fno = os.open(_path, os.O_RDWR | os.O_SYNC)

        _mem = mmap.mmap(fileno = _fno,
                 length = 4096,
                 flags  = mmap.MAP_SHARED,
                 prot   = mmap.PROT_READ | mmap.PROT_WRITE,
                 offset = 0)

        return _mem
        #a = _mem[regDict['WATCHDOG'][0]:regDict['WATCHDOG'][0]+4]

    def getReg(self, name):
        r = self.mem[self.regDict[name][0]:self.regDict[name][0]+4]
        return struct.unpack('<I', r)[0]

    def setReg(self, name, value):
        v = struct.pack('<I', value)
        self.mem[self.regDict[name][0]:self.regDict[name][0]+4] = v

    #==========================================================================
    def get_max(self, ch):
        ''' Gets HV channel model '''
        return self.maxV[ch]

    def get_vset(self, ch):
        ''' Gets HV channel setpoint  '''
        regName = 'CH' + str(ch+1) + '_V_SET'
        r = self.getReg(regName) / 10.0
        return r

    def set_vset(self, ch, value):
        ''' Sets HV channel setpoint  '''
        regName = 'CH' + str(ch+1) + '_V_SET'
        self.setReg(regName, value*10.0)

    def get_vmon(self, ch):
        ''' Gets HV voltage monitor '''
        regName = 'CH' + str(ch+1) + '_V_MON'
        r = self.getReg(regName) / 10.0
        return r

    def get_imon(self, ch):
        ''' Gets HV current monitor '''
        regName = 'CH' + str(ch+1) + '_I_MON'
        r = self.getReg(regName)
        return r

    def get_enabled(self, ch):
        regName = 'CH' + str(ch+1) + '_STATUS'
        r = self.getReg(regName)
        return (r & 0x1) == 0x1

    def set_enabled(self, ch, value):
        ''' Gets HV channel setpoint  '''
        regName = 'CH' + str(ch+1) + '_CTRL'
        if value:
            self.setReg(regName, 1)
        else:
            self.setReg(regName, 0)


pandaIf = PandaDriver()

def print_status():
    print('Status')
    print('             Ch 1   |   Ch 2   |   Ch 3   |   Ch 4   ')
    print('         +----------+----------+----------+----------+')

    # Enabled
    enabled = [pandaIf.get_enabled(ch) for ch in range(4)]
    s = ' Status  |'
    for i in range(4):
        if enabled[i]:
            s += ' Enabled  |'
        else:
            s += ' Disabled |'
    print(s)

    print('         +----------+----------+----------+----------+')
    voltages = [pandaIf.get_vmon(ch) for ch in range(4)]
    s = ' Voltage |'
    for i in range(4):
        s += ' {0:>8.2f} |'.format(voltages[i])

    print(s)

    print('         +----------+----------+----------+----------+')
    currents = [pandaIf.get_imon(ch) for ch in range(4)]
    s = ' Current |'
    for i in range(4):
        s += ' {0:>8.2f} |'.format(currents[i])
    print(s)
    print('         +----------+----------+----------+----------+')


def enable_disable_channel():
    print('Enable/disable channel')
    ch = raw_input('  Channel(1-4) ? ')
    try:
        ch_int = int(ch)
    except:
        print('Channel selction is not a number')

    if ch_int > 0 and ch_int < 5:
        pass
    else:
        print('Invalid channel selected')

    en = raw_input('  Enable (1=yes, 0=no)? ')
    try:
        en_int = int(en)
    except:
        print('Enable selction is not a number')

    # print('Enable: '+str(ch) + str(not not en_int))
    pandaIf.set_enabled(ch_int, en_int)

def set_voltage():
    print('Set voltage')
    ch = raw_input('  Channel(1-4) ? ')
    try:
        ch_int = int(ch)
    except:
        print('Channel selction is not a number')

    if ch_int > 0 and ch_int < 5:
        pass
    else:
        print('Invalid channel selected')

    v = raw_input('  Voltage[V] ? ')
    try:
        v_float = float(v)
    except:
        print('Voltage is not a number')

    # print('Set voltage: '+str(ch) + ', ' + str(v_float))
    pandaIf.set_vset(ch_int, v_float)



COMMAND_LIST = \
'''
###########################################################
Command list:
  [s] Print status
  [e] Enable/disable channel
  [v] Set voltage
  [q] Quit
Command? '''
###############################################################################
def main():
    while True:
        cmd = raw_input(COMMAND_LIST)
        if cmd == 'q':
            break
        elif cmd == 's':
            print_status()
        elif cmd == 'e':
            enable_disable_channel()
        elif cmd == 'v':
            set_voltage()



if __name__ == '__main__':
    main()

#