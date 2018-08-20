#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

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

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 7
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH0:,A=LS3_BTS:PM_D4769:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH1:,A=LS3_BTS:PM_D4769:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH2:,A=LS3_BTS:PM_D4769:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH4:,A=LS3_BTS:PM_D4794:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH5:,A=LS3_BTS:PM_D4794:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH6:,A=LS3_BTS:PM_D4794:C_")

# Slot 8
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH0:,A=LS3_BTS:PM_D4824:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH1:,A=LS3_BTS:PM_D4824:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH2:,A=LS3_BTS:PM_D4824:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH4:,A=LS3_BTS:PM_D4862:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH5:,A=LS3_BTS:PM_D4862:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH6:,A=LS3_BTS:PM_D4862:C_")

# Slot 9
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO9_CH0:,A=LS3_BTS:IC_D4799:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO9_CH1:,A=LS3_BTS:IC_D4895:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO9_CH2:,A=LS3_BTS:IC_D5001:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO9_CH3:,A=LS3_BTS:IC_D5105:")


## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA17:PICO7 DIAG_MTCA17:PICO8 DIAG_MTCA17:PICO9 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA17:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA17:PICO8_FPS:SLT_CSET", "8"
dbpf "DIAG_MTCA17:PICO9_FPS:SLT_CSET", "9"
