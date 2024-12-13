#!/bin/bash

######################################################
# Script de migration EOLE 2.6 et 2.7 vers EOLE 2.8  #
# Les donnees sont lues depuis un support externe    #
# Le script est utilisable pour :                    #
# - sauvegarder sur EOLE 2.6, 2.7                    #
# - restaurer sur EOLE 2.8                           #
######################################################

VERSION="20201116"
LDIF=eole.ldif
SYMPA=/var/lib/sympa
MYSQLDB=mysql.sql
ACLS=acls.sauv
QUOTAS=quotas.sauv
SID=sid.txt
READER=reader.txt
DD=/media/migration
RSYNC_LOG=/tmp/rsync.log
ACLS_LOG=/tmp/aclserr.log
ACLS_FIXED=/tmp/acls.txt
ACLS_DIR=/tmp/acls_blocks
UMOUNT_NEEDED=0

LOG_FILE="/tmp/migration-$(date +'%d%m%Y-%H%M%S').log"

if [ -f /usr/lib/eole/ihm.sh ];then
# version 2.4/2.5
. /usr/lib/eole/ihm.sh
numero_etab=$(CreoleGet numero_etab)
interactive='True'
else
# version 2.2 ou 2.3
. /usr/share/eole/FonctionsEoleNg
. /usr/bin/ParseDico
[ -f /etc/eole/containers.conf ] && . /etc/eole/containers.conf
fi

Green(){
  local msg="${@}"
  echo "[INFO] ${msg}" >> ${LOG_FILE}
  EchoVert "${msg}"
}

Red(){
  local msg="${@}"
  echo "[ERROR] ${msg}" >> ${LOG_FILE}
  EchoRouge "${msg}"
}

Cyan(){
  local msg="${@}"
  echo "[INFO] ${msg}" >> ${LOG_FILE}
  EchoCyan "${msg}"
}

Orange(){
  local msg="${@}"
  echo "[WARN] ${msg}" >> ${LOG_FILE}
  EchoOrange "${msg}"
}

StdEcho(){
  local msg="${@}"
  echo "[INFO] ${msg} | tee -a ${LOG_FILE}"
}

if [ -z "$numero_etab" ]
then
    Red "Récupération du numéro d'établissement impossible !"
    exit 1
fi

Version(){
    echo "Script de migration version : $VERSION"
    echo
}

Title(){
    echo
    Cyan "  * $1"
}

testcmd(){
    if [ "$1" -ne 0 ];then
        msg="$2"
        [ -z "$msg" ] && msg="Erreur, Abandon."
        Red "$msg"
        echo
        [ -z "$3" ] && exit 1
    fi
}

testf(){
    if [ ! -e $1 ];    then
        Red "$1 introuvable, Abandon."
        echo
        exit 1
    fi
}

Alerte(){
    echo
    Question_ouinon "Attention ceci va détruire votre annuaire, voulez-vous continuer ?" $interactive "non" "warn"
    testcmd $? "Abandon"
}

Alerte2(){
    echo
    Question_ouinon "Attention ceci va écraser certaines données de votre serveur, voulez-vous continuer ?" $interactive "non" "warn"
    testcmd $? "Abandon"
}

montage(){
    # $1 : point de montage
    # $2 : version (exemple 25)
    /bin/mkdir -p "$1"
    /bin/umount "$1" 2>/dev/null
    echo
    echo "Quel est le support de sauvegarde ?"
    echo "* support distant  => ex : //machine/partage"
    echo "* disque USB       => ex : /dev/sd.."
    echo "* répertoire local => ex : /root/sauvegarde"
    echo
    read -p "Chemin : " peri
    if [ "${peri:0:2}" = "//" ]
    then
        echo -n "Entrez un nom d'utilisateur (sinon rien) : "
        read user
        echo Montage de $peri
        [ "$2" = "25" ] && fs="cifs" || fs="smbfs"
        [ "$user" != "" ] && mount -t $fs $peri "$1" -o username=$user,iocharset=utf8 || mount -t $fs $peri "$1" -o password='',iocharset=utf8
        testcmd $? "Montage $peri impossible, Abandon."
        UMOUNT_NEEDED=1
    elif [ "${peri:0:4}" = "/dev" ]
    then
        echo Disque local
        echo Montage de $peri
        /bin/mount $peri "$1"
        testcmd $? "Montage $peri impossible, Abandon."
        UMOUNT_NEEDED=1
    elif [ "${peri:0:1}" = "/" ]
    then
        testf $peri
        [ -L "$1" ] && rm -f "$1"
        if [ -d "$1" ];then
            rmdir "$1"
            testcmd $?
        fi
        ln -ns $peri "$1"
        UMOUNT_NEEDED=0
    else
        testcmd 1 "Le chemin doit être complet !"
    fi
}

demontage(){
    # $1 : point de montage
    if [ $UMOUNT_NEEDED -eq 1 ]
    then
        Title "Démontage du support"
        /bin/umount "$1"
        echo
    fi
    [ -L "$1" ] && rm -f "$1"
}

saveconfigeol(){
    # $1 : répertoire de sauvegarde
    Title "Test du support"
    /bin/mkdir -p "$1"
    testcmd $? "Ecriture impossible sur le support !"
    ln -s /tmp "$1/testln"
    if [ $? -ne 0 ];then
        Red "Le support ne supporte pas les liens symboliques !"
        Question "Voulez-vous continuer malgré tout ?"
        testcmd $? "Abandon"
    fi
    rm -f "$1/testln"
    Title "Copie du fichier config.eol"
    /bin/cp -f /etc/eole/config.eol "$1/$version.eol"
    testf "$1/$version.eol"
    if [ -d /etc/eole/extra ];then
        /bin/cp -rf /etc/eole/extra "$1/"
    fi
}

questionsave(){
    # $1 : emplacement des données (/home ou /data)
    echo
    Question "Voulez-vous sauvegarder automatiquement les données ?"
    if [ $? -ne 0 ];then
        Orange "La migration des données contenues dans $1 ne sera pas automatique !"
        return 1
    fi
    return 0
}

questionrestore(){
    # $1 : répertoire de sauvegarde
    # $2 : emplacement des données (/home ou /data)
    echo
    if [ ! -d "$1$2" ];then
        Orange "Les données de $2 ne sont pas présentes dans la sauvegarde"
        Question_ouinon "Voulez-vous restaurer les ACL malgré tout ?" "$interactive" "oui"
        return $?
    fi
    return 0
}

savebcdi(){
    # $1 : répertoire de sauvegarde
    if [ -d /home/bcdiserv ];then
        Question "Voulez-vous sauvegarder les fichiers liés à Bcdi Web ?"
        if [ $? -eq 0 ];then
            Title "Sauvegarde de Bcdi Web"
            mkdir -p "$1/bcdi"
            cp -R /home/bcdiserv "$1/home/"
            cp -R /var/www/html/bcdiweb "$1/bcdi/"
            cp -f /etc/apache2/sites-enabled/bcdiweb.conf "$1/bcdi/"
            cp -f /etc/default/rsync "$1/bcdi/"
            cp -f /etc/rsyncd.conf "$1/bcdi/"
            echo
        fi
    fi
}

restorebcdi(){
    # $1 : répertoire de sauvegarde
    if [ -d "$1/home/bcdiserv" ];then
        echo "Restauration des données liées à Bcdi Web"
        # /home/bcdiserv est restauré par restorescribedata()
        if [ -d "$1/bcdi/bcdiweb" ];then
            cp -R "$1/bcdi/bcdiweb" /var/www/html/bcdiweb
            chown -R www-data:www-data /var/www/html/bcdiweb
        fi
        cp -f "$1/bcdi/bcdiweb.conf" /etc/apache2/sites-enabled
        cp -f "$1/bcdi/rsync" /etc/default/rsync
        cp -f "$1/bcdi/rsyncd.conf" /etc/rsyncd.conf
        echo
    fi
}

