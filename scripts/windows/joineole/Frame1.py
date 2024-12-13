# -*- coding: utf-8 -*-
#Boa:Frame:Frame1

import wx
import wx.lib.masked.ipaddrctrl
#import ipaddrctrl
from fonctions import *

import win32com.client
import pywintypes
import wx
import os,sys
import win32api
import win32netcon
import win32file
import win32con
import win32wnet
import win32process, win32event
from ctypes import *
import  wx.lib.masked as m
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


def create(parent):
    return Frame1(parent)

[wxID_FRAME1, wxID_FRAME1BUTTONJOIN, wxID_FRAME1BUTTONOPTIONS,
 wxID_FRAME1BUTTONSAVE, wxID_FRAME1CHECKBOXINSTALL, wxID_FRAME1CHECKBOXREBOOT,
 wxID_FRAME1COMBOBOXDOM, wxID_FRAME1IPADDRCTRL1, wxID_FRAME1PANEL1,
 wxID_FRAME1STATICTEXT1, wxID_FRAME1STATICTEXT2, wxID_FRAME1STATICTEXT3,
 wxID_FRAME1STATICTEXT4, wxID_FRAME1STATICTEXT5, wxID_FRAME1STATICTEXTNOMMACH,
 wxID_FRAME1STATUSBAR1, wxID_FRAME1TEXTCTRLADMIN, wxID_FRAME1TEXTCTRLHOSTNAME,
 wxID_FRAME1TEXTCTRLPASSWORD, wxID_FRAME1TEXTCTRLSERV,
] = [wx.NewId() for _init_ctrls in range(20)]

