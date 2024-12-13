#!/bin/bash +x

VM_VERSIONMAJEUR="$1"
MAJ_AUTO="$2"
DIST_UBUNTU="$3"

echo "start"
VERSION_EOLE=$( echo "$VM_VERSIONMAJEUR" | cut -c 1-3 )
#pour les nommage voir 'checkMajDepots.sh'
PKGS="${DIST_UBUNTU}_main \
      ${DIST_UBUNTU}_multiverse \
      ${DIST_UBUNTU}_restricted \
      ${DIST_UBUNTU}_univers \
      ${DIST_UBUNTU}-security_main \
      ${DIST_UBUNTU}-security_multiverse \
      ${DIST_UBUNTU}-security_restricted \
      ${DIST_UBUNTU}-security_univers \
      ${DIST_UBUNTU}-updates_main \
      ${DIST_UBUNTU}-updates_multiverse \
      ${DIST_UBUNTU}-updates_restricted \
      ${DIST_UBUNTU}-updates_univers "
    
case "$MAJ_AUTO" in
        STABLE)
          PKGS="$PKGS eole-${VM_VERSIONMAJEUR}_main \
                      eole-${VM_VERSIONMAJEUR}-security_main \
                      eole-${VM_VERSIONMAJEUR}-updates_main" 
          ;;

        RC)
          PKGS="$PKGS eole-${VM_VERSIONMAJEUR}_main \
                      eole-${VM_VERSIONMAJEUR}-security_main \
                      eole-${VM_VERSIONMAJEUR}-updates_main \
                      eole-${VM_VERSIONMAJEUR}-proposed-updates_main" 
          ;;

        DEV)
          PKGS="$PKGS eole-${VERSION_EOLE}-unstable_main" 
          ;;
          
       *)
          echo "MAJ_AUTO inconnu : $MAJ_AUTO"
          exit 1
          ;;
esac
   
rm -f "/tmp/pkgs-${VERSION_EOLE}"
declare -a PKGS_NAME
declare -a PKGS_NAME1

for PKG in $PKGS;
do
    if test -s "$HOME/depots/${PKG}.filename"
    then
        echo "utilise ${PKG}.filename"
        PKGS_NAME1=( $(sed -e 's#Filename: pool/.*/.*/.*/##' "$HOME/depots/${PKG}.filename") )
        PKGS_NAME=( "${PKGS_NAME[@]}" "${PKGS_NAME1[@]}" )
    else
        echo "utilise ${PKG}.filename (vide)"
    fi
done
touch "/tmp/pkgs-${VERSION_EOLE}"
sort <"/tmp/pkgs-${VERSION_EOLE}" | uniq | sed -e 's#Filename: pool/.*/.*/.*/##' >"/tmp/pkgs-${VERSION_EOLE}-filename"

PKGS_NAME=( $(sed -e 's#Filename: pool/.*/.*/.*/##' -e 's#_# #' "$HOME/depots/${PKG}.filename") )
echo "${PKGS_NAME[*]}" 


FICHIER_VERSION="$HOME/depots/${VM_VERSIONMAJEUR}"
if [ ! -f "${FICHIER_VERSION}.filename" ]
then
    echo "nouveau fichier filename"
    cp "/tmp/pkgs-${VERSION_EOLE}-filename" "/tmp/diff-${VERSION_EOLE}"
else
    diff -y --suppress-common-lines "${FICHIER_VERSION}.filename" "/tmp/pkgs-${VERSION_EOLE}-filename" >"/tmp/diff-${VERSION_EOLE}"
    if [ $? -eq 0 ]
    then
        echo "pas de changement !"
        rm -f "${FICHIER_VERSION}.lastDiff"
        #cat "/tmp/pkgs-${VERSION_EOLE}-filename"
        exit 1
    else
        echo "paquets différents !"
    fi
fi

nbUpdate=0
find /mnt/eole-ci-tests/module/ -name "*-${VERSION_EOLE}" -exec sort {} +  | uniq >"/tmp/paquets-${VERSION_EOLE}"
wc "/tmp/paquets-${VERSION_EOLE}"
while read -r paquet 
do
   if grep -E "^${paquet}\$" "/tmp/diff-${VERSION_EOLE}" 
   then
       echo "paquet mis à jour : $paquet"
       nbUpdate=$(( nbUpdate + 1 ))
   fi
done <"/tmp/paquets-${VERSION_EOLE}"

cat "/tmp/diff-${VERSION_EOLE}"
if (( nbUpdate > 0 ))
then 
    echo "des changements mais pas sur les paquets des modules"
    exit 1
else
    cp -f "/tmp/pkgs-${VERSION_EOLE}-filename" "${FICHIER_VERSION}.filename"
    echo "paquets ${VM_VERSIONMAJEUR} différents !" >>"${FICHIER_VERSION}.lastDiff" 
    cat "/tmp/diff-${VERSION_EOLE}" >"${FICHIER_VERSION}.lastDiff"
    echo "des changements sur $nbUpdate paquet(s)"
    exit 0
fi
