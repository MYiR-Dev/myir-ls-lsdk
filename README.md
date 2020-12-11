## Flexbuild Overview
Flexbuild is a component-oriented build framework and integration platform
with capabilities of flexible, ease-to-use, scalable system build and
distro depolyment.

With flex-builder CLI, users can easily build various components (linux,
u-boot, uefi, rcw, atf and miscellaneous userspace applications) and
customable distro root filesystem to streamline the system build with
efficient CI/CD.

With flex-installer CLI, users can easily install various distro to target
storage device (SD/eMMC card or USB/SATA disk) directly on target board or
on host machine.


## Build Environment
- Cross-build on x86 host machine running Ubuntu
- Native-build on ARM board running Ubuntu
- Build in Docker container hosted on any machine running any distro


## Supported distros for target arm64/arm32 or ppc64/ppc32
- Ubuntu/Debian userland   (main, mate, devel, lite)
- CentOS userland
- Yocto-based userland     (tiny, devel)
- Buildroot-based userland (tiny, devel)


## More info
See docs/flexbuild_usage.md, docs/build_and_deploy_distro.md, docs/lsdk_build_install.md for detailed information.
