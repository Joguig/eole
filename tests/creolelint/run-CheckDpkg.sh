#!/bin/bash

#########################################################################################################
#
# Check Dpkg Detail
#
#########################################################################################################
function ciCheckDpkgDetail()
{
    ACTION="$1"
    REFERENCE_FILE="$2"

    DPKG_DERNIER_FILE=${REFERENCE_FILE}.last_detail

    #
    # gestion dpkg détail
    #
    TMPFILE_DETAIL=/tmp/dpkg_detail.$$
    dpkg -l >"$TMPFILE_DETAIL"
    RESULT="0"
    if [[ ! -f "$DPKG_DERNIER_FILE" ]]
    then
       RESULT="1"
    else
       ciDiff "$TMPFILE_DETAIL" "$DPKG_DERNIER_FILE" >/dev/null
       RESULT="$?"
    fi
    if [ "$RESULT" == "1" ]
    then
       ciPrintMsg "Sauvegarde dpkg dans : $DPKG_DERNIER_FILE"
       /bin/cp -f "$TMPFILE_DETAIL" "$DPKG_DERNIER_FILE"
       DPKG_DATE_FILE=${REFERENCE_FILE}.$(date "+%Y-%m-%d_%H:%M:%S")
       ciPrintMsg "Sauvegarde nouveau dans historique : $DPKG_DATE_FILE"
       /bin/cp -f "$TMPFILE_DETAIL" "$DPKG_DATE_FILE"

       local ALERTE
       local nbAlerte
       nbAlerte=0
       ALERTE=""
       ciGetEoleVersion
       while read -r paquet derniere_version
       do
           ciPrintMsgMachine "check paquet : $paquet, $derniere_version"
           if grep -E "^${paquet}\$" "$DELTAFILE" >/dev/null 2>/dev/null
           then
               if [ "$VM_VERSION_EOLE" \> "$derniere_version" ]
               then
                   ALERTE="$ALERTE $paquet"
                   nbAlerte=$(( nbAlerte + 1 ))
               else
                   ciPrintMsgMachine "ATTENTION : paquet '$paquet' mis à jour par ubuntu mais ignoré en $VM_VERSION_EOLE"
               fi
           fi
       done <"$VM_DIR_EOLE_CI_TEST/scripts/liste_paquets_recompile.txt"

       if (( nbAlerte > 1 ))
       then
           ciPrintMsgMachine "ALERTE=$ALERTE"
           ciSignalAlerte "Paquets modifiés : $ALERTE"
       else
           if (( nbAlerte > 0 ))
           then
               ciPrintMsgMachine "ALERTE=$ALERTE"
               ciSignalAlerte "Paquet modifié : $ALERTE"
           else
               ciPrintMsgMachine "Pas de paquet UBUNTU modifié!"
           fi
       fi

       if [[ "$ACTION" = "ERREUR_SI_DIFFERENT" ]]
       then
           exit 1
       fi
    fi
    return 0
}

#########################################################################################################
#
# ciIsPaquetEole
# True si paquet EOLE
#
#########################################################################################################
function ciIsPaquetEole()
{
    # "/eole/ " en 2.5.2 !
    if apt-cache policy "$1" | grep -e "cdrom://EOLE " -e "/eole " -e "/eole/ " -e "/envole " >/dev/null 
    then
        return 0
    else
        return 1
    fi
}
export -f ciIsPaquetEole

