#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import locale
import codecs
import argparse
import traceback
import wmi
import shutil

if hasattr(sys, 'setdefaultencoding'):
    loc = locale.getdefaultlocale()
    if loc[1]:
        encoding = loc[1]
        sys.setdefaultencoding(encoding)

import win32process
import win32api
import win32com
import wmi
from datetime import datetime

import config 
from fonctions import test_hostname
from fonctions import activate_share
from fonctions import adduser
from fonctions import active_admin
from fonctions import active_numlock
from fonctions import active_ctrl_alt_supp
from fonctions import desactive_veille
from fonctions import restore_sys
from fonctions import show_hidden_files
from fonctions import show_ext
from fonctions import conf_ntp
from fonctions import conf_maj
from fonctions import add_dns_suffix
from fonctions import testOS
from fonctions import exec_func
from fonctions import lancecmd
from fonctions import cle_registre
from fonctions import domainpardefaut
from fonctions import apply_refiles
from fonctions import connect
from fonctions import reboot
from registre import *


def log( line):
    print( line )
    f = 'joineolebatch.log'
    # utf-8-sig"  gére le BOM automatiquement !
    fsock = codecs.open(f, 'a', "utf-8")
    fsock.write( str( datetime.now() ) )
    fsock.write(" : ")
    fsock.write( line )
    fsock.write("\r\n")
    fsock.close()


def activate_share():
    cmd = unicode('netsh advfirewall firewall set rule group="Recherche du réseau" new enable=Yes', "utf-8").encode("utf-8")
    exec_func(lancecmd, cmd, hide=True) 


def networks_private():
    NETWORK_CATEGORIES = {1: "PRIVATE",0: "PUBLIC", 2: "DOMAIN"}
    m = win32com.client.Dispatch("{DCB00C01-570F-4A9B-8D69-199FDBA5723B}") # NetworkListManager
    print( "GetConnectivity = " + str(m.GetConnectivity()))
    if m.IsConnected:
        print( "IsConnected = OUI")
    else:
        print( "IsConnected = NON")
    if m.IsConnectedToInternet:
        print( "IsConnectedToInternet = OUI")
    else:
        print( "IsConnectedToInternet = NON")

    more = 1
    pos = 1
    connections = m.GetNetworkConnections()
    while more:
        connection, more = connections.Next(pos)
        if connection:
            network = connection.GetNetwork()
            category = network.GetCategory()
            name = network.GetName()
            if category != 1:
                try:
                    network.SetCategory(1)
                    log( u"passage '%s' en mode private : OK" % name )
                except e:
                    log( u"passage '%s' en mode private : ERREUR " % name )
                    log( str( e) )
            else:
                log( u"passage '%s' en mode private : OK (%d) " % (name, category) )

        pos += 1


def joindom1( CS, dom, user, passwd, _computerName, server = None):

    cmd = "cscript.exe //NOLOGO JoinDomain.vbs " + chr(34) + dom + chr(34) + " " + chr(34) + user + chr(34)+ " " + chr(34) + passwd.decode('base64') + chr(34) + " "  + chr(34) + _computerName + chr(34) 
    print( cmd )
    return lancecmd(cmd, hide=False, nowait=False)


