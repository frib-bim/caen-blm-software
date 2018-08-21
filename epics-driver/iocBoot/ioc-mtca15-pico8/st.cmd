#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")
createPICO8("PICO6", "/dev/amc_pico_0000:0b:00.0")
createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO4,NAME=PICO4,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO5,NAME=PICO5,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO6,NAME=PICO6,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO7,NAME=PICO7,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO8,NAME=PICO8,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH0:,A=FE_LEBT:PM_D0945:A_")   # CableDB: D0945
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH1:,A=FE_LEBT:PM_D0945:B_")   # CableDB: D0945
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH2:,A=FE_LEBT:PM_D0945:C_")   # CableDB: D0945
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH4:,A=FE_LEBT:PM_D0961:A_")   # CableDB: D0962
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH5:,A=FE_LEBT:PM_D0961:B_")   # CableDB: D0962
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH6:,A=FE_LEBT:PM_D0961:C_")   # CableDB: D0962

# Slot 4
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH0:,A=FE_LEBT:PM_D0972:A_")   # CableDB: D0976
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH1:,A=FE_LEBT:PM_D0972:B_")   # CableDB: D0976
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH2:,A=FE_LEBT:PM_D0972:C_")   # CableDB: D0976
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH4:,A=FE_LEBT:PM_D0986:A_")   # CableDB: D0986
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH5:,A=FE_LEBT:PM_D0986:B_")   # CableDB: D0986
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH6:,A=FE_LEBT:PM_D0986:C_")   # CableDB: D0986

# Slot 5
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH0:,A=FE_LEBT:PM_D4051:A_")   # CableDB: D4051
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH1:,A=FE_LEBT:PM_D4051:B_")   # CableDB: D4051
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH2:,A=FE_LEBT:PM_D4051:C_")   # CableDB: D4051
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH4:,A=FS2_BMS:PM_D4143:A_")   # CableDB: D4143
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH5:,A=FS2_BMS:PM_D4143:B_")   # CableDB: D4143
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH6:,A=FS2_BMS:PM_D4143:C_")   # CableDB: D4143

# Slot 6
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH0:,A=FS2_BTS:PM_D3958:A_")   # CableDB: D3958
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH1:,A=FS2_BTS:PM_D3958:B_")   # CableDB: D3958
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH2:,A=FS2_BTS:PM_D3958:C_")   # CableDB: D3958
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH4:,A=FS2_BTS:PM_D4013:A_")   # CableDB: D4013
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH5:,A=FS2_BTS:PM_D4013:B_")   # CableDB: D4013
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH6:,A=FS2_BTS:PM_D4013:C_")   # CableDB: D4013

# Slot 7
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO7_CH0:,A=FS2_BBS:IC_D4055:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO7_CH1:,A=FS2_BBS:IC_D4018:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO7_CH2:,A=FS2_BBS:IC_D3979:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO7_CH4:,AFS2_BTS:IC_D4018:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO7_CH5:,A=FS2_BTS:IC_D3940:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO7_CH6:,A=FS2_BBS:IC_D4102:")

# Slot 8
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO8_CH2:,A=FS2_BTS:IC_D4019:")


## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA15:PICO3 DIAG_MTCA15:PICO4 DIAG_MTCA15:PICO5 DIAG_MTCA15:PICO6 DIAG_MTCA15:PICO7 DIAG_MTCA15:PICO8 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA15:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA15:PICO4_FPS:SLT_CSET", "4"
dbpf "DIAG_MTCA15:PICO5_FPS:SLT_CSET", "5"
dbpf "DIAG_MTCA15:PICO6_FPS:SLT_CSET", "6"
dbpf "DIAG_MTCA15:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA15:PICO8_FPS:SLT_CSET", "8"