#########################################################################################################
#
# Check Dpkg Nom
# gestion dpkg non détaillé : uniquement les noms de paquet
#
#########################################################################################################
function ciCheckDpkgDernier()
{
    ACTION="$1"
    REFERENCE_FILE="$2"

    DPKG_DERNIER_FILE=${REFERENCE_FILE}.dernier

    TMPFILE=/tmp/dpkg.$$
    /bin/rm -f "$TMPFILE"
    echo "Liste des paquets EOLE"
    dpkg -l | awk '/^ii/ {print $2;}' | while read -r PQ
    do
        if [[ "$PQ" == linux-* ]]
        then
            # ignore le noyau
            continue
        fi
        if ciIsPaquetEole "$PQ";
        then
            echo "EOLE : $PQ"
            echo "$PQ" >>"$TMPFILE"
        fi
    done
    echo "Liste des paquets EOLE : fin"

    if [ ! -f "$REFERENCE_FILE" ]
    then
       ciPrintMsg "1ere fois que la commande est lancée. sauvegarde et pas d'erreur"
       ciPrintMsg "Le fichier de référence est $REFERENCE_FILE"
       /bin/cp "$TMPFILE" "$REFERENCE_FILE"
    else
       ciPrintMsg "Le fichier de référence est $REFERENCE_FILE"
       TMPREF=/tmp/dpkg_ref.$$
       # elimine linux
       grep -v 'linux-' "$REFERENCE_FILE" | awk '{print $1};' >"$TMPREF"
       ciDiff "$TMPFILE" "$TMPREF" >"$TMPFILE.diff"
       result="$?"
       if [ "$result" == "0" ]
       then
           ciPrintMsg "LES PAQUETS SONT OK"
       else
           DELTAFILE=/tmp/dpkg-delta.$$
           ciGrepDiff "$TMPFILE.diff" > "$DELTAFILE"
           cat "$DELTAFILE"
           ciPrintMsg "< nouveau par rapport au fichier de référence, > supprimé par rapport au fichier de référence, | changé par rapport au fichier de référence"
           if [[ "$VM_MAJAUTO" = "DEV" ]]
           then
               ciPrintMsgMachine "LES PAQUETS SONT DIFFERENTS, En MODE DEV ignore !"
           else
               #ciSignalAlerte "LES PAQUETS SONT DIFFERENTS"
               ciPrintMsgMachine "LES PAQUETS SONT DIFFERENTS, SAUVEGARDE SUITE MODIFICATION DE LA LISTE DES PKGS "
               /bin/cp "$TMPFILE" "$REFERENCE_FILE"
           fi

           RESULT="0"
           if [[ ! -f "$DPKG_DERNIER_FILE" ]]
           then
               RESULT="1"
           else
               ciDiff "$TMPFILE" "$DPKG_DERNIER_FILE" >/dev/null
               RESULT="$?"
           fi

           if [ "$RESULT" == "1" ]
           then
               ciPrintMsg "Sauvegarde nouveau dans : $DPKG_DERNIER_FILE"
               /bin/cp -f "$TMPFILE" "$DPKG_DERNIER_FILE"
           else
               ciPrintMsg "La derniere sauvegarde est dans : $DPKG_DERNIER_FILE"
           fi
           if [[ "$VM_MAJAUTO" = "DEV" ]]
           then
               ciPrintMsg "En mode DEV, actualise ${REFERENCE_FILE} !"
               /bin/cp -f "$DPKG_DERNIER_FILE" "${REFERENCE_FILE}"
           fi
       fi
    fi
    return 0
}

#########################################################################################################
#
# Check Dpkg
#
#########################################################################################################
function ciCheckDpkg()
{
    ACTION=$1

    ciPrintMsgMachine "check-dpkg $ACTION $FRESHINSTALL_ARCHITECTURE $VM_MODULE $VM_MACHINE"

    [[ ! -d "$VM_DIR_EOLE_CI_TEST/module/"           ]] && ciCreateDir "$VM_DIR_EOLE_CI_TEST/module"
    [[ ! -d "$VM_DIR_EOLE_CI_TEST/module/$VM_MODULE" ]] && ciCreateDir "$VM_DIR_EOLE_CI_TEST/module/$VM_MODULE"

    if [ -n "$FRESHINSTALL_ARCHITECTURE" ]
    then
        REFERENCE_FILE=$VM_DIR_EOLE_CI_TEST/module/$VM_MODULE/dpkg-$VM_MACHINE-$VM_VERSIONMAJEUR-$FRESHINSTALL_ARCHITECTURE
    else
        REFERENCE_FILE=$VM_DIR_EOLE_CI_TEST/module/$VM_MODULE/dpkg-$VM_MACHINE-$VM_VERSIONMAJEUR
    fi

    ciCheckDpkgDetail "$ACTION" "$REFERENCE_FILE"
    ciCheckDpkgDernier "$ACTION" "$REFERENCE_FILE"
    return 0
}
export -f ciCheckDpkg

ciCheckDpkg PAS_D_ERREUR_SI_DIFFERENT
# Attention : pas de test ici !
