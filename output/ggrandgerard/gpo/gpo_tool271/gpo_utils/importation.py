#!/usr/bin/env python
# -*- coding:utf-8 -*-

# general
import traceback
import filecmp
import sys
import os
import ntpath
from glob import glob
from os.path import basename, exists, join

# samba
import ldb
import samba.getopt as options
from gpo_utils.gpo import (
    get_gpo_containers,
    del_gpo_link,
    get_gpo_dn,
    CommandError,
    Option,
    SuperCommand,
    gplink_options_string,
    cmd_create,
    cmd_restore,
    cmd_del
)

# specifique Eole
from gpo_utils.policy import (
    GPOVersion,
    cmd_add,
    cmd_register,
)

from gpo_utils.gpo_eole import (
    EoleGPOCommand
)


class cmd_import(EoleGPOCommand):
    """Import a GPO by displayName.
    
    Cette commande remplace l'ancien code 'importation.py'. Les appels 'importation.py ...' doivent être modifié en 'gpo-tool import ...' 
    
    Elle permet d'ajouter une policy à une GPO existante.
    
    Rappel:
    - Chaque appel a cette commande crée une transaction dans l'AD. Il est impératif de garder la cohérence AD/Sysvol dans une transaction
    - Elle doit être utilisée sur le DC portant le Sysvol de référence
    - Elle ne doit pas être utilisé sur un DC additionnel
    
    copy @policy_unix_path@ file into @gpo_name@ policy directory        
    * update sam.ldb with gpc informations
    ** gpo_name : the name of the GPO
    ** context : "User" or "Machine"
    ** policy_type : "Scripts" or 'Registry" (perhaps more in the future)
    ** policy_unix_path : file to copy
    ** policy_smb_path : policy path relative path
    """

    synopsis = "%prog <displayname> [options]"

    takes_optiongroups = {
        "sambaopts": options.SambaOptions,
        "versionopts": options.VersionOptions,
        "credopts": options.CredentialsOptions,
    }

    takes_args = ['gpo_name', 'context', 'policy_type', 'policy_unix_path', 'policy_smb_path' ]

    takes_options = [
        Option("-H", help="LDB URL for database or target server", type=str),
        Option("--force", help="Force", default=False, action='store_true'),
    ]

    context = None
    policy_type = None
    policy_unix_path = None
    policy_smb_path = None
    force = False

    def runInTransaction(self):
        """runInTransaction
         
        """
        # cf. https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/guid-list-of-group-policy-client-extensions/
        # GUID_ProcessScriptsGroupPolicy    = "{42B5FAAE-6536-11D2-AE5A-0000F87571E3}"
        # GUID_Scripts_Startup_Shutdown     = "{40B6664F-4972-11D1-A7CA-0000F87571E3}"
        # GUID_Preference_Tool_CSE_Registry = "{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}"
        # GUID_Core_GPO_Engine              = "{00000000-0000-0000-0000-000000000000}"
        # GUID_Preference_CSE_Registry      = "{B087BE9D-ED37-454F-AF9C-04291E351182}"
    
        # self.debug3 ( "context = " +self.context )
        # self.debug3 ( "policy_type = " + self.policy_type)
        # self.debug3 ( "policy_unix_path = " + self.policy_unix_path)
        # self.debug3 ( "policy_smb_path = " + self.policy_smb_path)

        gpc_extension = None
        if self.context == 'Machine':
            if self.policy_type == 'Scripts':
                gpc_extension = ["{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}"]
                self.gPCMachineExtensionNames_new_state = self.gpc_update_extension_value(self.gPCMachineExtensionNames_new_state, gpc_extension)
            elif self.policy_type == 'Registry':
                gpc_extension = ["{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}", "{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}"]
                self.gPCMachineExtensionNames_new_state = self.gpc_update_extension_value(self.gPCMachineExtensionNames_new_state, gpc_extension)
            else:
                print ("Context '{0}/{1}' is not managed.".format(self.context, self.policy_type))
                raise
        elif self.context == 'User':
            if self.policy_type == 'Scripts':
                gpc_extension = ["{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-11D1-A7CA-0000F87571E3}"]
                self.gPCUserExtensionNames_new_state = self.gpc_update_extension_value(self.gPCUserExtensionNames_new_state, gpc_extension)
            elif self.policy_type == 'Registry':
                gpc_extension = ["{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}", "{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}"]
                self.gPCUserExtensionNames_new_state = self.gpc_update_extension_value(self.gPCUserExtensionNames_new_state, gpc_extension)
            else:
                print ("Context '{0}/{1}' is not managed.".format(self.context, self.policy_type))
                raise
        else:
            print ("Context '{0}' is not managed.".format(self.context))
            raise
                
        if exists(self.policy_smb_path) and filecmp.cmp(self.policy_unix_path, self.policy_smb_path) and not self.force:
            return 0
            
        # load content if file exists
        self.debug2 ("sharepath " + self.sharepath)
        smb_path = ntpath.join(self.sharepath, self.policy_smb_path)
        self.debug2 ("smb_path " + smb_path)
        # write file
        with open(self.policy_unix_path, 'rb') as contentfh:
            content = contentfh.read()
        try:
            self.savecontent(smb_path, content, conn=self.conn)
        except TypeError:
            traceback.print_exc()
            local_path = join('/home/sysvol/{}/Policies/{}'.format(self.realm, self.gpo_id), self.policy_smb_path)
            self.savecontent(local_path, content)

        # update GPO version
        gpoversion = GPOVersion()
        gpoversion.extract(self.gpo_version)
        gpoversion.add(self.context)

        # modify version in GPT
        self.update_gpt_version(self.sharepath, gpoversion.value(), conn=self.conn)

        # modify version for groupPolicyContainer
        self.update_gpc_version(self.gpo_dn, gpoversion.value(), self.samdb)

        # fix ownership
        self.set_ownership_and_mode(smb_path, gpo=str(self.gpo_id), conn=self.conn, samdb=self.samdb)                
    
    def run(self, gpo_name, context, policy_type, policy_unix_path, policy_smb_path, force=False, H=None, sambaopts=None, credopts=None, versionopts=None):
        """
        * copy @policy_unix_path@ file into @gpo_name@ policy directory
        * update sam.ldb with gpc informations
        ** gpo_name : the name of the GPO
        ** context : "User" or "Machine"
        ** policy_type : "Scripts" or 'Registry" (perhaps more in the future)
        ** policy_unix_path : file to copy
        ** policy_smb_path : policy path relative path
        """
        self.context = context
        self.policy_type = policy_type
        self.policy_unix_path = policy_unix_path
        self.policy_smb_path = policy_smb_path
        self.force = force
        return self.connectAndRunInTransaction(gpo_name, H, sambaopts, credopts, versionopts)


