# !!! This file was auto generated by IOC Manager
# !!! Manual changes are not recommended and may be overwritten

reAddInfo "^.*:(FC|HMR|IC|ND)_D.*[_:]AVGS_RD$" "archive" "monitor:0.5, retention: 3mo"
reAddInfo "^.*:(FC|HMR|IC|ND)_D.*[_:]AVG_RD$" "archive" "monitor:2.0, retention: inf"
reAddInfo "^.*:(FC|HMR|IC|ND)_D.*[_:]LAVG_RD$" "archive" "monitor:1.0, retention: 3mo"
reAddInfo "^.*:(FC|HMR|IC|ND)_D.*[_:]STD_RD$" "archive" "monitor:1.0, retention: 3mo"
# IOC / Firmware versions
reAddInfo "^.*:(ioc_version|FFWVER_RD)$" "archive" "monitor:1.0, retention: inf"
reAddInfo "^.*:CWBEAM_CSET$" "archive" "monitor:1.0, retention: 12mo"
reAddInfo "^.*:DESC_RD$" "archive" "monitor:1.0, retention: inf"
# Acquisition Ranges
reAddInfo "^.*:EEPROM_RNG[01]_RD$" "archive" "monitor:1.0, retention: 12mo"
reAddInfo "^.*:EMS_D.*[_:]AVG_RD$" "archive" "monitor:2.0, retention: 3mo"
reAddInfo "^.*:PM_D.*[_:]AVG_RD$" "archive" "monitor:2.0, retention: 3mo"
# EEPROM / FPGA gain / offset
reAddInfo "^.*:RNG[01]_(EE|FPGA)(GAIN|OFST)_RD$" "archive" "monitor:1.0, retention: inf"
reAddInfo "^.*:RNG_CMD$" "archive" "monitor:1.0, retention: 12mo"
reAddInfo "^.*:SAT_RSTS$" "archive" "monitor:1.0, retention: 3mo"
reAddInfo "^.*:TOF_CSET$" "archive" "monitor:1.0, retention: 12mo"
reAddInfo "^.*:TRIP_(ALL_|)RSTS$" "archive" "monitor:1.0, retention: inf"
# MPS Soft Trips
reAddInfo "^.*:TRIP_1.*(LO|HI)_CSET$" "archive" "monitor:1.0, retention: inf"
reAddInfo "^.*:TRIP_EN_CMD$" "archive" "monitor:1.0, retention: inf"
# Long Average Trips
reAddInfo "^.*:TRIP_LAVG(LO|HI|TIME)(EN_CMD|(_CSET|_RSTS))$" "archive" "monitor:1.0, retention: inf"
reAddInfo "^.*:TRIP_RSTS$" "archive" "monitor:1.0, retention: inf"
reAddInfo "^.*_CTRL:ISRMAX_RD$" "archive" "monitor:1.0, retention: inf"
reAddInfo "^.*_CTRL:PLSCNT_RD$" "archive" "monitor:1.0, retention: inf"
reAddInfo "^.*_D.*:.*PKAVG_RD$" "archive" "monitor:0.1, retention: 12mo"
reAddInfo "^.*_FPS:NOK_RSTS$" "archive" "monitor:1.0, retention: inf"
