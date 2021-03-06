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
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")
createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")
createPICO8("PICO10", "/dev/amc_pico_0000:05:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA10,NAME=PICO8")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA10,NAME=PICO9")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA10,NAME=PICO10")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 8
reAddAlias "DIAG_MTCA10:PICO8_CH0:(.*)" "FS1_BBS:PM_D2444:A_$1"
reAddAlias "DIAG_MTCA10:PICO8_CH1:(.*)" "FS1_BBS:PM_D2444:B_$1"
reAddAlias "DIAG_MTCA10:PICO8_CH2:(.*)" "FS1_BBS:PM_D2444:C_$1"
reAddAlias "DIAG_MTCA10:PICO8_CH4:(.*)" "FS1_BBS:PM_D2482:A_$1"
reAddAlias "DIAG_MTCA10:PICO8_CH5:(.*)" "FS1_BBS:PM_D2482:B_$1"
reAddAlias "DIAG_MTCA10:PICO8_CH6:(.*)" "FS1_BBS:PM_D2482:C_$1"

# Slot 9
reAddAlias "DIAG_MTCA10:PICO9_CH0:(.*)" "FS1_BTS:PM_D2470:A_$1"
reAddAlias "DIAG_MTCA10:PICO9_CH1:(.*)" "FS1_BTS:PM_D2470:B_$1"
reAddAlias "DIAG_MTCA10:PICO9_CH2:(.*)" "FS1_BTS:PM_D2470:C_$1"
reAddAlias "DIAG_MTCA10:PICO9_CH4:(.*)" "FS1_BMS:PM_D2552:A_$1"
reAddAlias "DIAG_MTCA10:PICO9_CH5:(.*)" "FS1_BMS:PM_D2552:B_$1"
reAddAlias "DIAG_MTCA10:PICO9_CH6:(.*)" "FS1_BMS:PM_D2552:C_$1"

# Slot 10
reAddAlias "DIAG_MTCA10:PICO10_CH0:(.*)" "FS1_BMS:PM_D2602:A_$1"
reAddAlias "DIAG_MTCA10:PICO10_CH1:(.*)" "FS1_BMS:PM_D2602:B_$1"
reAddAlias "DIAG_MTCA10:PICO10_CH2:(.*)" "FS1_BMS:PM_D2602:C_$1"
reAddAlias "DIAG_MTCA10:PICO10_CH4:(.*)" "FS1_BMS:PM_D2703:A_$1"
reAddAlias "DIAG_MTCA10:PICO10_CH5:(.*)" "FS1_BMS:PM_D2703:B_$1"
reAddAlias "DIAG_MTCA10:PICO10_CH6:(.*)" "FS1_BMS:PM_D2703:C_$1"


< $(TOP)/iocBoot/archiver_tags.cmd

## Start the PICO python helper script
system "python3 ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA10:PICO8 DIAG_MTCA10:PICO9 DIAG_MTCA10:PICO10 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA10:PICO8_FPS:SLT_CSET", "8"
dbpf "DIAG_MTCA10:PICO9_FPS:SLT_CSET", "9"
dbpf "DIAG_MTCA10:PICO10_FPS:SLT_CSET", "10"

