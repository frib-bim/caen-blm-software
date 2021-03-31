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
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA19,NAME=PICO3")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA19,NAME=PICO4")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA19,NAME=PICO5")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA19,NAME=PICO6")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA19,NAME=PICO7")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA19,NAME=PICO8")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
reAddAlias "DIAG_MTCA19:PICO3_CH0:(.*)" "BDS_BTS:PM_D5514:A_$1"
reAddAlias "DIAG_MTCA19:PICO3_CH1:(.*)" "BDS_BTS:PM_D5514:B_$1"
reAddAlias "DIAG_MTCA19:PICO3_CH2:(.*)" "BDS_BTS:PM_D5514:C_$1"
reAddAlias "DIAG_MTCA19:PICO3_CH4:(.*)" "BDS_BTS:PM_D5567:A_$1"
reAddAlias "DIAG_MTCA19:PICO3_CH5:(.*)" "BDS_BTS:PM_D5567:B_$1"
reAddAlias "DIAG_MTCA19:PICO3_CH6:(.*)" "BDS_BTS:PM_D5567:C_$1"

# Slot 4
reAddAlias "DIAG_MTCA19:PICO4_CH0:(.*)" "BDS_BBS:PM_D5628:A_$1"
reAddAlias "DIAG_MTCA19:PICO4_CH1:(.*)" "BDS_BBS:PM_D5628:B_$1"
reAddAlias "DIAG_MTCA19:PICO4_CH2:(.*)" "BDS_BBS:PM_D5628:C_$1"
reAddAlias "DIAG_MTCA19:PICO4_CH4:(.*)" "BDS_BBS:PM_D5653:A_$1"
reAddAlias "DIAG_MTCA19:PICO4_CH5:(.*)" "BDS_BBS:PM_D5653:B_$1"
reAddAlias "DIAG_MTCA19:PICO4_CH6:(.*)" "BDS_BBS:PM_D5653:C_$1"

# Slot 5
reAddAlias "DIAG_MTCA19:PICO5_CH0:(.*)" "BDS_FFS:PM_D5743:A_$1"
reAddAlias "DIAG_MTCA19:PICO5_CH1:(.*)" "BDS_FFS:PM_D5743:B_$1"
reAddAlias "DIAG_MTCA19:PICO5_CH2:(.*)" "BDS_FFS:PM_D5743:C_$1"
reAddAlias "DIAG_MTCA19:PICO5_CH4:(.*)" "BDS_FFS:PM_D5774:A_$1"
reAddAlias "DIAG_MTCA19:PICO5_CH5:(.*)" "BDS_FFS:PM_D5774:B_$1"
reAddAlias "DIAG_MTCA19:PICO5_CH6:(.*)" "BDS_FFS:PM_D5774:C_$1"

# Slot 6
reAddAlias "DIAG_MTCA19:PICO6_CH0:(.*)" "BDS_FFS:PM_D5792:A_$1"
reAddAlias "DIAG_MTCA19:PICO6_CH1:(.*)" "BDS_FFS:PM_D5792:B_$1"
reAddAlias "DIAG_MTCA19:PICO6_CH2:(.*)" "BDS_FFS:PM_D5792:C_$1"
reAddAlias "DIAG_MTCA19:PICO6_CH4:(.*)" "BDS_BTS:PM_D5652:A_$1"
reAddAlias "DIAG_MTCA19:PICO6_CH5:(.*)" "BDS_BTS:PM_D5652:B_$1"
reAddAlias "DIAG_MTCA19:PICO6_CH6:(.*)" "BDS_BTS:PM_D5652:C_$1"

# Slot 7
reAddAlias "DIAG_MTCA19:PICO7_CH0:(.*)" "LS3_BTS:IC_D5205:$1"
reAddAlias "DIAG_MTCA19:PICO7_CH1:(.*)" "LS3_BTS:IC_D5291:$1"
reAddAlias "DIAG_MTCA19:PICO7_CH2:(.*)" "BDS_BTS:IC_D5496:$1"
reAddAlias "DIAG_MTCA19:PICO7_CH3:(.*)" "BDS_BTS:IC_D5515:$1"
reAddAlias "DIAG_MTCA19:PICO7_CH4:(.*)" "BDS_BTS:IC_D5550:$1"
reAddAlias "DIAG_MTCA19:PICO7_CH5:(.*)" "BDS_BBS:IC_D5578:$1"
reAddAlias "DIAG_MTCA19:PICO7_CH6:(.*)" "BDS_BBS:IC_D5611:$1"
reAddAlias "DIAG_MTCA19:PICO7_CH7:(.*)" "BDS_BBS:IC_D5641:$1"

# Slot 8
reAddAlias "DIAG_MTCA19:PICO8_CH0:(.*)" "BDS_BBS:IC_D5679:$1"
reAddAlias "DIAG_MTCA19:PICO8_CH1:(.*)" "BDS_BBS:IC_D5711:$1"
reAddAlias "DIAG_MTCA19:PICO8_CH2:(.*)" "BDS_FFS:IC_D5740:$1"
reAddAlias "DIAG_MTCA19:PICO8_CH3:(.*)" "BDS_FFS:IC_D5765:$1"
reAddAlias "DIAG_MTCA19:PICO8_CH4:(.*)" "BDS_FFS:IC_D5800:$1"
reAddAlias "DIAG_MTCA19:PICO8_CH5:(.*)" "BDS_FFS:IC_D5822:$1"
reAddAlias "DIAG_MTCA19:PICO8_CH6:(.*)" "BDS_BTS:IC_D5661:$1"
reAddAlias "DIAG_MTCA19:PICO8_CH7:(.*)" "BDS_BTS:IC_D5662:$1"


< $(TOP)/iocBoot/archiver_tags.cmd

## Start the PICO python helper script
system "python3 ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA19:PICO3 DIAG_MTCA19:PICO4 DIAG_MTCA19:PICO5 DIAG_MTCA19:PICO6 DIAG_MTCA19:PICO7 DIAG_MTCA19:PICO8 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA19:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA19:PICO4_FPS:SLT_CSET", "4"
dbpf "DIAG_MTCA19:PICO5_FPS:SLT_CSET", "5"
dbpf "DIAG_MTCA19:PICO6_FPS:SLT_CSET", "6"
dbpf "DIAG_MTCA19:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA19:PICO8_FPS:SLT_CSET", "8"
