Installation les outils nécessaire
==================================

* installer Python
* installer les librairies nécessaires
* installer Git
* recupérer les sources
* changer le numéro de version
* compilation

Python
------

L'installateur propose d'ajouter python dans le PATH (case à cocher), pip est intégré dans les dernières versions.


Python et PATH
--------------

Vérifier que C:\PythonXX\ est dans le PATH (variable d'environnement) :
recherche → panneaux de configuration → système → modifier les paramètres → paramètres système avancés → variables d'environnement → nouvelle

Installer les librairies
------------------------

Librairies python nécessaires pour le client EOLE Win32 :

* WxPython bibliothèque WxWidgets pour le développement d'interface graphique
pip install wxPython==4.0.1 sinon version de dev
la version de pip oblige à mettre à jour le code
solution temporaire installation par .exe version win32 3.0.2

* Python Win32 extension win32 pour Python
pip install pywin32

* Py2exe pour la compilation en .exe
pip install py2exe==0.6.9

* Twisted pour la programmation asynchrone
pip install twisted

* PIL Python Image Library pour la manipulation d'image
PIL a été forké le nom est maintenant pillow
pip install pillow

* WMI Python
pip install WMI

* zope-interface
pip install zope.interface

Installer Git et cloner les sources
-----------------------------------

Installation de Git
http://gitforwindows.org

Pour cloner les sources
git clone https://dev-eole.ac-dijon.fr/git/joineole.git

Pour changer le numéro de version
---------------------------------

dans le fichier setup-integrdom.py
version = '1.1',
dans le fichier Frame1.py (ligne 169)

Compiler
--------

Pour compiler double cliquer sur setup-integrdom.bat
Le .bat exécute :
python -O setup-integrdom.py py2exe

Les fichiers compilés par py2exe sont copiés dans "all/dlls"

Pour obtenir un seul exécutable la méthode a été changé.

Ancienne méthode :

    # "bundle_files": 1,
    # "compressed": True,

http://www.py2exe.org/index.cgi/SingleFileExecutable

Nouvelle méthode pour obtenir un seul exécutable NSIS
Télécharger l'exécutable

Pour réaliser le .exe :
clique droit sur le fichier setup.nsi → Compile NSIS script

