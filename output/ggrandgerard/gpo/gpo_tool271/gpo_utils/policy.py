# -*- coding: utf-8 -*-

from ConfigParser import ConfigParser
from StringIO import StringIO
from os import path, makedirs
import ntpath
import samba.getopt as options
from samba import smb
from samba.net import Net
from samba.ndr import ndr_unpack
from samba.dcerpc import nbt, security
from samba.ntacls import dsacl2fsacl
from samba.netcmd.gpo import samdb_connect, dc_url, parse_unc, get_gpo_info
import ldb
from samba.netcmd import (
    Command,
    CommandError,
    Option,
    SuperCommand,
)

from gpo_utils.registration import PolicySet, PolicyDescription
from gpo_utils.policy_types import GPO_POLICY_TYPES

GPO_REGISTRATION_PERSISTENCE = '/etc/samba/gpo_policies.pickle'

REGISTERED_POLICIES = PolicySet()
if path.isfile(GPO_REGISTRATION_PERSISTENCE):
    REGISTERED_POLICIES.load_policies(GPO_REGISTRATION_PERSISTENCE)


def savecontent(remote_path, content, conn=None):
    """Create file with content through SMB connection or locally.
    :param remote_path: location of file to create, either in unc format if
                        conn is provided, or as absolute path.
    :type remote_path: str
    :param content: content of file
    :type content: str
    :param conn: connection to server through SMB
    :type conn: smb.SMB
    """
    if conn is None:
        if not path.isdir(path.dirname(remote_path)):
            makedirs(path.dirname(remote_path))
        with open(remote_path, 'wb') as pol_file:
            pol_file.write(content)
    else:
        create_directory_hier(conn, ntpath.dirname(remote_path))
        conn.savefile(remote_path, content)


def update_gpt_version(gpt_path, version, conn=None):
    """Save new version value to GPT.
    :param gpt_path: location of GPO in GPT
    :type gpt_path: str
    :param version: version number
    :type version: str
    :param conn: connection to server through SMB
    :type conn: smb.SMB
    """
    gpt_ini_path = gpt_path + '\\GPT.INI'
    gpt_ini_content = conn.loadfile(gpt_ini_path)
    cp = ConfigParser()
    cp.readfp(StringIO(gpt_ini_content))
    cp.set('General', 'Version', version)
    cp_content = StringIO()
    cp.write(cp_content)
    cp_content.seek(0)
    savecontent(gpt_ini_path, cp_content.read(), conn=conn)


def update_gpc_version(gpo_dn, version, samdb):
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


def gpc_update_extension(gpo_dn, gpc_entry, cse_info, samdb):
    """Update GPC with cse information from added policy.
    :param gpo_dn: Group Policy Object dn
    :type gpo_dn: str
    :param cse_info: information needed to declare extension in GPC
    :type cse_info: tuple -> ( str , str list )
    :param samdb: ldb connection
    :type samdb: SamDB
    """
    if isinstance(cse_info[1], list):
        cse_guid_list = cse_info[1]
    elif isinstance(cse_info[1], str):
        cse_guid_list = [cse_info[1]]
    else:
        raise
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


def create_directory_hier(conn, remotedir):
    """Create directory through SMB connection (copied from samba.netcmd.gpo).
    :param conn: connection to server with SMB protocol
    :type conn: smb.SMB
    :param remotedir: folder to create remotely
    :type remotedir: str
    """
    elems = remotedir.replace('/', '\\').split('\\')
    path = ""
    for e in elems:
        path = path + '\\' + e
        if not conn.chkpath(path):
            conn.mkdir(path)


def set_ownership_and_mode(file_path, gpo, conn, samdb):
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
    ds_sd_flags = (security.SECINFO_OWNER | 
                    security.SECINFO_GROUP | 
                    security.SECINFO_DACL)
    msg = get_gpo_info(samdb, gpo=gpo, sd_flags=ds_sd_flags)[0]
    ds_sd_ndr = msg['nTSecurityDescriptor'][0]
    ds_sd = ndr_unpack(security.descriptor, ds_sd_ndr).as_sddl()
    # Create a file system security descriptor
    domain_sid = security.dom_sid(samdb.get_domain_sid())
    sddl = dsacl2fsacl(ds_sd, domain_sid)
    fs_sd = security.descriptor.from_sddl(sddl, domain_sid)

    # Set ACL
    sio = (security.SECINFO_OWNER | 
            security.SECINFO_GROUP | 
            security.SECINFO_DACL | 
            security.SECINFO_PROTECTED_DACL)
    conn.set_acl(file_path, fs_sd, sio)


