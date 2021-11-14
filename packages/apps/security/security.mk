#
# Copyright 2017-2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# SDK Security Components
#

SECURITY_REPO_LIST = cst openssl optee_os optee_client optee_test secure_obj libpkcs11 keyctl_caam
SECDIR = $(PACKAGES_PATH)/apps/security

security: $(SECURITY_REPO_LIST)


.PHONY: cst
cst:
ifeq ($(CONFIG_APP_CST), y)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto -o $(DISTROSCALE) = tiny ] && exit || \
	 $(call fbprint_b,"CST") && $(call fetch-git-tree,cst,apps/security) && \
	 cd $(SECDIR)/cst && $(MAKE) -j$(JOBS) && \
	 if [ -n "$(SECURE_PRI_KEY)" ]; then \
	     echo Using specified $(SECURE_PRI_KEY) and $(SECURE_PUB_KEY) ... ; \
	     cp -f $(SECURE_PRI_KEY) $(SECDIR)/cst/srk.pri; \
	     cp -f $(SECURE_PUB_KEY) $(SECDIR)/cst/srk.pub; \
	 elif [ ! -f srk.pri -o ! -f srk.pub ]; then \
	     ./gen_keys 1024 && echo "Generated new keys!"; \
	 else \
	     echo "Using default keys srk.pri and srk.pub"; \
	 fi && $(call fbprint_d,"CST")
endif



.PHONY: openssl
openssl:
ifeq ($(CONFIG_APP_OPENSSL), y)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto -o $(DISTROSCALE) = mate -o \
	   $(DISTROSCALE) = lite -o $(DISTROSCALE) = tiny ] && exit || \
	 if [ $(DESTARCH) = arm64 ]; then \
	     archopt=linux-aarch64; \
	 elif [ $(DESTARCH) = arm32 ]; then \
	     archopt=linux-armv4; \
	 else \
	     $(call fbprint_e,"$(DESTARCH) is not supported for openssl"); exit; \
	 fi && \
	 $(call fbprint_b,"OpenSSL") && $(call fetch-git-tree,openssl,apps/security) && \
	 [ ! -d $(DESTDIR)/usr/local/include/crypto ] && \
	 flex-builder -c cryptodev_linux -a $(DESTARCH) -f $(CONFIGLIST) || echo cryptodev exists && \
	 cd $(SECDIR)/openssl && ./Configure enable-devcryptoeng $$archopt shared \
	 -I$(DESTDIR)/usr/local/include --prefix=/usr/local --openssldir=lib/ssl && \
	 $(MAKE) clean && $(MAKE) depend && $(MAKE) 1>/dev/null && \
	 $(MAKE) DESTDIR=$(DESTDIR) install 1>/dev/null && \
	 rm -fr $(DESTDIR)/usr/local/lib/ssl/{certs,openssl.cnf,private} && \
	 ln -s /etc/ssl/certs/ $(DESTDIR)/usr/local/lib/ssl/ && \
	 ln -s /etc/ssl/private/ $(DESTDIR)/usr/local/lib/ssl/ && \
	 ln -s /etc/ssl/openssl.cnf $(DESTDIR)/usr/local/lib/ssl/ && \
	 $(call fbprint_d,"OpenSSL")
endif



