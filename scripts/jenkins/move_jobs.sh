#!/bin/bash

cd $HOME/jobs

for d in $(ls -d *)
do
    echo $d
    if [ -d "$d/jobs" ]
    then
        continue
    fi
    DEST=$(ls -d */jobs/$d)
    if [ -z "$DEST" ]
    then
	continue
    fi
    if [ -d "$DEST/builds" ]
    then
        echo "$DEST OK" 
        rm -rf "$d"/
        continue
    fi
    echo "$d ==> $DEST" 
    if [[ -f "$DEST/cdu.txt" ]] && [[ ! -f "$DEST/config.xml" ]]
    then
        echo "$DEST cdu sans config.xml" 
        rm -rf "$DEST"/
        continue 
    fi
    echo "$d ==> $DEST" 
    #mv "$d" "$DEST"
    ls -d -l "$DEST"
done
