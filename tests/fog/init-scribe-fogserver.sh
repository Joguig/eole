#!/bin/bash
echo "Début $0"

echo "* activation tftp"
# Attention: le tftp est activé mais c'est celui de FOG qui répondra
CreoleSet activer_tftp oui
CreoleSet adresse_ip_tftp 10.1.2.10
CreoleSet chemin_fichier_pxe /undionly.kpxe

echo "* reconfigure"
ciMonitor reconfigure
ciCheckExitCode $? "reconfigure"

echo "* sauvegarde CA machine"
ciSauvegardeCaMachine

echo "Fin $0"