savescribedata(){
    # $1 : répertoire de sauvegarde
    mkdir -p "$1/home"
    savebcdi "$1"
    Title "Copie des données"
    echo -n "."
    # ménage
    rm -f /home/netlogon/*.bat
    rm -f /home/netlogon/*.txt
    mkdir -p /home/options
    # FIXME : supprimer tous les .virus et .scanned avant ?
    for rep in "netlogon" "workgroups" "classes" "options";do
        echo -n "."
        cp --preserve=timestamps -rf /home/$rep "$1/home"
    done
    if [ -d /home/wpkg ];then
        echo -n "."
        mkdir -p "$1/home/wpkg"
        cp --preserve=timestamps -rf /home/wpkg/* "$1/home/wpkg"
        rm -rf "$1/home/wpkg/documents"
        rm -f  "$1/home/wpkg/wpkg.js"
    fi
    for abc in `find /home -maxdepth 2 -wholename '/home/?/*' | sort`;do
        echo -n "."
        rsync -cav --log-file $RSYNC_LOG --exclude=MailDir \
            --exclude=IntegrDom --exclude=.scanned* $(realpath ${abc}) "$1/${abc%/*}" >/dev/null
        testcmd $? "Erreur lors de la sauvegarde des données $abc : consulter le fichier $RSYNC_LOG" 'noexit'
    done
    # scribe (controle-vnc-applis)
    rm -rf "$1/home/netlogon/blockinput"
    rm -f "$1/home/a/admin/perso/Alias.lnk"
    rm -f "$1/home/a/admin/perso/alias"
    rm -f "$1/home/a/admin/perso/Esu.lnk"
    rm -f "$1/home/a/admin/perso/Install_Client_Scribe.lnk"
    rm -rf "$1/home/workgroups/professeurs/gestion-postes"
    rm -f "$1/home/workgroups/professeurs/Gestion-postes.lnk"
    echo
    # scribe (controle-vnc-client)
    # scribe (divers)
    # les corbeilles ($smb_trash_dir)
    # horus ?
}

savehorusdata(){
    # $1 : répertoire de sauvegarde
    Title "Copie des données"
    echo "(cette opération peut prendre du temps)"
    echo -n "."
    # purge des fichiers de connexion
    rm -f /home/netlogon/*.bat
    # FIXME : on devrait supprimer tous les .virus et .scanned avant
    echo -n "."
    if [ -L /data ];then
        # spécifique Horus-2.3
        mkdir -p "$1/data/home"
        for dir in `find /home/* -maxdepth 0 -type d`;do
            if [ $dir != "/home/workgroups" ];then
                cp -rf --preserve=timestamps $dir "$1/data/home"
                echo -n "."
            fi
        done
        cp -rf /home/workgroups/* "$1/data"
    else
        # spécifique Horus-2.2
        cp -rf --preserve=timestamps /data "$1/"
    fi
    # suppression des fichiers spéciaux
    echo -n "."
    rm -f "$1/data/aquota.group"
    rm -f "$1/data/aquota.user"
    rm -rf "$1/data/home/horus"
    rm -rf "$1/data/home/ftp"
    echo -n "."
    for prof in `find "$1/data/home" -maxdepth 2 -name "profiles"`;do
        ls $prof/* &>/dev/null
        if [ $? -ne 0 ];then
            # suppression des répertoires vides
            rmdir $prof
        elif [ ! -d `dirname $prof`/profil ];then
            # renommage profiles -> profil
            mv "$prof" "`dirname $prof`/profil"
        fi
    done
    echo -n "."
    if [ ! -L /opt ];then
        # spécifique Horus-2.3
        cp -rf --preserve=timestamps /opt "$1/data"
    fi
    echo
}

restorescribedata(){
    # $1 : répertoire de sauvegarde
    Title "Restauration des données"
    if [ ! -d "$1/home" ];then
        echo "Aucune donnée à restaurer"
        return
    fi
    echo "(cette opération peut prendre du temps)"
    restorebcdi "$1"
    rsync -cav --log-file $RSYNC_LOG --ignore-existing "$1/home/" /home/ >/dev/null
    testcmd $? "Erreur lors de la restauration des données, consulter le fichier $RSYNC_LOG"
    [ -f "$1/home/wpkg/hosts.xml" ] && cp -f "$1/home/wpkg/hosts.xml" /home/wpkg/
    # liens morts (#30782)
    for link in "/home/a/admin/perso/esu" "/home/a/admin/perso/client"
    do
        [ -L "$link" ] && [ ! -e "$link" ] && rm -f "$link"
    done
}

genadhome(){
    Title "Génération des liens vers /home/adhomes"
    for dir in /home/?/*;do
        /usr/share/eole/sbin/create_adhome "$(basename $dir)" "/home/adhomes"
    done
}

savequota(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegardes des quotas utilisateurs"
    /usr/sbin/repquota -a |grep -v '^#' > "$1/$QUOTAS"
}

restorequota(){
    # $1 : répertoire de sauvegarde
    Title "Restauration des quotas utilisateurs"
    testf "$1/$QUOTAS"
    python3 -c """from fichier.quota import set_quota
from sys import stdout
with open('$1/$QUOTAS', 'r') as fp:
    started = False
    num = 0
    for ligne in fp.readlines():
        if not started:
            if ligne.startswith('------------'):started = True
            continue
        # cas plusieurs partition
        if ligne.startswith('***'):
            started = False
            continue
        elts = ligne.strip().split()
        try:
            user  = elts[0]
            quota = elts[3]
        except:
            continue
        if quota != '0':
            num+=1
            if num % 20 == 0:
                stdout.write('.')
                stdout.flush()
            set_quota(user, int(quota)/1024)
print(\"\\n%d quotas non nuls restaurés\" % num)
"""
}

savescribeacl(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde des ACL"
    > "$1/$ACLS"
    for rep in "netlogon" "workgroups" "classes" "options";do
        echo -n "."
        /usr/bin/getfacl -R --absolute-names /home/$rep >> "$1/$ACLS"
    done
    for abc in `find /home -maxdepth 1 -name '?' | sort`
    do
        echo -n "."
        /usr/bin/getfacl -R --absolute-names $abc >> "$1/$ACLS"
    done
    echo
}

savehorusacl(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde des ACL"
    if [ -L /data ];then
        HOME="/home"
    else
        HOME="/data"
    fi
    /usr/bin/getfacl -R --absolute-names $HOME > "$1/$ACLS"
}

restoreacl(){
    # $1 : répertoire de sauvegarde
    Title "Restauration des ACL"
    if [ ! -f "$1/$ACLS" ];then
        echo
        Orange "Les ACL ne sont pas présentes dans la sauvegarde"
        return
    else
        sed -i -e "s;\(/home/workgroups/professeurs/gestion-postes/wx\(base\)\|\(msw\)\)28uh\(.*\?\)\(.dll\);\130u\490\5;g" "$1/$ACLS"
    fi
    [ -d /data ] && ln -nsf /home /data/home
    # Remplacement des anciens groupes "DomainAdmins" et "DomainUsers"
    sed "s/:DomainAdmins:/:10512:/ ; s/:DomainUsers:/:10513:/" "$1/$ACLS" > "$ACLS_FIXED"
    rm -f $ACLS_LOG
    [ -d "$ACLS_DIR" ] && rm -rf "$ACLS_DIR"
    mkdir "$ACLS_DIR"
    awk -v acl_dir=$ACLS_DIR -v RS= '{print > sprintf("%s/acl_block-%.10d.txt",acl_dir, NR)}' "$ACLS_FIXED"
    for acl_block in $ACLS_DIR/acl_block-*.txt
    do
        /usr/bin/setfacl --restore="$acl_block" 2>&1 |grep -Ev "MailDir|data/opt|aquota|horus|recyclage|netlogon|Alias\.lnk|\.scanned|profiles|/home/ftp|gestion-postes|IntegrDom|.lnk:" >>$ACLS_LOG
    done
    [ -L /data/home ] && rm -f /data/home
    ERR=`wc -l $ACLS_LOG|cut -d' ' -f1`
    if [ $ERR -gt 0 ];then
        Orange "ATTENTION : $ERR messages d'erreur dans $ACLS_LOG"
        for block in $(sed -e "s/^setfacl.*\?: \(.*\).:.* \([0-9]\+\)$/\1,\2/" -e "/setfacl/d" $ACLS_LOG)
        do
            sed -n "${block##*,}p" "${block%%,*}" | sed -e "s/\([^:]*\):\([^:]*\):.*/ACL non restaurée pour \1 \2/" >> /tmp/aclserr_parsed.log
        done
    fi
    if [ -e /tmp/aclserr_parsed.log ]
    then
        sort -u /tmp/aclserr_parsed.log > /tmp/aclserr_uniq.log
        rm -f /tmp/aclserr_parsed.log
        Red "$(head -n10 /tmp/aclserr_uniq.log)"
        echo
        Red "Consulter le fichier /tmp/aclserr_uniq.log pour la liste des comptes non retrouvés"
        echo "Corriger le fichier le fichier $1/$ACLS avant de relancer la procédure"
        echo
        exit 1
    fi
}

