TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#=============================
# Build the IOC application

PROD_IOC = pico
# pico.dbd will be created and installed
DBD += pico.dbd

# pico.dbd will be made up from these files:
pico_DBD += base.dbd

# Include dbd files from all support applications:
pico_DBD += pico8.dbd

# Add all the support libraries needed by this IOC
#pico_LIBS += xxx

# pico_registerRecordDeviceDriver.cpp derives from pico.dbd
pico_SRCS += pico_registerRecordDeviceDriver.cpp

pico_SRCS += pico.cpp
pico_SRCS += dev.cpp

# Build the main IOC entry point on workstation OSs.
pico_SRCS_DEFAULT += picoMain.cpp
pico_SRCS_vxWorks += -nil-

# Add support from base/src/vxWorks if needed
#pico_OBJS_vxWorks += $(EPICS_BASE_BIN)/vxComLibrary

# Finally link to the EPICS Base libraries
pico_LIBS += $(EPICS_BASE_IOC_LIBS)

PROD_IOC += picocli

picocli_SRCS += cli.cpp

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

