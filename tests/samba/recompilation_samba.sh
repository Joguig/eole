#!/bin/bash

my_dir="$(dirname "$0")"
echo $my_dir

# shellcheck disable=SC1091,SC1090
source "${my_dir}/get_vars_samba.sh"
export EOLE_VERSION
echo "EOLE_VERSION=$EOLE_VERSION"
export SAMBA_VERSION
echo "SAMBA_VERSION=$SAMBA_VERSION"
export DEBIAN_VERSION
echo "DEBIAN_VERSION=$DEBIAN_VERSION"
export BASE

if ! grep deb-src /etc/apt/sources.list.d/samba.list
then
	echo -e "deb [ arch=amd64 ] http://test-eole.ac-dijon.fr/samba samba-$SAMBA_VERSION main\ndeb-src [ arch=amd64 ] http://test-eole.ac-dijon.fr/samba samba-$SAMBA_VERSION main" > /etc/apt/sources.list.d/samba.list
	sed -e 's/^deb/deb-src/' /etc/apt/sources.list >> /etc/apt/sources.list.d/samba.list
	cat /etc/apt/sources.list.d/samba.list
        wget -O /tmp/repository.key "http://test-eole.ac-dijon.fr/eole/project/eole-${EOLE_VERSION}-repository.key"
        apt-key add /tmp/repository.key
	apt-get update 
	apt-get install -y build-essential git git-buildpackage pristine-tar
        apt-get upgrade -y 
fi

cd "$BASE" || exit 1
if [ ! -d samba ]
then
    git clone https://salsa.debian.org/samba-team/samba.git
    cd samba || exit 1
else
    cd samba || exit 1
    git checkout master
    git reset --hard HEAD
    git pull
fi

set -x
git checkout -b pristine-tar origin/pristine-tar
git remote add dev-eole https://dev-eole.ac-dijon.fr/git/samba.git
git remote -v
git fetch dev-eole
git checkout -b "$DEBIAN_VERSION" "origin/$DEBIAN_VERSION"
git checkout "$DEBIAN_VERSION"
git remote -v
git describe
TAG_SAMBA_DEBIAN=$(git describe)
echo "TAG_SAMBA_DEBIAN=$TAG_SAMBA_DEBIAN"
export TAG_SAMBA_DEBIAN
VERSION_TALLOC_DEBIAN=$(grep ^VERSION lib/talloc/wscript | awk '{ print substr($3,2,length($3)-2); }' )
echo "VERSION_TALLOC_DEBIAN=$VERSION_TALLOC_DEBIAN"
export VERSION_TALLOC_DEBIAN
VERSION_TDB_DEBIAN=$(grep ^VERSION lib/tdb/wscript | awk '{ print substr($3,2,length($3)-2); }')
echo "VERSION_TDB_DEBIAN=$VERSION_TDB_DEBIAN"
export VERSION_TDB_DEBIAN
VERSION_TEVENT_DEBIAN=$(grep ^VERSION lib/tevent/wscript | awk '{ print substr($3,2,length($3)-2); }')
echo "VERSION_TEVENT_DEBIAN=$VERSION_TEVENT_DEBIAN"
VERSION_LDB_DEBIAN=$(grep ^VERSION lib/ldb/wscript | awk '{ print substr($3,2,length($3)-2); }')
export VERSION_TEVENT_DEBIAN
echo "VERSION_LDB_DEBIAN=$VERSION_LDB_DEBIAN"
export VERSION_LDB_DEBIAN

git --no-pager branch
git checkout "dist/eole/$EOLE_VERSION/master"
test $? -eq 0 || exit 1
git --no-pager branch
git describe
TAG_SAMBA_EOLE=$(git describe)
echo "TAG_SAMBA_EOLE=$TAG_SAMBA_EOLE"
export TAG_SAMBA_EOLE
VERSION_TALLOC_EOLE=$(grep ^VERSION lib/talloc/wscript | awk '{ print substr($3,2,length($3)-2); }' )
echo "VERSION_TALLOC_EOLE=$VERSION_TALLOC_EOLE"
export VERSION_TALLOC_EOLE
VERSION_TDB_EOLE=$(grep ^VERSION lib/tdb/wscript | awk '{ print substr($3,2,length($3)-2); }')
echo "VERSION_TDB_EOLE=$VERSION_TDB_EOLE"
export VERSION_TDB_EOLE
VERSION_TEVENT_EOLE=$(grep ^VERSION lib/tevent/wscript | awk '{ print substr($3,2,length($3)-2); }')
echo "VERSION_TEVENT_EOLE=$VERSION_TEVENT_EOLE"
VERSION_LDB_EOLE=$(grep ^VERSION lib/ldb/wscript | awk '{ print substr($3,2,length($3)-2); }')
export VERSION_TEVENT_EOLE
echo "VERSION_LDB_EOLE=$VERSION_LDB_EOLE"
export VERSION_LDB_EOLE
set -x

