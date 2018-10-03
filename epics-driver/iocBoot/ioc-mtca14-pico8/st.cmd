#!../../bin/linux-x86_64/pico

# !!! This file was autogenerated by epics-driver/gen-iocs/gen.py

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA14,D=PICO8,NAME=PICO8,NELM=1000000")

< $(TOP)/iocBoot/archiver_tags.cmd

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 8
reAddAlias "DIAG_MTCA14:PICO8_CH0:(.*)" "LS2_CD10:ND_D3748:$1"
reAddAlias "DIAG_MTCA14:PICO8_CH1:(.*)" "LS2_CD12:ND_D3872:$1"


< $(TOP)/iocBoot/archiver_chan_tags.cmd

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA14:PICO8 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA14:PICO8_FPS:SLT_CSET", "8"