class GPOVersion(object):
    """GPO Version class with addition and display functions
    """

    def __init__(self, machine=0, user=0):
        self.user_factor = 65536
        self.machine_edits = machine
        self.user_edits = user
        self.update_version()

    def value(self):
        """Return int value as str.
        """
        return str(self.version)

    def add(self, ctx, value=1):
        """Add value for given context and compute new value of version.
        :param ctx: context the value is applying to
        :type ctx: str in ['Machine', 'User']
        :param value: number of edits to add to current version
        :type value: int (1 by default)
        """
        if ctx == 'Machine':
            self.machine_edits += value
        elif ctx == 'User':
            self.user_edits += value

        self.update_version()

    def extract(self, value):
        """Extract number of edits for machine and user contexts from given value.
        :param value: synthetic version number
        :type value: int
        """
        self.user_edits = value / self.user_factor
        self.machine_edits = value % self.user_factor
        self.update_version()

    def update_version(self):
        self.version = self.machine_edits + self.user_factor * self.user_edits

    def __repr__(self):
        return "Version Number: {} ({} machine edits and {} user edits)".format(self.version, self.machine_edits, self.user_edits)


class cmd_add(Command):
    """Add policy to Group Policy Object"""

    synopsis = "%prog GPO policy"

    takes_optiongroups = {
        "sambaopts": options.SambaOptions,
        "versionopts": options.VersionOptions,
        "credopts": options.CredentialsOptions,
    }

    takes_args = ['GPO', 'policy']

    takes_options = [
        Option("-H", "--URL", help="LDB URL for database or target server", type=str,
               metavar="URL", dest="H"),
        Option("-v", "--variable", help="Rule to add to Registry.pol in CSV form",
               type=str, action='append', dest='variables',
               metavar="<variable>:<value>"),
    ]

    def run(self, GPO, policy, H=None, sambaopts=None, credopts=None, versionopts=None, overwrite=False, variables=None):
        """Add policy to Group Policy Object
        """
        variables = [] if variables is None else variables
        policy_description = REGISTERED_POLICIES.get_policy_by_name(policy)
        if policy_description is None:
            raise Exception('Unregistered policy')

        policy = GPO_POLICY_TYPES.get(policy_description.pol_type, None)
        if policy is None:
            raise Exception('Unsupported policy type')

        policy = policy(policy_description, variables)

        # Open connection SamDB and SMB
        self.lp = sambaopts.get_loadparm()
        self.creds = credopts.get_credentials(self.lp, fallback_machine=True)

        self.url = dc_url(self.lp, self.creds, H)

        samdb_connect(self)

        policies_dn = self.samdb.get_default_basedn()
        policies_dn.add_child(ldb.Dn(self.samdb, "CN=Policies,CN=System"))

        base_dn = policies_dn
        search_expr = "(objectClass=groupPolicyContainer)"
        search_scope = ldb.SCOPE_ONELEVEL

        search_expr = "(&(objectClass=groupPolicyContainer)(displayname=%s))" % ldb.binary_encode(GPO)

        # find groupPolicyContainer for given display name
        try:
            gpc_entry = self.samdb.search(base=base_dn, scope=search_scope,
                                          expression=search_expr,
                                          attrs=['versionNumber',
                                                 'name',
                                                 'gPCMachineExtensionNames',
                                                 'gPCUserExtensionNames'])[0]
        except Exception:
            raise CommandError("Container '%s' does not exist" % GPO)

        # We need to know writable DC to setup SMB connection
        net = Net(creds=self.creds, lp=self.lp)
        if H and H.startswith('ldap://'):
            dc_hostname = H[7:]
            self.url = H
            flags = (nbt.NBT_SERVER_LDAP | 
                     nbt.NBT_SERVER_DS | 
                     nbt.NBT_SERVER_WRITABLE)
            cldap_ret = net.finddc(address=dc_hostname, flags=flags)
        else:
            flags = (nbt.NBT_SERVER_LDAP | 
                     nbt.NBT_SERVER_DS | 
                     nbt.NBT_SERVER_WRITABLE)
            cldap_ret = net.finddc(domain=self.lp.get('realm'), flags=flags)
            dc_hostname = cldap_ret.pdc_dns_name
            self.url = dc_url(self.lp, self.creds, dc=dc_hostname)
        gpo_id = gpc_entry['name']
        realm = cldap_ret.dns_domain
        unc_path = "\\\\%s\\sysvol\\%s\\Policies\\%s" % (realm, realm, gpo_id)

        gpo_version = GPOVersion()
        gpo_version.extract(int(str(gpc_entry['versionNumber'])))

        gpo_dn = gpc_entry['dn']

        # Connect to DC over SMB
        [dom_name, service, sharepath] = parse_unc(unc_path)
        try:
            conn = smb.SMB(dc_hostname, service, lp=self.lp, creds=self.creds)
        except Exception, e:
            raise CommandError("Error connecting to '%s' using SMB" % dc_hostname, e)

        self.samdb.transaction_start()

        try:
            # load content if file exists
            smb_path = ntpath.join(sharepath, policy.get_smb_path())
            local_sharepath = path.join('/home/sysvol', sharepath.replace('\\', '/'))
            local_path = path.join(local_sharepath, policy.get_unix_path())
            try:
                current_content = conn.loadfile(smb_path)
                policy.load(current_content)
            except:
                pass
            # write file
            try:
                savecontent(smb_path, policy.render(), conn=conn)
            except TypeError:
                savecontent(local_path, policy.render())
            # modify gPC*Extension field for GPO
            gpc_update_extension(gpo_dn, gpc_entry, policy.get_gpc_extension(), self.samdb)

            gpo_version.add(policy.policy.context)
            # modify version in GPT
            update_gpt_version(sharepath, gpo_version.value(), conn=conn)

            # modify version for groupPolicyContainer
            update_gpc_version(gpo_dn, gpo_version.value(), self.samdb)

            # fix ownership
            set_ownership_and_mode(smb_path, gpo=str(gpo_id), conn=conn, samdb=self.samdb)

        except Exception:
            self.samdb.transaction_cancel()
            raise
        else:
            self.samdb.transaction_commit()


