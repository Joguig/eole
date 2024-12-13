#!/bin/bash
# shellcheck disable=SC2029

#***************************************************************
# /etc/one/oned.conf
#
#VM_HOOK = [
#    name    = "AppMarket_Vm_Shutdown",
#    on      = "SHUTDOWN",
#    command = "/var/lib/one/remotes/hooks/eole/appmarket_update.sh",
#    arguments = "VM_SHUTDOWN_HOOK $ID",
#    remote  = "YES"
#]
#
#IMAGE_HOOK = [
#    name    = "AppMarket_Image_Create",
#    on      = "CREATE",
#    command = "/var/lib/one/remotes/hooks/eole/appmarket_update.sh",
#    arguments = "IMAGE_CREATE_HOOK $ID",
#    remote  = "YES"
#]
#
#IMAGE_HOOK = [
#    name    = "AppMarket_Image_Remove",
#    on      = "REMOVE",
#    command = "/var/lib/one/remotes/hooks/eole/appmarket_update.sh",
#    arguments = "IMAGE_REMOVE_HOOK $ID",
#    remote  = "YES"
#]
#***************************************************************

#***************************************************************
#
# log: envoie tous les arguments dans le fichier de log du Hook 
#
#***************************************************************
function log()
{
    echo "$*" >>/var/log/one/appmarket_update.log
    echo "$*" 
}

#***************************************************************
#
# xpath : récupére le resultat de la requete Xpath
#
# arg1 : requete
# var "template" : contient le contenu xml
#
#***************************************************************
function xpath()
{
    echo "$template" | /var/lib/one/remotes/datastore/xpath.rb --stdin "$1"
}

#***************************************************************
#
# getProperty : récupére la propriete de l'export Key/Valeur
#
# arg1 : requete
# var "template" : contient le contenu xml
#
#***************************************************************
function getProperty()
{
    echo "$template" | grep "$1"
}

#***************************************************************
#
# installInMarket : install l'image dans le market
#
# arg1 : nom appliance
# arg2 : nom fichier json 
#
#***************************************************************
function copyImageDepuisTemp()
{
    #TODO : definir l'emplacement des images /var/local/one/images ! 
    cp "/tmp/${EOLE_APPMARKET_NAME}.bz2" /var/local/one/images
}

#***************************************************************
#
# createAppliance : cree une appliance dans le market pour l'image
#
#***************************************************************
function createAppliance()
{
    EOLE_APPMARKET_NAME=${1}
    log "installInMarket ${1}"
    
    template=$(cat "/tmp/${EOLE_APPMARKET_NAME}.vm_xml" )
    MEMORY=$(xpath MEMORY)
    ARCH=$(xpath OS/ARCH)
    MD5=$(cat "/tmp/${EOLE_APPMARKET_NAME}.md5" )
    SIZE=$(du -h "/tmp/${EOLE_APPMARKET_NAME}.bz2" | awk '{ print $1; }' )
    
    cat >"/tmp/${EOLE_APPMARKET_NAME}.json" <<- EOF
{
      "name": "$EOLE_APPMARKET_NAME",
      "short_description": "$EOLE_APPMARKET_NAME",
      "description": "$EOLE_APPMARKET_NAME Description\r\n",
      "version": "1.0",
      "hypervisor": "KVM",
      "format": "raw",
      "os-arch": "$ARCH",
      "opennebula_template": "{
          "CONTEXT": {
              "NETWORK": "YES",
              "SSH_PUBLIC_KEY": "\$USER[SSH_PUBLIC_KEY]"
          },
          "CPU": "1",
          "GRAPHICS": { "LISTEN": "0.0.0.0", "TYPE": "vnc" },
          "MEMORY": "$MEMORY",
          "OS": { "ARCH": "$ARCH" }
      }",
      "tags": [
        "eole",
        " t_tag2"
      ],
      "files": [
        {
          "url": "http://appmarket.eole.lan/download/$EOLE_APPMARKET_NAME.bz2",
          "md5": "$MD5",
          "size": "$SIZE",
          "compression": "bz2"
        }
      ]
    }
