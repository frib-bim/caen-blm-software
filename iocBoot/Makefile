TOP = ..
include $(TOP)/configure/CONFIG
DIRS += $(wildcard *ioc*)
DIRS += $(wildcard as*)
DIRS := $(subst /Makefile,,$(wildcard $(addsuffix /Makefile, $(DIRS))))
include $(CONFIG)/RULES_DIRS

