#!/bin/bash

if ciVersionMajeurAPartirDe "2.9."
then
    ciSignalHack "injection du dictionnaire 99_routes.xml"
    cp ./99_routes.xml /usr/share/eole/creole/dicos
    ciRunPython /usr/bin/CreoleLint -t 01-extras-routes.yaml
fi