echo "----------------------------------------------------------------- samba/master "
echo "   | commit branch "
echo "   \------------------------------ ${TAG_SAMBA_DEBIAN} (origin/$DEBIAN_VERSION)"
echo "          | commit branch "
echo "          \---*-*-- ${TAG_SAMBA_EOLE} (dist/eole/$EOLE_VERSION/master)"

echo "************************************************************************************"
echo "* git log --graph --decorate --oneline"
git log --graph --decorate --oneline

echo "************************************************************************************"
echo "* git branch --no-merged"
git branch --no-merged

echo "************************************************************************************"
echo "* liste des commits DEBIAN non présent chez EOLE" 
echo "* git cherry -v ${TAG_SAMBA_EOLE} ${TAG_SAMBA_DEBIAN}" 
git cherry -v "${TAG_SAMBA_EOLE}" "${TAG_SAMBA_DEBIAN}" 
echo "************************************************************************************"

echo "************************************************************************************"
echo "* git --no-pager log ${TAG_SAMBA_EOLE}..${TAG_SAMBA_DEBIAN}" 
#git --no-pager log "${TAG_SAMBA_EOLE}..${TAG_SAMBA_DEBIAN}"
git --no-pager log -n 4 --pretty=oneline
echo "************************************************************************************"

echo "************************************************************************************"
echo "* git checkout dist/eole/$EOLE_VERSION/master"
git checkout "dist/eole/$EOLE_VERSION/master"

echo "************************************************************************************"
git log "${TAG_SAMBA_DEBIAN}" -n 1 --pretty=oneline
echo "************************************************************************************"
git log "${TAG_SAMBA_EOLE}" -n 1 --pretty=oneline
echo "************************************************************************************"
exit 0

echo "************************************************************************************"
echo "* git merge ${TAG_SAMBA_DEBIAN}"
git merge "${TAG_SAMBA_DEBIAN}"
git merge --abort 

echo "A faire :" 
echo "- enlever les commits EOLE"
echo "- enlever les marques de merge"
echo "- La lecture du changelog Debian a montré que les patches de sécurité (CVE) samba-4.9.6 étaient déjà appliqués sur la version 4.9.5 packagée par Debian.%"

echo "************************************************************************************"
echo "* git --no-pager diff HEAD~..HEAD"
echo "************************************************************************************"
git --no-pager diff HEAD~..HEAD
echo "************************************************************************************"
#git add .
#git commit -m "backlport gilles"
git checkout "dist/eole/$EOLE_VERSION/master"

cat >"$BASE/build.sh" <<EOF
cd /root/samba
gbp export-orig
exit
EOF

docker run -it --rm --name eole-debian-buster  -v "$BASE":/root eole-debian-buster /bin/bash /root/build.sh
echo "gbp export-orig ok $?"  

#cd "$BASE" || exit 1

if [ "$VERSION_TALLOC_EOLE" != "$VERSION_TALLOC_DEBIAN" ]
then
    cd "$BASE" || exit 1
    if [ ! -d talloc ]
    then
        git clone https://salsa.debian.org/samba-team/talloc.git
        cd talloc || exit 1
    else
        cd talloc || exit 1
        git checkout master
        git pull
    fi
    git remote add dev-eole https://dev-eole.ac-dijon.fr/git/talloc.git
    git remote -v
    git checkout -b pristine-tar origin/pristine-tar
    git fetch dev-eole
    git pull
    git checkout -b upstream debian/2.1.14-2
    TAG_TALLOC_DEBIAN=$(git describe)
    echo "TAG_TALLOC_DEBIAN=$TAG_TALLOC_DEBIAN"
    export TAG_TALLOC_DEBIAN

    git checkout "dist/eole/$EOLE_VERSION/master"
    git describe
    TAG_SAMBA_EOLE=$(git describe)
    echo "TAG_SAMBA_EOLE=$TAG_SAMBA_EOLE"
    
    gbp export-orig
    git pull
    cd "$BASE" || exit 1
else
    echo "pas besoin de rebuild TALLOC"
fi

if [ "$VERSION_TEVENT_EOLE" != "$VERSION_TEVENT_DEBIAN" ]
then
    cd "$BASE" || exit 1
    if [ ! -d tevent ]
    then
        git clone https://salsa.debian.org/samba-team/tevent.git
        cd tevent || exit 1
    else
        cd tevent || exit 1
        git checkout master
        git pull
    fi
    git remote add dev-eole https://dev-eole.ac-dijon.fr/git/tevent.git
    git remote -v
    git checkout -b pristine-tar origin/pristine-tar
    git fetch dev-eole
    gbp export-orig
    git pull
    cd "$BASE" || exit 1
else
    echo "pas besoin de rebuild TEVENT"
fi

