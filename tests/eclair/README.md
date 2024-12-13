# ubuntu Jammy
apt install -y ltsp
apt install -y squashfs-tools

mkdir -p /srv/ltsp

cat >/etc/ltsp/ltsp-server.conf <<EOF
BASE="/srv/ltsp"
TFTP_DIRS="/tmp"
EOF

cat >/etc/ltsp/ltsp-build-client.conf <<EOF
MIRROR="http://ftp.gr.debian.org/debian"
COMPONENTS="main contrib non-free"
SECURITY_MIRROR="none"
DISTRIBUTION="testing"

# Some must-have stuff
LATE_PACKAGES="
        less
        nano
        aptitude
        man
        nfs-client
"
EOF

BASE_DIR=/srv/ltsp ltsp image /
