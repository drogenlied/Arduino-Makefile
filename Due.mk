########################################################################
#
# Support for Arduino Due boards
#
# Copyright (C) 2016 Jan M. Binder based on
# work that is copyright Sudar, Nicholas Zambetti, David A. Mellis,
# Hernando Barragan & Jeremy Shaw 
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# Adapted from Arduino 0011 Makefile by M J Oldfield
#
# Original Arduino adaptation by mellis, eighthave, oli.keller
#
# Refer to HISTORY.md file for complete history of changes
#
########################################################################


ifndef ARDMK_DIR
    ARDMK_DIR := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
endif

# include Common.mk now we know where it is
include $(ARDMK_DIR)/Common.mk

ARDMK_VENDOR        = arduino
ARCHITECTURE        = sam

ifndef HW_VERSION
    HW_VERSION          = 1.6.8
endif

ifndef  PACKAGES_DIR
    PACKAGES_DIR        = $(HOME)/.arduino15/packages/arduino
endif

ifndef HW_DIR
    HW_DIR              = $(PACKAGES_DIR)/hardware/$(ARCHITECTURE)/$(HW_VERSION)
endif

ifndef TOOLS_DIR
    TOOLS_DIR           = $(PACKAGES_DIR)/tools
endif

ifndef COMPILER_DIR
    COMPILER_DIR        = $(TOOLS_DIR)/arm-none-eabi-gcc/4.8.3-2014q1
endif

ifndef LOADER_DIR
    LOADER_DIR        = $(TOOLS_DIR)/bossac/1.6.1-arduino
endif

ifndef AVR_TOOLS_DIR
    AVR_TOOLS_DIR       = $(COMPILER_DIR)
endif

ifndef ARDUINO_PLATFORM_LIB_PATH
    ARDUINO_PLATFORM_LIB_PATH = $(HW_DIR)/libraries
endif

ifndef ARDUINO_VAR_PATH
    ARDUINO_VAR_PATH    = $(HW_DIR)/variants
endif

ifndef ARDUINO_CORE_PATH
    ARDUINO_CORE_PATH   = $(HW_DIR)/cores/arduino
endif

ifndef ARDUINO_SYSTEM_PATH
    ARDUINO_SYSTEM_PATH = $(HW_DIR)/system
endif

ifndef  BOARDS_TXT
    BOARDS_TXT          = $(HW_DIR)/boards.txt
endif

ifndef PLATFORM_TXT
    PLATFORM_TXT        = $(HW_DIR)/platform.txt
endif

# newline definition for file parsing, do not remove the two newlines inside
define nl


endef

# parse boards.txt into makefile format
# this gives us all of the variable substitutions in that file for free
# obviously it is quite the hack but we do not have the build dir yet where we could store
# an intermediate file
# Explanation:
# awk -F=                                       set = as field separator
#   if ($$0 !~ /^($$|[:space:]*\#)/)            ignore all commented lines, also with spaces before comment
#   st = index($$0,"=");                        save place of first = in case there is more than one in the line
#   print "ACFG_"$$1" = "substr($$0,st+1)" "    print first field prefixed with ACFG_ , then = and then the rest of the line
# sed -e 's/{\([^}]*\)}/$$(ACFG_\1)/g'          replace variables in {} brackets with $(ACFG_variabel.name)
# sed -e 's/%/\\%/' -e 's/$$/%/'                replace % with \% and then rthe line end with %
BOARD_VARS := $(shell awk -F= '{if ($$0 !~ /^($$|[:space:]*\#)/){{st = index($$0,"="); print "ACFG_"$$1" = "substr($$0,st+1)" "};}}' $(BOARDS_TXT) | sed -e 's/{\([^}]*\)}/$$(ACFG_\1)/g' | sed -e 's/%/\\%/g' -e 's/$$/%/' )

# replace all the % signs by newline and evaluate as makefile code
$(eval $(patsubst \\\%, \%, $(patsubst \%, $(nl), $(BOARD_VARS) ) ) )
#$(info  "CC_NAME "$(ACFG_name))

# overwrite build.* variables from boards.txt before they are used in platform.txt
# this should be automated...
ACFG_build.vid = $(ACFG_$(BOARD_TAG).build.vid)
ACFG_build.pid = $(ACFG_$(BOARD_TAG).build.pid)
ACFG_build.usb_product = $(ACFG_$(BOARD_TAG).build.usb_product)
ACFG_build.usb_manufacturer = $(ACFG_$(BOARD_TAG).build.usb_manufacturer)
ACFG_build.system.path = $(ARDUINO_SYSTEM_PATH)