#
# portage 'importation.py' dans samba/gpo
#
#
class cmd_importation_from_source(cmd_import):
    """Import a GPO froms sources path."""

    synopsis = "%prog <gpo_name> --source_path <path> [options]"

    takes_optiongroups = {
        "sambaopts": options.SambaOptions,
        "versionopts": options.VersionOptions,
        "credopts": options.CredentialsOptions,
    }

    takes_args = ['gpo_name', 'sources_path']

    takes_options = [
        Option("-H", help="LDB URL for database or target server", type=str),
        Option('--source_path', action='store', dest='sources_path',
                    type=str, nargs='*', default=[],
                    help="Source: --source_path /usr/share/eole/gpo/reg --source_path /usr/share/eole/gpo.script"),
        Option("--force", help="Force", default=False, action='store_true'),
    ]

    def updatePolicy(self, context, policy_type, policy_unix_path, policy_smb_path):
        self.debug ("updatePolicy: " + context + " " + policy_type + " " + policy_unix_path + " " + policy_smb_path)
        self.context = context
        self.policy_type = policy_type
        self.policy_unix_path = policy_unix_path
        self.policy_smb_path = policy_smb_path
        super(cmd_importation_from_source, self).runInTransaction()

    def updateFromSourcePath(self, source_path):
        from reg_to_xml import regToRegistryXml
        regToRegistryXml(source_path + '/Machine', source_path + '/Machine')
        regToRegistryXml(source_path + '/User', source_path + '/User')

        # Import Logon PowerShell scripts
        for script_file in glob(source_path + '/User/*.ini'):
            self.updatePolicy('User', 'Scripts', script_file, join('User/Scripts', basename(script_file)))
        for script_file in glob(source_path + '/User/*.ps1'):
            self.updatePolicy('User', 'Scripts', script_file, join('User/Scripts/Logon', basename(script_file)))
        
        # Import Machine StartUp PowerShell scripts
        for script_file in glob(source_path + '/Machine/*.ini'):
            self.updatePolicy('Machine', 'Scripts', script_file, join('Machine/Scripts', basename(script_file)))
        for script_file in glob(source_path + '/Machine/*.ps1'):
            self.updatePolicy('Machine', 'Scripts', script_file, join('Machine/Scripts/StartUp', basename(script_file)))
        
        # Import Machine Registry XML
        regxml_file = source_path + '/Machine/Registry.xml'
        if exists(regxml_file):
            self.updatePolicy('Machine', 'Registry', regxml_file, 'Machine/Preferences/Registry/Registry.xml')
        # TODO
        # else: 
        # remove file from policy !
    
        # Import User Registry XML
        regxml_file = source_path + '/User/Registry.xml'
        if exists(regxml_file):
            self.updatePolicy('User', 'Registry', regxml_file, 'User/Preferences/Registry/Registry.xml')
        # TODO
        # else: 
        # remove file from policy !

    def runInTransaction(self):
        for source_path in self.sources_path:
            self.updateFromSourcePath(source_path)
        self.gpc_update_extension_once_in_transaction('gPCMachineExtensionNames', self.gPCMachineExtensionNames, self.gPCMachineExtensionNames_new_state)
        self.gpc_update_extension_once_in_transaction('gPCUserExtensionNames', self.gPCUserExtensionNames, self.gPCUserExtensionNames_new_state)
            
    def run(self, gpo_name, sources_path=None, force=False, H=None, sambaopts=None, credopts=None, versionopts=None):
        self.sources_path = sources_path
        self.force = force
        return self.connectAndRunInTransaction(gpo_name, H, sambaopts, credopts, versionopts)


