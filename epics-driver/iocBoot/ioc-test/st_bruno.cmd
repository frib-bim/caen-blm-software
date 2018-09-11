#!../../bin/linux-x86_64-debug/pico

< envPaths

cd $(TOP)

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","8388648")
epicsEnvSet("PICO_RATE_LIMIT", "10.0")

dbLoadDatabase("dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase) 

#system("insmod ../linux-driver/amc_pico.ko")

#createPICO8("PICOD", "/dev/amc_pico_0000:06:00.0")
#createPICO8("PICO3", "/dev/amc_pico_0000:07:00.0")
#dbLoadRecords("db/pico8_frib.db","SYS=TST,D=picod,NAME=PICOD,NELM=1048576")
#dbLoadRecords("db/pico8_frib.db","SYS=TST,D=pico3,NAME=PICO3,NELM=1048576")

createPICO8("PICO3", "/dev/amc_pico_0000:06:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:09:00.0")
createPICO8("PICO5", "/dev/amc_pico_0000:0a:00.0")

dbLoadRecords("db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO3,NAME=PICO3,NELM=1048576")
dbLoadRecords("db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO4,NAME=PICO4,NELM=1048576")
dbLoadRecords("db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO5,NAME=PICO5,NELM=1048576")

#dbLoadRecords("db/pico8_chan_alias.db", "P=TST:picod_CH0:,A=TST_ALIAS:picod_CH0:")

# Auto save/restore
#save_restoreDebug(2)

#set_savefile_path("as","/save")
#set_requestfile_path("as","/req")

#set_pass0_restoreFile("pico_settings.sav")
#set_pass1_restoreFile("pico_waveforms.sav")

#system("install -d as/req")
#system("install -d as/save")


## Start the PICO python helper script
#system "python iocBoot/scripts/blm_processing_thread.py TST:picod &"


iocInit()

#makeAutosaveFileFromDbInfo("as/req/pico_settings.req", "autosaveFields_pass0")
#makeAutosaveFileFromDbInfo("as/req/pico_waveforms.req", "autosaveFields_pass1")

#create_monitor_set("pico_settings.req", 10 , "")
#create_monitor_set("pico_waveforms.req", 30 , "")

# disable slew time difference between CPU and EVR
var picoSlewLimit 9e99

dbl > records.dbl

#dbpf "TST:picod_FPS:SLT_CSET", "7"    # Initialize PICO to AMC SLOT = 7
# dbpf "TST:pico3_FPS:SLT_CSET", "3"    # Initialize PICO to AMC SLOT = 3

#dbpf TST:picod_CH0:CWBEAM_CSET 0
