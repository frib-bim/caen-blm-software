#!../../bin/linux-x86_64/pico

# !!! This file was autogenerated by epics-driver/gen-iocs/gen.py

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")
epicsEnvSet("DIAGSTD_DISABLE_STATS", "YES")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA04,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA04,D=PICO4,NAME=PICO4,NELM=1000000")

< $(TOP)/iocBoot/archiver_tags.cmd

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
reAddAlias "DIAG_MTCA04:PICO3_CH0:(.*)" "FE_RFQ:ND_D1025:$1"
reAddAlias "DIAG_MTCA04:PICO3_CH1:(.*)" "LS1_CA01:ND_D1128:$1"
reAddAlias "DIAG_MTCA04:PICO3_CH2:(.*)" "LS1_CA03:ND_D1195:$1"
reAddAlias "DIAG_MTCA04:PICO3_CH4:(.*)" "LS1_CB01:ND_D1250:$1"
reAddAlias "DIAG_MTCA04:PICO3_CH5:(.*)" "LS1_CB03:ND_D1378:$1"
reAddAlias "DIAG_MTCA04:PICO3_CH6:(.*)" "LS3_CD06:ND_D4647:$1"

# Slot 4
reAddAlias "DIAG_MTCA04:PICO4_CH0:(.*)" "LS1_WA01:HMR_D1156:$1"
reAddAlias "DIAG_MTCA04:PICO4_CH1:(.*)" "LS1_WA02:HMR_D1190:$1"
reAddAlias "DIAG_MTCA04:PICO4_CH2:(.*)" "LS1_WA03:HMR_D1224:$1"
reAddAlias "DIAG_MTCA04:PICO4_CH4:(.*)" "LS1_WB01:HMR_D1287:$1"
reAddAlias "DIAG_MTCA04:PICO4_CH5:(.*)" "LS1_WB02:HMR_D1351:$1"
reAddAlias "DIAG_MTCA04:PICO4_CH6:(.*)" "LS1_WB03:HMR_D1415:$1"


< $(TOP)/iocBoot/archiver_chan_tags.cmd

## Start the PICO python helper script
system "python3 ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA04:PICO3 DIAG_MTCA04:PICO4 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA04:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA04:PICO4_FPS:SLT_CSET", "4"

