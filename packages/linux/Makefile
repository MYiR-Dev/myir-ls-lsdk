#
# Copyright 2017-2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# SDK linux kernel and modules components

SHELL=/bin/bash
include $(FBDIR)/configs/$(CONFIGLIST)
include $(FBDIR)/include/repo.mk

REPO_LIST = linux cryptodev_linux gpu_module lttng_modules
LINUXDIR = $(PACKAGES_PATH)/linux

UEFI_DTB_LIST = freescale/fsl-ls1043a-rdb-sdk.dtb freescale/fsl-ls1046a-rdb-sdk.dtb freescale/fsl-ls2088a-rdb.dtb freescale/fsl-lx2160a-rdb.dtb
PPC32_DTB_LIST = fsl/mpc8548cds_32b.dtb fsl/p1010rdb-pb.dtb fsl/p2020rdb-pc_32b.dtb fsl/p2041rdb.dtb fsl/p3041ds.dtb fsl/p4080ds.dtb fsl/p5040ds.dtb
PPC64_DTB_LIST = fsl/t1023rdb.dtb fsl/t1024rdb.dtb fsl/t1042d4rdb.dtb fsl/t2080rdb.dtb fsl/t4240rdb.dtb


.PHONY: linux
linux: build_kernel cryptodev_linux

