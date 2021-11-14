#
# Copyright 2017-2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# SDK Firmware Components
#


.PHONY: u-boot
uboot u-boot:
ifeq ($(CONFIG_FW_UBOOT), y)
	@if [ $(SOCFAMILY) = LS ]; then $(call fetch-git-tree,uboot,firmware); fi
	@if [ $(SOCFAMILY) = IMX ]; then $(call fetch-git-tree,uboot_imx,firmware); fi
ifeq ($(MACHINE), all)
	@for brd in $(LS_MACHINE_LIST); do \
		if [ $$brd = ls1088ardb_pb ]; then brd=ls1088ardb; fi; \
		if [ $${brd:0:7} = lx2160a ]; then brd=$${brd:0:10}; fi; \
		if [ $(DESTARCH) = arm64 -a $$brd = ls1021atwr ]; then continue; \
		elif [ $(DESTARCH) = arm32 ] && [ $$brd != ls1021atwr ]; then continue; fi; \
		$(call fbprint_n,"*** machine = $$brd ***"); cd $(FWDIR); \
		if [ $$brd = ls2088ardb ]; then brdmsk=*ls208?ardb*; else brdmsk=*$$brd*; fi && \
		for cfg in `ls $(UBOOT_TREE)/configs/$$brdmsk 2>/dev/null | cut -d/ -f3 | grep -iE tfa`; do \
		    $(call build-uboot-target,$$cfg) \
		done; \
	 done
else
	@$(call fbprint_b,"uboot for $(MACHINE)")
	@if [ $(MACHINE) = ls2088ardb -o $(MACHINE) = ls2088aqds ]; then \
	     brdmsk=`echo $(MACHINE)* | sed s/88/8?/`; \
	 elif echo $(MACHINE) | grep -q ^[p,t,P,T].*; then \
	     brdmsk=*`tr '[a-z]' '[A-Z]' <<< $(MACHINE)`*; \
	 elif [ $(MACHINE) = ls1088ardb_pb ]; then \
	     brdmsk=*ls1088ardb*; \
	 elif [ $${MACHINE:0:7} = lx2160a ]; then \
	     brdmsk=*$${MACHINE:0:10}*; \
	 elif [ $(MACHINE) = imx8mqevk ]; then \
	     brdmsk=imx8mq_evk_defconfig; \
	 elif [ $(MACHINE) = imx8mmevk ]; then \
	     brdmsk=imx8mm_evk_defconfig; \
	 elif [ $(MACHINE) = imx8mnevk ]; then \
	     brdmsk=imx8mn_ddr4_evk_defconfig; \
	 elif [ $(MACHINE) = imx8qmmek ]; then \
	     brdmsk=imx8qm_mek_defconfig; \
	 elif [ $(MACHINE) = imx8qxpmek ]; then \
	     brdmsk=imx8qxp_mek_defconfig; \
	 elif [ $(MACHINE) = imx6qsabresd ]; then \
	     brdmsk=mx6qsabresd_defconfig; \
	 elif [ $(MACHINE) = imx6qpsabresd ]; then \
	     brdmsk=mx6qpsabresd_defconfig; \
	 elif [ $(MACHINE) = imx6sllevk ]; then \
	     brdmsk=mx6sllevk_defconfig; \
	 elif [ $(MACHINE) = imx7ulpevk ]; then \
	     brdmsk=mx7ulp_evk_defconfig; \
	 elif echo $(MACHINE) | grep -q ^[imx].*; then \
	     brdmsk=$(MACHINE)_defconfig; \
	 else \
	     brdmsk=*$(MACHINE)*; \
	 fi && \
	 cd $(FWDIR) && \
	 if [ -z "$(BOOTTYPE)" ]; then \
	     $(call fbprint_e,"please specify -b boottype parameter for u-boot on $(MACHINE)"); \
	     exit; \
	 else \
	     if [ $(BOOTTYPE) = tfa -a "$(COT)" = arm-cot-with-verified-boot ]; then \
		 brdcfg=verified_boot; \
	     elif [ $(BOOTTYPE) = tfa -a "$(SECURE)" = y ]; then \
		 brdcfg=tfa_SECURE_BOOT_defconfig; \
	     elif [ $(BOOTTYPE) = tfa ]; then \
		 brdcfg=tfa_defconfig; \
	     elif [ $(BOOTTYPE) = sd ]; then \
		 brdcfg='sdcard|sd_defconfig|*_evk_defconfig|*_mek_defconfig|sllevk_defconfig|ulp_evk_defconfig'; \
	     elif [ $(BOOTTYPE) = qspi ]; then \
		 brdcfg='qspi_defconfig|qspi_SECURE_BOOT_defconfig'; \
	     elif [ $(BOOTTYPE) = nor ]; then \
		 brdcfg='nor|rdb_defconfig|rdb_SECURE_BOOT_defconfig|qds_defconfig|qds_SECURE_BOOT_defconfig'; \
	     elif [ $(BOOTTYPE) = nand ]; then \
		 brdcfg='nand'; \
	     fi; \
	     for cfg in `ls $(UBOOT_TREE)/configs/$$brdmsk 2>/dev/null | cut -d/ -f3 | grep -iE $$brdcfg`; do \
		 $(call build-uboot-target,$$cfg) \
	     done; \
	 fi