class cmd_list(Command):
    """List registered policies"""

    synopsis = "%prog [options]"

    def run(self):
        for pol in REGISTERED_POLICIES.get_policies_detail():
            print "Policy: '{}'\n\t- destination: {}\n\t- variables: {}\n".format(pol[0], pol[1], ', '.join(pol[2]))


class cmd_inspect(Command):
    """Display information on policy"""

    synopsis = "%prog [options]"

    takes_args = ['policy']

    def run(self, policy):
        pol = REGISTERED_POLICIES.get_policy_by_name(policy)
        if pol is None:
            raise Exception('Unknown policy')
        print "Policy: '{}'\n\t- destination: {}\n\t- variables: {}\n".format(pol.name, pol.get_unix_path(), ', '.join(pol.get_variables()))


class cmd_register(Command):
    """Add policy definition to known policies"""

    synopsis = "%prog [options]"

    takes_args = ['pol_path', 'cse', 'pol_type', 'GPT_path', 'template']
    takes_options = [
        Option("-u", "--update", help="Update policy if already exists, create it otherwise", action="store_true",
               dest="update")
        ]

    def run(self, pol_path, cse, pol_type, GPT_path, template, update=False):
        template = template.replace('\\n', '\n')
        policy = PolicyDescription(pol_path, cse, pol_type, GPT_path, template)
        REGISTERED_POLICIES.add_policy(policy, update=update)
        REGISTERED_POLICIES.save_policies(GPO_REGISTRATION_PERSISTENCE)
        pass


class cmd_policy(SuperCommand):
    """Group Policy Object (GPO) management."""

    subcommands = {}
    subcommands["add"] = cmd_add()
    subcommands["list"] = cmd_list()
    subcommands["inspect"] = cmd_inspect()
    subcommands["register"] = cmd_register()
