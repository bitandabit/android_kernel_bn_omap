#
# Copyright (C) 2009-2011 The Android-x86 Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
ifeq ($(OMAP_ENHANCEMENT), true)
ifneq ($(KERNEL_DEFCONFIG),)
ROOTDIR := $(abspath $(TOP))
KERNEL_DIR ?= $(ROOTDIR)/kernel
KERNEL_IMAGE_NAME ?= zImage

KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_OUT_ABS := $(abspath $(KERNEL_OUT))
TARGET_PREBUILT_KERNEL := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/$(KERNEL_IMAGE_NAME)
KERNEL_DEFCONFIG_FILE := $(KERNEL_DIR)/arch/$(TARGET_ARCH)/configs/$(KERNEL_DEFCONFIG)
TARGET_KERNEL_HAS_MODULE := $(shell grep -q "CONFIG_MODULES=y" $(KERNEL_DEFCONFIG_FILE) && echo true)
TARGET_KERNEL_CONFIG := $(KERNEL_OUT)/.config
KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules

ifeq ($(KERNEL_CROSS_COMPILE),)
KERNEL_CROSS_COMPILE := arm-eabi-
endif

define mv-modules
mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`;\
ko=`find $$mpath/kernel -type f -name *.ko`;\
for i in $$ko; do mv $$i $(KERNEL_MODULES_OUT)/; done;\
fi
endef

define clean-module-folder
mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`; rm -rf $$mpath;\
fi
endef

$(KERNEL_OUT):
	$(hide) mkdir -p $@

$(KERNEL_MODULES_OUT):
	$(hide) mkdir -p $@

.PHONY: kernel kernel-defconfig kernel-menuconfig kernel-modules clean-kernel

kernel-menuconfig: | $(KERNEL_OUT)
	$(hide) $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_ABS) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) menuconfig

kernel-savedefconfig: | $(KERNEL_OUT) $(ACP)
	$(hide) $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_ABS) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) savedefconfig
	$(hide) $(ACP) $(KERNEL_OUT)/defconfig $(KERNEL_DIR)/arch/$(TARGET_ARCH)/configs/$(KERNEL_DEFCONFIG)

$(TARGET_PREBUILT_KERNEL): kernel

$(TARGET_KERNEL_CONFIG) kernel-defconfig: | $(KERNEL_OUT) $(KERNEL_OUT)/include/generated/trapz_generated_kernel.h
	$(hide) $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_ABS) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG)
ifeq ($(USE_TRAPZ),true)
ifeq ($(USER_DEBUG_PVA), 1)
	$(hide) cat $(KERNEL_DIR)/arch/$(TARGET_ARCH)/configs/trapz_pva.config >> $(TARGET_KERNEL_CONFIG)
else
	$(hide) cat $(KERNEL_DIR)/arch/$(TARGET_ARCH)/configs/trapz.config >> $(TARGET_KERNEL_CONFIG)
endif
endif
ifeq ($(USE_DUMMY_IDME), true)
	$(hide) cat $(KERNEL_DIR)/arch/$(TARGET_ARCH)/configs/amazondummyidme.config >> $(TARGET_KERNEL_CONFIG)
endif
	$(hide) $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_ABS) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) oldconfig

$(KERNEL_HEADERS_INSTALL): $(TARGET_KERNEL_CONFIG) | $(KERNEL_OUT)
	-$(hide) $(MAKE) -k -C $(KERNEL_DIR) O=$(KERNEL_OUT_ABS) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) headers_install

kernel: $(TARGET_KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL) | $(KERNEL_OUT)
	$(hide) $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_ABS) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) $(KERNEL_EXTRA_BUILD_OPTIONS)
ifeq ($(TARGET_KERNEL_HAS_MODULE),true)
	$(hide) $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_ABS) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) modules
	$(hide) $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_ABS) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) INSTALL_MOD_PATH=$(ROOTDIR)/$(KERNEL_MODULES_OUT) INSTALL_MOD_STRIP=1 modules_install
	$(mv-modules)
	$(clean-module-folder)

kernel-modules: kernel | $(KERNEL_MODULES_OUT)

systemimage: kernel-modules

endif # TARGET_KERNEL_HAS_MODULE

$(INSTALLED_KERNEL_TARGET): kernel

$(INSTALLED_KERNEL_TARGET): $(TARGET_PREBUILT_KERNEL) | $(ACP)
	$(copy-file-to-target)
clean-kernel:
	$(hide) rm -rf $(KERNEL_OUT)
	$(hide) rm -rf $(KERNEL_MODULES_OUT)

endif # KERNEL_DEFCONFIG
endif # OMAP_ENHANCEMENT