build_kernel:
ifeq ($(CONFIG_KERL_LINUX), y)
	@$(call fetch-git-tree,linux,linux) && cd $(LINUXDIR) && \
	curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	$(call fbprint_n,"Building $(KERNEL_TREE) with $$curbrch") && \
	$(call fbprint_n,"Compiler = `$(CROSS_COMPILE)gcc --version | head -1`") && \
	if [ $(DESTARCH) = arm64 -a $(SOCFAMILY) = IMX ]; then \
	    locarch=arm64; dtbstr=freescale/imx*.dtb; \
	elif [ $(DESTARCH) = arm64 -a $(SOCFAMILY) = LS ]; then \
	    locarch=arm64; dtbstr=freescale/fsl*.dtb; extflags="DTC_FLAGS='-@'"; \
	elif [ $(DESTARCH) = arm32 -a $(SOCFAMILY) = LS ]; then \
	    locarch=arm; dtbstr=ls*.dtb; \
	elif [ $(DESTARCH) = arm32 -a $(SOCFAMILY) = IMX ]; then \
	    locarch=arm; dtbstr=imx*.dtb; \
	elif [ $(DESTARCH) = ppc32 -o $(DESTARCH) = ppc64 ]; then \
	    locarch=powerpc; dtbstr=fsl/*.dtb; \
	fi && \
	opdir=$(KERNEL_OUTPUT_PATH)/$$curbrch && mkdir -p $$opdir/tmp && \
	if [ "$(BUILDARG)" = "custom" ]; then \
	    $(MAKE) menuconfig -C $(KERNEL_PATH) O=$$opdir && \
	    $(call fbprint_d,"Custom kernel config: $$opdir/.config") && \
	    $(call fbprint_n,"Then rerun the command with removing \'custom\' to proceed with the customized .config") && exit; \
	fi; \
	$(call fbprint_n,"Total Config List = $(KERNEL_CFG) $(FRAGMENT_CFG)") && \
	if [ ! -f $$opdir/.config ]; then $(MAKE) $(KERNEL_CFG) $(FRAGMENT_CFG) -C $(KERNEL_PATH) O=$$opdir 1>/dev/null; fi && \
	if [ "$(ENDIANTYPE)" = "be" ]; then \
	    sed -i 's/# CONFIG_CPU_BIG_ENDIAN is not set/CONFIG_CPU_BIG_ENDIAN=y/' $$opdir/.config; \
	    echo Big-Endian enabled!; \
	fi && \
	$(MAKE) -j$(JOBS) all -C $(KERNEL_PATH) O=$$opdir && \
        if [ $(DESTARCH) = arm64 -a $(SOCFAMILY) = LS ]; then \
            $(MAKE) $$extflags $(UEFI_DTB_LIST) -C $(KERNEL_PATH) O=$$opdir; \
        fi && \
	if [ $(DESTARCH) = arm32 ]; then \
	    $(MAKE) -j$(JOBS) uImage LOADADDR=80008000 -C $(KERNEL_PATH) O=$$opdir; \
	fi && \
        if [ $(DESTARCH) = ppc32 ]; then \
            $(MAKE) -j$(JOBS) uImage $(PPC32_DTB_LIST) -C $(KERNEL_PATH) O=$$opdir; \
	elif [ $(DESTARCH) = ppc64 ]; then \
	    $(MAKE) -j$(JOBS) uImage $(PPC64_DTB_LIST) -C $(KERNEL_PATH) O=$$opdir; \
	fi && \
	if [ $(DESTARCH) = arm32 -o $(DESTARCH) = arm64 ]; then \
	    $(MAKE) zinstall \
	    INSTALL_PATH=$(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY) -C $(KERNEL_PATH) O=$$opdir; \
	fi && \
	if [ $(DESTARCH) = ppc32 -o $(DESTARCH) = ppc64 ]; then \
	    cp $$opdir/arch/$$locarch/boot/uImage $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY); \
	    tail -c +65 $$opdir/arch/$$locarch/boot/uImage > $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY)/Image.gz; \
	fi && \
	if [ $(DESTARCH) = arm64 ]; then \
	    cp $$opdir/arch/$$locarch/boot/Image* $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY); \
	elif [ $(DESTARCH) = arm32 ]; then \
	    cp -f $$opdir/arch/$$locarch/boot/uImage $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY); \
	    cp -f $$opdir/arch/$$locarch/boot/zImage $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY); \
	fi && \
	rm -rf $$opdir/tmp && \
        $(MAKE) -j$(JOBS) modules -C $(KERNEL_PATH) O=$$opdir && \
        $(MAKE) -j$(JOBS) modules_install INSTALL_MOD_PATH=$$opdir/tmp -C $(KERNEL_PATH) O=$$opdir && \
	$(MAKE) -j$(JOBS) headers_install INSTALL_HDR_PATH=$$opdir/tmp -C $(KERNEL_PATH) O=$$opdir && \
	if [ $(VIRTABLE) = y ]; then $(MAKE) -j$(JOBS) bindeb-pkg -C $(KERNEL_PATH) O=$$opdir; fi && \
	ls $$opdir/arch/$$locarch/boot/dts/$$dtbstr | xargs -I {} cp {} $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY) && \
	ls -l $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY) && \
	$(call fbprint_d,"$(KERNEL_TREE) $$curbrch in $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY)")
endif


.PHONY: cryptodev_linux
cryptodev_linux:
ifeq ($(CONFIG_KERL_CRYPTODEV_LINUX), y)
	@[ "$(BUILDARG)" = custom ] && exit || \
	 $(call fetch-git-tree,cryptodev_linux,linux) && $(call fetch-git-tree,linux,linux) && cd $(LINUXDIR) && \
	 if [ ! -d $(FBOUTDIR)/linux/kernel/$(DESTARCH)/$(SOCFAMILY) ]; then \
	     flex-builder -c linux -a $(DESTARCH) -p $(SOCFAMILY) -f $(CONFIGLIST); \
	 fi && \
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 opdir=$(KERNEL_OUTPUT_PATH)/$$curbrch && cd $(LINUXDIR)/cryptodev_linux && $(call fbprint_b,"CRYPTODEV_LINUX") && \
	 export KERNEL_MAKE_OPTS="-lcrypto -L$(RFSDIR)/usr/lib/aarch64-linux-gnu" && $(MAKE) KERNEL_DIR=$(KERNEL_PATH) O=$$opdir && \
	 $(MAKE) install KERNEL_DIR=$(KERNEL_PATH) O=$$opdir INSTALL_MOD_PATH=$$opdir/tmp && \
	 $(call fbprint_d,"CRYPTODEV_LINUX")
endif


perf:
	@$(call fetch-git-tree,$(KERNEL_TREE),linux) && cd $(LINUXDIR) && \
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 opdir=$(KERNEL_OUTPUT_PATH)/$$curbrch && \
	 $(call fbprint_b,"kernel tools/perf") && \
	 if [ ! -d $$opdir ]; then mkdir -p $$opdir; fi && \
	 if [ ! -f $$opdir/.config ]; then $(MAKE) $(KERNEL_CFG) -C $(KERNEL_PATH) O=$$opdir 1>/dev/null; fi && \
	 $(MAKE) -j$(JOBS) tools/perf -C $(KERNEL_PATH) O=$$opdir && \
	 cp $$opdir/tools/perf/perf $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY) && \
	 ls -l $(FBOUTDIR)/linux/$(KERNEL_TREE)/$(DESTARCH)/$(SOCFAMILY)/perf && \
	 $(call fbprint_d,"kernel tools/perf")


.PHONY: gpu_module
gpu_module:
ifeq ($(CONFIG_KERL_GPU_MODULE), y)
	@[ "$(BUILDARG)" = custom ] && exit || \
	 [ $(DESTARCH) = ppc32 -o $(DESTARCH) = ppc64 ] && exit || \
	 $(call fetch-git-tree,gpu_module,linux)
	@if [ ! -d $(LINUXDIR)/gpu_module/hal/kernel ]; then \
	     cd $(LINUXDIR) && echo Downloading $(gpu_module_bin_url) && \
             curl -R -k -f $(gpu_module_bin_url) -o gpu_module.bin && chmod +x gpu_module.bin && \
             ./gpu_module.bin --auto-accept && mv gpu-module-* gpu_module && rm -f gpu_module.bin; \
         fi && \
	 $(call fetch-git-tree,$(KERNEL_TREE),linux) && \
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 opdir=$(KERNEL_OUTPUT_PATH)/$$curbrch && mkdir -p $$opdir && \
	 cd $(LINUXDIR)/gpu_module && $(call fbprint_b,"gpu_module") && \
	 $(MAKE) KERNEL_DIR=$(KERNEL_PATH) O=$$opdir && \
	 $(MAKE) KERNEL_DIR=$(KERNEL_PATH) O=$$opdir INSTALL_MOD_PATH=$$opdir/tmp install && \
	 $(call fbprint_d,"gpu_module")
endif


.PHONY: lttng_modules
lttng_modules:
	@$(call fetch-git-tree,lttng_modules,linux) && \
	 $(call fetch-git-tree,$(KERNEL_TREE),linux) && \
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 opdir=$(KERNEL_OUTPUT_PATH)/$$curbrch && mkdir -p $$opdir && \
	 if ! grep CONFIG_STACKTRACE=y $$opdir/.config 1>/dev/null 2>&1; then \
	     flex-builder -c linux -B fragment:lttng.config -a $(DESTARCH) -p $(SOCFAMILY) -f $(CONFIGLIST); \
	 fi && \
	 cd $(LINUXDIR)/lttng_modules && $(call fbprint_b,"LTTng modules") && \
	 $(MAKE) KERNELDIR=$(KERNEL_PATH) O=$$opdir && \
	 $(MAKE) KERNELDIR=$(KERNEL_PATH) O=$$opdir modules_install && \
	 $(call fbprint_d,"LTTng modules")


repo_fetch:
	@echo -e "\nfetch linux repositories"
	@$(call repo-update,fetch,$(LINUX_REPO_LIST),linux)

repo_update_branch:
	@echo -e "\nlinux repositories update for branch"
	@$(call repo-update,branch,$(LINUX_REPO_LIST),linux)

repo_update_tag:
	@echo -e "\nlinux repositories update for tag"
	@$(call repo-update,tag,$(LINUX_REPO_LIST),linux)

repo_update_latest:
	@echo -e "\nlinux repositories update to latest HEAD commit"
	@$(call repo-update,update,$(LINUX_REPO_LIST),linux)

repo_update_commit:
	@echo -e "\nlinux repositories update to specified commit ID"
	@$(call repo-update,commit,$(LINUX_REPO_LIST),linux)
