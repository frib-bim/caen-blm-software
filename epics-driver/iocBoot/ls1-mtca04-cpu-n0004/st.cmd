#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca04-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA04:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA04:PICO:")

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA04,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA04,D=PICO4,NAME=PICO4,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3:  Neutron Detectors (BLM)
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO3_CH0:,A=FE_RFQ:ND_D1025")  
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO3_CH1:,A=LS1_CA01:ND_D1128")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO3_CH2:,A=LS1_CA03:ND_D1195")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO3_CH4:,A=LS1_CB01:ND_D1250")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO3_CH5:,A=LS1_CB03:ND_D1378")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO3_CH6:,A=LS3_CD06:ND_D4647")

# Slot 4:  Halo Monitor Rings (BLM)
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO4_CH0:,A=LS1_WA01:HMR_D1156")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO4_CH1:,A=LS1_WA02:HMR_D1190")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO4_CH2:,A=LS1_WA03:HMR_D1223")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO4_CH4:,A=LS1_WB01:HMR_D1287")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO4_CH5:,A=LS1_WB02:HMR_D1351")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA04:PICO4_CH6:,A=LS1_WB03:HMR_D1415")

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA04:PICO3 DIAG_MTCA04:PICO4 &"


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA04:CPU_N0101:")
save_restoreSet_status_prefix("DIAG_MTCA04:CPU_N0101:")

set_savefile_path("${AUTOSAVE}")
set_requestfile_path("${AUTOSAVE}")

set_pass0_restoreFile("pico_settings.sav")
set_pass1_restoreFile("pico_waveforms.sav")

iocInit()
iocLogInit()

makeAutosaveFileFromDbInfo("${AUTOSAVE}/pico_settings.req", "autosaveFields_pass0")
makeAutosaveFileFromDbInfo("${AUTOSAVE}/pico_waveforms.req", "autosaveFields_pass1")

create_monitor_set("pico_settings.req", 10 , "")
create_monitor_set("pico_waveforms.req", 30 , "")

caPutLogInit("${EPICS_IOC_LOG_INET}:${EPICS_IOC_LOG_PORT}", 1)

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA04:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA04:PICO4_FPS:SLT_CSET", "4"
