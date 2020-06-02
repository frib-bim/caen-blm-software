# -*- coding: utf-8 -*-
#     __________  ________ 
#    / ____/ __ \/  _/ __ )
#   / /_  / /_/ // // __  |
#  / __/ / _, _// // /_/ / 
# /_/   /_/ |_/___/_____/  
"""
Easier EPICs instruments.  Wrapper class for EPICS channel access.
Uses cothread on Linux, pyepics on Windows
@author: cogan

Version History
2017-11-11   Initial checkin
2018-01-17   Increased EPICS_CA_MAX_ARRAY_BYTES to 128MB
2018-01-30   Set default EPICS CA timeout = 1.0 sec
"""
import os
os.environ['EPICS_CA_MAX_ARRAY_BYTES'] = '128000800'; # 128MB max
if os.name=='nt':
    # For WINDOWS, use pyepics, and must list IP for all CA servers:
    os.environ['EPICS_CA_ADDR_LIST'] = 'mtcacpu01 mtcacpu03 localhost:15064';
    os.environ['EPICS_CA_AUTO_ADDR_LIST'] = 'Yes';
    import epics as ca
    from epics import caput, caget
else:
    # For LINUX, use cothread:
    import cothread.catools as ca
    from cothread.catools import caput, caget
    
class epicsDEV(object):

    def __init__(self, m_inst=''):
        self.m_inst = m_inst
        self.m_version = 1.03

    def get(self, PV, timeout=1.0):
        """ caget wrapper """
        PV = self.m_inst + PV;
        return ca.caget(PV,timeout=timeout)
        
    def getU(self, PV, timeout=1.0):
        """ caget wrapper, interpret as UINT32 """
        PV = self.m_inst + PV;
        return ((ca.caget(PV, timeout=timeout)+pow(2,32)) % pow(2,32))
    
    def getWave(self, PV, timeout=1.0):
        """ caget wrapper (expects waveform) """
        PV = self.m_inst + PV;
        return ca.caget(PV, timeout=timeout)
    
    def set(self, PV, val):
        """ caput wrapper, waits for completion """
        PV = self.m_inst + PV;
        return ca.caput(PV,val,wait=True)

    def setU(self, PV, val):
        """ caput wrapper, waits for completion, expects unsigned """
        PV = self.m_inst + PV;
        return ca.caput(PV,val,wait=True)
