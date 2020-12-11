#
# Copyright 2017-2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# SDK Application Components
#

SHELL=/bin/bash
include $(FBDIR)/configs/$(CONFIGLIST)
include $(FBDIR)/include/repo.mk


.PHONY: all

all: $(APPS_REPO_LIST) misc
	@$(call fbprint_d,"apps components")


include $(FBDIR)/packages/apps/eiq/eiq.mk
include $(FBDIR)/packages/apps/generic/generic.mk
include $(FBDIR)/packages/apps/security/security.mk
include $(FBDIR)/packages/apps/networking/networking.mk
include $(FBDIR)/packages/apps/multimedia/multimedia.mk
