#!/bin/bash -e

curdir=$(dirname $0)

cd $curdir
#if ! [ -e grub2_2.02.orig.tar.xz ];then
#  wget http://archive.ubuntu.com/ubuntu/pool/main/g/grub2/grub2_2.02.orig.tar.xz
#fi
#
if ! [ -e selinux_0.11.tar.gz ];then
  wget http://archive.ubuntu.com/ubuntu/pool/universe/s/selinux/selinux_0.11.tar.gz
fi

#if ! [ -e refpolicy_2.20180114.orig.tar.bz2 ];then
#  wget http://archive.ubuntu.com/ubuntu/pool/universe/r/refpolicy/refpolicy_2.20180114.orig.tar.bz2
#fi
#
#if ! [ -e refpolicy_2.20180114-4.debian.tar.xz ];then
#  wget http://archive.ubuntu.com/ubuntu/pool/universe/r/refpolicy/refpolicy_2.20180114-4.debian.tar.xz
#fi
#
#if ! [ -e selinux-policy-ubuntu_0.2.20091117-0ubuntu2_all.deb ];then
#  wget http://archive.ubuntu.com/ubuntu/pool/universe/r/refpolicy-ubuntu/selinux-policy-ubuntu_0.2.20091117-0ubuntu2_all.deb
#fi

