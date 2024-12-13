#!/bin/bash -x

my_dir="$(dirname "$0")"

# shellcheck disable=SC1091,SC1090
source "${my_dir}/get_vars_samba.sh"
export EOLE_VERSION
export SAMBA_VERSION
export DEBIAN_VERSION
export BASE

function cloneDepot()
{
    local url
    local project
    url="$1"
    project=$(basename "$1")
    project=${project/.git/}
    echo "Actualise '$project'" 
    cd "$BASE" || exit 1
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

cloneDepot https://salsa.debian.org/samba-team/talloc.git
cloneDepot https://salsa.debian.org/samba-team/tevent.git
cloneDepot https://salsa.debian.org/debian/cmocka.git
cloneDepot https://salsa.debian.org/samba-team/ldb.git
cloneDepot https://salsa.debian.org/samba-team/tdb.git
cloneDepot https://salsa.debian.org/samba-team/samba.git
apt-get build-dep -y "$BASE/samba"
exit 0
