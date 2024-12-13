#!/bin/bash

checkMirroirUbuntu()
{ 
    LASTDIFF_FILE="/mnt/eole-ci-tests/depots/lastDiff"
    rm -f "$LASTDIFF_FILE"
    MIRROR="$1"
    #checkDistribUbuntu lucid
    #checkDistribUbuntu precise
    checkDistribUbuntu trusty
    checkDistribUbuntu xenial
    checkDistribUbuntu bionic
    checkDistribUbuntu focal
    checkDistribUbuntu jammy
    checkDistribUbuntu noble
}

checkDistribUbuntu()
{
    DISTRIB=$1
    checkDepot ""
    checkDepot "-backport"
    checkDepot "-proposed"
    checkDepot "-proposed-updates"
    checkDepot "-security"
    checkDepot "-updates"
}

checkDepot()
{
    DEPOT=$1
    checkSousDepot main
    checkSousDepot multiverse
    checkSousDepot restricted
    checkSousDepot univers
}

checkMirroirEole()
{
    MIRROR="$1"
    # TODO: beurk, utiliser 'liste_version.txt'
    #checkDistribEole eole-2.4
    #checkDistribEole eole-2.4.0
    #checkDistribEole eole-2.4.1
    #checkDistribEole eole-2.4.2
    #checkDistribEole eole-2.5
    #checkDistribEole eole-2.5.0
    #checkDistribEole eole-2.5.1
    checkDistribEole eole-2.5.2
    checkDistribEole eole-2.6
    checkDistribEole eole-2.6.0
    checkDistribEole eole-2.6.1
    checkDistribEole eole-2.6.2
    checkDistribEole eole-2.7
    checkDistribEole eole-2.7.0
    checkDistribEole eole-2.7.1
    checkDistribEole eole-2.7.2
    checkDistribEole eole-2.8
    checkDistribEole eole-2.8.0
    checkDistribEole eole-2.8.1
    checkDistribEole eole-2.9
    checkDistribEole eole-2.9.0
    checkDistribEole eole-2.10
    checkDistribEole eole-2.10.0
}

checkDistribEole()
{
    DISTRIB=$1
    checkDepotEole ""
    checkDepotEole "-testing"
    checkDepotEole "-unstable"
    checkDepotEole "-proposed-updates"
    checkDepotEole "-security"
    checkDepotEole "-updates"
}

checkDepotEole()
{
    DEPOT=$1
    checkSousDepot main
    checkSousDepot cloud
}

checkMirroirEnvole()
{
    MIRROR="$1"
    checkDistribEnvole envole-4
    checkDistribEnvole envole-5
    checkDistribEnvole envole-6
    checkDistribEnvole envole-7
}

checkDistribEnvole()
{
    LASTDIFF_FILE="/mnt/eole-ci-tests/depots/lastDiff.envole"
    rm -f "$LASTDIFF_FILE"
    DISTRIB=$1
    checkDepotEnvole ""
    checkDepotEnvole "-unstable"
    checkDepotEnvole "-testing"
    checkDepotEnvole "-experimental"
}

checkDepotEnvole()
{
    DEPOT=$1
    checkSousDepot main
}

checkSousDepot()
{
    SOUSDEPOT=$1
    url="$MIRROR/dists/${DISTRIB}${DEPOT}/${SOUSDEPOT}/binary-amd64/Packages.gz"
    fichier="${DISTRIB}${DEPOT}_${SOUSDEPOT}"
    fichier_pkgs="/mnt/eole-ci-tests/depots/${fichier}.pkgs"
    fichier_filename="/mnt/eole-ci-tests/depots/${fichier}.filename"
    fichier_date="/mnt/eole-ci-tests/depots/${fichier}.date"
    curl -s -I "$url" >/tmp/curl 
    if grep "404" /tmp/curl >/dev/null
    then
        #echo "$fichier => dépots vide ?"
        rm -f "$fichier_filename"
        rm -f "$fichier_pkgs"
        return 0
    fi
    if grep "200" /tmp/curl >/dev/null
    then
        LM=$(grep  "Last-Modified" /tmp/curl)
        if [ -f "$fichier_date" ] && [ -f "${fichier_filename}" ]
        then
            D=$(grep  "Last-Modified" "$fichier_date")
            if [ "$D" == "$LM" ]
            then
                echo "$fichier => non modifié"
                return 0
            else 
                echo "$fichier => modifié  $D <> $LM "
            fi
        else
            echo "$fichier ==> nouveau "
        fi
        cp /tmp/curl "$fichier_date"
        wget --output-document=- "$url" | gzip --decompress --stdout >/tmp/pkgs
        grep "Filename:" </tmp/pkgs >/tmp/pkgs.filename
        if [ ! -f "${fichier_filename}" ]
        then
            echo "nouveau fichier 'filename' !"
        else
            if diff "${fichier_filename}" /tmp/pkgs.filename >/tmp/diff
            then
                echo "pas de changement !"
                return 0
            else
                echo "paquets différents !"
            fi
        fi

        MODIFICATION_DETECTEE="0"
        cp -f /tmp/pkgs "${fichier_pkgs}"
        cp -f /tmp/pkgs.filename "${fichier_filename}"
        (
        echo "===================================================================" 
        echo "${fichier} différents !" 
        ) >>"$LASTDIFF_FILE" 
        cat /tmp/diff >>"$LASTDIFF_FILE"
        return 1
    fi
    echo "$fichier => url ? $url "
    cat /tmp/curl
    return 2
}


