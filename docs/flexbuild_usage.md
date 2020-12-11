## Flexbuild Usage

```
$ cd flexbuild
$ source setup.env
$ flex-builder -h
```

```
Usage: flex-builder -c <component> [-a <arch>] [-f <config-file>]
   or: flex-builder -i <instruction> [-m <machine>] [-a <arch>] [-r <distro_type>:<distro_scale>] [-f <config-file>]
```

Most used example with automated build:
```
  flex-builder -m ls1043ardb                  # automatically build all firmware, linux, apps components and LSDK rootfs for ls1043ardb
  flex-builder -i auto -a arm64               # automatically build all firmware, linux, apps components and LSDK rootfs for all arm64 machines
```

Most used example with separate command:
```
$ flex-builder -i mkrfs                       # generate Ubuntu main arm64 rootfs, '-r ubuntu:main -a arm64' by default
$ flex-builder -i mkrfs -r ubuntu:lite        # generate Ubuntu lite arm64 userland
$ flex-builder -i mkrfs -r ubuntu:mate        # generate Ubuntu mate arm64 GUI desktop rootfs
$ flex-builder -i mkrfs -r yocto:tiny         # generate Yocto-based arm64 tiny rootfs
$ flex-builder -i mkrfs -r buildroot:tiny     # generate Buildroot-based arm64 tiny userland
$ flex-builder -i mkrfs -r centos             # generat CentOS arm64 rootfs
$ flex-builder -i mkfw -m lx2160ardb -b xspi  # generate composite firmware for FlexSPI boot on lx2160ardb
$ flex-builder -i mkfw -m ls1028ardb -b sd -s # generate composite firmware for SD secure boot on ls1028ardb
$ flex-builder -c atf -m ls1046ardb -b qspi   # build ATF with dependent RCW and U-Boot for qspi boot on ls1046adrdb
$ flex-builder -c linux                       # build linux with default linux repo and default branch/tag for all arm64 machines
$ flex-builder -i mkitb -r yocto:tiny         # generate lsdk_yocto_tiny_LS_arm64.itb including rootfs_lsdk_yocto_tiny_arm64.cpio.gz
$ flex-builder -i mkboot -a arm64             # generate boot partition tarball bootpartition_LS_arm64_lts.tgz
$ flex-builder -c apps                        # build all apps components(dpdk, fmc, restool, tsntool, optee_os, openssl, secure_obj, etc)
$ flex-builder -i merge-component             # merge all components packages into target userland
$ flex-builder -i packrfs                     # pack and compress target rootfs as rootfs_lsdk2004_ubuntu_main.tgz
$ flex-builder -i packapp                     # pack and compress target app components as app_components_LS_arm64.tgz
$ flex-builder -c eiq                         # build all eIQ components (armnn,opencv,tensorflow,caffe,armcl,flatbuffer,protobuf,onnx,etc)
$ flex-builder -c armnn                       # build specific ArmNN for AI/ML
$ flex-builder -i download -m ls1043ardb      # download prebuilt distro images for ls1043ardb
$ flex-builder -i mkdistroscr                 # generate distro boot script
$ flex-builder docker                         # create or attach to Ubuntu docker container to run flexbuild in docker invironment if needed
$ flex-builder clean                          # clean all previously generated images except distro rootfs
$ flex-builder clean-rfs                      # clean distro rootfs, '-r ubuntu:main -a arm64' by default
```

