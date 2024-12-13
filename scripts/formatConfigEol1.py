#!/bin/env python3
# coding: utf8

import sys
import json
import traceback

if sys.version_info < (3, 0):
    print("Sorry, requires Python 3.x")
    sys.exit(1)


def printvalue( var_value ):
    sys.stdout.write( '"')
    sys.stdout.write( str(var_value) )
    sys.stdout.write( '"')


def printjson( var_name, var_value ):
    try:
        sys.stdout.write( '"')
        sys.stdout.write( str(var_name) )
        sys.stdout.write( '"')
        var_type = type( var_value )
        if var_value is None:
            sys.stdout.write( ':')
            sys.stdout.write( 'null')
            return

        if var_type is str:
            sys.stdout.write( ':')
            printvalue( var_value )
            return

        if var_type is int:
            sys.stdout.write( ':')
            sys.stdout.write( str(var_value) )
            return

        if var_type is dict:
            sys.stdout.write( ':{')
            count = 0
            items = list(var_value.keys())
            for item in sorted( items ):
                if count:
                    sys.stdout.write(',')
                count += 1
                valeur = var_value[ item ]
                printjson( item, valeur )
            sys.stdout.write( '}')
            return

        if var_type is list:
            sys.stdout.write( ':[')
            count = 0
            for item in var_value:
                var_type_item = type( item )
                if count:
                    sys.stdout.write(',')
                count += 1
                if item is None:
                    sys.stdout.write( 'null')
                elif var_type_item is int:
                    sys.stdout.write( str(item) )
                else:
                    printvalue( item )
            sys.stdout.write( ']')
            return
    except Exception as e:
        sys.stderr.write( str(e) )
        raise e
    raise Exception('Type non géré : ' + str( var_type ) + " pour '" + unicode(var_name) + "'" )


try:
    contenu = json.load( sys.stdin )
    sys.stdout.write('{')
    count = 0
    keys = contenu.keys()
    for var in sorted( keys ):
        if count:
            sys.stdout.write(',')
        count += 1
        small_group = contenu[ var ]
        sys.stdout.write( '\n    ')
        printjson ( var, small_group )
    sys.stdout.write('\n}\n')
    sys.exit(0)
except Exception as e:
    sys.stderr.write( str(e) )
    traceback.print_exc(sys.stderr)
    sys.exit(1)
