#!/usr/bin/env python
import optparse
import filecmp
import sys
import ldb
import ntpath
from os.path import basename, exists, join
from glob import glob
from samba import smb
import samba.getopt as options
from samba.netcmd.gpo import samdb_connect, dc_url
from samba.dcerpc import nbt
from samba.net import Net
from samba.credentials import MUST_USE_KERBEROS
from samba.credentials import Credentials
from gpo_utils.policy import GPOVersion, savecontent, update_gpt_version, \
                            update_gpc_version, set_ownership_and_mode, \
                            gpc_update_extension


class ConnectBag:
    pass


def connexion(lp, creds):
    # Open connection SamDB and SMB
    # We need to know writable DC to setup SMB connection
    net = Net(creds=creds, lp=lp)
    flags = (nbt.NBT_SERVER_LDAP |
             nbt.NBT_SERVER_DS |
             nbt.NBT_SERVER_WRITABLE)
    cldap_ret = net.finddc(domain=lp.get('realm'), flags=flags)
    dc_hostname = cldap_ret.pdc_dns_name

    realm = cldap_ret.dns_domain

    # Connect to DC over SMB
    try:
        conn = smb.SMB(dc_hostname, 'sysvol', lp=lp, creds=creds)
    except Exception, e:
        raise Exception("Error connecting to '%s' using SMB" % dc_hostname, e)
    return conn, realm


def get_samdb(lp, creds, url):
    bag = ConnectBag()
    bag.lp = lp
    bag.creds = creds
    bag.url = url
    samdb_connect(bag)
    return bag.samdb


def get_gpo_informations(samdb, gpo_name):
    base_dn = samdb.get_default_basedn()
    base_dn.add_child(ldb.Dn(samdb, "CN=Policies,CN=System"))
    search_scope = ldb.SCOPE_ONELEVEL
    search_expr = "(&(objectClass=groupPolicyContainer)(displayname=%s))" % ldb.binary_encode(gpo_name)
    # find groupPolicyContainer for given display name
    try:
        gpc_entry = samdb.search(base=base_dn, scope=search_scope,
                                 expression=search_expr,
                                 attrs=['versionNumber',
                                        'name',
                                        'gPCMachineExtensionNames',
                                        'gPCUserExtensionNames'])[0]
    except Exception:
        raise Exception("Container '%s' does not exist" % gpo_name)
    gpo_id = gpc_entry['name']
    gpo_dn = gpc_entry['dn']
    gpo_version = int(str(gpc_entry['versionNumber']))
    return gpo_id, gpo_dn, gpo_version, gpc_entry


def main(gpo_name, context, policy_type, policy_unix_path, policy_smb_path, force=False):
    """
    * copy @policy_unix_path@ file into @gpo_name@ policy directory
    * update sam.ldb with gpc informations
    ** gpo_name : the name of the GPO
    ** context : "User" or "Machine"
    ** policy_type : "Scripts" or 'Registry" (perhaps more in the future)
    ** policy_unix_path : file to copy
    ** policy_smb_path : policy path relative path
    """

    gpc_ext_list = {}
    gpc_ext_list['Machine'] = {}
    gpc_ext_list['User'] = {}
    gpc_ext_list['Machine']['Scripts'] = ["{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}"]
    gpc_ext_list['User']['Scripts'] = ["{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-11D1-A7CA-0000F87571E3}"]
    gpc_ext_list['Machine']['Registry'] = ["{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}", "{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}"]
    gpc_ext_list['User']['Registry'] = ["{00000000-0000-0000-0000-000000000000}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}", "{B087BE9D-ED37-454F-AF9C-04291E351182}{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}"]
    try:
        gpc_extension = gpc_ext_list[context][policy_type]
    except:
        print("Context {0} with {1} type not managed.".format(context, policy_type))
        raise
    if exists(policy_smb_path) and filecmp.cmp(policy_unix_path, policy_smb_path) and not force:
        sys.exit(0)

    parser = optparse.OptionParser()
    lp = options.SambaOptions(parser).get_loadparm()
    #creds = options.CredentialsOptions(parser).get_credentials(lp, fallback_machine=True)
    creds = Credentials()
    creds.guess(lp)
    creds.set_kerberos_state(MUST_USE_KERBEROS)

    url = dc_url(lp, creds, None)

    samdb = get_samdb(lp, creds, url)
    samdb.transaction_start()
    try:
        # connexion
        conn, realm = connexion(lp, creds)

        gpo_id, gpo_dn, gpo_version, gpc_entry = get_gpo_informations(samdb, gpo_name)
        sharepath = '{}\\Policies\\{}'.format(realm, gpo_id)
        # load content if file exists
        smb_path = ntpath.join(sharepath, policy_smb_path)

        # write file
        with open(policy_unix_path, 'r') as contentfh:
            content = contentfh.read()
        try:
            savecontent(smb_path, content, conn=conn)
        except TypeError:
            local_path = join('/home/sysvol/{}/Policies/{}'.format(realm, gpo_id), policy_smb_path)
            savecontent(local_path, content)

        # modify gPCExtension field for GPO
        gpc_update_extension(gpo_dn, gpc_entry, (context, gpc_extension), samdb)

        # update GPO version
        gpoversion = GPOVersion()
        gpoversion.extract(gpo_version)
        gpoversion.add(context)

        # modify version in GPT
        update_gpt_version(sharepath, gpoversion.value(), conn=conn)

        # modify version for groupPolicyContainer
        update_gpc_version(gpo_dn, gpoversion.value(), samdb)

        # fix ownership
        set_ownership_and_mode(smb_path, gpo=str(gpo_id), conn=conn, samdb=samdb)

    except Exception:
        samdb.transaction_cancel()
        raise
    else:
        samdb.transaction_commit()

# Import Logon PowerShell scripts
for script_file in glob('/usr/share/eole/gpo/script/User/*.ini'):
    main('eole_script', 'User', 'Scripts', script_file, join('User/Scripts', basename(script_file)))
for script_file in glob('/usr/share/eole/gpo/script/User/*.ps1'):
    main('eole_script', 'User', 'Scripts', script_file, join('User/Scripts/Logon', basename(script_file)))

# Import Machine StartUp PowerShell scripts
for script_file in glob('/usr/share/eole/gpo/script/Machine/*.ini'):
    main('eole_script', 'Machine', 'Scripts', script_file, join('Machine/Scripts', basename(script_file)))
for script_file in glob('/usr/share/eole/gpo/script/Machine/*.ps1'):
    main('eole_script', 'Machine', 'Scripts', script_file, join('Machine/Scripts/StartUp', basename(script_file)))

# Import Machine Registry XML
regxml_file = '/usr/share/eole/gpo/reg/Machine/Registry.xml'
if exists(regxml_file):
    main('eole_script', 'Machine', 'Registry', regxml_file, 'Machine/Preferences/Registry/Registry.xml')

# Import User Registry XML
regxml_file = '/usr/share/eole/gpo/reg/User/Registry.xml'
if exists(regxml_file):
    main('eole_script', 'User', 'Registry', regxml_file, 'User/Preferences/Registry/Registry.xml')
