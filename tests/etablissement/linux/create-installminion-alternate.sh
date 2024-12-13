#!/bin/bash

LXC_ROOT="$1"
PROXY="$2"
DISTRIB_PC="$3"
echo "LXC_ROOT=$LXC_ROOT PROXY=$PROXY DISTRIB_PC=$DISTRIB_PC"
case "$DISTRIB_PC" in 
    ulyana|vanessa|vera|victoria|virginia|wilma)
        echo "ATTENTION :surcharge $LXC_ROOT/usr/share/eole/workstation/installMinion.sh car $DISTRIB_PC"
        cat installMinion-Futur.sh >"$LXC_ROOT/usr/share/eole/workstation/installMinion.sh"
        ;;

    bookworm)
        echo "ATTENTION :surcharge $LXC_ROOT/usr/share/eole/workstation/installMinion.sh car $DISTRIB_PC"
        cat installMinion-Futur.sh >"$LXC_ROOT/usr/share/eole/workstation/installMinion.sh"
        ;;

    *)
        echo "ATTENTION :surcharge installMinion.sh Désactivée"
        ;;
esac