# parse platform.txt into makefile format
# this gives us all of the variable substitutions in that file for free
# obviously it is quite the hack but we do not have the build dir yet where we could store
# an intermediate file
# Explanation:
# awk -F=                                       set = as field separator
#   if ($$0 !~ /^($$|[:space:]*\#)/)            ignore all commented lines, also with spaces before comment
#   st = index($$0,"=");                        save place of first = in case there is more than one in the line
#   print "ACFG_"$$1" = "substr($$0,st+1)" "    print first field prefixed with ACFG_ , then = and then the rest of the line
# sed -e 's/{\([^}]*\)}/$$(ACFG_\1)/g'          replace variables in {} brackets with $(ACFG_variabel.name)
# sed -e 's/%/\\%/' -e 's/$$/%/'                replace % with \% and then rthe line end with %

PLATFORM_VARS := $(shell awk -F= '{if ($$0 !~ /^($$|[:space:]*\#)/){{st = index($$0,"="); print "ACFG_"$$1" = "substr($$0,st+1)" "};}}' $(PLATFORM_TXT) | sed -e 's/{\([^}]*\)}/$$(ACFG_\1)/g' | sed -e 's/%/\\%/g' -e 's/$$/%/' )

#$(info  "CC_NAME "$(PLATFORM_VARS))
# replace all the % signs by newline and evaluate as makefile code
$(eval $(patsubst \\\%, \%, $(patsubst \%, $(nl), $(PLATFORM_VARS) ) ) )
#$(info  "CC_NAME "$(ACFG_name))

ifndef F_CPU
    F_CPU := $(ACFG_$(BOARD_TAG).build.f_cpu)
    ifndef F_CPU
        F_CPU=84000000
    endif
endif

########################################################################
# command names
ifndef CC_NAME
    CC_NAME := $(ACFG_compiler.c.cmd)
    ifndef CC_NAME
        CC_NAME := arm-none-eabi-gcc
    else
        $(call show_config_variable,CC_NAME,[COMPUTED])
    endif
endif

ifndef CXX_NAME
    CXX_NAME := $(ACFG_compiler.cpp.cmd)
    ifndef CXX_NAME
        CXX_NAME := arm-none-eabi-g++
    else
        $(call show_config_variable,CXX_NAME,[COMPUTED])
    endif
endif

ifndef AS_NAME
    AS_NAME := $(ACFG_compiler.S.cmd)
    ifndef AS_NAME
        AS_NAME := arm-none-eabi-gcc
    else
        $(call show_config_variable,AS_NAME,[COMPUTED])
    endif
endif

ifndef OBJCOPY_NAME
    OBJCOPY_NAME := $(ACFG_compiler.objcopy.cmd)
    ifndef OBJCOPY_NAME
        OBJCOPY_NAME := arm-none-eabi-objcopy
    else
        $(call show_config_variable,OBJCOPY_NAME,[COMPUTED])
    endif
endif

ifndef OBJDUMP_NAME
    OBJDUMP_NAME := $(ACFG_compiler.objdump.cmd)
    ifndef OBJDUMP_NAME
        OBJDUMP_NAME := arm-none-eabi-objdump
    else
        $(call show_config_variable,OBJDUMP_NAME,[COMPUTED])
    endif
endif

ifndef AR_NAME
    AR_NAME := $(ACFG_compiler.ar.cmd)
    ifndef AR_NAME
        AR_NAME := arm-none-eabi-ar
    else
        $(call show_config_variable,AR_NAME,[COMPUTED])
    endif
endif

ifndef SIZE_NAME
    SIZE_NAME := $(ACFG_compiler.size.cmd)
    ifndef SIZE_NAME
        SIZE_NAME := arm-none-eabi-size
    else
        $(call show_config_variable,SIZE_NAME,[COMPUTED])
    endif
endif

ifndef NM_NAME
    NM_NAME := $(ACFG_compiler.nm.cmd)
    ifndef NM_NAME
        NM_NAME := arm-none-eabi-gcc-nm
    else
        $(call show_config_variable,NM_NAME,[COMPUTED])
    endif
endif

# processor stuff
ifndef MCU
    MCU := $(ACFG_$(BOARD_TAG).build.mcu)
endif

ifndef MCU_FLAG_NAME
    MCU_FLAG_NAME=mcpu
endif

########################################################################
# FLAGS

EXTRA_CORE += USB avr

ifndef USB_TYPE
    USB_TYPE = USB_SERIAL
endif

