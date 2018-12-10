#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:05:00.0")
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=MTCA_TEST,D=PICO3,NAME=PICO3,NELM=1000000")
#dbLoadRecords("../../db/pico8_frib.db","SYS=MTCA_TEST,D=PICO4,NAME=PICO4,NELM=1000000")
#dbLoadRecords("../../db/pico8_frib.db","SYS=MTCA_TEST,D=PICO5,NAME=PICO5,NELM=1000000")

#py "import pico8"
#py "pico8.build('MTCA_TEST:PICO3')"
#py "pico8.build('MTCA_TEST:PICO4')"
#py "pico8.build('MTCA_TEST:PICO5')"

var picoSlewLimit 9e99

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
#dbpf "MTCA_TEST:PICO3_FPS:SLT_CSET", "3"
#dbpf "MTCA_TEST:PICO4_FPS:SLT_CSET", "4"
#dbpf "MTCA_TEST:PICO5_FPS:SLT_CSET", "5"
