#!/bin/bash -e

curdir=$(dirname $0)

cd $curdir

# build/install grub2
#rm -fr grub && mkdir grub && cd grub
#tar xJf ../grub2_2.02.orig.tar.xz --strip-components=1
#patch -p1 <../grub2-fix-yylex-build.patch
#./configure && make && make install
#cd ..

# build/install selinux
rm -fr selinux && mkdir selinux && cd selinux
tar xzf ../selinux_0.11.tar.gz --strip-components=1
make install
cd ..

# build/install refpolicy-ubuntu
#rm -fr refpolicy && mkdir refpolicy && cd refpolicy
#tar xjf ../refpolicy_2.20180114.orig.tar.bz2 --strip-components=1
#tar xJf ../refpolicy_2.20180114-4.debian.tar.xz 
#while read f;do
#  patch -p1 <debian/patches/$f || exit 1
#done <debian/patches/series
#make conf
#make policy || true
#make install || true
#cd ..
#dpkg -i --ignore-depends=selinux selinux-policy-ubuntu_0.2.20091117-0ubuntu2_all.deb