def main():

    parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('--cfg', dest='cfgFile', help="Path du fichier cfg")
    parser.add_argument('--hostname', dest='hostname', help="Nom du host dans le domaine")
    parser.add_argument('--installClient', dest='installClient', action="store_true", help="Install le client scribe/horus")
    parser.add_argument('--reboot', dest='reboot', action="store_true", help="reboot automatique à la fin de la procédure")
    args = parser.parse_args()

    c = wmi.WMI(moniker="winmgmts:{impersonationLevel=Impersonate,authenticationLevel=pktPrivacy,(Debug,Shutdown,LockMemory,!IncreaseQuota)}")
    #c = wmi.WMI(find_classes=False)
    #c = wmi.WMI()
    system = None
    for s in c.Win32_ComputerSystem ():
        system = s
    if system is None:
        return 1
    log('methodes')
    for method_name in system.methods:
        method = getattr(system, method_name)
        print method

    os = None
    for o in c.Win32_OperatingSystem():
        os = o.version.split('.')
    if os is None:
        return 1

    log(u'Test OS ' + str(os))
    ver_format = int(os[0]), int(os[1])
    win_version = {
        (4, 0): '95',
        (5, 1): 'XP',
        (5, 2): '2003',
        (6, 0): 'Vista',
        (6, 1): '7',
        (6, 2): '8',
        (6, 3): '8.1',
        (10, 0): '10',
    }
    _OS_ver = win_version[ver_format]

    _is64bit = '64' if win32process.IsWow64Process() else '32'
    log ('Windows ' + str(_OS_ver) + ' ' + _is64bit + 'bit' )

    if args.cfgFile is None:
        f = "joineolebatch.cfg"
    else:
        f = args.cfgFile
    log ('cfg :  ' + str(f) )
    _conf = config.Config( f )

    _is_Scribe = True
    if _OS_ver != 'XP':
        networks_private()
        activate_share()

    _dic_conf = _conf.get_conf()
    log("Options " + str(_dic_conf))
    _activeadmin = _dic_conf.get('activeadmin')
    _admin2 = _dic_conf.get('admin2')
    _adminlocal = _dic_conf.get('adminlocal')
    _cas = _dic_conf.get('cas')
    _change_maj_time = _dic_conf.get('change_maj_time')
    _dom = _dic_conf.get('domaine')
    _doInstall = _dic_conf.get('install')
    _hiddenfiles = _dic_conf.get('hiddenfiles')
    _ntp = _dic_conf.get('ntp')
    _numlock = _dic_conf.get('numlock')
    _passwd = _dic_conf.get('passwd')
    _passwd2 = _dic_conf.get('passwd2')
    _passwdadmin = _dic_conf.get('passwdadmin')
    _restoresys = _dic_conf.get('restoresys')
    _server = _dic_conf.get('serveur')
    _servip = _dic_conf.get('ip')
    _showext = _dic_conf.get('showext')
    _suffix_dns = _dic_conf.get('suffix_dns')
    _timemaj = _dic_conf.get('timemaj')
    _user = _dic_conf.get('admin')
    _veille = _dic_conf.get('veille')
    _rebootApres = _dic_conf.get('reboot')
    _scribe = _dic_conf.get('scribe')

    if _scribe is None:
        _is_Scribe = True
    if _scribe == 'True':
        _is_Scribe = True
    if _scribe == 'oui' :
        _is_Scribe = True
    if _scribe == 'non' :
        _is_Scribe = False
    if _scribe == 'False' :
        _is_Scribe = False

    if args.hostname is None:
        _computerName = _dic_conf.get('hostname')
    else:
        _computerName = args.hostname
    if _computerName is None:
        print ("'hostname' n'est pas renseigné")
        return

    log ('hostname cible :  ' + _computerName )

    if _passwd is None:
        print ("'passwd' n'est pas renseigné")
        return 

    if not test_hostname(_computerName):
        return
    
