#!../../bin/linux-x86_64/pico

# !!! This file was autogenerated by epics-driver/gen-iocs/gen.py

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")
epicsEnvSet("DIAGSTD_DISABLE_STATS", "YES")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

var reToolsVerbose 0

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")

# (SYS):(D)_CHX:Y_Z
# PICO7 CH4 (0-based) has 1/8 current divider
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA11,NAME=PICO7,ASLO4=8e6")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA11,NAME=PICO9")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 7
reAddAlias "DIAG_MTCA11:PICO7_CH0:(.*)" "FS1_BMS:HMR_D2703:$1"
reAddAlias "DIAG_MTCA11:PICO7_CH1:(.*)" "LS2_WC03:HMR_D2823:$1"
reAddAlias "DIAG_MTCA11:PICO7_CH2:(.*)" "LS2_WC06:HMR_D2942:$1"
reAddAlias "DIAG_MTCA11:PICO7_CH4:(.*)" "FS1_BMS:FC_D2634:$1"

# Slot 9
reAddAlias "DIAG_MTCA11:PICO9_CH0:(.*)" "FS1_BMS:ND_D2588:$1"
reAddAlias "DIAG_MTCA11:PICO9_CH1:(.*)" "LS2_CC02:ND_D2748:$1"
reAddAlias "DIAG_MTCA11:PICO9_CH2:(.*)" "LS2_CC04:ND_D2828:$1"
reAddAlias "DIAG_MTCA11:PICO9_CH3:(.*)" "LS2_CC06:ND_D2916:$1"


< $(TOP)/iocBoot/archiver_tags.cmd

## Start the PICO python helper script
system "python3 ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA11:PICO7 DIAG_MTCA11:PICO9 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA11:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA11:PICO9_FPS:SLT_CSET", "9"

