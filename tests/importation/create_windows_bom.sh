#!/bin/bash
if [ -z "$1" ]
then
   echo "Usage $0 : <fichier.csv>"
   exit 1
fi
if [ -z "$2" ]
then
   echo "Usage $0 : <fichier source.csv> <fichier dest.csv>"
   exit 1
fi
# signature "Unicode Little Endian : FF FE " 
printf "\xFF\xFE" > "$2"
# Windows utilise CRLF et UTF16LE"
sed 's/$/\r/' "$1" | iconv -f UTF-8 -t UTF-16LE >> "$2"
echo "$2 crée"