The supported options:
```
  -m, --machine         target machine, supports ls1012afrwy, ls1021atwr, ls1028ardb, ls1043ardb, ls1046ardb, ls1088ardb, ls2088ardb, lx2160ardb_rev2, etc
  -a, --arch            target architect, valid argument: arm64, arm64:be, arm32, arm32:be, ppc64, ppc32, arm64 as default if unspecified
  -b, --boottype        type of boot media, valid argument: sd, emmc, qspi, xspi, nor, nand, default all types if unspecified
  -c, --component       build all or separate component(s), valid argument: firmware, apps, linux, atf, rcw, networking, multimedia, security,
                        eiq, armnn, tensorflow, fmc, tsntool, openssl, dpdk, ovs_dpdk, optee_os, libpkcs11, secure_obj, etc
  -i, --instruction     instruction to do for dedicated purpose, valid argument as below:
      mkfw              generate composite firmware image for the specified type of sd/emmc/qspi/xspi/nor/nand boot
      mkallfw           generate all composite firmware in all sd/emmc/qspi/xspi/nor/nand boot type for non-secure and secure boot
      mklinux           generate lsdk_linux_<arch>.itb
      mkbootpartition   generate boot partition tarball including kernel, dtb, composite firmware, autoboot script, etc
      mkrfs             generate target rootfs, associated with -r, -a and -p options for different distro type and architecture
      rfsraw2ext        convert raw rootfs to ext4 rootfs
      mkdistroscr       generate distro autoboot script for all or single machine
      mkflashscr        generate U-Boot script of flashing images for all machines
      signimg           sign images and secure boot headers for specified machine
      merge-component   merge custom component packages and kernel modules into target distro rootfs
      auto              automatically build all firmware, kernel, apps components and distro userland with saving log in logs directory
      clean             clean all the obsolete images except distro rootfs
      clean-firmware    clean obsolete firmware images generated in build/firmware directory
      clean-linux       clean obsolete linux images generated in build/linux directory
      clean-apps        clean obsolete apps images generated in build/apps directory
      clean-rfs         clean target rootfs
      packrfs           pack and compress distro rootfs as .tgz
      packapps          pack and compress apps components as .tgz
      repo-fetch        fetch single or all git repositories if not exist locally
      repo-branch       set single or all git repositories to specified branch
      repo-update       update single or all git repositories to latest HEAD
      repo-commit       set single or all git repositories to specified commit
      repo-tag          set single or all git repositories to specified tag
      list              list enabled config, machines and components
  -p, --portfolio       specify portfolio of SoC, valid argument: ls, imx, imx6, imx7, imx8, default layerscape if unspecified
  -f, --cfgfile         specify config file, build_lsdk.cfg is used by default if only that file exists
  -B, --buildarg        secondary argument for various build commands
  -r, --rootfs          specify flavor of target rootfs, valid argument: ubuntu|debian|centos|android|buildroot:main|devel|mate|lite|tiny
  -j, --jobs            number of parallel build jobs, default 16 jobs if unspecified
  -s, --secure          enable security feature in case of secure boot without IMA/EVM
  -t, --ima-evm         enable IMA/EVM feature in case of secure boot with IMA/EVM
  -T, --cot             specify COT (Chain of Trust) type for secure boot, valid argument: arm-cot, arm-cot-with-verified-boot, nxp-cot
  -e, --encapsulation   enable encapsulation and decapsulation feature for chain of trust with confidentiality in case secure boot
  -v, --version         print the version of flexbuild
  -h, --help            print help info
```



## How to build composite firmware
The composite firmware consists of RCW/PBL, ATF BL2, ATF BL31, BL32 OPTEE, BL33 U-Boot/UEFI, bootloader environment variables,
secure boot headers, Ethernet firmware, dtb, kernel and tiny ramdisk rootfs, etc, this composite firmware can be programmed at
offset 0x0 in NOR/QSPI/FlexSPI flash device or at offset block 8 in SD/eMMC card.
```
Usage: flex-builder -i mkfw -m <machine> -b <boottype> [-B <bootloader>] [-s]
Example:
$ flex-builder -i mkfw -m ls1043ardb -b sd           # generate composite firmware_ls1043ardb_uboot_sdboot.img
$ flex-builder -i mkfw -m lx2160ardb -b xspi -s      # generate composite firmware_lx2160ardb_uboot_xspiboot_secure.img
$ flex-builder -i mkfw -m ls1046ardb -b qspi -B uefi # generate composite firmware_ls1046ardb_uefi_qspi.img
$ flex-builder -i mkfw -m imx8mnevk                  # generate composite firmware_imx8mnevk.img
$ flex-builder -i mkfw -m imx8mqevk                  # generate composite firmware_imx8mqevk.img
$ flex-builder -i mkfw -m imx8qxpmek                 # generate composite firmware_imx8qxpmek.img
```



## How to build bootpartition and rootfs tarball
```
Usage: flex-builder -i <instruction> [ -m <machine> ] [ -b <boottype> ] [ -a <arch> ]
Examples:
$ flex-builder -i mkbootpartition -a arm64           # generate bootpartition_LS_arm64_lts_5.4.tgz for arm64 Layerscape platforms
$ flex-builder -i mklinux -a arm64                   # generate lsdk_linux_arm64_LS_tiny.itb
$ flex-builder -i mklinux -a arm32                   # generate lsdk_linux_arm32_LS_tiny.itb
$ flex-builder -i signimg -m ls1046ardb -b sd        # sign images and generate secure boot headers for secure boot on ls1046ardb
$ flex-builder -i mkbootpartition -a arm64 -p imx    # generate boot partition tarball for all arm64 i.MX platforms
$ flex-builder -i mkrfs                              # generate Ubuntu main arm64 userland by default
$ flex-builder -i merge-component -a arm64           # merge all apps components packages and kernel modules into arm64 rootfs
$ flex-builder -i packrfs -a arm64                   # pack target rootfs directory as rootfs_<sdk_version>_ubuntu_main_arm64.tgz
```