class cmd_importation_eole_script(EoleGPOCommand):
    """Import a GPO_script by displayName."""

    synopsis = "%prog [options]"

    takes_optiongroups = {
        "sambaopts": options.SambaOptions,
        "versionopts": options.VersionOptions,
        "credopts": options.CredentialsOptions,
    }

    takes_args = []

    takes_options = [
        Option("-H", help="LDB URL for database or target server", type=str),
        Option("--container", help="do link Gpo with Container dn", type=str),
    ]

    def run(self, H=None, container=None, sambaopts=None, credopts=None, versionopts=None):
        
        self.gpo_name = "eole_script"
        self.GPOSCRIPT_DATA_DIR = "/var/tmp/gpo-script"
        self.hashFileGpo = self.GPOSCRIPT_DATA_DIR + "/" + self.gpo_name + "_hash"
        self.flagFileGpo = self.GPOSCRIPT_DATA_DIR + "/update_" + self.gpo_name
        
        self.gpo_id = None
        doDelete = False
        doCreate = False
        doAddPolicies = False
        doComputeHash = False
        doCheck = False
        
        # protection 
        if os.path.isfile(self.hashFileGpo):
            if os.path.getsize(self.hashFileGpo) == 0:
                self.debug2 ("size = 0, rm %s" % self.flagFileGpo)
                os.remove(self.hashFileGpo)

        if self.initialisation(self.gpo_name, H, sambaopts, credopts, versionopts) == False:
            self.debug2 ("gpo_already_exists: %s n'existe pas" % self.gpo_name)
            self.debug ("Create GPO")
            doCreate = True
            doAddPolicies = True
            doComputeHash = True 
        else:
            self.debug2 ("gpo_already_exists: %s existe" % self.gpo_name)
            self.debug ("update GPO")

            if os.path.isfile(self.flagFileGpo):
                print ("Ask to recreat GPO because %s exist." % self.flagFileGpo)
                self.debug2 ("rm %s" % self.flagFileGpo)
                os.remove(self.flagFileGpo)
                doDelete = True
                doCreate = True
                doAddPolicies = True 
                doComputeHash = True 
            
            # if gpo hash do not correspond, return 0
            if os.path.isfile(self.hashFileGpo):
                self.debug2 ("gpo_compromised GPOID=%s" % self.gpo_id)
                # hashdeep -r -X -k /var/tmp/gpo-script/eole_script_hash '/home/sysvol/domseth.ac-test.fr/Policies/{0BDCB614-7639-487F-B036-6C0ABF27FE5F}'
                localPathGpo = "/home/sysvol/%s" % self.sharepath.replace('\\', '/')
                cmd_hashdeep = '/usr/bin/hashdeep -r -X -k "%s" "%s"' % (self.hashFileGpo, localPathGpo)
                self.debug2 ("cmd_hashdeep :" + cmd_hashdeep)
                divergent = os.popen(cmd_hashdeep).read() 
                if divergent == "":
                    self.debug2 ("Gpo ok")
                else:
                    self.debug2 ("divergent :\n" + divergent)
                    self.debug2 ("divergent !, rebuild")
                    doDelete = True
                    doCreate = True
                    doAddPolicies = True
                    doComputeHash = True 
            else:
                self.debug ("GPO EOLE \"%s\" existe" % self.gpo_name)

        backup_links_gpo_containers = None 
        if doDelete:
            try:
                if self.gpo_id is None:
                    self.debug ("Pas de suppression de la GPO EOLE \"%s\"" % self.gpo_name)
                else:
                    backup_links_gpo_containers = get_gpo_containers(self.samdb, self.gpo_id)
                    print ("Suppression de la GPO EOLE \"%s\"" % self.gpo_id)
                    cmd = cmd_del()
                    cmd.run(self.gpo_id, H, sambaopts, credopts, versionopts)
            except CommandError as ce:
                self.debug ("La GPO n'existe pas, bizarre! " + str(ce))
                pass
            except Exception as e:
                raise e
            
        if doCreate:
            print ("Enregistrement de la GPO EOLE \"%s\"" % self.gpo_name)
            cmd = cmd_create()
            cmd.run(displayname=self.gpo_name, H=H, sambaopts=sambaopts, credopts=credopts, versionopts=versionopts)

            if self.initialisation(self.gpo_name, H, sambaopts, credopts, versionopts) == False:
                raise CommandError("GPO create %s failed " % self.gpo_name)
            localPathGpo = "/home/sysvol/%s" % self.sharepath.replace('\\', '/')
            connNetlogon = self.smb_connection(self.dc_hostname, "netlogon", lp=self.lp, creds=self.creds, sign=True)
            self.create_directory_hier(connNetlogon, 'users')
            self.set_ownership_and_mode('users', gpo=str(self.gpo_id), conn=connNetlogon, samdb=self.samdb)                
            self.create_directory_hier(connNetlogon, 'groups')
            self.set_ownership_and_mode('groups', gpo=str(self.gpo_id), conn=connNetlogon, samdb=self.samdb)                
            self.create_directory_hier(connNetlogon, 'machines')
            self.set_ownership_and_mode('machines', gpo=str(self.gpo_id), conn=connNetlogon, samdb=self.samdb)                
            self.create_directory_hier(connNetlogon, 'os')
            self.set_ownership_and_mode('os', gpo=str(self.gpo_id), conn=connNetlogon, samdb=self.samdb)                
            doComputeHash = True
            doCheck = True
            
        if doAddPolicies:
            self.debug ("Register 'WaitNetwork'")
            cmd = cmd_register()
            cmd.run(pol_path="WaitNetwork",
                     cse='{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F73-3407-48AE-BA88-E8213C6761F1}',
                     pol_type='Registry.pol',
                     GPT_path='User',
                     template="HKLM\Software\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon;SyncForegroundPolicy;REG_DWORD;4;{value}",
                     update=True)
            
            self.debug ("Add 'WaitNetwork' to GPO EOLE \"%s\"" % self.gpo_name)
            cmd = cmd_add()
            cmd.run(GPO=self.gpo_name, policy="WaitNetwork", variables=['value:1'], overwrite=False, H=H, sambaopts=sambaopts, credopts=credopts, versionopts=versionopts)
            doComputeHash = True
            doCheck = True

        cmd = cmd_importation_from_source()
        cmd.run(self.gpo_name, sources_path=['/usr/share/eole/gpo/reg', '/usr/share/eole/gpo/script'], force=False, H=H, sambaopts=sambaopts, credopts=credopts, versionopts=versionopts)

        if doDelete: 
            if len(backup_links_gpo_containers):
                self.debug ("Restore link for GPO %s" % self.gpo_name)
                for gpo_container in backup_links_gpo_containers:
                    container_dn = str(gpo_container['dn'])
                    if self.doSetLink(container_dn):
                        print ("linked to container '%s'" % container_dn)

        if not container is None:
            print ("Linked to container '%s'" % container)
            self.doSetLink(container)

        # dans le code, il est indiqué qu'il ne faut pas faire les setAcl dans la transaction !
        if doCheck:
            self.debug ("check_gpos_acl ...")
            self.check_gpos_acl()

        self.debug ("Compute Hash, wait ...")
        cmd_hashdeep = 'hashdeep -r "%s" >"%s" ' % (localPathGpo, self.hashFileGpo)
        self.debug2 ("cmd_hashdeep :" + cmd_hashdeep)
        update_hash = os.popen(cmd_hashdeep).read()
        self.debug2 ("update hash :" + update_hash)

        print ("Import OK")
            

