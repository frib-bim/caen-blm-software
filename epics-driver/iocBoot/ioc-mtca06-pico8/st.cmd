#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA06,D=PICO3,NAME=PICO3,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3: Halo Monitor Rings (BLM)
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA06:PICO3_CH0:,A=LS1_WB04:HMR_D1478:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA06:PICO3_CH1:,A=LS1_WB05:HMR_D1542:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA06:PICO3_CH2:,A=LS1_WB06:HMR_D1606:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA06:PICO3_CH4:,A=LS1_WB07:HMR_D1670:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA06:PICO3_CH5:,A=LS1_WB08:HMR_D1733:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA06:PICO3_CH6:,A=LS1_WB09:HMR_D1797:")


## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA06:PICO3 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA06:PICO3_FPS:SLT_CSET", "3"
