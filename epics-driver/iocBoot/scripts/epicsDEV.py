# -*- coding: utf-8 -*-
"""
Easier EPICs instruments.  Wrapper class for EPICS channel access.
Uses cothread on Linux, pyepics on Windows
@author: cogan
"""
import os
os.environ['EPICS_CA_MAX_ARRAY_BYTES'] = '5222111'; # 5MB max
if os.name=='nt':
    # For WINDOWS, use pyepics, and must list IP for all CA servers:
    os.environ['EPICS_CA_ADDR_LIST'] = 'mtcacpu01 mtcacpu03 localhost:15064';
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

    def get(self, PV):
        """ caget wrapper """
        PV = self.m_inst + PV;
        return ca.caget(PV)
        
    def getU(self, PV):
        """ caget wrapper, interpret as UINT32 """
        PV = self.m_inst + PV;
        return ((ca.caget(PV)+pow(2,32)) % pow(2,32))
    
    def getWave(self, PV):
        """ caget wrapper (expects waveform) """
        PV = self.m_inst + PV;
        return ca.caget(PV)
    
    def set(self, PV, val):
        """ caput wrapper, waits for completion """
        PV = self.m_inst + PV;
        return ca.caput(PV,val,wait=True)

    def setU(self, PV, val):
        """ caput wrapper, waits for completion, expects unsigned """
        PV = self.m_inst + PV;
        return ca.caput(PV,val,wait=True)
