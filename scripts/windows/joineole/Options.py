# -*- coding: utf-8 -*-
#Boa:Frame:Frame2

import wx
import wx.lib.masked.timectrl
import wx.lib.masked.textctrl
import config
from fonctions import *
import os

def create(parent):
    return Frame2(parent)

[wxID_FRAME2, wxID_FRAME2BUTTONOKOPTIONS, wxID_FRAME2BUTTONSAVE, 
 wxID_FRAME2CHECKBOXACTIVEADMIN, wxID_FRAME2CHECKBOXADMINLOCAL, 
 wxID_FRAME2CHECKBOXCAS, wxID_FRAME2CHECKBOXDOMAINUSERS, 
 wxID_FRAME2CHECKBOXEXT, wxID_FRAME2CHECKBOXHDDENFILES, 
 wxID_FRAME2CHECKBOXMAJ, wxID_FRAME2CHECKBOXNUMLOCK, 
 wxID_FRAME2CHECKBOXRESTORESYS, wxID_FRAME2CHECKBOXSUFFIXDNS, 
 wxID_FRAME2CHECKBOXVEILLE, wxID_FRAME2NOTEBOOK1, wxID_FRAME2PANEL1, 
 wxID_FRAME2PANEL2, wxID_FRAME2PANEL3, wxID_FRAME2PANEL5, 
 wxID_FRAME2STATICLINE1, wxID_FRAME2STATICLINE2, wxID_FRAME2STATICTEXT1, 
 wxID_FRAME2STATICTEXT2, wxID_FRAME2STATICTEXT3, wxID_FRAME2STATICTEXT4, 
 wxID_FRAME2STATICTEXT5, wxID_FRAME2STATICTEXT6, wxID_FRAME2STATICTEXT7, 
 wxID_FRAME2STATICTEXT8, wxID_FRAME2TEXTCTRLADMIN2, wxID_FRAME2TEXTCTRLNTP, 
 wxID_FRAME2TEXTCTRLPASSWD2, wxID_FRAME2TEXTCTRLPASSWDADMIN, 
 wxID_FRAME2TIMECTRL1, 
] = [wx.NewId() for _init_ctrls in range(34)]

