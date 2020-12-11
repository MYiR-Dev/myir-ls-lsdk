## Build and Deploy Various Distro

flex-builder supports generating various distro in different scale, including Ubuntu, Debian, CentOS, Yocto-based and Buildroot-based distro.
Users can choose appropriate distro to meet the need in practic use case.


To build Ubuntu/Debian/CentOS/Yocto/Buildroot distro
```
Usage: flex-builder -i mkrfs [ -r <distro_type>:<distro_scale>:<codename> ] [ -a <arch> ] [ -B <additional_packages_list> ]
$ flex-builder -i mkrfs -r ubuntu:main  -a arm64  # generate ubuntu main userland with main packages as per additional_packages_list
$ flex-builder -i mkrfs -r ubuntu:devel -a arm32  # generate Ubuntu devel userland with more main and universe/multiverse packages
$ flex-builder -i mkrfs -r ubuntu:lite  -a arm64  # generate Ubuntu lite userland with base packages
$ flex-builder -i mkrfs -r ubuntu:mate  -a arm64  # generate Ubuntu mate GUI desktop userland
$ flex-builder -i mkrfs -r debian:lite:stretch    # generate Debian lite userland with basic packages
$ flex-builder -i mkrfs -r centos -a arm64        # generate CentOS arm64 userland
$ flex-builder -i mkrfs -r yocto:tiny -a arm64    # generate Yocto tiny arm64 userland
$ flex-builder -i mkrfs -r buildroot:tiny         # generate Buildroot tiny arm64 userland
```
To quickly install a new apt package to target Ubuntu arm64 userland on host machine, run the command as below
```
$ sudo chroot build/rfs/rootfs_<sdk_version>_ubuntu_main_arm64 apt install <package>
```


Example: Build and deploy Ubuntu main distro (default for LSDK)
```
$ flex-builder -i mkrfs             # generate ubuntu userland, '-r ubuntu:main -a arm64' by default
$ flex-builder -i mkbootpartition   # genrate bootpartition_LS_arm64_lts_5.4.tgz
$ flex-builder -c apps -a arm64     # build all apps components
$ flex-builder -i merge-component   # merge app components into target userland
$ flex-builder -i packrfs           # pack and compress target userland as .tgz
$ flex-builder -i mkfw -m ls1046ardb -b sd # generate composite firmware_ls1046ardb_uboot_sdboot.img
$ cd build/images
$ flex-installer -r rootfs_<sdk_version>_ubuntu_main_arm64.tgz -b bootpartition_LS_arm64_lts_5.4.tgz -d /dev/sdx
or
$ flex-installer -r rootfs_<sdk_version>_ubuntu_main_arm64.tgz -b bootpartition_LS_arm64_lts_5.4.tgz -f firmware_ls1046ardb_uboot_sdboot.img -d /dev/sdx
```
Note: The '-f <firmware> option is used for SD boot only'.



Example: Build and deploy Ubuntu Mate distro for GUI desktop
```
$ flex-builder -i mkrfs -r ubuntu:mate -a arm64
$ flex-builder -c apps -r ubuntu:mate -a arm64
$ flex-builder -i mkbootpartition -a arm64
$ flex-builder -i merge-component -r ubuntu:mate -a arm64
$ flex-builder -i packrfs -r ubuntu:mate -a arm64
$ cd build/images
$ flex-installer -r rootfs_<sdk_version>_ubuntu_mate_arm64.tgz -b bootpartition_LS_arm64_lts_5.4.tgz -d /dev/sdx
```


Example: Build and deploy Ubuntu lite distro
```
$ flex-builder -i mkrfs -r ubuntu:lite -a arm64
$ flex-builder -i mkbootpartition -a arm64
$ flex-builder -i merge-component -r ubuntu:lite -a arm64
$ flex-builder -i packrfs -r ubuntu:lite -a arm64
$ cd build/images
$ flex-installer -r rootfs_<sdk_version>_ubuntu_lite_arm64.tgz -b bootpartition_LS_arm64_lts_5.4.tgz -d /dev/sdx
```
You can modify the default additional_lite_packages_list in configs/ubuntu/additional_packages_list to customize packages.



