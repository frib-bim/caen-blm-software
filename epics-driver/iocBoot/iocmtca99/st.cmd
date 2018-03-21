#!../../bin/linux-x86_64-debug/pico

#< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")
createPICO8("PICO6", "/dev/amc_pico_0000:0b:00.0")
createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")
createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA,D=PICO4,NAME=PICO4,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA,D=PICO5,NAME=PICO5,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA,D=PICO6,NAME=PICO6,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA,D=PICO7,NAME=PICO7,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA,D=PICO8,NAME=PICO8,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA,D=PICO9,NAME=PICO9,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z


# Auto save/restore
save_restoreDebug(2)

#dbLoadRecords("db/save_restoreStatus.db", "P=DIAG_MTCA:CPU_R0404:")
#save_restoreSet_status_prefix("DIAG_MTCA:CPU_R0404:")

set_savefile_path("/usr/local/lib/iocapps/pico8/epics-driver/iocBoot/iocmtcacpu04/as","/save")
set_requestfile_path("/usr/local/lib/iocapps/pico8/epics-driver/iocBoot/iocmtcacpu04/as","/req")

set_pass0_restoreFile("pico_settings.sav")
set_pass1_restoreFile("pico_waveforms.sav")

system("install -d /usr/local/lib/iocapps/pico8/epics-driver/iocBoot/iocmtcacpu04/as/req")
system("install -d /usr/local/lib/iocapps/pico8/epics-driver/iocBoot/iocmtcacpu04/as/save")

iocInit()
iocLogInit()

makeAutosaveFileFromDbInfo("/usr/local/lib/iocapps/pico8/epics-driver/iocBoot/iocmtcacpu04/as/req/pico_settings.req", "autosaveFields_pass0")
makeAutosaveFileFromDbInfo("/usr/local/lib/iocapps/pico8/epics-driver/iocBoot/iocmtcacpu04/as/req/pico_waveforms.req", "autosaveFields_pass1")

create_monitor_set("pico_settings.req", 10 , "")
create_monitor_set("pico_waveforms.req", 30 , "")

caPutLogInit("${EPICS_IOC_LOG_INET}:${EPICS_IOC_LOG_PORT}", 1)