checkMirroirFreeBSD()
{
    MIRROR="$1"
    checkDistribFreeBSD 12
    checkDistribFreeBSD 13
}

checkDistribFreeBSD()
{
    LASTDIFF_FILE="/mnt/eole-ci-tests/depots/lastDiff.freebsd"
    rm -f "$LASTDIFF_FILE"
    DISTRIB=$1
    checkDepotFreeBSD "latest"
    checkDepotFreeBSD "release_0"
    checkDepotFreeBSD "release_1"
    checkDepotFreeBSD "release_2"
    checkDepotFreeBSD "release_3"
}

checkDepotFreeBSD()
{
    DEPOT=$1
    url="$MIRROR/FreeBSD:${DISTRIB}:amd64/${DEPOT}/packagesite.txz"
    fichier="FreeBSD${DISTRIB}_${DEPOT}"
    fichier_pkgs="/mnt/eole-ci-tests/depots/${fichier}.pkgs"
    fichier_filename="/mnt/eole-ci-tests/depots/${fichier}.filename"
    fichier_date="/mnt/eole-ci-tests/depots/${fichier}.date"
    curl -s -I "$url" >/tmp/curl 
    if grep "404" /tmp/curl >/dev/null
    then
        #echo "$fichier => dépots vide ?"
        rm -f "$fichier_filename"
        rm -f "$fichier_pkgs"
        return 0
    fi
    if grep "200" /tmp/curl >/dev/null
    then
        LM=$(grep  "Last-Modified" /tmp/curl)
        if [ -f "$fichier_date" ] && [ -f "${fichier_filename}" ]
        then
            D=$(grep  "Last-Modified" "$fichier_date")
            if [ "$D" == "$LM" ]
            then
                echo "$fichier => non modifié"
                return 0
            else 
                echo "$fichier => modifié  $D <> $LM "
            fi
        else
            echo "$fichier ==> nouveau "
        fi
        cp /tmp/curl "$fichier_date"
        wget --output-document=/tmp/pkgs.txz "$url"
        cd /tmp || exit 1
        tar xvfJ /tmp/pkgs.txz packagesite.yaml  
        cp packagesite.yaml /tmp/pkgs
        jq -c "{name: .name,version: .version}" packagesite.yaml >/tmp/pkgs.filename 
        if [ ! -f "${fichier_filename}" ]
        then
            echo "nouveau fichier 'filename' !"
        else
            if diff "${fichier_filename}" /tmp/pkgs.filename >/tmp/diff
            then
                echo "pas de changement !"
                return 0
            else
                echo "paquets différents !"
            fi
        fi

        MODIFICATION_DETECTEE="0"
        cp -f /tmp/pkgs "${fichier_pkgs}"
        cp -f /tmp/pkgs.filename "${fichier_filename}"
        (
        echo "===================================================================" 
        echo "${fichier} différents !" 
        ) >>"$LASTDIFF_FILE" 
        cat /tmp/diff >>"$LASTDIFF_FILE"
        return 1
    fi
    echo "$fichier => url ? $url "
    cat /tmp/curl
    return 2
}


checkMirrors()
{
    checkMirroirUbuntu http://eole.ac-dijon.fr/ubuntu
    checkMirroirEole http://test-eole.ac-dijon.fr/eole
    checkMirroirEnvole http://test-eole.ac-dijon.fr/envole
    checkMirroirFreeBSD https://pkg.freebsd.org
}

echo "start"
MODIFICATION_DETECTEE="1"
if [ -f "/mnt/eole-ci-tests/ModulesEole.yaml" ]
then
    mkdir -p "/mnt/eole-ci-tests/depots"
    checkMirrors
    echo "ok"
else
    echo "/mnt/eole-ci-tests/ non monté !"
fi
exit "$MODIFICATION_DETECTEE"
