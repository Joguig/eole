#!/usr/bin/python3
# coding: utf-8
# pep8: --ignore=E201,E202,E211,E501
# pylint: disable=C0323,C0301,C0103,C0111,E0213,C0302,C0203,W0703,R0201,C0325

import sys
import os

import apt_pkg
apt_pkg.init_system()  # pylint: disable=no-member

class TriggerDepots (object):
    VM_VERSIONMAJEUR = sys.argv[1]
    VERSION_EOLE = ""
    MAJ_AUTO = sys.argv[2]
    DIST_UBUNTU = sys.argv[3]
    SOURCE = sys.argv[4]
    LASTDIFF_FILE = sys.argv[5]

    def __init__(self):
        self.VERSION_EOLE = self.VM_VERSIONMAJEUR[0:3]
        self.FICHIER_VERSION = "/mnt/eole-ci-tests/depots/" + self.LASTDIFF_FILE
        self.ENVOLE="7"
        if self.VM_VERSIONMAJEUR < "2.5.2":
            self.ENVOLE="4"
        if self.VM_VERSIONMAJEUR < "2.6.1":
            self.ENVOLE="5"
        if self.VM_VERSIONMAJEUR < "2.7.1":
            self.ENVOLE="6"
        print ( "VM_VERSIONMAJEUR=" + self.VM_VERSIONMAJEUR )
        print ( "VERSION_EOLE=" + self.VERSION_EOLE )
        print ( "ENVOLE=" + self.ENVOLE )
        print ( "MAJ_AUTO=" + self.MAJ_AUTO )
        print ( "DIST_UBUNTU=" + self.DIST_UBUNTU )
        print ( "SOURCE=" + self.SOURCE )
        print ( "LASTDIFF_FILE=" + self.LASTDIFF_FILE )

    def getListeDepots(self):
        if self.DIST_UBUNTU=="freebsd":
            results = []
        else:
            results = [ self.DIST_UBUNTU + "_main" ,
                        self.DIST_UBUNTU + "_multiverse" ,
                        self.DIST_UBUNTU + "_restricted" ,
                        self.DIST_UBUNTU + "_univers",
                        self.DIST_UBUNTU + "-security_main",
                        self.DIST_UBUNTU + "-security_multiverse",
                        self.DIST_UBUNTU + "-security_restricted",
                        self.DIST_UBUNTU + "-security_univers",
                        self.DIST_UBUNTU + "-updates_main",
                        self.DIST_UBUNTU + "-updates_multiverse",
                        self.DIST_UBUNTU + "-updates_restricted",
                        self.DIST_UBUNTU + "-updates_univers" ]

            if self.MAJ_AUTO == "STABLE":
                results = results + [ "eole-" + self.VM_VERSIONMAJEUR + "_main", "eole-" + self.VM_VERSIONMAJEUR + "-security_main", "eole-" + self.VM_VERSIONMAJEUR + "-updates_main" ,  "envole-" + self.ENVOLE + "_main" ]

            if self.MAJ_AUTO == "RC":
                results = results + [ "eole-" + self.VM_VERSIONMAJEUR + "_main", "eole-" + self.VM_VERSIONMAJEUR + "-security_main", "eole-" + self.VM_VERSIONMAJEUR + "-updates_main", "eole-" + self.VM_VERSIONMAJEUR + "-proposed-updates_main" ,  "envole-" + self.ENVOLE + "-unstable_main" ,  "envole-" + self.ENVOLE + "-testing_main" ]

            if self.MAJ_AUTO == "DEV":
                results = results + [ "eole-" + self.VERSION_EOLE + "-unstable_main",  "envole-" + self.ENVOLE + "-unstable_main" ,  "envole-" + self.ENVOLE + "-testing_main" ]
        
        return ( results )

    def updateMapPkgVersion( self, line , results):
        if len(line) == 0:
            return False
        if not line.startswith( "Filename:"):
            return False
        elements = line.strip().split("/")
        deb = elements[-1]
        pq = deb.split('_')
        nom_pq = pq[0]
        version_pq = pq[1]
        if nom_pq in results:
            version_map = results[ nom_pq ]
            vc = apt_pkg.version_compare( version_pq, version_map )  # pylint: disable=no-member
            if vc <= 0:
                return False
            # print ( nom_pq + " " + version_pq + " > " + version_map )
        else:
            # print ( nom_pq + " " + version_pq + " new " )
            pass
        results[ nom_pq] = version_pq
        return True

    def createMapPkgVersion( self, depots ):
        results = dict()
        for depot in depots:
            fname = "/mnt/eole-ci-tests/depots/" + depot + ".filename"
            print ("utilise " + fname )
            if os.path.isfile(fname):
                with open(fname) as f:
                    for line in f:
                        self.updateMapPkgVersion( line, results)
            else:
                # print ("utilise " + fname + " (vide)")
                pass
        return results
    
    def createMapPkgEole( self, depots ):
        results = dict()
        for depot in depots:
            fname = "/mnt/eole-ci-tests/depots/" + depot + ".pkgs"
            #print ("utilise " + fname )
            if os.path.isfile(fname):
                with open(fname) as f:
                    isEole = False
                    for line in f:
                        if line.startswith( "Homepage"):
                            isEole = line.startswith( "Homepage: http://eole.orion.education.fr/diff/")
                            continue
                        if len(line) == 0:
                            isEole = False
                            continue 
                        if line.startswith( "Filename:"):
                            if isEole:
                                self.updateMapPkgVersion( line, results)
                            isEole = False
                            continue
            else:
                # print ("utilise " + fname + " (vide)")
                pass
        return results

    def loadArrayPaquetsAIgnorer( self , fname):
        array = []
        if os.path.isfile(fname):
            with open( fname, "r") as ins:
                for line in ins:
                    array.append(line)
        return array

    def loadLastList( self , fname):
        # print ("utilise " + fname )
        results = dict()
        if os.path.isfile(fname):
            with open(fname) as f:
                for line in f:
                    elements = line.strip().split()
                    # print (elements)
                    if len( elements ) > 1:
                        results[ elements[0] ] = elements[ 1 ]
        else:
            # print ("utilise " + fname + " (vide)")
            pass
        return results

    def saveLastList( self , fname, pkgs):
        print ("save " + fname )
        with open( fname, 'w') as f:
            for nom_paquet in sorted( pkgs.keys() ):
                if len(nom_paquet) > 0:
                    f.write( nom_paquet )
                    f.write( ' ' )
                    f.write( str( pkgs[ nom_paquet ] ) )
                    f.write( '\n' )
                    # print ( nom_paquet + " " + str( pkgs[ nom_paquet ] ))

    def saveListPaquets( self , fname, pkgs):
        print ("save " + fname )
        with open( fname, 'w') as f:
            for nom_paquet in sorted( pkgs.keys() ):
                if len(nom_paquet) > 0:
                    f.write( nom_paquet )
                    f.write( '\n' )

    def printDict( self , pkgs):
        print ("===============================")
        for nom_paquet in sorted( pkgs.keys() ):
            versions_paquet = pkgs[ nom_paquet ]
            print ( nom_paquet + " " + str( versions_paquet ))

    def createCause( self, pkgs, pkgs_eole):
        print ("<cause>")
        for nom_paquet in sorted( pkgs.keys() ):
            versions_paquet = pkgs[ nom_paquet ]
            if 'ver' in versions_paquet.keys() :
                ver = versions_paquet['ver']
                if nom_paquet in pkgs_eole.keys():
                    print ( nom_paquet + " " + str( versions_paquet ) + " http://castor.eole.lan:9998/package/"+nom_paquet+"/"+ ver)
                else:
                    print ( nom_paquet + " " + str( versions_paquet ) )
            else:
                print ( nom_paquet + " " + str( versions_paquet ))
        print ("</cause>")

    def compare( self , pkgs_a, pkgs_b ):
        resultat_comparaison = dict()
        keys_b = pkgs_b.keys()
        keys_a = pkgs_a.keys()
        for nom_paquet in keys_a:
            version_a = pkgs_a[ nom_paquet ]
            if nom_paquet in keys_b:
                version_b = pkgs_b[ nom_paquet ]
                vc = apt_pkg.version_compare( version_a, version_b )   # pylint: disable=no-member
                if vc == 0:
                    continue
                if vc < 0:
                    continue
                resultat_comparaison[ nom_paquet ] = { 'ver': version_a, 'old': version_b }
            else:
                resultat_comparaison[ nom_paquet ] = { 'ver': version_a }

        for nom_paquet in keys_b:
            version_b = pkgs_b[ nom_paquet ]
            if nom_paquet not in keys_a:
                resultat_comparaison[ nom_paquet ] = { 'old': version_b }

        return resultat_comparaison

    def raiseTrigger( self , pkgs_a, changements ):
        resultat_comparaison = dict()
        paquets_changes = changements.keys()
        keys_a = pkgs_a.keys()
        for nom_paquet in paquets_changes:
            if nom_paquet in keys_a:
                print("paquet changé : " + nom_paquet + " OK ")
                resultat_comparaison[ nom_paquet ] = changements[ nom_paquet ]
            else:
                print("paquet changé : " + nom_paquet + " ignore")
        return resultat_comparaison

    def filtrePaquetsIgnores( self , array_pkgs, changements ):
        resultat_comparaison = dict()
        for nom_paquet in changements.keys():
            if nom_paquet in array_pkgs:
                print("paquet ignoré : " + nom_paquet )
            else:
                resultat_comparaison[ nom_paquet ] = changements[ nom_paquet ]
        return resultat_comparaison

    def calculPaquetsActuels( self ):
        # find /mnt/eole-ci-tests/module/ -name "*-self.VERSION_EOLE}" -exec sort {} +  | uniq >"/tmp/paquets-self.VERSION_EOLE}"
        topdir = '/mnt/eole-ci-tests/module/'
        exten = '-' + self.LASTDIFF_FILE + '-amd64.last_detail'
        results = dict()
        for dirpath, dirnames, files in os.walk(topdir):  # pylint: disable=unused-variable
            for name in files:
                if name.lower().endswith(exten):
                    fname = os.path.join(dirpath, name)
                    with open(fname) as f:
                        for line in f:
                            if line.startswith("Souhait=") or line.startswith("| État=Non/Installé") or line.startswith("|/ Err?=(aucune") or line.startswith("||/ Nom"):
                                continue
                            elements = line.strip().split()
                            if len( elements ) > 2:
                                # print (elements[1] + " " + elements[2])
                                results[elements[1] ] = elements[2]
        return results

    def checkUpdate( self ):
        if self.VM_VERSIONMAJEUR == "{{VERSION_MAJEUR}}":
            return 1

        if os.path.isfile("/mnt/eole-ci-tests/ModulesEole.yaml") is False:
            print ("/mnt/eole-ci-tests non monté, stop")
            return 1
        if self.DIST_UBUNTU == '':
            print ("DIST_UBUNTU inconnu, stop " + self.DIST_UBUNTU)
            return 1 
        depots = self.getListeDepots()

        PKGS_VERSION = self.createMapPkgVersion( depots )
        print ("Nb paquets Depots : " + str( len( PKGS_VERSION ) ))
        # self.printDict( PKGS_VERSION )

        PKGS_EOLE = self.createMapPkgEole( depots )
        print ("Nb paquets EOLE: " + str( len( PKGS_EOLE ) ))
        #self.printDict( PKGS_EOLE )

        fichierLast = "/mnt/eole-ci-tests/depots/" + self.LASTDIFF_FILE + ".last"
        PKGS_LAST = trigger.loadLastList( fichierLast )
        print ("Nb paquets derniere modification : " + str( len( PKGS_LAST ) ))
        # self.printDict( PKGS_LAST )

        fichierAIgnorer = "/mnt/eole-ci-tests/version/" + self.LASTDIFF_FILE + ".a_ignorer"
        paquetsAIgnorer = self.loadArrayPaquetsAIgnorer( fichierAIgnorer )
        print ("Nb paquets à ignorer : " + str( len( paquetsAIgnorer ) ) + " paquet(s)")

        fichiersApresInstance = "/mnt/eole-ci-tests/version/" + self.LASTDIFF_FILE + ".apres_instance"
        pkgs_apres_instances = self.calculPaquetsActuels()
        print ("Nb paquets apres instance EOLE : " + str( len( pkgs_apres_instances ) ))
        # self.printDict( pkgs_apres_instances )
        self.saveListPaquets( fichiersApresInstance, pkgs_apres_instances )

        resultats = self.compare( PKGS_VERSION, PKGS_LAST)
        if len( resultats ) <= 0:
            print ("pas de changments " + self.VM_VERSIONMAJEUR )
            return 1

        print ("filtre des paquets à ignorer !")
        resultats = self.filtrePaquetsIgnores( paquetsAIgnorer, resultats )
        print ("paquets " + self.VM_VERSIONMAJEUR + " différents !")
        print ("des changements sur " + str( len( resultats ) ) + " paquet(s)")
        #self.printDict( resultats )
        self.saveLastList( fichierLast, PKGS_VERSION )

        fichiersApresInstance = "/mnt/eole-ci-tests/version/" + self.LASTDIFF_FILE + ".apres_instance"
        pkgs_apres_instances = self.calculPaquetsActuels()
        print ("Nb paquets apres instance EOLE : " + str( len( pkgs_apres_instances ) ))
        # self.printDict( pkgs_apres_instances )
        self.saveListPaquets( fichiersApresInstance, pkgs_apres_instances )

        if len( pkgs_apres_instances ) > 0:
            print ("Test si déclenchement du trigger " + self.VM_VERSIONMAJEUR + " ?")
            resultats = self.raiseTrigger( pkgs_apres_instances, resultats )
            if len( resultats ) <= 0:
                print ("pas de changments EOLE " + self.VM_VERSIONMAJEUR)
                return 1
        else:
            print ("Instances non executés ==> tous les paquets ")

        self.createCause( resultats, PKGS_EOLE )
        print ("des changements sur " + str( len( resultats ) ) + " paquet(s) EOLE")
        fname = "/mnt/eole-ci-tests/depots/" + self.LASTDIFF_FILE + ".lastDiff"
        self.saveLastList( fname, resultats )
        return 0


if __name__ == '__main__':
    trigger = TriggerDepots()
    sys.exit( trigger.checkUpdate() )
