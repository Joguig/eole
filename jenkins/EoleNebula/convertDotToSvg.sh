#!/bin/bash
# ---------------------------------------------------------------------------------
# EoleCi
# Copyright © 2014-2023 Pôle de Compétence Logiciels Libres EOLE <eole@ac-dijon.fr>
# 
# LICENCE PUBLIQUE DE L'UNION EUROPÉENNE v. 1.2 :
# in french: https://joinup.ec.europa.eu/sites/default/files/inline-files/EUPL%20v1_2%20FR.txt
# in english https://joinup.ec.europa.eu/sites/default/files/custom-page/attachment/2020-03/EUPL-1.2%20EN.txt
# ---------------------------------------------------------------------------------

if ! command -v dot >/dev/null 
then
    echo "$0: install graphviz, tred, dot"
    apt install -y graphviz
fi

SOURCE=$1
DEST=$2
# reduction transitive, suppression de tous les noeuds de type 'dev-', puis conversion en svg 
tred <"${SOURCE}" 2>/dev/null | sed -e "/\"dev-/d" | dot -Tsvg -x -o"${DEST}" 