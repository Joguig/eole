#!/usr/bin/env python
# coding: utf-8
# pep8: --ignore=E201,E202,E211,E501
# pylint: disable=C0323,C0301,C0103,C0111,E0213,C0302,C0203,W0703,R0201,C0325

import sys
import os
from os.path import expanduser
from locale import currency
from array import array
import yaml

try:
    import apt_pkg
    apt_pkg.init_system()  # pylint: disable=no-member
except ImportError:
    sys.exit(2)


class ExportDependsFromPackages (object):
    current_pq = "$"

    def getListeDepots(self):
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
            results = results + [ "eole-" + self.VM_VERSIONMAJEUR + "_main", "eole-" + self.VM_VERSIONMAJEUR + "-security_main", "eole-" + self.VM_VERSIONMAJEUR + "-updates_main" ]

        if self.MAJ_AUTO == "RC":
            results = results + [ "eole-" + self.VM_VERSIONMAJEUR + "_main", "eole-" + self.VM_VERSIONMAJEUR + "-security_main", "eole-" + self.VM_VERSIONMAJEUR + "-updates_main", "eole-" + self.VM_VERSIONMAJEUR + "-proposed-updates_main" ]

        if self.MAJ_AUTO == "DEV":
            results = results + [ "eole-" + self.VERSION_EOLE + "-unstable_main" ]

        return ( results )

    def updateMapPkgVersion( self, line , results):
        if line.startswith( "Package:"):
            elements = line.strip().split(" ")
            pq = elements[-1]
            if not pq.startswith("eole-"):
                return
            self.current_pq = pq
            if self.current_pq not in results.keys():
                dict_pkg = dict() 
                results[ self.current_pq ]= dict_pkg
            return
        
        if len(line) == 0:
            self.current_pq = "$"
            return
        
        if self.current_pq == "$":
            return 
        
        if line.startswith( "Depends:"):
            depends = line.strip().split(":")
            depends = depends[1]
            depends = depends.strip().split(",")
            r = []
            for d in depends:
                d = d.strip()
                items = d.split("(")
                r.append( items[0].strip() )
            
            dict_pkg = results[ self.current_pq ]
            dict_pkg[ "depends" ] = r
            return
        
        if line.startswith( "Conflicts:"):
            conflitcs = line.strip().split(":")
            conflitcs = conflitcs[1]
            conflitcs = conflitcs.strip().split(",")
            r = []
            for d in conflitcs:
                d = d.strip()
                items = d.split("(")
                r.append( items[0].strip() )
            
            dict_pkg = results[ self.current_pq ]
            dict_pkg[ "conflitcs" ] = r
            return
        
        if line.startswith( "Provides:"):
            provides = line.strip().split(" ")
            provides = provides[1] 
            provides = provides.strip().split(",")
            r = []
            for d in provides:
                d = d.strip()
                items = d.split("(")
                r.append( items[0].strip() )
            
            dict_pkg = results[ self.current_pq ]
            dict_pkg[ "provides" ] = r
            return

    def createMapPkgVersion( self, depots ):
        results = dict()
        for depot in depots:
            fname = self.HOME + "/depots/" + depot + ".pkgs"
            print ("utilise " + fname )
            if os.path.isfile(fname):
                self.current_pq = "$"
                with open(fname) as f:
                    for line in f:
                        self.updateMapPkgVersion( line, results)
            else:
                # print ("utilise " + fname + " (vide)")
                pass
        return results

    def createYaml( self , fname, pkgs):
        print ("save " + fname )
        with open( fname, 'w') as outfile:
            yaml.dump(pkgs, outfile, default_flow_style=False)

    def createYamls( self ,  pkgs):
        os.mkdir("/mnt/eole-ci-tests-one/output/ggrandgerard/zephir2/" + self.VM_VERSIONMAJEUR + "/serviceapplicatif/")
        for nom_paquet in sorted( pkgs.keys() ):
            self.createYaml( "/mnt/eole-ci-tests-one/output/ggrandgerard/zephir2/" + self.VM_VERSIONMAJEUR + "/serviceapplicatif/" + nom_paquet + ".yml", pkgs[ nom_paquet ] )

    def printDict( self , pkgs):
        print ("===============================")
        for nom_paquet in sorted( pkgs.keys() ):
            print ( nom_paquet + " " + str( pkgs[ nom_paquet ] ))

    def checkUpdate( self, vm, majauto, distrib ):
        self.VM_VERSIONMAJEUR = vm
        self.MAJ_AUTO = majauto
        self.DIST_UBUNTU = distrib
        self.VERSION_EOLE = self.VM_VERSIONMAJEUR[0:3]
        self.HOME = "/mnt/jenkins-one"
        self.FICHIER_VERSION = self.HOME + "/depots/" + self.VM_VERSIONMAJEUR


        depots = self.getListeDepots()
        PKGS_VERSION = self.createMapPkgVersion( depots )
        self.printDict( PKGS_VERSION )
        self.createYamls( PKGS_VERSION )
        return 0

if __name__ == '__main__':
    exporter = ExportDependsFromPackages()
    exporter.checkUpdate( "2.6.2", "STABLE", "xenial")
    exporter.checkUpdate( "2.6.1", "STABLE", "xenial")
    exporter.checkUpdate( "2.6.0", "STABLE", "xenial")
    exporter.checkUpdate( "2.5.2", "STABLE", "trusty")
    exporter.checkUpdate( "2.5.1", "STABLE", "trusty")
    exporter.checkUpdate( "2.5.0", "STABLE", "trusty")
    
