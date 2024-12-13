set -e

#BASE=/home/gilles/NAS1TO
BASE=/root

function cloneDepot()
{
    local url
    local project
    url="$1"
    folder="$2"
    project=$(basename "$1")
    project=${project/.git/}
    echo "Actualise '$project'" 
    cd "$folder" || exit 1
    if [ ! -d "$project" ]
    then
        echo "Clone $project"
        git clone "$url"
        cd "$project" || exit 1
    else
        echo "Pull $project"
        cd "$project" || exit 1
        git checkout master
        git pull
    fi
}

apt-get install -y build-essential git git-buildpackage pristine-tar
lvextend -r -L 10G /dev/eolebase-vg/root 

mkdir "$BASE"
cd "$BASE" || exit 1

cloneDepot https://github.com/samba-team/samba.git "$BASE/samba/"

pushd $BASE/samba/samba
git pull
git checkout v4-11-stable
git pull

sudo bootstrap/generated-dists/ubuntu1804/bootstrap.sh 
    
sudo  make uninstall

CPPFLAGS="-I/usr/include/tirpc" CFLAGS="-I/usr/include/tirpc" \
LINKFLAGS="-ltirpc" \

./configure --prefix=/usr \
            --sysconfdir=/etc \
            --localstatedir=/var \
            --exec-prefix=/usr/lib/x86_64-linux-gnu \
            --with-piddir=/run \
            --enable-fhs \
            --enable-selftest \
	        --accel-aes=intelaesni \
            --with-ads \
            --with-automount \
            --enable-avahi \
            --with-dnsupdate \
            --with-pam \
            --enable-pthreadpool \
	        --with-quotas \
	        --with-syslog \
	        --with-systemd \
	        --with-winbind \
	        --with-gpgme \
	        --systemd-install-services \
            --disable-rpath-install

make -j 4 
sudo  make install
    #sudo mv -v /usr/lib/libnss_win{s,bind}.so*   /lib                       
    #sudo ln -v -sf ../../lib/libnss_winbind.so.2 /usr/lib/libnss_winbind.so
    #sudo ln -v -sf ../../lib/libnss_wins.so.2    /usr/lib/libnss_wins.so    
command -v samba
samba -V
popd
