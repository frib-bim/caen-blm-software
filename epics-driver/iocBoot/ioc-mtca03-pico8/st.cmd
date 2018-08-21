#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA03,D=PICO3,NAME=PICO3,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH0:,A=FS2_BMS:IC_D4141:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH1:,A=FS2_BMS:IC_D4180:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH2:,A=FS2_BMS:IC_D4221:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH3:,A=FS2_BMS:IC_D4277:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH4:,A=FS2_BMS:IC_D4305:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH5:,A=LS3_CD01:IC_D4385:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH6:,A=LS3_CD03:IC_D4503:")


## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA03:PICO3 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA03:PICO3_FPS:SLT_CSET", "3"