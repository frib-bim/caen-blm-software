#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca01-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA01:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA01:PICO:")

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
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO4,NAME=PICO4,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO5,NAME=PICO5,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO6,NAME=PICO6,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO7,NAME=PICO7,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO8,NAME=PICO8,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA01,D=PICO9,NAME=PICO9,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO3_CH0:,A=FE_SCS2:EMS_D0718:Y_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO3_CH1:,A=FE_SCS2:EMS_D0718:X_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO3_CH4:,A=FE_SCS1:EMS_D0739:Y_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO3_CH5:,A=FE_SCS1:EMS_D0739:X_")

# Slot 4
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO4_CH0:,A=FE_LEBT:PM_D0912:Y_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO4_CH1:,A=FE_LEBT:PM_D0912:X_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO4_CH2:,A=FE_LEBT:PM_D0885:Y_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO4_CH4:,A=FE_LEBT:PM_D0885:X_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO4_CH5:,A=FE_LEBT:PM_D0856:Y_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO4_CH6:,A=FE_LEBT:PM_D0856:X_")

# Slot 5
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO5_CH0:,A=FE_LEBT:PM_D0783:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO5_CH1:,A=FE_LEBT:PM_D0783:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO5_CH2:,A=FE_LEBT:PM_D0783:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO5_CH4:,A=FE_SCS2:PM_D0752:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO5_CH5:,A=FE_SCS2:PM_D0752:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO5_CH6:,A=FE_SCS2:PM_D0752:C_")

# Slot 6
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO6_CH0:,A=FE_LEBT:PM_D0824:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO6_CH1:,A=FE_LEBT:PM_D0824:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO6_CH2:,A=FE_LEBT:PM_D0824:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO6_CH4:,A=FE_LEBT:PM_D0808:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO6_CH5:,A=FE_LEBT:PM_D0808:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO6_CH6:,A=FE_LEBT:PM_D0808:C_")

# Slot 7
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH0:,A=FE_MEBT:PM_D1092:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH1:,A=FE_MEBT:PM_D1092:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH2:,A=FE_MEBT:PM_D1092:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH4:,A=FE_LEBT:PM_D0998:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH5:,A=FE_LEBT:PM_D0998:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO7_CH6:,A=FE_LEBT:PM_D0998:C_")

# Slot 8
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH0:,A=FE_LEBT:FC_D0796:")   # CableDB: D0794
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH1:,A=FE_LEBT:FC_D0814:")   # CableDB: D0811
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH2:,A=FE_LEBT:FC_D0977:")   # CableDB: D0976
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH4:,A=FE_LEBT:FC_D0998:")   # CableDB: D0998
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH5:,A=FE_EML:FC_D1104:")    # CableDB: D1100
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO8_CH6:,A=FE_MEBT:FC_D1102:")   # CableDB: D1123

# Slot 9
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO9_CH0:,A=FE_SCS2:FC_D0717:")   # CableDB: D0718
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA01:PICO9_CH2:,A=FE_SCS1:FC_D0738:")   # CableDB: D0739

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA01:PICO3 DIAG_MTCA01:PICO4 DIAG_MTCA01:PICO5 DIAG_MTCA01:PICO6 DIAG_MTCA01:PICO7 DIAG_MTCA01:PICO8 DIAG_MTCA01:PICO9 &"


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA01:CPU_N0101:")
save_restoreSet_status_prefix("DIAG_MTCA01:CPU_N0101:")

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
dbpf "DIAG_MTCA01:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA01:PICO4_FPS:SLT_CSET", "4"
dbpf "DIAG_MTCA01:PICO5_FPS:SLT_CSET", "5"
dbpf "DIAG_MTCA01:PICO6_FPS:SLT_CSET", "6"
dbpf "DIAG_MTCA01:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA01:PICO8_FPS:SLT_CSET", "8"
dbpf "DIAG_MTCA01:PICO9_FPS:SLT_CSET", "9"
