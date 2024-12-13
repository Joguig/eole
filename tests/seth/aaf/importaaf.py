#!/usr/bin/env python
# -*- coding: utf-8 -*-
from eoleaaf.parseaaf import main
from eoleaaf.config import path_aaf_complet
# print(path_aaf_complet)
# par defaut : /home/aaf-complet
#try:
#    if sys.argv[1] == 'all':
#        reset_db = True
#except:
reset_db = False
main(path_aaf_complet, reset_db)
