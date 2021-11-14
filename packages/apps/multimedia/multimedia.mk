#
# Copyright 2017-2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# SDK Multi-Media Components
#

MULTIMEDIA_REPO_LIST = wayland wayland_protocols libdrm weston gpulib
MMDIR = $(PACKAGES_PATH)/apps/multimedia

multimedia: $(MULTIMEDIA_REPO_LIST)


.PHONY: wayland
wayland:
ifeq ($(CONFIG_APP_WAYLAND), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"wayland") && $(call fetch-git-tree,wayland,apps/multimedia) && \
	 if [ $(DISTROTYPE) != ubuntu ]; then echo wayland is not supported on $(DISTROTYPE) yet; exit; fi && \
	 export CC="$(CROSS_COMPILE)gcc --sysroot=$(RFSDIR)" && export PKG_CONFIG_SYSROOT_DIR=$(RFSDIR) && \
	 export PKG_CONFIG_LIBDIR=$(RFSDIR)/usr/lib/aarch64-linux-gnu/pkgconfig && cd $(MMDIR)/wayland && \
	 ./autogen.sh --prefix=/usr/local --host=aarch64-linux-gnu --disable-documentation --with-host-scanner && \
	 $(MAKE) && $(MAKE) install && $(call fbprint_d,"wayland")
endif
endif


.PHONY: wayland_protocols
wayland_protocols:
ifeq ($(CONFIG_APP_WAYLAND_PROTOCOLS), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"wayland_protocols") && $(call fetch-git-tree,wayland_protocols,apps/multimedia) && \
	 cd $(MMDIR)/wayland_protocols && ./autogen.sh --prefix=/usr --host=aarch64-linux-gnu && \
	 $(MAKE) && $(MAKE) install && $(call fbprint_d,"wayland_protocols")
endif
endif


.PHONY: libdrm
libdrm:
ifeq ($(CONFIG_APP_LIBDRM), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"libdrm") && $(call fetch-git-tree,libdrm,apps/multimedia) && \
	 export CC="$(CROSS_COMPILE)gcc --sysroot=$(RFSDIR)" && cd $(MMDIR)/libdrm && \
	 ./autogen.sh --prefix=/usr/local --host=aarch64-linux-gnu --disable-vc4 \
	 --enable-vivante-experimental-api --disable-freedreno --disable-vmwgfx --disable-nouveau \
	 --disable-amdgpu --disable-radeon --disable-intel && $(MAKE) && $(MAKE) install && \
	 cp tests/modetest/.libs/modetest $(DESTDIR)/usr/local/bin && \
	 $(call fbprint_d,"libdrm")
endif
endif


