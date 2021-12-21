#
# Copyright 2017-2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# SDK Generic Components
#

MYIR_REPO_LIST = quectel
MYIRDIR = $(PACKAGES_PATH)/apps/myir

myir: $(MYIR_REPO_LIST)



.PHONY: quectel
quectel:
ifeq ($(CONFIG_APP_QUECTEL), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"quectel") && $(call fetch-git-tree,quectel,apps/myir) && \
	 cd $(MYIRDIR)/quectel && export CC=aarch64-linux-gnu-gcc && \
	 export CXX=aarch64-linux-gnu-g++ && \
	 make && sudo make install DESTDIR=$(DESTDIR) && $(call fbprint_d,"quectel")
endif
endif