class Frame1(wx.Frame):
    def _init_ctrls(self, prnt):
        # generated method, don't edit
        wx.Frame.__init__(self, id=wxID_FRAME1, name='', parent=prnt,
              pos=wx.Point(767, 300), size=wx.Size(296, 380),
              style=wx.TAB_TRAVERSAL | wx.SYSTEM_MENU | wx.CAPTION | wx.CLIP_CHILDREN | wx.CLOSE_BOX,
              title=u'joineole')
        self.SetClientSize(wx.Size(280, 342))
        self.SetIcon(wx.Icon(u'eole.ico', wx.BITMAP_TYPE_ICO))
        self.Center(wx.BOTH)
        self.Bind(wx.EVT_ACTIVATE, self.OnFrame1Activate)

        self.panel1 = wx.Panel(id=wxID_FRAME1PANEL1, name='panel1', parent=self,
              pos=wx.Point(0, 0), size=wx.Size(280, 319),
              style=wx.TAB_TRAVERSAL)

        self.staticTextNomMach = wx.StaticText(id=wxID_FRAME1STATICTEXTNOMMACH,
              label=u'Nom de la machine', name=u'staticTextNomMach',
              parent=self.panel1, pos=wx.Point(2, 8), size=wx.Size(118, 16),
              style=0)

        self.textCtrlServ = wx.TextCtrl(id=wxID_FRAME1TEXTCTRLSERV,
              name=u'textCtrlServ', parent=self.panel1, pos=wx.Point(136, 72),
              size=wx.Size(128, 21), style=wx.TE_PROCESS_ENTER, value=u'')
        self.textCtrlServ.Bind(wx.EVT_TEXT_ENTER, self.OnTextCtrlServTextEnter,
              id=wxID_FRAME1TEXTCTRLSERV)

        self.textCtrlAdmin = wx.TextCtrl(id=wxID_FRAME1TEXTCTRLADMIN,
              name='textCtrlAdmin', parent=self.panel1, pos=wx.Point(136, 136),
              size=wx.Size(124, 21), style=0, value='admin')

        self.textCtrlPassword = wx.TextCtrl(id=wxID_FRAME1TEXTCTRLPASSWORD,
              name='textCtrlPassword', parent=self.panel1, pos=wx.Point(136,
              168), size=wx.Size(124, 21), style=wx.TE_PASSWORD, value=u'')
        self.textCtrlPassword.SetEditable(True)

        self.checkBoxInstall = wx.CheckBox(id=wxID_FRAME1CHECKBOXINSTALL,
              label=u'Installation du client Scribe', name=u'checkBoxInstall',
              parent=self.panel1, pos=wx.Point(80, 200), size=wx.Size(192, 13),
              style=0)
        self.checkBoxInstall.SetValue(True)

        self.checkBoxReboot = wx.CheckBox(id=wxID_FRAME1CHECKBOXREBOOT,
              label=u'Red\xe9marrage automatique', name=u'checkBoxReboot',
              parent=self.panel1, pos=wx.Point(80, 224), size=wx.Size(176, 13),
              style=0)
        self.checkBoxReboot.SetValue(True)

        self.buttonJoin = wx.Button(id=wxID_FRAME1BUTTONJOIN,
              label=u'&Joindre le domaine', name='buttonJoin',
              parent=self.panel1, pos=wx.Point(80, 248), size=wx.Size(120, 23),
              style=0)
        self.buttonJoin.Bind(wx.EVT_BUTTON, self.OnButtonJoinButton,
              id=wxID_FRAME1BUTTONJOIN)

        self.buttonSave = wx.Button(id=wxID_FRAME1BUTTONSAVE,
              label=u'&Enregistrer', name='buttonSave', parent=self.panel1,
              pos=wx.Point(8, 280), size=wx.Size(75, 23), style=0)
        self.buttonSave.Bind(wx.EVT_BUTTON, self.OnButtonSaveButton,
              id=wxID_FRAME1BUTTONSAVE)

        self.statusBar1 = wx.StatusBar(id=wxID_FRAME1STATUSBAR1,
              name='statusBar1', parent=self, style=0)
        self.statusBar1.SetStatusText(u'Pr\xeat')
        self.SetStatusBar(self.statusBar1)

        self.staticText1 = wx.StaticText(id=wxID_FRAME1STATICTEXT1,
              label=u'Nom du serveur', name='staticText1', parent=self.panel1,
              pos=wx.Point(4, 76), size=wx.Size(116, 13), style=0)

        self.staticText2 = wx.StaticText(id=wxID_FRAME1STATICTEXT2,
              label=u'Nom du domaine', name='staticText2', parent=self.panel1,
              pos=wx.Point(4, 44), size=wx.Size(116, 13), style=0)

        self.staticText3 = wx.StaticText(id=wxID_FRAME1STATICTEXT3,
              label=u'IP du serveur', name='staticText3', parent=self.panel1,
              pos=wx.Point(4, 108), size=wx.Size(132, 13), style=0)

        self.staticText4 = wx.StaticText(id=wxID_FRAME1STATICTEXT4,
              label=u'Utilisateur', name='staticText4', parent=self.panel1,
              pos=wx.Point(4, 140), size=wx.Size(108, 13), style=0)

        self.staticText5 = wx.StaticText(id=wxID_FRAME1STATICTEXT5,
              label=u'Mot de passe', name='staticText5', parent=self.panel1,
              pos=wx.Point(4, 172), size=wx.Size(108, 13), style=0)

        self.comboBoxDom = wx.ComboBox(choices=[], id=wxID_FRAME1COMBOBOXDOM,
              name=u'comboBoxDom', parent=self.panel1, pos=wx.Point(136, 40),
              size=wx.Size(130, 21), style=wx.TE_PROCESS_ENTER, value=u'')
        self.comboBoxDom.SetLabel(u'')
        self.comboBoxDom.Bind(wx.EVT_COMBOBOX, self.OnComboBoxDomCombobox,
              id=wxID_FRAME1COMBOBOXDOM)
        self.comboBoxDom.Bind(wx.EVT_TEXT_ENTER, self.OnComboBoxDomTextEnter,
              id=wxID_FRAME1COMBOBOXDOM)

        self.textCtrlHostname = wx.TextCtrl(id=wxID_FRAME1TEXTCTRLHOSTNAME,
              name=u'textCtrlHostname', parent=self.panel1, pos=wx.Point(136,
              8), size=wx.Size(128, 21), style=0, value=u'')

        self.buttonOptions = wx.Button(id=wxID_FRAME1BUTTONOPTIONS,
              label=u'Options', name=u'buttonOptions', parent=self.panel1,
              pos=wx.Point(176, 280), size=wx.Size(88, 26), style=0)
        self.buttonOptions.Bind(wx.EVT_BUTTON, self.OnButtonOptionsButton,
              id=wxID_FRAME1BUTTONOPTIONS)

        self.ipAddrCtrl1 = wx.lib.masked.ipaddrctrl.IpAddrCtrl(id=wxID_FRAME1IPADDRCTRL1,
              name='ipAddrCtrl1', parent=self.panel1, pos=wx.Point(144, 104),
              size=wx.Size(113, 23), style=wx.TE_PROCESS_TAB, value='')
        self.ipAddrCtrl1.Bind(wx.EVT_KEY_UP, self.OnIpAddrCtrl1KeyUp)

    def __init__(self, parent):
        self._init_ctrls(parent)
        log("Dossier courant " + str(sys.argv) )
        self.OS_ver = testOS()
        self.is64bit = '64' if win32process.IsWow64Process() else '32'
        self.is_Scribe = False
        self.checkBoxInstall.SetValue(False)
        self.textCtrlHostname.SetValue(win32api.GetComputerName())
        if self.OS_ver != 'XP':
            networks_private()
            activate_share()
        #else:
        #    self.textCtrlHostname.Disable()
        self.dic_conf = dict()
        self.conf = self.init_conf('joineole.cfg')
        self.statusBar1.SetStatusText('Version 1.2 : Windows ' + str(self.OS_ver) + ' ' + self.is64bit + ' bits' )
        self.dic_conf = self.conf.get_conf()
        if self.dic_conf != {}:
            try:
                self.comboBoxDom.SetValue(self.dic_conf['domaine'])
                self.textCtrlServ.SetValue(self.dic_conf['serveur'])
                self.ipAddrCtrl1.SetValue(self.dic_conf['ip'])
                self.textCtrlAdmin.SetValue(self.dic_conf['admin'])
                self.textCtrlPassword.SetValue(self.dic_conf['passwd'].decode('base64'))
                self.buttonJoin.SetFocus()
            except:
                self.dic_conf['domaine'] = self.comboBoxDom.GetValue()
                self.dic_conf['serveur'] = self.textCtrlServ.GetValue()
                self.dic_conf['ip'] = self.ipAddrCtrl1.GetAddress()
                self.dic_conf['admin'] = self.textCtrlAdmin.GetValue()
                self.dic_conf['passwd'] = self.textCtrlPassword.GetValue().encode('base64')

        order = (self.comboBoxDom, self.textCtrlServ, self.ipAddrCtrl1, self.textCtrlAdmin,
            self.textCtrlPassword, self.checkBoxInstall, self.checkBoxReboot , self.buttonJoin)
        for i in xrange(len(order) - 1):
           order[i+1].MoveAfterInTabOrder(order[i])
        for dom in finddoms():
            self.comboBoxDom.Append(dom)
        self.options = Options.Frame2(self)
        self.update_checkboxInstall()

    def init_conf(self, f_cfg):
        try:
            log("Dossier courant " + str(sys.argv[1]) )
            f =  sys.argv[1] + '\\' + f_cfg
        except :
            log("Dossier courant " + str(sys.argv) )
            f =  f_cfg
        conf = config.Config(f)
        return conf

    # les boutons     :
    # "Enregistrer"
    def OnButtonSaveButton(self, event):
        self.dic_conf['domaine'] = self.comboBoxDom.GetValue()
        self.dic_conf['serveur'] = self.textCtrlServ.GetValue()
        self.dic_conf['ip'] = self.ipAddrCtrl1.GetAddress()
        self.dic_conf['admin'] = self.textCtrlAdmin.GetValue()
        self.dic_conf['passwd'] = self.textCtrlPassword.GetValue().encode('base64')
        self.tmp_conf = self.init_conf('joineole.cfg')
        self.tmp_dic_conf = self.tmp_conf.get_conf()
        self.conf.set_conf(dict(self.tmp_dic_conf.items() + self.dic_conf.items()))

    # "Joindre le domaine"
    def OnButtonJoinButton(self, event):
        if not test_hostname(self.textCtrlHostname.GetValue()):
            self.statusBar1.SetStatusText('Nom de station incorrect')
            return
        self.read_conf()
        server = self.textCtrlServ.GetValue()
        dom, servip = self.comboBoxDom.GetValue(), self.ipAddrCtrl1.GetAddress()
        user, passwd = self.textCtrlAdmin.GetValue(), self.textCtrlPassword.GetValue()
        if self.OS_ver != 'XP':
            if self.OS_ver == '10':
                force_smb()
            cle_registre()
            rename_7(self.textCtrlHostname.GetValue())
        else:
            renomme_station(self.textCtrlHostname.GetValue(),self.comboBoxDom.GetValue())
        # joindre le domaine
        self.statusBar1.SetStatusText('Jonction au domaine "%s"...'%dom)
        ret = exec_func(joindom, dom, user, passwd)
        log("joindom retourne "   + str(ret))
        #if ret == 1355:
        #    c = wmi.WMI ()
        #    for nic in c.Win32_NetworkAdapterConfiguration (IPEnabled=True):
        #      nic.SetWINSServer (find_ip(server, ""))
        #ret = exec_func(joindom, dom, user, passwd)
        if ret != 0 :
            return
        domainpardefaut(self.comboBoxDom.GetValue())
        #si on a deja enregistre les options
        if self.dic_conf.has_key('admin2'):
            log(" mise en place des options " + str(self.dic_conf))
            if self.dic_conf['admin2'] != "": adduser(self.dic_conf['admin2'], self.dic_conf['passwd2'].decode('base64') )
            if self.dic_conf['activeadmin'] == 'True' : active_admin(self.dic_conf['passwdadmin'].decode('base64'))
            if self.dic_conf['numlock']  == 'True': active_numlock(self.OS_ver)
            if self.dic_conf['cas'] == 'True': active_ctrl_alt_supp()
            if self.dic_conf['veille']  == 'True':desactive_veille()
            if self.dic_conf['restoresys']  == 'True': restore_sys()
            if self.dic_conf['hiddenfiles']  == 'True': show_hidden_files(self.OS_ver)
            if self.dic_conf['showext']  == 'True':show_ext(self.OS_ver)
            if self.dic_conf['ntp']  != "": conf_ntp(self.dic_conf['ntp'])
            if self.dic_conf['change_maj_time'] == 'True': conf_maj(self.dic_conf['timemaj'])
            if self.dic_conf['suffix_dns'] == 'True': add_dns_suffix()
            if self.dic_conf['adminlocal']  == 'True':
                try:
                    joindom(dom, user, passwd)
                    adminlocal(dom)
                except:
                    log("erreur pour ajouter domainsUsers")
                    log(traceback.format_exc())
            if self.dic_conf['suffix_dns'] == 'True': add_dns_suffix()

        self.statusBar1.SetStatusText('Jonction au domaine "%s" termin\xe9e, red\xe9marrage n\xe9cessaire'%dom)
        if self.checkBoxInstall.GetValue():
            # montage du partage "perso"
            unc = r'\\%s\%s'%(servip, 'perso')
            self.statusBar1.SetStatusText('Connexion a "%s"...'%unc)
            drive = exec_func(connect,'u:', unc, user, passwd)
            if not drive:
                self.statusBar1.SetStatusText('Connexion a "%s" impossible !!!'%unc)
                log('Connexion a "%s" impossible !!!'%unc)
                return
            cmdscribe = r'%s\client\cliscribe-setup.exe'%drive
            cmdhorus = r'%s\client\clieole-setup.exe'%drive
            args = '%s /SILENT /NORESTART'
            if os.path.exists(cmdscribe):
                cmd = args%cmdscribe
            else:
                cmd = args%cmdhorus

            self.statusBar1.SetStatusText('Ex\xe9cution de "%s"...'%cmd)
            if exec_func(lancecmd, cmd, hide=True) != 0:
                return disconnect(drive)
            # Installation du service de MAJ du client
            cmdscribe = r'%s\client\cliscribe-updater-setup.exe'%drive
            cmdhorus = r'%s\client\clieole-updater-setup.exe'%drive
            args = '%s /SILENT /NORESTART'
            if os.path.exists(cmdscribe):
                cmd = args%cmdscribe
            else:
                cmd = args%cmdhorus
            self.statusBar1.SetStatusText('Ex\xe9cution de "%s"...'%cmd)
            if exec_func(lancecmd, cmd, hide=True) != 0:
                return disconnect(drive)
            disconnect(drive)
        self.statusBar1.SetStatusText('Installation termin\xe9e.')
        apply_refiles(self.OS_ver)
        if self.checkBoxReboot.GetValue():
            self.statusBar1.SetStatusText('Red\xe9marrage...')
            reboot()


    def OnComboBoxDomCombobox(self, event):
        dc = finddc(self.comboBoxDom.GetValue())
        if dc != None:
            self.textCtrlServ.SetValue(dc)
            self.ipAddrCtrl1.SetValue(find_ip(dc))
            self.update_checkboxInstall()

    def OnComboBoxDomTextEnter(self, event):
        dc = finddc(self.comboBoxDom.GetValue())
        if dc != None:
            self.textCtrlServ.SetValue(dc)
            self.ipAddrCtrl1.SetValue(find_ip(dc))
            self.update_checkboxInstall()

    def OnButtonOptionsButton(self, event):
        self.dic_conf['domaine'] = self.comboBoxDom.GetValue()
        self.dic_conf['serveur'] = self.textCtrlServ.GetValue()
        self.dic_conf['ip'] = self.ipAddrCtrl1.GetAddress()
        self.dic_conf['admin'] = self.textCtrlAdmin.GetValue()
        self.dic_conf['passwd'] = self.textCtrlPassword.GetValue().encode('base64')
        tmp_conf = config.Config('tmp.cfg')
        tmp_conf.set_conf(self.dic_conf)
        self.options.Show(True)

    def update_checkboxInstall(self):
        if self.ipAddrCtrl1.IsValid() and not self.ipAddrCtrl1.IsEmpty():
            self.is_Scribe = testportscribe(self.ipAddrCtrl1.GetAddress())
            if not self.is_Scribe :
                self.checkBoxInstall.SetLabelText(u'Installation du client Horus')
                self.checkBoxInstall.Enable()
            else:
                self.checkBoxInstall.SetLabelText(u'Installation du client Scribe')
                self.checkBoxInstall.Enable()
                self.checkBoxInstall.SetValue(self.is_Scribe)
        else:
            self.checkBoxInstall.SetLabelText(u'Installation du client ...')
            self.checkBoxInstall.SetValue(False)
            #self.checkBoxInstall.Disable()

    def OnComboBoxDomText(self, event):
        pass

    def OnTextCtrlServTextEnter(self, event):
        try:
            dom = getDomainFromDC(self.textCtrlServ.GetValue())
            self.comboBoxDom.SetValue(dom)
            self.ipAddrCtrl1.SetValue(find_ip(self.textCtrlServ.GetValue()))
            self.update_checkboxInstall()
        except:
            pass


    def OnIpAddrCtrl1TextEnter(self, event):
        code = event.GetKeyCode()
        print code
        try:
            dom = getDomainFromDC(self.textCtrlServ.GetValue())
            self.comboBoxDom.SetValue(dom)
            self.textCtrlServ.SetValue(getNameFromIP(self.ipAddrCtrl1.GetAddress()))
            self.update_checkboxInstall()
        except:
            pass

    def OnIpAddrCtrl1Text(self, event):
        print 'text'
        code = event.GetKeyCode()
        print code
        if self.ipAddrCtrl1.IsValid():
            try:
                self.textCtrlServ.SetValue(getNameFromIP(self.ipAddrCtrl1.GetAddress()))
                dom = getDomainFromDC(self.textCtrlServ.GetValue())
                self.comboBoxDom.SetValue(dom)
                self.update_checkboxInstall()
            except:
                pass

    def OnIpAddrCtrl1KeyUp(self, event):
        code = event.GetKeyCode()
        uni_key_code = event.GetUnicodeKey()
        if code == wx.WXK_RETURN or uni_key_code == 13:
            log("enter")
            if self.ipAddrCtrl1.IsValid():
                #try:
                self.textCtrlServ.SetValue(getNameFromIP(self.ipAddrCtrl1.GetAddress()))
                dom = getDomainFromDC(self.textCtrlServ.GetValue())
                self.comboBoxDom.SetValue(dom)
                log(str(dom))
                self.update_checkboxInstall()
                #except:
                #    pass

    def OnDot(self, event):
        """
        Defines what action to take when the '.' character is typed in the
        control.  By default, the current field is right-justified, and the
        cursor is placed in the next field.
        """
        print "my OnDot"