.PHONY: secure_obj
secure_obj:
ifeq ($(CONFIG_APP_SECURE_OBJ), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"secure_obj") && $(call fetch-git-tree,secure_obj,apps/security) && \
	 [ ! -f $(DESTDIR)/usr/local/include/openssl/opensslconf.h ] && flex-builder -c openssl -f $(CONFIGLIST) || echo openssl exists && \
	 if [ $(CONFIG_APP_OPTEE) != y ]; then \
	     $(call fbprint_e,"Please enable CONFIG_APP_OPTEE to y in configs/$(CONFIGLIST)"); exit 1; \
	 fi && \
	 if [ ! -d $(SECDIR)/optee_os/out/arm-plat-ls ]; then flex-builder -c optee_os -f $(CONFIGLIST); fi && \
	 if [ ! -f $(DESTDIR)/lib/libteec.so ]; then flex-builder -c optee_client -f $(CONFIGLIST); fi && \
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 kerneloutdir=$(KERNEL_OUTPUT_PATH)/$$curbrch && mkdir -p $(DESTDIR)/usr/lib && \
	 if [ ! -f $$kerneloutdir/.config ]; then $(call build_dependent_linux); fi && \
	 kernelrelease=`cat $$kerneloutdir/include/config/kernel.release` && \
	 cd $(SECDIR)/secure_obj && export DESTDIR=${DESTDIR}/usr/local && \
	 export TA_DEV_KIT_DIR=$(SECDIR)/optee_os/out/arm-plat-ls/export-ta_arm64 && \
	 export OPTEE_CLIENT_EXPORT=$(DESTDIR)/usr && export KERNEL_SRC=$(KERNEL_PATH) && \
	 export KERNEL_BUILD=$$kerneloutdir && $(call fbprint_n,"Using KERNEL_BUILD $$kerneloutdir") && \
	 export SECURE_STORAGE_PATH=$(SECDIR)/secure_obj/secure_storage_ta/ta && \
	 export OPENSSL_PATH=$(SECDIR)/openssl && mkdir -p $(DESTDIR)/usr/local/secure_obj/$$curbrch && \
	 mkdir -p $(DESTDIR)/usr/lib/aarch64-linux-gnu/openssl-1.0.0/engines && mkdir -p $(DESTDIR)/lib/optee_armtz && \
	 ./compile.sh && cp images/libeng_secure_obj.so $(DESTDIR)/usr/lib/aarch64-linux-gnu/openssl-1.0.0/engines && \
	 mkdir -p $(KERNEL_OUTPUT_PATH)/$$curbrch/tmp/lib/modules/$$kernelrelease/extra && \
	 cp images/securekeydev.ko $(KERNEL_OUTPUT_PATH)/$$curbrch/tmp/lib/modules/$$kernelrelease/extra/ && \
	 cp images/*.ta $(DESTDIR)/lib/optee_armtz && cp images/*.so $(DESTDIR)/usr/local/lib && \
	 cp images/{*_app,mp_verify} $(DESTDIR)/usr/local/bin && cp -rf securekey_lib/include/* $(DESTDIR)/usr/local/include && \
	 $(call fbprint_d,"secure_obj")
endif
else
	@$(call fbprint_w,INFO: CONFIG_APP_SECURE_OBJ is not enabled by default in configs/$(CONFIGLIST)) && exit
endif



.PHONY: libpkcs11
libpkcs11:
ifeq ($(CONFIG_APP_LIBPKCS11), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"libpkcs11") && $(call fetch-git-tree,libpkcs11,apps/security) && \
	 if [ ! -f $(SECDIR)/openssl/Configure ]; then \
	     echo building dependent openssl ... && \
	     flex-builder -c openssl -a $(DESTARCH) -f $(CONFIGLIST); \
	 fi && \
	 if [ ! -d $(SECDIR)/secure_obj/securekey_lib/include ]; then \
	     echo building dependent secure_obj ... && \
	     flex-builder -c secure_obj -a $(DESTARCH) -f $(CONFIGLIST); \
	 fi && \
	 cd $(SECDIR)/libpkcs11 && $(MAKE) clean && $(MAKE) all OPENSSL_PATH=$(SECDIR)/openssl \
	 EXPORT_DIR=$(DESTDIR)/usr/local CURDIR=$(SECDIR)/libpkcs11 \
	 SECURE_OBJ_PATH=$(SECDIR)/secure_obj/securekey_lib && \
	 mkdir -p $(DESTDIR)/usr/local/bin && \
	 mv $(DESTDIR)/usr/local/app/pkcs11_app $(DESTDIR)/usr/local/bin && \
	 cp -f images/thread_test $(DESTDIR)/usr/bin && $(call fbprint_d,"libpkcs11")
endif
else
	@$(call fbprint_w,INFO: CONFIG_APP_LIBPKCS11 is not enabled by default in configs/$(CONFIGLIST)) && exit
endif



optee: optee_os optee_client optee_test

.PHONY: optee_os
optee_os:
ifeq ($(CONFIG_APP_OPTEE), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"optee_os") && $(call fetch-git-tree,optee_os,apps/security) && \
	 if ! `pip3 show -q pycryptodomex`; then pip3 install pycryptodomex; fi && \
	 if [ $(MACHINE) = all ]; then \
	     for brd in $(LS_MACHINE_LIST); do \
		 if [ $$brd = ls1021atwr -o $$brd = ls1028ardb ]; then continue; fi; \
		 flex-builder -c optee_os -m $$brd -a $(DESTARCH) -f $(CONFIGLIST); \
	     done; \
	 else \
	     if [ $(MACHINE) = ls1088ardb_pb ]; then brd=ls1088ardb; \
	     elif [ $(MACHINE) = lx2160ardb_rev2 ]; then brd=lx2160ardb; \
	     elif [ $(MACHINE) = lx2162aqds ]; then brd=lx2160aqds; \
	     elif [ $(MACHINE) = ls1046afrwy ]; then brd=ls1046ardb; else brd=$(MACHINE); fi && \
	     cd $(SECDIR)/optee_os && $(MAKE) CFG_ARM64_core=y PLATFORM=ls-$$brd ARCH=arm;\
		$(CROSS_COMPILE)\objcopy -v -O binary out/arm-plat-ls/core/tee.elf out/arm-plat-ls/core/tee_$(MACHINE).bin;\
	     if [ $(MACHINE) = ls1012afrwy ]; then \
		mv out/arm-plat-ls/core/tee_$(MACHINE).bin out/arm-plat-ls/core/tee_$(MACHINE)_512mb.bin && \
		$(MAKE) -j$(JOBS) CFG_ARM64_core=y PLATFORM=ls-ls1012afrwy ARCH=arm CFG_DRAM0_SIZE=0x40000000 && \
		$(CROSS_COMPILE)\objcopy -v -O binary out/arm-plat-ls/core/tee.elf out/arm-plat-ls/core/tee_$(MACHINE).bin; \
	     fi; \
	fi && rm -f out/arm-plat-ls/core/tee.bin && $(call fbprint_d,"optee_os")
endif
else
	@$(call fbprint_w,INFO: CONFIG_APP_OPTEE is not enabled by default in configs/$(CONFIGLIST))
endif



.PHONY: optee_client
optee_client:
ifeq ($(CONFIG_APP_OPTEE), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"optee_client") && $(call fetch-git-tree,optee_client,apps/security) && \
	 cd $(SECDIR)/optee_client && $(MAKE) -j$(JOBS) ARCH=arm64 && mkdir -p $(DESTDIR)/usr/local/lib && \
	 ln -sf $(DESTDIR)/lib/libteec.so $(DESTDIR)/usr/local/lib/libteec.so && \
	 $(call fbprint_d,"optee_client")
endif
else
	@$(call fbprint_w,INFO: CONFIG_APP_OPTEE is not enabled by default in configs/$(CONFIGLIST))
endif



.PHONY: optee_test
optee_test:
ifeq ($(CONFIG_APP_OPTEE), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"optee_test") && $(call fetch-git-tree,optee_test,apps/security) && \
	 if [ ! -f $(DESTDIR)/lib/libteec.so.1.0 ]; then flex-builder -c optee_client -m $(MACHINE); fi && \
	 cd $(SECDIR)/optee_test && $(MAKE) CFG_ARM64=y OPTEE_CLIENT_EXPORT=$(DESTDIR)/usr \
	 TA_DEV_KIT_DIR=$(SECDIR)/optee_os/out/arm-plat-ls/export-ta_arm64 && \
	 mkdir -p $(DESTDIR)/lib/optee_armtz $(DESTDIR)/bin && \
	 cp $(SECDIR)/optee_test/out/ta/*/*.ta $(DESTDIR)/lib/optee_armtz && \
	 cp $(SECDIR)/optee_test/out/xtest/xtest $(DESTDIR)/bin && \
	 $(call fbprint_d,"optee_test")
