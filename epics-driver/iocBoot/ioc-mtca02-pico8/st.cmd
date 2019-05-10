#!../../bin/linux-x86_64/pico

# !!! This file was autogenerated by epics-driver/gen-iocs/gen.py

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")
epicsEnvSet("DIAGSTD_DISABLE_STATS", "YES")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO11", "/dev/amc_pico_0000:0a:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA02,D=PICO11,NAME=PICO11,NELM=1000000")

< $(TOP)/iocBoot/archiver_tags.cmd

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 11
reAddAlias "DIAG_MTCA02:PICO11_CH0:(.*)" "BPM_DBG:BUT1:$1"
reAddAlias "DIAG_MTCA02:PICO11_CH1:(.*)" "BPM_DBG:BUT2:$1"
reAddAlias "DIAG_MTCA02:PICO11_CH2:(.*)" "BPM_DBG:CH2:$1"
reAddAlias "DIAG_MTCA02:PICO11_CH3:(.*)" "BPM_DBG:CH3:$1"
reAddAlias "DIAG_MTCA02:PICO11_CH4:(.*)" "BPM_DBG:BUT3:$1"
reAddAlias "DIAG_MTCA02:PICO11_CH5:(.*)" "BPM_DBG:BUT4:$1"
reAddAlias "DIAG_MTCA02:PICO11_CH6:(.*)" "BPM_DBG:CH6:$1"
reAddAlias "DIAG_MTCA02:PICO11_CH7:(.*)" "BPM_DBG:CH7:$1"


< $(TOP)/iocBoot/archiver_chan_tags.cmd

## Start the PICO python helper script
system "python3 ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA02:PICO11 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA02:PICO11_FPS:SLT_CSET", "11"

