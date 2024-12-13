#!/usr/bin/python3
# coding: utf-8
# pep8: --ignore=E201,E202,E211,E501
# pylint: disable=C0301,C0103,C0111,E0213,C0302,C0203,W0703,C0325,R0902,R0904,R0912,R0911

import io
import os
import platform
import sys
import time
import json
from traceback import print_exc
import pexpect

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
    [ 'instance_amon_smb4'   , r"Entrer le mot de passe de l'administrateur du contr.*leur de domaine"         , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'instance_amonecole'   , r"Mot de passe de l'administrateur du contr.*leur de domaine \(Administrator\) ", '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'instance_amon_smb4a'  , r"Mot de passe de l'administrateur du contr.*leur de domaine :"                 , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'instance_rearme'      , r"Start Systemd services"                                                       , '$REARME', 'REPETITION_OK'],
    [ 'instance_rearme1'     , r"des scripts posttemplate"                                                     , '$REARME', 'REPETITION_OK'],
    [ 'gen_conteneur_addc'   , r"Génération du conteneur addc"                                                 , '$REARME', 'REPETITION_OK'],
    [ 'envoi_materiel'       , r"Pour enrichir cette base, acceptez-vous l'envoi de la description "           , 'non', 'REPETITION_OK'],
    [ 'detruire_ldap'        , r"l'annuaire LDAP \(attention"                                                  , 'non', 'REPETITION_OK'],
    [ 'admin_eole1'          , r"un nouvel administrateur eole1"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_eole2'          , r"un nouvel administrateur eole2"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_eole3'          , r"un nouvel administrateur eole3"                                               , 'non', 'REPETITION_OK'],
    [ 'admin_samba'          , r"Changement du mot de passe de l'utilisateur \"admin\""                        , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'admin_samba_23'       , r"New passwords don't match!"                                                   , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe_root'    , r"Changement du mot de passe de l'utilisateur root"                             , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe_root24'  , r"Changement du mot de passe pour l'utilisateur"                                , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe_eole'    , r"Changement du mot de passe de l'utilisateur eole"                             , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe'         , r"Changement du mot de passe"                                                   , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe_replay'  , r"Nouveau mot de passe \(2/5\)"                                                 , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'mot_de_passe_us'      , r"Enter new UNIX password"                                                      , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
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
    [ 'maj_auto_long_time'   , r"Updating certificates in /etc/ssl/certs"                                     , '$REARME', 'REPETITION_OK'],
    [ 'upgrade_auto_cert'    , r"Voulez-vous remplacer l'ancien certificat auto-signé ?"                      , 'oui', 'REPETITION_OK'],
    [ 'inst_zephir_recreate' , r"Voulez-vous re-créer les utilisateurs et données de base"                     , '', 'REPETITION_OK'],
    [ 'inst_zephir_password' , r"Initialisation du mot de passe de l'administrateur de base \(admin_zephir\)"  , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'inst_zephir_new_user' , r"nom d'utilisateur a créer"                                                    , '', 'REPETITION_OK'],
    [ 'reinit_esu_faute'     , r"Voulez vous réinitaliser la base ESU"                                         , 'non', 'REPETITION_OK'],
    [ 'reinit_esu'           , r"Voulez vous réinitialiser la base ESU"                                        , 'non', 'REPETITION_OK'],
    [ 'reinit_esu_001'       , r"Voulez-vous réinitialiser la base ESU"                                        , 'non', 'REPETITION_OK'],
    [ 'instance_rvp'         , r"Voulez-vous \(re\)configurer le Réseau Virtuel Privé maintenant"              , 'non', 'REPETITION_OK'],
    [ 'instance_rvp_23'      , r"Voulez-vous configurer le Réseau Virtuel Privé maintenant"                    , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , r"Voulez-vous \(re\)configurer la haute disponibilité"                          , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , r"Voulez-vous synchroniser les noeuds"                                          , 'non', 'REPETITION_OK'],
    [ 'instance_ha'          , r"Voulez-vous attendre que le script synchro-nodes.sh soit exécuté"             , 'non', 'REPETITION_OK'],
    [ 'maj_auto_23'          , r"Ces paquets ne sont pas classés Stables"                                      , 'oui', 'REPETITION_OK'],
    [ 'mot_de_passe_23'      , r"Entrez le nouveau mot de passe UNIX"                                          , '$PASSWORD_EOLEx2', 'REPETITION_OK'],
    [ 'instance_arv_23'      , r"Voulez-vous réinitialiser la base ARV et perdre vos modifications"            , 'non', 'REPETITION_OK'],
    [ 'zephir_mini'          , r"oulez-vous établir une configuration réseau minimale \(O/N\)"                 , 'N', 'REPETITION_OK'],
    [ 'zephir_ip'            , r"Entrez l'adresse du serveur "                                                 , 'zephir.ac-test.fr', 'REPETITION_OK'],
    [ 'zephir_ip1'           , r"Entrez l'adresse \(nom DNS\) du serveur "                                     , 'zephir.ac-test.fr', 'REPETITION_OK'],
    [ 'zephir_login'         , r"Entrez votre login pour l'application Zéphir \(rien pour sortir\) :"          , 'admin_zephir', 'REPETITION_OK'],
    [ 'zephir_logina'        , r"Entrez votre login zephir \(rien pour sortir\) :"                             , 'admin_zephir', 'REPETITION_OK'],
    [ 'zephir_passwd'        , r"Mot de passe pour l'application Zéphir pour"                                  , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'zephir_passwda'       , r"Mot de passe zephir pour "                                                    , '$PASSWORD_EOLE', 'REPETITION_OK'],
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
    # [ 'genconteneur_002'     , "-\\\|/"                                                                       , 'oui', 'REPETITION_OK'],
    [ 'genconteneur_003'     , r"Le cache LXC est déjà présent, voulez-vous le re-créer"                       , 'non', 'REPETITION_OK'],
    [ 'genconteneur_004'     , r"Le cache LXC est déjà présent, voulez-vous le supprimer ?"                    , 'non', 'REPETITION_OK'],
    [ 'upgrade_auto_confirm' , r"va effectuer la migration vers une nouvelle version de la distribution"       , 'oui', 'REPETITION_OK'],
    [ 'upgrade_auto_version' , r"Version de la 2.4"                                                            , '', 'REPETITION_OK'],
    [ 'upgrade_auto_001'     , r"Which version do you want to upgrade to"                                      , '1', 'REPETITION_OK'],
    [ 'upgrade_auto_002'     , r"Upgrade-Auto est actuellement en version"                                     , 'oui', 'REPETITION_OK'],
    [ 'upgrade_auto_003'     , r"Forcer la migration malgré tout"                                              , 'oui', 'REPETITION_OK'],
    [ 'upgrade_auto_zephir'  , r"La configuration de migration n'a pas été préparée sur le serveur Zéphir"     , '', 'REPETITION_OK'],
    [ 'maj_release_us'       , r"This script will upgrade to a new release"                                    , '', 'REPETITION_OK'],
    [ 'maj_release_fr'       , r"Ce script va effectuer la migration vers une nouvelle version mineure de"     , '', 'REPETITION_OK'],
    [ 'upgrade_erreur'       , r"Réponse invalide"                                                             , '$ERREUR', 'REPETITION_OK'],
    [ 'upgrade_fin'          , r"exécuter la commande 'instance'"                                              , '$FIN_UPGRADE_OK', 'REPETITION_OK'],
    [ 'upgrade_fin2'         , r"Ecriture sur les serveurs et les modules"                                     , '$FIN_UPGRADE_OK', 'REPETITION_OK'],
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
    [ 'addc_0005'            , r"root@192.168.0.5's password:"                                                 , '$PASSWORD_EOLE', 'REPETITION_INTERDITE'],
    [ 'addc_0005a'           , r"root@10.1.3.6's password:"                                                    , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'addc_0006'            , r"Active Directory .Administrator. password"                                    , '$PASSWORD_SAMBA4x2', 'REPETITION_OK'],
    [ 'addc_0006a'           , r"Création du mot de passe .Administrator. Active Directory"                    , '$PASSWORD_SAMBA4x2', 'REPETITION_OK'],
    [ 'addc_0007'            , r"Active Directory .admin. password"                                            , '$PASSWORD_SAMBA4x2', 'REPETITION_OK'],
    [ 'addc_0007a'           , r"Création du mot de passe .admin. Active Directory"                            , '$PASSWORD_SAMBA4x2', 'REPETITION_OK'],
    [ 'addc_0008'            , r"Compte pour joindre le serveur au domaine"                                    , '$ACCOUNT_SAMBA4', 'REPETITION_INTERDITE'],
    [ 'addc_0009'            , r"Mot de passe de jonction au domaine"                                          , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
    [ 'wsad_0001'            , r"Le DC 192.168.0.73 est déclaré comme 'windows'"                               , "$SELECT_ACCOUNT_WSAD", 'REPETITION_OK'],
    [ 'wsad_0002'            , r"Horloge synchronisée sur 192.168.0.73"                                        , "$SELECT_ACCOUNT_WSAD", 'REPETITION_OK'],
    [ 'hapy_0001'            , r"Initialisation du mot de passe .* interface Web Sunstone"                     , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'hapy_0002'            , r"Entrez le nouveau mot de passe"                                               , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'hapy_0003'            , r"Retapez le nouveau mot de passe"                                              , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'hapy_0004'            , r"Do you want to proceed"                                                       , 'Y', 'REPETITION_OK'],
    [ 'hapy_0004f'           , r"Voulez-vous commencer ?"                                                      , 'Y', 'REPETITION_OK'],
    [ 'hapy_0005'            , r"root@hapy-node's password:"                                                   , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'hapy_deploiement'     , r"Voulez-vous lancer le déploiement automatique des machines virtuelles"        , 'O', 'REPETITION_OK'],
    [ 'hapy_deploiement_cred', r"Voulez-vous retenir ces identifiants"                                         , 'O', 'REPETITION_OK'],
    [ 'hapy_deploiement_crea', r"Création des machines virtuelles"                                             , '$REARME', 'REPETITION_OK'],
    [ 'ssh_passwd_eole'      , r"root@[^']+'s password:"                                                       , '$PASSWORD_EOLE', 'REPETITION_OK'],
    [ 'ssh_c31e1_eole'       , r"c31e1@[^']+'s password:"                                                       , '$PASSWORD_EOLE', 'REPETITION_OK'],
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
    [ 'hapyauto_001'         , r"Attente démarrage provisionning"                                              , '$DISABLE_MONITOR', 'REPETITION_OK'],
    [ 'hapyauto_002'         , r"instanceUnattended: TAG=EOF"                                                  , '$ENABLE_MONITOR', 'REPETITION_OK'],
    [ 'hapyauto_003'         , r"fin du provisionning OK"                                                      , '$ENABLE_MONITOR', 'REPETITION_OK'],
    # pb GPO/kerberos     [ 'scribead_003'         , r"Enregistrement du GPO EOLE"                                                   , '$PASSWORD_SAMBA4', 'REPETITION_OK'],
]

# Exemple de fichier json UNATTENDED_FILE
# [
#    {
#        "tag": "manquant",
#        "pattern": "Fichier ",
#        "action": "azeaze"
#    },
#    {
#        "tag": "addc_0008",
#        "action": "$PASSWORD_SAMBA4"
#    }
#]

EXPECT_CONTINUE=-1
EXPECT_STOP_OK=0
EXPECT_STOP_FAILED=1
EXPECT_STOP_TIMEOUT=2
EXPECT_STOP_TRACEBACK=3
EXPECT_DO_ACTION=4

def trace_calls(frame, event, arg):
    if event != 'call':
        return
    co = frame.f_code
    func_name = co.co_name
    if func_name == 'write':
        # Ignore write() calls from print statements
        return
    func_line_no = frame.f_lineno
    func_filename = co.co_filename
    caller = frame.f_back
    caller_line_no = caller.f_lineno
    caller_filename = caller.f_code.co_filename
    print ("[%s:%s]%s from line %s of %s" % (func_filename, func_line_no, func_name, caller_line_no, caller_filename))
    # print 'Call to %s on line %s of %s' % (func_name, line_no, filename)
    # if func_name in TRACE_INTO:
    #    # Trace into this function
    #    return trace_lines
    return


class MonitorEoleCi(object):
    pwd_eole = 'eole'
    account_samba4 = ''  # default
    pwd_samba4 = 'Eole12345!'
    erreur = False
    tracebackDetecte = False
    ignorePexpectExit = False
    enableMonitor = True
    nePasAfficherLesMessagesMonitor = False
    commande = None
    env = None
    pexpectCommand = None
    zephir_desincription = False
    specifique_actions = []
    unattended_file = None
    #
    # ATTENTION : la liste des variables est définies dans un environnement shell réduit cf: ciMonitor dans EoleCiFunctions.sh
    #

    def println_err(self, texte):
        sys.stdout.flush()
        sys.stderr.write(str(texte) + "\n")
        sys.stderr.flush()

    def getEnv(self, key, default):
        valeur = os.getenv(key, default)
        if valeur == "":
            valeur = default
            if self.vmDebug > "0":
                self.println_err(key + "=" + default + " (default)")
        else:
            if self.vmDebug > "0":
                self.println_err(key + "=" + valeur)
        return valeur

    def __init__(self):
        self.tty8 = None
        self.vmDebug = os.getenv('VM_DEBUG', '0')
        self.vmId = self.getEnv('VM_ID', '?')
        self.vmOwner = self.getEnv('VM_OWNER', '?')
        self.vmOne = self.getEnv('VM_ONE', '?')
        self.versionMajeur = self.getEnv('VM_VERSIONMAJEUR', '?')
        self.machine = self.getEnv('VM_MACHINE', '?')
        self.freshinstall_module = self.getEnv('FRESHINSTALL_MODULE', '?')
        self.module = self.getEnv('VM_MODULE', '?' )
        if self.module == "?":
            self.module = self.freshinstall_module
        self.doGenRpt = self.getEnv('DO_GEN_RPT', 'oui')
        self.timeoutChaine = self.getEnv('VM_TIMEOUT', '600')
        self.configuration = self.getEnv('CONFIGURATION', 'default')
        self.strategieMajAuto = self.getEnv('VM_MAJAUTO', 'STABLE')
        self.utiliseConteneur = self.getEnv('VM_CONTAINER', 'non')
        self.etablissement = self.getEnv('VM_ETABLISSEMENT', '$')
        self.unattended_file = self.getEnv('UNATTENDED_FILE', "/root/unattended.eol")
        self.rne = self.getEnv('VM_NO_ETAB', '$')
        self.getRneFromEtablissement()
        self.zephir = None
        try:
            self.tty8 = io.TextIOWrapper( io.FileIO(os.open( "/dev/tty8", os.O_NOCTTY | os.O_RDWR), "w+"))
        except Exception:
            self.tty8 = None
        try:
            if self.module == "eclair":
                self.timeout = 2000
            else:
                self.timeout = int(self.timeoutChaine)
        except Exception:
            self.timeout = 600

    def println_monitor(self, texte):
        texte = "MONITOR: " + texte
        self.println_err("\n" + texte)
        if self.tty8 is not None:
            self.tty8.write(texte)
            self.tty8.write("\n")

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
            self.println_err("no etab vide !")
        elif self.rne != "$":
            self.println_err("no etab = " + self.rne)

    def setCommande(self, cmd1):
        self.commande = cmd1
        self.println_monitor(cmd1)

    def setTimeout(self, timeoutCmd):
        if timeoutCmd > self.timeout:
            self.timeout = timeoutCmd

    def setActions(self, specifique_actions):
        self.specifique_actions = specifique_actions

    def do_sendline(self, texte):
        if self.enableMonitor == False:
            self.println_monitor("ERREUR: monitor_eole_ci4,ne pas appeler 'do_sendline' avec Monitor désactivé")
        else:
            self.pexpectCommand.sendline(texte)

    def do_action_passive(self, action):
        if action == "$FIN_UPGRADE_OK":
            self.println_monitor("FIN_UPGRADE_OK")
            self.ignorePexpectExit = True
            return EXPECT_STOP_FAILED

        elif action == "$IGNORE_EXIT":
            self.println_monitor("IGNORE_EXIT")
            self.ignorePexpectExit = True
            return EXPECT_CONTINUE

        elif action == "$FIN_OK":
            if self.tracebackDetecte:
                self.println_monitor("EXIT ERREUR TRACEBACK DETECTE")
                return EXPECT_STOP_TRACEBACK
            elif self.erreur:
                self.println_monitor("EXIT ERREUR DETECTE")
                return EXPECT_STOP_TRACEBACK
            else:
                return EXPECT_STOP_OK

        self.ignorePexpectExit = False
        if action == "$FAILED":
            self.println_monitor("failed")
            return EXPECT_STOP_FAILED
        elif action == "$TIMEOUT":
            self.println_monitor("apres timeout de " + str(self.timeout) + " secondes")
            return EXPECT_STOP_TIMEOUT
        elif action == "$SELECT_ACCOUNT_WSAD":
            self.account_samba4 = 'Administrateur'
            self.pwd_samba4 = 'Eole12345!'
            self.println_monitor("switch to " + self.account_samba4 + "%" + self.pwd_samba4)
            time.sleep(1)
            return EXPECT_CONTINUE
        elif action == "$TRACEBACK":
            self.tracebackDetecte = True
            return EXPECT_CONTINUE
        elif action == "$ERREUR":
            self.erreur = True
            return EXPECT_CONTINUE
        elif action == "$REARME":
            return EXPECT_CONTINUE
        elif action == "$PAUSE":
            time.sleep(10)
            return EXPECT_CONTINUE
        elif action == "$ENABLE_MONITOR":
            self.println_monitor("Instance dans instance => ENABLE_MONITOR")
            self.enableMonitor = True
            return EXPECT_CONTINUE
        elif action == "$DISABLE_MONITOR":
            self.println_monitor("Instance dans instance => DISABLE_MONITOR")
            self.enableMonitor = False
            return EXPECT_CONTINUE
        return 4 # continue

    def do_action_active(self, action):

        if action == "$PASSWORD_EOLE":
            time.sleep(5)
            self.do_sendline(self.pwd_eole)
            return EXPECT_CONTINUE
        elif action == "$PASSWORD_EOLEx2":
            time.sleep(5)
            self.do_sendline(self.pwd_eole)
            time.sleep(1)
            self.do_sendline(self.pwd_eole)
            return EXPECT_CONTINUE
        elif action == "$ACCOUNT_SAMBA4":
            time.sleep(5)
            self.do_sendline(self.account_samba4)
            time.sleep(1)
            return EXPECT_CONTINUE
        elif action == "$PASSWORD_SAMBA4":
            time.sleep(5)
            self.do_sendline(self.pwd_samba4)
            time.sleep(1)
            return EXPECT_CONTINUE
        elif action == "$PASSWORD_SAMBA4x2":
            time.sleep(5)
            self.do_sendline(self.pwd_samba4)
            time.sleep(1)
            self.do_sendline(self.pwd_samba4)
            return EXPECT_CONTINUE
        elif action == "$ACCOUNT_WSAD":
            self.account_samba4 = 'Administrateur'
            self.do_sendline(self.account_samba4)
            time.sleep(1)
            return EXPECT_CONTINUE
        elif action == "$PASSWORD_WSAD":
            time.sleep(5)
            self.do_sendline(self.pwd_samba4)
            time.sleep(1)
            return EXPECT_CONTINUE
        elif action == "$PASSWORD_WSADx2":
            time.sleep(5)
            self.do_sendline(self.pwd_samba4)
            time.sleep(1)
            self.do_sendline(self.pwd_samba4)
            return EXPECT_CONTINUE
        elif action == "$ZEPHIR_DESINSCRIRE":
            # je dois memorise l'information, car l'applciation va quitter
            self.zephir_desincription = True
            self.do_sendline('1')
            return EXPECT_CONTINUE
        elif action == "$NO_RNE":
            self.println_monitor("NO RNE => " + self.rne)
            self.do_sendline(self.rne)
            return EXPECT_CONTINUE
        self.do_sendline(action)
        return EXPECT_CONTINUE

    def monitor_cmd(self):
        self.erreur = False
        self.tracebackDetecte = False
        # , timeout=self.timeout il est global !
        self.pexpectCommand = pexpect.spawn(self.commande, ignore_sighup=False, maxread=200, encoding='utf-8', echo=False, env=self.env, logfile=sys.stdout,)
        self.pexpectCommand.delaybeforesend = 1 # see.: https://pexpect.readthedocs.io/en/stable/commonissues.html#timing-issue-with-send-and-sendline
        #self.pexpectCommand.logfile_read = sys.stdout # desactive les caractères émis STDIN
        # self.pexpectCommand.echo = False

        if os.path.isfile(self.unattended_file):
            print ("ATTENTION: Charge '" + self.unattended_file + "'")
            with open(self.unattended_file) as file:
                for reponse in json.load( file ):
                    tag = reponse[ 'tag' ] if 'tag' in reponse else None
                    trouve = False
                    for expect_record in expect_tables:
                        if expect_record[0] == tag:
                            trouve = True
                            if 'pattern' in reponse:
                                expect_record[1] = reponse[ 'pattern' ]
                            if 'action' in reponse:
                                expect_record[2] = reponse[ 'action' ]
                            if 'repeat' in reponse:
                                expect_record[3] = reponse[ 'repeat' ]
                            print ("Surcharge     : " + str(expect_record))
                            break

                    if not trouve:
                        if 'pattern' in reponse:
                            pattern = reponse[ 'pattern' ]
                            action = reponse[ 'action' ] if 'action' in reponse else ''  # = ENTER
                            repeat = reponse[ 'repeat' ] if 'repeat' in reponse else 'REPETITION_OK'
                            expect_record = [tag, pattern, action, repeat ]
                            expect_tables.append(expect_record)
                            print ("Ajout pattern : " + str(expect_record))
                        else:
                            print ("pas de 'pattern' pour le tag '" + tag + "' ignore")

        tables = [i[1] for i in expect_tables ]

        compiled_pattern_list = self.pexpectCommand.compile_pattern_list(tables)
        time.sleep(0.5)
        cdu = EXPECT_CONTINUE
        action_precedente = '$'
        action_precedente1 = '$'
        self.enableMonitor = True
        while cdu == EXPECT_CONTINUE:
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

            cdu = self.do_action_passive(action)
            if cdu == EXPECT_DO_ACTION:
                cdu = EXPECT_CONTINUE # continue
                if self.enableMonitor:
                    if repetition == 'REPETITION_INTERDITE':
                        if action_precedente == action:
                            self.println_monitor(tag + " action:" + action)
                            self.println_monitor("ERREUR REPETITION ACTION:" + action + " RISQUE BOUCLE INFINIE ?")
                            cdu = EXPECT_CONTINUE
                            break
                        if action_precedente1 == action:
                            self.println_monitor(tag + " action:" + action)
                            self.println_monitor("ERREUR REPETITION ACTION:" + action + " RISQUE BOUCLE INFINIE ?")
                            cdu = EXPECT_CONTINUE
                            break

                    if not self.nePasAfficherLesMessagesMonitor and self.enableMonitor:
                        self.println_monitor(tag + " action:" + action)
                    action_precedente1 = action_precedente
                    action_precedente = action
                    cdu = self.do_action_active(action)

        try:
            if cdu == EXPECT_STOP_OK:
                self.pexpectCommand.close()
            else:
                self.pexpectCommand.close(True)
        except Exception as e:
            self.println_monitor("Erreur ignorée ! : " + str(e))

        if self.ignorePexpectExit:
            self.println_monitor("Pexpect with ignorePexpectExit Exit=" + str(cdu) + ", PexpectExit=" + str(self.pexpectCommand.exitstatus) + ", Status=" + str(self.pexpectCommand.status) + ", Signalstatus=" + str(self.pexpectCommand.signalstatus))
            return 0
        if cdu != EXPECT_STOP_OK:
            self.println_monitor("Pexpect Exit=" + str(cdu) + ", PexpectExit=" + str(self.pexpectCommand.exitstatus) + ", Status=" + str(self.pexpectCommand.status) + ", Signalstatus=" + str(self.pexpectCommand.signalstatus))
            return cdu
        if self.pexpectCommand.exitstatus != 0:
            self.println_monitor("ATTENTION: Pexpect Exit=0, PexpectExit=" + str(self.pexpectCommand.exitstatus) + ", Status=" + str(self.pexpectCommand.status) + ", Signalstatus=" + str(self.pexpectCommand.signalstatus))
            return self.pexpectCommand.exitstatus
        return 0

    def getSourceMajAuto(self):
        majAutoArg = ''
        if self.compare_version( '2.3' ) == 0:
            if not os.path.isfile('/etc/eole/config.eol'):
                self.println_err("\nmonitor_maj_auto: pas de config.eol, donc utilise '-i' !")
                majAutoArg += ' -i'
            majAutoArg += ' -S test-eoleng.ac-dijon.fr -E '

        elif self.compare_version( '2.4' ) == 0:
            majAutoArg += ' -S test-eole.ac-dijon.fr '

        elif self.compare_version( '2.4.1') == 0:
            if os.path.isfile('/etc/eole/config.eol'):
                self.println_err("\nconfig.eol existe !")
            else:
                self.println_err("\nmonitor_maj_auto: pas de config.eol, donc utilise '-i' !")
                majAutoArg += ' -i'
            majAutoArg += ' -S test-eole.ac-dijon.fr '

        elif self.compare_version( '2.4.1' ) > 0:
            if os.path.isfile('/etc/eole/config.eol'):
                self.println_err("\nconfig.eol existe !")
            else:
                self.println_err("\nmonitor_maj_auto: pas de config.eol, donc utilise '-i' !")
                majAutoArg += ' -i'
            majAutoArg += ' -S test-eole.ac-dijon.fr -V test-eole.ac-dijon.fr '
        else:
            self.println_err("\nVersion non gérée dans 'monitor_eole_ci.py' ! " + self.versionMajeur)
            return None

        return majAutoArg

    def do_maj_auto(self, strategie):

        if self.utiliseConteneur == 'oui':
            self.setTimeout(1200)  # Attention : cela peut être tres long entre deux evenements/pattern ...
        else:
            self.setTimeout(600)

        majAutoDepots = self.getSourceMajAuto()
        if majAutoDepots is None:
            self.println_err("\nVersion non gérée dans 'monitor_eole_ci.py' ! " + self.versionMajeur)
            return 1

        majAutoArg = majAutoDepots
        if strategie == 'DEV':
            majAutoArg += ' -D'
        if strategie == 'RC':
            majAutoArg += ' -C'
        if strategie == 'STABLE':
            majAutoArg += ''
        if self.vmDebug > "0":
            majAutoArg += ' -d'

        if self.compare_version( '3.0' ) == 0:
            if platform.system() != 'Linux':
                self.setCommande('pkg update')
                self.monitor_cmd()
                self.setCommande('pkg upgrade -y')
                self.monitor_cmd()
            else:
                self.env = {'LANG': 'C', 'DEBIAN_FRONTEND': 'noninteractive' }
                self.setCommande('apt-get update')
                self.monitor_cmd()
                self.setCommande('apt-get upgrade -y')
                self.monitor_cmd()
                self.env = None
        else:
            self.setCommande('Maj-Auto ' + majAutoArg)
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("maj_auto")
            return cdu

        if os.path.isfile('/usr/share/eole/creole/dicos/20_web.xml') and self.compare_version ('2.7.1') > 0:
            #dépôts "unstable" pour Envole #33075
            majAutoArg = majAutoDepots
            if strategie == 'DEV':
                # "-D eole -D envole" impossible
                majAutoArg += ' -D'
            else:
                majAutoArg += ' -C eole'
                majAutoArg += ' -D envole'
            self.setCommande('Maj-Auto ' + majAutoArg)
            cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("maj_auto")
        return cdu

    def monitor_query_auto(self, param1):
        majAutoArg = self.getSourceMajAuto()
        if majAutoArg is None:
            self.println_err("\nVersion non gérée dans 'monitor_eole_ci.py' ! " + self.versionMajeur)
            return 1

        majAutoArg += ' '.join(param1[1:])
        if self.compare_version( '3.0' ) == 0:
            if platform.system() != 'Linux':
                self.setCommande('pkg available')
            else:
                self.setCommande('apt-get update')
        else:
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
        if self.utiliseConteneur == 'oui':
            self.setTimeout(1200)  # Attention : cela peut être tres long entre deux evenements/pattern ...
        else:
            self.setTimeout(600)

        # pas de -S --> utilise eole.ac-dijon.fr et pas test-eole !
        majAutoArg = ' -C '
        if self.vmDebug > "0":
            majAutoArg += ' -d'
        self.setCommande('Maj-Auto ' + majAutoArg)
        return self.monitor_cmd()

    def monitor_maj_auto_rc(self):
        return self.do_maj_auto("RC")

    def monitor_maj_auto_dev(self):
        return self.do_maj_auto("DEV")

    def compare_version(self, withVersion, fromVersion=''):
        """
        retourne une valeur négative si versionMajeur (ou fromVersion) < withVersion
        retourne zéro si versionMajeur (ou fromVersion) = withVersion
        retourne une valeur positive si versionMajeur (ou fromVersion) > withVersion
        """
        if self.versionMajeur == '?':
            self.println_err('version inconnue')
            return -1
    
        if fromVersion == '':
            vmCible=self.versionMajeur.split('.')
        else:
            vmCible=fromVersion.split('.')
        vmATester=withVersion.split('.')
        for i in range(0, 3):
            if i >= len(vmCible):
                cible=0
            else:
                cible=int(vmCible[i])
            if i >= len(vmATester):
                atester=0
            else:
                atester=int(vmATester[i])
            delta = cible - atester
            if delta != 0:
                return delta
        return 0
        
    def monitor_instance(self):
        if self.compare_version( '2.3' ) == 0:
            self.setCommande('instance /etc/eole/config.eol')
        else:
            self.setCommande('instance')
        if self.machine == 'rie.esbl-ad':
            self.setActions([['esbl_003', 'ad'],
                             ['esbl_004', 'admin'],
                             ['esbl_006', '$PASSWORD_SAMBA4']])
        if self.compare_version( '2.7.1' ) > 0 and self.module == 'seth':
            # ce pattern n'a de sens que dans le cas Seth Education (car sur Seth le pattern pour admin est addc_0007a)
            self.setActions([['admin_samba', '$PASSWORD_SAMBA4x2']])
        if self.compare_version( '2.8' ) > 0 and self.module == 'amonecole':
            self.setActions([['admin_samba', '$PASSWORD_SAMBA4x2'],
                             ['instance_amon_smb4a', '$PASSWORD_SAMBA4x2']])
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("instance")
        return cdu

    def monitor_reconfigure(self):
        if not os.path.isfile('/etc/eole/config.eol'):
            self.println_err("\nPas de fichier /etc/config.eol ==> erreur")
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
            self.println_err("gen_rpt désactivé !")
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
        if self.compare_version( '3.0' ) != 0:
            if commandeInitiale != "diagnose":
                self.monitor_gen_rpt()
        os.system("sauvegarde-fichier.sh " + commandeInitiale)

    def monitor_maj_release(self, args):
        if len(args) < 2:
            self.println_err("\nPas de parametres à monitor_maj_release ==> erreur")
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

            '2.7.0->2.7.2': '1' ,
            '2.7.0->2.7.1': '2' ,

            '2.7.1->2.7.2': '1' ,

            '2.8.0->2.8.1': '1' ,
        }

        tag = current_release.strip() + "->" + release_target.strip()
        try:
            release_target_idx = all_releases[tag]
        except KeyError:
            # Current is not in list, keep all if 2.3
            self.println_err("\npas de Maj-Release '{0}'".format(tag))
            self.println_err("\nMauvaise version cible: '" + release_target + "' ne fait pas partie de " + str(all_releases))
            self.println_err("\nCorriger 'monitor_eole_ci.py'")
            return 1
        except ValueError:
            # Current is not in list, keep all if 2.3
            self.println_err("\npas de Maj-Release '{0}'".format(tag))
            self.println_err("\nMauvaise version cible: '" + release_target + "' ne fait pas partie de " + str(all_releases))
            self.println_err("\nCorriger 'monitor_eole_ci.py'")
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
            self.println_err("\nPas de parametres à  monitor_upgrade_auto ==> erreur")
        else:
            try:
                # Current Release, Target releases, index
                all_releases = {
                    '2.8.1->2.9.0': '1',
                    '2.8.0->2.9.0': '1',

                    '2.7.2->2.8.1': '1',

                    '2.7.2->2.8.0': '1',

                    '2.6.2->2.7.2': '1',
                    '2.6.2->2.7.1': '2',
                    '2.6.2->2.7.0': '3',

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
                if self.compare_version( '2.3' ) == 0:
                    self.setCommande('/usr/share/eole/Upgrade-Auto')
                    self.setActions([ [ 'upgrade_auto_version', str(release_target_idx) ] ])
                else:
                    if self.compare_version( '2.4.2' ) >= 0:
                        if strategie == "cdrom":
                            self.setCommande('Upgrade-Auto --release ' + release_target + ' --cdrom --force')
                            self.setActions([ [ 'upgrade_auto_001', str(release_target_idx) ] ])
                        elif self.compare_version( '2.8.1' ) < 0:
                            self.setCommande('Upgrade-Auto --release ' + release_target + ' --force --limit-rate 10m ')
                            self.setActions([ [ 'upgrade_auto_001', str(release_target_idx) ] ])
                        else:
                            self.setCommande('Upgrade-Auto --release ' + release_target + ' --force')
                            self.setActions([ [ 'upgrade_auto_001', str(release_target_idx) ] ])
                    else:
                        self.setCommande('Upgrade-Auto')
                        self.setActions([ [ 'upgrade_auto_version', str(release_target_idx) ] ])
                self.setTimeout(1200)  # Attention : cela peut être tres long entre deux evenements/pattern ...
                cdu = self.monitor_cmd()
                if cdu != 0:
                    self.sauvegarde_fichier("upgrade_auto")
            except Exception:
                self.println_err("\nPas d'upgrade auto '{0}'".format(tag))
                self.println_err("\nMauvaise version cible: '" + release_target + "' ne fait pas partie de " + str(all_releases.keys()))
                self.println_err("\nCorriger 'monitor_eole_ci.py'")
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
        if self.compare_version( '2.3' ) == 0:
            self.setCommande('/usr/bin/gen_conteneurs')
        else:
            if self.compare_version( '2.4' ) == 0:
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
        self.println_err("enregistrement_testcharge pour " + serveurName + " " + str(idServeur))
        if idServeur > 0:
            self.monitor_zephir_desinscrire()

        self.setCommande('enregistrement_zephir')
        self.setActions([ [ 'zephir_choix', '3' ],
                          [ 'zephir_creer', 'O' ],
                          [ 'zephir_libelle', serveurName ],
                          [ 'zephir_delai', '1' ] ])
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier("enregistrement_zephir")
        return cdu

    def monitor_zephir_desinscrire(self):
        self.initZephir()
        self.setCommande('enregistrement_zephir')
        self.setActions([ [ 'zephir_choix1', '1' ],
                          [ 'zephir_logina', '' ] ])
        cdu = self.monitor_cmd()
        return cdu

    def monitor_enregistrement_domaine(self, args):
        # current_release = self.versionMajeur
        # args = ['enregistrement_domaine', '', '', '', '', '', '']
        # attention aux args='' !
        if len(args) > 1:
            release_target = args[1]
        else:
            release_target = ''
        if release_target == '':
            release_target = self.versionMajeur
        self.println_err("\nenregistrement_domaine, scribe version cible = " + release_target)
        self.setCommande('enregistrement_domaine.sh')
        if self.compare_version(fromVersion=release_target, withVersion='2.8.0') >= 0:
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
        if idServeur < 0:
            self.sauvegarde_fichier("enregistrement_zephir")
            return 1
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

    def monitor_shell(self, args):
        cmd1 = ' '.join(args)
        self.setCommande(cmd1)
        cdu = self.monitor_cmd()
        if cdu != 0:
            self.sauvegarde_fichier(cmd1)
        return cdu

    def initZephir(self):
        # import ssl

        # self.println_err( "================================================================")
        self.getEnv("CURL_CA_BUNDLE", "?")
        self.getEnv("REQUESTS_CA_BUNDLE", "?")
        self.getEnv("SSL_CERT_DIR", "?")
        self.getEnv("SSL_CERT_FILE", "?")
        # self.println_err( "monitor_eole_ci4: ssl version " + str( ssl.OPENSSL_VERSION) )
        # self.println_err( "monitor_eole_ci4: ssl Paths " + str( ssl.get_default_verify_paths() ) )

        # ctx = ssl._create_default_https_context()
        # self.println_err( "monitor_eole_ci4: SSLContext protocol=" + str(ctx.protocol))
        # self.println_err( "monitor_eole_ci4: options=" + str(ctx.options))
        # self.println_err( "monitor_eole_ci4: check_hostname=" + str(ctx.check_hostname))
        # self.println_err( "monitor_eole_ci4: verify_mode=" + str(ctx.verify_mode))
        # self.println_err( "monitor_eole_ci4: verify_flags=" + str(ctx.verify_flags))
        # _wrap_socket', 'cert_store_stats', 'check_hostname', 'get_ca_certs', 'load_cert_chain', 'load_default_certs', 'load_dh_params', 'load_verify_locations', 'options', 'protocol', 'session_stats', 'set_alpn_protocols', 'set_ciphers', 'set_default_verify_paths', 'set_ecdh_curve', 'set_npn_protocols', 'set_servername_callback', 'verify_flags', 'verify_mode', 'wrap_bio', 'wrap_socket']
        # ctx.load_default_certs
        # ctx.load_cert_chain
        # css = ctx.cert_store_stats()
        # self.println_err( "monitor_eole_ci4: cert_store_stats=" + str(css))
        # gcc = ctx.get_ca_certs()
        # self.println_err( "monitor_eole_ci4: get_ca_certs=" + str(gcc ))
        # lcc = ctx.load_cert_chain()
        # self.println_err( "monitor_eole_ci4: load_cert_chain=" + str(lcc ))

        # response = urllib.request.urlopen('http://python.org/')
        # urllib.request.Request(
        # html = response.read()
        # import requests
        # self.println_err ("requests.certs.where " + requests.certs.where())
        # req = requests.get('https://admin_zephir:eole@zephir.ac-test.fr:7080', verify=True)
        # self.println_err(req.content)

        import xmlrpc.client
        # self.zephir = xmlrpc.client.ServerProxy('https://admin_zephir:eole@zephir.ac-test.fr:7080', verbose=True)
        self.zephir = xmlrpc.client.ServerProxy('https://admin_zephir:eole@zephir.ac-test.fr:7080')
        if self.vmDebug > "0":
            self.println_err("monitor_eole_ci4: zephir")
            self.println_err(vars(self.zephir))
            self.println_err("monitor_eole_ci4: fin initZephir")
            self.println_err("================================================================")

    def getIdServeurName(self, serveur_name):
        criteres_selection = {'libelle': serveur_name}
        try:
            # sys.settrace(trace_calls)
            rc, groupe_serv = self.zephir.serveurs.groupe_serveur(criteres_selection)
        except Exception:
            if self.vmDebug > "0":
                print_exc(limit=None)
                self.println_err ('erreur groupe_serveur, ... ré essai avec trace ')
                sys.settrace(trace_calls)
                rc, groupe_serv = self.zephir.serveurs.groupe_serveur(criteres_selection)
                sys.settrace(None)
            else:
                self.println_err ('erreur xmlrpc (zephir présent ?)')
                return -1

        if rc == 0:
            self.println_err ('erreur xmlrpc ' + str(rc))
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
        self.println_err('Version: ' + self.versionMajeur)

        if self.machine == '?':
            self.println_err('machine inconnue')
            return 0
        self.println_err('Machine: ' + self.machine)
        self.println_err('Configuration: ' + self.configuration)
        serveur_name = self.machine + '-' + self.configuration + '-' + self.versionMajeur
        return self.getIdServeurName(serveur_name)

    def zephirCtl(self, args):
        if len(args) < 1:
            self.println_err("\nPas de parametres à zephirCtl ==> erreur")
            return
        serveur_name = args[1]
        #self.println_err('Commande : ' + commande )
        if serveur_name == "-":
            if self.versionMajeur == '?':
                self.println_err('version inconnue')
                return 0
            if self.machine == '?':
                self.println_err('machine inconnue')
                return 0
            self.println_err('Machine: ' + self.machine)
            self.println_err('Configuration: ' + self.configuration)
            serveur_name = self.machine + '-' + self.configuration + '-' + self.versionMajeur
        self.println_err('Configuration : ' + serveur_name )
        criteres_selection = {'libelle': serveur_name}
        try:
            # sys.settrace(trace_calls)
            rc, groupe_serv = self.zephir.serveurs.groupe_serveur(criteres_selection)
        except Exception:
            if self.vmDebug > "0":
                print_exc(limit=None)
                self.println_err ('erreur groupe_serveur, ... ré essai avec trace ')
                sys.settrace(trace_calls)
                rc, groupe_serv = self.zephir.serveurs.groupe_serveur(criteres_selection)
                sys.settrace(None)
            else:
                self.println_err ('erreur xmlrpc (zephir présent ?)')
                return -1

        if rc == 0:
            self.println_err ('erreur xmlrpc ' + str(rc))
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

        # affichage des données pour chaque serveur : identifiant, rne, adresse dns, adresses eth0 et eth1 si disponible
        rc, config = self.zephir.serveurs.get_config(id_serveur)

        if len(args) < 3:
            print("Usage: zephirctl <commande>")
            print(" zephirctl config")
            print(" zephirctl variantes")
            print(" zephirctl modules")
            print(" zephirctl get <var>")
            print(" zephirctl set <var> <value>")
            return 0
        commande = args[2]
        update = False
        if commande == "config":
            print( json.dumps(config, sort_keys=True, indent=4 ))
            #for k in sorted(config):
            #    print("%s = \"%s\"" %(k,config[k]) )
            update = False
        elif commande == "variantes":
            # liste des variantes standard par module
            modulesById = {}
            modulesByLibelle = {}
            for mod in self.zephir.modules.get_module()[1]:
                # correspondance libelle de module/n° de module
                modulesById[mod['id']] = mod['libelle']
                modulesByLibelle[mod['libelle']] = mod['id']
            #variantesById={}
            #variantesByModule={}
            for var in self.zephir.modules.get_variante()[1]:
                print( '%s:%s:%s' % (modulesById[var['module']], var['libelle'], var['id']))
        elif commande == "modules":
            modulesByLibelle = {}
            for mod in self.zephir.modules.get_module()[1]:
                modulesByLibelle[mod['libelle']] = mod['id']
            for mod in sorted(modulesByLibelle):
                print( '%s:%s' % (mod, modulesByLibelle[mod]))
        elif commande == "get":
            if len(args) < 4:
                self.println_err("\nUsage: zephirCtl get <var>")
                return -1
            var = args[3]
            print( '%s = \"%s\"' % (var, config[var]))
            update = False
        elif commande == "set":
            if len(args) < 5:
                self.println_err("\nUsage: zephirCtl set <var> <val>")
                return -1
            varname = args[3]
            value = args[4]
            code, res = self.zephir.serveurs.set_groupe_var([id_serveur], varname, value, True)
            if code == 0:
                print( "Erreur d'insertion de la variable %s (%s) : %s" % (varname, value, str(res) ))
            else:
                print( '%s = \"%s\" -> \"%s\"' % (varname, config[varname], value))
            #update=True
        else:
            self.println_err("\nzephirCtl commande '%s' inconnue ==> " % commande)
            return -1

        if update:
            self.println_err (commande + " " + serveur_name + ': ' + str(id_serveur))
            rc, message = self.zephir.serveurs.save_conf([id_serveur], config)
            if rc != 1:
                self.println_err( "rc=" + str(rc)  )
                self.println_err(type(message))
                self.println_err(message.encode('ascii', 'ignore'))
                return -1
        return 0


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
    if cmd == 'monitor_eole_ci4.py': #appel direct depuis python3
        cmd = sys.argv[2]
        param = sys.argv[3:]
    else:
        param = sys.argv[1:]  # je mets 'cmd' en 1er ==> equivalent a sys.argv !
    monitor = MonitorEoleCi()
    # print ('pexpect version : ' + str( sys.modules['pexpect'] ) )
    if cmd == 'testversion':
        monitorExitCode = monitor.compare_version(param[1])
        print("compare=" + str(monitorExitCode ) )
    elif cmd == 'instance':
        monitorExitCode = monitor.monitor_instance()
    elif cmd == 'diagnose':
        monitorExitCode = monitor.monitor_diagnose()
    elif cmd == 'gen_conteneurs':
        monitorExitCode = monitor.monitor_gen_conteneurs()
    elif cmd == 'zephir_recupere_configuration':
        monitorExitCode = monitor.monitor_zephir_recupere_configuration()
    elif cmd == 'zephir_desinscrire':
        monitorExitCode = monitor.monitor_zephir_desinscrire()
    elif cmd == 'zephirctl':
        monitorExitCode = monitor.zephirCtl(param)
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
    elif cmd in ['ssh', 'ssh-copy-id', 'scp', 'salt-run', 'bash', 'lxc-attach', 'onebck', 'onerst']:
        monitorExitCode = monitor.monitor_shell(param)
    else:
        monitorExitCode = 1
        monitor.println_err("commande '%s' inconnue." % cmd)
        printusage()
    sys.stdout.flush()
    sys.stderr.flush()
    sys.exit(monitorExitCode)
