#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

epicsEnvSet("AUTOSAVE", "/mnt/iocdata/autosave/mtca09-pico8")

## Channel Access Security config
asSetFilename("${EPICS_CA_SEC_FILE}")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("$(TOP)/db/iocAdminSoft.db", "IOC=DIAG_MTCA09:PICO")
dbLoadRecords("$(TOP)/db/reccaster.db", "P=DIAG_MTCA09:PICO:")

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")
createPICO8("PICO6", "/dev/amc_pico_0000:0b:00.0")
createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA09,D=PICO3,NAME=PICO3,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA09,D=PICO4,NAME=PICO4,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA09,D=PICO5,NAME=PICO5,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA09,D=PICO6,NAME=PICO6,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA09,D=PICO7,NAME=PICO7,NELM=1000000")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA09,D=PICO8,NAME=PICO8,NELM=1000000")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

# Slot 3
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO3_CH0:,A=LS1_BTS:PM_D2056:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO3_CH1:,A=LS1_BTS:PM_D2056:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO3_CH2:,A=LS1_BTS:PM_D2056:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO3_CH4:,A=LS1_BTS:PM_D2131:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO3_CH5:,A=LS1_BTS:PM_D2131:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO3_CH6:,A=LS1_BTS:PM_D2131:C_")

# Slot 4
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO4_CH0:,A=FS1_CSS:PM_D2198:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO4_CH1:,A=FS1_CSS:PM_D2198:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO4_CH2:,A=FS1_CSS:PM_D2198:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO4_CH4:,A=FS1_CSS:PM_D2225:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO4_CH5:,A=FS1_CSS:PM_D2225:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO4_CH6:,A=FS1_CSS:PM_D2225:C_")

# Slot 5
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO5_CH0:,A=FS1_CSS:PM_D2249:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO5_CH1:,A=FS1_CSS:PM_D2249:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO5_CH2:,A=FS1_CSS:PM_D2249:C_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO5_CH4:,A=FS1_CSS:PM_D2385:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO5_CH5:,A=FS1_CSS:PM_D2385:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO5_CH6:,A=FS1_CSS:PM_D2385:C_")

# Slot 6
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO6_CH0:,A=FS1_BTS:PM_D2439:A_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO6_CH1:,A=FS1_BTS:PM_D2439:B_")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO6_CH2:,A=FS1_BTS:PM_D2439:C_")

# Slot 7 : Ion Chamber (BLM)
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO7_CH0:,A=FS1_BTS:IC_D2448:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO7_CH1:,A=FS1_BTS:IC_D2449:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO7_CH2:,A=FS1_BTS:IC_D2478:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO7_CH3:,A=FS1_BTS:IC_D2479:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO7_CH4:,A=FS1_STRL:IC_D2233:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO7_CH5:,A=FS1_STRL:IC_D2234:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO7_CH6:,A=FS1_STRL:IC_D2253:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO7_CH7:,A=FS1_STRL:IC_D2254:")

# Slot 8: Halo Ring Monitor (BLM)
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO8_CH0:,A=LS1_WB10:HMR_D1861:")
dbLoadRecords("../../db/pico8_chan_alias.db", "P=DIAG_MTCA09:PICO8_CH1:,A=LS1_WB11:HMR_D1924:")

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA09:PICO3 DIAG_MTCA09:PICO4 DIAG_MTCA09:PICO5 DIAG_MTCA09:PICO6 DIAG_MTCA09:PICO7 DIAG_MTCA09:PICO8 &"


# Auto save/restore
save_restoreDebug(2)

dbLoadRecords("../../db/save_restoreStatus.db", "P=DIAG_MTCA09:CPU_N0009:")
save_restoreSet_status_prefix("DIAG_MTCA09:CPU_N0009:")

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
dbpf "DIAG_MTCA09:PICO3_FPS:SLT_CSET", "3"
dbpf "DIAG_MTCA09:PICO4_FPS:SLT_CSET", "4"
dbpf "DIAG_MTCA09:PICO5_FPS:SLT_CSET", "5"
dbpf "DIAG_MTCA09:PICO6_FPS:SLT_CSET", "6"
dbpf "DIAG_MTCA09:PICO7_FPS:SLT_CSET", "7"
dbpf "DIAG_MTCA09:PICO8_FPS:SLT_CSET", "8"