EOF

    cat "/tmp/$EOLE_APPMARKET_NAME.json"
    
    copyImageDepuisTemp 
    appmarket create "/tmp/$EOLE_APPMARKET_NAME.json"
    return $?
}

#***************************************************************
#
# updateAppliance : mets à jour une appliance dans le market
#
#***************************************************************
function updateAppliance()
{
    EOLE_APPMARKET_NAME=${1}
    
    # seul les MD5 et SIZE sont à mettre à jour !
    MD5=$(cat "/tmp/$EOLE_APPMARKET_NAME.md5" )
    SIZE=$(du -h "/tmp/$EOLE_APPMARKET_NAME.bz2" | awk '{ print $1; }' )

    cat >"/tmp/$EOLE_APPMARKET_NAME.json" <<- EOF
{ "files": [ { "md5": "$MD5", "size": "$SIZE" }] }
EOF

    cat "/tmp/$EOLE_APPMARKET_NAME.json"
    appmarket update "$ID_APPLIANCE" "/tmp/$EOLE_APPMARKET_NAME.json" 
    return $?
}

#***************************************************************
#
# installInMarket : install l'image dans le market
#
# arg1 : nom appliance
# arg2 : nom fichier json 
#
#***************************************************************
function installInMarket()
{
    EOLE_APPMARKET_NAME=${1}
    log "installInMarket ${1}"
    
    if [ ! -f "/tmp/$EOLE_APPMARKET_NAME.bz2" ]
    then
        log "  appliance ${1} : image bzip '/tmp/$EOLE_APPMARKET_NAME.bz2'  manquante"
        return 1
    fi

    if [ ! -f "/tmp/$EOLE_APPMARKET_NAME.md5" ]
    then
        log "  appliance ${1} : fichier Md5  '/tmp/$EOLE_APPMARKET_NAME.md5' manquant"
        return 1
    fi

    if [ ! -f "/tmp/$EOLE_APPMARKET_NAME.vm_template" ]
    then
        log "  appliance ${1} : fichier template '/tmp/$EOLE_APPMARKET_NAME.vm_template' de la VM manquant"
        return 1
    fi
    
    if [ ! -f "/tmp/$EOLE_APPMARKET_NAME.vm_xml" ]
    then
        log "  appliance ${1} : fichier template '/tmp/$EOLE_APPMARKET_NAME.vm_template' de la VM manquant"
        return 1
    fi
    
    template=$(cat "/tmp/$EOLE_APPMARKET_NAME.vm_xml" )
    MEMORY=$(xpath MEMORY)
    ARCH=$(xpath OS/ARCH)
    MD5=$(cat "/tmp/$EOLE_APPMARKET_NAME.md5" )
    SIZE=$(du -h "/tmp/$EOLE_APPMARKET_NAME.bz2" | awk '{ print $1; }' )
    
    ID_APPLIANCE=$(appmarket list | grep " $EOLE_APPMARKET_NAME " | awk '{ print $1; }')
    log "installInMarket ${1}"
    if [ -z "$ID_APPLIANCE" ]
    then
        log "  Nouvelle Appliance"
        createAppliance "$EOLE_APPMARKET_NAME"
        return $?
    else
        log "  ID_APPLIANCE : $ID_APPLIANCE"
        updateAppliance "$EOLE_APPMARKET_NAME"
        return $?
    fi
}

