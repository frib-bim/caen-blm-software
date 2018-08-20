#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca17-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA17:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA17:PICO:")

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


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA17:CPU_N0101:")
save_restoreSet_status_prefix("DIAG_MTCA17:CPU_N0101:")

set_savefile_path("${AUTOSAVE}")
set_requestfile_path("${AUTOSAVE}")

set_pass0_restoreFile("pico_settings.sav")
set_pass1_restoreFile("pico_waveforms.sav")

iocInit()
iocLogInit()

system "test -d ${AUTOSAVE} || mkdir ${AUTOSAVE}"
makeAutosaveFileFromDbInfo("${AUTOSAVE}/pico_settings.req", "autosaveFields_pass0")
makeAutosaveFileFromDbInfo("${AUTOSAVE}/pico_waveforms.req", "autosaveFields_pass1")

create_monitor_set("pico_settings.req", 10 , "")
create_monitor_set("pico_waveforms.req", 30 , "")

caPutLogInit("${EPICS_PUT_LOG_INET}:${EPICS_PUT_LOG_PORT}", 1)

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA17:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA17:PICO8_FPS:SLT_CSET", "8"
dbpf "DIAG_MTCA17:PICO9_FPS:SLT_CSET", "9"
