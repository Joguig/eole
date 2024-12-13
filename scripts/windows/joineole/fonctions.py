# -*- coding: utf-8 -*-

import win32com.client
import pywintypes
import wx
import os,sys
import glob
import win32api
import win32netcon, win32file, win32con, win32wnet
import win32process, win32event
from ctypes import *
import  wx.lib.masked as m
from datetime import datetime
import platform
import win32net
import socket
import wmi
import config
from ctypes import *
import Options
import subprocess
from registre import *
import traceback
import ctypes 
import _winreg

def joindom(dom, user, passwd,server = None):
    log("joindom " + dom + " " +  user)
    netapi32 = windll.LoadLibrary ("netapi32.dll")
    user = '%s\\%s'%(dom, user)
    
    #log('NetJoinDomain' + str(dom) + str(user) + str(passwd) + str(server))
    if testOS == 'XP':
        ret = netapi32.NetJoinDomain(server, dom , None, user, passwd ,int(0x00000001|0x00000002|0x00000020))
    else:
        ret = netapi32.NetJoinDomain(server, dom , None, user, passwd ,int(0x00000001|0x00000002|0x00000020|0x00000400))
    if ret != 0:
        log('Erreur ' + str(ret))
        dicterr = dict()
        dicterr[1219]='Fermez les connexions existantes sur le serveur'
        dicterr[1311]='Domaine introuvable'
        dicterr[1326]='Erreur d\'authentification' 
        dicterr[2691]='Deja dans le domaine'
        dicterr[1355]='Domaine introuvable' 
        try:
            msgerr = dicterr[ret]
        except:
            msgerr = ''
        raise pywintypes.error(ret, 'NetJoinDomain', 'Impossible de joindre le domaine ' + dom +  '\n' + msgerr)
    return ret


def connect(drive, unc, username=None, password=None, persistent=False):
    """Monte un lecteur
    """
    #TODO deco si deja connecte au serveur
    log('connect ' + drive + ':' + unc)
    dliste = ['d:','e:','f:','g:','h:','i:','j:','k:','l:','m:','n:','o:','p:','q:','r:','s:','t:','u:','v:','w:','x:','y:','z:']
    if persistent: flags = win32netcon.CONNECT_UPDATE_PROFILE
    else: flags = 0
    if win32file.GetDriveType(drive) != win32con.DRIVE_NO_ROOT_DIR:
        for drive in dliste:
            if win32file.GetDriveType(drive) == win32con.DRIVE_NO_ROOT_DIR: break
    win32wnet.WNetAddConnection2(
        win32netcon.RESOURCETYPE_DISK,
        drive,
        unc,
        None,
        username,
        password,
        flags
        )
    return drive

def disconnect(drive):
    """Demonte le lecteur "drive"
    """
    log("disconnect " + drive)
    if not os.path.exists(drive): return True
    if win32file.GetDriveType(drive) == win32con.DRIVE_REMOTE: 
        win32wnet.WNetCancelConnection2(drive, 0, 1)
        return True
    return False

def lancecmd(cmd, hide=False, nowait=False, waitinput=False):
    #print str(cmd)
    log('lance commande ' + str(cmd))
    appName = None
    commandLine = cmd
    processAttributes = None
    threadAttributes = None
    inheritHandles = False
    creationFlags = win32con.CREATE_DEFAULT_ERROR_MODE
    newEnvironnement = None
    currentDirectory = None
    startupinfo = win32process.STARTUPINFO()
    if hide:
        startupinfo.dwFlags = win32process.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = win32con.SW_HIDE
    handle, hthread, process_id, thread_id = win32process.CreateProcess(appName,
                                                                       commandLine,
                                                                       processAttributes,
                                                                       threadAttributes,
                                                                       inheritHandles,
                                                                       creationFlags,
                                                                       newEnvironnement,
                                                                       currentDirectory,
                                                                       startupinfo)
     
    if waitinput:
        # attendre au moins que le programme s'initialise
        # NE fonctionne PAS tjrs
        win32event.WaitForInputIdle(handle, win32event.INFINITE)
    if nowait: return 0
    # Sinon on attend que l'application finisse
    win32event.WaitForSingleObject(handle, win32event.INFINITE)
    return int(win32process.GetExitCodeProcess(handle))

