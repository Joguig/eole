#!/bin/bash
#
# postinstall.sh <vm_id>
# $1 = vm_id nebula
# $2 = vmOwner nebula
# $3 = options
#
# Attention : Lancé par le process de création de .fi apres avoir monté /mnt/eole-ci-tests
#
# le CDROM de context n'existe donc pas 
# =====================================
#
echo "Post Install Vm"
VM_ID=$1
VM_OWNER=$2
OPTIONS=$3

BASE=/mnt/eole-ci-tests

echo "Install Service 'eole-ci-tests' depuis /mnt/eole-ci-tests "
/bin/bash "$BASE/scripts/service/CheckUpdate.sh"
/bin/bash "$BASE/scripts/post-install/CheckUpdateService.sh"
    
cp "$BASE/scripts/service/mount.eole-ci-tests" /root/mount.eole-ci-tests
chmod 755 /root/mount.eole-ci-tests
chown root:root /root/mount.eole-ci-tests

echo "Impose Swapiness=0"
sysctl vm.swappiness=0

if [ "$OPTIONS" = "RESET_PASSWORD" ]
then
    if [ "$(lsb_release -rs)" == "22.04" ] || [ "$(lsb_release -rs)" == "24.04" ]
    then
        if grep -q 'minlen' /etc/pam.d/common-password 2>/dev/null
        then
            echo "minlen present dans /etc/pam.d/common-password"
        else
            echo "Inject minlen=4 dans /etc/pam.d/common-password"
            sed -i -e 's/pam_pwquality.so retry=3/pam_pwquality.so retry=3 minlen=4/' /etc/pam.d/common-password
        fi
        if grep -q 'minlen = 4' /etc/security/pwquality.conf 2>/dev/null
        then
            echo "minlen=4 present dans /etc/security/pwquality.conf"
        else
            echo "Inject minlen dans /etc/security/pwquality.conf"
            sed -i -e '/# minlen = 8/a minlen = 4' /etc/security/pwquality.conf  2>/dev/null
        fi 
        id pcadmin >/dev/null 2>&1 && echo -e "pcadmin:eole" | chpasswd -c SHA512 
        id eole >/dev/null 2>&1 && echo -e "eole:eole" | chpasswd -c SHA512
        echo -e "root:eole290" | chpasswd -c SHA512
        sed -i -e "s,Mot de passe.*,Mot de passe par défaut de l'utilisateur root : eole290," /etc/issue
        if command -v cloud-init
        then
            apt-get remove -y cloud-init
        fi
    else
        sed -i -e 's/obscure sha512/obscure minlen=4 sha512/' /etc/pam.d/common-password
        id pcadmin && echo -e "eole\neole" | passwd pcadmin
        id eole && echo -e "eole\neole" | passwd eole
        echo -e "eole\neole" | passwd root
    fi
fi

######################################
# Run fstrim at system boot/shutdown #
######################################
if command -v systemctl >/dev/null 2>/dev/null \
   && systemctl list-units "*.mount" >/dev/null
then
    if ! systemctl cat fstrim.service > /dev/null 2>&1
    then
	echo "Install systemd service to TRIM filesystems at boot/shutdown"
        # Provide default fstrim.service
        cat > /etc/systemd/system/fstrim.service <<EOT
[Unit]
Description=Discard unused blocks
After=local-fs.target remote-fs.target

[Service]
Type=oneshot
ExecStart=/sbin/fstrim -av
ExecStop=/sbin/fstrim -av
RemainAfterExit=yes

[Install]
WantedBy=basic.target
EOT
    else
	echo "Override systemd service to TRIM filesystems at boot/shutdown"
        mkdir -p /etc/systemd/system/fstrim.service.d
        cat > /etc/systemd/system/fstrim.service.d/override.conf <<EOT
[Unit]
After=local-fs.target remote-fs.target

[Service]
ExecStart=
ExecStart=/sbin/fstrim -av
ExecStop=/sbin/fstrim -av
RemainAfterExit=yes

[Install]
WantedBy=basic.target
EOT
    fi
    systemctl daemon-reload
    systemctl enable fstrim.service
else
    echo "Install wrapper to TRIM filesystems"
    mkdir -p ~root/bin

    cat > ~root/bin/trimallfs <<'EOT'
#!/bin/bash

#------------------------------------------------------------------------
# Copyright © 2016 Équpe EOLE <eole@ac-dijon.fr>
# Author: Daniel Dehennin <daniel.dehennin@ac-dijon.fr>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

log() { echo -e "$@"; }
warn() { log "$@" >&2; }
die() { warn "$@"; exit ${EXIT_CODE:-1}; }

[ "${DEBUG}" = 'yes' ] && set -x

if ! command -v fstrim > /dev/null 2>/dev/null
then
    die "Binary fstrim is not installed"
fi

fstrim -av 2> /dev/null
if [ $? = 1 ]
then
    # -a option is not supported
    # List all MOUNTPOINT with TRIM support then run fstrim on them
    lsblk -o MOUNTPOINT,DISC-MAX | grep -E '^/.* [1-9]+.*' | awk '{print $1}' | xargs -I{} fstrim -v {}
fi
EOT

    chmod +x ~root/bin/trimallfs

    if [ -x /sbin/initctl ]
    then

	echo "Upstart service to TRIM filesystem at boot/shutdown"

	cat > /etc/init/fstrim.conf <<'EOT'
# fstrim
#
# This service discard unused block

description "Discard unused block"

start on runlevel [S] and not-container
stop on runlevel [016] and not-container

exec /root/bin/trimallfs
EOT
    else
	echo "System V service to TRIM filesystems at boot/shutdown"
	cat > /etc/init.d/fstrim <<'EOT'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          fstrim
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     S
# Default-Stop:      0 1 6
# Short-Description: TRIM all filesystems
# Description:       Discard all deleted blocs to permit qemu-img
#                    to strip the images
### END INIT INFO

TRIMALLFS="/root/bin/trimallfs"

if [ -x "${TRIMALLFS}" ]
then
    ${TRIMALLFS}
fi
EOT
    chmod +x /etc/init.d/fstrim
    update-rc.d fstrim start 10 S . stop 30 0 1 6 . 2> /dev/null
    fi
fi

# Trim the filesystems now
service fstrim start

## Finish the post-install and POWEROFF the VM to save it
if [ -n "$VM_ID" ]
then
    if [ -n "$VM_OWNER" ]
    then
        [ ! -d "$BASE/output/$VM_OWNER" ] && mkdir "$BASE/output/$VM_OWNER"
        [ ! -d "$BASE/output/$VM_OWNER/$VM_ID" ] && mkdir "$BASE/output/$VM_OWNER/$VM_ID"
        echo "0" >>"$BASE/output/$VM_OWNER/$VM_ID/postinstall.exit"
        HOSTNAME="$(hostname)"
    	export HOSTNAME

        if [[ -f "$BASE/output/$VM_OWNER/$VM_ID/.eole-ci-tests.freshinstall" ]]
        then
            cp "$BASE/output/$VM_OWNER/$VM_ID/.eole-ci-tests.freshinstall" /root/.eole-ci-tests.freshinstall
            chmod 755 /root/.eole-ci-tests.freshinstall
            chown root:root /root/.eole-ci-tests.freshinstall
        fi
        env | sort >"$BASE/output/$VM_OWNER/$VM_ID/postinstall.env"
    fi
fi

echo "0" >"$BASE/output/$VM_OWNER/$VM_ID/vnc.exit"
echo "Post Install Vm fini"
