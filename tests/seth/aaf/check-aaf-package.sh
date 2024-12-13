#!/bin/bash
echo "* Vérification eole-seth-aaf"
if ! dpkg -l eole-seth-aaf
then
    echo "* Installation eole-seth-aaf"
    ciAptEole eole-seth-aaf
fi
ciConfigurationEole instance setheducation
exit 0
