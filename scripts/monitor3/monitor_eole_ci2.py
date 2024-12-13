#!/usr/bin/env python2
# coding: utf-8
# pep8: --ignore=E201,E202,E211,E501
# pylint: disable=C0323,C0301,C0103,C0111,E0213,C0302,C0203,W0703,R0201,C0325,R0902,R0904,R0912,R0911

import io
import os
import pexpect
import sys
import time

# Table des pattern / actions
#    tag : mot cle a utilser dans test.yaml
#    pattern : texte à detecter
#    action : texte à emmetre, si action = "$xxx"  ==> action particuilere
expect_tables = [
    [ 'EOF'                  , pexpect.EOF                                                                     , '$FIN_OK', 'REPETITION_OK'],
    [ 'TIMEOUT'              , pexpect.TIMEOUT                                                                 , '$TIMEOUT', 'REPETITION_OK'],
    [ 'traceback'            , r"Traceback \(most recent call last\):"                                         , '$TRACEBACK', 'REPETITION_OK'],
    [ 'diagnose_partage'     , r" partage => Erreur"                                                           , '$ERREUR', 'REPETITION_OK'],
    [ 'diagnose_bdd'         , r" bdd => Erreur"                                                               , '$ERREUR', 'REPETITION_OK'],
    [ 'diagnose_reseau'      , r" reseau => Erreur"                                                            , '$ERREUR', 'REPETITION_OK'],
    [ 'diagnose_internet'    , r" internet => Erreur"                                                          , '$ERREUR', 'REPETITION_OK'],
    [ 'instance_err_creole'  , r"Impossible d’accéder aux variables Creole"                                    , '$ERREUR', 'REPETITION_OK'],
    [ 'instance_maj'         , r"Une mise à jour est recommand"                                                , 'non', 'REPETITION_OK'],
    [ 'instance_continue'    , r"Continuer instanciation quand"                                                , 'oui', 'REPETITION_OK'],
    [ 'instance_erreur'      , r"Pour regénérer le fichier, relancer gen_conteneurs"                           , '$ERREUR', 'REPETITION_OK'],
    [ 'instance_amon_smb'    , r"le serveur au domaine maintenant"                                             , 'non', 'REPETITION_OK'],
    [ 'instance_amon_smb2'   , r"Relancer l'intégration"                                                       , 'non', 'REPETITION_OK'],
    [ 'instance_amon_smb3'   , r"Entrer le nom de l'administrateur du contr.*leur de domaine"                  , 'admin', 'REPETITION_OK'],
    [ 'instance_amon_smb3a'  , r"Nom de l'administrateur du contr.*leur de domaine"                            , 'admin', 'REPETITION_OK'],
    [ 'instance_amon_smb4'   , r"Entrer le mot de passe de l'administrateur du contr.*leur de domaine"         , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'instance_amon_smb4a'  , r"Mot de passe de l'administrateur du contr.*leur de domaine"                   , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'instance_rearme'      , r"Start Systemd services"                                                       , '$REARME', 'REPETITION_OK'],
    [ 'instance_rearme1'     , r"des scripts posttemplate"                                                     , '$REARME', 'REPETITION_OK'],
    [ 'gen_conteneur_addc'   , r"Génération du conteneur addc"                                                 , '$REARME', 'REPETITION_OK'],
    [ 'envoi_materiel'       , r"Pour enrichir cette base, acceptez-vous l'envoi de la description "           , 'non', 'REPETITION_OK'],
    [ 'detruire_ldap'        , r"l'annuaire LDAP \(attention"                                                  , 'non', 'REPETITION_OK'],
    [ 'admin_eole1'          , r"un nouvel administrateur eole1"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_eole2'          , r"un nouvel administrateur eole2"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_eole3'          , r"un nouvel administrateur eole3"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_samba'          , r"Changement du mot de passe de l'utilisateur \"admin\""                        , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'admin_samba_23'       , r"New passwords don't match!"                                                   , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'mot_de_passe_root'    , r"Changement du mot de passe de l'utilisateur root"                             , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'mot_de_passe_root24'  , r"Changement du mot de passe pour l'utilisateur"                                , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'mot_de_passe_eole'    , r"Changement du mot de passe de l'utilisateur eole"                             , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'mot_de_passe'         , r"Changement du mot de passe"                                                   , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'mot_de_passe_replay'  , r"Nouveau mot de passe \(2/5\)"                                                 , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'mot_de_passe_us'      , r"Enter new UNIX password"                                                      , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'lock_detected'        , r"A system lock is already set by another process"                              , '$FAILED', 'REPETITION_OK'],
    [ 'maj_auto_err_connect' , r"MAJ : Erreur => Pas de contact avec les serveurs de mise"                     , '$FAILED', 'REPETITION_OK'],
    [ 'maj_auto_erreur'      , r"MAJ : Erreur"                                                                 , '$ERREUR', 'REPETITION_OK'],
    [ 'redemarrage'          , r"Un redémarrage est nécessaire"                                                , 'non', 'REPETITION_OK'],
    [ 'bases_filtrage'       , r"Voulez-vous mettre à jour les bases de filtrage maintenant"                   , 'oui', 'REPETITION_OK'],
    [ 'maj_auto'             , r"Configure sources.list"                                                       , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_241'         , r"Voulez-vous continuer \[oui/non\]"                                            , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_241a'        , r"Voulez-vous continuer \? \[oui/non\]"                                         , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_262'         , r"Voulez-vous continuer \? \[non/oui\]"                                         , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_fr'          , r"Configuration des sources.list"                                               , 'oui', 'REPETITION_OK'],
    [ 'maj_auto_warning'     , r"E: Le téléchargement de quelques fichiers d.index a échoué, ils ont été"      , '$IGNORE_EXIT', 'REPETITION_OK'],
    [ 'maj_auto_long_time'   , r"Updating certificates in /etc/ssl/certs"                                      , '$REARME', 'REPETITION_OK'],
    [ 'inst_zephir_recreate' , r"Voulez-vous re-créer les utilisateurs et données de base"                     , '', 'REPETITION_OK'],
    [ 'inst_zephir_password' , r"Initialisation du mot de passe de l'administrateur de base \(admin_zephir\)"  , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'inst_zephir_new_user' , r"nom d'utilisateur a créer"                                                    , '$PAUSE', 'REPETITION_OK'],
    [ 'reinit_esu_faute'     , r"Voulez vous réinitaliser la base ESU"                                         , 'non', 'REPETITION_OK'],
    [ 'reinit_esu'           , r"Voulez vous réinitialiser la base ESU"                                        , 'non', 'REPETITION_OK'],
    [ 'reinit_esu_001'       , r"Voulez-vous réinitialiser la base ESU"                                        , 'non', 'REPETITION_OK'],
    [ 'instance_rvp'         , r"Voulez-vous \(re\)configurer le Réseau Virtuel Privé maintenant"              , 'non', 'REPETITION_OK'],
    [ 'instance_rvp_23'      , r"Voulez-vous configurer le Réseau Virtuel Privé maintenant"                    , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , r"Voulez-vous \(re\)configurer la haute disponibilité"                          , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , r"Voulez-vous synchroniser les noeuds"                                          , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , r"Voulez-vous attendre que le script synchro-nodes.sh soit exécuté"             , 'non', 'REPETITION_OK'],
    [ 'maj_auto_23'          , r"Ces paquets ne sont pas classés Stables"                                      , 'oui', 'REPETITION_OK'],
    [ 'mot_de_passe_23'      , r"Entrez le nouveau mot de passe UNIX"                                          , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'instance_arv_23'      , r"Voulez-vous réinitialiser la base ARV et perdre vos modifications"            , 'non', 'REPETITION_OK'],
    [ 'zephir_mini'          , r"oulez-vous établir une configuration réseau minimale \(O/N\)"                 , 'N', 'REPETITION_OK'],
    [ 'zephir_ip'            , r"Entrez l'adresse du serveur "                                                 , 'zephir.ac-test.fr', 'REPETITION_OK'],
    [ 'zephir_ip1'           , r"Entrez l'adresse \(nom DNS\) du serveur "                                     , 'zephir.ac-test.fr', 'REPETITION_OK'],
    [ 'zephir_login'         , r"Entrez votre login pour l'application Zéphir \(rien pour sortir\) :"          , 'admin_zephir', 'REPETITION_OK'],
    [ 'zephir_logina'        , r"Entrez votre login zephir \(rien pour sortir\) :"                             , 'admin_zephir', 'REPETITION_OK'],
    [ 'zephir_passwd'        , r"Mot de passe pour l'application Zéphir pour"                                  , 'eole', 'REPETITION_OK'],
    [ 'zephir_passwda'       , r"Mot de passe zephir pour "                                                    , 'eole', 'REPETITION_OK'],
    [ 'zephir_creer'         , r"créer le serveur dans la base "                                               , 'N', 'REPETITION_OK'],
    [ 'zephir_rne'           , r"Etablissement du serveur \("                                                  , '$NO_RNE', 'REPETITION_OK'],
    [ 'zephir_libelle'       , r"libellé du serveur \("                                                        , '', 'REPETITION_OK'],
    [ 'zephir_get'           , r"\(rien pour saisir directement un n° de serveur\)"                            , '$NO_RNE', 'REPETITION_INTERDITE'],
    [ 'zephir_id'            , r"entrez le n°[ ]*identifiant le serveur.*phir"                                 , '1', 'REPETITION_OK'],
    [ 'zephir_id2'           , r"entrez le n° identifiant le serveur l'application Zéphir"                     , '1', 'REPETITION_OK'],
    [ 'zephir_id1'           , r"entrez le n° identifiant le serveur dans l'application Zéphir"                , '1', 'REPETITION_OK'],
    [ 'zephir_migration'     , r"Le module du serveur choisi est "                                             , 'oui', 'REPETITION_OK'],
    [ 'zephir_get1'          , r"matériel \("                                                                  , '', 'REPETITION_OK'],
    [ 'zephir_get2'          , r"processeur \("                                                                , '', 'REPETITION_OK'],
    [ 'zephir_get3'          , r"disque dur \("                                                                , '', 'REPETITION_OK'],
    [ 'zephir_nom'           , r"nom de l'installateur"                                                        , '', 'REPETITION_OK'],
    [ 'zephir_tel'           , r"telephone de l'installateur"                                                  , '', 'REPETITION_OK'],
    [ 'zephir_comment'       , r"commentaires"                                                                 , '', 'REPETITION_OK'],
    [ 'zephir_delai'         , r"Délai entre deux connexions à zephir"                                         , '', 'REPETITION_OK'],
    [ 'zephir_choixm'        , r" module \("                                                                    , '', 'REPETITION_OK'],
    [ 'zephir_choixv'        , r" variante \("                                                                  , '', 'REPETITION_OK'],
    [ 'zephir_get4'          , r"une procédure d'enregistrement à déjà eu lieu pour ce serveur"                , 'O', 'REPETITION_OK'],
    [ 'zephir_choix1'        , r"Ce serveur est déjà enregistré sur "                                          , '3', 'REPETITION_OK'],
    [ 'zephir_choix'         , r"Configuration des communications vers "                                       , '1', 'REPETITION_OK'],
    [ 'zephir_err_etab'      , r"l'établissement doit exister dans la base zephir"                             , '$ERREUR', 'REPETITION_OK'],
    [ 'zephir_gaspacho'      , r"La base gaspacho a déjà été initialisée, voulez-vous la réinitialiser"        , '', 'REPETITION_OK'],
    [ 'bacula_001'           , r"Le catalogue Bacula a déjà été initialisé, voulez-vous le reinitialiser"      , 'non', 'REPETITION_OK'],
    [ 'genconteneur_001'     , r"L'ensemble des conteneurs va être arrêté, voulez-vous continuer"              , 'oui', 'REPETITION_OK'],
    [ 'genconteneur_002'     , r"-\\\|/"                                                                       , 'oui', 'REPETITION_OK'],
    [ 'genconteneur_003'     , r"Le cache LXC est déjà présent, voulez-vous le re-créer"                       , 'non', 'REPETITION_OK'],
    [ 'genconteneur_004'     , r"Le cache LXC est déjà présent, voulez-vous le supprimer ?"                    , 'non', 'REPETITION_OK'],
    [ 'upgrade_auto_confirm' , r"va effectuer la migration vers une nouvelle version de la distribution"       , 'oui', 'REPETITION_OK'],
    [ 'upgrade_auto_version' , r"Version de la 2.4"                                                            , '', 'REPETITION_OK'],
    [ 'upgrade_auto_001'     , r"Which version do you want to upgrade to"                                      , '1', 'REPETITION_OK'],
    [ 'upgrade_auto_002'     , r"Upgrade-Auto est actuellement en version"                                     , 'oui', 'REPETITION_OK'],
    [ 'upgrade_auto_zephir'  , r"La configuration de migration n'a pas été préparée sur le serveur Zéphir"     , '', 'REPETITION_OK'],
    [ 'maj_release_us'       , r"This script will upgrade to a new release"                                    , '', 'REPETITION_OK'],
    [ 'maj_release_fr'       , r"Ce script va effectuer la migration vers une nouvelle version mineure de"     , '', 'REPETITION_OK'],
    [ 'upgrade_erreur'       , r"Réponse invalide"                                                             , '$ERREUR', 'REPETITION_OK'],
    [ 'upgrade_fin'          , r"exécuter la commande 'instance'"                                              , '$FIN_UPGRADE_OK', 'REPETITION_OK'],
    [ 'whatchdog_001'        , r"réceptionnés en"                                                              , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_001a'       , r"rceptionns en"                                                                , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_002'        , r"Gestion du conteneur bdd"                                                     , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_003'        , r"Sélection du paquet linux-"                                                   , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_003a'       , r"Slection du paquet linux-"                                                    , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_004'        , r"Dépaquetage de la mise à jour de linux-"                                      , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_004a'       , r"Dpaquetage de la mise à jour de linux-"                                       , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_005'        , r"Dépaquetage de linux-firmware"                                                , '$REARME', 'REPETITION_OK'],
    [ 'whatchdog_005a'       , r"Dpaquetage de linux-firmware"                                                 , '$REARME', 'REPETITION_OK'],
    [ 'restauration_000'     , r"Sauvegarde à restaurer"                                                       , '01-01-2016', 'REPETITION_OK'],
    [ 'restauration_001'     , r"liste des sauvegardes présentes"                                              , '01-01-2016', 'REPETITION_OK'],
    [ 'restauration_002'     , r"Restaurer les bases ARV et la configuration Strongswan"                       , 'oui', 'REPETITION_OK'],
    [ 'restauration_003'     , r"Restaurer les données \(o/n\)"                                                , 'o', 'REPETITION_OK'],
    [ 'restauration_004'     , r"Restaurer la base de données \(o/n\)"                                         , 'o', 'REPETITION_OK'],
    [ 'genrpt_email'         , r"Envoyer l'archive par email ?"                                                , 'non', 'REPETITION_OK'],
    [ 'genrpt_dest'          , r"Destinataire du message :"                                                    , 'touser@ac-test.fr', 'REPETITION_OK'],
    [ 'genrpt_commentaire'   , r"Commentaire :"                                                                , 'depuis eolecitest!', 'REPETITION_OK'],
    [ 'eolead_23'            , r"Mot de passe de l'administrateur Active Directory :"                          , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
    [ 'addc_0001'            , r"Confirming Active Directory Administrator password :"                         , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
    [ 'addc_0002'            , r"Active Directory Administrator password :"                                    , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
    [ 'addc_0003'            , r"Create new 'admin' password"                                                  , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
    [ 'addc_0004'            , r"Confirming 'admin' password"                                                  , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
    [ 'addc_0005'            , r"root@192.168.0.5's password:"                                                 , 'eole', 'REPETITION_OK'],
    [ 'addc_0005a'           , r"root@10.1.3.6's password:"                                                    , 'eole', 'REPETITION_OK'],
    [ 'addc_0006'            , r"Active Directory .Administrator. password"                                    , '$PASSWORD_SAMBA4x2', 'REPETITION_OK'],
    [ 'addc_0006a'           , r"Création du mot de passe .Administrator. Active Directory"                    , '$PASSWORD_SAMBA4x2', 'REPETITION_OK'],
    [ 'addc_0007'            , r"Active Directory .admin. password"                                            , '$PASSWORD_SAMBA4x2', 'REPETITION_OK'],
    [ 'addc_0007a'           , r"Création du mot de passe .admin. Active Directory"                            , '$PASSWORD_SAMBA4x2', 'REPETITION_OK'],
    [ 'addc_0008'            , r"Compte pour joindre le serveur au domaine"                                    , '', 'REPETITION_OK'],
    [ 'addc_0009'            , r"Mot de passe de jonction au domaine"                                          , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
    [ 'hapy_0001'            , r"Initialisation du mot de passe .* interface Web Sunstone"                     , 'eole', 'REPETITION_OK'],
    [ 'hapy_0002'            , r"Entrez le nouveau mot de passe"                                               , 'eole', 'REPETITION_OK'],
    [ 'hapy_0003'            , r"Retapez le nouveau mot de passe"                                              , 'eole', 'REPETITION_OK'],
    [ 'hapy_0004'            , r"Do you want to proceed"                                                       , 'Y', 'REPETITION_OK'],
    [ 'hapy_0004f'           , r"Voulez-vous commencer ?"                                                      , 'Y', 'REPETITION_OK'],
    [ 'hapy_0005'            , r"root@hapy-node's password:"                                                   , 'eole', 'REPETITION_OK'],
    [ 'ssh_passwd_eole'      , r"root@[^']+'s password:"                                                       , 'eole', 'REPETITION_OK'],
    [ 'ssh_fingerprint_eole' , r"Are you sure you want to continue connecting"                                 , 'yes', 'REPETITION_OK'],
    [ 'no_space_001'         , r"Aucun espace disponible sur le périphérique"                                  , '$ERREUR', 'REPETITION_OK'],
    [ 'eclair_001'           , r"image des clients légers"                                                     , 'oui', 'REPETITION_OK'],
    [ 'eclair_002'           , r"image par défaut des clients légers"                                          , 'oui', 'REPETITION_OK'],
    [ 'eclair_003'           , r"Génération de l'image "                                                       , '$REARME', 'REPETITION_OK'],
    [ 'esbl_001'             , r"Voulez-vous joindre un domaine maintenant"                                    , 'oui', 'REPETITION_OK'],
    [ 'esbl_002'             , r"Tapez \(c\) pour \(c\)ontinuer l'installation, \(q\)uitter"                   , 'c', 'REPETITION_OK'],
    [ 'esbl_003'             , r"Entrer le type de domaine à joindre \(ad, nt ou amd pour amédée\)"            , 'nt', 'REPETITION_OK'],
    [ 'esbl_004'             , r"Donner le nom d'un compte autorisé à ajouter des stations au domaine"         , 'admin.ddt-101', 'REPETITION_OK'],
    [ 'esbl_005'             , r"Tapez \(q\) pour \(q\)uitter, \(c\)ontinuer l'installation, \(m\)odifier les" , 'c', 'REPETITION_OK'],
    [ 'esbl_006'             , r"Mot de passe pour le compte"                                                  , 'equidomdom', 'REPETITION_OK'],
    [ 'scribead_001'         , r"Mot de passe de l'utilisateur Administrator pour le domaine"                  , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
    [ 'scribead_002'         , r"Voulez-vous \(re\)synchroniser les mots de passe des utilisateurs ?"          , 'oui', 'REPETITION_OK'],
    [ 'scribead_003'         , r"Password for [Administrator@DOMSCRIBE.AC-TEST.FR]:"                           , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
]


class MonitorEoleCi(object):
    erreur = False
    tracebackDetecte = False
    ignorePexpectExit = False
    nePasAfficherLesMessagesMonitor = False
    commande = None
    pexpectCommand = None
    zephir_desincription = False
    specifique_actions = []
    #
    # ATTENTION : la liste des variables est définies dans un environnement shell réduit cf: ciMonitor dans EoleCiFunctions.sh
    #

    def getEnv(self, key, default):
        valeur = os.getenv(key, default)
        if self.vmDebug > "0":
            print(key + "=" + valeur)
        return valeur
    
    def __init__(self):
        self.vmDebug = os.getenv('VM_DEBUG', '0')
        self.vmId = self.getEnv('VM_ID', '?')
        self.vmOne = self.getEnv('VM_ONE', '?')
        self.versionMajeur = self.getEnv('VM_VERSIONMAJEUR', '?')
        self.machine = self.getEnv('VM_MACHINE', '?')
        self.module = self.getEnv('VM_MODULE', '?')
        self.doGenRpt = self.getEnv('DO_GEN_RPT', 'oui')
        self.timeoutChaine = self.getEnv('VM_TIMEOUT', '600')
        self.configuration = self.getEnv('CONFIGURATION', 'default')
        self.strategieMajAuto = self.getEnv('VM_MAJAUTO', 'STABLE')
        self.utiliseConteneur = self.getEnv('VM_CONTAINER', 'non')
        self.etablissement = self.getEnv('VM_ETABLISSEMENT', '$')
        self.rne = self.getEnv('VM_NO_ETAB', '$')        
        self.getRneFromEtablissement()
        self.zephir = None
        try:
            self.tty8 = io.TextIOWrapper(
                            io.FileIO(
                                os.open(
                                    "/dev/tty8",
                                    os.O_NOCTTY | os.O_RDWR),
                                "w+"))
        except Exception:
            self.tty8 = None
        try:
            if self.module == "eclair":
                self.timeout = 2000
            else:
                self.timeout = int(self.timeoutChaine)
        except Exception:
            self.timeout = 600

    def println_err(self, texte):
        sys.stdout.flush()
        sys.stderr.write(texte + "\n")
        sys.stderr.flush()

    def println_monitor(self, texte):
        texte = "MONITOR: " + texte
        print("\n" + texte)
        if self.tty8 is not None:
            self.tty8.write(unicode(texte))
            self.tty8.write(unicode("\n"))

    def getRneFromEtablissement(self):
        if self.etablissement == 'aca':
            self.rne = '0000000A'
        elif self.etablissement == 'etb1':
            self.rne = '00000001'
        elif self.etablissement == 'etb2':
            self.rne = '00000002'
        elif self.etablissement == 'etb3':
            self.rne = '00000003'
        elif self.etablissement == 'etb4':
            self.rne = '00000004'
        elif self.etablissement == 'etb5':
            self.rne = '00000005'
        elif self.etablissement == 'etb6':
            self.rne = '00000006'
        elif self.etablissement == 'in':
            self.rne = '00000009'
        elif self.etablissement == 'rie':
            self.rne = '0000001A'
        elif self.etablissement == 'spc':
            self.rne = '00000011'
        elif self.etablissement == 'siegeNT1':
            self.rne = '00000012'
        elif self.etablissement == 'siegeNT2':
            self.rne = '00000013'
        elif self.etablissement == 'siegeAD1':
            self.rne = '00000014'
        elif self.etablissement == 'siegeAD2':
            self.rne = '00000015'
        elif self.etablissement == 'vut':
            self.rne = '00000016'
        elif self.rne == "":
            print("no etab vide !")
        elif self.rne != "$":
            print("no etab = " + self.rne)

    def setCommande(self, cmd1):
        self.commande = cmd1
        self.println_monitor(cmd1)

    def setTimeout(self, timeoutCmd):
        if timeoutCmd > self.timeout:
            self.timeout = timeoutCmd

    def setActions(self, specifique_actions):
        self.specifique_actions = specifique_actions

    def do_action(self, action):
        if action == "$FIN_UPGRADE_OK":
            self.println_monitor("FIN_UPGRADE_OK")
            self.ignorePexpectExit = True
            return 1

        elif action == "$IGNORE_EXIT":
            self.println_monitor("IGNORE_EXIT")
            self.ignorePexpectExit = True
            return -1

        elif action == "$FIN_OK":
            if self.tracebackDetecte:
                self.println_monitor("EXIT ERREUR TRACEBACK DETECTE")
                return 3
            elif self.erreur:
                self.println_monitor("EXIT ERREUR DETECTE")
                return 3
            else:
                return 0

        self.ignorePexpectExit = False
        if action == "$FAILED":
            self.println_monitor("failed")
            return 1
        elif action == "$TIMEOUT":
            self.println_monitor("apres timeout de " + str(self.timeout) + " secondes")
            return 2
        elif action == "$PASSWORD_EOLE":
            time.sleep(3)
            self.pexpectCommand.sendline('eole')
            time.sleep(1)
            self.pexpectCommand.sendline('eole')
            return -1
        elif action == "$PASSWORD_SAMBA4":
            time.sleep(3)
            self.pexpectCommand.sendline('Eole12345!')
            time.sleep(1)
            return -1
        elif action == "$PASSWORD_SAMBA4x2":
            time.sleep(3)
            self.pexpectCommand.sendline('Eole12345!')
            time.sleep(1)
            self.pexpectCommand.sendline('Eole12345!')
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
        elif action == "$ZEPHIR_DESINSCRIRE":
            # je dois memorise l'information, car l'applciation va quitter
            self.zephir_desincription = True
            self.pexpectCommand.sendline('1')
            return -1
        elif action == "$NO_RNE":
            print("\nMONITOR : NO RNE => " + self.rne)
            action = self.rne
        self.pexpectCommand.sendline(action)
        return -1

    def monitor_cmd(self):
        self.erreur = False
        self.tracebackDetecte = False
        self.pexpectCommand = pexpect.spawn(self.commande, ignore_sighup=False)
        self.pexpectCommand.delaybeforesend = 0.1
        # self.pexpectCommand.echo = False
        tables = [i[1] for i in expect_tables ]
        compiled_pattern_list = self.pexpectCommand.compile_pattern_list(tables)
        time.sleep(0.5)
        cdu = -1
        action_precedente = '$'
        while cdu == -1:
            index = self.pexpectCommand.expect_list(compiled_pattern_list, timeout=self.timeout)
            sys.stdout.flush()
            tag = expect_tables[index][0]
            action = expect_tables[index][2]
            repetition = expect_tables[index][3]
            for specifique_action in self.specifique_actions:
                if specifique_action[0] == tag:
                    action = specifique_action[1]
                    break
            if repetition == 'REPETITION_INTERDITE':
                if action_precedente == action:
                    self.println_monitor("ERREUR REPETITION ACTION:" + action + " RISQUE BOUCLE INFINIE ?")
                    cdu = -1
                    break

            if not self.nePasAfficherLesMessagesMonitor:
                self.println_monitor(tag + " action:" + action)
            action_precedente = action
            cdu = self.do_action(action)

        try:
            if cdu == 0:
                self.pexpectCommand.close()
            else:
                self.pexpectCommand.close(True)
        except Exception as e:
            self.println_monitor("Erreur ignorée ! : " + str(e))

        if self.ignorePexpectExit:
            self.println_monitor("Pexpect with ignorePexpectExit Exit=" + str(cdu) + ", PexpectExit=" + str(self.pexpectCommand.exitstatus) + ", Status=" + str(self.pexpectCommand.status) + ", Signalstatus=" + str(self.pexpectCommand.signalstatus))
            return 0
        if cdu != 0:
            self.println_monitor("Pexpect Exit=" + str(cdu) + ", PexpectExit=" + str(self.pexpectCommand.exitstatus) + ", Status=" + str(self.pexpectCommand.status) + ", Signalstatus=" + str(self.pexpectCommand.signalstatus))
            return cdu
        if self.pexpectCommand.exitstatus != 0:
            self.println_monitor("ATTENTION: Pexpect Exit=0, PexpectExit=" + str(self.pexpectCommand.exitstatus) + ", Status=" + str(self.pexpectCommand.status) + ", Signalstatus=" + str(self.pexpectCommand.signalstatus))
            return self.pexpectCommand.exitstatus
        return 0

    def getSourceMajAuto(self):

        majAutoArg = ''
        if self.versionMajeur == '2.3':
            if not os.path.isfile('/etc/eole/config.eol'):
                print("\nmonitor_maj_auto: pas de config.eol, donc utilise '-i' !")
                majAutoArg += ' -i'
            majAutoArg += ' -S test-eoleng.ac-dijon.fr -E '

        elif self.versionMajeur == '2.4':
            majAutoArg += ' -S test-eole.ac-dijon.fr '

        elif self.versionMajeur == '2.4.1':
            if os.path.isfile('/etc/eole/config.eol'):
                print("\nconfig.eol existe !")
            else:
                print("\nmonitor_maj_auto: pas de config.eol, donc utilise '-i' !")
                majAutoArg += ' -i'
            majAutoArg += ' -S test-eole.ac-dijon.fr '

        elif self.versionMajeur > '2.4.1':
            if os.path.isfile('/etc/eole/config.eol'):
                print("\nconfig.eol existe !")
            else:
                print("\nmonitor_maj_auto: pas de config.eol, donc utilise '-i' !")
                majAutoArg += ' -i'
            majAutoArg += ' -S test-eole.ac-dijon.fr -V test-eole.ac-dijon.fr '
        else:
            print("\nVersion non gérée dans 'monitor_eole_ci.py' ! " + self.versionMajeur)
            return None

        return majAutoArg

    def do_maj_auto(self, strategie):

        if self.utiliseConteneur == 'oui':
            self.setTimeout(1200)  # Attention : cela peut être tres long entre deux evenements/pattern ...
        else:
            self.setTimeout(600)

        majAutoArg = self.getSourceMajAuto()
        if majAutoArg is None:
            print("\nVersion non gérée dans 'monitor_eole_ci.py' ! " + self.versionMajeur)
            return 1

        if strategie == 'DEV':
            majAutoArg += ' -D'
        if strategie == 'RC':
            majAutoArg += ' -C'
        if strategie == 'STABLE':
            majAutoArg += ''
        if self.vmDebug > "0":
            majAutoArg += ' -d'

        self.setCommande('Maj-Auto ' + majAutoArg)
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("maj_auto")
        return cdu

    def monitor_query_auto(self, param1):
        majAutoArg = self.getSourceMajAuto()
        if majAutoArg is None:
            print("\nVersion non gérée dans 'monitor_eole_ci.py' ! " + self.versionMajeur)
            return 1

        majAutoArg += ' '.join(param1[1:])
        self.setCommande('Query-Auto ' + majAutoArg)
        cdu = self.monitor_cmd()
        return cdu

    def monitor_apt_eole(self, param1):
        argumentsAptEole = ' '.join(param1[1:])
        self.setCommande('apt-eole ' + argumentsAptEole)
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("apt-eole")
        return cdu

    def monitor_apt(self, param1):
        argumentsApt = ' '.join(param1[1:])
        self.setCommande('apt ' + argumentsApt)
        cdu = self.monitor_cmd()
        return cdu

    def monitor_maj_auto(self):
        return self.do_maj_auto(self.strategieMajAuto)

    def monitor_maj_auto_stable(self):
        return self.do_maj_auto("STABLE")

    def monitor_maj_auto_rc(self):
        return self.do_maj_auto("RC")

    def monitor_maj_auto_dev(self):
        return self.do_maj_auto("DEV")

    def monitor_instance(self):
        if self.versionMajeur == '2.3':
            self.setCommande('instance /etc/eole/config.eol')
        else:
            self.setCommande('instance')
        if self.machine == 'rie.esbl-ad':
            self.setActions([['esbl_003', 'ad'],
                             ['esbl_004', 'admin'],
                             ['esbl_006', '$PASSWORD_SAMBA4']])
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("instance")
        return cdu

    def monitor_reconfigure(self):
        if not os.path.isfile('/etc/eole/config.eol'):
            print ("\nPas de fichier /etc/config.eol ==> erreur")
            return 1

        self.setCommande('reconfigure')
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("reconfigure")
        return cdu

    def monitor_gen_rpt(self):
        if not os.path.isfile('/etc/eole/config.eol'):
            return 0
        if self.doGenRpt == "non":
            print ("gen_rpt désactivé !")
            return 0

        self.setCommande('gen_rpt_test.sh')
        # voir sauvegarde-fichier.sh !
        os.chdir("/tmp")
        self.nePasAfficherLesMessagesMonitor = True
        self.monitor_cmd()
        self.nePasAfficherLesMessagesMonitor = False
        # ignore cdu !
        return 0

    def sauvegarde_fichier(self, commandeInitiale):
        if commandeInitiale != "diagnose":
            self.monitor_gen_rpt()
        os.system("sauvegarde-fichier.sh " + commandeInitiale)

    def monitor_maj_release(self, args):
        if len(args) < 2:
            print ("\nPas de parametres à  monitor_maj_release ==> erreur")
            return 1

        release_target = args[1]
        current_release = self.versionMajeur

        # Current Release, Target releases, index
        all_releases = {
            '2.5.0->2.5.2': '1' ,
            '2.5.0->2.5.1': '2' ,

            '2.5.1->2.5.2': '1' ,

            '2.6.0->2.6.2': '1' ,
            '2.6.0->2.6.1': '2' ,

            '2.6.1->2.6.2': '1' ,

            '2.7.0->2.7.1': '1'
        }

        tag = current_release.strip() + "->" + release_target.strip()
        try:
            release_target_idx = all_releases[tag]
        except ValueError:
            # Current is not in list, keep all if 2.3
            print("\npas de Maj-Release '{0}'".format(tag))
            print("\nMauvaise version cible: '" + release_target + "' ne fait pas partie de " + str(all_releases))
            print("\nCorriger 'monitor_eole_ci.py'")
            return 1

        self.setCommande('Maj-Release')
        self.setActions([ [ 'maj_release_us', str(release_target_idx) ], [ 'maj_release_fr', str(release_target_idx) ] ])
        self.setTimeout(1200)  # Attention : cela peut être tres long entre deux evenements/pattern ...
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("upgrade_auto")
        return cdu

    def monitor_upgrade_auto(self, args):
        cdu = 1
        if len(args) < 1:
            print("\nPas de parametres à  monitor_upgrade_auto ==> erreur")
        else:
            try:
                # Current Release, Target releases, index
                all_releases = {
                    '2.6.2->2.7.1': '1',
                    '2.6.2->2.7.0': '2',

                    '2.5.2->2.6.2': '1',
                    '2.5.2->2.6.1': '2',
                    '2.5.2->2.6.0': '3',

                    '2.4.2->2.5.2': '1',
                    '2.4.2->2.5.1': '2',

                    '2.4.1->2.4.2': '1',

                    '2.4->2.4.2': '1',
                    '2.4->2.4.1': '2',

                    '2.3->2.4.2': '1',
                    '2.3->2.4.1': '2',
                    '2.3->2.4': '3',
                    '2.3->2.4.0': '3',
                    '2.3->2.4-dev': '4'
                }

                release_target = args[1]
                if len(args) > 2:
                    strategie = args[2]
                else:
                    strategie = "internet"
                tag = self.versionMajeur + "->" + release_target
                release_target_idx = all_releases[tag]
                if self.versionMajeur == '2.3':
                    self.setCommande('/usr/share/eole/Upgrade-Auto')
                    self.setActions([ [ 'upgrade_auto_version', str(release_target_idx) ] ])
                else:
                    if self.versionMajeur >= '2.4.2':
                        if strategie == "cdrom":
                            self.setCommande('Upgrade-Auto --release ' + release_target + ' --cdrom --force')
                            self.setActions([ [ 'upgrade_auto_001', str(release_target_idx) ] ])
                        else:
                            self.setCommande('Upgrade-Auto --release ' + release_target + ' --force --limit-rate 10m ')
                            self.setActions([ [ 'upgrade_auto_001', str(release_target_idx) ] ])
                    else:
                        self.setCommande('Upgrade-Auto')
                        self.setActions([ [ 'upgrade_auto_version', str(release_target_idx) ] ])
                self.setTimeout(1200)  # Attention : cela peut être tres long entre deux evenements/pattern ...
                cdu = self.monitor_cmd()
                if cdu != 0:
                    self.sauvegarde_fichier("upgrade_auto")
            except Exception:
                print("\nPas d'upgrade auto '{0}'".format(tag))
                print("\nMauvaise version cible: '" + release_target + "' ne fait pas partie de " + str(all_releases.keys()))
                print("\nCorriger 'monitor_eole_ci.py'")
                cdu = 1
        return cdu

    def monitor_diagnose(self):
        self.setCommande('diagnose -T')
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("diagnose")
        return cdu

    def monitor_sauvegarde(self):
        self.setCommande('sauvegarde.sh')
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("sauvegarde.sh")
        return cdu

    def monitor_restauration(self, args):
        self.setCommande('restauration.sh')
        if len(args) > 0:
            dateSauvegarde = args[1]
        else:
            dateSauvegarde = "01-01-2016"
        # restauration_001 sphynx
        # restauration_000 zephir
        self.setActions([ [ 'restauration_001', dateSauvegarde ], [ 'restauration_000', dateSauvegarde ] ])
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("restauration")
        return cdu

    def monitor_gen_conteneurs(self):
        if self.versionMajeur == '2.3':
            self.setCommande('/usr/bin/gen_conteneurs')
        else:
            if self.versionMajeur == '2.4':
                self.setCommande('/usr/share/eole/sbin/gen_conteneurs')
            else:
                self.setCommande('/usr/sbin/gen_conteneurs -v')

        self.setTimeout(3600)  # Attention : cela peut être tres long entre deux evenements/pattern ...
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("gen_conteneur")
        return cdu

    def monitor_zephir_enregistrement(self):
        self.initZephir()
        self.setCommande('enregistrement_zephir')
        self.setActions([ [ 'zephir_choix', '2' ], [ 'zephir_creer', 'O' ] ])
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("enregistrement_zephir")
        return cdu

    def monitor_zephir_enregistrement_testcharge(self):
        self.initZephir()
        serveurName = self.vmOne + "-" + self.vmId
        idServeur = self.getIdServeurName(serveurName)
        print("enregistrement_testcharge pour " + serveurName + " " + str(idServeur))
        if idServeur > 0:
            self.monitor_zephir_desinscrire()

        self.setCommande('enregistrement_zephir')
        self.setActions([ [ 'zephir_choix', '3' ],
                          [ 'zephir_creer', 'O' ],
                          [ 'zephir_libelle', serveurName ],
                          [ 'zephir_delai', '1' ] ]
                       )
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("enregistrement_zephir")
        return cdu

    def monitor_zephir_desinscrire(self):
        self.initZephir()
        self.setCommande('enregistrement_zephir')
        self.setActions([ [ 'zephir_choix1', '1' ],
                          [ 'zephir_logina', '' ] ]
                       )
        cdu = self.monitor_cmd()
        return cdu

    def monitor_enregistrement_domaine(self, args):
        current_release = self.versionMajeur
        # args = ['enregistrement_domaine', '', '', '', '', '', '']
        # attention aux args='' !
        if len(args) > 1:
            release_target = args[1]
        else:
            release_target = ''
        if release_target == '':
            release_target = self.versionMajeur
        print ("\nenregistrement_domaine, scribe version cible = " + release_target)
        self.setCommande('enregistrement_domaine.sh')
        if release_target > "2.8":
            self.setActions([ [ 'instance_amon_smb4a', '$PASSWORD_SAMBA4x2' ] ])
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("enregistrement_domaine")
        return cdu

    def monitor_onehost_create_all(self):
        self.setCommande('onehost_create_all')
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("onehost_create_all")
        return cdu

    def monitor_zephir_recupere_configuration(self):
        self.initZephir()
        idServeur = self.getIdServeur()
        self.setCommande('enregistrement_zephir')
        self.setActions([ [ 'zephir_choix', '2' ], [ 'zephir_id', str(idServeur) ] ])
        cdu = self.monitor_cmd()
        if self.zephir_desincription:
            self.setCommande('enregistrement_zephir')
            self.setActions([ [ 'zephir_choix', '2' ], [ 'zephir_id', str(idServeur) ] ])
            cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("enregistrement_zephir")
        return cdu

    def monitor_ssh(self, cmd):
        self.setCommande(cmd)
        cdu = self.monitor_cmd()
        return cdu

    def initZephir(self):
        import ssl

        # self.getEnv("CURL_CA_BUNDLE", "?" )
        # self.getEnv("REQUESTS_CA_BUNDLE", "?" )
        # self.getEnv("SSL_CERT_DIR", "?" )
        # self.getEnv("SSL_CERT_FILE", "?" )
        # print( "ssl version " + str( ssl.OPENSSL_VERSION) )
        # print( "ssl Paths " + str( ssl.get_default_verify_paths() ) )
        
        import xmlrpclib
        self.zephir = xmlrpclib.ServerProxy('https://admin_zephir:eole@zephir.ac-test.fr:7080')

    def getIdServeurName(self, serveur_name):
        criteres_selection = {'libelle': serveur_name}
        rc, groupe_serv = self.zephir.serveurs.groupe_serveur(criteres_selection)
        if rc == 0:
            self.println_err ('erreur xmlrpc')
            return 0

        if len(groupe_serv) == 0:
            self.println_err ('bizarre : ' + serveur_name + ' n existe pas !')
            return 0

        if len(groupe_serv) == 1:
            id_serveur = groupe_serv[0]['id']
        else:
            self.println_err ('bizarre : ' + serveur_name + ' renvoi plusieurs serveurs nb=' + str(len(groupe_serv)))
            id_serveur = groupe_serv[0]['id']
            self.println_err ('utilise le permier : ' + str(id_serveur))

        self.println_err (serveur_name + ': ' + str(id_serveur))
        return id_serveur

    def getIdServeur(self):
        if self.versionMajeur == '?':
            self.println_err('version inconnue')
            return 0
        if self.versionMajeur == '2.4.1h':
            self.versionMajeur = '2.4.1'
        self.println_err('Version: ' + self.versionMajeur)

        if self.machine == '?':
            self.println_err('machine inconnue')
            return 0
        self.println_err('Machine: ' + self.machine)
        self.println_err('Configuration: ' + self.configuration)
        serveur_name = self.machine + '-' + self.configuration + '-' + self.versionMajeur
        return self.getIdServeurName(serveur_name)


def printusage():
    print ('Usage : python monitor_eole_ci.py <cmd> [<arg1> [<arg2> ... ]]')
    print ('Avec pour <cmd> :  ')
    print ('     diagnose')
    print ('     gen_conteneurs')
    print ('     gen_rpt')
    print ('     instance')
    print ('     query_auto <options> ')
    print ('     maj_auto')
    print ('     maj_auto_dev')
    print ('     maj_auto_rc')
    print ('     maj_auto_stable')
    print ('     maj_release      <versionCible>')
    print ('     reconfigure')
    print ('     restauration     <date>')
    print ('     sauvegarde')
    print ('     upgrade_auto     <versionCible>')
    print ('     zephir_desinscrire')
    print ('     zephir_enregistrement')
    print ('     zephir_enregistrement_testcharge')
    print ('     zephir_recupere_configuration')
    print ('     enregistrement_domaine [<versionCible>]')
    print ('     ssh <command>')
    print ('     scp <source> <destination>')


if __name__ == '__main__':
    if len(sys.argv) == 1:
        printusage()
        sys.exit(1)
    cmd = sys.argv[1]
    param = sys.argv[1:]  # je mets 'cmd' en 1er ==> equivalent a sys.argv !
    monitor = MonitorEoleCi()
    # print ('pexpect version : ' + str( sys.modules['pexpect'] ) )
    if cmd == 'instance':
        monitorExitCode = monitor.monitor_instance()
    elif cmd == 'diagnose':
        monitorExitCode = monitor.monitor_diagnose()
    elif cmd == 'gen_conteneurs':
        monitorExitCode = monitor.monitor_gen_conteneurs()
    elif cmd == 'zephir_recupere_configuration':
        monitorExitCode = monitor.monitor_zephir_recupere_configuration()
    elif cmd == 'zephir_desinscrire':
        monitorExitCode = monitor.monitor_zephir_desinscrire()
    elif cmd == 'sauvegarde':
        monitorExitCode = monitor.monitor_sauvegarde()
    elif cmd == 'reconfigure':
        monitorExitCode = monitor.monitor_reconfigure()
    elif cmd == 'query_auto':
        monitorExitCode = monitor.monitor_query_auto(param)
    elif cmd == 'apt':
        monitorExitCode = monitor.monitor_apt(param)
    elif cmd == 'maj_auto':
        monitorExitCode = monitor.monitor_maj_auto()
    elif cmd == 'maj_auto_stable':
        monitorExitCode = monitor.monitor_maj_auto_stable()
    elif cmd == 'maj_auto_rc_reconfigure':
        monitorExitCode = monitor.monitor_maj_auto_rc()
    elif cmd == 'maj_auto_rc':
        monitorExitCode = monitor.monitor_maj_auto_rc()
    elif cmd == 'maj_auto_dev':
        monitorExitCode = monitor.monitor_maj_auto_dev()
    elif cmd == 'gen_rpt':
        monitorExitCode = monitor.monitor_gen_rpt()
    elif cmd == 'zephir_enregistrement_testcharge':
        monitorExitCode = monitor.monitor_zephir_enregistrement_testcharge()
    elif cmd == 'zephir_enregistrement':
        monitorExitCode = monitor.monitor_zephir_enregistrement()
    elif cmd == 'apt_eole':
        monitorExitCode = monitor.monitor_apt_eole(param)
    elif cmd == 'upgrade_auto':
        monitorExitCode = monitor.monitor_upgrade_auto(param)
    elif cmd == 'restauration':
        monitorExitCode = monitor.monitor_restauration(param)
    elif cmd == 'maj_release':
        monitorExitCode = monitor.monitor_maj_release(param)
    elif cmd == 'enregistrement_domaine':
        monitorExitCode = monitor.monitor_enregistrement_domaine(param)
    elif cmd == 'onehost_create_all':
        monitorExitCode = monitor.monitor_onehost_create_all()
    elif cmd in ['ssh', 'scp']:
        monitorExitCode = monitor.monitor_ssh(' '.join(param))
    else:
        monitorExitCode = 1
        print ("commande '%s' inconnue." % cmd)
        printusage()
    sys.stdout.flush()
    sys.stderr.flush()
    sys.exit(monitorExitCode)
