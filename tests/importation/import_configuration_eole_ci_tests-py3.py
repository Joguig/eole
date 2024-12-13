#!/usr/bin/env python3

import sys
import xmlrpc.client
#from io import StringIO as cStringIO
import json
import os
import time
import base64
import traceback
from time import sleep
from packaging.version import parse as VERS

# ce code est validé par jenkins !
# pylint: disable=import-error
from zephir.utils.ldap_user import add_user, encrypt_passwd

class ZephirClient:
    stopAFirstError = os.getenv('STOP_ON_ERROR', '0')
    versionMajeur = os.getenv('VM_VERSIONMAJEUR', '?')
    indent = 0

    def __init__(self, url):
        self.url = url
        print ("stopAFirstError = " + self.stopAFirstError )
        print ("versionMajeur = " + self.versionMajeur )

    def connect(self):
        self.zephir = xmlrpc.client.ServerProxy(self.url) #, allow_none=True)

    def printIndent(self, texte):
        indent = self.indent
        lignes = texte.split('\n')
        if len(lignes) <= 1:
            print (("    " * indent) + texte )
        else:
            print (("    " * indent) + lignes[1] )
            indent += 1
            for ligne in lignes[1:]:
                print (("    " * indent) + texte )

    def liste_modules(self):
        self.printIndent( "*modules disponibles *")
        self.indent=1
        rc, modules = self.zephir.modules.get_module()
        for module in modules:
            self.printIndent( str(module['id']) + " - " + module['libelle'] )

    def liste_versions(self):
        self.printIndent( "*extraction version*")
        self.indent=1
        versions = []
        rc, modules = self.zephir.modules.get_module()
        for module in modules:
            module_et_version=module['libelle']
            index = module_et_version.rfind('-')
            if index < 1:
                self.signalInfo( module_et_version, "bizarre, format sans version ?")
            else:
                version=module_et_version[ index + 1:].strip()
                if version not in versions:
                    versions.append( version )
        return versions

    def add_etablissement(self, libelle, rne):
        rc, etabs = self.zephir.etabs.get_etab()
        for etab in etabs:
            if etab['libelle'] == libelle:
                return
        rc = self.zephir.etabs.add_etab(rne,libelle,"","","","","","","","",'45')
        self.printIndent( "Etablissement ajouté : " + rne + " " + libelle + " " + str(rc) )

    def add_user(self, login, passwd ):
        enc_passwd = encrypt_passwd(passwd)
        add_user(login,passwd)

    def add_user_arv(self):
        self.add_user("arv", "eole")
        self.zephir.save_permissions("arv", "1,7")

    def add_user_admin_zephir(self):
        self.add_user("admin_zephir", "eole")
        self.zephir.save_permissions("admin_zephir", "1,2,3,4,5,6,7,8,9,10,11,12,13,14,21,22,23,31,40")

    def getModuleId(self, module_et_version ):
        rc, mods = self.zephir.modules.get_module()
        for mod in mods:
            libelle = mod['libelle']
            id_mod = mod['id']
            if libelle == module_et_version:
                return id_mod
        raise Exception('module inconnu : ' + module_et_version)

    def getVarianteId(self, id_mod, nom_variante ):
        rc, variantes = self.zephir.modules.get_variante()
        for var in variantes:
            id_var = var['id']
            module_var = var['module']
            variante = var['libelle']
            #print variante + ' ' + str(module_var) + ' ' + str(id_var)
            if variante.startswith(nom_variante) and id_mod == module_var :
                return id_var
        raise Exception('variante inconnue :' + nom_variante)

    def getRne(self, etablissement):
        rc, etabs = self.zephir.etabs.get_etab()
        for etab in etabs:
            if etab['libelle'] == etablissement:
                return etab['rne']
        return None

    def getServeur(self, nom_serveur):
        criteres_selection = {'libelle':nom_serveur}
        rc, groupe_serv = self.zephir.serveurs.groupe_serveur(criteres_selection)
        #print 'getServeur '+ str(rc) + " " + str(groupe_serv)
        return groupe_serv

    def add_serveurs( self, etablissement, nom_serveur, nom_module, version_majeur ):
        rne = self.getRne( etablissement )
        if rne is None:
            raise Exception("L'etablissement " + etablissement +" n'existe pas")
        id_mod = self.getModuleId( nom_module + '-' + version_majeur)
        id_variante = self.getVarianteId( id_mod, 'standard' )
        code, res = self.zephir.serveurs.add_serveur(rne, nom_serveur, '', '', '', time.asctime(), '', '', '', id_mod, id_mod, '', id_variante)
        if code == 0:
            raise Exception(res)
        id_serveur = int(res)
        self.printIndent( "Serveur ajouté %s : %s" % (nom_serveur, id_serveur) )
        return id_serveur

    def signalErreur(self, texte, configuration):
        self.nbErreur = self.nbErreur + 1
        if configuration != 'basique':
            self.nbErreurNonBasique = self.nbErreurNonBasique + 1
            self.printIndent( "ErreurNonBasique : ==> " + texte )
        else:
            self.printIndent( "WARNING: ERR BASIQUE ==> " + texte )
        if self.stopAFirstError == "1" and self.nbErreur > 5:
            sys.exit(1)

    def signalWarning( self, configEol, msg):
        self.nbWarning = self.nbWarning + 1
        self.printIndent( "WARNING: " + configEol + ' ' + msg)
        if self.stopAFirstError == "1" and self.nbErreur > 5:
            sys.exit(1)

    def signalIgnore( self, configEol, msg):
        self.nbWarning = self.nbWarning + 1
        #self.printIndent( "IGNORE: " + configEol + ' ' + msg)

    def signalInfo( self, configEol, msg):
        self.nbWarning = self.nbWarning + 1
        self.printIndent( "INFO: " + configEol + ' ' + msg)

    def importModeleConfiguration(self, repConfiguration, configurationModele, modele, module, etablissement, version):
        index = configurationModele.rfind('-')
        if index < 1:
            self.signalInfo( configurationModele , "bizarre, format sans version ?")
            return
        # gestion nom configuration avec un '-'
        if version != configurationModele[ index + 1:].strip():
            return
        configuration = configurationModele[ : index ].strip()

        # cas général
        configEol = repConfiguration + "/etc/eole/config.eol"
        if version == '2.3':
            configEol = repConfiguration + "/etc/eole/config.ini"
            if VERS(self.versionMajeur) >= VERS('2.6.0'):
                self.signalIgnore( configurationModele, ' ignoré sur Zephir-' + self.versionMajeur )
                return
        else:
            if VERS(version) < VERS('2.5'):
                self.signalIgnore( configurationModele, ' ignorée sur Zephir-' + self.versionMajeur )
                return
            else:
                if VERS(version) < VERS('2.6'):
                    if VERS(self.versionMajeur) >= VERS('2.8.0'):
                        self.signalIgnore( configurationModele, ' ignorée sur Zephir-' + self.versionMajeur )
                        return

        if VERS(self.versionMajeur) < VERS(version):
            self.signalIgnore( configurationModele, 'version supérieure à celle du Zephir-' + self.versionMajeur )
            return

        if os.path.isfile(configEol) == False:
            self.signalInfo( configEol, ' manquant')
            return

        self.indent = 2
        self.printIndent( " ")
        self.printIndent( "Import Configuration: " + modele + " " + configurationModele + " Module: " + module )
        self.indent = 3

        if module == 'amonecoleeclair':
            if version == '2.3':
                module = 'amonecole+'
                self.printIndent( "HACK amonecole+")

        self.printIndent( "Configuration: " + configuration )
        self.printIndent( "Version: " + version )
        if configuration == 'basique':
            self.signalInfo( configEol, ' ignore')
            return
        try:
            # check serveur
            serveur_name = modele + '-' + configuration + '-' + version
            #print ('       ' + serveur_name )
            serveur = self.getServeur( serveur_name )
            if len( serveur ) == 0:
                try:
                    id_serveur = self.add_serveurs( etablissement, serveur_name, module, version)
                except Exception as e:
                    self.printIndent( "ERREUR: Add_serveurs ")
                    self.printIndent( "Exception: " + str(e))
                    self.signalErreur( configurationModele , configuration)
                    return
                serveur = self.getServeur( serveur_name )

            if len( serveur ) == 1:
                id_serveur = serveur[0]['id']
                id_module = serveur[0]['module_actuel']
            else:
                self.signalWarning( configEol, serveur_name + ' 2 serveurs ???')
                return

            with open( configEol ) as fh:
                contenu = fh.read()
            contenu = contenu.replace(chr(13)+chr(10),'\n')
            contenu = contenu.replace(chr(232),' ')

            rc, mod = self.zephir.modules.get_module(id_module)
            if len( mod ) != 1:
                self.signalWarning( configEol, str(id_module) + ' ne renvoi pas le bon nombre de module!!')
                return
            module_version = int(mod[0]['version'])
            if module_version >= 6:
                contentConfigEol = json.loads(contenu)
                if isinstance(contentConfigEol, bytes):
                    contentConfigEol = contentConfigEol.decode()
                dico = [str(contentConfigEol)]
            #elif module_version >= 2:
            #    # vérification du format et préparation de l'envoi
            #    sio = cStringIO.StringIO(contenu)
            #    c = ConfigParser(dict_type=dict)
            #    c.readfp(sio)
            #    sio.close()
            #    dico = [unicode(str(c._sections),"UTF-8")]
            else:
                dico = base64.encodebytes(contenu)
            # print(dico)
            rc, message = self.zephir.serveurs.save_conf(id_serveur, dico)
            if rc != 1:
                self.indent = 3
                self.printIndent( "rc=" + str(rc)  )
                print(type(message))
                print(message.encode('ascii', 'ignore'))
                #self.printIndent( "msg=" + message.encode('ascii', 'ignore') )
                self.signalErreur( configurationModele , configuration)
                self.indent = 2
                return

            with open( repConfiguration + "/zephir.id" ,"w") as fh:
                fh.write( str(id_serveur) )
            self.indent = 3
            self.printIndent( configurationModele + ' ==> OK ' )
        except Exception as e:
            self.indent = 3
            self.printIndent( "exception=" + str(e))
            self.signalErreur( configurationModele , configuration)
            traceback.print_exc()

    def createModeleConfiguration(self, repModele, modele, module, etablissement, version):
        for configurationModele in sorted(os.listdir(repModele)):
            if configurationModele == 'minimale':
                continue
            repConfiguration = repModele + "/" + configurationModele
            if os.path.isdir(repConfiguration) == False:
                continue
            self.importModeleConfiguration( repConfiguration, configurationModele, modele, module, etablissement, version)

    def createModele(self, repModele, modele, version):
        contextSh =  repModele + "/context.sh"
        if os.path.isfile(contextSh) == False:
            self.signalInfo( contextSh, "pas de fichier !" )
            return

        module = '?'
        etablissement= '?'
        no_etablissement='?'
        for ligne in open(contextSh).readlines():
            items = ligne.split('=')
            if items[0] == 'VM_MODULE':
                module = items[1].strip()
            if items[0] == 'VM_ETABLISSEMENT':
                etablissement = items[1].strip()
            if items[0] == 'VM_NO_ETAB':
                no_etablissement = items[1].strip()
        if module == '?':
            return
        module = module[1:-1]
        if module == 'base':
            module = 'eolebase'

        if module == 'zephir':
            # pas de zephir dans zephir !
            return

        if etablissement == '?':
            self.signalInfo( contextSh, ' VM_ETABLISSEMENT manquant')
            return
        etablissement = etablissement[1:-1]

        rne = self.getRne(etablissement)
        if rne is None:
            if etablissement == '?':
                self.signalWarning( contextSh , ' VM_NO_ETAB manquant, et etablissement inconnu')
                return
            no_etablissement = no_etablissement[1:-1]
            self.add_etablissement(etablissement,no_etablissement )

        self.createModeleConfiguration( repModele, modele, module, etablissement, version)

    def restartZephir(self):
        self.printIndent( "Redémarrage zéphir")
        os.system("systemctl restart zephir")
        self.printIndent( "Redémarrage zephir_web")
        os.system("systemctl restart zephir_web ")
        self.printIndent( "Attente 5s")
        sleep(5)

    def createServeurFromEoleCiTestsConfiguration(self, pathRepertoireConfiguration):
        self.nbErreur = 0
        self.nbErreurNonBasique = 0
        self.nbWarning = 0
        for version in self.liste_versions():
            self.indent = 0
            #self.restartZephir()
            self.connect()
            self.printIndent( "********************************************************************************************")
            self.printIndent( "Version " + version)
            for modele in sorted(os.listdir(pathRepertoireConfiguration)):
                self.indent = 1
                if modele in ['squashtm', 'jenkins', 'openvas', 'gateway' ]:
                    continue
                repModele = pathRepertoireConfiguration + "/" + modele
                if os.path.isdir(repModele) == False:
                    continue
                self.createModele( repModele, modele, version)
            self.printIndent( " ")


if __name__ == '__main__':
    print("debut import 1")
    zephirClient = ZephirClient('http://admin_zephir:eole@localhost:7081')
    zephirClient.connect()
    zephirClient.add_user_arv()
    zephirClient.add_user_admin_zephir()
    zephirClient.liste_modules()
    print(zephirClient.liste_versions())
    zephirClient.createServeurFromEoleCiTestsConfiguration("/mnt/eole-ci-tests/configuration")
    print("NbWarning = " + str( zephirClient.nbWarning ))
    print("NbErreur = " + str( zephirClient.nbErreur ))
    print("NbErreurNonBasique = " + str( zephirClient.nbErreurNonBasique ))
    seuil = 10
    if zephirClient.nbErreurNonBasique < seuil:
        print("moins de " + str(seuil) + " erreurs, ==> fin Exit = 0")
        sys.exit(0)
    else:
        print("Error: plus de " + str(seuil) + " erreurs, ==> fin Exit = 1")
        sys.exit(1)
