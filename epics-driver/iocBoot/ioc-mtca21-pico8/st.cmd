#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA21,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA21,D=PICO4,NAME=PICO4,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA21:PICO3_CH0:,A=LS1_D:PM_D1232:A_")   # D-Station, not in cable DB
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA21:PICO3_CH1:,A=LS1_D:PM_D1232:B_")   # D-Station, not in cable DB
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA21:PICO3_CH2:,A=LS1_D:PM_D1232:C_")   # D-Station, not in cable DB
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA21:PICO3_CH4:,A=LS1_D:PM_D1240:A_")   # D-Station, not in cable DB
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA21:PICO3_CH5:,A=LS1_D:PM_D1240:B_")   # D-Station, not in cable DB
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA21:PICO3_CH6:,A=LS1_D:PM_D1240:C_")   # D-Station, not in cable DB

# Slot 4
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA21:PICO4_CH0:,A=LS1_D:FC_D1244:")   # D-Station, not in cable DB

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA21:PICO3 DIAG_MTCA21:PICO4 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA21:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA21:PICO4_FPS:SLT_CSET", "4"