endif

define build-uboot-target
	if [ $(SOCFAMILY) = IMX -a ! -d $(FWDIR)/imx_mkimage ]; then $(call fetch-git-tree,imx_mkimage,firmware); fi && \
	if [ $(SOCFAMILY) = IMX -a ! -d $(FWDIR)/linux_firmware ]; then $(call fetch-git-tree,linux_firmware,firmware); fi && \
	if [ $(SOCFAMILY) = IMX -a ! -d $(FWDIR)/seco ]; then $(call fetch-git-tree,seco,firmware); fi && \
	if echo $1 | grep -qE imx8q && [ ! -f $(FWDIR)/imx_scfw/mx8qx-mek-scfw-tcm.bin ]; then \
	     curl -R -k -f $(imx_scfw_bin_url) -o imx_scfw.bin && chmod +x imx_scfw.bin && \
             ./imx_scfw.bin --auto-accept && mv `basename -s .bin $(imx_scfw_bin_url)` imx_scfw && rm -f imx_scfw.bin; \
	fi && \
	if echo $1 | grep -qE 'ls1021a|^mx';  then export ARCH=arm; export CROSS_COMPILE=arm-linux-gnueabihf-; dtbstr=-dtb; \
	elif echo $1 | grep -q ^[p,t,P,T].*;  then export ARCH=powerpc; export CROSS_COMPILE=powerpc-linux-; \
	     if [ ! -f $(FBOUTDIR)/rfs/rootfs_buildroot_ppc32_tiny/host/bin/powerpc-linux-gcc ]; then \
		 flex-builder -i mktoolchain -a ppc32 -f $(CONFIGLIST); fi; \
	     if ! echo "$(PATH)" | grep -q ppc32; then export PATH="$(FBOUTDIR)/rfs/rootfs_buildroot_ppc32_tiny/host/bin:$(PATH)";fi; \
	else export ARCH=arm64;export CROSS_COMPILE=aarch64-linux-gnu-; dtbstr=-dtb; fi && \
	if [ $(MACHINE) != all ]; then brd=$(MACHINE); fi && \
	if [ $$brd = ls1088ardb_pb ]; then brd=ls1088ardb; fi && \
	if [ $${brd:0:7} = lx2160a ]; then brd=$${brd:0:10}; fi && \
	opdir=$(FBOUTDIR)/firmware/u-boot/$$brd/output/$1 && \
	if [ ! -d $$opdir ]; then mkdir -p $$opdir; fi &&  \
	$(call fbprint_n,"config = $1") && if [ ! -f $$opdir/.config ]; then $(MAKE) -C $(UBOOT_TREE) $1 O=$$opdir; fi && \
	$(MAKE) -C $(UBOOT_TREE) -j$(JOBS) O=$$opdir && \
	if echo $1 | grep -iqE 'sdcard|nand'; then \
	   if [ -f $$opdir/u-boot-with-spl-pbl.bin ]; then \
	       srcbin=u-boot-with-spl-pbl.bin; \
	   else \
	       srcbin=u-boot-with-spl.bin; \
	   fi; \
	   if echo $1 | grep -iqE 'SECURE_BOOT'; then \
	       if echo $1 | grep -iqE 'sdcard'; then \
		   cp $$opdir/spl/u-boot-spl.bin $(FBOUTDIR)/firmware/u-boot/$$brd/uboot_$${brd}_sdcard_spl.bin ; \
		   cp $$opdir/u-boot-dtb.bin $(FBOUTDIR)/firmware/u-boot/$$brd/uboot_$${brd}_sdcard_dtb.bin ; \
	       elif echo $1 | grep -iqE 'nand'; then \
		   cp $$opdir/spl/u-boot-spl.bin $(FBOUTDIR)/firmware/u-boot/$$brd/uboot_$${brd}_nand_spl.bin ; \
		   cp $$opdir/u-boot-dtb.bin $(FBOUTDIR)/firmware/u-boot/$$brd/uboot_$${brd}_nand_dtb.bin ; \
	       fi; \
	   fi; \
	   tgtbin=uboot_`echo $1|sed -r 's/(.*)(_.*)/\1/'`.bin; \
	elif echo $1 | grep -iqE 'verified_boot'; then \
	    mkdir -p $(FBOUTDIR)/firmware/atf/$$brd; \
	    cat $$opdir/u-boot-nodtb.bin $$opdir/u-boot.dtb > $$opdir/u-boot-combined-dtb.bin; \
	    cp -f $$opdir/u-boot-nodtb.bin $$opdir/u-boot.dtb $$opdir/u-boot-combined-dtb.bin $(FBOUTDIR)/firmware/atf/$$brd/; \
	    cp -f $$opdir/u-boot.dtb $$opdir/tools/mkimage $(FWDIR)/atf/; \
	    srcbin=u-boot-combined-dtb.bin; \
	else \
	    if echo $1 | grep -qE ^mx; then \
		srcbin=u-boot-dtb.imx; \
		tgtbin=uboot_`echo $1|sed -r 's/(.*)(_.*)/\1/'`.imx; \
	    else \
		srcbin=u-boot$$dtbstr.bin; \
		tgtbin=uboot_`echo $1|sed -r 's/(.*)(_.*)/\1/'`.bin; \
	    fi; \
	fi;  \
	if echo $1 | grep -qE ^imx8; then \
	    flex-builder -c imx_atf -m $(MACHINE) -f $(CONFIGLIST); \
	    $(call imx_mkimage_target, $1) \
	    cp $(FWDIR)/imx_mkimage/$$board_path/flash.bin $(FBOUTDIR)/firmware/u-boot/$$brd/$$tgtbin; \
	else \
	    cp $$opdir/$$srcbin $(FBOUTDIR)/firmware/u-boot/$$brd/$$tgtbin ; \
	fi && \
	$(call fbprint_d,"$(FBOUTDIR)/firmware/u-boot/$$brd/$$tgtbin");
