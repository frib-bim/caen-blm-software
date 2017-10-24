#!../../bin/linux-x86_64-debug/pico

#< envPaths

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase) 

createPICO8("PICO", "/dev/amc_pico_0000:01:00.0")
#debugPICO("PICO", 5)

#dbLoadRecords("../../db/pico8.db","SYS=TST,D=pico,NAME=PICO")
dbLoadRecords("../../db/pico8_frib.db","SYS=TST,D=pico,NAME=PICO")

dbLoadRecords("../../db/pico8_ram.template", "P=TST:mem:,NAME=PICO,FTVL=LONG,NELM=7")

# Auto save/restore
save_restoreDebug(2)

#dbLoadRecords("db/save_restoreStatus.db", "P=picotest:")
#save_restoreSet_status_prefix("picotest:")

set_savefile_path("${PWD}/as","/save")
set_requestfile_path("${PWD}/as","/req")

set_pass0_restoreFile("pico_settings.sav")
set_pass1_restoreFile("pico_waveforms.sav")

system("install -d as/req")
system("install -d as/save")

iocInit()

makeAutosaveFileFromDbInfo("as/req/pico_settings.req", "autosaveFields_pass0")
makeAutosaveFileFromDbInfo("as/req/pico_waveforms.req", "autosaveFields_pass1")

create_monitor_set("pico_settings.req", 10 , "")
create_monitor_set("pico_waveforms.req", 30 , "")
