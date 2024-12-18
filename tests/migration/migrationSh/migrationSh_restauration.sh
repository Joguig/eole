#!/bin/bash

ciGetEoleVersion
echo "VM_VERSION_EOLE=$VM_VERSION_EOLE"
VM_VERSION_EOLE_SANS_POINT="${VM_VERSION_EOLE//./}"
echo "VM_VERSION_EOLE_SANS_POINT=$VM_VERSION_EOLE_SANS_POINT"
SCRIPT="migration${VM_VERSION_EOLE_SANS_POINT}.sh"
echo "SCRIPT=$SCRIPT"

if [ -z "$1" ] 
then
    VERSIONMAJEUR_ORIGINE=$VM_VERSIONMAJEUR
else
    VERSIONMAJEUR_ORIGINE="$1"
fi

[ ! -d /mnt/sauvegardes ] && mkdir -p /mnt/sauvegardes

echo "Restauration depuis la sauvegarde $VERSIONMAJEUR_ORIGINE !"
VM_VERSIONMAJEUR=$VERSIONMAJEUR_ORIGINE ciGetDirSauvegarde
if [ ! -d "$DIR_SAUVEGARDE/migrationSh/" ]
then
    echo "* Restauration : la sauvegarde n'a pas été faite dans la version $VERSIONMAJEUR_ORIGINE !"
    exit 1    
fi

if [ -z "$2" ] 
then
    # shellcheck disable=SC2010
    FICHIER="$DIR_SAUVEGARDE/migrationSh/sauvegarde-${VM_VERSION_EOLE_SANS_POINT}.tar.gz" 
    echo "FICHIER=$FICHIER"
    BCK_BASENAME=$(basename "$FICHIER" .tar.gz)
else
    BCK_BASENAME="$2"
    FICHIER="$DIR_SAUVEGARDE/migrationSh/${BCK_BASENAME}.tar.gz"
fi
if [ ! -f "$FICHIER" ]
then
    echo "* Restauration : la sauvegarde n'a pas été faite dans la version $VERSIONMAJEUR_ORIGINE pour $VM_VERSION_EOLE_SANS_POINT !"
    exit 1    
fi
echo "Fichier sauvegarde utilisé : $FICHIER"
ls -l "$FICHIER"

tar xvf "$FICHIER" --directory /
RESULT="$?" 
if [ "$RESULT" -ne 0 ]
then
    echo "Restauration => $RESULT : le fichier '$FICHIER' n'est pas présent !"
    exit 1    
fi

ls -l /mnt/sauvegardes

EOLEAD="non"
if [ -f /mnt/sauvegardes/scribe-00000001/ca_ad.pem ];then
    EOLEAD="oui"
    ciSignalHack "Test Eole-AD : le le certificat Seth a changé !"
    VM_OUTPUT="$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER"
    /bin/cp -f "$VM_OUTPUT/seth1_ca.pem" /mnt/sauvegardes/scribe-00000001/ca_ad.pem
    ciCheckExitCode "$?"
fi

echo "************************************************************"
echo "* Restauration $BCK_BASENAME"
echo "************************************************************"
cd /root || exit 1
/bin/rm -f "$SCRIPT"
wget "ftp://eoleng.ac-dijon.fr/pub/Outils/migration/$SCRIPT"
ciCheckExitCode $?

#Attention ceci va détruire votre annuaire, voulez-vous continuer
#Chemin :
#Voulez-vous que les liens vers /home/adhomes soient générés automatiquement

# la presence de ce fichier ==> 
bash "$SCRIPT" <<EOF
oui
/mnt/sauvegardes
oui
EOF
ciCheckExitCode $?

echo "************************************************************"
echo "* Affichage des logs"
echo "************************************************************"
ciAfficheContenuFichier /tmp/aclserr.log

