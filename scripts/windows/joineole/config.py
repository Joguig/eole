# -*- coding: utf-8 -*-

import ConfigParser
import os

class Config:
    def __init__(self,file):
        self.config = ConfigParser.RawConfigParser()
        self.file= file.replace('"','')
        self.cfg = dict()

    def get_file(self):
        return self.file

    def set_file(self, f):
        self.file= f
          
    def get_conf(self):
        if os.path.isfile(self.file): 
            self.config.read(self.file)
            if self.config.has_section('global'):
                self.cfg = dict(self.config.items('global'))
            else:
                self.cfg = dict()
        else:
            self.cfg = dict()
        return self.cfg        
        
        
    def set_conf(self, dic):
        if not self.config.has_section('global'):
            self.config.add_section('global')
        for k,v in dic.items():
            self.config.set('global', k, v)
        # Writing our configuration file to 'example.cfg'
        with open(self.file, 'wb') as configfile:
            self.config.write(configfile)
            
    def apply_conf(self):
        pass
        
    