class cmd_delete(EoleGPOCommand):
    """Delete a GPO by displayName."""

    synopsis = "%prog <displayname> [options]"

    takes_optiongroups = {
        "sambaopts": options.SambaOptions,
        "versionopts": options.VersionOptions,
        "credopts": options.CredentialsOptions,
    }

    takes_args = ['displayname']

    takes_options = [
        Option("-H", help="LDB URL for database or target server", type=str),
    ]

    def runInTransaction(self):
        # Check for existing links
        gpo_containers = get_gpo_containers(self.samdb, self.gpo_id)
        if len(gpo_containers):
            self.outf.write("GPO %s is linked to containers\n" % self.gpo_id)
            for gpo_container in gpo_containers:
                del_gpo_link(self.samdb, gpo_container['dn'], self.gpo_id)
                self.outf.write("    Removed link from %s.\n" % gpo_container['dn'])
        # Remove LDAP entries
        gpo_dn = get_gpo_dn(self.samdb, self.gpo_id)
        self.debug2 ("samdb delete gpo dn :" + str(gpo_dn))
        gpo_dn_user = ldb.Dn(self.samdb, "CN=User,%s" % str(gpo_dn))
        self.debug2 ("samdb delete gpo user :" + str(gpo_dn_user))
        self.samdb.delete(gpo_dn_user)
        gpo_dn_machine = ldb.Dn(self.samdb, "CN=Machine,%s" % str(gpo_dn))
        self.debug2 ("samdb delete gpo machine :" + str(gpo_dn_machine))
        self.samdb.delete(gpo_dn_machine)
        self.debug2 ("samdb delete:" + str(self.gpo_dn))
        self.samdb.delete(self.gpo_dn)
        # Remove GPO files
        self.debug2 ("conn delete:" + self.sharepath)
        self.conn.deltree(self.sharepath)
        self.outf.write ("GPO %s deleted.\n" % self.displayname)

    def run(self, displayname, H=None, sambaopts=None, credopts=None, versionopts=None):
        return self.connectAndRunInTransaction(displayname, H, sambaopts, credopts, versionopts)

            
