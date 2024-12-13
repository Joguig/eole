#!/usr/bin/python3
# coding: utf-8
# pep8: --ignore=E201,E202,E211,E501
# pylint: disable=C0323,C0301,C0103,C0111,E0213,C0302,C0203,W0703,R0201,C0325,R0902,R0904,R0912,R0911

import io
import os
import json
import pexpect
import platform
import sys
import time
import traceback
import random
import string
import argparse
import secrets

# Table des pattern / actions
#    tag : mot cle a utilser dans test.yaml
#    pattern : texte à detecter
#    action : texte à emmetre, si action = "$xxx"  ==> action particuilere
#    repeat : REPETITION_OK / REPETITION_NOK
expect_tables = [
    [ 'EOF'                  , pexpect.EOF                                                                     , '$FIN_OK', 'REPETITION_OK'],
    [ 'TIMEOUT'              , pexpect.TIMEOUT                                                                 , '$TIMEOUT', 'REPETITION_OK'],
    [ 'traceback'            , u"Traceback \(most recent call last\):"                                         , '$TRACEBACK', 'REPETITION_OK'],
    [ 'diagnose_partage'     , u" partage => Erreur"                                                           , '$ERREUR', 'REPETITION_OK'],
    [ 'diagnose_bdd'         , " bdd => Erreur"                                                               , '$ERREUR', 'REPETITION_OK'],
    [ 'diagnose_reseau'      , " reseau => Erreur"                                                            , '$ERREUR', 'REPETITION_OK'],
    [ 'diagnose_internet'    , " internet => Erreur"                                                          , '$ERREUR', 'REPETITION_OK'],
    [ 'instance_err_creole'  , "Impossible d’accéder aux variables Creole"                                    , '$ERREUR', 'REPETITION_OK'],
    [ 'instance_maj'         , "Une mise à jour est recommand"                                                , 'non', 'REPETITION_OK'],
    [ 'instance_continue'    , "Continuer instanciation quand"                                                , 'oui', 'REPETITION_OK'],
    [ 'instance_erreur'      , "Pour regénérer le fichier, relancer gen_conteneurs"                           , '$ERREUR', 'REPETITION_OK'],
    [ 'instance_amon_smb'    , "le serveur au domaine maintenant"                                             , 'non', 'REPETITION_OK'],
    [ 'instance_amon_smb2'   , "Relancer l'intégration"                                                       , 'non', 'REPETITION_OK'],
    [ 'instance_amon_smb3'   , "Entrer le nom de l'administrateur du contr.*leur de domaine"                  , 'admin', 'REPETITION_OK'],
    [ 'instance_amon_smb3a'  , "Nom de l'administrateur du contr.*leur de domaine"                            , 'admin', 'REPETITION_OK'],
    [ 'instance_amon_smb4'   , "Entrer le mot de passe de l'administrateur du contr.*leur de domaine"         , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'instance_amonecole'   , "Mot de passe de l'administrateur du contr.*leur de domaine \(Administrator\) ", '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'instance_amon_smb4a'  , "Mot de passe de l'administrateur du contr.*leur de domaine :"                 , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'instance_rearme'      , "Start Systemd services"                                                       , '$REARME', 'REPETITION_OK'],
    [ 'instance_rearme1'     , "des scripts posttemplate"                                                     , '$REARME', 'REPETITION_OK'],
    [ 'gen_conteneur_addc'   , "Génération du conteneur addc"                                                 , '$REARME', 'REPETITION_OK'],
    [ 'envoi_materiel'       , "Pour enrichir cette base, acceptez-vous l'envoi de la description "           , 'non', 'REPETITION_OK'],
    [ 'detruire_ldap'        , "l'annuaire LDAP \(attention"                                                  , 'non', 'REPETITION_OK'],
    [ 'admin_eole1'          , "un nouvel administrateur eole1"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_eole2'          , "un nouvel administrateur eole2"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_eole3'          , "un nouvel administrateur eole3"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_samba'          , "Changement du mot de passe de l'utilisateur \"admin\""                        , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'admin_samba_23'       , "New passwords don't match!"                                                   , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe_root'    , "Changement du mot de passe pour l’utilisateur root"                           , '$PASSWORD_ROOTx2', 'REPETITION_OK'],
    [ 'mot_de_passe_eole'    , "Changement du mot de passe pour l’utilisateur eole"                           , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe'         , "Changement du mot de passe"                                                   , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe_replay'  , "Nouveau mot de passe \(2/5\)"                                                 , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe_us'      , "Enter new UNIX password"                                                      , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'lock_detected'        , "A system lock is already set by another process"                              , '$FAILED', 'REPETITION_OK'],
    [ 'maj_auto_err_connect' , "MAJ : Erreur => Pas de contact avec les serveurs de mise"                     , '$FAILED', 'REPETITION_OK'],
    [ 'maj_auto_erreur'      , "MAJ : Erreur"                                                                 , '$ERREUR', 'REPETITION_OK'],
    [ 'redemarrage'          , "Un redémarrage est nécessaire"                                                , 'non', 'REPETITION_OK'],
    [ 'bases_filtrage'       , "Voulez-vous mettre à jour les bases de filtrage maintenant"                   , 'oui', 'REPETITION_OK'],
    [ 'maj_auto'             , "Configure sources.list"                                                       , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_241'         , "Voulez-vous continuer \[oui/non\]"                                            , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_241a'        , "Voulez-vous continuer \? \[oui/non\]"                                         , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_262'         , "Voulez-vous continuer \? \[non/oui\]"                                         , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_fr'          , "Configuration des sources.list"                                               , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_warning'     , "E: Le téléchargement de quelques fichiers d.index a échoué, ils ont été"      , '$IGNORE_EXIT', 'REPETITION_OK'],
    [ 'maj_auto_long_time'   , "Updating certificates in /etc/ssl/certs"                                     , '$REARME', 'REPETITION_OK'],
    [ 'upgrade_auto_cert'    , "Voulez-vous remplacer l'ancien certificat auto-signé ?"                      , 'oui', 'REPETITION_OK'],
    [ 'inst_zephir_recreate' , "Voulez-vous re-créer les utilisateurs et données de base"                     , '', 'REPETITION_OK'],
    [ 'inst_zephir_password' , "Initialisation du mot de passe de l'administrateur de base \(admin_zephir\)"  , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'inst_zephir_new_user' , "nom d'utilisateur a créer"                                                    , '$PAUSE', 'REPETITION_OK'],
    [ 'reinit_esu_faute'     , "Voulez vous réinitaliser la base ESU"                                         , 'non', 'REPETITION_OK'],
    [ 'reinit_esu'           , "Voulez vous réinitialiser la base ESU"                                        , 'non', 'REPETITION_OK'],
    [ 'reinit_esu_001'       , "Voulez-vous réinitialiser la base ESU"                                        , 'non', 'REPETITION_OK'],
    [ 'instance_rvp'         , "Voulez-vous \(re\)configurer le Réseau Virtuel Privé maintenant"              , 'non', 'REPETITION_OK'],
    [ 'instance_rvp_23'      , "Voulez-vous configurer le Réseau Virtuel Privé maintenant"                    , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , "Voulez-vous \(re\)configurer la haute disponibilité"                          , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , "Voulez-vous synchroniser les noeuds"                                          , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , "Voulez-vous attendre que le script synchro-nodes.sh soit exécuté"             , 'non', 'REPETITION_OK'],
    [ 'maj_auto_23'          , "Ces paquets ne sont pas classés Stables"                                      , 'oui', 'REPETITION_OK'],
    [ 'mot_de_passe_23'      , "Entrez le nouveau mot de passe UNIX"                                          , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'instance_arv_23'      , "Voulez-vous réinitialiser la base ARV et perdre vos modifications"            , 'non', 'REPETITION_OK'],
    [ 'zephir_mini'          , "oulez-vous établir une configuration réseau minimale \(O/N\)"                 , 'N', 'REPETITION_OK'],
    [ 'zephir_ip'            , "Entrez l'adresse du serveur "                                                 , 'zephir.ac-test.fr', 'REPETITION_OK'],
    [ 'zephir_ip1'           , "Entrez l'adresse \(nom DNS\) du serveur "                                     , 'zephir.ac-test.fr', 'REPETITION_OK'],
    [ 'zephir_login'         , "Entrez votre login pour l'application Zéphir \(rien pour sortir\) :"          , 'admin_zephir', 'REPETITION_OK'],
    [ 'zephir_logina'        , "Entrez votre login zephir \(rien pour sortir\) :"                             , 'admin_zephir', 'REPETITION_OK'],
    [ 'zephir_passwd'        , "Mot de passe pour l'application Zéphir pour"                                  , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'zephir_passwda'       , "Mot de passe zephir pour "                                                    , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'zephir_creer'         , "créer le serveur dans la base "                                               , 'N', 'REPETITION_OK'],
    [ 'zephir_rne'           , "Etablissement du serveur \("                                                  , '$NO_RNE', 'REPETITION_OK'],
    [ 'zephir_libelle'       , "libellé du serveur \("                                                        , '', 'REPETITION_OK'],
    [ 'zephir_get'           , "\(rien pour saisir directement un n° de serveur\)"                            , '$NO_RNE', 'REPETITION_INTERDITE'],
    [ 'zephir_id'            , "entrez le n°[ ]*identifiant le serveur.*phir"                                 , '1', 'REPETITION_OK'],
    [ 'zephir_id2'           , "entrez le n° identifiant le serveur l'application Zéphir"                     , '1', 'REPETITION_OK'],
    [ 'zephir_id1'           , "entrez le n° identifiant le serveur dans l'application Zéphir"                , '1', 'REPETITION_OK'],
    [ 'zephir_migration'     , "Le module du serveur choisi est "                                             , 'oui', 'REPETITION_OK'],
    [ 'zephir_get1'          , "matériel \("                                                                  , '', 'REPETITION_OK'],
    [ 'zephir_get2'          , "processeur \("                                                                , '', 'REPETITION_OK'],
    [ 'zephir_get3'          , "disque dur \("                                                                , '', 'REPETITION_OK'],
    [ 'zephir_nom'           , "nom de l'installateur"                                                        , '', 'REPETITION_OK'],
    [ 'zephir_tel'           , "telephone de l'installateur"                                                  , '', 'REPETITION_OK'],
    [ 'zephir_comment'       , "commentaires"                                                                 , '', 'REPETITION_OK'],
    [ 'zephir_delai'         , "Délai entre deux connexions à zephir"                                         , '', 'REPETITION_OK'],
    [ 'zephir_choixm'        , " module \("                                                                    , '', 'REPETITION_OK'],
    [ 'zephir_choixv'        , " variante \("                                                                  , '', 'REPETITION_OK'],
    [ 'zephir_get4'          , "une procédure d'enregistrement à déjà eu lieu pour ce serveur"                , 'O', 'REPETITION_OK'],
    [ 'zephir_choix1'        , "Ce serveur est déjà enregistré sur "                                          , '3', 'REPETITION_OK'],
    [ 'zephir_choix'         , "Configuration des communications vers "                                       , '1', 'REPETITION_OK'],
    [ 'zephir_err_etab'      , "l'établissement doit exister dans la base zephir"                             , '$ERREUR', 'REPETITION_OK'],
    [ 'zephir_gaspacho'      , "La base gaspacho a déjà été initialisée, voulez-vous la réinitialiser"        , '', 'REPETITION_OK'],
    [ 'bacula_001'           , "Le catalogue Bacula a déjà été initialisé, voulez-vous le reinitialiser"      , 'non', 'REPETITION_OK'],
    [ 'genconteneur_001'     , "L'ensemble des conteneurs va être arrêté, voulez-vous continuer"              , 'oui', 'REPETITION_OK'],
    # [ 'genconteneur_002'     , "-\\\|/"                                                                       , 'oui', 'REPETITION_OK'],
    [ 'genconteneur_003'     , "Le cache LXC est déjà présent, voulez-vous le re-créer"                       , 'non', 'REPETITION_OK'],
    [ 'genconteneur_004'     , "Le cache LXC est déjà présent, voulez-vous le supprimer ?"                    , 'non', 'REPETITION_OK'],
    [ 'upgrade_auto_confirm' , "va effectuer la migration vers une nouvelle version de la distribution"       , 'oui', 'REPETITION_OK'],
    [ 'upgrade_auto_version' , "Version de la 2.4"                                                            , '', 'REPETITION_OK'],
    [ 'upgrade_auto_001'     , "Which version do you want to upgrade to"                                      , '1', 'REPETITION_OK'],
    [ 'upgrade_auto_002'     , "Upgrade-Auto est actuellement en version"                                     , 'oui', 'REPETITION_OK'],
    [ 'upgrade_auto_003'     , "Forcer la migration malgré tout"                                              , 'oui', 'REPETITION_OK'],
    [ 'upgrade_auto_zephir'  , "La configuration de migration n'a pas été préparée sur le serveur Zéphir"     , '', 'REPETITION_OK'],
    [ 'maj_release_us'       , "This script will upgrade to a new release"                                    , '', 'REPETITION_OK'],
    [ 'maj_release_fr'       , "Ce script va effectuer la migration vers une nouvelle version mineure de"     , '', 'REPETITION_OK'],
    [ 'upgrade_erreur'       , "Réponse invalide"                                                             , '$ERREUR', 'REPETITION_OK'],
    [ 'upgrade_fin'          , "exécuter la commande 'instance'"                                              , '$FIN_UPGRADE_OK', 'REPETITION_OK'],
    [ 'whatchdog_001'        , "réceptionnés en"                                                              , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_001a'       , "rceptionns en"                                                                , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_002'        , "Gestion du conteneur bdd"                                                     , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_003'        , "Sélection du paquet linux-"                                                   , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_003a'       , "Slection du paquet linux-"                                                    , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_004'        , "Dépaquetage de la mise à jour de linux-"                                      , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_004a'       , "Dpaquetage de la mise à jour de linux-"                                       , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_005'        , "Dépaquetage de linux-firmware"                                                , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_005a'       , "Dpaquetage de linux-firmware"                                                 , '$REARME', 'REPETITION_OK'],
    [ 'restauration_000'     , "Sauvegarde à restaurer"                                                       , '01-01-2016', 'REPETITION_OK'],
    [ 'restauration_001'     , "liste des sauvegardes présentes"                                              , '01-01-2016', 'REPETITION_OK'],
    [ 'restauration_002'     , "Restaurer les bases ARV et la configuration Strongswan"                       , 'oui', 'REPETITION_OK'],
    [ 'restauration_003'     , "Restaurer les données \(o/n\)"                                                , 'o', 'REPETITION_OK'],
    [ 'restauration_004'     , "Restaurer la base de données \(o/n\)"                                         , 'o', 'REPETITION_OK'],
    [ 'genrpt_email'         , "Envoyer l'archive par email ?"                                                , 'non', 'REPETITION_OK'],
    [ 'genrpt_dest'          , "Destinataire du message :"                                                    , 'touser@ac-test.fr', 'REPETITION_OK'],
    [ 'genrpt_commentaire'   , "Commentaire :"                                                                , 'depuis eolecitest!', 'REPETITION_OK'],
    [ 'eolead_23'            , "Mot de passe de l'administrateur Active Directory :"                          , '$PASSWORD_ADDC', 'REPETITION_OK'],
    [ 'addc_0001'            , "Confirming Active Directory Administrator password :"                         , '$PASSWORD_ADDC', 'REPETITION_OK'],
    [ 'addc_0002'            , "Active Directory Administrator password :"                                    , '$PASSWORD_ADDC', 'REPETITION_OK'],
    [ 'addc_0003'            , "Create new 'admin' password"                                                  , '$PASSWORD_ADDC', 'REPETITION_OK'],
    [ 'addc_0004'            , "Confirming 'admin' password"                                                  , '$PASSWORD_ADDC', 'REPETITION_OK'],
    [ 'addc_0005'            , "root@192.168.0.5's password:"                                                 , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'addc_0005a'           , "root@10.1.3.6's password:"                                                    , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'addc_0006'            , "Active Directory .Administrator. password"                                    , '$PASSWORD_ADDCx2', 'REPETITION_OK'],
    [ 'addc_0006a'           , "Création du mot de passe .Administrator. Active Directory"                    , '$PASSWORD_ADDCx2', 'REPETITION_OK'],
    [ 'addc_0007'            , "Active Directory .admin. password"                                            , '$PASSWORD_ADDCx2', 'REPETITION_OK'],
    [ 'addc_0007a'           , "Création du mot de passe .admin. Active Directory"                            , '$PASSWORD_ADDCx2', 'REPETITION_OK'],
    [ 'addc_0008'            , "Compte pour joindre le serveur au domaine"                                    , '', 'REPETITION_INTERDITE'],
    [ 'addc_0009'            , "Mot de passe de jonction au domaine"                                          , '$PASSWORD_ADDC', 'REPETITION_OK'],
    [ 'hapy_0001'            , "Initialisation du mot de passe .* interface Web Sunstone"                     , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'hapy_0002'            , "Entrez le nouveau mot de passe"                                               , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'hapy_0003'            , "Retapez le nouveau mot de passe"                                              , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'hapy_0004'            , "Do you want to proceed"                                                       , 'Y', 'REPETITION_OK'],
    [ 'hapy_0004f'           , "Voulez-vous commencer ?"                                                      , 'Y', 'REPETITION_OK'],
    [ 'hapy_0005'            , "root@hapy-node's password:"                                                   , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'ssh_passwd_eole'      , "root@[^']+'s password:"                                                       , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'ssh_c31e1_eole'       , "c31e1@[^']+'s password:"                                                       , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'ssh_fingerprint_eole' , "Are you sure you want to continue connecting"                                 , 'yes', 'REPETITION_OK'],
    [ 'no_space_001'         , "Aucun espace disponible sur le périphérique"                                  , '$ERREUR', 'REPETITION_OK'],
    [ 'eclair_001'           , "image des clients légers"                                                     , 'oui', 'REPETITION_OK'],
    [ 'eclair_002'           , "image par défaut des clients légers"                                          , 'oui', 'REPETITION_OK'],
    [ 'eclair_003'           , "Génération de l'image "                                                       , '$REARME', 'REPETITION_OK'],
    [ 'esbl_001'             , "Voulez-vous joindre un domaine maintenant"                                    , 'oui', 'REPETITION_OK'],
    [ 'esbl_002'             , "Tapez \(c\) pour \(c\)ontinuer l'installation, \(q\)uitter"                   , 'c', 'REPETITION_OK'],
    [ 'esbl_003'             , "Entrer le type de domaine à joindre \(ad, nt ou amd pour amédée\)"            , 'nt', 'REPETITION_OK'],
    [ 'esbl_004'             , "Donner le nom d'un compte autorisé à ajouter des stations au domaine"         , 'admin.ddt-101', 'REPETITION_OK'],
    [ 'esbl_005'             , "Tapez \(q\) pour \(q\)uitter, \(c\)ontinuer l'installation, \(m\)odifier les" , 'c', 'REPETITION_OK'],
    [ 'esbl_006'             , "Mot de passe pour le compte"                                                  , 'equidomdom', 'REPETITION_OK'],
    [ 'scribead_001'         , "Mot de passe de l'utilisateur Administrator pour le domaine"                  , '$PASSWORD_ADDC', 'REPETITION_OK'],
    [ 'scribead_002'         , "Voulez-vous \(re\)synchroniser les mots de passe des utilisateurs ?"          , 'oui', 'REPETITION_OK'],
]


class InstanceUnattended(object):
    def choice_char(self, length, chars):
        for idx in range(length):
            yield secrets.choice(chars)

    def random_password(self):
        digit_len = secrets.choice(range(3, 5))
        lower_len = secrets.choice(range(3, 5))
        upper_len = 15 - digit_len - lower_len

        digit = list(self.choice_char(digit_len, string.digits))
        lower = list(self.choice_char(lower_len, string.ascii_lowercase))
        upper = list(self.choice_char(upper_len, string.ascii_uppercase))

        passwd = digit + lower + upper
        random.shuffle(passwd)
        return secrets.choice(string.ascii_letters) + ''.join(passwd)

    def random_ad_password(self):
        pronc_len = secrets.choice(range(1, 3))
        digit_len = secrets.choice(range(3, 5))
        lower_len = secrets.choice(range(3, 5))
        upper_len = 15 - pronc_len - digit_len - lower_len

        pronc = list(self.choice_char(pronc_len, "_-$"))
        digit = list(self.choice_char(digit_len, string.digits))
        lower = list(self.choice_char(lower_len, string.ascii_lowercase))
        upper = list(self.choice_char(upper_len, string.ascii_uppercase))

        passwd = pronc + digit + lower + upper
        random.shuffle(passwd)
        return secrets.choice(string.ascii_letters) + ''.join(passwd)

    def println_err(self, texte):
        sys.stdout.flush()
        sys.stderr.write(str(texte) + "\n")
        sys.stderr.flush()

    def debugln_err(self, texte):
        if self.vmDebug > "0":
            self.println_err(texte)

    def getEnv(self, key, default):
        valeur = os.getenv(key, default)
        if self.vmDebug > "0":
            self.println_err(key + "=" + valeur)
        return valeur

    def __init__(self):
        self.vmDebug = os.getenv('VM_DEBUG', '0')
        self.versionMajeur = self.getEnv('VM_VERSIONMAJEUR', '?') # creoleget
        self.module = self.getEnv('VM_MODULE', '?') # creoleget
        self.rne = self.getEnv('VM_NO_ETAB', '$') # creoleget
        self.timeout = 2000
        self.aPwdGenerated = False
        self.pwd_eole = None
        self.pwd_root = None
        self.pwd_addc = None
        self.erreur = False
        self.tracebackDetecte = False
        self.ignorePexpectExit = False
        self.pexpectCommand = None
        self.specifique_actions = []

    def println_instanceUnattended(self, texte):
        texte = "instanceUnattended: " + texte
        self.println_err("\n" + texte)

    def load_passwords(self, file):
        if os.path.isfile(file) == False:
            print( file + " : fichier inconnu!")
            return
        self.println_err("\ninstanceUnattended : chargement des mdp depuis " + file)
        for ligne in open(file,'r').readlines():
            items = ligne.split(' ')
            if len(items) > 1: 
                if items[0] == 'root':
                    self.pwd_root = items[1].strip()
                if items[0] == 'eole':
                    self.pwd_eole = items[1].strip()
                if items[0] == 'addc':
                    self.pwd_addc = items[1].strip()
        #self.debugln_err( "root " + self.pwd_root )
        #self.debugln_err( "eole " + self.pwd_eole )
        #self.debugln_err( "addc " + self.pwd_addc )

    def store_passwords(self, file):
        if not self.aPwdGenerated:
            self.println_err("\ninstanceUnattended : Aucun mdp généré => pas de modification du fichier pwd")
            return
        self.println_err("\ninstanceUnattended : sauvegarde des mdp dans " + file)
        with open(file,'w') as fd:
            if not self.pwd_root is None:
                fd.write(f'root {self.pwd_root}\n')
            if not self.pwd_eole is None:
                fd.write(f'eole {self.pwd_eole}\n')
            if not self.pwd_addc is None:
                fd.write(f'addc {self.pwd_addc}\n')

    def setTimeout(self, timeoutCmd):
        if timeoutCmd > self.timeout:
            self.timeout = timeoutCmd

    def setActions(self, specifique_actions):
        self.specifique_actions = specifique_actions

    def sendPwdEole(self):
        if self.pwd_eole is None:
            self.pwd_eole = self.random_password()
            self.aPwdGenerated = True
        self.pexpectCommand.sendline(self.pwd_eole)
        
    def sendPwdRoot(self):
        if self.pwd_root is None:
            self.pwd_root = self.random_password()
            self.aPwdGenerated = True
        self.pexpectCommand.sendline(self.pwd_root)
        
    def sendPwdAddc(self):
        if self.pwd_addc is None:
            self.pwd_addc = self.random_password()
            self.aPwdGenerated = True
        self.pexpectCommand.sendline(self.pwd_addc)
        
    def do_action(self, action):
        if action == "$FIN_UPGRADE_OK":
            self.println_instanceUnattended("FIN_UPGRADE_OK")
            self.ignorePexpectExit = True
            return 1

        elif action == "$IGNORE_EXIT":
            self.println_instanceUnattended("IGNORE_EXIT")
            self.ignorePexpectExit = True
            return -1

        elif action == "$FIN_OK":
            if self.tracebackDetecte:
                self.println_instanceUnattended("EXIT ERREUR TRACEBACK DETECTE")
                return 3
            elif self.erreur:
                self.println_instanceUnattended("EXIT ERREUR DETECTE")
                return 3
            else:
                return 0

        self.ignorePexpectExit = False
        if action == "$FAILED":
            self.println_instanceUnattended("failed")
            return 1
        elif action == "$TIMEOUT":
            self.println_instanceUnattended("apres timeout de " + str(self.timeout) + " secondes")
            return 2
        elif action == "$PASSWORD_EOLE":
            time.sleep(5)
            self.sendPwdEole()
            return -1
        elif action == "$PASSWORD_EOLEx2":
            time.sleep(5)
            self.sendPwdEole()
            time.sleep(1)
            self.sendPwdEole()
            return -1
        elif action == "$PASSWORD_ROOTx2":
            time.sleep(5)
            self.sendPwdRoot()
            time.sleep(1)
            self.sendPwdRoot()
            return -1
        elif action == "$PASSWORD_ADDC":
            time.sleep(5)
            self.sendPwdAddc()
            time.sleep(1)
            return -1
        elif action == "$PASSWORD_ADDCx2":
            time.sleep(5)
            self.sendPwdAddc()
            time.sleep(1)
            self.sendPwdAddc()
            return -1
        elif action == "$TRACEBACK":
            self.tracebackDetecte = True
            return -1
        elif action == "$ERREUR":
            self.erreur = True
            return -1
        elif action == "$REARME":
            return -1
        elif action == "$PAUSE":
            time.sleep(10)
            self.pexpectCommand.sendline('')
            return -1
        elif action == "$NO_RNE":
            self.println_err("\ninstanceUnattended : NO RNE => " + self.rne)
            action = self.rne
        self.pexpectCommand.sendline(action)
        return -1

    def PExpectLoop(self):
        if self.versionMajeur > '2.7.1' and self.module == 'seth':
            # ce pattern n'a de sens que dans le cas Seth Education (car sur Seth le pattern pour admin est addc_0007a)
            self.setActions([['admin_samba', '$PASSWORD_ADDCx2']])
        if self.versionMajeur > '2.8' and self.module == 'amonecole':
            self.setActions([['admin_samba', '$PASSWORD_ADDCx2'], ['instance_amon_smb4a', '$PASSWORD_ADDCx2'], ])
        self.erreur = False
        self.tracebackDetecte = False
        # , timeout=self.timeout il est global !
        self.pexpectCommand = pexpect.spawn("instance", ignore_sighup=False, maxread=200,
                                            encoding='utf-8', echo=False, logfile=sys.stdout)
        self.pexpectCommand.delaybeforesend = 0.1
        # self.pexpectCommand.echo = False
        tables = [i[1] for i in expect_tables ]
        compiled_pattern_list = self.pexpectCommand.compile_pattern_list(tables)
        time.sleep(0.5)

        cdu = -1
        action_precedente = '$'
        action_precedente1 = '$'
        while cdu == -1:
            index = self.pexpectCommand.expect_list(compiled_pattern_list, timeout=self.timeout)
            sys.stdout.flush()
            sys.stderr.flush()
            tag = expect_tables[index][0]
            action = expect_tables[index][2]
            repetition = expect_tables[index][3]
            for specifique_action in self.specifique_actions:
                if specifique_action[0] == tag:
                    action = specifique_action[1]
                    break
            if repetition == 'REPETITION_INTERDITE':
                if action_precedente == action:
                    self.println_instanceUnattended("ERREUR REPETITION ACTION:" + action + " RISQUE BOUCLE INFINIE ?")
                    cdu = -1
                    break
                if action_precedente1 == action:
                    self.println_instanceUnattended("ERREUR REPETITION ACTION:" + action + " RISQUE BOUCLE INFINIE ?")
                    cdu = -1
                    break

            #self.println_instanceUnattended(tag + " action:" + action)
            action_precedente1 = action_precedente
            action_precedente = action
            cdu = self.do_action(action)

        try:
            if cdu == 0:
                self.pexpectCommand.close()
            else:
                self.pexpectCommand.close(True)
        except Exception as e:
            self.println_instanceUnattended(f"Erreur ignorée ! : {str(e)}")

        if self.ignorePexpectExit:
            msg = f"Pexpect with ignorePexpectExit Exit={str(cdu)},"
            msg += f"PexpectExit={str(self.pexpectCommand.exitstatus)},"
            msg += f"Status={str(self.pexpectCommand.status)},"
            msg += f"Signalstatus={str(self.pexpectCommand.signalstatus)}"
            self.println_instanceUnattended(msg)
            return 0
        if cdu != 0:
            msg = f"Pexpect Exit={str(cdu)}, PexpectExit={str(self.pexpectCommand.exitstatus)},"
            msg += f"Status={str(self.pexpectCommand.status)},"
            msg += f"Signalstatus={str(self.pexpectCommand.signalstatus)}"
            self.println_instanceUnattended(msg)
            return cdu
        if self.pexpectCommand.exitstatus != 0:
            msg = f"ATTENTION: Pexpect Exit=0, PexpectExit={str(self.pexpectCommand.exitstatus)},"
            msg += f"Status={str(self.pexpectCommand.status)}, Signalstatus={str(self.pexpectCommand.signalstatus)}"
            self.println_instanceUnattended(msg)
            return self.pexpectCommand.exitstatus
        return 0

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='instance-unattended',
                                     description='Instance your server without any questions.',
                                     usage="%(prog)s [options]")
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('--response', help='json response file to use')
    parser.add_argument('--store-passwords', action='store_true', help='enable generated password storage')
    parser.add_argument('--file-passwords', help='password file to use')
    args = parser.parse_args()

    instanceUnattended = InstanceUnattended()
    exitCode = -1
    try:
        if args.debug:
            instanceUnattended.vmDebug = "1"
        if args.file_passwords: 
            instanceUnattended.load_passwords(args.file_passwords)
        if args.response:
            if os.path.isfile(fichierReponses) == False:
                print( fichierReponses + " : fichier inconnu!")
                sys.exit(1)
                fichierReponses = args.response

            with open(fichierReponses) as file:
                for reponse in json.load( file ):
                    tag     = reponse[ 'tag' ] if 'tag' in reponse else None
                    trouve=False
                    for expect_record in expect_tables:
                        if expect_record[0] == tag:
                            trouve=True
                            if 'pattern' in reponse:
                                expect_record[1] = reponse[ 'pattern' ]
                            if 'action' in reponse:
                                expect_record[1] = reponse[ 'action' ]
                            if 'repeat' in reponse:
                                expect_record[1] = reponse[ 'repeat' ]
                            break

                    if trouve == False:
                        if 'pattern' in reponse:
                            pattern = reponse[ 'pattern' ] if 'pattern' in reponse else ''
                        else:
                            print ("pas de 'pattern' pour le tag '" + tag + "'")
                            sys.exit(1)
                        action  = reponse[ 'action' ] if 'action' in reponse else '' # = ENTER
                        repeat  = reponse[ 'repeat' ] if 'repeat' in reponse  else 'REPETITION_OK'
                        expect_tables.append([tag, pattern, action, repeat ])

        exitCode = instanceUnattended.PExpectLoop()
        
        # si demandé, j'enregistre uniquement les mots de passes générés
        if args.store_passwords:
            if args.file_passwords is None:
                if os.path.isdir("/mnt/hapy-deploy"):
                    passwd_dir = "/mnt/hapy-deploy"
                else:
                    passwd_dir = "/tmp"
                passwd_file= f"{passwd_dir}/instance-pwd.sc"
                instanceUnattended.store_passwords(passwd_file)
            else:
                instanceUnattended.store_passwords(args.file_passwords)
    except Exception as e:
        traceback.print_exc( e )
        exitCode = -2
    sys.exit(exitCode)
