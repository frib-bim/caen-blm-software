#!../../bin/linux-x86_64-debug/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
#createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
#createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")
#createPICO8("PICO6", "/dev/amc_pico_0000:0b:00.0")
#createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
#createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")
#createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA99,D=PICO3,NAME=PICO3,NELM=1000000")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA99,D=PICO4,NAME=PICO4,NELM=1000000")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA99,D=PICO5,NAME=PICO5,NELM=1000000")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA99,D=PICO6,NAME=PICO6,NELM=1000000")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA99,D=PICO7,NAME=PICO7,NELM=1000000")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA99,D=PICO8,NAME=PICO8,NELM=1000000")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA99,D=PICO9,NAME=PICO9,NELM=1000000")

var picoSlewLimit 9e99

iocInit()
