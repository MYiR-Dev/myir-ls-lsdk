#####################################
#
# Copyright 2017 NXP
#
# SPDX-License-Identifier:      BSD-3-Clause
#
#####################################

include $(FBDIR)/configs/$(CONFIGLIST)

TGTDIRS := firmware linux apps rfs

all: $(TGTDIRS)

$(TGTDIRS): ECHO
	@$(MAKE) -C $(FBDIR)/packages/$@

ECHO:
	@echo Building $(TGTDIRS)
