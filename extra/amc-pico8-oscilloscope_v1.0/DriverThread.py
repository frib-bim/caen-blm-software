# -*- coding: utf-8 -*-

''' Task to handle communication with driver.

Copyright (C) 2015 CAEN ELS d.o.o.

'''

from PyQt5.QtCore import *
import numpy as np

import DriverInterface as di


class DriverThread(QThread):
    ''' Communciation between Oscilloscope GUI and AMC-Pico8 Linux driver '''

    newDataAvailable = pyqtSignal(np.ndarray)

    def __init__(self):
        super(DriverThread, self).__init__()
        self.interval_ms = 1000
        self.exiting = False
        self.nr_samp = 10000
        self.drv = di.DriverInterface('/dev/amc_pico', debug=False)

    def __del__(self):
        # print('DriverThread __del__')
        self.wait()

    @pyqtSlot()
    def setExiting(self):
        ''' Qt Slot to gracefully terminate thread. '''
        self.exiting = True

    @pyqtSlot(int)
    def set_nr_samp(self, nr_samp):
        self.nr_samp = nr_samp

    @pyqtSlot(str)
    def set_nr_samp(self, nr_samp):
        # print('set_nr_samp', nr_samp)
        self.nr_samp = int(nr_samp, 0)

    @pyqtSlot(float)
    def change_samp_freq(self, samp_freq):
        self.drv.set_fsamp(samp_freq)

    @pyqtSlot(int)
    def change_ranges(self, rngs):
        # print('Changing ranges, captain!')
        # print('Ranges', hex(rngs))
        self.drv.set_range(rngs)

    @pyqtSlot(int)
    def change_gate_mux(self, sel):
        # print('change_gate_mux slot')
        self.drv.set_gate_mux(sel)

    @pyqtSlot(int)
    def change_conv_mux(self, sel):
        # print('change_conv_mux slot')
        self.drv.set_conv_mux(sel)

    @pyqtSlot(int)
    def change_ring_buf(self, nr_samp):
        # print('change_ring_buf slot', nr_samp)
        self.drv.set_ring_buf(nr_samp)

    @pyqtSlot(int, float, int, int)
    def change_trigger_conf(self, mode, level, length, channel):
        # print('change_trigger_conf slot', mode, level, length, channel)
        self.drv.set_trigger(level, channel, length, mode)

    def run(self):
        ''' Infinite loop with sleep() to not overload the processor. '''
        while not self.exiting:
            self.msleep(self.interval_ms)
            # print('Hello from DriverThread while loop')

            data = self.drv.read(self.nr_samp).T
            self.newDataAvailable.emit(data)
