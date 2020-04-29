TOP=..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

ifdef BASE_3_15

TESTPROD_HOST += testtbuf
TESTS += testtbuf
testtbuf_SRCS += testtbuf.c
testtbuf_SRCS += picoTest_registerRecordDeviceDriver.cpp
testtbuf_LIBS += pico8Support
testtbuf_LIBS += $(EPICS_BASE_IOC_LIBS)


DBD += picoTest.dbd

picoTest_DBD += base.dbd
picoTest_DBD += pico8.dbd

TESTSCRIPTS_HOST += $(TESTS:%=%.t)

endif

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