## How to build Linux kernel and modules
To build linux with default repo and current branch according to default config
```
Usage: flex-builder -c linux [ -a <arch> ]
Examples:
$ flex-builder -c linux -a arm64                     # for arm64 Layerscape platforms, little-endian by default
$ flex-builder -c linux -a arm64:be                  # for arm64 Layerscape platforms, big-endian
$ flex-builder -c linux -a arm32                     # for arm32 Layerscape platform
$ flex-builder -c linux -a arm64 -p imx              # for arm64 i.MX platforms
$ flex-builder -c linux -a arm32 -p imx              # for arm32 i.MX platforms
$ flex-builder -c linux -a ppc64                     # for ppc64 platforms, big-endian by default
$ flex-builder -c linux -a ppc32                     # for ppc32 platforms, big-endian by default
```

To build linux with the specified kernel repo and branch/tag according to default kernel config
```
Usage: flex-builder -c linux:<kernel_repo>:<branch|tag|commit> -a <arch>
Examples:
$ flex-builder -c linux:dash-lts:linux-5.4 -a arm64
$ flex-builder -c linux:linux:LSDK-20.04-V5.4 -a arm64
```

To customize kernel options with the default repo and current branch in interactive menu
```
$ flex-builder -c linux:custom -a <arch>             # generate a customized .config
$ flex-builder -c linux -a <arch>                    # compile kernel and modules according to the .config above
```

To build custom linux with the specified kernel repo and branch/tag according to default config and the appended fragment config
```
Usage: flex-builder -c linux [ :<kernel_repo>:<tag|branch> ] -B fragment:<xx.config> -a <arch>
Examples:
$ flex-builder -c linux -B fragment:ima_evm_arm64.config
$ flex-builder -c linux -B fragment:"ima_evm_arm64.config lttng.config"
$ flex-builder -c linux:linux:LSDK-20.04-V5.4 -B fragment:lttng.config
```




## How to build ATF (TF-A)
```
Usage: flex-builder -c atf [ -m <machine> ] [ -b <boottype> ] [ -s ] [ -B bootloader ]
Examples:
$ flex-builder -c atf -m ls1028ardb -b sd             # build U-Boot based ATF image for SD boot on ls1028ardb
$ flex-builder -c atf -m ls1046ardb -b qspi           # build U-Boot based ATF image for QSPI boot on ls1046ardb
$ flex-builder -c atf -m ls2088ardb -b nor -s         # build U-Boot based ATF image for secure IFC-NOR boot on ls2088ardb
$ flex-builder -c atf -m lx2160ardb -b xspi -B uefi   # build UEFI based ATF image for FlexSPI-NOR boot on lx2160ardb
```
flex-builder can automatically build the dependent RCW, U-Boot/UEFI, OPTEE and CST before building ATF to generate target images.
Note 1: If you want to specify different RCW configuration instead of the default one, first modify variable rcw_<boottype> in
        configs/board/<machine>/manifest, then run 'flex-builder -c rcw -m <machine>' to generate new RCW image.
Note 2: The '-s' option is used for secure boot, OPTEE and FUSE_PROVISIONING are not enabled by default, you can change
        CONFIG_BUILD_OPTEE=n to y and/or change CONFIG_FUSE_PROVISIONING=n to y in configs/build_lsdk.cfg to enable it if necessary.



## How to build U-Boot
```
Usage:   flex-builder -c uboot -m <machine> -b <boottype>
Examples:
$ flex-builder -c uboot -m ls1021atwr -b sd           # build U-Boot image for SD boot on Layerscape ls1021atwr
$ flex-builder -c uboot -m ls1021atwr -b nor          # build U-Boot image for NOR boot on Layerscape ls1021atwr
$ flex-builder -c uboot -m imx6qsabresd               # build U-Boot image for SD boot on i.MX6 mx6qsabresd
$ flex-builder -c uboot -m imx8mqevk                  # build U-Boot image for SD boot on i.MX8 mx8mqevk
```



