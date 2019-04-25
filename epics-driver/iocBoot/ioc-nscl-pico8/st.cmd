#!../../bin/linux-x86_64/pico

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")
epicsEnvSet("DIAGSTD_DISABLE", "YES")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

createPICO8("PICO", "/dev/amc_pico_0000:06:00.0")
dbLoadRecords("../../db/pico8_frib.db","SYS=EGUN,D=PICO,NAME=PICO,NELM=1000000")

system "python ../../iocBoot/scripts/blm_processing_thread.py EGUN:PICO &"

iocInit()

