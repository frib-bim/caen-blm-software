PICO8 IOC Admin Guide
=====================

Source code is found in

```
git clone https://<username>@stash.nscl.msu.edu/scm/bcm/caen-blm-software.git
```

Two branches are found in this repository 'master' and 'devel'.
The 'master' branch is the stable/tested code.

Linux kernel module
-------------------

The kernel module source is found in the the 'linux-driver/' sub-directory.
The Makefile in this directory uses the Linux kernel build system,
and has the
[usual options](https://www.kernel.org/doc/Documentation/kbuild/modules.txt).
By default it will try to compile against the headers for the
kernel version of the build host.

```
cd linux-driver
make
```

For testing purposes the built module can be loaded directly with 'insmod'.

```
insmod amc_pico.ko
```

This creates a device file '/dev/amc_pico_0000:BB:DD.F' for each card
where BB:DD.F is the PCI geographic address of the device.

uTCA slot to PCI address mapping
--------------------------------

The mapping between uTCA crate slot and PCI B:D.F depends on the topology
of the PCI/PCIe bus of the host computer.
It should remain stable across system reboots as long as this topology does
not change.

The PCI bus topology can be viewed by running

```
lspci -t
-[0000:00]-+-00.0
           +-01.0-[01-0d]----00.0-[02-0d]--+-00.0-[03]--
           |                               +-01.0-[04]----00.0
           |                               +-02.0-[05]--
           |                               +-03.0-[06]--
           |                               +-08.0-[07]--
           |                               +-09.0-[08]----00.0
           |                               +-0a.0-[09]--
           |                               +-10.0-[0a]--
           |                               +-11.0-[0b]--
           |                               +-12.0-[0c]--
           |                               \-13.0-[0d]--
           +-02.0
           +-14.0
           +-16.0
           +-16.3
           +-19.0
           +-1a.0
           +-1c.0-[0e]----00.0
           +-1d.0
           +-1f.0
           +-1f.2
           \-1f.3
```

In this case the uTCA slots have been enumerated as buses 3 through 0xd
with a separate bridge for each slot.

This topology will vary depending on the MCH and CPU models present.

EPICS driver
------------

The EPICS driver source is found in the 'epics-driver/' sub-directory.
The Makefile in this directory uses the EPICS build system.

It may be necessary to edit 'configure/RELEASE' to change 'EPICS_BASE'
if the headers/libraries for EPICS Base aren't located in '/usr/lib/epics'
on the build system.

```
cd epics-driver
make
```

Depending on the build system architecture this will result in the creation of
an executable 'bin/linux-x86/pico' or 'bin/linux-x86_64/pico'.

An EPICS IOC is run with this executable in combination with a
IOC shell (aka 'start') script.
An example is provided as 'iocBoot/ioctest/st.cmd'.

In the case of the PICO8 driver this script will contain one or more pairs of
lines like:

```
createPICO8("dig", "/dev/amc_pico_0000:06:00.0")
dbLoadRecords("../../db/pico8.db","SYS=TST,D=pico,NAME=dig,NELM=100000")
```

The command 'createSIS8300()' associates a device file with an arbitrary internal name,
In this case "dig", which is used in the following line, and which will appear in some log messages.

The process database file 'pico8.db' is loaded with three macros defined.
The macros "SYS" and "D" are used to define the record name prefix "$(SYS):$(D)",
and must be globally unique.
"NAME" is one of the internal device names previously created.
"NELM" is the maximum number of samples per channel that the driver will be capable of reading back.

Restarting IOCs
---------------

To start/stop it run as root

> # service softioc-pico8 <start|stop|restart>

You can attach to the IOC's interactive shell with "console <iocname>" (run "console -u" to list ioc names).
Note that the escape sequence to get out of the shell is Ctrl+e, c, '.'.
Typing 'exit' will restart the IOC (this is actually the preferred way).

EPICS max. array bytes
----------------------

With the PICO8 driver (and other digitizer drivers) it will be necessary to
set the EPICS_CA_MAX_ARRAY_BYTES linux environment variable both in the IOC,
and in all clients reading waveform data.

For the PICO8 driver, the requirement is that EPICS_CA_MAX_ARRAY_BYTES must be >= 4*NELM+100
For example.  If NELM=4194304 then EPICS_CA_MAX_ARRAY_BYTES must be at least 33554432.

In the IOC shell/start script the following should be added before iocInit().

```
epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES","33554532")
```

CA clients should set eg.

```
export EPICS_CA_MAX_ARRAY_BYTES=33554532
```
