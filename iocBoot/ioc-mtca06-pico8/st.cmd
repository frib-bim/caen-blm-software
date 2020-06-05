#!../../bin/linux-x86_64/pico

# !!! This file was autogenerated by epics-driver/gen-iocs/gen.py

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")
epicsEnvSet("DIAGSTD_DISABLE_STATS", "YES")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

callbackParallelThreads 0 Low
var reToolsVerbose 0

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA06,NAME=PICO3")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
reAddAlias "DIAG_MTCA06:PICO3_CH0:(.*)" "LS1_WB04:HMR_D1478:$1"
reAddAlias "DIAG_MTCA06:PICO3_CH1:(.*)" "LS1_WB05:HMR_D1542:$1"
reAddAlias "DIAG_MTCA06:PICO3_CH2:(.*)" "LS1_WB06:HMR_D1606:$1"
reAddAlias "DIAG_MTCA06:PICO3_CH4:(.*)" "LS1_WB07:HMR_D1670:$1"
reAddAlias "DIAG_MTCA06:PICO3_CH5:(.*)" "LS1_WB08:HMR_D1733:$1"
reAddAlias "DIAG_MTCA06:PICO3_CH6:(.*)" "LS1_WB09:HMR_D1797:$1"


< $(TOP)/iocBoot/archiver_tags.cmd

## Start the PICO python helper script
system "python3 ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA06:PICO3 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA06:PICO3_FPS:SLT_CSET", "3"