if [ "$VERSIONMAJEUR_ORIGINE" = "2.6.2" ]
then
    login='6b.01'
    echo "************************************************************"
    echo "* Vérification des répertoires"
    echo "************************************************************"
    home="/home/${login:0:1}/$login"
    adhome="/home/adhomes/$login"
    ls -ld "$home"
    if [ -L "$home" ]
    then
        ciPrintMsgMachine "$home est bien un lien"
    else
        ciSignalAlerte "$home n'est pas un lien symbolique"
    fi
    ls -ld "$adhome"
    if [ -d "$adhome" ] && [ ! -L "$adhome" ]
    then
        ciPrintMsgMachine "$adhome est bien un répertoire"
    else
        ciSignalAlerte "$adhome n'est pas un répertoire"
    fi
fi

echo "************************************************************"
echo "* vu que l'on a modifié plein de fichiers, il faut tester"
echo " creoled. et le redémarrer si besoin"
echo "************************************************************"
ciCheckCreoled

echo "************************************************************"
echo "* Migration configuration"
echo "************************************************************"
ciRunPython mise_a_jour_config_apres_migration.py
ciCheckExitCode $?

echo "******* Check Proxy ***********"
ciSetHttpProxy

ciMonitor instance
ciCheckExitCode $?

ciDiagnose
ciCheckExitCode $?

if ciVersionMajeurAPartirDe "2.7."
then
    USER="3a.01"
    
    if [[ "${VM_MODULE}" == "scribe" ]]
    then
        REALM=$(CreoleGet ad_domain)
        echo "* Vérification msDS-SupportedEncryptionTypes"
        if [[ "$EOLEAD" == "non" ]]
        then
            #. /etc/eole/samba4-vars.conf 
            #ldbsearch -H /var/lib/samba/private/sam.ldb -b "CN=Schema,CN=Configuration,$BASEDN" -s base objectVersion
            lxc-attach -n addc -- ldbsearch -H /var/lib/samba/private/sam.ldb '(objectclass=computer)' msDS-SupportedEncryptionTypes |grep -v 'ref:' |grep -v '^# ' |grep -v '^$'
        else
            kinit "Administrator@${REALM^^}" < <(echo "Eole12345!")
            ciCheckExitCode "$?" "kinit with password"
            kdestroy
        fi
    else
        # case Seth
        REALM=$(CreoleGet ad_realm )
    fi
    
    echo "* Vérification authentification AD après migration pour $USER"
    if echo "Eole54321!" | CreoleRun "kinit $USER@${REALM^^}" fichier
    then
        ciPrintMsgMachine "Authentification AD : OK"
    else
        ciSignalAlerte "Authentification AD : KO"
        kdestroy
    fi
    if ciVersionMajeurAPartirDe "2.8." && [[ -f /etc/ldap/slapd.conf ]]
    then
        entry=$(ldapsearch -x -D cn=reader,o=gouv,c=fr -w "$(cat /root/.reader)" uid="$USER" userPassword | grep ^userPassword)
        if [ "$(echo "$entry" | cut -d' ' -f 2 | base64 -d)" = "{SASL}$USER@$REALM" ]
        then
            ciPrintMsgMachine "Redirection SASL : OK"
        else
            ciSignalAlerte "Redirection SASL :KO"
            echo "$entry"
        fi
    fi
    echo "Vérification ACL après migration pour $USER"
    USERACL=$(getfacl /home/adhomes/$USER/perso 2>/dev/null)
    OKACL="# file: home/adhomes/$USER/perso
# owner: $USER
# group: root
user::rwx
user:$USER:rwx
group::---
group:professeurs:r-x
mask::rwx
other::---
default:user::rwx
default:user:$USER:rwx
default:group::---
default:group:professeurs:r-x
default:mask::rwx
default:other::---"
    if [ "$USERACL" == "$OKACL" ]
    then
        ciPrintMsgMachine "ACL : OK"
    else
       ciSignalAlerte "ACL : KO"
       echo "$USERACL"
    fi
fi

exit 0
