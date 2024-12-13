#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright © 2022 Pôle de compétences EOLE <eole@ac-dijon.fr>
#
# License CeCILL:
#  * in french: http://www.cecill.info/licences/Licence_CeCILL_V2-fr.html
#  * in english http://www.cecill.info/licences/Licence_CeCILL_V2-en.html
##########################################################################
import sys
# pylint: disable=E0401
from scribe.linker import _user_factory

def main():

    aide = sys.argv[0] + " <utilisateur1>[,utilisateur2,utilisateur3]\n"

    # récupération des arguments de la ligne de commande
    try:
        users = sys.argv[1]
    # pylint: disable=W0702
    except:
        sys.exit("\n"+aide)

    if users == "-h":
        sys.exit("\n"+aide)

    liste_users = users.split(",")

    for user in liste_users:
        try:
            ldap_user = _user_factory(user.strip())
        except Exception as msg:
            print(msg)
            continue
        print("modification de l'utilisateur {0}".format(user))
        # pylint: disable=W0212
        ldap_user._update_shell(user)

# si on a appelé le programme directement : on exécute main
if __name__ == "__main__":
    main()
