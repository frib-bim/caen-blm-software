THELOG=/tmp/pico8.log

all install distclean:
	echo "`date -R` $(MAKE) $@" >> $(THELOG) || true
	$(MAKE) -C epics-driver $@

.PHONY: all install distclean
