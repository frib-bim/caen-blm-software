#!../../bin/linux-x86_64-debug/pico

#< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

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

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO3_CH0:,A=FE_SCS2:EMS_D0718Y:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO3_CH1:,A=FE_SCS2:EMS_D0718X:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO3_CH4:,A=FE_SCS1:EMS_D0739Y:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO3_CH5:,A=FE_SCS1:EMS_D0739X:")

# Slot 4
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO4_CH0:,A=FE_LEBT:PM_D0913Y:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO4_CH1:,A=FE_LEBT:PM_D0913X:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO4_CH2:,A=FE_LEBT:PM_D0884Y:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO4_CH4:,A=FE_LEBT:PM_D0884X:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO4_CH5:,A=FE_LEBT:PM_D0856Y:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO4_CH6:,A=FE_LEBT:PM_D0856X:")

# Slot 5
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO5_CH0:,A=FE_LEBT:PM_D0783A:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO5_CH1:,A=FE_LEBT:PM_D0783B:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO5_CH2:,A=FE_LEBT:PM_D0783C:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO5_CH4:,A=FE_SCS2:PM_D0752A:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO5_CH5:,A=FE_SCS2:PM_D0752B:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO5_CH6:,A=FE_SCS2:PM_D0752C:")

# Slot 6
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO6_CH0:,A=FE_LEBT:PM_D0824A:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO6_CH1:,A=FE_LEBT:PM_D0824B:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO6_CH2:,A=FE_LEBT:PM_D0824C:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO6_CH4:,A=FE_LEBT:PM_D0811A:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO6_CH5:,A=FE_LEBT:PM_D0811B:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO6_CH6:,A=FE_LEBT:PM_D0811C:")

# Slot 7
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO7_CH0:,A=FE_MEBT:PM_D1092A:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO7_CH1:,A=FE_MEBT:PM_D1092B:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO7_CH2:,A=FE_MEBT:PM_D1092C:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO7_CH4:,A=FE_LEBT:PM_D0998A:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO7_CH5:,A=FE_LEBT:PM_D0998B:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO7_CH6:,A=FE_LEBT:PM_D0998C:")

# Slot 8
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO8_CH0:,A=FE_LEBT:FC_D0998:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO8_CH1:,A=FE_LEBT:FC_D0976:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO8_CH2:,A=FE_LEBT:FC_D0811:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO8_CH4:,A=FE_LEBT:FC_D0794:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO8_CH5:,A=FE_SCS1:FC_D0739:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO8_CH6:,A=FE_SCS2:FC_D0718:")

# Slot 9
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO9_CH4:,A=FE_MEBT:FC_D1123:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA:PICO9_CH5:,A=FE_EML:FC_D1100:")

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

makeAutosaveFileFromDbInfo("/usr/local/lib/iocapps/pico8/epics-driver/iocBoot/iocmtcacpu04/as/req/pico_settings.req", "autosaveFields_pass0")
makeAutosaveFileFromDbInfo("/usr/local/lib/iocapps/pico8/epics-driver/iocBoot/iocmtcacpu04/as/req/pico_waveforms.req", "autosaveFields_pass1")

create_monitor_set("pico_settings.req", 10 , "")
create_monitor_set("pico_waveforms.req", 30 , "")
