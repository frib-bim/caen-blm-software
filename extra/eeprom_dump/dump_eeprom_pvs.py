from itertools import product
from epics import caget
import csv
from datetime import datetime
import requests
import json

CHANNELFINDER='https://controls.ftc/channelfinder/resources/channels?'

url = '%s~name=DIAG_MTCA*:PICO*_CH0:RNG0_EEGAIN_RD&pvStatus=Active' % CHANNELFINDER

picos = [
    c['name'].split('_CH0')[0] 
    for c in json.loads(requests.get(url).content)
]

chans = range(8)
ranges = range(2)
params = ['EEGAIN', 'EEOFST']

filename = 'eeprom_%s.csv' % datetime.now().strftime("%Y-%m-%d-%H-%M-%S")

with open(filename, 'wb') as f:
    print("Writing results to %s" % filename)
    writer = csv.writer(f)
    writer.writerow(["PV", "Value"])
    for pico in picos:
        for chan, rng, param in product(chans, ranges, params):
            pv = "%s_CH%d:RNG%d_%s_RD" % (pico, chan, rng, param)
            val = caget(pv)
            writer.writerow([pv, val])
        print("%s done" % pico)
