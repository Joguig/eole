#!/bin/bash
if [ -z "$1" ]
then
   echo "Usage $0 : <fichier source.csv> <fichier dest.csv>"
   exit 1
fi
if [ -z "$2" ]
then
   echo "Usage $0 : <fichier source.csv> <fichier dest.csv>"
   exit 1
fi
# signature "UTF8 : bom " 
printf "\xFE\xBB\xBF" > "$2"
# Mac => Cr en fin de ligne + utf-16 
sed 's/\n/\r/' "$1" | iconv -f UTF-8 -t UTF-16 >> "$2"
echo "$2 crée"
