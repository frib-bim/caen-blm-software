# -*- coding: utf-8 -*-
"""
Import and define common utilities, including matlab plots, math, sleep, and EPICS CA
@author: cogan

Version History
Nov 11 2017   Initial checkin
"""

# Import numpy, fft, pyplot in main namespace.
from time import sleep
from datetime import *
from pprint import *
from numpy import *                # for basic matlab-like functions
from numpy.fft import *            # for fft
from numpy.matlib import repmat    # for repmat
from scipy.signal import *         # for lfilter
from scipy.interpolate import interp1d
from matplotlib.pyplot import figure as mplfigure
from matplotlib.pyplot import *
rcParams['axes.formatter.useoffset'] = False;   # disable by default yaxis plot offsets
import time
import warnings

#  Define matlab-like functions
def figure(figure_id=None):    
    if figure_id is None:
        fig = gcf();
    else:
        # do this even if figure_id == 0
        fig = mplfigure(num=figure_id)
    fig.canvas.flush_events()
    time.sleep(0.01)
    if (os.name=="nt"):
        fig.canvas.manager.window.activateWindow();
        fig.canvas.manager.window.raise_();
    else:
        fig.canvas.manager.window.attributes('-topmost',1);
        fig.canvas.manager.window.attributes('-topmost',0);
    return fig
def imagesc(data2d):
    if not hasattr(data2d, 'ndim'):
        data2d = array(data2d);
    if data2d.ndim==1:
        data2d = [data2d];
    return imshow(data2d, aspect='auto', interpolation='none', origin='lower');
    #plt.imshow(data, aspect='auto', interpolation='none',extent=extents(x) + extents(y), origin='lower')
#  Handy FFT getter
def getfft(y, dt, norm=True, npts=None):
    Y = fft(y,n=npts);
    npts = uint32(Y.size);
    freq = fftfreq(npts, dt);
    freq = freq[0:uint32(npts/2)];
    Y = Y[0:uint32(npts/2)];
    if norm:
        Y = 20*log10(abs(Y)*2/npts);
    return Y, freq
#  Cuz I refuse to learn this basic python string format syntax.
def sprintf(fmt, *args):
    buf = fmt % args
    return buf
def fprintf(fmt, *args):
    print(fmt % args)
def warning(warnstr):
    warnings.warn(warnstr)
def find(tstval):
    return where(tstval)[0]
def isempty(val):
    return (val.size==0);
def inputstr(prompt=""):
    sys.stdout.flush();  # to be safe, must flush stdout before prompt
    return input(prompt)
def pause(secs=-1):
    if (secs<0):
        inputstr("[Press Enter]");
    else:
        time.sleep(secs);
def tic():
    global tictime0
    tictime0 = datetime.now()
def toc():
    global tictime0
    deltat = datetime.now() - tictime0;
    return deltat.total_seconds();
def caputw(pv,val):
    caput(pv,val,wait=True);
def whos(var):
    typ = type(var);
    if (type.__str__(typ)=="<class '__main__.struct'>"):
        pprint(var.__dict__)
        return
    nel = var.size;
    sz = var.shape;
    if (nel==1):
        fprintf('Type=%15s  Size = %d ',type(var),nel)
    elif (var.ndim==1):
        fprintf('%15s of %15s  Size = %d  (%d x %d)',type(var),type(var[0]),nel,sz[0],1)
    elif (var.ndim==2):
        fprintf('%15s of %15s  Size = %d  (%d x %d)',type(var),type(var[0]),nel,sz[0],sz[1])
    elif (var.ndim==3):
        fprintf('%15s of %15s  Size = %d  (%d x %d x %d)',type(var),type(var[0]),nel,sz[0],sz[1],sz[2])
def dec2hex(dec,width=0):
    if (type(dec) == ndarray):
        str = '';
        for d in dec:
            str += dec2hex(d) + sprintf('\n');
        return str
    if (type(dec) == float64): dec=uint32(dec);
    if (width==0):
        fmt = "%X";
    else:
        fmt = "%%0%dX" % width
    return fmt % dec
def fread(filepath,dtype=uint8):
    return fromfile(filepath,dtype);
#  Save dat struct, with column headers
def savedat(dat,filename):
    expdat = array( [ dat.I1, dat.Q1, dat.I2, dat.Q2, dat.I3, dat.Q3, dat.I4, dat.Q4 ] ).transpose();
    savetxt(filename+".csv", expdat, delimiter=",",header="I1,Q1,I2,Q2,I3,Q3,I4,Q4")

#  Simple struct class MATLAB-like, type is scottutil.struct
class struct():
    pass

"""
EPICS Channel Access support  (caget/caput)
"""
from epicsDEV import *
