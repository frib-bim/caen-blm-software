TOP=../..
include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE

DB += pico8_frib_chan_trip.db
DB += pico8.db
DB += pico8_frib.db
DB += pico8_chan_alias.db
# DB += pico8_ram.template

DB_INSTALLS += $(IOCSTATS)/db/iocAdminSoft.db
DB_INSTALLS += $(RECSYNC)/db/reccaster.db

ifneq ($(AUTOSAVE),)
DB_INSTALLS += $(firstword $(wildcard $(AUTOSAVE)/asApp/Db/save_restoreStatus.db $(AUTOSAVE)/db/save_restoreStatus.db))
endif

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE
