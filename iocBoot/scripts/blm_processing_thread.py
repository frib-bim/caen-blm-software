# -*- coding: utf-8 -*-
#     __________  ________
#    / ____/ __ \/  _/ __ )
#   / /_  / /_/ // // __  |
#  / __/ / _, _// // /_/ /
# /_/   /_/ |_/___/_____/
"""
Initiate from console:  python blm_processing_thread.py <picoDevPrefix1> <picoDevPrefix2> ...
@author: cogan
2019-07-11	cogan	Syntax update python2->3.  Added SLO_CSET scale factors.
"""

# Import and define common utilities, including matlab plots, math, sleep, and EPICS CA
from blm_dev_support import *
from cothread import WaitForQuit
import sys

""" Callbacks for cothread camonitor() """


def acqCBufCallback(value):
    pvname = value.name;  #  PV name
    if (value == 0):
        disp('Callback DONE: ' + pvname + ' ' + time.ctime())
        return
    disp('Callback:     ' + pvname + ' ' + time.ctime())
    dev = epicsDEV(pvname.replace("_CTRL:acqDDRwave", ""));
    numpts = dev.get("_CTRL:acqDDRnpts");  # numpts = pow(2,18);
    dat = getCBufData(dev, numpts);  # Get/process raw waveform
    #  Assign the soft channel outputs
    #  Scale by SLO (units A -> uA)
    dev.set('_CH0:DDRWV_RD', dat.ch0 * dev.get('_CH0:SLO_CSET'));
    dev.set('_CH1:DDRWV_RD', dat.ch1 * dev.get('_CH1:SLO_CSET'));
    dev.set('_CH2:DDRWV_RD', dat.ch2 * dev.get('_CH2:SLO_CSET'));
    dev.set('_CH3:DDRWV_RD', dat.ch3 * dev.get('_CH3:SLO_CSET'));
    dev.set('_CH4:DDRWV_RD', dat.ch4 * dev.get('_CH4:SLO_CSET'));
    dev.set('_CH5:DDRWV_RD', dat.ch5 * dev.get('_CH5:SLO_CSET'));
    dev.set('_CH6:DDRWV_RD', dat.ch6 * dev.get('_CH6:SLO_CSET'));
    dev.set('_CH7:DDRWV_RD', dat.ch7 * dev.get('_CH7:SLO_CSET'));
    dev.set('_CTRL:DDR_TIME_RD', dat.t0);
    dev.set('_CTRL:DDR_BEAMSTATW_RD', dat.beamstat);
    dev.set('_CTRL:DDR_NOKW_RD', dat.nokflags);
    dev.set('_CTRL:acqDDRwave', 0);  # This triggers another callback, so we ignore ==0 above.


""" Setup camonitor() """
for arg in sys.argv[1:]:
    disp('Setting up callback: ' + arg + "_CTRL:acqDDRwave")
    ca.camonitor(arg + "_CTRL:acqDDRwave", acqCBufCallback, format=1);

""" Process callbacks forever """
WaitForQuit();