if [ "$VERSION_CMOCKA_EOLE" != "$VERSION_CMOCKA_DEBIAN" ]
then
    cd "$BASE" || exit 1
    if [ ! -d cmocka ]
    then
        git clone https://salsa.debian.org/debian/cmocka.git
        cd cmocka || exit 1
    else
        cd cmocka || exit 1
        git checkout master
        git pull
    fi
    git remote add dev-eole https://dev-eole.ac-dijon.fr/git/cmocka.git
    git remote -v
    git checkout -b pristine-tar origin/pristine-tar
    git fetch dev-eole
    gbp export-orig
    git pull
    cd "$BASE" || exit 1
else
    echo "pas besoin de rebuild CMOCKA"
fi

if [ "$VERSION_LDB_EOLE" != "$VERSION_LDB_DEBIAN" ]
then
    cd "$BASE" || exit 1
    if [ ! -d ldb ]
    then
        git clone https://salsa.debian.org/samba-team/ldb.git
        cd ldb || exit 1
    else
        cd ldb || exit 1
        git checkout master
        git pull
    fi
    git remote add dev-eole https://dev-eole.ac-dijon.fr/git/ldb.git
    git remote -v
    git checkout -b pristine-tar origin/pristine-tar
    git fetch dev-eole
    gbp export-orig
    git pull
    cd "$BASE" || exit 1
else
    echo "pas besoin de rebuild LDB"
fi

if [ "$VERSION_TDB_EOLE" != "$VERSION_TDB_DEBIAN" ]
then
    cd "$BASE" || exit 1
    if [ ! -d tdb ]
    then
        git clone https://salsa.debian.org/samba-team/tdb.git
        cd tdb || exit 1
    else
        cd tdb || exit 1
        git checkout master
        git pull
    fi
    git remote add dev-eole https://dev-eole.ac-dijon.fr/git/tdb.git
    git remote -v
    git checkout -b pristine-tar origin/pristine-tar
    git fetch dev-eole
    gbp export-orig
    git pull
    cd "$BASE" || exit 1
else
    echo "pas besoin de rebuild TDB"
fi

echo "======================================"
echo "Compilation samba"
cd "$BASE" || exit 1
mkdir work
echo "cp samba_4.9.5+dfsg.orig.tar.xz root@eolebase.ac-test.fr:"
echo "rsync -avz samba -e ssh root@eolebase.ac-test.fr:"

echo "NB : La copie des sources (dépôt) samba via ssh entraîne une erreur de liens symboliques par la suite !%"

echo "Vérifier/installer les dépendances de compilation :"

apt-get build-dep -y ./samba
test $? -eq 0 || exit 1

echo "Si à cette étape, on s'aperçoit qu'une des librairies est à recompiler, aller voir [[Samba#Compilation-dune-librairie-exemple-ldb|Compiler et diffuser une librairie]] et revenez plus tard !%"

echo "Compiler le paquet (%{color:purple}prévoir 40 minutes% une fois lancé)"
cd "$BASE" || exit 1
cd samba || exit 1
dpkg-buildpackage -sa --no-sign
test $? -eq 0 || exit 1

echo "l'option @-sa@ permet d'inclure les sources. Il ne faut pas la mettre si les sources ont déjà été inclues."
echo "l'option @--no-sign@ évite d'avoir une erreur lors de la tentative de signature des paquets ;)"

echo "Une fois le paquet compilé on obtient les fichiers deb, changes et dsc dans le répertoire supérieur."
echo "Il est possible de vérifier la liste de ce qui a été compilé en consultant le fichier *.changes."

echo "======================================"
echo "Signer le paquet"

echo "Sur la machine @bionic-builder@, créer un répertoire dédié (exemple @~/samba@) puis copier les fichiers générés dedans :"
echo "scp *.*deb *.tar.xz *.dsc *.changes *.buildinfo buildd@bionic-builder.eole.lan:samba"
echo ""

echo "Sur la machine @bionic-builder@, signer les paquets à l'aide de la commande :"

echo "cd samba || exit 1"
echo "debsign -k eole *.changes"
test $? -eq 0 || exit 1


echo "======================================"
echo "Publier le paquet"

echo "Sur la machine @castor@, créer un répertoire dédié (exemple @/srv/repository/samba/tmp/samba@) puis copier les paquets signés dedans :"

echo "scp * repository@castor:/srv/repository/samba/tmp/samba"


echo "Puis importer les paquets dans le dépôt :"

echo "cd /srv/repository/samba || exit 1"
echo "reprepro -v include samba-4.9 tmp/samba/*.changes"


echo "Il est possible de vérifier les paquets disponible à l'aide de la commande :"
echo "reprepro listfilter samba-4.9 '\$Source (= samba)'"

echo "======================================"
echo "Finaliser le travail"

echo "Mettre à jour et pousser toutes les branches ..."
echo "FIXME"