endif
else
	@$(call fbprint_w,INFO: CONFIG_APP_OPTEE is not enabled by default in configs/$(CONFIGLIST))
endif



.PHONY: keyctl_caam
keyctl_caam:
ifeq ($(CONFIG_APP_KEYCTL_CAAM), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = mate -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"keyctl_caam") && $(call fetch-git-tree,keyctl_caam,apps/security) && \
	 cd $(SECDIR)/keyctl_caam && $(MAKE) CC=$(CROSS_COMPILE)gcc DESTDIR=$(DESTDIR) install && \
	 $(call fbprint_d,"keyctl_caam")
endif
endif



security_repo_fetch:
	@echo -e "\nfetch security repositories: $(SECURITY_REPO_LIST)"
	@$(call repo-update,fetch,$(SECURITY_REPO_LIST),apps/security)

security_repo_update_branch:
	@echo -e "\nsecurity repositories update for branch"
	@$(call repo-update,branch,$(SECURITY_REPO_LIST),apps/security)

security_repo_update_tag:
	@echo -e "\nsecurity repositories update for tag"
	@$(call repo-update,tag,$(SECURITY_REPO_LIST),apps/security)

security_repo_update_latest:
	@echo -e "\nsecurity repositories update to latest HEAD commit"
	@$(call repo-update,update,$(SECURITY_REPO_LIST),apps/security)

security_repo_update_commit:
	@echo -e "\nsecurity repositories update to specified commit ID"
	@$(call repo-update,commit,$(SECURITY_REPO_LIST),apps/security)
