#! /usr/bin/python3
# -*- coding: utf-8 -*-

import sys 
import traceback
from creole.var_loader import convert_value, force_unicode
from creole.loader import creole_loader, config_save_values
from curses.ascii import isdigit

# exemple !
#python3 CreoleSet_Multi.py <<EOF
#set activer_nut oui
#set nut_ups_daemon non
#set nut_monitor_foreign_name 0 dummy
#set nut_monitor_foreign_host 0 10.1.3.1
#set nut_monitor_foreign_password 0 nut_monitor_password
#set nut_monitor_foreign_user 0 amon-ups
#EOF

def main():
    try:
        namespace = 'creole'
        config = creole_loader(rw=True, owner='creoleset', load_extra=True)
        #print ( "config: " + str(config) )
        for line in sys.stdin:
            line = line.strip()
            if len(line) == 0:
                continue 
            if line.startswith("#"):
                continue 
            print ( line )
            idx1 = line.find(" ")
            if idx1 < 0:
                print ( "erreur format : " + line )
                exit(1)
            action = line[0:idx1] 
            #print ( " --> action " + action )
            idx2 = line.find(" ",idx1+1)
            if idx2 < 0:
                print ( "erreur format : " + line )
                exit(1)
            varName = line[idx1+1:idx2] 
            #print ( " --> varName  (" + varName+")" )
            var = config.find_first(byname=varName, type_='path', force_permissive=True)
            #print ( " --> var  " + str(var) )

            if action == 'default':
                #print ( " --> default" )
                homeconfig, name = config.cfgimpl_get_home_by_path(var)
                homeconfig.__delattr__(name)
            if action == 'set':
                #print ( " --> set " )
                option = config.unwrap_from_path(var)
                #print ( " --> option  " + str(option) )
                if option.impl_is_multi():
                    idx3 = line.find(" ",idx2+1)
                    if idx3 < 0:
                        print ( "erreur format : set <var> <idx> <value>" + line )
                        exit(1)
                    indice = line[idx2+1:idx3]    
                    #print ( " --> indice " + indice)
                    value  = str(line[idx3+1:])
                    value  = value.strip()
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    #print ( " --> value avant convert (" + value +")" )
                    value = convert_value(option, value)
                    #print ( " --> value apres convert (" + value +")" )
                    values = getattr(config, var)
                    #print ( " --> values avant (" + str(values)+")" )
                    #print ( " --> len(values) =" + str(len(values)) + " / " + str(idx) )
                    if indice == '+':
                        values.append(value)
                    else:
                        idx = int(indice) 
                        #print ( " --> idx  " + str(idx) )
                        if idx >= len(values):
                            #print ( " --> append" )
                            values.append(value)
                        else:
                            #print ( " --> set idx " + str(idx) )
                            values[idx] = value
                            #print ( " --> values apres (" + str(values)+")" )
                    setattr(config, var, values)
                    values = getattr(config, var)
                    #print ( " --> values apres (" + str(values)+")" )
                else:
                    value  = str(line[idx2+1:])
                    value  = value.strip() 
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    #print ( " --> value (" + value +")" )
                    value = convert_value(option, value)
                    setattr(config, var, value)
        config_save_values(config, 'creole')
    except Exception as err:
        traceback.print_exc()
        exit(1)

if __name__ == '__main__':
    main()