class cmd_show(EoleGPOCommand):
    """Select a GPO by displayName."""

    synopsis = "%prog <displayname> [options]"

    takes_optiongroups = {
        "sambaopts": options.SambaOptions,
        "versionopts": options.VersionOptions,
        "credopts": options.CredentialsOptions,
    }

    takes_args = ['displayname']

    takes_options = [
        Option("-H", help="LDB URL for database or target server", type=str),
        Option("--attribut", help="GPO Attribute", type=str)
    ]

    def run(self, displayname, attribut=None, H=None, sambaopts=None, credopts=None, versionopts=None):

        if self.initialisation(displayname, H, sambaopts, credopts, versionopts) is False:
            self.errf.write ("GPO %s is unkown." % displayname)
            return 1
        else:
            if attribut is None:
                self.outf.write(str(self.gpc_entry['name'][0]))
            else:
                self.outf.write(str(self.gpc_entry[attribut][0]))
            self.outf.write('\n') 
            
            
class cmd_importation_from_backup(cmd_restore):
    """Import GPO Eole to a new container."""

    synopsis = "%prog [options]"

    takes_optiongroups = {
        "sambaopts": options.SambaOptions,
        "versionopts": options.VersionOptions,
        "credopts": options.CredentialsOptions,
    }

    takes_args = [ ]
    
    takes_options = [
        Option("-H", help="LDB URL for database or target server", type=str),
        Option("--sourcepath", help="Source folder of the policy", type=str, default='/usr/share/eole/gpo/script'),
        Option("--displayname", help="GPO Display Name", type=str),
        Option("--tmpdir", help="Temporary directory for copying policy files", type=str),
        Option("--entities", help="File defining XML entities to insert into DOCTYPE header", type=str),
        Option("--restore-metadata", help="Keep the old GPT.INI file and associated version number", default=False, action="store_true")
    ]
    
    # cf. https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/guid-list-of-group-policy-client-extensions/
    # 42B5FAAE-6536-11D2-AE5A-0000F87571E3 ProcessScriptsGroupPolicy
    # 40B6664F-4972-11D1-A7CA-0000F87571E3 Scripts (Startup/Shutdown)
    # BEE07A6A-EC9F-4659-B8C9-0B1937907C83 Preference Tool CSE GUID Registry
    # 00000000-0000-0000-0000-000000000000 Core GPO Engine
    # B087BE9D-ED37-454F-AF9C-04291E351182 Preference CSE GUID Registry
    def restore_from_backup_to_local_dir(self, sourcedir, targetdir, dtd_header=''):
        self.outf.write("restore_from_backup_to_local_dir ... \n")
        # Convert Machine registry files to usr/share/eole/gpo/reg/Machine/Registry.xml
        # regToXml('/usr/share/eole/gpo/reg/Machine')
        # Convert User registry files to usr/share/eole/gpo/reg/User/Registry.xml
        # regToXml('/usr/share/eole/gpo/reg/User')
        # Import Logon PowerShell scripts