.PHONY: gpulib
gpulib:
ifeq ($(CONFIG_APP_GPULIB), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = lite ] && exit || \
	 $(call fbprint_b,"gpulib") && $(call fetch-git-tree,gpulib,apps/multimedia)
	@if [ ! -d $(MMDIR)/gpulib ]; then \
	     cd $(MMDIR) && echo Downloading $(gpulib_bin_url) && \
	     wget --progress=bar:force $(gpulib_bin_url) -O gpulib.bin && chmod +x gpulib.bin && \
	     ./gpulib.bin --auto-accept && mv gpulib-* gpulib && rm -f gpulib.bin; \
	 fi && \
	 cd $(MMDIR)/gpulib/ls1028a/linux && install -d $(DESTDIR)/opt && \
	 install -d $(DESTDIR)/usr/local/include && install -d $(DESTDIR)/usr/local/lib && \
	 cp -a gpu-demos/opt/viv_samples/* $(DESTDIR)/opt && \
	 cp -a gpu-core/usr/include/* $(DESTDIR)/usr/local/include && \
	 cp -a gpu-core/usr/lib/* $(DESTDIR)/usr/local/lib && \
	 $(call fbprint_d,"gpulib")
endif
endif


.PHONY: weston
weston:
ifeq ($(CONFIG_APP_WESTON), y)
ifeq ($(DESTARCH),arm64)
	@[ $(DISTROTYPE) != ubuntu -o $(DISTROSCALE) = lite -o $(VIRTABLE) = n ] && exit || \
	 $(call fbprint_b,"weston") && $(call fetch-git-tree,weston,apps/multimedia) && \
	 if [ ! -f $(RFSDIR)/usr/lib/aarch64-linux-gnu/libpng.so ]; then $(call build_dependent_rfs); fi && \
	 if [ ! -d $(DESTDIR)/usr/local/include/libdrm ]; then flex-builder -c libdrm -r $(DISTROTYPE):$(DISTROSCALE) -f $(CONFIGLIST); fi && \
	 if [ ! -f $(DESTDIR)/usr/local/include/wayland-client.h ]; then flex-builder -c wayland -r $(DISTROTYPE):$(DISTROSCALE) -f $(CONFIGLIST); fi && \
	 if [ ! -d $(DESTDIR)/usr/share/wayland-protocols ]; then flex-builder -c wayland_protocols -r $(DISTROTYPE):$(DISTROSCALE) -f $(CONFIGLIST); fi && \
	 if [ ! -d $(DESTDIR)/usr/local/include/EGL ]; then flex-builder -c gpulib -r $(DISTROTYPE):$(DISTROSCALE) -f $(CONFIGLIST); fi && \
	 if [ ! -d /usr/local/lib/python3.6/dist-packages/mesonbuild ]; then pip3 install meson; fi && \
	 if [ ! -f /usr/bin/ninja ]; then sudo apt install ninja-build; fi && \
	 if [ ! -f /usr/local/bin/wayland-scanner ]; then sudo ln -sf /usr/bin/wayland-scanner /usr/local/bin/wayland-scanner; fi && \
	 sudo cp -Prf --preserve=mode,timestamps $(DESTDIR)/usr/* $(RFSDIR)/usr/ && \
	 sudo sed -i -e "s#'/usr/local/lib'#'$(RFSDIR)/usr/local/lib'#g" -e "s# /usr/local/lib# $(RFSDIR)/usr/local/lib#g" $(RFSDIR)/usr/local/lib/*.la && \
	 if [ $(VIRTABLE) = y ]; then sudo chroot $(RFSDIR) ldconfig; fi && cd $(MMDIR)/weston && rm -rf build && mkdir build && \
	 sed -e 's%@TARGET_CROSS@%$(CROSS_COMPILE)%g' -e 's%@TARGET_ARCH@%aarch64%g' \
	     -e 's%@TARGET_CPU@%cortex-a72%g' -e 's%@TARGET_ENDIAN@%little%g' -e 's%@STAGING_DIR@%$(RFSDIR)%g' \
	     $(FBDIR)/packages/rfs/misc/meson/cross-compilation.conf > $(MMDIR)/weston/build/cross-compilation.conf && \
	 PKG_CONFIG_LIBDIR=$(RFSDIR)/usr/local/lib/pkgconfig:$(RFSDIR)/usr/lib/aarch64-linux-gnu/pkgconfig:$(RFSDIR)/usr/share/pkgconfig \
	 PYTHONNOUSERSITE=y PKG_CONFIG_SYSROOT_DIR=$(RFSDIR) \
	 meson --prefix=/usr/local --libdir=lib --default-library=shared --buildtype=release --cross-file=build/cross-compilation.conf \
	 -Dsimple-dmabuf-drm=auto -Ddoc=false -Dbackend-drm-screencast-vaapi=false -Dbackend-rdp=false -Dcolor-management-lcms=false \
	 -Dcolor-management-colord=false -Dpipewire=false -Dbackend-x11=false -Drenderer-g2d=false -Degl=true -Dimage-jpeg=false \
	 -Dimage-webp=false -Dweston-launch=false -Dlauncher-logind=false -Dremoting=false -Ddemo-clients=false build && \
	 PYTHONNOUSERSITE=y DESTDIR=$(DESTDIR) ninja -j9 -C build/ install && \
	 if [ $(DISTROTYPE) = ubuntu -o $(DISTROTYPE) = debian ]; then \
	     echo OPTARGS=\" \" | sudo tee $(RFSDIR)/etc/default/weston && sudo install -d $(RFSDIR)/etc/xdg/weston && \
	     if [ $(SOCFAMILY) = IMX ]; then sudo sed -e 's%DP%HDMI-A%g' $(FBDIR)/packages/rfs/misc/weston/weston.ini > $(RFSDIR)/etc/xdg/weston/weston.ini; \
	     else sudo cp $(FBDIR)/packages/rfs/misc/weston/weston.ini $(RFSDIR)/etc/xdg/weston/weston.ini; fi && \
	     sudo install -m 755 $(FBDIR)/packages/rfs/misc/weston/weston.sh $(RFSDIR)/etc/profile.d/ && \
	     sudo install $(FBDIR)/packages/rfs/misc/weston/weston.service $(RFSDIR)/lib/systemd/system/ && \
	     sudo ln -sf /lib/systemd/system/weston.service $(RFSDIR)/etc/systemd/system/multi-user.target.wants/weston.service; \
	 fi && \
	 sudo sed -i -e "s#$(RFSDIR)##g" $(RFSDIR)/usr/local/lib/*.la && $(call fbprint_d,"weston")
endif
endif




multimedia_repo_fetch:
	@echo -e "\nfetch multimedia repositories: $(MULTIMEDIA_REPO_LIST)"
	@$(call repo-update,fetch,$(MULTIMEDIA_REPO_LIST),apps/multimedia)

multimedia_repo_update_branch:
	@echo -e "\nmultimedia repositories update for branch"
	@$(call repo-update,branch,$(MULTIMEDIA_REPO_LIST),apps/multimedia)

multimedia_repo_update_tag:
	@echo -e "\nmultimedia repositories update for tag"
	@$(call repo-update,tag,$(MULTIMEDIA_REPO_LIST),apps/multimedia)

multimedia_repo_update_latest:
	@echo -e "\nmultimedia repositories update to latest HEAD commit"
	@$(call repo-update,update,$(MULTIMEDIA_REPO_LIST),apps/multimedia)

multimedia_repo_update_commit:
	@echo -e "\nmultimedia repositories update to specified commit ID"
	@$(call repo-update,commit,$(MULTIMEDIA_REPO_LIST),apps/multimedia)