savemail(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde des données liées à la messagerie"
    [ -x /usr/bin/CreoleGet ] && container_path_mail=$(CreoleGet container_path_mail)
    mkdir -p "$1/listes"
    echo -n "."
    if [ ! -e "$1/listes/sympa" ];then
        mkdir -p "$1/listes/sympa"
    fi
    if [ -f "$container_path_mail/etc/mail/sympa.aliases" ];then
        cp "$container_path_mail/etc/mail/sympa.aliases" "$1/listes/sympa/aliases"
    elif [ -f "$container_path_mail/etc/mail/sympa_aliases" ];then
        cp "$container_path_mail/etc/mail/sympa_aliases" "$1/listes/sympa/aliases"
    else
        cp "$container_path_mail/etc/mail/sympa/aliases" "$1/listes/sympa/aliases"
    fi
    cp -R $container_path_mail/$SYMPA/expl "$1/listes"
    echo -n "."
    cp -R $container_path_mail/$SYMPA/wwsarchive "$1/listes"
    mkdir -p "$1/courier"
    echo -n "."
    cp -f $container_path_mail/etc/courier/pop3d.* $container_path_mail/etc/courier/imapd.* "$1/courier"
    mkdir -p "$1/mail"
    echo -n "."
    for maildir in `find /home -maxdepth 3 -name MailDir`;do
        # 2.2 : mails dans /home/<l>/<login>/MailDir
        if [ -d "$maildir/cur" ];then
            user=`echo $maildir | awk -F "/" '{ print $(NF-1) }'`
            mkdir -p "$1/mail/$user"
            rsync -cav --log-file $RSYNC_LOG $maildir/ "$1/mail/$user" >/dev/null
        fi
    done
    if [ "$(ls -A /var/spool/mail)" ];then
        # 2.2 : mails responsables dans /var/spool/mail
        echo -n "."
        rsync -cav --log-file $RSYNC_LOG /var/spool/mail/* "$1/mail" >/dev/null
    fi
    if [ -d /home/mail ];then
        # 2.3/2.4 : toutes les boîtes dans /home/mail
        echo -n "."
        rsync -cav --log-file $RSYNC_LOG /home/mail/* "$1/mail" >/dev/null
    fi
    echo
}

restoremail(){
    # $1 : répertoire de sauvegarde
    Title "Restauration des données liées à la messagerie"
    container_path_mail=$(CreoleGet container_path_mail)
    # sympa_aliases => sympa.aliases => sympa/aliases (#5049 puis #17087)
    if [ ! -e "$container_path_mail/etc/mail/sympa/aliases" ];then
        mkdir -p "$container_path_mail/etc/mail/sympa/aliases"
    fi
    cp "$1/listes/sympa/aliases" "$container_path_mail/etc/mail/sympa/aliases"
    echo -n "."
    rsync --log-file $RSYNC_LOG --ignore-existing -cav "$1/listes/expl" "$container_path_mail/$SYMPA" >/dev/null
    echo -n "."
    rsync --log-file $RSYNC_LOG --ignore-existing -cav "$1/listes/wwsarchive" "$container_path_mail/$SYMPA" >/dev/null
    echo -n "."
    CreoleRun "chown -R sympa:sympa $SYMPA" mail
    echo -n "."
    # restauration des certificats SSL pour pop et imap
    cp -f "$1"/courier/*.* "$container_path_mail/etc/courier"
    echo -n "."
    rsync --log-file $RSYNC_LOG -cav "$1/mail" /home/ >/dev/null
    echo -n "."
    CreoleRun "chown -R mail:mail /home/mail" mail
    echo -n "."
    # re-génération des listes de diffusion (pour les responsables)
    python3 -c """from scribe.eolegroup import Group
g = Group()
g.ldap_admin.connect()
for classe in g._get_groups('Classe'):
    domain = g._get_maillist(classe).split('@')[1]
    g._delete_maillist(classe, domain)
    g._delete_maillist('profs-%s' % classe, domain)
    g._delete_maillist('resp-%s' % classe, domain)
    g._add_maillist('Classe', classe)
    g._add_maillist('Equipe', 'profs-%s' % classe)
    g._add_resp_maillist(classe)
g.ldap_admin.close()
"""
    echo -n "."
    # vérification de l'adresse IP du serveur ldap
    SEARCHPATH="$container_path_mail/$SYMPA/expl"
    adresse_ip_mysql=$(CreoleGet adresse_ip_mysql)
    for config in `grep -l "host localhost" $SEARCHPATH/*/config $SEARCHPATH/*/*/config 2>/dev/null`;do
        sed -i "s/^host localhost$/host $adresse_ip_mysql/g" $config
    done
    echo
    # re-génération des alias pour sympa
    /usr/share/eole/backend/regenalias.sh
}

saveldap(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde de l'annuaire"
    [ -x /usr/bin/CreoleGet ] && container_path_annuaire=$(CreoleGet container_path_annuaire)
    [ -f /root/.reader ] && cp -f /root/.reader "$1/$READER"
    [ -x /usr/bin/CreoleService ] && CreoleService slapd stop || /etc/init.d/slapd stop
    chroot "/$container_path_annuaire" /usr/sbin/slapcat -f /etc/ldap/slapd.conf| grep -Ev "^sambaShareAdmin:|^sambaShareDep:|^location:|^server:|^sambaLogonScript:" > "$1/$LDIF"
    testcmd $?
    [ -x /usr/bin/CreoleService ] && CreoleService slapd start || /etc/init.d/slapd start
}

restoreldap(){
    # $1 : répertoire de sauvegarde
    Title "Restauration de l'annuaire"
    # Recherche de l'ancienne objectClass "sambaServer" (#3730)
    dn=$(grep "ou=ordinateurs,ou=ressource" "$1/$LDIF" | grep "dn: cn" | grep -v '\$')
    if [ -n "$dn" ];then
        Red "L'entrée ldap débutant par \"$dn\" est obsolète."
        echo "Veuillez la supprimer du fichier : $LDIF"
        echo
        exit 1
    fi
    # Recherche des chemins commençant par /partages (#5686)
    grep -q "^sambaFilePath: \/partages\/" "$1/$LDIF"
    if [ $? -eq 0 ];then
        Red "Des attributs \"sambaFilePath\" débutent par \"/partages\""
        echo "Les occurences de \"/partages\" doivent être remplacées par \"/home\" dans le fichier : $LDIF"
        echo
        exit 1
    fi
    [ -f "$1/$READER" ] && cp -f "$1/$READER" /root/.reader
    # code inspiré de posttemplate/02-annuaire
    container_path_annuaire=$(CreoleGet container_path_annuaire)
    CHROOT=''
    [ ! "$container_path_annuaire" = "" ] && CHROOT="chroot $container_path_annuaire"
    # le montage n'est pas accessible depuis le conteneur :)
    CreoleService slapd stop -c annuaire
    rm -f $container_path_annuaire/var/lib/ldap/*.*
    cp -f "$1/$LDIF" "$container_path_annuaire/tmp/$LDIF"
    $CHROOT slapadd -f /etc/ldap/slapd.conf -l "/tmp/$LDIF"
    testcmd $? "Erreur lors de la restauration de l'annuaire !"
    CreoleRun "chown openldap:openldap /var/lib/ldap/*" annuaire
    rm -f "$container_path_annuaire/tmp/$LDIF"
    CreoleService slapd start -c annuaire
    testcmd $? "Erreur lors du redémarrage d'OpenLDAP !"
}

saveldap2scribe(){
    # $1 : répertoire de sauvegarde
    Title "Mise à niveau de l'annuaire"
    python -c """ldif = '$1/$LDIF'
with open(ldif, 'r') as ldif_buffer:
    fic = ldif_buffer.readlines()
new = []
for line in fic:
    if line.startswith('mailDir: ') and '/MailDir/' in line:
        new.append('mailDir: /home/mail/%s/' % line.split('/')[3])
    else:
        new.append(line)
if new != fic:
    with open(ldif, 'w') as ldif_buffer:
        ldif_buffer.write(''.join(new))
"""
}

restoreldap2scribe(){
    # $1 : répertoire de sauvegarde
    Title "Mise à niveau de l'annuaire"
    python3 -c """from scribe.eoleshare import Share
s = Share()
s.ldap_admin.connect()
sh = s._get_shares_data()
for sha in sh:
    if not 'sambaShareModel' in sha[1]:
        name = sha[1]['sambaShareName'][0]
        if name in ['icones\$', 'groupes', 'commun', 'devoirs']:
            s._set_attr(name, 'sambaShareModel', name)
        else:
            s._set_attr(name, 'sambaShareModel', 'standard')
s.ldap_admin.close()
"""
}

saveldap2horus(){
    # $1 : répertoire de sauvegarde
    Title "Mise à niveau de l'annuaire"
    sed -i 's/\\profiles$/\\profil/g' "$1/$LDIF"
}

restoreldap2horus(){
    # $1 : répertoire de sauvegarde
    Title "Mise à niveau de l'annuaire"
    python3 -c """from horus.backend import get_share_template, mod_share
if get_share_template('minedu') == 'standard':
    mod_share('minedu', model='minedu')
if get_share_template('groupes') == 'standard':
    mod_share('groupes', model='groupes')
"""
}

usersync(){
    Title "Synchronisation des comptes AD"
    keytool -delete -alias eole-ad -keystore /etc/ssl/certs/java/cacerts -storepass changeit >/dev/null
    keytool -import -trustcacerts -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt -alias eole-ad -file /etc/ssl/certs/ca_local.crt
    lsc -f /etc/lsc -s all -t1 | grep -E "INFO|ERROR"
    service eole-lsc start
    Title "Nettoyage du cache winbind"
    /usr/share/eole/postservice/05-eolead-join-and-sync-ldap
    /usr/bin/actualise_cache
    Title "Restauration des mots de passe"
    /usr/share/eole/postservice/10-eolead-inject-password instance force
}

savesmb(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde des données liées à SAMBA et à CUPS"
    [ -x /usr/bin/CreoleGet ] && container_path_fichier=$(CreoleGet container_path_fichier)
    mkdir -p "$1/cups"
    if [ -d "$container_path_fichier/etc/cups" ]
    then
        cp -f $container_path_fichier/etc/cups/printers.conf "$1/cups" 2>/dev/null
        cp -f $container_path_fichier/etc/cups/ppds.dat "$1/cups" 2>/dev/null
        if [ -d "$container_path_fichier/etc/cups/ppd" ]
        then
            cp -rf $container_path_fichier/etc/cups/ppd "$1/cups"
        fi
    fi
    mkdir -p "$1/samba"
    #if [ -f $container_path_fichier/var/lib/samba/secrets.tdb ];then
    #    cp -f $container_path_fichier/var/lib/samba/secrets.tdb "$1/samba"
    #elif [ -f $container_path_fichier/var/lib/samba/private/secrets.tdb ];then
    #    cp -f $container_path_fichier/var/lib/samba/private/secrets.tdb "$1/samba"
    #else
    #    cp -f $container_path_fichier/etc/samba/secrets.tdb  "$1/samba" 2>/dev/null
    #fi
    cp -rf $container_path_fichier/var/lib/samba/printers "$1/samba"
    for f in "ntdrivers.tdb" "ntforms.tdb" "ntprinters.tdb";do
    cp -f "$container_path_fichier/var/lib/samba/$f" "$1/samba" 2>/dev/null
    done
    if [ -f /var/lib/eole/config/sid.sav ];then
        cp /var/lib/eole/config/sid.sav "$1/samba/$SID"
    else
        chroot "/$container_path_fichier" net getlocalsid | /usr/bin/awk '{print $6}' > "$1/samba/$SID"
    fi
}

restoresmb(){
    # $1 : répertoire de sauvegarde
    Title "Restauration des données liées à SAMBA et à CUPS"
    container_path_fichier=$(CreoleGet container_path_fichier)
    cp -f  "$1"/cups/printers.conf "$container_path_fichier/etc/cups/printers.conf" 2>/dev/null
    cp -f  "$1"/cups/ppds.dat "$container_path_fichier/etc/cups/ppds.dat" 2>/dev/null
    cp -rf "$1"/cups/ppd/* "$container_path_fichier/etc/cups/ppd/" 2>/dev/null
    cp -rf "$1"/samba/printers/* "$container_path_fichier/var/lib/samba/printers/" 2>/dev/null
    for f in "ntdrivers.tdb" "ntforms.tdb" "ntprinters.tdb";do
    cp -f "$1/samba/$f" "$container_path_fichier/var/lib/samba/$f" 2>/dev/null
    done
    NEWSID=`cat $1/samba/$SID`
    # overwrites new (ramdom) SID #25756
    cp -f $1/samba/$SID /var/lib/eole/config/sid.sav
    CHROOT=''
    [ ! "$container_path_fichier" = "" ] && CHROOT="chroot $container_path_fichier"
    $CHROOT net setlocalsid $NEWSID
    testcmd $? "Impossible de restaurer le SID du domaine"
}

savescribemysql(){
    # $1 : répertoire de sauvegarde
    # $2 : version (22 ou 23)
    Title "Sauvegarde des bases Mysql"
    if [ -x /usr/bin/CreoleGet ];then
        container_path_mysql=$(CreoleGet container_path_mysql)
        container_ip_mysql=$(CreoleGet container_ip_mysql)
    fi
    mkdir -p "$1/mysql"
    cp $container_path_mysql/etc/mysql/debian.cnf $1/mysql

    if [ $EOLE_VERSION = '2.6' ];then
        mysqlopts="--defaults-file=/etc/mysql/debian.cnf"
    else
        PASS=`/usr/bin/pwgen -1`
        if [ "$2"  = "24" ];then
            /usr/share/eole/sbin/mysql_pwd.py "$PASS" nomodif >/dev/null
        else
            /usr/share/eole/mysql_pwd.py "$PASS" nomodif >/dev/null
        fi
        if [ -n "$container_ip_mysql" ]
        then
            mysqlhost=""
            if [ "${container_ip_mysql}" = "127.0.0.1" ]
            then
                mysqlhost="-h localhost"
            else
                mysqlhost="-h $container_ip_mysql"
            fi
        fi
        mysqlopts="$mysqlhost -uroot -p$PASS"
    fi
    [ "$2"  != "22" ] && opt="--events" || opt=""
    [ $EOLE_VERSION = '2.6' ] && opt="$opt --single-transaction"
    [ "$2"  = "24" ]  && optdb="--databases" || optdb="--database"
    DATABASES=$(CreoleRun "mysql $mysqlopts -e \"show databases\"" "mysql" | grep -v "^Database$")
    for databasename in $DATABASES;do
        [ "$databasename" = "information_schema" ] && continue
        [ "$2"  = "24" ] && [ "$databasename" = "performance_schema" ] && continue
        echo -n "."
        CreoleRun "mysqldump $mysqlopts $optdb $databasename --flush-privileges --create-options -Q -c --lock-tables $opt" "mysql" > "$1/mysql/$databasename.sql"
        testcmd $? "Erreur lors de la sauvegarde de la base $databasename !"
    done
    echo
}

savehorusmysql(){
    # $1 : répertoire de sauvegarde
    # $2 : version (22 ou 23)
    Title "Sauvegarde des bases Mysql"
    mkdir -p "$1/mysql"
    cp /etc/mysql/debian.cnf "$1/mysql"
    PASS=`/usr/bin/pwgen -1`
    if [ "$2"  = "24" ];then
        /usr/share/eole/sbin/mysql_pwd.py "$PASS" nomodif >/dev/null
    else
        /usr/share/eole/mysql_pwd.py "$PASS" nomodif >/dev/null
    fi
    [ "$2"  != "22" ] && opt="--events" || opt=""
    if [ "$2"  = "24" ];then
        all="--all-databases"
    else
        all="--all-database"
    fi
    mysqldump $all -uroot -p$PASS $opt > "$1/mysql/$MYSQLDB"
}

restorescribemysql(){
    # $1 : répertoire de sauvegarde
    Title "Restauration des bases Mysql"
    #testf $1/mysql/mysql.sql
    #PASS=`/usr/bin/pwgen -1`
    #/usr/share/eole/sbin/mysql_pwd.py "$PASS" nomodif >/dev/null
    # FIXME : intérêt de restaurer la bdd mysql sur Scribe ?
    #echo -n "."
    #cp -f $1/mysql/debian.cnf /etc/mysql/debian.cnf
    #/usr/share/eole/mysql_pwd.py "$PASS" nomodif >/dev/null
    #adresse_ip_mysql=$(CreoleGet adresse_ip_mysql)
    for database in 'sympa';do
        echo -n "."
        testf "$1/mysql/$database.sql"
        mysql --defaults-file=/etc/mysql/debian.cnf <"$1/mysql/$database.sql"
    done
    echo -n "."
    # mysql_upgrade n'est pas disponible sur le maître (fourni par mysql-server)
    CreoleRun "mysql_upgrade --defaults-file=/etc/mysql/debian.cnf --force" mysql >/dev/null
    echo
}

savebacula22(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde de la configuration bacula"
    mkdir -p "$1/bacula"
    #cp -f /etc/bacula/typesupport.conf $1/bacula 2>/dev/null
    /usr/share/eole/bacula/baculasupport.py -l >"$1/bacula/support.conf"
    #cp -f /etc/bacula/eolemsgdefs.pic  $1/bacula 2>/dev/null
    #cp -f /etc/bacula/eolemessages.conf $1/bacula 2>/dev/null
    /usr/share/eole/bacula/baculamessage.py -l >"$1/bacula/mail.conf"
    cp -f /etc/bacula/listefichiers*.conf "$1/bacula"
    # chemins Scribe
    cp -f /var/www/ead/config/bacula-distant.txt "$1/bacula" 2>/dev/null
    cp -f /var/www/ead/config/bacula-usb.txt "$1/bacula" 2>/dev/null
    # chemins Horus
    cp -f /var/www/ead/tmp/bacula-distant.txt "$1/bacula" 2>/dev/null
    cp -f /var/www/ead/tmp/bacula-usb.txt "$1/bacula" 2>/dev/null
}

savebacula23(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde de la configuration bacula"
    mkdir -p "$1/bacula"
    # EOLE 2.3
    python -c """from pyeole.bacula import load_bacula_support;
for k,v in load_bacula_support().items():print '{0}=\"{1}\"'.format(k,v)""" > $1/bacula/bacula23.conf
    python -c """from pyeole.bacula import load_bacula_mail;mail=load_bacula_mail();
if mail:
    for k,v in mail.items():print '{0}=\"{1}\"'.format(k,v)""" >> $1/bacula/bacula23.conf
    if [ -f /var/lib/eole/config/baculajobs.conf ];then
        cp -f /var/lib/eole/config/baculajobs.conf $1/bacula/baculajobs.conf
    fi
}

savebacula24(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde de la configuration bacula"
    if [ -f $1/extra/bacula/config.eol ];then
        [ -d $1/extra/bareos ] && rm -rf $1/extra/bareos
        mv -f $1/extra/bacula $1/extra/bareos
        sed -i 's/bacula/bareos/g' $1/extra/bareos/config.eol
    fi
}

restorebacula(){
    # $1 : répertoire de sauvegarde
    Title "Restauration de la configuration des sauvegardes"
    if [ -f $1/extra/bareos/config.eol ];then
        # configuration "extra" en 2.4
        return
    fi
    script="/usr/share/eole/sbin/bareosconfig.py"
    if [ -f $1/bacula/bacula23.conf ];then
        . $1/bacula/bacula23.conf
    else
        support=`cat $1/bacula/support.conf`
        if [ "$support" = 'bande' ];then
            support='manual'
        elif [ "$support" = 'usb' ];then
            usb_path=`cat "$1/bacula/bacula-usb.txt" 2>/dev/null`
        elif [ "$support" = "distant" ];then
            support='smb'
            if [ -f "$1/bacula/bacula-distant.txt" ];then
                smb_machine=`awk -F ' ' '{print $1}' "$1/bacula/bacula-distant.txt"`
                if [ "${smb_machine:0:2}" = "//" ];then
                    # format Horus-2.2
                    smb_partage=`echo $smb_machine | awk -F '/' '{print $4}'`
                    smb_machine=`echo $smb_machine | awk -F '/' '{print $3}'`
                    smb_login=`awk -F ' ' '{print $3}' "$1/bacula/bacula-distant.txt"`
                    smb_password=`awk -F ' ' '{print $4}' "$1/bacula/bacula-distant.txt"`
                else
                    # format Scribe-2.2
                    smb_partage=`awk -F ' ' '{print $3}' "$1/bacula/bacula-distant.txt"`
                    smb_login=`awk -F ' ' '{print $4}' "$1/bacula/bacula-distant.txt"`
                    smb_password=`awk -F ' ' '{print $5}' "$1/bacula/bacula-distant.txt"`
                fi
                smb_ip=`awk -F ' ' '{print $2}' "$1/bacula/bacula-distant.txt"`
            fi
        fi
        mail_ok=`awk -F ';' '{print $2}' "$1/bacula/mail.conf"`
        mail_error=`awk -F ';' '{print $3}' "$1/bacula/mail.conf"`
    fi

    # restauration des adresses mail
    echo -n "."
    [ ! -z "$mail_ok" ] && $script -m --mail_ok=$mail_ok
    echo -n "."
    [ ! -z "$mail_error" ] && $script -m --mail_error=$mail_error
    echo "."
    # restaurtion du support "manual"
    if [ "$support" = 'manual' ];then
        $script -s manual
    # restauration du support "usb"
    elif [ "$support" = 'usb' ];then
        if [ -z "$usb_path" ];then
            Orange "Support USB non configuré"
        else
            $script -s usb --usb_path=$usb_path
        fi
    # restauration du support "smb"
    elif [ "$support" = 'smb' ];then
        if [ -z "$smb_machine" -o -z "$smb_ip" -o -z "$smb_partage" ];then
            Orange "Configuration smb incomplète"
        else
            smbopts="--smb_machine=$smb_machine --smb_ip=$smb_ip --smb_partage=$smb_partage"
            if [ ! -z "$smb_login" -a ! -z "$smb_password" ];then
                smbopts="$smbopts --smb_login=$smb_login --smb_password=$smb_password"
            fi
            $script -s smb $smbopts
        fi
    elif [ "$support" = 'none' ];then
        Orange "Aucun support de sauvegarde configuré"
    else
        Orange "Support de sauvegarde \"$support\" inconnu"
    fi
    if [ -f $1/bacula/baculajobs.conf ];then
        python3 -c """import sys
from pickle import load
from pyeole.bareos import add_job
for job in load(file('$1/bacula/baculajobs.conf', 'r')):
    job.update({'no_reload':True})
    try:
        add_job(**job)
        sys.stdout.write('.')
    except Exception, msg:
        print msg
"""
    fi
}

savead(){
    # utiliser samba_backup dans le conteneur en reprenant le fonctionnement du schedule samba_backup (non installé)
    if $(lxc-info addc 2>/dev/null >/dev/null)
    then
        Title "Sauvegarde des données du contrôleur de domaine"
        ADDC_ROOTFS="$(lxc-config lxc.lxcpath)/addc/rootfs"	
	lxc-attach -n addc -- /usr/bin/addc_backup
        cp -a "${ADDC_ROOTFS}/home/backup/samba" "$1/"
    fi
}

restoread(){
    # utiliser samba-tool backup dans le conteneur
    if $(lxc-info addc 2>/dev/null >/dev/null) && [ -d "$1/samba/bareos" ]
    then
        Title "Restauration des données du contrôleur de domaine"
        ADDC_ROOTFS="$(lxc-config lxc.lxcpath)/addc/rootfs"	
	[ -d "${ADDC_ROOTFS}/home/backup/samba" ] || mkdir -p "${ADDC_ROOTFS}/home/backup/samba"
        cp -a "$1/samba" "${ADDC_ROOTFS}/home/backup/"
	cp -a "${ADDC_ROOTFS}/var/lib/samba/private/tls" /tmp/
	lxc-attach -n addc -- /usr/bin/addc_restore
	cp -a /tmp/tls "${ADDC_ROOTFS}/var/lib/samba/private/"
	lxc-attach -n addc -- systemctl restart samba-ad-dc
    fi
}

saveamon(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde des personnalisations DansGuardian"
    [ -x /usr/bin/CreoleGet ] && container_path_proxy=$(CreoleGet container_path_proxy)
    mkdir -p "$1/dansguardian"
    dg=$container_path_proxy/var/lib/blacklists/dansguardian
    if [ -d "${dg}0" ];then
        mkdir -p "$1/dansguardian/dansguardian0"
        cp -rf "${dg}0/"* "$1/dansguardian/dansguardian0"
    fi
    if [ -d "${dg}1" ];then
        mkdir -p "$1/dansguardian/dansguardian1"
        cp -rf "${dg}1/"* "$1/dansguardian/dansguardian1"
    fi

    mkdir -p "$1/ead"
    ead=/usr/share/ead2/backend/tmp
    config=/var/lib/eole/config
    # Sites / Mode de filtrage
    cp -f $ead/filtrage-contenu* "$1/ead" 2>/dev/null
    # "Destinations interdites"
    cp -f $ead/dest_interdites*.txt "$1/ead" 2>/dev/null
    # "Sources interdites" (web)
    cp -f $ead/horaire_ip*.txt "$1/ead" 2>/dev/null
    # "Sources interdites" (réseau)
    cp -f $ead/poste_all*.txt "$1/ead" 2>/dev/null
    # Groupe de machine
    cp -f $ead/ipset_group*.txt "$1/ead" 2>/dev/null
    cp -f $ead/ipset_schedules*.pickle "$1/ead" 2>/dev/null
    # Règles du pare-feu
    if [ -f $config/regles.csv ];then
        cp -f $config/regles.csv "$1/ead" 2>/dev/null
    else
        cp -f $ead/regles.csv "$1/ead" 2>/dev/null
    fi
    oldead=/var/www/ead/tmp
    cp -f $oldead/kill-p2p "$1/ead" 2>/dev/null
    if [ -f $config/horaires.txt ];then
        cp -f $config/horaires.txt "$1/ead" 2>/dev/null
    else
        cp -f $oldead/horaires.txt "$1/ead" 2>/dev/null
    fi

    mkdir -p "$1/squid"
    squid=$container_path_proxy/etc/squid
    # /etc/squid3 sur EOLE 2.4
    [ ! -d $squid ] && squid=${squid}3

    Title "Sauvegarde des personnalisations Squid"
    cp -f $squid/domaines_nocache_* "$1/squid" 2>/dev/null
    cp -f $squid/domaines_noauth_* "$1/squid" 2>/dev/null
    cp -f $squid/src_noauth_* "$1/squid" 2>/dev/null
    cp -f $squid/src_nocache_* "$1/squid" 2>/dev/null
}

restoreamon(){
    # $1 : répertoire de sauvegarde
    Title "Restauration des personnalisations Eole-Guardian"
    container_path_proxy=$(CreoleGet container_path_proxy)
    dg=$container_path_proxy/var/lib/blacklists/dansguardian
    if [ $(CreoleGet dans_instance_1_active "non") == "oui" ];then
        if [ -d "$1/dansguardian/dansguardian0" ];then
            cp -rf "$1/dansguardian/dansguardian0/"* "${dg}0"
        fi
    fi
    if [ $(CreoleGet dans_instance_2_active "non") == "oui" ];then
        if [ -d "$1/dansguardian/dansguardian1" ];then
            cp -rf "$1/dansguardian/dansguardian1/"* "${dg}1"
        fi
    fi

    ead=/usr/share/ead2/backend/tmp
    for f in "filtrage-contenu*" "dest_interdites*.txt" "horaire_ip*.txt"\
             "poste_all*.txt" "ipset_group*.txt" "ipset_schedules*.pickle";do
        cp -f "$1/ead/"$f $ead 2>/dev/null
    done

    if [ ! -f "$1/ead/kill-p2p" ];then
        # il est à "on" par défaut sur 2.3
        echo "KILLP2P=off" > /var/lib/eole/config/killp2p.conf
    fi
    cp -f "$1/ead/horaires.txt" /var/lib/eole/config/horaires.txt 2>/dev/null
    cp -f "$1/ead/regles.csv" /var/lib/eole/config/regles.csv 2>/dev/null

    squid=$container_path_proxy/etc/squid3
    Title "Restauration des personnalisations Squid"
    cp -f $1/squid/domaines_nocache_* "$squid" 2>/dev/null
    cp -f $1/squid/domaines_noauth_* "$squid" 2>/dev/null
    cp -f $1/squid/src_noauth_* "$squid" 2>/dev/null
    cp -f $1/squid/src_nocache_* "$squid" 2>/dev/null
}

saveenvole(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde des applications web"
    [ -x /usr/bin/CreoleGet ] && container_path_web=$(CreoleGet container_path_web)
    mkdir -p $1/html
    cp -rpf $container_path_web/var/www/html/ "$1"

    mkdir -p $1/www-data
    if [ -d /home/www-data ];then
        Title "Sauvegarde des données des applications web"
        cp -rpf /home/www-data/ "$1"
    fi

    mkdir -p $1/redis
    if [ -d /var/lib/redis ];then
        Title "Sauvegarde des bases Redis"
        cp -rpf /var/lib/redis/ "$1"
    fi
}

savedivers(){
    # $1 : répertoire de sauvegarde
    Title "Sauvegarde des autres fichiers"
    # sauvegarde des certificats SSL (#2475)
    mkdir -p $1/ssl
    cp -rf /etc/ssl/* "$1/ssl"
    # suppression des liens symbolique
    find "$1/ssl" -type l -delete
    mkdir -p $1/config
    ead_config=/usr/share/ead2/backend/config
    [ -f "$ead_config/perm_local.ini" ] && cp -f "$ead_config/perm_local.ini" "$1/config"
    [ -f "$ead_config/roles_local.ini" ] && cp -f "$ead_config/roles_local.ini" "$1/config"
    ead_tmp=/usr/share/ead2/backend/tmp
    eole_config=/var/lib/eole/config
    [ -f "$ead_tmp/cron.txt" ] && cp -f "$ead_tmp/cron.txt" "$1/config/cron.txt"
    if [ -f "$eole_config/bp_server.conf" ];then
        cp -f "$eole_config/bp_server.conf" "$1/config/bp_server.conf"
    else
        cp -f "$ead_tmp/bp_server.txt" "$1/config/bp_server.conf"
    fi
    [ -d /usr/share/horus/models ] && cp -rf /usr/share/horus/models "$1/config"
    [ -f /usr/share/eole/wpkg/wpkg_config.eol ] && cp /usr/share/eole/wpkg/wpkg_config.eol "$1"
    cp -f $eole_config/dhcp.conf "$1/config/" 2>/dev/null
    echo
}

savesso(){
    # $1 : répertoire de sauvegarde
    sso_dir=/usr/share/sso
    if [ -d $sso_dir ];then
        Title "Sauvegarde des données du service SSO"
        # filtres et fichiers de configuration SSO
        backup_dir=$1/sso
        mkdir -p $backup_dir
        for sso_conf_dir in app_filters attribute_sets external_attrs user_infos metadata interface securid_users
        do
            [ -d ${sso_dir}/${sso_conf_dir} ] && /bin/cp -rf ${sso_dir}/${sso_conf_dir} $backup_dir
        done
    fi
}

savecreole(){
    # $1 : répertoire de sauvegarde
    BACKUP_DIR="$1/creolelocal"
    Title "Sauvegarde des personnalisations Creole locales (non restauré)"
    mkdir -p ${BACKUP_DIR}/distrib
    mkdir -p ${BACKUP_DIR}/dicos
    mkdir -p ${BACKUP_DIR}/patch
    if [ -d /usr/share/eole/creole ];then
        CREOLE_DIR="/usr/share/eole/creole"
    else
        CREOLE_DIR="/etc/eole"
    fi
    # dictionnaires locaux
    /bin/cp -rf $CREOLE_DIR/dicos/local/*.xml ${BACKUP_DIR}/dicos/ >/dev/null 2>&1
    # patchs
    /bin/cp -rf $CREOLE_DIR/patch/*.patch ${BACKUP_DIR}/patch/ >/dev/null 2>&1
    # templates non installés par un paquet (variante et locaux)
    for TMPL in `ls $CREOLE_DIR/distrib/*`
    do
        dpkg -S $TMPL >/dev/null 2>&1
        if [ $? -ne 0 ];then
            /bin/cp -rf $TMPL ${BACKUP_DIR}/distrib/
        fi
    done
}

restoredivers(){
    # $1 : répertoire de sauvegarde
    Title "Restauration des autres fichiers"
    # restauration des certificats SSL (#2475, #25538)
    cp -rf "$1"/ssl/* /etc/ssl
    #FIXME
    [ ${EOLE_VERSION} !=  "2.8" ] && mv -f /etc/ssl/certs/eole.key /etc/ssl/private/

    chmod 600 /etc/ssl/private/eole.key
    ead_config=/usr/share/ead2/backend/config/
    [ -f "$1/config/perm_local.ini" ] && cp -f "$1/config/perm_local.ini" "$ead_config"
    [ -f "$1/config/roles_local.ini" ] && cp -f "$1/config/roles_local.ini" "$ead_config"
    cp -f "$1/config/bp_server.conf" /var/lib/eole/config 2>/dev/null
    # restauration des configurations extra
    [ -d $1/extra ] && cp -rf $1/extra/* /etc/eole/extra/
    if [ -d "$1/config/models" ];then
        rsync -cav --log-file $RSYNC_LOG --ignore-existing "$1/config/models" /usr/share/eole/fichier/models >/dev/null
    fi
    if [ -f "$1/wpkg_config.eol" ];then
        mkdir -p /usr/share/eole/wpkg
        cp -f "$1/wpkg_config.eol" /usr/share/eole/wpkg
    fi
    # désactivation de la maj hebdomadaire
    if [ -f "$1/config/cron.txt" ] && [ $(cat "$1/config/cron.txt" | wc -w) -eq 0 ];then
        /usr/share/eole/schedule/manage_schedule post majauto weekly del >/dev/null
    fi
    cp -f "$1/config/dhcp.conf" /var/lib/eole/config/dhcp.conf 2>/dev/null
    echo
}

restoresso(){
    # $1 : répertoire de sauvegarde
    sso_dir=/usr/share/sso
    if [ -d $sso_dir ];then
        Title "Restauration des données du service SSO"
        restoresso_dir(){
            # restauration des fichiers d'un répertoire (si non existants)
            src_dir=$1
            dest_dir=$2
            extensions=*
            # traite tout les fichier ou une extension particulière
            [ -z "$3" ] || extensions=*.$3
            mkdir -p ${dest_dir}
            if [ -d $src_dir ];then
                for data_file in `ls -d ${src_dir}/${extensions} 2>/dev/null`;do
                    # on n'écrase pas les fichiers installés par les paquet
                    filename=`basename $data_file`
                    [ -e ${dest_dir}/${filename} ] || /bin/cp -r $data_file $dest_dir/
                done
            fi
        }
        ## répetoires de filtres, attributs calculés, metadata, ..
        backup_dir=$1/sso
        for sso_conf_dir in app_filters attribute_sets external_attrs user_infos metadata securid_users;do
            restoresso_dir ${backup_dir}/${sso_conf_dir} ${sso_dir}/${sso_conf_dir}
        done
        interf_dir=${sso_dir}/interface
        int_backup_dir=$1/sso/interface
        ## presonnalisations de l'interface
        # themes et infos homonymes
        for data_dir in images themes theme/image theme/style info_homonymes;do
            restoresso_dir ${int_backup_dir}/${data_dir} ${interf_dir}/${data_dir}
        done
        # fichiers divers de l'interface (avertissement.txt, fichiers .css et .tmpl)
        restoresso_dir $int_backup_dir $interf_dir "tmpl"
        restoresso_dir $int_backup_dir $interf_dir "css"
        restoresso_dir $int_backup_dir $interf_dir "txt"
    fi
}

#scribedivers(){
#    # $1 : répertoire de sauvegarde
#    #Title "Sauvegarde des autres fichiers"
#    mkdir -p $1/config
#    else
#        echo "simple" > $1/config/controlevnc.conf
#    fi
#    # FIXME : posh et applications => c'est mort ?
#}

finsauve(){
    echo
    Green "Sauvegarde spéciale terminée"
}

finresto(){
    Green "Restauration spéciale terminée"
}

scribe22(){
    ## SAUVEGARDE SPECIALE POUR SCRIBE-2.2 ##
    montage $DD
    /etc/init.d/samba stop
    /etc/init.d/nscd start
    DDS="$DD/scribe-$numero_etab"
    /bin/mkdir -p "$DDS"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    questionsave '/home'
    savedata=$?
    [ $savedata -eq 0 ] && savescribedata "$DDS"
    savemail "$DDS"
    # la sauvegarde des quotas et des acl se base sur pam/ldap
    /etc/init.d/slapd restart
    savequota "$DDS"
    savescribeacl "$DDS"
    saveldap "$DDS"
    saveldap2scribe "$DDS"
    savesmb "$DDS"
    savescribemysql "$DDS" '22'
    savebacula22 "$DDS"
    saveenvole "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    /etc/init.d/samba start
    finsauve
}

horus22(){
    ## SAUVEGARDE SPECIALE POUR HORUS-2.2 ##
    montage $DD
    /etc/init.d/xinetd stop
    /etc/init.d/samba stop
    /etc/init.d/nscd start
    DDS="$DD/horus-$numero_etab"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    questionsave '/data'
    savedata=$?
    [ $savedata -eq 0 ] && savehorusdata "$DDS"
    # la sauvegarde des quotas et des acl se base sur pam/ldap
    /etc/init.d/slapd restart
    savequota "$DDS"
    [ $savedata -eq 0 ] && savehorusacl "$DDS"
    saveldap "$DDS"
    saveldap2horus "$DDS"
    savesmb "$DDS"
    savehorusmysql "$DDS" '22'
    savebacula22 "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    /etc/init.d/samba start
    [ "$xinet_interbase" != 'non' ] && /etc/init.d/xinetd start
    finsauve
}

amon22(){
    ## SAUVEGARDE SPECIALE POUR AMON-2.2 ##
    montage $DD
    DDS="$DD/amon-$numero_etab"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    saveamon "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    finsauve
}

scribe23(){
    ## SAUVEGARDE SPECIALE POUR SCRIBE-2.3 et AmonEcole 2.3 ##
    montage $DD
    CreoleService smbd stop
    CreoleService nscd start
    DDS="$DD/scribe-$numero_etab"
    /bin/mkdir -p "$DDS"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    questionsave '/home'
    savedata=$?
    [ $savedata -eq 0 ] && savescribedata "$DDS"
    savemail "$DDS"
    # la sauvegarde des quotas et des acl se base sur pam/ldap
    CreoleService slapd restart
    savequota "$DDS"
    savescribeacl "$DDS"
    saveldap "$DDS"
    saveldap2scribe "$DDS"
    savesmb "$DDS"
    savescribemysql "$DDS" '23'
    savebacula23 "$DDS"
    saveenvole "$DDS"
    [ "$1" = "amonecole" ] && saveamon "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    CreoleService smbd start
    finsauve
}

horus23(){
    ## SAUVEGARDE SPECIALE POUR HORUS-2.3 ##
    montage $DD
    CreoleService xinetd stop
    CreoleService smbd stop
    CreoleService nscd start
    DDS="$DD/horus-$numero_etab"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    questionsave '/home'
    savedata=$?
    [ $savedata -eq 0 ] && savehorusdata "$DDS"
    # la sauvegarde des quotas et des acl se base sur pam/ldap
    CreoleService slapd restart
    savequota "$DDS"
    [ $savedata -eq 0 ] && savehorusacl "$DDS"
    saveldap "$DDS"
    #saveldap2horus "$DDS"
    savesmb "$DDS"
    savehorusmysql "$DDS" '23'
    savebacula23 "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    CreoleService smbd start
    [ "$activer_interbase" != 'non' ] && CreoleService xinetd start
    finsauve
}

amon23(){
    ## SAUVEGARDE SPECIALE POUR AMON >= 2.3 ##
    # $1 : "25" ou rien
    montage $DD "$1"
    DDS="$DD/amon-$numero_etab"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    saveamon "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    finsauve
}

scribe24(){
    ## SAUVEGARDE SPECIALE POUR SCRIBE >= 2.4 et AmonEcole >= 2.4 ##
    # $1 : "amonecole" ou rien
    # $2 : "25" ou rien
    montage $DD "$2"
    CreoleService smbd stop
    CreoleService nscd start
    DDS="$DD/scribe-$numero_etab"
    /bin/mkdir -p "$DDS"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    questionsave '/home'
    savedata=$?
    [ $savedata -eq 0 ] && savescribedata "$DDS"
    savemail "$DDS"
    # la sauvegarde des quotas et des acl se base sur pam/ldap
    CreoleService slapd restart
    savequota "$DDS"
    savescribeacl "$DDS"
    saveldap "$DDS"
    # saveldap2scribe "$DDS"
    savesmb "$DDS"
    savescribemysql "$DDS" '24'
    savebacula24 "$DDS"
    saveenvole "$DDS"
    [ "$1" = "amonecole" ] && saveamon "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    CreoleService smbd start
    finsauve
}

horus24(){
    ## SAUVEGARDE SPECIALE POUR HORUS >= 2.4 ##
    # $1 : "25" ou rien
    montage $DD "$1"
    CreoleService xinetd stop
    CreoleService smbd stop
    CreoleService nscd start
    DDS="$DD/horus-$numero_etab"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    questionsave '/home'
    savedata=$?
    [ $savedata -eq 0 ] && savehorusdata "$DDS"
    # la sauvegarde des quotas et des acl se base sur pam/ldap
    CreoleService slapd restart
    savequota "$DDS"
    [ $savedata -eq 0 ] && savehorusacl "$DDS"
    saveldap "$DDS"
    #saveldap2horus "$DDS"
    savesmb "$DDS"
    savehorusmysql "$DDS" '24'
    savebacula24 "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    CreoleService smbd start
    [ "$activer_interbase" != 'non' ] && CreoleService xinetd start
    finsauve
}

scribe27(){
    ## SAUVEGARDE SPECIALE POUR SCRIBE >= 2.4 et AmonEcole >= 2.4 ##
    # $1 : "amonecole" ou rien
    # $2 : "25" ou rien
    if $(lxc-info addc 2>/dev/null >/dev/null);then
	    montage $DD "$2"
	    CreoleService smbd stop
	    #CreoleService nscd start
	    DDS="$DD/scribe-$numero_etab"
	    /bin/mkdir -p "$DDS"
	    saveconfigeol "$DDS"
	    savecreole "$DDS"
	    questionsave '/home'
	    savedata=$?
	    [ $savedata -eq 0 ] && savescribedata "$DDS"
	    savemail "$DDS"
	    # la sauvegarde des quotas et des acl se base sur pam/ldap
	    CreoleService slapd restart
	    savequota "$DDS"
	    savescribeacl "$DDS"
	    saveldap "$DDS"
	    # saveldap2scribe "$DDS"
	    savead "$DDS"
	    savesmb "$DDS"
	    savescribemysql "$DDS" '24'
	    savebacula24 "$DDS"
	    saveenvole "$DDS"
	    [ "$1" = "amonecole" ] && saveamon "$DDS"
	    savesso "$DDS"
	    savedivers "$DDS"
	    demontage $DD
	    CreoleService smbd start
	    finsauve
    else
        Orange "Passer d’abord le scribe en mode AD"
    fi
}

horus27(){
    ## SAUVEGARDE SPECIALE POUR HORUS >= 2.4 ##
    # $1 : "25" ou rien
    echo
    Question_ouinon "Attention le module horus n'est pas disponible en 2.8, voulez-vous continuer ?" $interactive "non" "warn"
    testcmd $? "Abandon"

    montage $DD "$1"
    CreoleService xinetd stop
    CreoleService smbd stop
    #CreoleService nscd start
    DDS="$DD/horus-$numero_etab"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    questionsave '/home'
    savedata=$?
    [ $savedata -eq 0 ] && savehorusdata "$DDS"
    # la sauvegarde des quotas et des acl se base sur pam/ldap
    CreoleService slapd restart
    savequota "$DDS"
    [ $savedata -eq 0 ] && savehorusacl "$DDS"
    saveldap "$DDS"
    #saveldap2horus "$DDS"
    savesmb "$DDS"
    savehorusmysql "$DDS" '24'
    savebacula24 "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    CreoleService smbd start
    [ "$activer_interbase" != 'non' ] && CreoleService xinetd start
    finsauve
}

amon27(){
    ## SAUVEGARDE SPECIALE POUR AMON >= 2.7 ##
    # $1 : "25" ou rien
    montage $DD "$1"
    DDS="$DD/amon-$numero_etab"
    saveconfigeol "$DDS"
    savecreole "$DDS"
    saveamon "$DDS"
    savesso "$DDS"
    savedivers "$DDS"
    demontage $DD
    finsauve
}

amon28()
{
    ## RESTAURATION SPECIALE POUR AMON-2.8 ##
    Alerte2
    montage $DD '25'
    DDS="$DD/amon-$numero_etab"
    testf "$DDS"
    restoreamon "$DDS"
    restoresso "$DDS"
    restoredivers "$DDS"
    demontage $DD
}

scribe28(){
    ## RESTAURATION SPECIALE POUR SCRIBE-2.8 ##
    Alerte
    montage $DD '25'
    DDS="$DD/scribe-$numero_etab"
    testf "$DDS"
    questionrestore "$DDS" '/home'
    restoacl=$?
    restoread "$DDS" # problème de conflit entre les deux annuaires
    CreoleService smbd stop -c fichier
    CreoleService nmbd stop -c fichier
    service eole-lsc stop
    restoreldap "$DDS"
    restoreldap2scribe "$DDS"
    usersync
    restoresmb "$DDS"
    restorescribedata "$DDS"
    restoremail "$DDS"
    restorequota "$DDS"
    [ $restoacl -eq 0 ] && restoreacl "$DDS"
    genadhome
    restorescribemysql "$DDS"
    restorebacula "$DDS"
    [ "$1" = "amonecole" ] && restoreamon "$DDS"
    restoresso "$DDS"
    restoredivers "$DDS"
    demontage $DD
    CreoleService smbd start -c fichier
    CreoleService nmbd start -c fichier
}

savezephir(){
    enregistrement_zephir --check > /dev/null
    if [ $? -eq 0 ];then
        Title "Sauvegarde des données locales sur Zéphir"
        /usr/share/zephir/scripts/zephir_client save_files
    fi
}

# Sauvegarde
if [ -f /etc/eole/version ]
then
    version=`cat /etc/eole/version`
    if [ "$version" = "scribe-2.2" ];then
        clear
        Version
        Green "Sauvegarde du module $version"
        scribe22
    else
        Version
        Red "Détection d’un module 2.2 indisponible en 2.8.0 !"
        exit 1
    fi
elif [ -f /etc/eole/release ]
then
    . /etc/eole/release
    version="$EOLE_MODULE-$EOLE_VERSION"
    # Question => Question_ouinon
    Question() {
         Question_ouinon "$1"
    }
    if [ $EOLE_VERSION == '2.3' ];then
        if [ "$version" = "scribe-2.3" ];then
            clear
            Version
            Green "Sauvegarde du module $version"
            scribe23
        else
            Version
            Red "Détection d’un module indisponible en 2.8.0 !"
            exit 1
        fi
    elif [ $EOLE_VERSION == '2.4' ];then
        if [ "$version" = "scribe-2.4" ];then
            clear
            Version
            Green "Sauvegarde du module $version"
            scribe24
        else
            Version
            Red "Détection d’un module indisponible en 2.8.0 !"
            exit 1
        fi
    elif [ $EOLE_VERSION == '2.5' ];then
        if [ "$version" = "scribe-2.5" ];then
            clear
            Version
            Green "Sauvegarde du module $version"
            scribe24 '' '25'
        else
            Version
            Red "Détection d’un module non disponible en 2.8.0 !"
            exit 1
        fi
    elif [ $EOLE_VERSION == '2.6' ];then
        if [ "$version" = "scribe-2.6" ];then
            clear
            Version
            Green "Sauvegarde du module $version"
            scribe24 '' '25'
        else
            Version
            Red "Détection d’un module non disponible en 2.8.0 !"
            exit 1
        fi
    elif [ $EOLE_VERSION == '2.7' ];then
        if [ "$version" = "scribe-2.7" ];then
            clear
            Version
            Green "Sauvegarde du module $version"
            scribe27 '' '25'
        else
            Version
            Red "Détection d’un module non disponible en 2.8.0 !"
            exit 1
        fi
    elif [ $EOLE_VERSION == '2.8' ];then
        if [ "$version" = "scribe-2.8" ];then
            clear
            Version
            Green "Restauration du module $version"
            scribe28
        else
            Version
            Red "Détection du module 2.8.0 impossible !"
            exit 1
        fi
        savezephir
        echo
        finresto
    else
        Version
        Red "Détection du module impossible !"
        exit 1
    fi
else
    Version
    Red "Détection du module impossible !"
    exit 1
fi
echo
exit 0
