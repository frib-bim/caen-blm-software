#!../../bin/linux-x86_64/pico

# !!! This file was autogenerated by epics-driver/gen-iocs/gen.py

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")
epicsEnvSet("DIAGSTD_DISABLE_STATS", "YES")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA12,D=PICO5,NAME=PICO5,NELM=1000000")

< $(TOP)/iocBoot/archiver_tags.cmd

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 5
reAddAlias "DIAG_MTCA12:PICO5_CH0:(.*)" "LS2_CC08:ND_D2987:$1"
reAddAlias "DIAG_MTCA12:PICO5_CH1:(.*)" "LS2_CC10:ND_D3075:$1"
reAddAlias "DIAG_MTCA12:PICO5_CH2:(.*)" "LS2_CC12:ND_D3155:$1"
reAddAlias "DIAG_MTCA12:PICO5_CH3:(.*)" "LS2_CD02:ND_D3252:$1"
reAddAlias "DIAG_MTCA12:PICO5_CH4:(.*)" "LS2_CD04:ND_D3376:$1"
reAddAlias "DIAG_MTCA12:PICO5_CH5:(.*)" "LS2_CD06:ND_D3500:$1"
reAddAlias "DIAG_MTCA12:PICO5_CH6:(.*)" "LS2_CD08:ND_D3624:$1"


< $(TOP)/iocBoot/archiver_chan_tags.cmd

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA12:PICO5 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA12:PICO5_FPS:SLT_CSET", "5"

