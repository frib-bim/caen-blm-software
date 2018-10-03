#!../../bin/linux-x86_64/pico

# !!! This file was autogenerated by epics-driver/gen-iocs/gen.py

< envPaths

epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","10000000")
epicsEnvSet("ENGINEER", "diag")

dbLoadDatabase("../../dbd/pico.dbd",0,0)
pico_registerRecordDeviceDriver(pdbbase)

# slot numbers from /sys/bus/pci/slots/*/address
{%- for card_num, card_data in mtca_data.cards|dictsort %}
createPICO8("PICO{{ card_num }}", "/dev/amc_pico_0000:{{ card_data.addr }}:00.0")
{%- endfor %}

# (SYS):(D)_CHX:Y_Z
{%- for card_num, card_data in mtca_data.cards|dictsort %}
dbLoadRecords("../../db/pico8_frib.db","SYS=DIAG_MTCA{{ mtca_num }},D=PICO{{ card_num }},NAME=PICO{{ card_num }},NELM=1000000")
{%- endfor %}

< $(TOP)/iocBoot/archiver_tags.cmd

# record name aliases
# (SYS):(D)_CHX:Y_Z -> (A)Y_Z
{% for card_num, card_data in mtca_data.cards|dictsort %}
# Slot {{ card_num }}
  {%- for chan_num, chan_data in card_data.chans|dictsort %}
reAddAlias "DIAG_MTCA{{ mtca_num }}:PICO{{ card_num }}_CH{{ chan_num }}:(.*)" "{{ chan_data.dev }}$1"
  {%- endfor %}
{% endfor %}

< $(TOP)/iocBoot/archiver_chan_tags.cmd

## Start the PICO python helper script
system "python ../../iocBoot/scripts/blm_processing_thread.py {% for card_num, d in mtca_data.cards|dictsort %}DIAG_MTCA{{ mtca_num }}:PICO{{ card_num }} {% endfor -%} &"

iocInit()

## Set PICO card AMC slot numbers on startup for each card.
{%- for card_num, card_data in mtca_data.cards|dictsort %}
dbpf "DIAG_MTCA{{ mtca_num }}:PICO{{ card_num }}_FPS:SLT_CSET", "{{ card_num }}"
{%- endfor %}


