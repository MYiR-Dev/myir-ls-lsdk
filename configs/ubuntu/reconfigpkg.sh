#!/bin/bash
#
# Copyright 2018 NXP
#
# SPDX-License-Identifier:      BSD-3-Clause
#
# reconfigure default setting of some application packages

# for sshd
if [ -f /etc/ssh/sshd_config ]; then
    sed -i "/^#PermitRootLogin yes/s/#//g" /etc/ssh/sshd_config
fi

# for tftp service
if dpkg-query -W tftp-hpa 1>/dev/null 2>&1 ; then
    chmod 777 /var/lib/tftpboot
    cat > /etc/init.d/tftp <<EOF
    service tftp
    {
       disable = no
       socket_type = dgram
       protocol = udp
       wait = yes
       user = root
       server = /usr/sbin/in.tftpd
       server_args = -s /var/lib/tftpboot -c
       per_source = 11
       cps = 100 2
    }
EOF
    sed -i '/TFTP_OPTIONS/d' /etc/default/tftpd-hpa
    sed -i '/TFTP_ADDRESS/aTFTP_OPTIONS=" -l -c -s"' /etc/default/tftpd-hpa
fi

# auto load gpu driver module galcore.ko during booting up
if ! grep -q galcore /etc/modules; then
    echo galcore >> /etc/modules
fi

if ! grep -q mali-dp /etc/modules; then
    echo mali-dp >> /etc/modules
fi