#         for script_file in glob('/usr/share/eole/gpo/script/User/*.ini'):
#             main('eole_script', 'User', 'Scripts', script_file, join('User/Scripts', basename(script_file)))
#         for script_file in glob('/usr/share/eole/gpo/script/User/*.ps1'):
#             main('eole_script', 'User', 'Scripts', script_file, join('User/Scripts/Logon', basename(script_file)))
#         # Import Machine StartUp PowerShell scripts
#         for script_file in glob('/usr/share/eole/gpo/script/Machine/*.ini'):
#             main('eole_script', 'Machine', 'Scripts', script_file, join('Machine/Scripts', basename(script_file)))
#         for script_file in glob('/usr/share/eole/gpo/script/Machine/*.ps1'):
#             main('eole_script', 'Machine', 'Scripts', script_file, join('Machine/Scripts/StartUp', basename(script_file)))
#         # Import Machine Registry XML
#         regxml_file = '/usr/share/eole/gpo/reg/Machine/Registry.xml'
#         if exists(regxml_file):
#             main('eole_script', 'Machine', 'Registry', regxml_file, 'Machine/Preferences/Registry/Registry.xml')
#         # Import User Registry XML
#         regxml_file = '/usr/share/eole/gpo/reg/User/Registry.xml'
#         if exists(regxml_file):
#             main('eole_script', 'User', 'Registry', regxml_file, 'User/Preferences/Registry/Registry.xml')
        super(cmd_importation_from_backup, self).restore_from_backup_to_local_dir(sourcedir, targetdir, dtd_header)
            
    def run(self, displayname, sourcepath, H=None, tmpdir=None, entities=None, sambaopts=None, credopts=None,
            versionopts=None, restore_metadata=None):
        sourcepath = str(sourcepath)
        if not os.path.isdir(sourcepath):
            raise CommandError("Source directory '%s' does not exist" % sourcepath)
        if displayname is None:
            displayname = os.path.basename(sourcepath)
        super(cmd_importation_from_backup, self).run(displayname, sourcepath, H, tmpdir, entities, sambaopts, credopts, versionopts, restore_metadata)
                    
        
class cmd_importation(SuperCommand):
    """Group Policy Object (GPO) EOLE Scripts."""

    subcommands = {}
    subcommands["importation"] = cmd_import()
    subcommands["importation_from_backup"] = cmd_importation_from_backup()
    subcommands["importation_from_source"] = cmd_importation_from_source()
    subcommands["import_eole_script"] = cmd_importation_eole_script()
    subcommands["delete_by_name"] = cmd_delete()
    subcommands["show_by_name"] = cmd_show()

 
if __name__ == "__main__": 
    # make sure the script dies immediately when hitting control-C,
    # rather than raising KeyboardInterrupt. As we do all database
    # operations using transactions, this is safe.
    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)
     
    cmd = cmd_importation()
    subcommand = None
    args = ()
     
    if len(sys.argv) > 1:
        subcommand = sys.argv[1]
        if len(sys.argv) > 2:
            args = sys.argv[2:]
     
    try:
        retval = cmd._run("eole", subcommand, *args)
    except SystemExit as e:
        retval = e.code
    except Exception as e:
        cmd.show_command_error(e)
        retval = 1
    sys.exit(retval)
    
