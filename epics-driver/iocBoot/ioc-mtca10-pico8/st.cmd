#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO8", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO9", "/dev/amc_pico_0000:0d:00.0")
createPICO8("PICO10", "/dev/amc_pico_0000:07:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA10,D=PICO8,NAME=PICO8,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA10,D=PICO9,NAME=PICO9,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA10,D=PIC10,NAME=PICO10,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 8
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO8_CH0:,A=FS1_BBS:PM_D2444:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO8_CH1:,A=FS1_BBS:PM_D2444:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO8_CH2:,A=FS1_BBS:PM_D2444:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO8_CH4:,A=FS1_BBS:PM_D2482:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO8_CH5:,A=FS1_BBS:PM_D2482:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO8_CH6:,A=FS1_BBS:PM_D2482:C_")

# Slot 9
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO9_CH0:,A=FS1_BTS:PM_D2470:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO9_CH1:,A=FS1_BTS:PM_D2470:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO9_CH2:,A=FS1_BTS:PM_D2470:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO9_CH4:,A=FS1_BMS:PM_D2504:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO9_CH5:,A=FS1_BMS:PM_D2504:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO9_CH6:,A=FS1_BMS:PM_D2504:C_")

# Slot 10
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO10_CH0:,A=FS1_BMS:PM_D2602:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO10_CH1:,A=FS1_BMS:PM_D2602:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO10_CH2:,A=FS1_BMS:PM_D2602:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO10_CH4:,A=FS1_BMS:PM_D2703:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO10_CH5:,A=FS1_BMS:PM_D2703:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA10:PICO10_CH6:,A=FS1_BMS:PM_D2703:C_")

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA10:PICO8 DIAG_MTCA10:PICO9 DIAG_MTCA10:PICO10 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA10:PICO8_FPS:SLT_CSET", "8"
dbpf "DIAG_MTCA10:PICO9_FPS:SLT_CSET", "9"
dbpf "DIAG_MTCA10:PICO10_FPS:SLT_CSET", "10"
