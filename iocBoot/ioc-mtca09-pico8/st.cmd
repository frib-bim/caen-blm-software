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
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")
createPICO8("PICO6", "/dev/amc_pico_0000:0b:00.0")
createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA09,NAME=PICO3")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA09,NAME=PICO4")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA09,NAME=PICO5")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA09,NAME=PICO6")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA09,NAME=PICO7")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA09,NAME=PICO9")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
reAddAlias "DIAG_MTCA09:PICO3_CH0:(.*)" "LS1_BTS:PM_D2056:A_$1"
reAddAlias "DIAG_MTCA09:PICO3_CH1:(.*)" "LS1_BTS:PM_D2056:B_$1"
reAddAlias "DIAG_MTCA09:PICO3_CH2:(.*)" "LS1_BTS:PM_D2056:C_$1"
reAddAlias "DIAG_MTCA09:PICO3_CH4:(.*)" "LS1_BTS:PM_D2131:A_$1"
reAddAlias "DIAG_MTCA09:PICO3_CH5:(.*)" "LS1_BTS:PM_D2131:B_$1"
reAddAlias "DIAG_MTCA09:PICO3_CH6:(.*)" "LS1_BTS:PM_D2131:C_$1"

# Slot 4
reAddAlias "DIAG_MTCA09:PICO4_CH0:(.*)" "FS1_CSS:PM_D2198:A_$1"
reAddAlias "DIAG_MTCA09:PICO4_CH1:(.*)" "FS1_CSS:PM_D2198:B_$1"
reAddAlias "DIAG_MTCA09:PICO4_CH2:(.*)" "FS1_CSS:PM_D2198:C_$1"
reAddAlias "DIAG_MTCA09:PICO4_CH4:(.*)" "FS1_CSS:PM_D2225:A_$1"
reAddAlias "DIAG_MTCA09:PICO4_CH5:(.*)" "FS1_CSS:PM_D2225:B_$1"
reAddAlias "DIAG_MTCA09:PICO4_CH6:(.*)" "FS1_CSS:PM_D2225:C_$1"

# Slot 5
reAddAlias "DIAG_MTCA09:PICO5_CH0:(.*)" "FS1_CSS:PM_D2249:A_$1"
reAddAlias "DIAG_MTCA09:PICO5_CH1:(.*)" "FS1_CSS:PM_D2249:B_$1"
reAddAlias "DIAG_MTCA09:PICO5_CH2:(.*)" "FS1_CSS:PM_D2249:C_$1"
reAddAlias "DIAG_MTCA09:PICO5_CH4:(.*)" "FS1_CSS:PM_D2385:A_$1"
reAddAlias "DIAG_MTCA09:PICO5_CH5:(.*)" "FS1_CSS:PM_D2385:B_$1"
reAddAlias "DIAG_MTCA09:PICO5_CH6:(.*)" "FS1_CSS:PM_D2385:C_$1"

# Slot 6
reAddAlias "DIAG_MTCA09:PICO6_CH0:(.*)" "FS1_BTS:PM_D2439:A_$1"
reAddAlias "DIAG_MTCA09:PICO6_CH1:(.*)" "FS1_BTS:PM_D2439:B_$1"
reAddAlias "DIAG_MTCA09:PICO6_CH2:(.*)" "FS1_BTS:PM_D2439:C_$1"
reAddAlias "DIAG_MTCA09:PICO6_CH4:(.*)" "FS1_MGB01:ND_D2332:$1"
reAddAlias "DIAG_MTCA09:PICO6_CH5:(.*)" "FS1_BTS:ND_D2408:$1"

# Slot 7
reAddAlias "DIAG_MTCA09:PICO7_CH0:(.*)" "FS1_BTS:IC_D2448:$1"
reAddAlias "DIAG_MTCA09:PICO7_CH1:(.*)" "FS1_BTS:IC_D2449:$1"
reAddAlias "DIAG_MTCA09:PICO7_CH2:(.*)" "FS1_BTS:IC_D2478:$1"
reAddAlias "DIAG_MTCA09:PICO7_CH3:(.*)" "FS1_BTS:IC_D2479:$1"
reAddAlias "DIAG_MTCA09:PICO7_CH4:(.*)" "FS1_STRL:IC_D2227:$1"
reAddAlias "DIAG_MTCA09:PICO7_CH5:(.*)" "FS1_STRL:IC_D2228:$1"
reAddAlias "DIAG_MTCA09:PICO7_CH6:(.*)" "FS1_STRL:IC_D2246:$1"
reAddAlias "DIAG_MTCA09:PICO7_CH7:(.*)" "FS1_STRL:IC_D2247:$1"

# Slot 9
reAddAlias "DIAG_MTCA09:PICO9_CH0:(.*)" "LS1_WB10:HMR_D1861:$1"
reAddAlias "DIAG_MTCA09:PICO9_CH1:(.*)" "LS1_WB11:HMR_D1925:$1"


< $(TOP)/iocBoot/archiver_tags.cmd

## Start the PICO python helper script
system "python3 ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA09:PICO3 DIAG_MTCA09:PICO4 DIAG_MTCA09:PICO5 DIAG_MTCA09:PICO6 DIAG_MTCA09:PICO7 DIAG_MTCA09:PICO9 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA09:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA09:PICO4_FPS:SLT_CSET", "4"
dbpf "DIAG_MTCA09:PICO5_FPS:SLT_CSET", "5"
dbpf "DIAG_MTCA09:PICO6_FPS:SLT_CSET", "6"
dbpf "DIAG_MTCA09:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA09:PICO9_FPS:SLT_CSET", "9"
