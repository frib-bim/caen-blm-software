TOP=../..
include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE

DB += pico8.db
DB += pico8_frib_capture.db
DB += pico8_frib_reg.db
DB += pico8_chan_alias.db

ifneq ($(AUTOSAVE),)
DB_INSTALLS += $(firstword $(wildcard $(AUTOSAVE)/asApp/Db/save_restoreStatus.db $(AUTOSAVE)/db/save_restoreStatus.db))
endif

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

