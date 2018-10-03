#!../../bin/linux-x86_64/pico

# !!! This file was autogenerated by epics-driver/gen-iocs/gen.py

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")
createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA17,D=PICO7,NAME=PICO7,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA17,D=PICO8,NAME=PICO8,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA17,D=PICO9,NAME=PICO9,NELM=1000000")

< $(TOP)/iocBoot/archiver_tags.cmd

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


< $(TOP)/iocBoot/archiver_chan_tags.cmd

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA17:PICO7 DIAG_MTCA17:PICO8 DIAG_MTCA17:PICO9 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA17:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA17:PICO8_FPS:SLT_CSET", "8"
dbpf "DIAG_MTCA17:PICO9_FPS:SLT_CSET", "9"

