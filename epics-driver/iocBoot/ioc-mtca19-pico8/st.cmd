#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA19:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA19:PICO:")

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")
createPICO8("PICO6", "/dev/amc_pico_0000:0b:00.0")
createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA19,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA19,D=PICO4,NAME=PICO4,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA19,D=PICO5,NAME=PICO5,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA19,D=PICO6,NAME=PICO6,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA19,D=PICO7,NAME=PICO7,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA19,D=PICO8,NAME=PICO8,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO3_CH0:,A=BDS_BTS:PM_D5513:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO3_CH1:,A=BDS_BTS:PM_D5513:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO3_CH2:,A=BDS_BTS:PM_D5513:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO3_CH4:,A=BDS_BTS:PM_D5567:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO3_CH5:,A=BDS_BTS:PM_D5567:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO3_CH6:,A=BDS_BTS:PM_D5567:C_")

# Slot 4
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO4_CH0:,A=BDS_BBS:PM_D5628:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO4_CH1:,A=BDS_BBS:PM_D5628:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO4_CH2:,A=BDS_BBS:PM_D5628:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO4_CH4:,A=BDS_BBS:PM_D5655:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO4_CH5:,A=BDS_BBS:PM_D5655:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO4_CH6:,A=BDS_BBS:PM_D5655:C_")

# Slot 5
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO5_CH0:,A=BDS_FFS:PM_D5742:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO5_CH1:,A=BDS_FFS:PM_D5742:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO5_CH2:,A=BDS_FFS:PM_D5742:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO5_CH4:,A=BDS_FFS:PM_D5773:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO5_CH5:,A=BDS_FFS:PM_D5773:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO5_CH6:,A=BDS_FFS:PM_D5773:C_")

# Slot 6
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO6_CH0:,A=BDS_FFS:PM_D5800:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO6_CH1:,A=BDS_FFS:PM_D5800:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO6_CH2:,A=BDS_FFS:PM_D5800:C_")

# Slot 7
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO7_CH0:,A=LS3_BTS:IC_D5205:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO7_CH1:,A=LS3_BTS:IC_D5291:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO7_CH2:,A=BDS_BTS:IC_D5496:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO7_CH3:,A=BDS_BTS:IC_D5515:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO7_CH4:,A=BDS_BTS:IC_D5550:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO7_CH5:,A=BDS_BBS:IC_D5578:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO7_CH6:,A=BDS_BBS:IC_D5611:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO7_CH7:,A=BDS_BBS:IC_D5641:")

# Slot 8
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO8_CH0:,A=BDS_BBS:IC_D5679:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO8_CH1:,A=BDS_BBS:IC_D5711:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO8_CH2:,A=BDS_FFS:IC_D5740:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO8_CH3:,A=BDS_FFS:IC_D5765:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO8_CH4:,A=BDS_FFS:IC_D5800:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA19:PICO8_CH5:,A=BDS_FFS:IC_D5822:")


## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA19:PICO3 DIAG_MTCA19:PICO4 DIAG_MTCA19:PICO5 DIAG_MTCA19:PICO6 DIAG_MTCA19:PICO7 DIAG_MTCA19:PICO8  &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA19:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA19:PICO4_FPS:SLT_CSET", "4"
dbpf "DIAG_MTCA19:PICO5_FPS:SLT_CSET", "5"
dbpf "DIAG_MTCA19:PICO6_FPS:SLT_CSET", "6"
dbpf "DIAG_MTCA19:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA19:PICO8_FPS:SLT_CSET", "8"