def reboot():
    lancecmd('shutdown -r -f -t0', hide=True, nowait=True)
# ncessite l'utilisation de privileges NT, 
# solution temporaire ci-dessus
##    opts = win32con.EWX_REBOOT | win32con.EWX_FORCE
##    win32api.ExitWindowsEx(opts, 0)
    subprocess.call(["shutdown.exe", "-r", "-f", "-t", "6"])
    
def testOS():
    c = wmi.WMI()
    for os in c.Win32_OperatingSystem():
        ver = os.version.split('.')
        log(u'Test OS ' + str(ver))
    ver_format = int(ver[0]), int(ver[1])
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
    if ver_format in win_version:
        return  win_version[ver_format]
            
def rename_7(hostname):
    #from ctypes.wintypes import *
    log("rename >7 " + hostname)    
    kernel32 = WinDLL('kernel32.dll')
    uhostname = unicode(hostname)
    windll.kernel32.SetComputerNameExW(5, uhostname)

def renomme_station(hostname,dom):
    log("rename XP ")        
    cles = [["computername",HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Control\\ComputerName\\ComputerName","ComputerName",REG_SZ,hostname],
    ["computername",HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Control\\ComputerName\\ActiveComputerName","ComputerName",REG_SZ,hostname],
    ["computername",HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Services\\Tcpip\\Parameters","Hostname",REG_SZ,hostname],
    ["computername",HKEY_LOCAL_MACHINE,"System\\CurrentControlSet\\Services\\Tcpip\\Parameters","NV Hostname",REG_SZ,hostname]]
    for cle in cles:
        ruche = cle[1]
        keypath = cle[2]
        key = cle[3]
        keytype = cle[4]
        keyval = cle[5]
        try:
            regkey = OpenKeyEx(ruche, keypath, 0, KEY_ALL_ACCESS|KEY_WOW64_64KEY)
        except:
            regkey = CreateKeyEx(ruche, keypath, 0, KEY_ALL_ACCESS|KEY_WOW64_64KEY)
            
        SetValueEx(regkey, key, 0, keytype, keyval)
        CloseKey(regkey)
    c = wmi.WMI ()
    for system in c.Win32_ComputerSystem ():
        system.Rename (hostname)

def testportscribe(ip):
    log("test port 8789 : " + ip)        
    s = socket.socket()
    try:
        s.settimeout(1)
        s.connect((ip, 8789))
        s.close()
        return 1
    except socket.error:
        s.close()
        return 0
         
        
def activate_share():    
    cmd =  unicode('netsh advfirewall firewall set rule group="Recherche du réseau" new enable=Yes', "utf-8").encode("utf-8")
    exec_func(lancecmd, cmd, hide=True) 

def networks_private():
    NETWORK_CATEGORIES = {1: "PRIVATE",0: "PUBLIC", 2: "DOMAIN"}
    m = win32com.client.Dispatch("{DCB00C01-570F-4A9B-8D69-199FDBA5723B}")
    more = 1
    pos = 1
    connections = m.GetNetworkConnections()
    while more:
        connection, more = connections.Next(pos)
        if connection:
            network = connection.GetNetwork()
            category = network.GetCategory()
            try:
                log('passage reseau en modeprivate')
                network.SetCategory(1)
            except:
                log("erreur pour passer connection en private")
        pos += 1    


def finddc(domain):
    try:
        dc = win32net.NetGetDCName(None, domain)
        dc = dc.replace('\\\\','')
        log('cherche controleur de domaine ' + domain + ' = ' + dc)
        return dc
    except Exception, e:
        log(traceback.format_exc()) 
        log('Erreur de cherche controleur de domaine ' + domain )        
        #self.statusBar1.SetStatusText(str(e))
        return None

def find_ip(hostname):
    if hostname != '' or hostname != None:
        log('cherche ip  ' + hostname)        
        return socket.gethostbyname(hostname)
    else:
        return ''

def finddoms():
    list_domains = []
    network = win32com.client.GetObject ("WinNT:")
    log('cherche  domaines')
    for group in network:
        try:
            if not group.name == 'WORKGROUP':
                list_domains.append(group.name)
        except:
            log(traceback.format_exc()) 
            log('Erreur recherche de domaines')
            pass
    return list_domains


def domainpardefaut(dom):
    log('domaine par defaut = ' + dom)
    cles=[["DefaultDomainName",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultDomainName",REG_SZ,dom]]
    apply_cles(cles)


def exec_func( func, *args, **kwargs):
    try: return func(*args, **kwargs)
    except pywintypes.error, e:
        msg = """Erreur a  l'execution de "%s" """%(func.__name__)
        errbox(msg, '%s %s'%(e[0], e[2]))
    except Exception, e:
        msg = """Erreur a  l'execution de "%s" """%(func.__name__)
        errbox(msg, e)

def errbox( msg, e):
    wx.MessageBox(msg + " "  + str(e), 'Erreur', wx.ICON_ERROR)
    #self.statusBar1.SetStatusText(u'Erreur : "%s"'%e)


def cle_registre():
    cles = [["Compatibilite Samba",HKEY_LOCAL_MACHINE,"System\CurrentControlSet\Services\LanManWorkstation\Parameters","DomainCompatibilityMode",REG_DWORD,1],
    ["Compatibilite Samba",HKEY_LOCAL_MACHINE,"System\CurrentControlSet\Services\LanManWorkstation\Parameters","DNSNameResolutionRequired",REG_DWORD,0],
    ["win10",HKEY_LOCAL_MACHINE,"SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths","\\\\*\\netlogon",REG_SZ,"RequireMutualAuthentication=0,RequireIntegrity=0,RequirePrivacy=0"],
    ["Delais d'attente du profil",HKEY_LOCAL_MACHINE,"SOFTWARE\Policies\Microsoft\Windows\System","WaitForNetwork",REG_DWORD,0],
    ["compatibilite auth sur amon",HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\Control\Lsa","LmCompatibilityLevel",REG_DWORD,1]
    ]
    apply_cles(cles)
    
def force_smb():
    cmd = 'sc.exe config lanmanworkstation depend= bowser/mrxsmb10/nsi'
    exec_func(lancecmd, cmd, hide=True) 
    cmd='sc.exe config mrxsmb20 start= disabled'
    exec_func(lancecmd, cmd, hide=True) 
    cmd = 'powershell.exe -Command Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart'
    exec_func(lancecmd, cmd, hide=True) 

def adduser(login, password):
    d={}
    d['name'] = login  
    d['password'] = password
    d['comment'] = "utilisateur local"
    d['flags'] = win32netcon.UF_NORMAL_ACCOUNT | win32netcon.UF_SCRIPT
    d['priv'] = win32netcon.USER_PRIV_USER
    d['domainandname'] = login
    try:
        win32net.NetUserAdd(None, 1, d)
        log('ajout user ' + str(d))
    except:
        #deja existant d = win32net.NetUserGetInfo(None, dict['Login'], 1) error 2224
        log('Erreur ajout user ' + str(d))
        pass
    try:
        log('ajout user au groupe administrateurs:' + login )
        win32net.NetLocalGroupAddMembers(None, "Administrateurs", 3, [d])
    except:
        log('Erreur ajout user au groupe administrateurs:' + login )
        #deja existant 1378
        pass    

def active_admin(password):
    #net user administrator /active:yes
    d={}
    d = win32net.NetUserGetInfo(None, "administrateur", 3)
    d['password'] = password
    d['flags'] = d['flags'] & ~win32netcon.UF_ACCOUNTDISABLE
    win32net.NetUserSetInfo(None,'Administrateur', 3, d)
    log('activation administrateur local' )    

def active_numlock(os_ver):
    """Navigate to HKEY_USERS\.DEFAULT\ControlPanel\Keyboard. 
     InitialKeyboadIndicators 2.
    """
    log('activation numlock' )        
    load_hive(os_ver)
    cles=[["numlock",HKEY_USERS,"ttt\Control Panel\Keyboard","InitialKeyboardIndicators",REG_DWORD,2]]
    apply_cles(cles)
    unload_hive()
    

def active_ctrl_alt_supp():
    log('activation ctrl alt supp' )        
    #HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
    cles=[["DisableCAD",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System","DisableCAD",REG_DWORD,1],
    ["DisableCAD",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System","LogonType",REG_DWORD,0],
    ["DisableCAD",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon","DisableCAD",REG_DWORD,1]
    ]
    apply_cles(cles)
    
    #rk = OpenKeyEx(HKEY_LOCAL_MACHINE,r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon',0,KEY_ALL_ACCESS|KEY_WOW64_64KEY)
    #is_reflect = _winreg.QueryReflectionKey(rk)
    #_winreg.EnableReflectionKey(rk)
    #SetValueEx(rk,"DisableCAD",0,REG_DWORD,1)
    #if is_reflect: _winreg.DisableReflectionKey(rk)
    #CloseKey(rk)

    

def desactive_veille():
    log('desactivation veille' )        
    subprocess.call(['powercfg.exe', '-change' , '-monitor-timeout-ac' , '0'])    
    subprocess.call(['powercfg.exe', '-change' , '-disk-timeout-ac' , '0'])    
    subprocess.call(['powercfg.exe', '-change' , '-standby-timeout-ac' , '0'])    
    subprocess.call(['powercfg.exe', '-change' , '-hibernate-timeout-ac' , '0'])            

def restore_sys():
    """HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore
    Value Name: DisableSR     Type: REG_DWORD    Value: 1"""
    log('desactivation restauration systeme' )      
    cles=[["DisableSR",HKEY_LOCAL_MACHINE,"SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore","DisableSR",REG_DWORD,1]]
    apply_cles(cles)

def show_hidden_files(os_ver):
    """
    HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
    Hidden, choose Modify and enter 1 
    """
    load_hive(os_ver)
    cles=[["Hidden",HKEY_USERS,"ttt\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced","Hidden",REG_DWORD,1]]
    apply_cles(cles)
    unload_hive()    
    
def show_ext(OS_ver):
    """
    HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced registry subkey.
    Double-click HideFileExt and set it to 0 to show known file extensions or 1 to hide them.
    """
    log('montre extensions' )          
    load_hive(OS_ver)
    cles=[["Hidden",HKEY_USERS,"ttt\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced","HideFileExt",REG_DWORD,0]]
    apply_cles(cles)
    unload_hive()  

def conf_ntp(server):
    """
    net stop w32time w32tm /config /syncfromflags:manual /manualpeerlist:"ntp.oma.be" w32tm /config /reliable:yes net start w32time - See more at: http://www.majorxtrem.be/2011/02/16/synchroniser-lheure-dun-windows-serveur-sur-un-serveur-ntp/#sthash.SnLQZxuh.dpuf
    """
    subprocess.call(['net', 'stop', 'w32time'])
    cles=[["serverntp",HKEY_LOCAL_MACHINE,"Software\Microsoft\Windows\CurrentVersion\DateTime\Servers","1",REG_SZ,server],
    ["serverntp",HKEY_LOCAL_MACHINE,"Software\Microsoft\Windows\CurrentVersion\DateTime\Servers","@",REG_SZ,'1'],
    ["serverntp",HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\services\W32Time","Start",REG_DWORD,3],
    ["serverntp",HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\services\W32Time\Parameters","Type",REG_SZ,'NTP']]
    apply_cles(cles)
    
    rk = OpenKeyEx(HKEY_LOCAL_MACHINE,r'SYSTEM\CurrentControlSet\services\W32Time\Parameters',0,KEY_ALL_ACCESS|KEY_WOW64_64KEY)
    SetValueEx(rk,"Type",0,REG_SZ,'NTP')
    CloseKey(rk)    
    
    subprocess.call(['net', 'start', 'w32time'])
    subprocess.call(['w32tm', '/resync'])    
    log('mise a l heure sur ' + server )          

def conf_maj(time):
    heure = str(time).split(':')
    cles=[["demarrage",HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\Services\wuauserv","Start",REG_DWORD,2],
    ["Automatisation",HKEY_LOCAL_MACHINE,"Software\Policies\Microsoft\Windows\WindowsUpdate\AU","AUOptions",REG_DWORD,4],
    ["silencieuse",HKEY_LOCAL_MACHINE,"Software\Policies\Microsoft\Windows\WindowsUpdate\AU","AutoInstallMinorUpdates",REG_DWORD,1],
    ["redemarrer",HKEY_LOCAL_MACHINE,"Software\Policies\Microsoft\Windows\WindowsUpdate\AU","NoAutoRebootWithLoggedOnUsers",REG_DWORD,1],
    ["Jour",HKEY_LOCAL_MACHINE,"Software\Policies\Microsoft\Windows\WindowsUpdate\AU","ScheduledInstallDay",REG_DWORD,0],
    ["Heure",HKEY_LOCAL_MACHINE,"Software\Policies\Microsoft\Windows\WindowsUpdate\AU","ScheduledInstallTime",REG_DWORD,eval(heure[0])]]
    apply_cles(cles)
    log('windows update a' + str(heure))      
     

def adminlocal(domain):
    try:
        log('domainusers = administrateurs' )      
        ret = win32net.NetLocalGroupAddMembers( None, 'administrateurs', 3, [{'domainandname': domain + '\\DomainUsers'}] )
    except:
        log(traceback.format_exc()) 
    
def add_dns_suffix():
    #    reg add HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters /V SearchList /D "%suffix%,%OLD_DNS%" /F
    suffix = read_reg(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','DhcpDomain')
    cles=[
    ["suffixDNS",HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\services\Tcpip\Parameters","NV Domain",REG_SZ,suffix],
    ["suffixDNS1",HKEY_LOCAL_MACHINE,"SYSTEM\CurrentControlSet\services\Tcpip\Parameters","Domain",REG_SZ,suffix]]
    apply_cles(cles)
    log('suffix dns = '  + str(suffix))      
    
def apply_refiles(os_ver):
    systemroot = os.environ['SYSTEMROOT']
    try:
        path =  sys.argv[1] + '\\' + os_ver
    except :
        path = os_ver   
    log("regfile " + os_ver + ' ' + path ) 
    if os.path.exists(path):
        for regfile in glob.glob(path + '\*.reg'):
            log(regfile)
            if os.path.isfile(systemroot + r'\syswow64\regedit'):
                subprocess.call([systemroot + r'\syswow64\regedit', '/s', regfile])  
            else:
                subprocess.call([systemroot + r'\regedit', '/s', regfile])  

def log(line):
    try:
        f =  sys.argv[1].replace('"','') + '\\joinlog.log'
    except :
        f = 'joinlog.log'
    try:    
        fsock = open(f, 'a')
        fsock.write(str(datetime.now()) + ' : ' +  str(line) + '\n')
        fsock.close()
        print line
    except:
        #pb pour ecrire dans le fichier de log, cle retire 
        pass

    
def getDomainFromDC(dc):
    if dc != '':
        cmd = "C:\\Windows\\System32\\nbtstat.exe -a " + dc
        with disable_file_system_redirection():
            try:
                output = subprocess.check_output(cmd , stderr=subprocess.STDOUT,shell=True)
            except Exception, e:
                output = str(e.output)
            log(output)
            for line in output.split('\n'):
                if '<1C>' in line:
                    return line.split('<1C>')[0].strip()

def getNameFromIP(ip):
    if ip != '':
        cmd = "C:\\Windows\\System32\\nbtstat.exe -A " + ip.replace(' ','') #+ " & exit 0"
        with disable_file_system_redirection():
            try:
                output = subprocess.check_output(cmd , stderr=subprocess.STDOUT,shell=True)
            except Exception, e:
                output = str(e.output)
            log(output)
            for line in output.split('\n'):
                if '<00>' in line:
                    log(line)
                    return line.split('<00>')[0].strip()
    
def test_hostname(hostname):
    forbidden_car = ('\\','/', ':', '*','?','"','<','>','|')
    if len(hostname) > 15:
        return False
    for  c in forbidden_car:
        if c in hostname:
            return False
    return True

class disable_file_system_redirection:
    if testOS() != 'XP':
        _disable = ctypes.windll.kernel32.Wow64DisableWow64FsRedirection
        _revert = ctypes.windll.kernel32.Wow64RevertWow64FsRedirection
    def __enter__(self):
        if testOS() != 'XP':
            self.old_value = ctypes.c_long()
            self.success = self._disable(ctypes.byref(self.old_value))
    def __exit__(self, type, value, traceback):
        if testOS() != 'XP':
            if self.success:
                self._revert(self.old_value)
                
                
                
