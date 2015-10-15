#!../../bin/linux-x86_64-debug/pico

#< envPaths

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase) 

createPICO8("PICO", "/dev/pico0")

dbLoadRecords("../../db/pico8.db","SYS=TST,D=pico,NAME=PICO")

iocInit()