##        dbg('IpAddrCtrl::OnDot', indent=1)
        pos = self._adjustPos(self._GetInsertionPoint(), event.GetKeyCode())
        oldvalue = self.GetValue()
        edit_start, edit_end, slice = self._FindFieldExtent(pos, getslice=True)
        #if not event.ShiftDown():
        if pos > edit_start and pos < edit_end:
            # clip data in field to the right of pos, if adjusting fields
            # when not at delimeter; (assumption == they hit '.')
            newvalue = oldvalue[:pos] + ' ' * (edit_end - pos) + oldvalue[edit_end:]
            self._SetValue(newvalue)
            self._SetInsertionPoint(pos)
##        dbg(indent=0)
        return self._OnChangeField(event)

    def read_conf(self):
        self.tmp_conf = self.init_conf('joineole.cfg')
        self.tmp_dic_conf = self.tmp_conf.get_conf()
        self.dic_conf = dict(self.dic_conf.items() + self.tmp_dic_conf.items())
        self.dic_conf['domaine'] = self.comboBoxDom.GetValue()
        self.dic_conf['serveur'] = self.textCtrlServ.GetValue()
        self.dic_conf['ip'] = self.ipAddrCtrl1.GetAddress()
        self.dic_conf['admin'] = self.textCtrlAdmin.GetValue()
        self.dic_conf['passwd'] = self.textCtrlPassword.GetValue().encode('base64')
        log("read_conf")
        log(str(self.dic_conf))

    def OnFrame1Activate(self, event):
        #self.read_conf()
        event.Skip()