## How to build various firmware components
```
Usage: flex-builder -c <component> [ -a <arch> ] [ -r <distro_type>:<distro_scale> ]
Examples:
$ flex-builder -c firmware -m ls2088ardb -b nor       # build all firmware (U-Boot/UEFI, RCW, ATF, PHY firmware, etc) for ls2088ardb
$ flex-builder -c firmware -m all                     # build all firmware (U-Boot/UEFI, RCW, ATF, PHY firmware, etc) for all machines
$ flex-builder -c rcw -m ls1046ardb                   # build RCW images for ls1046ardb
$ flex-builder -c bin_firmware                        # build binary fm_ucode, qe_ucode, mc_bin, phy_cortina, pfe_bin, etc
```


## How to build APP components
The supported APP components: restool, tsntool, gpp_aioptool, dpdk, pktgen_dpdk, ovs_dpdk, flib, fmlib, fmc, spc, openssl, cst, aiopsl,
ceetm, qbman_userspace, eth_config, crconf, optee_os, optee_client, optee_test, libpkcs11, secure_obj, eiq, opencv, tflite,
tensorflow, armcl, armnn, caffe, flatbuffer, onnx, onnxruntime, protobuf, etc.
```
Usage: flex-builder -c <component> [ -a <arch> ] [ -r <distro_type>:<distro_scale> ]
Examples:
$ flex-builder -c apps -a arm64                       # build all apps components against arm64 Ubuntu-based userland by default
$ flex-builder -c apps -r yocto:devel                 # build apps components against arm64 Yocto-based userland
$ flex-builder -c apps -r buildroot:devel             # build all apps components against arm64 buildroot-based userland
$ flex-builder -c fmc -a arm64                        # build FMC component against arm64 Ubuntu main userland
$ flex-builder -c fmc -a arm32                        # build FMC component against arm32 Ubuntu main userland
$ flex-builder -c dpdk -r ubuntu:main                 # build DPDK component against Ubuntu main userland
$ flex-builder -c dpdk -r yocto:devel                 # build DPDK component against Yocto devel userland
$ flex-builder -c weston                              # build weston component
$ flex-builder -c optee_os                            # build optee_os component
$ flex-builder -c eiq                                 # build all eIQ components (opencv, armnn, tensorflow, tflite, onnxruntime, etc)
```




## Manage git repositories of various components
```
Usage: flex-builder -i <instruction> [ -B <args> ]
Examples:
$ flex-builder -i repo-fetch                          # fetch all git repositories of components from remote repos if not exist locally
$ flex-builder -i repo-fetch -B dpdk                  # fetch single dpdk component from remote repository if not exist locally
$ flex-builder -i repo-branch                         # switch branches of all components to specified branches according to the config file
$ flex-builder -i repo-tag                            # switch tags of all components to specified tags according to default config
$ flex-builder -i repo-commit                         # set all components to the specified commmits of current branches
$ flex-builder -i repo-update                         # update all components to the latest HEAD commmit of current branches 
```



## How to use different build config instead of the default config
Uer can create a custom config file configs/build_custom.cfg, flex-builder will preferentially select build_custom.cfg, otherwise, if there
is a config file configs/build_lsdk_internal.cfg, it will be used. In case there is only configs/build_lsdk.cfg, it will be used.
If there are multiple build_xx.cfg config files in configs directory, user can specify the expected one by specifying -f option.
Example:
```
$ flex-builder -m ls1043ardb -b sd -f build_custom.cfg
```



## How to add new apps component in Flexbuild
```
- Add a new CONFIG_APP_<component>=y and configure <component>_repo_url and <component>_repo_branch in configs/build_xx.cfg,
  user can directly create the new component git repository in packages/apps/xx directory as well.
- Add makefile target support for the new component in packages/apps/<category>/<category>.mk
- Run 'flex-builder -c <component> -a <arch>' to build new component
- Run 'flex-builder -i merge-component -a <arch>' to merger new component package into distro userland
- Run 'flex-builder -i packrfs -a <arch>' to pack the target distro userland for deployment
```




## How to configurate different packages/components path and images output path instead of the default path for sharing with multi-users
The default packages path is <flexbuild_dir>/packages, the default images output path is <flexbuild_dir>/build, there are two ways to
change the default path:
Way1: set PACKAGES_PATH and/or FBOUTDIR in environment variable as below:
```
$ export PACKAGES_PATH=<path>
$ export FBOUTDIR=<path>
```
Way2: modify DEFAULT_PACKAGES_PATH and/or DEFAULT_OUT_PATH in <flexbuild_dir>/configs/build_lsdk.cfg
