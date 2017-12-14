# -*- coding: utf-8 -*-
"""
BLM Device Support (beam loss monitor, CAEN PICO8) 

@author: cogan
2017-12-14  Added proper error handling for invalid data in getCBufData()
"""

# Import and define common utilities, including matlab plots, math, sleep, and EPICS CA
from scottutil import *
from epicsDEV import *


def getDDRLastAddr(dev):
    return dev.get('_CTRL:DDR_LAST_ADDR')

def getCBufData(dev,npts=100000):
    nbytes = npts*12*4;
    lastaddr = getDDRLastAddr(dev);
    startaddr = lastaddr - nbytes;
    fprintf('Start = %08X, Stop = %08X',startaddr,lastaddr);
    if (startaddr>=0):
        wave = getDDRwave(dev, startaddr, nbytes);
    else:   # startaddr is negative, wrap to end of buffer
        wave  = getDDRwave(dev, 0, lastaddr);
        wave2 = getDDRwave(dev, 256*1024*1024+startaddr, -startaddr);
        wave = append(wave2, wave);
    #  In case buffer is not at the right offset, clip the data to correct length
    idxs = find(wave==0xFFFFF81B);
    if isempty(idxs):
        disp( 'Warning: Circle Buffer data not valid.' )
        dat = struct();
        dat.ch0 = 0;
        dat.ch1 = 0;
        dat.ch2 = 0;
        dat.ch3 = 0;
        dat.ch4 = 0;
        dat.ch5 = 0;
        dat.ch6 = 0;
        dat.ch7 = 0;
        dat.t0 = 0;
        dat.beamstat = 0;
        dat.nokflags = 0;
        dat.wave = wave;
        return dat;
    if (idxs[0]==7): wave = wave[4:-8];
    if (idxs[0]==11): wave = wave[8:-4];
    return parseCBufData(wave);

#  Get raw DRAM waveforms.
#  Read chunks of 524288 bytes

def getDDRwave(dev,memOffs,nbytes=524288):
    numProcs = int(ceil(nbytes/524288.0));
    wave = [];
    for n in range(0,numProcs):
        nbytes2 = (mod(nbytes,524288) if (n==numProcs-1) else 524288);
        dev.set('_mem:Cnt-SP', nbytes2);
        dev.set('_mem:Off-SP',memOffs + n*524288);
        dev.set('_mem:Data-I.PROC',1);
        fprintf('Get DDR @ %08X to %08X',memOffs + n*524288, memOffs + n*524288+nbytes2-1)
        temp = dev.get('_mem:Data-I');
        wave = append(wave, temp);           
    if (wave.size > nbytes/4):
        wave = wave[0:uint32(nbytes/4)];
    return wave


def toInt32(x):
    return (x - pow(2,32)*(x>=pow(2,31)));
def toInt16(x):
    return (x - pow(2,16)*(x>=pow(2,15)));
def bitxor(x,y):
    z = x.copy();
    for n in range(0,size(x)):
        z[n] = uint32(x[n]) ^ uint32(y[n]);
    return z;
def bitAtW(theWord,offset,width):
    return ( (uint32(theWord) >> offset) & (pow(2,width)-1) ); # Mask bits at bit offset
def warning(msg):
    warnings.warn(msg);
def caputw(pv,val):
    caput(pv,val,wait=True);

#  Convert Circle Buffer memory readback to data struct
def parseCBufData(wave):
#   frib_ddr1 <= { 32'hFFFF_F81B, 16'h00, SAMPLE_TIMEON[7:0], fribsample_debug[3:0], reg_fps_status[3:0], reg_sample_timestamp };
#   frib_ddr2 <= {float_ch3, float_ch2, float_ch1, float_ch0};
#   frib_ddr3 <= {float_ch7, float_ch6, float_ch5, float_ch4};
    dat = struct();
    dat.t = (uint32(wave[1::12])-uint32(wave[1])) + (wave[0::12]/80.5e6);     #  Timestamps [sec]
    dat.t0 = uint32(wave[1]) + dat.t[0];
    dat.t = dat.t - dat.t[0];
    dat.time_err = 0;
    dat.nokflags = uint8(bitAtW( wave[2::12],0,3 ));    # {DAQ_NOK_LATCH, DAQ_NOK, AMC_NPERMIT}
    dat.beamstat = uint8(bitAtW( wave[2::12],4,3 ));    # { startOfCyc, wind2, wind1 }
    dat.wind1 = uint8(bitAtW( dat.beamstat,0,1 ));
    dat.wind2 = uint8(bitAtW( dat.beamstat,1,1 ));
    dat.soc = uint8(bitAtW( dat.beamstat,2,1 ));
    dat.eoc = uint8(bitAtW( dat.beamstat,3,1 ));
    dat.ton      = bitAtW(wave[2::12],8,8);
    dat.fribcode = wave[3::12];
    matches = sum(dat.fribcode==0xFFFFF81B);
    if (matches==dat.fribcode.size):
        disp(sprintf('Checksum match = %d / %d  (date=%s, local=%s)',matches,dat.fribcode.size,
            datetime.fromtimestamp(int(dat.t0)).strftime('%m-%d %H:%M:%S'), datetime.now().strftime('%H:%M:%S')))
    else:
        warning(sprintf('Checksum match = %d / %d',matches,dat.fribcode.size))
    # convert remaining wave data to floats (previously interpreted as uint32)
    whos(wave)
    dat.wave = uint32(wave);
    wave = uint32(wave);
    wave.dtype = float32;
    dat.ch0 = wave[4::12];
    dat.ch1 = wave[5::12];
    dat.ch2 = wave[6::12];
    dat.ch3 = wave[7::12];
    dat.ch4 = wave[8::12];
    dat.ch5 = wave[9::12];
    dat.ch6 = wave[10::12];
    dat.ch7 = wave[11::12];
    #  Quick check on timestamp [usec]
    minStep = min(diff(dat.t));
    maxStep = max(diff(dat.t));
    if (minStep<0.8e-6):
        dat.time_err = 1;
        warning(sprintf('Timestamp anomolies: step backwards, %.1f usec:  %s to %s',
                        minStep*1e6, datetime.fromtimestamp(int(dat.t0)).strftime('%H:%M:%S'),
                        datetime.fromtimestamp(int(dat.t0+dat.t[-1])).strftime('%m-%d %H:%M:%S')))
    if (maxStep>1.5e-6):
        dat.time_err = 1;
        warning(sprintf('Timestamp anomolies: time gap, %.1f usec:  %s to %s',
                        maxStep*1e6, datetime.fromtimestamp(int(dat.t0)).strftime('%H:%M:%S'),
                        datetime.fromtimestamp(int(dat.t0+dat.t[-1])).strftime('%H:%M:%S')))
    if (1 | dat.time_err):
        #  Add some extra timestamp info
        dat.t_sec = wave[1::16];
        dat.t_subsec = bitAtW(wave[0::16],8,24);
    #end
    return dat;


def saveBLMDat(dat,filename):
    expdat = array( [ dat.ch0, dat.ch1, dat.ch2, dat.ch3, dat.ch4, dat.ch5, dat.ch6, dat.ch7 ] ).transpose();
    savetxt(filename+".csv", expdat, delimiter=",")
