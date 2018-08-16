#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca07-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA07:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA07:PICO:")

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA07,D=PICO8,NAME=PICO8,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 8: Neutron Detectors (BLM)
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH0:,A=LS1_CB05:ND_D1505:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH1:,A=LS1_CB07:ND_D1633:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH2:,A=LS1_CB09:ND_D1760:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH3:,A=LS1_CB11:ND_D1908:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA07:PICO8_CH4:,A=LS1_BTS:ND_D2076:")

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA07:PICO8 &"


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA07:CPU_N0007:")
save_restoreSet_status_prefix("DIAG_MTCA07:CPU_N0007:")

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
dbpf "DIAG_MTCA07:PICO8_FPS:SLT_CSET", "8"
