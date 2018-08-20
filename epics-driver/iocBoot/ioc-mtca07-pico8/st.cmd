#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA07,D=PICO8,NAME=PICO8,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 8: Neutron Detectors (BLM)
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH0:,A=LS1_CB05:ND_D1505:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH1:,A=LS1_CB07:ND_D1633:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH2:,A=LS1_CB09:ND_D1760:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH3:,A=LS1_CB11:ND_D1908:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH4:,A=LS1_BTS:ND_D2076:")

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA07:PICO8 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA07:PICO8_FPS:SLT_CSET", "8"
