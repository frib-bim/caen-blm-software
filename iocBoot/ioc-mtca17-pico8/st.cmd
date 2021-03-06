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
createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")
createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")
createPICO8("PICO10", "/dev/amc_pico_0000:05:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA17,NAME=PICO7")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA17,NAME=PICO8")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA17,NAME=PICO9")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA17,NAME=PICO10")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 7
reAddAlias "DIAG_MTCA17:PICO7_CH0:(.*)" "LS3_BTS:PM_D4771:A_$1"
reAddAlias "DIAG_MTCA17:PICO7_CH1:(.*)" "LS3_BTS:PM_D4771:B_$1"
reAddAlias "DIAG_MTCA17:PICO7_CH2:(.*)" "LS3_BTS:PM_D4771:C_$1"
reAddAlias "DIAG_MTCA17:PICO7_CH4:(.*)" "LS3_BTS:PM_D4797:A_$1"
reAddAlias "DIAG_MTCA17:PICO7_CH5:(.*)" "LS3_BTS:PM_D4797:B_$1"
reAddAlias "DIAG_MTCA17:PICO7_CH6:(.*)" "LS3_BTS:PM_D4797:C_$1"

# Slot 8
reAddAlias "DIAG_MTCA17:PICO8_CH0:(.*)" "LS3_BTS:PM_D4827:A_$1"
reAddAlias "DIAG_MTCA17:PICO8_CH1:(.*)" "LS3_BTS:PM_D4827:B_$1"
reAddAlias "DIAG_MTCA17:PICO8_CH2:(.*)" "LS3_BTS:PM_D4827:C_$1"
reAddAlias "DIAG_MTCA17:PICO8_CH4:(.*)" "LS3_BTS:PM_D4862:A_$1"
reAddAlias "DIAG_MTCA17:PICO8_CH5:(.*)" "LS3_BTS:PM_D4862:B_$1"
reAddAlias "DIAG_MTCA17:PICO8_CH6:(.*)" "LS3_BTS:PM_D4862:C_$1"

# Slot 9
reAddAlias "DIAG_MTCA17:PICO9_CH0:(.*)" "LS3_BTS:IC_D4799:$1"
reAddAlias "DIAG_MTCA17:PICO9_CH1:(.*)" "LS3_BTS:IC_D4895:$1"
reAddAlias "DIAG_MTCA17:PICO9_CH2:(.*)" "LS3_BTS:IC_D5001:$1"
reAddAlias "DIAG_MTCA17:PICO9_CH3:(.*)" "LS3_BTS:IC_D5105:$1"

# Slot 10
reAddAlias "DIAG_MTCA17:PICO10_CH0:(.*)" "LS3_WD06:HMR_D4700:$1"


< $(TOP)/iocBoot/archiver_tags.cmd

## Start the PICO python helper script
system "python3 ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA17:PICO7 DIAG_MTCA17:PICO8 DIAG_MTCA17:PICO9 DIAG_MTCA17:PICO10 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA17:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA17:PICO8_FPS:SLT_CSET", "8"
dbpf "DIAG_MTCA17:PICO9_FPS:SLT_CSET", "9"
dbpf "DIAG_MTCA17:PICO10_FPS:SLT_CSET", "10"

