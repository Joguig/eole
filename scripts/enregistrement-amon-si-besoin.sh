#!/bin/bash

if ciVersionMajeurApres "2.6.0"
then
	ciSetHttpProxy
    # $1 : version du module Scribe
    ciMonitor enregistrement_domaine "$1"
    ciCheckExitCode $? "enregistrement_domaine"
    ciPrintMsgMachine "Enregistrment au domaine OK"
else
    ciPrintMsgMachine "pas d'enregistrment au domaine pour cette version"
fi
