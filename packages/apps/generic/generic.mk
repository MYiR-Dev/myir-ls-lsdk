#
# Copyright 2017-2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# SDK Generic Components
#

GENERIC_REPO_LIST = iperf cjson docker_ce
GENDIR = $(PACKAGES_PATH)/apps/generic

generic: $(GENERIC_REPO_LIST) misc



.PHONY: iperf
iperf:
ifeq ($(CONFIG_APP_IPERF), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"iperf") && $(call fetch-git-tree,iperf,apps/generic) && \
	 cd $(GENDIR)/iperf && export CC=aarch64-linux-gnu-gcc && \
	 export CXX=aarch64-linux-gnu-g++ && ./configure --host=aarch64 && \
	 make && sudo make install DESTDIR=$(DESTDIR) && $(call fbprint_d,"iperf")
endif
endif


.PHONY: cjson
cjson:
ifeq ($(CONFIG_APP_CJSON), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -a $(DISTROTYPE) != yocto ] && exit || \
	 $(call fbprint_b,"cjson") && $(call fetch-git-tree,cjson,apps/generic) && \
	 cd $(GENDIR)/cjson && export CC=$(CROSS_COMPILE)gcc && \
	 mkdir -p build && cd build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
	 $(MAKE) && sudo $(MAKE) install DESTDIR=$(RFSDIR) && $(call fbprint_d,"cjson")
endif
endif


.PHONY: docker_ce
docker_ce:
ifeq ($(CONFIG_APP_DOCKER_CE), y)
ifeq ($(DISTROTYPE), ubuntu)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = lite -o $(DISTROSCALE) = mate ] && exit || \
	 $(call fbprint_b,"docker_ce") && $(call fetch-git-tree,docker_ce,apps/generic)
	@if [ ! -d $(GENDIR)/docker_ce ]; then \
	     mkdir -p $(GENDIR)/docker_ce && cd $(GENDIR)/docker_ce && \
	     wget --progress=bar:force $(docker_ce_bin_url) && tar xf docker-ce-bin-v18.09.6.tar.gz --strip-components 1; \
	 fi && \
	 if [ $(DESTARCH) = arm32 ]; then tarch=armhf; else tarch=$(DESTARCH); fi && \
	 if [ -f $(RFSDIR)/usr/bin/dockerd-ce ]; then $(call fbprint_n,"docker-ce was already installed") && exit; fi && \
	 if [ ! -d $(RFSDIR)/usr/lib ]; then $(call build_dependent_rfs); fi && \
	 if [ $(DISTROTYPE) = ubuntu -a $(DISTROSCALE) != lite -a -d $(GENDIR)/docker_ce ]; then \
	     sudo cp -f $(GENDIR)/docker_ce/containerd/containerd.io_1.2.4_$${tarch}.deb $(RFSDIR) && \
	     sudo cp -f $(GENDIR)/docker_ce/docker-ce/ubuntu-bionic/$$tarch/*.deb $(RFSDIR) && \
	     [ $(VIRTABLE) = n ] && echo unable to run chroot in this environment && exit || \
	     sudo chroot $(RFSDIR) dpkg -i containerd.io_1.2.4_$${tarch}.deb && \
	     sudo chroot $(RFSDIR) dpkg -i docker-ce-cli_v18.09.6-ubuntu-bionic_$${tarch}.deb && \
	     sudo chroot $(RFSDIR) dpkg -i docker-ce_v18.09.6-ubuntu-bionic_$${tarch}.deb && \
	     sudo rm -f $(RFSDIR)/*.deb && $(call fbprint_d,"docker_ce"); \
	 fi
endif
endif



misc:
	@$(CROSS_COMPILE)gcc $(FBDIR)/packages/rfs/misc/ccsr.c -o $(DESTDIR)/usr/local/bin/ccsr



generic_repo_fetch:
	@echo -e "\nfetch generic repositories: $(GENERIC_REPO_LIST)"
	@$(call repo-update,fetch,$(GENERIC_REPO_LIST),apps/generic)

generic_repo_update_branch:
	@echo -e "\ngeneric repositories update for branch"
	@$(call repo-update,branch,$(GENERIC_REPO_LIST),apps/generic)

generic_repo_update_tag:
	@echo -e "\ngeneric repositories update for tag"
	@$(call repo-update,tag,$(GENERIC_REPO_LIST),apps/generic)

generic_repo_update_latest:
	@echo -e "\ngeneric repositories update to latest HEAD commit"
	@$(call repo-update,update,$(GENERIC_REPO_LIST),apps/generic)

generic_repo_update_commit:
	@echo -e "\ngeneric repositories update to specified commit ID"
	@$(call repo-update,commit,$(GENERIC_REPO_LIST),apps/generic)
