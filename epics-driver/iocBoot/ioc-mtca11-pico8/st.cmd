#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca11-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA11:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA11:PICO:")

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


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA11:CPU_N0011:")
save_restoreSet_status_prefix("DIAG_MTCA11:CPU_N0011:")

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
dbpf "DIAG_MTCA11:PICO9_FPS:SLT_CSET", "9"
