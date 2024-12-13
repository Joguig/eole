#!/usr/bin/env python3

# general
import traceback
import os
from io import StringIO
from configparser import ConfigParser
import ntpath

# samba
import ldb
from samba.samdb import SamDB
from samba.ndr import ndr_unpack, ndr_print
from samba.auth import system_session
from samba.auth_util import system_session_unix
from samba.samba3 import libsmb_samba_internal as libsmb
from samba.dcerpc import security, xattr
from samba.ntacls import getntacl, dsacl2fsacl, SMBHelper
from samba.netcmd.common import netcmd_dnsname
from samba.provision import SYSVOL_SERVICE, POLICIES_ACL, acl_type 
import samba.xattr_native

from samba.netcmd.gpo import (
    smb_connection,
    get_gpo_dn,
    parse_unc,
    parse_gplink,
    encode_gplink,
    attr_default,
    get_gpo_info,
    gpo_flags_string,
    CommandError,
    GPOCommand
)


class EoleGPOCommand(GPOCommand):
    """Abstract Class to manage Eole GPO."""

    # to disable pylint error !
    displayname = None
    gpo_id = None
    samdb = None
    lp = None
    creds = None
    realm = None
    dc_hostname = None
    gpo_displayname = None
    url = None
    unc = None
    gpo_dn = None
    gpo_version = None
    dom_name = None
    service = None
    sharepath = None
    conn = None
    debugLevel = 0
    
    #     
    def debug(self, text):
        ''' Envoi le texte sur la sortie Stderr si l'option '-d 1' est passé en arguments à la commande '''
        if self.debugLevel > 0:
            self.errf.write(" * ")
            self.errf.write(text)
            self.errf.write("\n")
            
    def debug2(self, text):
        ''' Envoi le texte sur la sortie Stderr si l'option '-d 2' est passé en arguments à la commande '''
        if self.debugLevel > 1:
            self.errf.write("    * ")
            self.errf.write(text)
            self.errf.write("\n")
            
    def debug3(self, text):
        ''' Envoi le texte sur la sortie Stderr si l'option '-d 2' est passé en arguments à la commande '''
        if self.debugLevel > 2:
            self.errf.write("        * ")
            self.errf.write(text)
            self.errf.write("\n")
            
    # de gpo.py 4.11 avant commit    
    def smb_connection(self, dc_hostname, service, lp, creds, sign=True):
        # SMB connect to DC
        try:
            self.debug2 ("smb_connection '%s' %s " % (dc_hostname, service))
            conn = smb_connection(dc_hostname, service, lp=lp, creds=creds, sign=sign)
        except Exception:
            raise CommandError("Error connecting to '%s' using SMB" % dc_hostname)
        return conn

    # de gpo.py 4.11    
    def samdb_connect(self):
        '''make a ldap connection to the server'''
        try:
            self.samdb = SamDB(url=self.url,
                               session_info=system_session(),
                               credentials=self.creds, lp=self.lp)
        except Exception as e:
            raise CommandError("LDAP connection to %s failed " % self.url, e)

    def load_gpo_entry(self, gpo_name):
        """Get GPO information using get_gpo_info, with displayname
        
        Return :
                False si la GPO n'existe pas
                True si elle existe, et que les variables ont été injectées
                
        Inject :
                self.gpc_entry ='ldb result' 
                self.gpo_id = name
                self.gpo_displayname = displayName 
                self.unc = gPCFileSysPath
                self.gpo_dn = dn
                self.gpo_version = versionNumber
                self.dom_name = dommain extrait de UNC ( le realm )
                self.service = service extrait de UNC ('sysvol')
                self.sharepath = path extrait de UNC 
        
        """
        try:
            self.debug2 ("Get GPO '%s' " % gpo_name)
            gpc_entries = get_gpo_info(self.samdb, displayname=gpo_name)
            if gpc_entries.count == 0:
                self.debug2 ( "gpc_entry = None !")
                return False
            else: 
                self.gpc_entry = gpc_entries[0]
                #self.debug2 ( "gpc_entry = " + str(type( self.gpc_entry )))
                self.gpo_id = self.gpc_entry['name'][0]
                self.debug2 ("gpo name     : %s" % self.gpo_id)
                self.gpo_displayname = self.gpc_entry['displayName'][0]
                self.debug2 ("display name : %s" %  self.gpo_displayname )
                self.unc = str(self.gpc_entry['gPCFileSysPath'][0])
                self.debug2 ("path         : %s" % self.unc)
                self.gpo_dn = self.gpc_entry.dn
                self.debug2 ("dn           : %s" % self.gpo_dn)
                self.gpo_version = int(attr_default(self.gpc_entry, 'versionNumber', '0'))
                self.debug2 ("version      : %s" % self.gpo_version)
                self.debug2 ("flags        : %s" % gpo_flags_string(int(attr_default(self.gpc_entry, 'flags', '0'))))

                self.domain_sid = security.dom_sid(self.samdb.get_domain_sid())
                self.debug2 ("domain_sid   : %s" % str(self.domain_sid))
                if not 'nTSecurityDescriptor' in self.gpc_entry.keys():
                    raise CommandError("pas assez de droits pour accéder au ACL de " + self.gpo_name)
                self.nTSecurityDescriptor = self.gpc_entry['nTSecurityDescriptor'][0]
                self.acl = ndr_unpack(security.descriptor,self.nTSecurityDescriptor).as_sddl()
                self.sddl = dsacl2fsacl( self.acl , self.domain_sid)
                self.fs_sd = security.descriptor.from_sddl(self.sddl, self.domain_sid)
                self.debug2 ("nTSecurityDescriptor : %s" % self.sddl )
            
                if 'gPCMachineExtensionNames' in self.gpc_entry.keys():
                    self.gPCMachineExtensionNames = str(self.gpc_entry['gPCMachineExtensionNames'][0])
                else:
                    self.gPCMachineExtensionNames = ''
                self.gPCMachineExtensionNames_new_state = self.gPCMachineExtensionNames 
                self.debug2 ("gPCMachineExtensionNames: %s" % self.gPCMachineExtensionNames_new_state)

                if 'gPCUserExtensionNames' in self.gpc_entry.keys():
                    self.gPCUserExtensionNames = str(self.gpc_entry['gPCUserExtensionNames'][0])
                else:
                    self.gPCUserExtensionNames = ''
                self.gPCUserExtensionNames_new_state = self.gPCUserExtensionNames 
                self.debug2 ("gPCUserExtensionNames: %s" % self.gPCUserExtensionNames_new_state)

                # verify UNC path
                try:
                    [self.dom_name, self.service, self.sharepath] = parse_unc(self.unc)
                except ValueError:
                    raise CommandError("Invalid GPO path (%s)" % self.unc)
                self.debug2 ("domain       : %s" % self.dom_name)
                self.debug2 ("service      : %s" % self.service)
                self.debug2 ("sharepath    : %s" % self.sharepath)
                return True
        except Exception:
            traceback.print_exc()
            raise CommandError("GPO '%s' does not exist" % gpo_name)
    
    def doConnection(self, H=None, sambaopts=None, credopts=None, versionopts=None):
        self.lp = sambaopts.get_loadparm()
        self.creds = credopts.get_credentials(self.lp, fallback_machine=True)
        self.debugLevel = 0
        debug_level = sambaopts._lp.get('debug level')
        if debug_level is not None:
            debug_level_items = debug_level.split(' ')
            if len(debug_level_items) > 0: 
                try:
                    # dans le cas, "debug level 3 " !
                    self.debugLevel = int(debug_level_items[0])
                except:
                    # dans le cas, "debug level smb:3" !
                    pass
        
        #self.debug2 ( "H            : " + str(H))
        #self.debug2 ( "samaopts     : " + str(vars(sambaopts)))
        #self.debug2 ( "credopts     : " + str(vars(credopts)))
        #self.debug2 ( "versionopts  : " + str(vars(versionopts)))
        self.realm = self.lp.get('realm')
        self.debug2 ( "realm        : " + self.realm)
        
        # We need to know writable DC to setup SMB connection
        if H and H.startswith('ldap://'):
            self.dc_hostname = H[7:]
            self.url = H
        else:
            self.dc_hostname = netcmd_dnsname(self.lp)
            self.url = 'ldap://' + self.dc_hostname
        
        self.debug2 ("dc_hostname  : '%s'" % str(self.dc_hostname ))
        self.samdb_connect()
        
    def initialisation(self, gpo_name, H=None, sambaopts=None, credopts=None, versionopts=None):
        """initialisation :
        - Initialise les variables
        - Initialise la connection à samdb
        - Charge les informations de la GPO 
        
        Return :
                False si la GPO n'existe pas
                True si elle existe, et que les variables ont été injectées
                
        Inject :
                self.lp = load parm from smb.conf
                self.creds = credentials depuis la ligne de commande
                self.realm = déclarer dans smb.conf
                self.dc_hostname = hostname du DC a utiliser (depuis -H ldap:// )
                self.url = (depuis -H ldap:// )
        
        Inject depuis load_gpo_entry:        
                self.gpc_entry ='ldb result' 
                self.gpo_id = name
                self.gpo_displayname = displayName 
                self.unc = gPCFileSysPath
                self.gpo_dn = dn
                self.gpo_version = versionNumber
                self.dom_name = dommain extrait de UNC ( le realm )
                self.service = service extrait de UNC ('sysvol')
                self.sharepath = path extrait de UNC 
        
        """
        self.doConnection(H=H, sambaopts=sambaopts, credopts=credopts, versionopts=versionopts)
        self.debug2 ( "gpo_name     : " + gpo_name)
        return self.load_gpo_entry( gpo_name )
   

    def run(self):
        """Run the command. This should be overridden by all subclasses."""
        raise NotImplementedError(self.run)

    def runInTransaction(self):
        """runInTransaction. This should be overridden by all subclasses.
        
        Cette fonction s'execute dans le cotntext d'une transaction
        - si la fonction renvoi 0, alors la transaction est confirmée
        - si la fonction renvoi 1 ou une exception, alors la transaction est annulée
        
        """
        raise NotImplementedError(self.run)

    def connectAndRunInTransaction(self, displayname, H=None, sambaopts=None, credopts=None, versionopts=None):
        """ connect And call runInTransaction
        Cette fonction est appelée pour :
        - charger la GPO,
        - initier la connexion SmaDB,
        - ouvrir la connexion SMB
        - appeler runInTransaction dans le contexte d'une transaction
        - garantir 1 seul commit/rollback  
        """

        self.displayname = displayname
        if self.initialisation( displayname, H, sambaopts, credopts, versionopts ) is False:
            print ("GPO %s is unkown." % displayname)
            return 1
        
        self.samdb.transaction_start()
        try:
            self.conn = self.smb_connection(self.dc_hostname, self.service, lp=self.lp, creds=self.creds, sign=True)
            self.debug2( str( self.conn ))
            self.runInTransaction()
            self.samdb.transaction_commit()
            return 0
        except Exception as e:
            self.samdb.transaction_cancel()
            traceback.print_exc()
            raise e

    def erreur_acl(self, messages, direct_db_access, path, acl_lue, acl_attendue, policy_path):
        self.debug2 ( path)
        self.debug2 ( "   " + acl_type(direct_db_access) + " " + messages )
        self.debug2 ( "   " + acl_lue )
        self.debug2 ( "   " + acl_attendue )
        if acl_attendue is None: 
            return
        
        smb_path = path.replace("/home/sysvol/",'').replace('/','\\')
        self.debug ( "Correction acl " + smb_path )
        self.conn.set_acl(smb_path, self.fs_sd, security.SECINFO_OWNER |
                                              security.SECINFO_GROUP |
                                              security.SECINFO_DACL |
                                              security.SECINFO_PROTECTED_DACL )
         
    def check_gpos_acl(self):
        """Set ACL on the sysvol/<dnsname>/Policies folder and the policy
        folders beneath.
        """
    
    
        self.conn = self.smb_connection(self.dc_hostname, self.service, lp=self.lp, creds=self.creds, sign=True)
        
        # Set ACL for GPO root folder
        sysvolpath = "/home/sysvol"
        domainsid = security.dom_sid(self.samdb.get_domain_sid())
        self.debug2 ("domainsid = " + str(domainsid) )
        domaindn = self.samdb.domain_dn()
        self.debug2 ("domaindn  = " + domaindn ) 
        dnsdomain = self.dom_name
        self.debug2 ("dnsdomain  = " + dnsdomain )
        
        root_policy_path = os.path.join(sysvolpath, self.dom_name, "Policies")
        self.debug2 ("root_policy_path   = " + root_policy_path  )

        policy_path = os.path.join(root_policy_path, str(self.gpo_id))
        self.debug2 ("policy_path  = " + policy_path )
        
        # Ensure we can read this directly, and via the smbd VFS
        session_info = system_session_unix()
        for direct_db_access in [True, False]:
            fsacl = getntacl(self.lp, root_policy_path, session_info, direct_db_access=direct_db_access, service=SYSVOL_SERVICE)
            if fsacl is None:
                self.erreur_acl ('DB ACL on policy root not found!', direct_db_access, root_policy_path, None, None, policy_path)
            fsacl_sddl = fsacl.as_sddl(domainsid)
            if fsacl_sddl != POLICIES_ACL:
                self.erreur_acl ('ACL on policy root does not match expected value from provision', direct_db_access, root_policy_path, fsacl_sddl, POLICIES_ACL, policy_path)
        
            fsacl = getntacl(self.lp, policy_path, session_info, direct_db_access=direct_db_access, service=SYSVOL_SERVICE)
            fsacl_sddl = fsacl.as_sddl(domainsid)
            if fsacl_sddl != self.sddl :
                self.erreur_acl ('ACL on GPO directory does not match expected value from GPO object', direct_db_access, policy_path, fsacl_sddl, self.sddl, policy_path)
            
            for root, dirs, files in os.walk(policy_path, topdown=False):
                self.debug2 (" root: " + root )
                for name in files:
                    self.debug2 (" file: " + name )
                    root_path = os.path.join(root, name)
                    fsacl = getntacl(self.lp, root_path, session_info, direct_db_access=direct_db_access, service=SYSVOL_SERVICE)
                    if fsacl is None:
                        self.erreur_acl ('ACL on GPO file not found!', direct_db_access, root_path, None, None, policy_path)
                    fsacl_sddl = fsacl.as_sddl(domainsid)
                    if fsacl_sddl != self.sddl :
                        self.erreur_acl ('ACL on GPO file does not match expected value from GPO object', direct_db_access, root_path, fsacl_sddl, self.sddl, policy_path)
        
                for name in dirs:
                    self.debug2 (" dir: " + name )
                    root_path = os.path.join(root, name)
                    fsacl = getntacl(self.lp, root_path, session_info, direct_db_access=direct_db_access, service=SYSVOL_SERVICE)
                    if fsacl is None:
                        self.erreur_acl ('ACL on GPO directory not found!', direct_db_access, root_path, None, None)
                    fsacl_sddl = fsacl.as_sddl(domainsid)
                    if fsacl_sddl != self.sddl :
                        self.erreur_acl ('ACL on GPO directory does not match expected value from GPO object', direct_db_access, root_path, fsacl_sddl, self.sddl, policy_path)
                
    def set_ownership_and_mode(self, file_path, gpo, conn, samdb):
        """Set ownership and acl for rule file file_path in GPT to user connected
        through conn and samdb connection (copied from samba.netcmd.gpo).
        :param file_path: location of rule file in unc format
        :type file_path: str
        :param gpo: gpo ID
        :type gpo: str
        :param conn: connection to server with SMB protocol
        :type conn: smb.SMB
        :param samdb: connection to ldb
        :type samdb: samba.samdb.SamDB
        """
        # Get new security descriptor
        ds_sd_flags = ( security.SECINFO_OWNER |
                        security.SECINFO_GROUP |
                        security.SECINFO_DACL )
        msg = get_gpo_info(samdb, gpo=gpo, sd_flags=ds_sd_flags)[0]
        ds_sd_ndr = msg['nTSecurityDescriptor'][0]
        ds_sd = ndr_unpack(security.descriptor, ds_sd_ndr).as_sddl()
    
        # Create a file system security descriptor
        domain_sid = security.dom_sid(samdb.get_domain_sid())
        sddl = dsacl2fsacl(ds_sd, domain_sid)
        fs_sd = security.descriptor.from_sddl(sddl, domain_sid)
        # Set ACL
        sio = ( security.SECINFO_OWNER |
                security.SECINFO_GROUP |
                security.SECINFO_DACL |
                security.SECINFO_PROTECTED_DACL )
        #self.debug2 ("set_acl = " + file_path)
        #self.debug2 ("sddl       = " + sddl ) 
        conn.set_acl(file_path, fs_sd, sio)

    def gpc_update_extension(self, gpo_dn, gpc_entry, cse_info, samdb):
        """Update GPC with cse information from added policy.
        :param gpo_dn: Group Policy Object dn
        :type gpo_dn: str
        :param cse_info: information needed to declare extension in GPC
        :type cse_info: tuple -> ( str , str list )
        :param samdb: ldb connection
        :type samdb: SamDB
        """
        #print("gpo_dn="+str(gpo_dn) + " gpc_entry=" + str( gpc_entry ) + " cse_info=" + str(cse_info))
        if isinstance(cse_info[1], list):
            cse_guid_list = cse_info[1]
        elif isinstance(cse_info[1], str):
            cse_guid_list = [cse_info[1]]
        else:
            raise Exception('type extension unknown')
        field = 'gPC{}ExtensionNames'.format(cse_info[0])
        if not field in gpc_entry.keys():
            # First value in field
            new_state = '[{}]'.format(']['.join(sorted(cse_guid_list)))
        else:
            # Merge old values with new values in field; must be sorted and uniq.
            gpc_entries_list = str(gpc_entry[field]).strip('[]').split('][')
            new_state = sorted(set(gpc_entries_list + cse_guid_list))
            new_state = '[{}]'.format(']['.join(new_state))
        m = ldb.Message()
        m.dn = gpo_dn
        m['a05'] = ldb.MessageElement(new_state, ldb.FLAG_MOD_REPLACE, field)
        controls = ["permissive_modify:0"]
        samdb.modify(m, controls=controls)
        
    def gpc_update_extension_value(self, current, cse_info):
        """Update GPC with cse information from added policy.
        :param current: information needed to declare extension in GPC
        :type current: str list
        :param cse_info: information needed to declare extension in GPC
        :type cse_info: str list
        """
        #self.debug2 ("gpc_update_extension_value")
        #self.debug2 ("  current = " + current )
        #self.debug2 ("  cse_info = " + str(cse_info))
        if isinstance(cse_info, list):
            # exemple: cse_info = ['{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}']
            # exemple: cse_info = ["{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}","{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}"]
            cse_guid_list = cse_info
        elif isinstance(cse_info, str):
            # exemple: cse_info[1] = '{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}'
            cse_guid_list = [cse_info]
        else:
            raise Exception('type extension unknown')

        if current != '':
            gpc_entries_list = str(current).strip('[]').split('][')
            new_state = set(gpc_entries_list + cse_guid_list)
        else:
            new_state = cse_guid_list
        # tri obligatoire 
        new_state = sorted(new_state)
        # format
        new_state = '[{}]'.format(']['.join(new_state))
        if current != new_state:
            self.debug2 ("  gpc_update_extension_value return = " + new_state )
        return new_state

    def gpc_update_extension_once_in_transaction(self, field, current, new_state):
        """Update GPC with cse information from added policy.
        :param field: 
        :type gPCuserExtensionNames | gPCMachineExtensionNames
        :param current: current information extension in GPC
        :type current: str list 
        :param new_state: information needed to declare extension in GPC
        :type new_state: str list 
        :summary: new_state: ex.: [{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}][{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}]
        :param samdb: ldb connection
        :type samdb: SamDB
        """
        self.debug2 ("gpc_update_extension_one_in_transaction " + field + " " + current + " -> " + new_state)
        if current == new_state:
            return
        self.debug2 ("set extensions " + field + " " + new_state )
        # display name : 'Default Domain Policy'
        #dn: CN={31B2F340-016D-11D2-945F-00C04FB984F9},CN=Policies,CN=System,DC=domscribe,DC=ac-test,DC=fr
        #gPCMachineExtensionNames: [{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{53D6AB1B-2488-11D1-A28C-00C04FB94F17}][{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}][{B1BE8D72-6EAC-11D2-A4EA-00C04F79F83A}{53D6AB1B-2488-11D1-A28C-00C04FB94F17}]
         
        # display name : 'EnableLinkedConnections' (version 4)
        #gPCMachineExtensionNames: [{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}][{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}]
         
        # display name : 'eole_script' (version 65556 !)
        #gPCMachineExtensionNames: [{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}][{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}]
         
        # display name : 'Default Domain Controllers Policy'
        #dn: CN={6AC1786C-016F-11D2-945F-00C04FB984F9},CN=Policies,CN=System,DC=domscribe,DC=ac-test,DC=fr
        #gPCMachineExtensionNames: [{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}]
        
        m = ldb.Message()
        m.dn = self.gpo_dn
        m['a05'] = ldb.MessageElement(new_state, ldb.FLAG_MOD_REPLACE, field)
        controls = ["permissive_modify:0"]
        self.samdb.modify(m, controls=controls)
        
    def update_gpt_version(self, gpt_path, version, conn):
        """Save new version value to GPT.
        :param gpt_path: location of GPO in GPT
        :type gpt_path: str
        :param version: version number
        :type version: str
        :param conn: connection to server through SMB
        :type conn: smb.SMB
        """
        #self.debug2 ("update_gpt_version version=" + version)
        gpt_ini_path = gpt_path + '\\GPT.INI'
        self.debug2 ("update_gpt_version gpt_ini_path=" + gpt_ini_path)
        gpt_ini_content = conn.loadfile(gpt_ini_path)
        cp = ConfigParser()
        cp.read_file(StringIO(gpt_ini_content.decode('utf-8') if isinstance(gpt_ini_content, bytes) else gpt_ini_content))
        cp.set('General', 'Version', version)
        cp_content = StringIO()
        cp.write(cp_content)
        cp_content.seek(0)
        self.savecontent(gpt_ini_path, cp_content.read())
    
    def savecontent(self, remote_path, content):
        """Create file with content through SMB connection or locally.
        :param remote_path: location of file to create, either in unc format if
                            conn is provided, or as absolute path.
        :type remote_path: str
        :param content: content of file
        :type content: str
        """
        #self.debug2 ("savecontent  " + remote_path)
        remote_path_folder = ntpath.dirname(remote_path)
        self.debug2 ("savecontent: remote_path_folder " + remote_path_folder)
        self.create_directory_hier(self.conn, self.fs_sd, remote_path_folder)
        self.conn.savefile(remote_path, content.encode('utf-8') if isinstance(content, str) else content)

        self.debug2 ("savecontent: setacl " + remote_path)
        self.conn.set_acl(remote_path, self.fs_sd, security.SECINFO_OWNER |
                                                   security.SECINFO_GROUP |
                                                   security.SECINFO_DACL |
                                                   security.SECINFO_PROTECTED_DACL )
        
    def check_attrs_path(self, remotepath, r_name, l_name, sources_path, e):

        relative_name = r_name[len(remotepath)+1:].replace("\\","/")
        recherche = '# file: ' + relative_name
        #self.debug2( '    check_attrs: recherche  "' + recherche + '"')

        # extract from 'attrs' file from paquet
        dosattrib_attendu = None
        for source_path in sources_path:
            attrs_path = os.path.join(source_path , 'attrs' )
            if os.path.isfile(attrs_path):
                #self.debug2( '    check_attrs: attrs_path ' + attrs_path)
                with open(attrs_path, 'r') as ltemp:
                    file_and_path = ltemp.readline()
                    while file_and_path:
                        file_and_path = file_and_path.strip()
                        idx = file_and_path.find(recherche)
                        #self.debug2( '    file_and_path "' + file_and_path + '" idx=' + str(idx))
                        if idx >= 0:
                            dosattrib_attendu = ltemp.readline()
                            #self.debug2( '    file_and_path OK' )
                            break
                        file_and_path = ltemp.readline()
        
        if dosattrib_attendu is None:
            # je ne connais pas , j'ignore !
            self.debug2( '    check_attrs: ' + l_name + ' inconnu' )
            return
        
        # extract from file system
        try:
            attribute = samba.xattr_native.wrap_getxattr(l_name, xattr.XATTR_DOSATTRIB_NAME_S3)
        except Exception:
            self.debug2( '    check_attrs: attribute  exception !' )
            return

        # extract with getfattr 
        cmd_getfattr="getfattr -n user.DOSATTRIB -e hex '" + l_name + "' 2>/dev/null"
        #self.debug2( '    check_attrs: cmd_getfattr ' + cmd_getfattr)
        dosattribs = os.popen(cmd_getfattr).read().split('\n')
        
        dosattrib = dosattribs[1][0:49]
        #self.debug2( '    check_attrs: dosattrib  "' + dosattrib + '"')
        dosattrib1 = dosattrib_attendu[0:49]
        #self.debug2( '    check_attrs: dosattrib1 "' + dosattrib1 + '"')
        if dosattrib == dosattrib1:
            return

        self.debug2( 'check_attrs: ' + l_name + " e=" + str(e))
        self.debug2( '    check_attrs: dosattrib_attendu  "' + dosattrib_attendu + '"')
        self.debug2( '    check_attrs: dosattrib getfattr "' + str(dosattribs[1]) + '"')
        attribute_from_filesystem = ndr_unpack(xattr.DOSATTRIB, attribute)
        if attribute_from_filesystem:
            self.debug2( '    check_attrs: attribute samba  ' + ndr_print(attribute_from_filesystem))
        else:
            self.debug2( '    check_attrs: attribute samba ?')
        
        dosattrib_to_set = dosattrib_attendu[len(xattr.XATTR_DOSATTRIB_NAME_S3)+1:].strip()
        cmd_setfattr="setfattr -n user.DOSATTRIB -v '" + dosattrib_to_set + "' '" + l_name + "'"
        self.debug2( '    check_attrs: cmd_setfattr ' + cmd_setfattr)
        cmd_setfattr_ouput = os.popen(cmd_setfattr).read()
        self.debug2( '    check_attrs: cmd_setfattr_ouput ' + cmd_setfattr_ouput)
        self.debug( 'Fix attrs: ' + relative_name)

        
    def check_attrs(self, remotepath, sources_path):
        """Create directory through SMB connection (copied from samba.netcmd.gpo).
        :param conn: connection to server with SMB protocol
        :type conn: smb.SMB
        :param remotepath: folder to create remotely
        :type remotepath: str
        """
        self.debug2 ("check_attrs: " + remotepath)
        attr_flags = libsmb.FILE_ATTRIBUTE_SYSTEM | \
                     libsmb.FILE_ATTRIBUTE_DIRECTORY | \
                     libsmb.FILE_ATTRIBUTE_ARCHIVE | \
                     libsmb.FILE_ATTRIBUTE_HIDDEN

        self.use_ntvfs = "smb" in self.lp.get("server services")
        self.debug3 ("check_attrs: use_ntvfs " + str(self.use_ntvfs))
        smb_helper = SMBHelper(self.conn, self.domain_sid)
        
        l_dirs = [ "/home/sysvol/%s" % remotepath.replace('\\', '/') ]
        r_dirs = [ remotepath ]
        while r_dirs:
            r_dir = r_dirs.pop()
            l_dir = l_dirs.pop()
            dirlist = self.conn.list(r_dir, attribs=attr_flags)
            dirlist.sort(key=lambda x: x['name'])
            for e in dirlist:
                r_name = smb_helper.join(r_dir, e['name'])
                l_name = os.path.join(l_dir, e['name'])
                if e['attrib'] & libsmb.FILE_ATTRIBUTE_DIRECTORY:
                    r_dirs.append(r_name)
                    l_dirs.append(l_name)
                self.check_attrs_path(remotepath, r_name, l_name, sources_path, e)

    def create_directory_hier(self, conn, fs_sd, remotedir):
        """Create directory through SMB connection (copied from samba.netcmd.gpo).
        :param conn: connection to server with SMB protocol
        :type conn: smb.SMB
        :param remotedir: folder to create remotely
        :type remotedir: str
        """
        #self.debug2 ("create_directory_hier " + remotedir)
        elems = remotedir.replace('/', '\\').split('\\')
        path = ""
        for e in elems:
            path = path + '\\' + e
            #self.debug2 ("create_directory_hier: path? " + path)
            if not conn.chkpath(path):
                self.debug2 ("create_directory_hier: mkdir " + path)
                conn.mkdir(path)
                self.debug2 ("create_directory_hier: setacl " + path)
                conn.set_acl(path, fs_sd, security.SECINFO_OWNER |
                                                security.SECINFO_GROUP |
                                                security.SECINFO_DACL |
                                                security.SECINFO_PROTECTED_DACL )

    def update_gpc_version(self, gpo_dn, version, samdb):
        """Save new version value to GPC.
        :param gpo_dn: DN identifying GPO in GPC
        :type gpo_dn: DN object
        :param version: version number
        :type version: str
        :param conn: connection to server through SMB
        :type conn: smb.SMB
        """
        m = ldb.Message()
        m.dn = gpo_dn
        m['a05'] = ldb.MessageElement(version, ldb.FLAG_MOD_REPLACE, "versionNumber")
        controls = ["permissive_modify:0"]
        samdb.modify(m, controls=controls)
        
    def doSetLink(self, container_dn ):

        self.debug2 ("doSetLink :" + str(container_dn))
        gpo_dn = str(get_gpo_dn(self.samdb, self.gpo_id))
        self.debug2 ("gpo dn :" + gpo_dn ) 
        
        # Check if valid Container DN
        try:
            containerObject = self.samdb.search(base=container_dn, scope=ldb.SCOPE_BASE,
                                    expression="(objectClass=*)",
                                    attrs=['gPLink'])[0]
        except Exception:
            raise CommandError("Container '%s' does not exist" % container_dn)

        # Update existing GPlinks or Add new one
        existing_gplink = False
        gplink_options = 0
        if 'gPLink' in containerObject:
            gplist = parse_gplink(str(containerObject['gPLink'][0]))
            existing_gplink = True
            found = False
            for g in gplist:
                gplink_options = g['options'] 
                if g['dn'].lower() == gpo_dn.lower():
                    g['options'] = gplink_options
                    found = True
                    break
            if found:
                self.debug ("GPO '%s' already linked to this container" % self.gpo_id)
                return False
            else:
                gplist.insert(0, {'dn': gpo_dn, 'options': gplink_options})
        else:
            gplist = []
            gplist.append({'dn': gpo_dn, 'options': gplink_options})

        gplink_str = encode_gplink(gplist)

        m = ldb.Message()
        m.dn = ldb.Dn(self.samdb, container_dn)

        if existing_gplink:
            m['new_value'] = ldb.MessageElement(gplink_str, ldb.FLAG_MOD_REPLACE, 'gPLink')
        else:
            m['new_value'] = ldb.MessageElement(gplink_str, ldb.FLAG_MOD_ADD, 'gPLink')

        try:
            self.samdb.modify(m)
        except Exception as e:
            raise CommandError("Error adding GPO Link to %s " % container_dn, e)
        return True


