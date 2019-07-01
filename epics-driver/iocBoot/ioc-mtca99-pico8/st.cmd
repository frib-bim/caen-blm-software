#!../../bin/linux-x86_64-debug/pico

< envPaths

var reToolsVerbose 0

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO3", "/dev/amc_pico_0000:08:00.0")
#createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")
#createPICO8("PICO5", "/dev/amc_pico_0000:09:00.0")
createPICO8("PICO6", "/dev/amc_pico_0000:0b:00.0")
#createPICO8("PICO7", "/dev/amc_pico_0000:0f:00.0")
#createPICO8("PICO8", "/dev/amc_pico_0000:0d:00.0")
#createPICO8("PICO9", "/dev/amc_pico_0000:07:00.0")

#debugPICO("PICO", 5)

# (SYS):(D)_CHX:Y_Z
# PICO3 CH0 has 1:8 current divider
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA99,NAME=PICO3,ASLO0=8e6,ASLOSQ0=64e12,CYCTIME0=8e2")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA99,NAME=PICO4")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA99,NAME=PICO5")
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA99,NAME=PICO6")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA99,NAME=PICO7")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA99,NAME=PICO8")
#dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA99,NAME=PICO9")

# Add some aliases

# Neutron detector
reAddAlias "DIAG_MTCA99:PICO3_CH0:(.*)" "FE_RFQ:ND_D1025:$1"

# Ion chamber
reAddAlias "DIAG_MTCA99:PICO3_CH1:(.*)" "FS1_STRL:IC_D2233:$1"

var picoSlewLimit 9e99

iocInit()

