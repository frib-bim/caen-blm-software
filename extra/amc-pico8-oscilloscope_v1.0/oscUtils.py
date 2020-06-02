#!/usr/bin/env python3
# -*- coding: utf-8 -*-

''' Various oscilloscope utility functions.

Copyright (C) 2015 CAEN ELS d.o.o.

'''

import numpy as np


def _toSIstringSingle(x, prec):
    if np.isnan(x):
        return 'NaN'

    if np.abs(x) < 10e-24:
        return '0'

    exp = np.log10(np.abs(x))
    exp3 = int(np.floor(exp / 3))
    siSel = exp3 + 8
    _SI = ['y', 'z', 'a', 'f', 'p', 'n', 'u', 'm', '', 'k', 'M', 'G', 'T']

    m = x / 10 ** (exp3 * 3)

    strFmt = '%.' + str(prec) + 'f'
    return strFmt % m + ' ' + _SI[siSel]


def toSIstring(x, prec=3):
    ''' Converts numbers or arrays of numbers to string in SI notation
    '''

    if isinstance(x, (int, float)):
        return _toSIstringSingle(x, prec)
    else:
        return [_toSIstringSingle(xi, prec) for xi in x]


def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i:i + n]


def wind_avg(x, n):
    ''' Window avergaing on an numpy array '''
    if n == 1:
        return x
    else:
        return [np.sum(xi) / float(n) for xi in chunks(x, n)]


if __name__ == '__main__':
    print(toSIstring(1e-18, 2))
    print(toSIstring(1e-8, 5))
    print(toSIstring(1e7))
    print(toSIstring(-1e7))
    print(toSIstring(0))
