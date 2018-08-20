#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA12,D=PICO5,NAME=PICO5,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 5
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH0:,A=LS2_CC08:ND_D2987:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH1:,A=LS2_CC10:ND_D3075:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH2:,A=LS2_CC12:ND_D3155:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH3:,A=LS2_CD02:ND_D3252:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH4:,A=LS2_CD04:ND_D3376:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH5:,A=LS2_CD06:ND_D3500:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH6:,A=LS2_CD08:ND_D3624:")

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA12:PICO5 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA12:PICO5_FPS:SLT_CSET", "5"