##http://support.microsoft.com/kb/2743127/fr
##necessaire au bon fonctionnement de joindom
##Desactivation du service Webclient
#voir http://support.microsoft.com/?scid=kb%3Bfr%3B832161&x=5&y=14
#["compatibilite auth sur amon",HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\Control\Lsa","LmCompatibilityLevel",REG_DWORD,1]
#["Desactivation de l'UAC",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System","EnableLUA",REG_DWORD,0],
#["Desactivation de l'UAC",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System","ConsentPromptBehaviorAdmin",REG_DWORD,0],
#["Desactivation de l'UAC",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System","PromptOnSecureDesktop",REG_DWORD,0],
## evite erreur chargement de profils (CompatibleRUPSecurity)
## WaitForNetwork equivalent gpedit.msc Stratégie ordinateur local / Configuration ordinateur / Modèles d’administration / Système / Profils des utilisateurs, 
## activer Définir le temps d’attente maximal pour le réseau si un utilisateur a un profil utilisateur ou un répertoire d’accueil distant itinérant et mettre 0 secondes
## cf http://wiki.samba.org/index.php/Windows7

    if _OS_ver != 'XP':
        apply_cles([
["Compatibilite Samba"                    ,HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\Services\LanManWorkstation\Parameters","DNSNameResolutionRequired", REG_DWORD,0],
["Compatibilite Samba"                    ,HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\Services\LanManWorkstation\Parameters","DomainCompatibilityMode", REG_DWORD,1],
["Compatibilite Samba"                    ,HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\Services\LanManWorkstation\Parameters","RequireSecuritySignature", REG_DWORD,0],
["compatibilite auth sur amon"            ,HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\Control\Lsa","LsaAllowReturningUnencryptedSecrets",REG_DWORD,1],
["Desactivation Webclient"                ,HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\Services\WebClient","Start",REG_DWORD,4],
["workaround erreur chargement de profils",HKEY_LOCAL_MACHINE,"SOFTWARE\Policies\Microsoft\Windows\System", "CompatibleRUPSecurity", REG_DWORD,1],
["workaround erreur chargement de profils",HKEY_LOCAL_MACHINE,"SOFTWARE\Policies\Microsoft\Windows\System", "SlowLinkDetectEnabled", REG_DWORD,0],
["Delais d'attente du profil"             ,HKEY_LOCAL_MACHINE,"SOFTWARE\Policies\Microsoft\Windows\System", "WaitForNetwork", REG_DWORD,0],
["workaround erreur chargement de profils",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "CompatibleRUPSecurity", REG_DWORD,1],
["workaround erreur chargement de profils",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "RunLogonScriptSync", REG_DWORD,1],
["Correction accès refusé à netlogon"     ,HKEY_LOCAL_MACHINE,"SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths","\\\\*\\netlogon",REG_SZ,"RequireMutualAuthentication=0,RequireIntegrity=0,RequirePrivacy=0"],
["Correction accès refusé à netlogon"     ,HKEY_LOCAL_MACHINE,"SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths","\\\\*\\netlogon",REG_SZ,"RequireMutualAuthentication=0,RequireIntegrity=0,RequirePrivacy=0"]
        ])
    else:
        log("rename XP ")
        apply_cles([
        ["computername",HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Control\\ComputerName\\ComputerName","ComputerName",REG_SZ,_computerName],
        ["computername",HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Control\\ComputerName\\ActiveComputerName","ComputerName",REG_SZ,_computerName],
        ["computername",HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Services\\Tcpip\\Parameters","Hostname",REG_SZ,_computerName],
        ["computername",HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Services\\Tcpip\\Parameters","NV Hostname",REG_SZ,_computerName]
        ])

    # joindre le domaine
    log ('Renomage en "%s" et Jonction au domaine "%s"...' % (_computerName, _dom) )
    try: 
        _ret = joindom1( system, _dom, _user, _passwd, _computerName)
    except Exception, e:
        traceback.format_exc( e)
        return

    log("joindom retourne " + str(_ret))
    if _ret != 0 :
        return

    domainpardefaut( _dom )
    if _admin2 is not None:
        adduser( _admin2, _passwd2.decode('base64') )
    if _activeadmin == 'True' :
        active_admin( _passwdadmin.decode('base64') )
    if _numlock == 'True':
        active_numlock( _OS_ver )
    if _cas == 'True':
        active_ctrl_alt_supp()
    if _veille == 'True':
        desactive_veille()
    if _restoresys == 'True':
        restore_sys()
    if _hiddenfiles == 'True':
        show_hidden_files( _OS_ver )
    if _showext == 'True':
        show_ext( _OS_ver)
    if _ntp is not None:
        conf_ntp( _ntp )
    if _change_maj_time == 'True':
        conf_maj(_timemaj)
    if _suffix_dns == 'True':
        add_dns_suffix()

    if _adminlocal == 'True':
        try:
            adminlocal( _dom )
        except:
            log("erreur pour ajouter domainsUsers")
            log(traceback.format_exc())

    log ('Jonction au domaine "%s" terminee, redemarrage necessaire' % _dom)
    if args.installClient:
        # montage du partage "perso"
        _unc = r'\\%s\%s' % (_servip, 'perso')

        if _is_Scribe:
            _exe = 'cliscribe-setup.exe'
            _exe_updater = 'cliscribe-updater-setup.exe'
        else:
            _exe = 'clieole-setup.exe'
            _exe_updater = 'clieole-updater-setup.exe'

        _cmd = 'NET USE w: /DELETE '
        cdu = lancecmd( _cmd, hide=True)

        _cmd = 'NET USE w: \\\\%s\%s /USER:%s %s /PERSISTENT:NO ' % (_servip, _user, _user, _passwd.decode('base64') )
        log ( _cmd )
        cdu = lancecmd( _cmd, hide=True)
        if cdu != 0:
            return

        _fichier = r'W:\perso\client\%s' % (_exe)
        _fichier_updater = r'W:\perso\client\%s' % (_exe_updater)
        _fichierlocal = 'c:\eole\%s' % (_exe)
        _fichierlocal_updater = 'c:\eole\%s' % (_exe_updater)

        _cmd = 'CMD /C COPY %s %s' % (_fichier, _fichierlocal)
        log ( _cmd )
        cdu = lancecmd( _cmd, hide=True)
        if cdu != 0:
            return

        _cmd = 'CMD /C COPY %s %s' % (_fichier_updater, _fichierlocal_updater)
        log ( _cmd )
        cdu = lancecmd( _cmd, hide=True)
        if cdu != 0:
            return

        _cmd = r'%s /SILENT /NORESTART' % _fichierlocal
        log ('Execution de "%s"...' % _cmd)
        cdu = lancecmd( _cmd, hide=True)
        if cdu != 0:
            return

        _cmd_updater = r'%s /SILENT /NORESTART' % _fichierlocal_updater
        log ('Execution de "%s"...' % _cmd_updater)
        if lancecmd( _cmd_updater, hide=True) != 0:
            return

        _cmd = 'NET USE w: /DELETE '
        cdu = lancecmd( _cmd, hide=True)

    log ('Installation terminee.')
    apply_refiles( _OS_ver )
    if args.reboot:
        log ( 'Redemarrage...' )
        reboot()
    log ( 'Fin...' )


if __name__ == '__main__':
    sys.exit(main())
