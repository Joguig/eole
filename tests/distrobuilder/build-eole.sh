#!/bin/bash -x 

ARCHIVE=http://eole.ac-dijon.fr/ubuntu
#TYPE=container
RELEASE=focal
VARIANT=eole-sso
ARCHITECTURE=amd64

mkdir -p "/tmp/eole" "/tmp/distrobuilder"
cp eole.yml /tmp/eole/eole.yaml
pushd "/tmp/eole" ||exit 1

/usr/bin/distrobuilder --cache-dir /tmp/distrobuilder \
                       build-lxc eole.yaml \
                       -o image.name="eole-{{ eole.version }}-{{ eole.architecture }}" \
                       -o image.architecture="$ARCHITECTURE" \
                       -o image.release="$RELEASE" \
                       -o image.variant="$VARIANT" \
                       -o source.url="$ARCHIVE"
                       
lxc-create -n eole-sso -t local -- --metadata meta.tar.xz --fstree rootfs.tar.xz

lxc-start -n eole-sso

cat >/tmp/config.eol <<EOF
{
    "___version___":"2.8.1",
    "activer_ead_web":{"owner":"basique","val":"oui"},
    "adresse_ip_dns":{"owner":"basique","val":["192.168.0.1"]},
    "adresse_ip_eth0":{"owner":"basique","val":"192.168.0.24"},
    "adresse_ip_gw":{"owner":"basique","val":"192.168.0.1"},
    "bash_tmout":{"owner":"basique","val":0},
    "check_passwd":{"owner":"basique","val":"non"},
    "domaine_messagerie_etab":{"owner":"basique","val":"ac-test.fr"},
    "exim_relay_smtp":{"owner":"basique","val":"gateway.ac-test.fr"},
    "frontend_ead_distant_eth0":{"owner":"gen_config","val":"oui"},
    "ip_admin_eth0":{"owner":"basique","val":["0.0.0.0"]},
    "ip_frontend_ead_distant_eth0":{"owner":"gen_config","val":["0.0.0.0"]},
    "ip_ssh_eth0":{"owner":"basique","val":["0.0.0.0"]},
    "libelle_etab":{"owner":"basique","val":"aca"},
    "netmask_admin_eth0":{"owner":{"0":"basique"},"val":{"0":"0.0.0.0"}},
    "netmask_frontend_ead_distant_eth0":{"owner":{"0":"gen_config"},"val":{"0":"0.0.0.0"}},
    "netmask_ssh_eth0":{"owner":{"0":"basique"},"val":{"0":"0.0.0.0"}},
    "nom_academie":{"owner":"basique","val":"ac-test"},
    "nom_domaine_local":{"owner":"basique","val":"ac-test.fr"},
    "nom_machine":{"owner":"basique","val":"eolebase"},
    "numero_etab":{"owner":"basique","val":"0000000A"},
    "serveur_maj":{"owner":"basique","val":["test-eole.ac-dijon.fr"]},
    "serveur_ntp":{"owner":"basique","val":["hestia.eole.lan"]},
    "ssh_eth0":{"owner":"basique","val":"oui"},
    "ssl_organization_unit_name":{"owner":"basique","val":["110 043 015","ac-test"]},
    "system_mail_from":{"owner":"basique","val":"fromuser@ac-test.fr"},
    "system_mail_to":{"owner":"basique","val":"touser@ac-test.fr"},
    "vm_swappiness":{"owner":"basique","val":0}
}
EOF

lxc-attach -n eole-sso mkdir /etc/eole/extra

find /var/lib/lxc/eole-sso/rootfs

cp /tmp/config.eol /var/lib/lxc/eole-sso/rootfs/etc/eole/config.eol

ciMonitor lxc-attach -n eole-sso instance
ls -l 
popd ||exit 1
