# -*- coding: UTF-8 -*-

###########################################################################
# Eole NG - 2007
# Copyright Pole de Competence Eole  (Ministere Education - Academie Dijon)
# Licence CeCill  cf /root/LicenceEole.txt
# eole@ac-dijon.fr
#
# eop_etat_initial.py
#
# Utilitaire servant dans le cadre de tests à remettre les arborescences
# des utilisateurs à l'état initial (aucun devoir distribué).
# 
#
# Réalise la suppression des arborescences suivantes (à partir de "devoirs")
#
# * dans workgroups :
#     /home/workgroups/devoirs/
#
# * pour chaque perso d'élève, par exemple pour c31e1 :
#     /home/c/c31e1/perso/devoirs/
#     /home/c/c31e1/devoirs/
#
# * pour chaque perso de prof, par exemple pour prof1 :
#     /home/p/prof1/perso/devoirs/
#
###########################################################################


import os, shutil

HOME_PATH = '/home'

# chemin vers le répertoire "devoirs" de l'utilisateur
USER_DEV_DIR = os.path.join(HOME_PATH, '%(user).1s', '%(user)s', 'devoirs')
USER_PERSO_DEV_DIR = os.path.join(HOME_PATH, '%(user).1s', '%(user)s', 'perso/devoirs')

# le dossier contenant les devoirs distribués
WORKGROUPS_DEV_DIR = os.path.join(HOME_PATH, 'workgroups/devoirs')

eleves = ['c31e1', 'c31e2', 'c31e3', 'c32e4', 'c32e5', 'c32e6', 'c33e7', 'c33e8', 'c33e9', 'c41e10', 'c41e11', 'c41e12', 'c42e13', 'c42e14', 'c42e15', 'c43e16', 'c43e17', 'c43e18']
profs = ['prof1', 'prof2', 'prof3', 'prof4', 'prof5', 'prof6', 'prof7', 'prof8', 'prof9']

def myrmtree(dir):
    if os.path.exists(dir): 
        shutil.rmtree(dir)

myrmtree(WORKGROUPS_DEV_DIR)

for eleve in eleves:
    myrmtree(USER_DEV_DIR%{'user': eleve})
    myrmtree(USER_PERSO_DEV_DIR%{'user': eleve})

for prof in profs:
    myrmtree(USER_PERSO_DEV_DIR%{'user': prof})
