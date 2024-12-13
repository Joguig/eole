# -*- coding: utf-8 -*-
#!/usr/bin/env python
#Boa:App:BoaApp

import wx, sys
if hasattr(sys, 'setdefaultencoding'):
    import locale
    loc = locale.getdefaultlocale()
    if loc[1]:
        encoding = loc[1]
        sys.setdefaultencoding(encoding)

import Frame1
import Options
import config
import fonctions
import registre

modules ={'Frame1': [1, 'Main frame of Application', 'Frame1.py'],
 u'Options': [0, '', u'Options.py'],
 u'config': [0, '', u'config.py'],
 u'fonctions': [0, '', u'fonctions.py'],
 u'registre': [0, '', u'registre.py']}

class BoaApp(wx.App):
    def OnInit(self):
        self.main = Frame1.create(None)
        self.main.Show()
        self.SetTopWindow(self.main)
        return True

def main():
    application = BoaApp(0)
    application.MainLoop()

if __name__ == '__main__':  
    main()