class Frame2(wx.Frame):
    def _init_coll_boxSizer1_Items(self, parent):
        # generated method, don't edit

        parent.AddWindow(self.notebook1, 0, border=0, flag=0)
        parent.AddWindow(self.panel5, 0, border=0, flag=0)

    def _init_coll_notebook1_Pages(self, parent):
        # generated method, don't edit

        parent.AddPage(imageId=-1, page=self.panel1, select=True,
              text=u'Utilisateurs')
        parent.AddPage(imageId=-1, page=self.panel2, select=False,
              text=u'Environnement')
        parent.AddPage(imageId=-1, page=self.panel3, select=False,
              text=u'Syst\xe8me')

    def _init_sizers(self):
        # generated method, don't edit
        self.boxSizer1 = wx.BoxSizer(orient=wx.VERTICAL)

        self._init_coll_boxSizer1_Items(self.boxSizer1)

        self.SetSizer(self.boxSizer1)

    def _init_ctrls(self, prnt):
        # generated method, don't edit
        wx.Frame.__init__(self, id=wxID_FRAME2, name=u'Frame2', parent=prnt,
              pos=wx.Point(486, 263), size=wx.Size(432, 328),
              style=wx.STAY_ON_TOP | wx.DEFAULT_FRAME_STYLE, title=u'Options')
        self.SetClientSize(wx.Size(416, 290))
        self.Bind(wx.EVT_CLOSE, self.OnFrame2Close)
        self.Bind(wx.EVT_KILL_FOCUS, self.OnFrame2KillFocus)

        self.notebook1 = wx.Notebook(id=wxID_FRAME2NOTEBOOK1, name='notebook1',
              parent=self, pos=wx.Point(0, 0), size=wx.Size(416, 256), style=0)

        self.panel1 = wx.Panel(id=wxID_FRAME2PANEL1, name='panel1',
              parent=self.notebook1, pos=wx.Point(0, 0), size=wx.Size(408, 228),
              style=wx.TAB_TRAVERSAL)

        self.panel2 = wx.Panel(id=wxID_FRAME2PANEL2, name='panel2',
              parent=self.notebook1, pos=wx.Point(0, 0), size=wx.Size(408, 228),
              style=wx.TAB_TRAVERSAL)

        self.panel3 = wx.Panel(id=wxID_FRAME2PANEL3, name='panel3',
              parent=self.notebook1, pos=wx.Point(0, 0), size=wx.Size(408, 228),
              style=wx.TAB_TRAVERSAL)

        self.staticText1 = wx.StaticText(id=wxID_FRAME2STATICTEXT1,
              label=u"Ajout d'un compte Administrateur", name='staticText1',
              parent=self.panel1, pos=wx.Point(16, 16), size=wx.Size(182, 16),
              style=0)

        self.staticText2 = wx.StaticText(id=wxID_FRAME2STATICTEXT2,
              label=u'login', name='staticText2', parent=self.panel1,
              pos=wx.Point(48, 40), size=wx.Size(27, 16), style=0)

        self.staticText3 = wx.StaticText(id=wxID_FRAME2STATICTEXT3,
              label=u'password', name='staticText3', parent=self.panel1,
              pos=wx.Point(32, 72), size=wx.Size(50, 16), style=0)

        self.textCtrladmin2 = wx.TextCtrl(id=wxID_FRAME2TEXTCTRLADMIN2,
              name=u'textCtrladmin2', parent=self.panel1, pos=wx.Point(104, 40),
              size=wx.Size(128, 23), style=0, value=u'')
        self.textCtrladmin2.Bind(wx.EVT_TEXT, self.OnTextCtrladmin2Text,
              id=wxID_FRAME2TEXTCTRLADMIN2)

        self.textCtrlpasswd2 = wx.TextCtrl(id=wxID_FRAME2TEXTCTRLPASSWD2,
              name=u'textCtrlpasswd2', parent=self.panel1, pos=wx.Point(104,
              72), size=wx.Size(128, 23), style=wx.TE_PASSWORD, value=u'')

        self.staticText4 = wx.StaticText(id=wxID_FRAME2STATICTEXT4,
              label=u'Activation du compte Administrateur', name='staticText4',
              parent=self.panel1, pos=wx.Point(16, 112), size=wx.Size(197, 16),
              style=0)

        self.checkBoxactiveadmin = wx.CheckBox(id=wxID_FRAME2CHECKBOXACTIVEADMIN,
              label=u'', name=u'checkBoxactiveadmin', parent=self.panel1,
              pos=wx.Point(232, 112), size=wx.Size(16, 15), style=0)
        self.checkBoxactiveadmin.SetValue(False)
        self.checkBoxactiveadmin.Bind(wx.EVT_CHECKBOX,
              self.OnCheckBoxactiveadminCheckbox,
              id=wxID_FRAME2CHECKBOXACTIVEADMIN)

        self.staticText5 = wx.StaticText(id=wxID_FRAME2STATICTEXT5,
              label=u'Mot de passe du compte administateur', name='staticText5',
              parent=self.panel1, pos=wx.Point(16, 136), size=wx.Size(207, 16),
              style=0)

        self.textCtrlpasswdadmin = wx.TextCtrl(id=wxID_FRAME2TEXTCTRLPASSWDADMIN,
              name=u'textCtrlpasswdadmin', parent=self.panel1, pos=wx.Point(240,
              136), size=wx.Size(110, 23), style=wx.TE_PASSWORD, value=u'')

        self.checkBoxnumlock = wx.CheckBox(id=wxID_FRAME2CHECKBOXNUMLOCK,
              label=u'Activation NumLock', name=u'checkBoxnumlock',
              parent=self.panel2, pos=wx.Point(24, 24), size=wx.Size(128, 15),
              style=0)
        self.checkBoxnumlock.SetValue(False)

        self.checkBoxcas = wx.CheckBox(id=wxID_FRAME2CHECKBOXCAS,
              label=u'D\xe9sactiver ctrl+alt+supp', name=u'checkBoxcas',
              parent=self.panel2, pos=wx.Point(24, 56), size=wx.Size(192, 15),
              style=0)
        self.checkBoxcas.SetValue(False)

        self.checkBoxveille = wx.CheckBox(id=wxID_FRAME2CHECKBOXVEILLE,
              label=u'D\xe9sactiver mise en veille', name=u'checkBoxveille',
              parent=self.panel2, pos=wx.Point(24, 96), size=wx.Size(192, 15),
              style=0)
        self.checkBoxveille.SetValue(False)
        self.checkBoxveille.Enable(True)

        self.checkBoxrestoresys = wx.CheckBox(id=wxID_FRAME2CHECKBOXRESTORESYS,
              label=u'D\xe9sactiver la restauration syst\xe8me',
              name=u'checkBoxrestoresys', parent=self.panel2, pos=wx.Point(24,
              128), size=wx.Size(224, 15), style=0)
        self.checkBoxrestoresys.SetValue(False)

        self.checkBoxhddenfiles = wx.CheckBox(id=wxID_FRAME2CHECKBOXHDDENFILES,
              label=u'Afficher les fichiers cach\xe9s',
              name=u'checkBoxhddenfiles', parent=self.panel2, pos=wx.Point(24,
              160), size=wx.Size(200, 15), style=0)
        self.checkBoxhddenfiles.SetValue(False)

        self.checkBoxext = wx.CheckBox(id=wxID_FRAME2CHECKBOXEXT,
              label=u'Afficher les extensions dont le type est connu',
              name=u'checkBoxext', parent=self.panel2, pos=wx.Point(24, 192),
              size=wx.Size(280, 15), style=0)
        self.checkBoxext.SetValue(False)

        self.staticText6 = wx.StaticText(id=wxID_FRAME2STATICTEXT6,
              label=u'serveur NTP', name='staticText6', parent=self.panel3,
              pos=wx.Point(16, 32), size=wx.Size(64, 16), style=0)

        self.textCtrlntp = wx.TextCtrl(id=wxID_FRAME2TEXTCTRLNTP,
              name=u'textCtrlntp', parent=self.panel3, pos=wx.Point(96, 24),
              size=wx.Size(152, 23), style=0, value=u'')

        self.checkBoxdomainusers = wx.CheckBox(id=wxID_FRAME2CHECKBOXDOMAINUSERS,
              label=u'DomainUsers administrateur du poste',
              name=u'checkBoxdomainusers', parent=self.panel1, pos=wx.Point(40,
              256), size=wx.Size(240, 15), style=0)
        self.checkBoxdomainusers.SetValue(False)

        self.staticText7 = wx.StaticText(id=wxID_FRAME2STATICTEXT7,
              label=u'Heure des mises \xe0 jour windows', name='staticText7',
              parent=self.panel3, pos=wx.Point(16, 96), size=wx.Size(169, 16),
              style=0)

        self.timeCtrl1 = wx.lib.masked.timectrl.TimeCtrl(display_seconds=False,
              fmt24hr=True, id=wxID_FRAME2TIMECTRL1, name='timeCtrl1',
              oob_color=wx.NamedColour('Yellow'), parent=self.panel3,
              pos=wx.Point(216, 96), size=wx.Size(43, 23), style=0,
              useFixedWidthFont=True, value='12:00:00 AM')

        self.panel5 = wx.Panel(id=wxID_FRAME2PANEL5, name='panel5', parent=self,
              pos=wx.Point(0, 256), size=wx.Size(416, 32),
              style=wx.TAB_TRAVERSAL)

        self.buttonsave = wx.Button(id=wxID_FRAME2BUTTONSAVE,
              label=u'Enregistrer', name=u'buttonsave', parent=self.panel5,
              pos=wx.Point(208, 0), size=wx.Size(88, 26), style=0)
        self.buttonsave.Bind(wx.EVT_BUTTON, self.OnButtonsaveButton,
              id=wxID_FRAME2BUTTONSAVE)

        self.checkBoxadminlocal = wx.CheckBox(id=wxID_FRAME2CHECKBOXADMINLOCAL,
              label=u'Utilisateurs administrateur locaux',
              name=u'checkBoxadminlocal', parent=self.panel1, pos=wx.Point(24,
              184), size=wx.Size(344, 15), style=0)
        self.checkBoxadminlocal.SetValue(False)
        self.checkBoxadminlocal.SetLabelText(u'Utilisateurs du domaine administrateurs locaux (horus)')

        self.staticLine1 = wx.StaticLine(id=wxID_FRAME2STATICLINE1,
              name='staticLine1', parent=self.panel1, pos=wx.Point(40, 104),
              size=wx.Size(352, 2), style=0)

        self.staticLine2 = wx.StaticLine(id=wxID_FRAME2STATICLINE2,
              name='staticLine2', parent=self.panel1, pos=wx.Point(41, 168),
              size=wx.Size(351, 2), style=0)

        self.checkBoxMaj = wx.CheckBox(id=wxID_FRAME2CHECKBOXMAJ,
              label=u"Changer l'heures de MAJ Windows", name=u'checkBoxMaj',
              parent=self.panel3, pos=wx.Point(16, 72), size=wx.Size(240, 15),
              style=0)
        self.checkBoxMaj.SetValue(False)
        self.checkBoxMaj.Bind(wx.EVT_CHECKBOX, self.OnCheckBoxMajCheckbox,
              id=wxID_FRAME2CHECKBOXMAJ)

        self.staticText8 = wx.StaticText(id=wxID_FRAME2STATICTEXT8, label=u'',
              name='staticText8', parent=self.panel5, pos=wx.Point(32, 8),
              size=wx.Size(0, 16), style=0)

        self.checkBoxsuffixdns = wx.CheckBox(id=wxID_FRAME2CHECKBOXSUFFIXDNS,
              label=u'Utiliser le suffix DNS du dhcp comme suffix global',
              name=u'checkBoxsuffixdns', parent=self.panel3, pos=wx.Point(16,
              152), size=wx.Size(336, 15), style=0)
        self.checkBoxsuffixdns.SetValue(False)

        self.buttonOKoptions = wx.Button(id=wxID_FRAME2BUTTONOKOPTIONS,
              label=u'OK', name=u'buttonOKoptions', parent=self.panel5,
              pos=wx.Point(320, 0), size=wx.Size(88, 26), style=0)
        self.buttonOKoptions.SetLabelText(u'OK')
        self.buttonOKoptions.SetToolTipString(u'')
        self.buttonOKoptions.Bind(wx.EVT_BUTTON, self.OnButtonOKoptionsButton,
              id=wxID_FRAME2BUTTONOKOPTIONS)

        self._init_coll_notebook1_Pages(self.notebook1)

        self._init_sizers()

    def __init__(self, parent):
        self._init_ctrls(parent)
        self.Centre()
        self.dic_conf = dict()
        try:
            f =  sys.argv[1] + '\joineole.cfg'
        except :
            f =  'joineole.cfg'          
        self.log("options joineole.cfg " + f)
        self.conf = config.Config(f)
        self.dic_conf = self.conf.get_conf()
        self.tmp_dic_conf = dict()
        self.tmp_conf = config.Config('tmp.cfg')
        #self.tmp_dic_conf = self.tmp_conf.get_conf()  
        try :
            self.textCtrladmin2.SetValue(self.dic_conf['admin2'])
            self.textCtrlpasswd2.SetValue(self.dic_conf['passwd2'].decode('base64'))
            self.checkBoxactiveadmin.SetValue(eval(self.dic_conf['activeadmin']))
            self.textCtrlpasswdadmin.SetValue(self.dic_conf['passwdadmin'].decode('base64'))
            self.checkBoxnumlock.SetValue(eval(self.dic_conf['numlock']))
            self.checkBoxcas.SetValue(eval(self.dic_conf['cas']))
            self.checkBoxveille.SetValue(eval(self.dic_conf['veille']))
            self.checkBoxrestoresys.SetValue(eval(self.dic_conf['restoresys']))
            self.checkBoxhddenfiles.SetValue(eval(self.dic_conf['hiddenfiles']))
            self.checkBoxext.SetValue(eval(self.dic_conf['showext']))
            self.textCtrlntp.SetValue(self.dic_conf['ntp'])
            self.timeCtrl1.SetValue(self.dic_conf['timemaj'])   
            self.checkBoxadminlocal.SetValue(eval(self.dic_conf['adminlocal']))
            self.checkBoxMaj.SetValue(eval(self.dic_conf['change_maj_time']))
            self.checkBoxsuffixdns.SetValue(eval(self.dic_conf['suffix_dns']))            
        except:
            pass
        self.textCtrlpasswdadmin.Enable(self.checkBoxactiveadmin.Value)
        self.textCtrlpasswd2.Enable(self.textCtrladmin2.GetValue() != '')
        self.timeCtrl1.Enable(self.checkBoxMaj.Value)        

            

    def OnButtonsaveButton(self, event):
        self.dic_conf['admin2'] = self.textCtrladmin2.GetValue()
        self.dic_conf['passwd2']  = self.textCtrlpasswd2.GetValue().encode('base64')
        self.dic_conf['activeadmin']  = self.checkBoxactiveadmin.GetValue()
        self.dic_conf['passwdadmin']  = self.textCtrlpasswdadmin.GetValue().encode('base64')
        self.dic_conf['numlock']  = self.checkBoxnumlock.GetValue()
        self.dic_conf['cas']  = self.checkBoxcas.GetValue()
        self.dic_conf['veille']  = self.checkBoxveille.GetValue()
        self.dic_conf['restoresys']  = self.checkBoxrestoresys.GetValue()
        self.dic_conf['hiddenfiles']  = self.checkBoxhddenfiles.GetValue()
        self.dic_conf['showext']  = self.checkBoxext.GetValue()
        self.dic_conf['ntp']  = self.textCtrlntp.GetValue()
        self.dic_conf['timemaj']  = self.timeCtrl1.GetValue()  
        self.dic_conf['adminlocal'] = self.checkBoxadminlocal.GetValue()
        self.dic_conf['change_maj_time'] = self.checkBoxMaj.GetValue()
        self.dic_conf['suffix_dns'] = self.checkBoxsuffixdns.GetValue()                    
        self.conf.set_conf(dict(self.tmp_dic_conf.items() + self.dic_conf.items()))
        self.staticText8.SetLabelText(u'Configuration sauvegardée')


    def OnFrame2Close(self, event):
        try:
            f = sys.argv[1] + '\\tmp.cfg'
        except :
            f = 'tmp.cfg'        
        if os.path.isfile(f):
            self.log("remove " + f)
            os.remove(f)
        self.Hide()

    def OnFrame2KillFocus(self, event):
        pass
    
    def log(self, line):
        try:
            f =  sys.argv[1].replace('"','') + '\\joinlog.log'
        except :
            f = 'joinlog.log'
        fsock = open(f, 'a')
        fsock.write(str(datetime.now()) + ' : ' +  line + '\n')
        fsock.close()

    def OnCheckBoxactiveadminCheckbox(self, event):
        self.textCtrlpasswdadmin.Enable(self.checkBoxactiveadmin.Value)
        event.Skip()

    def OnTextCtrladmin2Text(self, event):
        self.textCtrlpasswd2.Enable(self.textCtrladmin2.GetValue() != '')
        event.Skip()

    def OnCheckBoxMajCheckbox(self, event):
        self.timeCtrl1.Enable(self.checkBoxMaj.Value)        
        event.Skip()

    def OnButtonOKoptionsButton(self, event):
        self.Close()
        event.Skip()