endef

define imx_mkimage_target
    if echo $1 | grep -qE ^imx8mm; then \
	board_path=iMX8M; fdt=fsl-imx8mm-evk.dtb; target=flash_hdmi_spl_uboot; SOC=iMX8MM; \
    elif echo $1 | grep -qE ^imx8mq; then \
	board_path=iMX8M; fdt=fsl-imx8mq-evk.dtb; target=flash_hdmi_spl_uboot; SOC=iMX8MQ; \
    elif echo $1 | grep -qE ^imx8mn; then \
	board_path=iMX8M; fdt=fsl-imx8mn-ddr4-evk.dtb; target=flash_ddr4_evk_no_hdmi; SOC=iMX8MN; \
    elif echo $1 | grep -qE ^imx8qm; then \
	board_path=iMX8QM; fdt=fsl-imx8qm-mek.dtb; target=flash; SOC=iMX8QM; \
	cp $(FWDIR)/linux_firmware/firmware/seco/mx8qm-ahab-container.img $(FWDIR)/imx_mkimage/$$board_path/; \
	cp $(FWDIR)/imx_scfw/mx8qm-mek-scfw-tcm.bin $(FWDIR)/imx_mkimage/$$board_path/scfw_tcm.bin; \
    elif echo $1 | grep -qE ^imx8qx; then \
	board_path=iMX8QX; fdt=fsl-imx8qxp-mek.dtb; target=flash; SOC=iMX8QX; \
	cp $(FWDIR)/seco/firmware/seco/mx8qx-ahab-container.img $(FWDIR)/imx_mkimage/$$board_path/; \
	cp $(FWDIR)/imx_scfw/mx8qx-mek-scfw-tcm.bin $(FWDIR)/imx_mkimage/$$board_path/scfw_tcm.bin; \
    fi; \
    plat=`echo ${MACHINE} | cut -c 1-6`; \
    cp -t $(FWDIR)/imx_mkimage/$$board_path $$opdir/spl/u-boot-spl.bin \
      $$opdir/u-boot-nodtb.bin $$opdir/u-boot.bin $$opdir/arch/arm/dts/$$fdt \
      $(FWDIR)/linux_firmware/firmware/ddr/synopsys/*.bin \
      $(FWDIR)/linux_firmware/firmware/hdmi/cadence/signed_hdmi_imx8m.bin; \
    cp $$opdir/tools/mkimage $(FWDIR)/imx_mkimage/$$board_path/mkimage_uboot; \
    cp $(FWDIR)/imx_atf/build/$$plat/release/bl31.bin $(FWDIR)/imx_mkimage/$$board_path/bl31.bin; \
    cd $(FWDIR)/imx_mkimage && $(MAKE) clean && $(MAKE) SOC=$$SOC $$target;
endef

endif