#***************************************************************
#
# hookShutdownVm : action suite à shutdown de la VM
#
# arg1 : id vm
#
#***************************************************************
function hookShutdownVm()
{
    ID=${1}
    template=$(onevm show "$ID" -x )
    EOLE_APPMARKET_NAME=$(xpath USER_TEMPLATE/EOLE_APPMARKET_NAME)
    if [ -z "$EOLE_APPMARKET_NAME" ]
    then
        log "hookShutdownVm $ID : pas de valeur EOLE_APPMARKET_NAME"
        return 0
    fi

    log "**************** hookShutdownVm *******************"
    log "$template"
    log "**************** Début"
    log "EOLE_APPMARKET_NAME : $EOLE_APPMARKET_NAME"
    log "ID : $ID"
    USER_NAME=$(xpath UNAME)
    log "USER_NAME : $USER_NAME"
    OWNER_USE_PERMISSION=$(xpath PERMISSIONS/OWNER_U)
    log "OWNER_USE_PERMISSION : $OWNER_USE_PERMISSION"
    ID_NEW_DISK=$(xpath TEMPLATE/DISK[0]/SAVE_AS)
    log "ID_NEW_DISK : $ID_NEW_DISK"
    FILE_IN_DATASTORE=$(xpath TEMPLATE/DISK[0]/SAVE_AS_SOURCE)
    log "FILE_IN_DATASTORE : $FILE_IN_DATASTORE"
    
    log "Zip image et transfert vers le Market"
    # bzip en local, transfert vers market, sauvegarde et calcul le md5 en une passe
    #bzip2 --stdout < $FILE_IN_DATASTORE | ssh root@appmarket.eole.lan "tee /tmp/$EOLE_APPMARKET_NAME.bz2 | md5sum - >/tmp/$EOLE_APPMARKET_NAME.md5"
    
    log "Envoi template vers le Market"
    onevm show "$ID"    | ssh root@appmarket.eole.lan "cat >/tmp/$EOLE_APPMARKET_NAME.vm_template"
    onevm show "$ID" -x | ssh root@appmarket.eole.lan "cat >/tmp/$EOLE_APPMARKET_NAME.vm_xml"
    
    log "Trampoline vers le Market et autocall ..."
    # trampoline ...
    CMD=$0
    scp "$CMD" "root@appmarket.eole.lan:/tmp/$EOLE_APPMARKET_NAME.install"
    ssh root@appmarket.eole.lan "bash -x /tmp/$EOLE_APPMARKET_NAME.install INSTALL_IN_MARKET '$EOLE_APPMARKET_NAME'"
    RESULT=$?
    
    log "**************** Fin : $RESULT"
    return $RESULT
}

#***************************************************************
#
# hookCreateImage : action suite à la création de l'image
# Attention : la création en BD se fait avant le fichier !
# arg1 : id image
#
#***************************************************************
function hookCreateImage()
{
    ID=${1}
    template=$(oneimage show "$ID" )
    USER_NAME=$(getProperty UNAME)
    SOURCE=$(getProperty SOURCE)
    log "hookCreateImage $ID $USER_NAME $SOURCE"
    log "$template"
}

#***************************************************************
#
# hookremoveImage : action suite à la suppression de l'image
# arg1 : id image
#
#***************************************************************
function hookRemoveImage()
{
    ID=${1}
    template=$(oneimage show "$ID" )
    log "hookremoveImage $ID"
    log "$template"
}

#***************************************************************
#
# main : point d'entrée
# arg1 : type du Hook [VM_HOOK | IMAGE_HOOK]
#***************************************************************
function main()
{
    case "${1}" in
        IMAGE_CREATE_HOOK)
            # cette commande doit etre lancée sur le serveur Sunstone
            hookCreateImage "${2}"
            return $?
            ;;

        IMAGE_REMOVE_HOOK)
            # cette commande doit etre lancée sur le serveur Sunstone
            hookRemoveImage "${2}"
            return $?
            ;;

        VM_SHUTDOWN_HOOK)
            # cette commande doit etre lancée sur le serveur Sunstone
            hookShutdownVm "${2}"
            return $?
            ;;

        INSTALL_IN_MARKET)
            # cette commande doit etre lancée sur le serveur Appmarket
            installInMarket "${2}"
            return $?
            ;;

        *)
            log "${1} inconnu !"
            return 1
            ;;
    esac
}

main "${1}" "${2}"
exit "$?"