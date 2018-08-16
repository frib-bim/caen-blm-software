#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca03-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA03:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA03:PICO:")

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA03,D=PICO3,NAME=PICO3,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH0:,A=FS2_BMS:IC_D4141:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH1:,A=FS2_BMS:IC_D4180:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH2:,A=FS2_BMS:IC_D4221:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH3:,A=FS2_BMS:IC_D4277:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH4:,A=FS2_BMS:IC_D4305:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH5:,A=LS3_CD01:IC_D4385:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA03:PICO3_CH6:,A=LS3_CD03:IC_D4503:")


## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA03:PICO3 &"


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA03:CPU_N0003:")
save_restoreSet_status_prefix("DIAG_MTCA03:CPU_N0003:")

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
dbpf "DIAG_MTCA03:PICO3_FPS:SLT_CSET", "3"
