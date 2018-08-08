#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca15-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA15:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA15:PICO:")

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")
createPICO8("PICO6", "/dev/amc_pico_0000:0b:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO4,NAME=PICO4,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO5,NAME=PICO5,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA15,D=PICO6,NAME=PICO6,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH0:,A=FE_LEBT:PM_D0945:A_")   # CableDB: D0945
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH1:,A=FE_LEBT:PM_D0945:B_")   # CableDB: D0945
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH2:,A=FE_LEBT:PM_D0945:C_")   # CableDB: D0945
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH4:,A=FE_LEBT:PM_D0961:A_")   # CableDB: D0962
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH5:,A=FE_LEBT:PM_D0961:B_")   # CableDB: D0962
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO3_CH6:,A=FE_LEBT:PM_D0961:C_")   # CableDB: D0962

# Slot 4
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH0:,A=FE_LEBT:PM_D0972:A_")   # CableDB: D0976
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH1:,A=FE_LEBT:PM_D0972:B_")   # CableDB: D0976
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH2:,A=FE_LEBT:PM_D0972:C_")   # CableDB: D0976
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH4:,A=FE_LEBT:PM_D0986:A_")   # CableDB: D0986
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH5:,A=FE_LEBT:PM_D0986:B_")   # CableDB: D0986
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO4_CH6:,A=FE_LEBT:PM_D0986:C_")   # CableDB: D0986

# Slot 5
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH0:,A=FE_LEBT:PM_D4051:A_")   # CableDB: D4051
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH1:,A=FE_LEBT:PM_D4051:B_")   # CableDB: D4051
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH2:,A=FE_LEBT:PM_D4051:C_")   # CableDB: D4051
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH4:,A=FE_LEBT:PM_D4144:A_")   # CableDB: D4143
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH5:,A=FE_LEBT:PM_D4144:B_")   # CableDB: D4143
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO5_CH6:,A=FE_LEBT:PM_D4144:C_")   # CableDB: D4143

# Slot 6
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH0:,A=FE_MEBT:PM_D3959:A_")   # CableDB: D3958
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH1:,A=FE_MEBT:PM_D3959:B_")   # CableDB: D3958
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH2:,A=FE_MEBT:PM_D3959:C_")   # CableDB: D3958
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH4:,A=FE_LEBT:PM_D4009:A_")   # CableDB: D4013
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH5:,A=FE_LEBT:PM_D4009:B_")   # CableDB: D4013
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA15:PICO6_CH6:,A=FE_LEBT:PM_D4009:C_")   # CableDB: D4013


## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA15:PICO3 DIAG_MTCA15:PICO4 DIAG_MTCA15:PICO5 DIAG_MTCA15:PICO6 &"


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA15:CPU_N0101:")
save_restoreSet_status_prefix("DIAG_MTCA15:CPU_N0101:")

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
dbpf "DIAG_MTCA15:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA15:PICO4_FPS:SLT_CSET", "4"
dbpf "DIAG_MTCA15:PICO5_FPS:SLT_CSET", "5"
dbpf "DIAG_MTCA15:PICO6_FPS:SLT_CSET", "6"
