#
# Copyright 2017-2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# SDK Networking Components
#


NETWORKING_REPO_LIST = restool tsntool gpp_aioptool aiopsl flib fmlib fmc spc dpdk ovs_dpdk pktgen_dpdk ceetm dce qbman_userspace eth_config crconf
NETDIR = $(PACKAGES_PATH)/apps/networking

networking: $(NETWORKING_REPO_LIST)


.PHONY: restool
restool:
ifeq ($(CONFIG_APP_RESTOOL), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"restool") && $(call fetch-git-tree,restool,apps/networking) && \
	 cd $(NETDIR)/restool && $(MAKE) && $(MAKE) install && \
	 $(call fbprint_d,"restool")
endif
endif



.PHONY: tsntool
tsntool:
ifeq ($(CONFIG_APP_TSNTOOL), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto -o $(DISTROSCALE) = tiny -o $(DISTROSCALE) = mate ] && exit || \
	 $(call fbprint_b,"tsntool") && $(call fetch-git-tree,tsntool,apps/networking) && \
	 $(call fetch-git-tree,linux,linux) && \
	 if [ $(DISTROTYPE) = ubuntu -a ! -f $(RFSDIR)/lib/aarch64-linux-gnu/libnl-genl-3.so ] || \
	 [ $(DISTROTYPE) = yocto -a ! -f $(RFSDIR)/usr/lib/libnl-genl-3.so ]; then $(call build_dependent_rfs); fi && \
	 [ ! -f $(RFSDIR)/usr/local/include/cjson/cJSON.h ] && \
	 flex-builder -c cjson -a $(DESTARCH) -f $(CONFIGLIST) || echo cJSON.h exists && cd $(NETDIR)/tsntool && \
	 export CC="$(CROSS_COMPILE)gcc --sysroot=$(RFSDIR)" && export PKG_CONFIG_SYSROOT_DIR=$(RFSDIR) && \
	 export PKG_CONFIG_LIBDIR=$(RFSDIR)/usr/local/lib/pkgconfig:$(RFSDIR)/usr/lib/pkgconfig:$(RFSDIR)/usr/lib/aarch64-linux-gnu/pkgconfig && \
	 mkdir -p include/linux && cp -f $(KERNEL_PATH)/include/uapi/linux/tsn.h include/linux && $(MAKE) clean && $(MAKE) && \
	 install -d $(DESTDIR)/usr/local/bin && install -d $(DESTDIR)/usr/lib && \
	 install -m 755 tsntool $(DESTDIR)/usr/local/bin/tsntool$$tsnver && \
	 install -m 755 libtsn.so $(DESTDIR)/usr/lib/libtsn.so$$tsnver && \
	 $(call fbprint_d,"tsntool")
endif
endif



.PHONY: gpp_aioptool
gpp_aioptool:
ifeq ($(CONFIG_APP_GPP_AIOPTOOL), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"gpp_aioptool") && $(call fetch-git-tree,gpp_aioptool,apps/networking) && \
	 cd $(NETDIR)/gpp_aioptool && $(MAKE) clean && $(MAKE) && $(MAKE) install && \
	 $(call fbprint_d,"gpp_aioptool")
endif
endif



