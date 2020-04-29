#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")
epicsEnvSet("DIAGSTD_DISABLE_STATS", "YES")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

var reToolsVerbose 0

# slot numbers from /sys/bus/pci/slots/*/address
createPICO8("PICO4", "/dev/amc_pico_0000:06:00.0")

# (SYS):(D)_CHX:Y_Z
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG,SSYS=MTCA21,NAME=PICO4")

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py DIAG_MTCA21:PICO4 &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
dbpf "DIAG_MTCA21:PICO4_FPS:SLT_CSET", "4"
