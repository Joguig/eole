#!/bin/bash -x


ciPrintMsg "Identifier le /dev"
LVM=$(vgs --noheadings -o name |xargs)
if [ -z "${LVM}" ]
then
    ciSignalWarning "impossible de trouver le dev LVM"
    return 1
fi

echo "LVM=${LVM}"
ls -l "/dev/${LVM}"

LVM_FREE=$(vgs --noheadings -o pv_free | xargs)
echo "LVM_FREE=${LVM_FREE}"

ciPrintMsg "Lister les LVM"
lvscan

ciPrintMsg "Voir l’espace libre sur le VG"
vgdisplay | grep "Free  PE / Size"

LVM_FREE1=$(vgs --noheadings -o pv_free | xargs)
echo "LVM_FREE1=${LVM_FREE1}"
if [ "${LVM_FREE1}" == "0" ]
then
    ciSignalWarning "pas de place disponible pour etendre le LVM"
    exit 0
fi

ciPrintMsg "Current size LV de /dev/${LVM}/root"
LV_SIZE=$(lvs "/dev/${LVM}/root" --noheadings -olv_size)
echo "$LV_SIZE"

ciPrintMsg "Ajouter ${LVM_FREE1} au LV de /dev/${LVM}/root"
lvextend -L+"${LVM_FREE1}" "/dev/${LVM}/root"
RESULT="$?"
if [ "$RESULT" -ne 0 ]
then
    ciSignalWarning "impossible d'étendre le LV (exit=$RESULT)"
    exit 1
fi

ciPrintMsg "Étendre le système de fichier pour occuper tout l’espace ajouté"
resize2fs "/dev/${LVM}/root"
RESULT="$?"
if [ "$RESULT" -ne 0 ]
then
    ciSignalWarning "impossible resizer le LV (exit=$RESULT)"
    exit 1
fi