ASFLAGS += $(ACFG_compiler.S.flags)
ASFLAGS += $(ACFG_$(BOARD_TAG).build.extra_flags)

CFLAGS += $(ACFG_compiler.c.flags)
CFLAGS += $(ACFG_$(BOARD_TAG).build.extra_flags)

#CPPFLAGS += -DLAYOUT_US_ENGLISH -D$(USB_TYPE)

CPPFLAGS += $(ACFG_compiler.cpp.flags)
CPPFLAGS += $(ACFG_compiler.libsam.c.flags)

CXXFLAGS += $(ACFG_$(BOARD_TAG).build.extra_flags)

ifeq ("$(ACFG_$(BOARD_TAG).build.gnu0x)","true")
    CXXFLAGS_STD      += "-std=gnu++0x"
endif

ifeq ("$(ACFG_$(BOARD_TAG).build.elide_constructors)", "true")
    CXXFLAGS      += -felide-constructors
endif

# linker options
LDFLAGS += $(ACFG_compiler.c.elf.flags)

ifneq ("$(ACFG_$(BOARD_TAG).build.ldscript)",)
    LDFLAGS   += -T$(ARDUINO_VAR_PATH)/$(VARIANT)/$(ACFG_$(BOARD_TAG).build.ldscript)
endif
LDFLAGS += -Wl,-Map,$(OBJDIR)/$(TARGET).map
LDFLAGS += $(ACFG_compiler.c.elf.extra_flags)

LD_EXTRA_FLAGS += -L$(OBJDIR)
LD_EXTRA_FLAGS += -Wl,--cref -Wl,--check-sections -Wl,--gc-sections -Wl,--entry=Reset_Handler
LD_EXTRA_FLAGS += -Wl,--unresolved-symbols=report-all -Wl,--warn-common -Wl,--warn-section-align

LD_START_GROUP = -Wl,--start-group
LD_GROUP_FLAGS += $(ACFG_compiler.combine.flags)
LD_GROUP_FLAGS += $(ARDUINO_VAR_PATH)/$(VARIANT)/$(ACFG_$(BOARD_TAG).build.variant_system_lib)
LD_END_GROUP = -Wl,--end-group


# OBJCOPY_HEX_FLAGS = $(ACFG_compiler.elf2hex.flags)
OBJCOPY_EEP_FLAGS = $(ACFG_compiler.objcopy.eep.flags)

########################################################################
# some fairly odd settings so that 'make upload' works
#
# may require additional patches for Windows support

TOUCH_PORT = $(strip $(ACFG_$(BOARD_TAG).upload.use_1200bps_touch))
WAIT_PORT = $(strip $(ACFG_$(BOARD_TAG).upload.wait_for_upload_port))
NATIVE_UPLOAD = $(strip $(ACFG_$(BOARD_TAG).upload.native_usb))

ARD_RESET_ARDUINO := $(shell which ard-reset-arduino 2> /dev/null)
ifndef ARD_RESET_ARDUINO
# same level as *.mk in bin directory when checked out from git
# or in $PATH when packaged
ARD_RESET_ARDUINO = $(ARDMK_DIR)/bin/ard-reset-arduino
endif

ifeq ($(TOUCH_PORT), true)
    ifneq (,$(findstring CYGWIN,$(shell uname -s)))
        RESET_CMD = $(ARD_RESET_ARDUINO) --caterina $(ARD_RESET_OPTS) $(DEVICE_PATH)
    else
        RESET_CMD = $(ARD_RESET_ARDUINO) --caterina $(ARD_RESET_OPTS) $(call get_monitor_port)
    endif
else
    ifneq (,$(findstring CYGWIN,$(shell uname -s)))
        RESET_CMD = $(ARD_RESET_ARDUINO) $(ARD_RESET_OPTS) $(DEVICE_PATH)
    else
        RESET_CMD = $(ARD_RESET_ARDUINO) $(ARD_RESET_OPTS) $(call get_monitor_port)
    endif
endif

ifneq (,$(findstring CYGWIN,$(shell uname -s)))
    DUE_PORT = $(DEVICE_PATH)
else
    DUE_PORT = $(notdir $(call get_monitor_port))
endif

TARGET_UPLOAD = $(TARGET_BIN)
UPLOAD_CMD = $(LOADER_DIR)/$(ACFG_tools.bossac.cmd) --port=$(DUE_PORT) -U $(NATIVE_UPLOAD) -e -w $(ACFG_tools.bossac.upload.params.verify) -b $(TARGET_UPLOAD) -R

########################################################################
# automatially include Arduino.mk for the user

include $(ARDMK_DIR)/Arduino.mk
