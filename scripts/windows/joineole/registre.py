# -*- coding: utf-8 -*-

from _winreg import *
import win32security
import win32con
import win32api
import platform
import win32process
import _winreg
import ctypes
from datetime import datetime
import traceback


def apply_reg(os_ver):
    if os.path.exists(sys.argv[1] + '\\' + os_ver):
        for regfile in glob.glob(sys.argv[1] + '\\' + os_ver + '\\*.reg'):
            os.system("regedit /s " + regfile)

def load_hive(os_ver):
    flags = win32security.TOKEN_ADJUST_PRIVILEGES | win32security.TOKEN_QUERY
    htoken = win32security.OpenProcessToken(win32api.GetCurrentProcess(),flags)
    loadid = win32security.LookupPrivilegeValue(None,'SeRestorePrivilege')
    newprivlist = [(loadid, win32security.SE_PRIVILEGE_ENABLED)]
    win32security.AdjustTokenPrivileges(htoken,0,newprivlist)
    if os_ver == 'XP':
        ntuser_path = "C:\\Documents and Settings\\Default User\\NTUSER.dat"
    else:
        ntuser_path = "C:\\Users\Default\\NTUSER.dat"
    win32api.RegLoadKey(win32con.HKEY_USERS,"ttt",ntuser_path)

def read_reg(ruche, cle,val):
    data = ''
    try:
        if platform.architecture()[0] == '64bit' or win32process.IsWow64Process():
            key = _winreg.OpenKey( ruche, cle ,0, _winreg.KEY_READ | _winreg.KEY_WOW64_64KEY)
        else:
            key = _winreg.OpenKey( ruche, cle,0, _winreg.KEY_READ)
        (data,typevaleur) = _winreg.QueryValueEx(key,val)
        _winreg.CloseKey(key)
    except:
        log(traceback.format_exc())
        pass
    return data


def unload_hive():
    win32api.RegUnLoadKey(win32con.HKEY_USERS,"ttt")

            
def apply_cles(cles):


    for cle in cles:
        ruche = cle[1]
        keypath = cle[2]
        key = cle[3]
        keytype = cle[4]
        keyval = cle[5]
        try:
            regkey = OpenKeyEx(ruche, keypath, 0, KEY_ALL_ACCESS|KEY_WOW64_64KEY)
        except:
            log(traceback.format_exc())
            log('attention creation ' + str(ruche) + ' ' + str(keypath))
            try:
                regkey = CreateKeyEx(ruche, keypath, 0, KEY_ALL_ACCESS|KEY_WOW64_64KEY)  
            except:
                log(traceback.format_exc())
                continue
        log(str(key) + ' ' + str(keyval) + str(keytype))
        try:
            is_reflect = _winreg.QueryReflectionKey(regkey)
            _winreg.EnableReflectionKey(regkey)
        except :
            pass
        SetValueEx(regkey, key, 0, keytype, keyval)
        try:
            if is_reflect: _winreg.DisableReflectionKey(regkey)
        except:
            log(traceback.format_exc())
            pass
        CloseKey(regkey)


def log(line):
    try:
        f =  sys.argv[1].replace('"','') + '\\joinlog.log'
    except :
        f = 'joinlog.log'
    try: 
        fsock = open(f, 'a')
        fsock.write(str(datetime.now()) + ' : ' +  str(line) + '\n')
        fsock.close()
    except:
        #pb pour ecrire dans le fichier de log, cle retire 
        pass
    #print line
    