.PHONY: dpdk
dpdk:
ifeq ($(CONFIG_APP_DPDK), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto -o  $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite -o $(DISTROSCALE) = tiny ] &&  exit || \
	 $(call fbprint_b,"dpdk") && $(call fetch-git-tree,dpdk,apps/networking) && \
	 if [ ! -d $(RFSDIR)/usr/lib ]; then $(call build_dependent_rfs); fi && \
	 if [ ! -f $(DESTDIR)/usr/local/lib/libcrypto.so ]; then \
	     flex-builder -c openssl -r $(DISTROTYPE):$(DISTROSCALE) -a $(DESTARCH) -f $(CONFIGLIST); \
	 fi && \
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 if [ ! -f $(KERNEL_OUTPUT_PATH)/$$curbrch/include/generated/utsrelease.h ]; then $(call build_dependent_linux); fi && \
	 kernelrelease=$(cat $KERNEL_OUTPUT_PATH/$curbrch/include/config/kernel.release) && \
	 cd $(NETDIR)/dpdk && export CROSS=$(CROSS_COMPILE) && export RTE_KERNELDIR=$(KERNEL_OUTPUT_PATH)/$$curbrch && \
	 export LDFLAGS="-L$(DESTDIR)/usr/local/lib -L$(RFSDIR)/lib/aarch64-linux-gnu -L$(RFSDIR)/usr/lib" && \
	 export RTE_SDK=$(PWD) && export RTE_TARGET=arm64-dpaa-linuxapp-gcc && \
	 export MODULES_VERSION=$$kernelrelease && export OPENSSL_PATH=$(RFSDIR)/usr && \
	 $(MAKE) install T=arm64-dpaa-linuxapp-gcc DESTDIR=$(DESTDIR)/usr/local CONFIG_RTE_EAL_IGB_UIO=n CONFIG_RTE_KNI_KMOD=y \
		 CONFIG_RTE_LIBRTE_PMD_OPENSSL=y EXTRA_CFLAGS="-I$(DESTDIR)/usr/local/include -I$(RFSDIR)/usr/include/aarch64-linux-gnu" \
		 EXTRA_LDFLAGS="-L$(DESTDIR)/usr/local/lib -L$(RFSDIR)/lib/aarch64-linux-gnu" && \
	 if [ $(CONFIG_APP_VPP) = y ]; then \
	     $(MAKE) install T=arm64-dpaa-linuxapp-gcc DESTDIR=$(DESTDIR)/usr/local/dpdk4vpp \
		     CONFIG_RTE_EAL_IGB_UIO=n CONFIG_RTE_KNI_KMOD=y CONFIG_RTE_LIBRTE_PMD_OPENSSL=y \
		     EXTRA_CFLAGS="-I$(DESTDIR)/usr/local/include -I$(RFSDIR)/usr/include/aarch64-linux-gnu -Ofast -fPIC -ftls-model=local-dynamic" \
		     EXTRA_LDFLAGS="-L$(DESTDIR)/usr/local/lib -L$(DESTDIR)/usr/local/lib -L$(RFSDIR)/lib/aarch64-linux-gnu"; \
	 fi && \
	 if [ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto ]; then echo pktgen_dpdk is not supported on $(DISTROTYPE) yet; exit; fi && \
	 $(call fbprint_n,"Building DPDK Examples ...") && cd examples && \
	 export CROSS=$(CROSS_COMPILE) && export RTE_SDK=$(NETDIR)/dpdk && export RTE_TARGET=arm64-dpaa-linuxapp-gcc && \
	 export OPENSSL_PATH=$(RFSDIR)/usr && export RTE_SDK_BIN=$(DESTDIR)/usr/local && \
	 $(MAKE) -j$(JOBS) -C l2fwd-crypto CONFIG_RTE_LIBRTE_PMD_OPENSSL=y EXTRA_CFLAGS="-I$(RFSDIR)/usr/include/aarch64-linux-gnu" \
		 EXTRA_LDFLAGS="-L$(DESTDIR)/usr/local/lib -L$(RFSDIR)/lib/aarch64-linux-gnu" && $(MAKE) -j$(JOBS) -C vhost && \
	 $(MAKE) -j$(JOBS) -C ipsec-secgw CONFIG_RTE_LIBRTE_PMD_OPENSSL=y EXTRA_CFLAGS="-I$(DESTDIR)/usr/local/include" \
		 EXTRA_LDFLAGS="-L$(DESTDIR)/usr/local/lib -L$(RFSDIR)/lib/aarch64-linux-gnu"  && \
	 dpdk_examples_list="l2fwd l3fwd cmdif l2fwd-qdma ip_fragmentation ip_reassembly l2fwd-keepalive l3fwd-acl link_status_interrupt qdma_demo ethtool \
	 multi_process/symmetric_mp multi_process/simple_mp multi_process/symmetric_mp_qdma timer skeleton rxtx_callbacks ipv4_multicast cmdline kni" && \
	 for dpdkpkg in $$dpdk_examples_list; do $(MAKE) -j$(JOBS) -C $$dpdkpkg; done && \
	 find . -perm -111 -a -type f | xargs -I {} cp {} $(DESTDIR)/usr/local/bin && \
	 mv $(DESTDIR)/usr/local/bin/ethtool $(DESTDIR)/usr/local/bin/dpdk-ethtool && \
	 mkdir -p $(DESTDIR)/usr/local/dpdk/cmdif/include && mkdir -p $(DESTDIR)/usr/local/dpdk/cmdif/lib && \
	 cp cmdif/lib/client/fsl_cmdif_client.h cmdif/lib/server/fsl_cmdif_server.h cmdif/lib/shbp/fsl_shbp.h $(DESTDIR)/usr/local/dpdk/cmdif/include/ && \
	 cp cmdif/lib/arm64-dpaa-linuxapp-gcc/librte_cmdif.a ${DESTDIR}/usr/local/dpdk/cmdif/lib/ && \
	 mkdir -p $(DESTDIR)/usr/local/dpdk/examples/ipsec_secgw && cp -f ipsec-secgw/*.cfg ${DESTDIR}/usr/local/dpdk/examples/ipsec_secgw && \
	 cp -f $(NETDIR)/dpdk/arm64-dpaa-linuxapp-gcc/kmod/rte_kni.ko ${DESTDIR}/usr/local/dpdk && rm -rf ${DESTDIR}/usr/local/home && \
	 echo -e "\nInstalling dpdk-extras ...$(DESTDIR) " && cp -rf $(NETDIR)/dpdk/nxp/* $(DESTDIR)/usr/local/dpdk && \
	 rm -rf $(DESTDIR)/usr/local/share/dpdk/examples && cd $(DESTDIR)/usr/local/bin && rm -f dpdk-pdump && rm -f dpdk-pmdinfo && \
	 rm -f dpdk-procinfo && \
	 $(call fbprint_d,"dpdk")
endif
endif



.PHONY: vpp
vpp:
ifeq ($(CONFIG_APP_VPP), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"vpp") && $(call fetch-git-tree,vpp,apps/networking) && \
	 if [ ! -d $(RFSDIR)/lib/aarch64-linux-gnu ]; then $(call build_dependent_rfs); fi && \
	 if [ ! -f $(RFSDIR)/lib/aarch64-linux-gnu/libnuma.so ]; then \
		sudo chroot $(RFSDIR) apt install -y libnuma-dev; \
	 fi && \
	 if [ ! -d $(RFSDIR)/usr/lib/python3/dist-packages/cffi ]; then \
		sudo chroot $(RFSDIR) apt install -y python3-cffi; \
	 fi && \
	 test -d $(DESTDIR)/usr/local/dpdk4vpp || flex-builder -c dpdk -f $(CONFIGLIST); \
	 export CROSS_PREFIX=aarch64-linux-gnu && export CROSS_TOOLCHAIN=/usr && \
	 export CROSS_SYSROOT=$(RFSDIR) && export ARCH=arm64 && export OPENSSL_PATH=$(RFSDIR)/usr && \
	 export EXTRA_INC=$(RFSDIR)/usr/include/aarch64-linux-gnu && \
	 export EXTRA_LIBS=$(RFSDIR)/lib/aarch64-linux-gnu && \
	 export DPDK_PATH=$(DESTDIR)/usr/local/dpdk4vpp && \
	 export LD_LIBRARY_PATH=$(DESTDIR)/usr/local/dpdk4vpp/lib:$(RFSDIR)/lib/aarch64-linux-gnu && \
	 sudo cp -f $(DESTDIR)/usr/local/dpdk4vpp/lib/librte* $(RFSDIR)/usr/local/lib/ && \
	 if [ ! -f $(RFSDIR)/usr/lib/libssl.so.1.1 ]; then \
		sudo cp -f $(DESTDIR)/usr/local/lib/libssl.so.1.1 $(RFSDIR)/usr/lib/; \
	 fi && \
	 for number in 6 7 8 ; do \
	     if [ -d /usr/lib/python3.$$number -a \
		  ! -f /usr/lib/python3.$$number/_sysconfigdata_m_linux_aarch64-linux-gnu -a \
		  -f $(RFSDIR)/usr/lib/python3.$$number/_sysconfigdata_m_linux_aarch64-linux-gnu.py ]; then \
	         sudo cp -f $(RFSDIR)/usr/lib/python3.$$number/_sysconfigdata_m_linux_aarch64-linux-gnu.py /usr/lib/python3.$$number/; \
	     fi \
	 done && \
	 cd $(NETDIR)/vpp && $(MAKE) -j$(JOBS) install-dep && cd build-root && $(MAKE) distclean && \
	 $(MAKE) -j$(JOBS) V=0 PLATFORM=dpaa TAG=dpaa vpp-package-deb && \
	 mkdir -p $(DESTDIR)/usr/local/vpp && cp -vf *.deb $(DESTDIR)/usr/local/vpp && \
	 sudo mkdir -p $(RFSDIR)/usr/local/vpp && sudo cp -vf *.deb $(RFSDIR)/usr/local/vpp && \
	 echo "compiling VPP completed, installing deb packages"; \
	 ls -l $(RFSDIR)/usr/local/vpp |grep deb | awk '{print $$NF}' > deb.txt && \
	 while read -r filename; do \
	     pkgname=`echo $$filename | cut -d_ -f1`; \
	     if [ "$$pkgname" != "vpp" ]; then \
	         sudo chroot $(RFSDIR) dpkg -l $$pkgname > /dev/null 2>&1; \
		 if [ $$? = 0 ]; then echo $$pkgname && sudo chroot $(RFSDIR) dpkg -r $$pkgname; fi \
	     fi \
	 done < deb.txt && \
	 while read -r filename; do \
	     pkgname=`echo $$filename | cut -d_ -f1`; \
	     if [ "$$pkgname" = "vpp" ]; then \
	         sudo chroot $(RFSDIR) dpkg -l $$pkgname > /dev/null 2>&1; \
		 if [ $$? = 0 ]; then \
		     sudo rm $(RFSDIR)/var/lib/dpkg/info/vpp.*; \
		     sudo chroot $(RFSDIR) dpkg -r --force-depends --force-remove-reinstreq vpp; \
		 fi && \
		 sudo chroot $(RFSDIR) dpkg -i /usr/local/vpp/$$filename; \
	     fi \
	 done < deb.txt && \
	 while read -r filename; do \
		pkgname=`echo $$filename | cut -d_ -f1`; \
		if [ "$$pkgname" != "vpp" ]; then sudo chroot $(RFSDIR) dpkg -i /usr/local/vpp/$$filename; fi \
	 done < deb.txt && \
	 rm deb.txt && sudo chroot $(RFSDIR) apt install -f -y && \
	 sudo cp -f $(DESTDIR)/usr/local/lib/librte* $(RFSDIR)/usr/local/lib/; \
	 $(call fbprint_d,"vpp")
endif
else
	@$(call fbprint_w,INFO: CONFIG_APP_VPP is not enabled by default in configs/$(CONFIGLIST))
endif



.PHONY: pktgen_dpdk
pktgen_dpdk:
ifeq ($(CONFIG_APP_PKTGEN_DPDK), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"pktgen_dpdk") && $(call fetch-git-tree,pktgen_dpdk,apps/networking) && \
	 cd $(NETDIR)/pktgen_dpdk && export CROSS=$(CROSS_COMPILE) && \
	 export RTE_SDK=$(NETDIR)/dpdk && export RTE_TARGET=arm64-dpaa-linuxapp-gcc && \
	 $(MAKE) EXTRA_CFLAGS="-L$(RFSDIR)/usr/lib -L$(RFSDIR)/lib/aarch64-linux-gnu -Wl,-rpath=$(RFSDIR)/usr/lib \
	 -I$(RFSDIR)/usr/include/lua5.3 -I$(RFSDIR)/usr/include/aarch64-linux-gnu" && \
	 cp -f Pktgen.lua ${DESTDIR}/usr/bin && cp -f app/arm64-dpaa-linuxapp-gcc/pktgen ${DESTDIR}/usr/bin && \
	 $(call fbprint_d,"pktgen_dpdk")
endif
endif



.PHONY: ovs_dpdk
ovs_dpdk:
ifeq ($(CONFIG_APP_OVS_DPDK), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto -o $(DISTROSCALE) = mate \
	   -o $(DISTROSCALE) = lite -o $(DISTROSCALE) = tiny ] && exit || \
	 $(call fbprint_b,"ovs_dpdk") && $(call fetch-git-tree,ovs_dpdk,apps/networking) && \
	 [ ! -d $(RFSDIR)/usr/lib ] && $(call build_dependent_rfs) || echo $(RFSDIR) exists && \
	 [ ! -d $(DESTDIR)/usr/local/dpdk ] && flex-builder -c dpdk -r $(DISTROTYPE):$(DISTROSCALE) -f $(CONFIGLIST) || \
	 echo dpdk exists && cd $(NETDIR)/ovs_dpdk && export CROSS=$(CROSS_COMPILE) && \
	 export RTE_SDK=$(NETDIR)/dpdk && export RTE_TARGET=arm64-dpaa-linuxapp-gcc && ./boot.sh && \
	 export LDFLAGS="-L$(RFSDIR)/lib/aarch64-linux-gnu -L$(RFSDIR)/lib -L$(RFSDIR)/usr/lib" && \
	 export LIBS="-ldl -lssl" && ./configure --prefix=/usr/local --host=aarch64-linux-gnu \
	 --with-dpdk=$(DESTDIR)/usr/local --with-openssl=$(RFSDIR)/usr CFLAGS="-g -Wno-cast-align -Ofast \
	 -I$(DESTDIR)/usr/local/include/dpdk -I$(RFSDIR)/usr/include -I$(RFSDIR)/usr/include/aarch64-linux-gnu -lpthread -lssl" && \
	 $(MAKE) -j$(JOBS) install && $(call fbprint_d,"ovs_dpdk")
endif
endif



.PHONY: flib
flib:
ifeq ($(CONFIG_APP_FLIB), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"flib") && $(call fetch-git-tree,flib,apps/networking) && \
	 $(MAKE) -C $(NETDIR)/flib install && $(call fbprint_d,"flib")
endif
endif



.PHONY: fmlib
fmlib:
ifeq ($(CONFIG_APP_FMLIB), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"fmlib") && $(call fetch-git-tree,fmlib,apps/networking) && \
	 [ ! -d $(KERNEL_PATH)/include/uapi/linux/fmd ] && $(call build_dependent_linux) || \
	 echo include/uapi/linux/fmd exists && cd $(NETDIR)/fmlib && \
	 export KERNEL_SRC=$(KERNEL_PATH) && \
	 $(MAKE) clean && $(MAKE) && $(MAKE) install-libfm-arm && \
	 $(call fbprint_d,"fmlib")
endif
endif



.PHONY: fmc
fmc:
ifeq ($(CONFIG_APP_FMC), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROSCALE) = mate -o $(DISTROTYPE) = centos -o $(DISTROSCALE) = tiny ] && exit || \
	 $(call fbprint_b,"fmc") && $(call fetch-git-tree,fmc,apps/networking) && \
	 if [ $(DISTROTYPE) = ubuntu -o $(DISTROTYPE) = yocto -o $(DISTROTYPE) = debian ]; then \
	    xmlhdr=$(RFSDIR)/usr/include/libxml2; \
	 elif [ $(DISTROTYPE) = buildroot ]; then xmlhdr=$(RFSDIR)/../host/include/libxml2; fi && \
	 if [ $(DESTARCH) = arm64 ]; then host=aarch64-linux-gnu; elif [ $(DESTARCH) = arm32 ]; then host=arm-linux-gnueabihf; fi; \
	 [ ! -d $(NETDIR)/fmlib/include/fmd/Peripherals -o ! -f $(DESTDIR)/lib/libfm-arm.a ] && \
	 flex-builder -c fmlib -a $(DESTARCH) -f $(CONFIGLIST) || echo fmlib exists && \
	 if [ ! -f $$xmlhdr/libxml/parser.h ]; then $(call build_dependent_rfs); fi && \
	 if [ ! -d $(KERNEL_PATH)/include/uapi/linux/fmd ]; then $(call build_dependent_linux); fi && \
	 export LDFLAGS="-L$(DESTDIR)/lib -L$(RFSDIR)/lib -L$(RFSDIR)/lib/$$host -L$(RFSDIR)/usr/lib \
	 -Wl,-rpath=$(RFSDIR)/lib:$(RFSDIR)/lib/$$host:$(RFSDIR)/usr/lib:$(RFSDIR)/usr/lib/$$host" && \
	 export CFLAGS="-I$(RFSDIR)/usr/include/$$host -I$(NETDIR)/fmlib/include/fmd \
		-I$(NETDIR)/fmlib/include/fmd/Peripherals -I$(NETDIR)/fmlib/include/fmd/integrations" && \
	 cd $(NETDIR)/fmc && $(MAKE) clean -C source && \
	 $(MAKE) FMD_USPACE_HEADER_PATH=$(KERNEL_PATH)/include/uapi/linux/fmd \
		 FMLIB_HEADER_PATH=$(NETDIR)/fmlib/include \
		 LIBXML2_HEADER_PATH=$$xmlhdr \
		 FMD_USPACE_LIB_PATH=$(DESTDIR)/lib TCLAP_HEADER_PATH=$(RFSDIR)/usr/include \
		 CXX=$(CROSS_COMPILE)g++ CC=$(CROSS_COMPILE)gcc -C source && \
	 install -d $(DESTDIR)/usr/local/bin && \
	 install -m 755 source/fmc $(DESTDIR)/usr/local/bin/fmc && \
	 install -d $(DESTDIR)/etc/fmc/config && \
	 install -m 644 etc/fmc/config/hxs_pdl_v3.xml $(DESTDIR)/etc/fmc/config && \
	 install -m 644 etc/fmc/config/netpcd.xsd $(DESTDIR)/etc/fmc/config && \
	 install -d $(DESTDIR)/usr/local/include/fmc && \
	 install source/fmc.h $(DESTDIR)/usr/local/include/fmc && \
	 install -d $(DESTDIR)/usr/local/lib/$$host && \
	 install source/libfmc.a $(DESTDIR)/usr/local/lib/$$host && \
	 install -d $(DESTDIR)/usr/local/fmc/ && \
	 install -m 755 $(FBDIR)/packages/rfs/misc/fmc/init-ls104xa $(DESTDIR)/usr/local/fmc && \
	 install -d $(DESTDIR)/lib/systemd/system/ && \
	 install -d $(DESTDIR)/etc/systemd/system/multi-user.target.wants/ && \
	 install $(FBDIR)/packages/rfs/misc/fmc/fmc.service $(DESTDIR)/lib/systemd/system/ && \
	 ln -sf /lib/systemd/system/fmc.service $(DESTDIR)/etc/systemd/system/multi-user.target.wants/fmc.service && \
	 $(call fbprint_d,"fmc")
endif
endif


.PHONY: spc
spc:
ifeq ($(CONFIG_APP_SPC), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite -o $(DISTROTYPE) = centos -o $(DISTROSCALE) = tiny ] && exit || \
	 $(call fbprint_b,"SPC") && $(call fetch-git-tree,spc,apps/networking) && \
	 if [ $(DISTROTYPE) = ubuntu -o $(DISTROTYPE) = yocto -o $(DISTROTYPE) = debian ]; then xmlhdr=$(RFSDIR)/usr/include/libxml2; \
	 elif [ $(DISTROTYPE) = buildroot ]; then xmlhdr=$(RFSDIR)/../host/include/libxml2; fi && \
	 if [ ! -f $$xmlhdr/libxml/parser.h ]; then $(call build_dependent_rfs); fi && \
	 export LDFLAGS="-L$(RFSDIR)/lib -L$(RFSDIR)/lib/aarch64-linux-gnu -L$(RFSDIR)/usr/lib \
	 -Wl,-rpath=$(RFSDIR)/lib:$(RFSDIR)/lib/aarch64-linux-gnu:$(RFSDIR)/usr/lib/aarch64-linux-gnu:$(RFSDIR)/usr/lib" && \
	 $(MAKE) LIBXML2_HEADER_PATH=$$xmlhdr TCLAP_HEADER_PATH=$(RFSDIR)/usr/include \
		 NET_USPACE_HEADER_PATH=$(NETDIR)/spc/source/include/net \
		 CXX=$(CROSS_COMPILE)g++ CC=$(CROSS_COMPILE)gcc -C $(NETDIR)/spc/source && \
	 cp -f $(NETDIR)/spc/source/spc $(DESTDIR)/usr/local/bin && cp -rf $(NETDIR)/spc/etc $(DESTDIR) && \
	 $(call fbprint_d,"SPC")
endif
endif


.PHONY: aiopsl
aiopsl:
ifeq ($(CONFIG_APP_AIOPSL), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto -o $(DISTROSCALE) = tiny ] && exit || \
	 $(call fbprint_b,"AIOPSL") && $(call fetch-git-tree,aiopsl,apps/networking) && cd $(NETDIR)/aiopsl && \
	 if [ ! -d $(DESTDIR)/usr/local/aiop/bin ]; then mkdir -p $(DESTDIR)/usr/local/aiop/bin; fi && \
	 cp -rf misc/setup/scripts $(DESTDIR)/usr/local/aiop  && \
	 cp -rf misc/setup/traffic_files $(DESTDIR)/usr/local/aiop && \
	 cp -rf demos/images/* $(DESTDIR)/usr/local/aiop/bin && \
	 $(call fbprint_d,"AIOPSL")
endif
endif



.PHONY: ceetm
ceetm:
ifeq ($(CONFIG_APP_CEETM), y)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"CEETM") && $(call fetch-git-tree,ceetm,apps/networking) && \
	 cd $(NETDIR)/ceetm && \
	 if [ ! -f iproute2-4.15.0/tc/tc_util.h ]; then \
	     wget --no-check-certificate $(iproute2_src_url) && tar xzf iproute2-4.15.0.tar.gz; \
	 fi && \
	 export IPROUTE2_DIR=$(NETDIR)/ceetm/iproute2-4.15.0 && \
	 $(MAKE) clean && $(MAKE) && $(MAKE) install && \
	 $(call fbprint_d,"CEETM")
endif



.PHONY: dce
dce:
ifeq ($(CONFIG_APP_DCE), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto -o $(DISTROSCALE) = tiny ] && exit || \
	 $(call fbprint_b,"dce") && $(call fetch-git-tree,dce,apps/networking) && cd $(NETDIR)/dce && \
	 if [ ! -f lib/qbman_userspace/Makefile ]; then git submodule update; fi && \
	 $(MAKE) ARCH=aarch64 && $(MAKE) install && $(call fbprint_d,"dce")
endif
endif



.PHONY: openstack_nova
openstack_nova:
ifeq ($(CONFIG_APP_OPENSTACK_NOVA), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"openstack_nova") && $(call fetch-git-tree,openstack_nova,apps/networking) && \
	 if [ ! -f $(NETDIR)/openstack_nova/nova/.patched ]; then \
	    cd $(NETDIR)/openstack_nova/nova && sed -zi 's/\,\n\s*retry_on_request\=True//g' db/sqlalchemy/api.py && \
	    sed -i '/from os_brick.initiator import connector/i\from os_brick import initiator' virt/libvirt/volume/drbd.py && \
	    sed -i 's/connector.DRBD/initiator.DRBD/' virt/libvirt/volume/drbd.py && touch .patched; \
	 fi && \
	 cd $(NETDIR)/openstack_nova && sudo python setup.py install \
	    --install-lib=$(RFSDIR)/usr/lib/python2.7/dist-packages --install-scripts=$(RFSDIR)/usr/local/bin && \
	 $(call fbprint_d,"openstack_nova")
endif
else
	@$(call fbprint_w,INFO: CONFIG_APP_OPENSTACK_NOVA is not enabled by default in configs/$(CONFIGLIST))
endif


.PHONY: qbman_userspace
qbman_userspace:
ifeq ($(CONFIG_APP_QBMAN_USERSPACE), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"qbman_userspace") && $(call fetch-git-tree,qbman_userspace,apps/networking) && \
	 cd $(NETDIR)/qbman_userspace && export PREFIX=/usr/local && export ARCH=aarch64 && $(MAKE) && \
	 cp -f lib_aarch64_static/libqbman.a $(DESTDIR)/usr/local/lib/ && \
	 cp -f include/*.h $(DESTDIR)/usr/local/include/ && $(call fbprint_d,"qbman_userspace")
endif
endif


.PHONY: eth_config
eth_config:
ifeq ($(CONFIG_APP_ETH_CONFIG), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROSCALE) = mate -o $(DISTROTYPE) = centos -o $(DISTROSCALE) = tiny ] && exit || \
	 $(call fbprint_b,"eth_config") && $(call fetch-git-tree,eth_config,apps/networking) && \
	 mkdir -p $(DESTDIR)/etc/fmc/config && cd $(NETDIR)/eth_config && \
	 cp -rf private $(DESTDIR)/etc/fmc/config && cp -rf shared_mac $(DESTDIR)/etc/fmc/config && \
	 $(call fbprint_d,"eth_config")
endif
endif


.PHONY: crconf
crconf:
ifeq ($(CONFIG_APP_CRCONF), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"crconf") && $(call fetch-git-tree,crconf,apps/networking) && \
	 sed -i -e 's/CC =/CC ?=/' -e 's/DESTDIR=/DESTDIR?=/' $(NETDIR)/crconf/Makefile && \
	 cd $(NETDIR)/crconf && export CC=$(CROSS_COMPILE)gcc && export DESTDIR=${DESTDIR}/usr/local && \
	 $(MAKE) clean && $(MAKE) && $(MAKE) install && $(call fbprint_d,"crconf")
endif
endif



networking_repo_fetch:
	@echo -e "\nfetch networking repositories: $(NETWORKING_REPO_LIST)"
	@$(call repo-update,fetch,$(NETWORKING_REPO_LIST),apps/networking)

networking_repo_update_branch:
	@echo -e "\nnetworking repositories update for branch"
	@$(call repo-update,branch,$(NETWORKING_REPO_LIST),apps/networking)

networking_repo_update_tag:
	@echo -e "\nnetworking repositories update for tag"
	@$(call repo-update,tag,$(NETWORKING_REPO_LIST),apps/networking)

networking_repo_update_latest:
	@echo -e "\nnetworking repositories update to latest HEAD commit"
	@$(call repo-update,update,$(NETWORKING_REPO_LIST),apps/networking)

networking_repo_update_commit:
	@echo -e "\nnetworking repositories update to specified commit ID"
	@$(call repo-update,commit,$(NETWORKING_REPO_LIST),apps/networking)