Example: Build and deploy Yocto-based distro
```
Usage: flex-builder -i mkrfs -r yocto:<distro_scale> [ -a <arch> ]
The <distro_scale> can be tiny, devel,   <arch> can be arm32, arm64
$ flex-builder -i mkrfs -r yocto:tiny -a arm64
$ flex-builder -i mkfw -m ls1046ardb -b sd
$ flex-builder -i mkbootpartition
$ cd build/images
$ flex-installer -r rootfs_<sdk_version>_yocto_tiny_arm64.tgz -b bootpartition_LS_arm64_lts_5.4.tgz -f firmware_ls1046ardb_uboot_sdboot.img -d /dev/sdx
```
You can customize additional packages to IMAGE_INSTALL_append in configs/yocto/local_arm64_<distro_scale>.conf, if you want to install
more packages(e.g. dpdk, ovs-dpdk, netperf, etc) in yocto userland, you can choose devel instead of tiny. Additionally, you can add yocto
recipes for customizing package in packages/rfs/misc/yocto/recipes-support directory, or you can add your own app component in 
packages/apps/Makefile to integrate it into Yocto userland.



Example: Build and deploy Buildroot-based distro
```
Usage: flex-builder -i mkrfs -r buildroot:<distro_scale> -a <arch>
The <distro_scale> can be tiny, devel, imaevm,  <arch> can be arm32, arm64, ppc32, ppc64
$ flex-builder -i mkrfs -r buildroot:devel:custom      # customize buildroot .config in interactive menu for arm64 arch
$ flex-builder -i mkrfs -r buildroot:devel             # generate buildroot userland as per existing .config or qoriq_arm64_devel_defconfig
$ flex-builder -i mkrfs -r buildroot:tiny -a arm64     # generate arm64 rootfs as per qoriq_arm64_tiny_defconfig
$ flex-builder -i mkrfs -r buildroot:tiny -a arm64:be  # generate arm64 big-endian rootfs as per qoriq_arm64_be_devel_defconfig
$ flex-builder -i mkrfs -r buildroot:devel -a arm32    # generate arm32 little-endian rootfs as per qoriq_arm64_devel_defconfig
$ flex-builder -i mkrfs -r buildroot:tiny -a ppc32     # generate ppc32 big-endian rootfs as per qoriq_arm64_devel_defconfig
$ flex-builder -i mkrfs -r buildroot:devel -a ppc64    # generate ppc64 big-endian rootfs as per qoriq_ppc64_devel_defconfig
$ flex-builder -i mkrfs -r buildroot:imaevm -a arm64   # generate arm64 little-endian rootfs as per qoriq_arm64_imaevm_defconfig
$ flex-builder -i mkfw -m ls1046ardb -b sd
$ flex-builder -i mkbootpartition -a arm64
$ cd build/images
$ flex-installer -r rootfs_<sdk_version>_buildroot_tiny_arm64.tgz -b bootpartition_LS_arm64_lts_5.4.tgz -f firmware_ls1046ardb_uboot_sdboot.img -d /dev/mmcblk0
```
You can modify configs/buildroot/qoriq_<arch>_<distro_scale>_defconfig to customize various packages



Example: Build and deploy CentOS distro
```
Usage:   flex-builder -i mkrfs -r centos -a <arch>
$ flex-builder -i mkrfs -r centos -a arm64
$ flex-builder -i mkbootpartition -a arm64
$ flex-builder -i merge-component -r centos -a arm64
$ flex-builder -i packrfs -r centos -a arm64
$ cd build/images
$ flex-installer -r rootfs_<sdk_version>_centos_7.7.1908_arm64.tgz -b bootpartition_LS_arm64_lts_5.4.tgz -d /dev/sdx
```



Example: Build and deploy Android distro i.MX or Layerscape (experimental)
```
Usage: flex-builder -i mkrfs -r andorid [ -a <arch> -p <portforlio> ]
$ flex-builder -i mkrfs -r android -p layerscape   # build Android system for Layerscape platforms with external PCIe graphics card
$ flex-builder -i mkrfs -r android -p imx6         # build Android system for i.MX6
$ flex-builder -i mkrfs -r android -p imx8         # build Android system for i.MX8
$ flex-builder -i auto -a arm64 -p imx             # build all images for for i.MX8
$ flex-installer -r rootfs_android_v7.1.2_system.img -b bootpartition_LS_arm64_lts_5.4.tgz -d /dev/mmcblk0
```
Supported platforms: ls1028ardb, ls104xardb, mx6qsabresd, imx6sllevk, imx7ulpevk, imx8mmevk, mx8mqevk, imx8qmmek, imx8qxpmek.
