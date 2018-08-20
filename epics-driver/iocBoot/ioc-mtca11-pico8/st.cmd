#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA11,D=PICO9,NAME=PICO9,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 9
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA11:PICO9_CH0:,A=FS1_BMS:ND_D2588:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA11:PICO9_CH1:,A=LS2_CC02:ND_D2748:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA11:PICO9_CH2:,A=LS2_CC04:ND_D2828:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA11:PICO9_CH3:,A=LS2_CC06:ND_D2916:")


## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA11:PICO9 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA11:PICO9_FPS:SLT_CSET", "9"
