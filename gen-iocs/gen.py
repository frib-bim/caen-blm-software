import xlrd
import os
from collections import defaultdict
from jinja2 import Environment, FileSystemLoader
import sys

source = 'Diagnostics Rack Wiring.xlsx'

class MTCA:
    def __init__(self, rack, mtca):
        self.rack = rack
        self.mtca = mtca
        self.cards = {}

    def __repr__(self):
        return 'MTCA(%s rack=%s, cards: %r)' % (self.mtca, self.rack,
                                                self.cards.__repr__())

class Pico:
    def __init__(self, slot):
        self.slot = slot
        self.chans = {}
        self.addr = {
            2: '0e', 3: '08', 4: '06', 5: '09',
            6: '0b', 7: '0f', 8: '0d', 9: '07',
            10: '05', 11: '0a' }[slot]

    def __repr__(self):
        return self.chans.__repr__()

class PicoChannel:
    def __init__(self, chan, dev):
        self.chan = chan
        self.dev = dev

    def __repr__(self):
        return 'PicoCh(%s)' % (self.dev,)

wb = xlrd.open_workbook(source, on_demand=True)
racks = [sheet for sheet in wb.sheet_names() if '_N' in sheet]
mtca = {}

def get_mtca_map():
    mtca = {}

    for rack in racks:
        ws = wb.sheet_by_name(rack)
        header = ws.row_values(2)

        cols = ('Lattice Beamline Location',
                'Device Type', 'Function',
                'MTCA Chassis', 'MTCA Slot', 'PICO Port')

        # All columns must be present in this sheet
        if not set(cols).issubset(set(header)):
            continue

        # Read data columns
        values = zip(*[ws.col_values(header.index(c), 3) for c in cols])

        # Filter out incomplete data
        values = [v for v in values if all(v)]

        # Put data in dictionary
        for loc, dev_type, dev_func, chassis, slot, port in values:
            chassis = '%02d' % int(chassis)
            slot = int(slot)
            ch = int(port[2])
            if dev_type in ("bias","ground"):
                continue

            m = mtca.get(chassis)
            if m is None:
                m = mtca[chassis] = MTCA(rack, chassis)

            c = m.cards.get(slot)
            if c is None:
                c = m.cards[slot] = Pico(slot)

            if ch in c.chans:
                print("Duplicate channel", c.chans[ch])

            if dev_type in ('PM', 'EMS'):
                dev = '%s:%s_' % (loc, dev_func.split(' Signal')[0])
            else:
                dev = '%s:' % loc

            c.chans[ch] = PicoChannel(ch, dev)

    return mtca

mtca_map = get_mtca_map()

env = Environment(loader=FileSystemLoader('./'))
template = env.get_template('template.st.cmd')

if '--debug' in sys.argv:
    for mtca_num, mtca_data in sorted(mtca_map.items()):
        print(f'MTCA {mtca_num}')
        for card, card_data in sorted(mtca_data.cards.items()):
            print(f'  Card {card}')
            for ch, ch_data in sorted(card_data.chans.items()):
                print(f'    Ch {ch}: {ch_data}')

for mtca_num, mtca_data in mtca_map.items():
    target = '../iocBoot/ioc-mtca%s-pico8/st.cmd' % mtca_num
    with open(target, 'w') as f:
        f.write(template.render({'mtca_num': mtca_num,
                                 'mtca_data': mtca_data}))
    print(target)

