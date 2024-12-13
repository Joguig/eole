#!/bin/bash
echo "* Vérification eole-seth-education"
if ! dpkg -l eole-seth-education
then
    echo "* Installation eole-seth-education"
    ciAptEole eole-seth-education
fi
ciConfigurationEole instance seth-education
exit 0

