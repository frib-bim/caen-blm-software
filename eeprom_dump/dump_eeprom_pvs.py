from itertools import product
from epics import caget
import csv
from datetime import datetime

picos = [
  'DIAG_MTCA01:PICO3',
  'DIAG_MTCA01:PICO4',
  'DIAG_MTCA01:PICO5',
  'DIAG_MTCA01:PICO6',
  'DIAG_MTCA01:PICO7',
  'DIAG_MTCA01:PICO8',
  'DIAG_MTCA01:PICO9',
  'DIAG_MTCA04:PICO3',
  'DIAG_MTCA04:PICO4',
  'DIAG_MTCA15:PICO3',
  'DIAG_MTCA15:PICO4',
  'DIAG_MTCA17:PICO3',
  'DIAG_MTCA17:PICO4'
]

chans = range(8)
ranges = range(2)
params = ['EEGAIN', 'EEOFST']

with open('eeprom_%s.csv' % datetime.now().strftime("%Y-%m-%d-%H-%M-%S"), 'wb') as f:
    writer = csv.writer(f)
    writer.writerow(["PV", "Value", "Raw Value"])
    for pico, chan, rng, param in product(picos, chans, ranges, params):
        pv = "%s_CH%d:RNG%d_%s_RD" % (pico, chan, rng, param)
        val = caget(pv)
        raw = caget(pv + ".RVAL")
        writer.writerow([pv, val, raw])
