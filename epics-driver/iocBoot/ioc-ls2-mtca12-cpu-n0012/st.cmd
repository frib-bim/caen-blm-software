#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca12-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA12:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA12:PICO:")

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA12,D=PICO5,NAME=PICO5,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 5
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH0:,A=LS2_CC08:ND_D2987:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH1:,A=LS2_CC10:ND_D3075:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH2:,A=LS2_CC12:ND_D3155:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH3:,A=LS2_CD02:ND_D3252:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH4:,A=LS2_CD04:ND_D3376:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH5:,A=LS2_CD06:ND_D3500:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA12:PICO5_CH6:,A=LS2_CD08:ND_D3624:")

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA12:PICO5 &"


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA12:CPU_N0012:")
save_restoreSet_status_prefix("DIAG_MTCA12:CPU_N0012:")

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
dbpf "DIAG_MTCA12:PICO5_FPS:SLT_CSET", "5"
