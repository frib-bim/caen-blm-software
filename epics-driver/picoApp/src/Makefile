TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#=============================
# Build the IOC application

LIBRARY_IOC = pico8Support

pico8Support_SRCS += pico.cpp
pico8Support_SRCS += fdhelper.cpp
pico8Support_SRCS += dev.cpp
pico8Support_SRCS += tbuf.cpp

DBD += pico8.dbd

ifneq ($(SKIP_TEST),YES)

PROD_IOC = pico
# pico.dbd will be created and installed
DBD += pico.dbd

# pico.dbd will be made up from these files:
pico_DBD += base.dbd
pico_DBD += system.dbd

# Include dbd files from all support applications:
pico_DBD += pico8.dbd

# Add all the support libraries needed by this IOC
#pico_LIBS += xxx

# pico_registerRecordDeviceDriver.cpp derives from pico.dbd
pico_SRCS += pico_registerRecordDeviceDriver.cpp

# Build the main IOC entry point on workstation OSs.
pico_SRCS_DEFAULT += picoMain.cpp
pico_SRCS_vxWorks += -nil-

ifneq ($(AUTOSAVE),)
pico_DBD += asSupport.dbd
pico_LIBS += autosave
endif

ifneq ($(DEVLIB2),)
pico_DBD += epicspci.dbd
pico_LIBS += epicspci
endif

# Add support from base/src/vxWorks if needed
#pico_OBJS_vxWorks += $(EPICS_BASE_BIN)/vxComLibrary

# Finally link to the EPICS Base libraries
pico_LIBS += pico8Support
pico_LIBS += $(EPICS_BASE_IOC_LIBS)

endif # SKIP_TEST

PROD_IOC += picocli

picocli_SRCS += cli.cpp

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

