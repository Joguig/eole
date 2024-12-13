
# general
import ntpath
from os import path

# samba
import samba.getopt as options

#EOLE import de Samba 4.11
from samba.netcmd.gpo import (
    Option,
    SuperCommand,
)

#EOLE
from gpo_utils.gpo_eole import (
    EoleGPOCommand
)
from gpo_utils.policy_types import GPO_POLICY_TYPES
from gpo_utils.registration import (
    PolicySet,
    PolicyDescription
)


GPO_REGISTRATION_PERSISTENCE = '/etc/samba/gpo_policies.pickle'

REGISTERED_POLICIES = PolicySet()
if path.isfile(GPO_REGISTRATION_PERSISTENCE):
    REGISTERED_POLICIES.load_policies(GPO_REGISTRATION_PERSISTENCE)

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
        self.user_edits = int(value / self.user_factor)
        self.machine_edits = value % self.user_factor
        self.update_version()

    def update_version(self):
        self.version = self.machine_edits + self.user_factor * self.user_edits

    def __repr__(self):
        return "Version Number: {} ({} machine edits and {} user edits)".format(self.version, self.machine_edits, self.user_edits)

class cmd_add(EoleGPOCommand):
    """Add policy to Group Policy Object exist """
    
    # La GPO doit exister !
    
    synopsis = "%prog <GPO> <policy> [options]"

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

    def runInTransaction(self):
        # load content if file exists
        smb_path = ntpath.join(self.sharepath, self.policy.get_smb_path())
        try:
            current_content = self.conn.loadfile(smb_path)
            self.policy.load(current_content)
        except:
            # ignore si le fichier n'existe pas, on va le créer !
            pass

        # on travaille seulement sur le DC SYSVOL_REF ! donc en local
        self.savecontent(smb_path, self.policy.render())
        gpoversion = GPOVersion()
        gpoversion.extract(int(str(self.gpc_entry['versionNumber'])))
        gpoversion.add(self.policy.policy.context)

        # modify version in GPT
        self.update_gpt_version(self.sharepath, gpoversion.value(), conn=self.conn)

        # modify version for groupPolicyContainer
        self.update_gpc_version(self.gpo_dn, gpoversion.value(), self.samdb)
        
        # modify gPC*Extension field for GPO
        self.gpc_update_extension(self.gpo_dn, self.gpc_entry, self.policy.get_gpc_extension(), self.samdb)
        
        # fix ownership
        self.set_ownership_and_mode(smb_path, gpo=str(self.gpo_id), conn=self.conn, samdb=self.samdb)        

    def run(self, GPO, policy, H=None, sambaopts=None, credopts=None, versionopts=None, overwrite=False, variables=None):
        variables = [] if variables is None else variables
        policy_description = REGISTERED_POLICIES.get_policy_by_name(policy)
        if policy_description is None:
            raise Exception('Unregistered policy')

        policy = GPO_POLICY_TYPES.get(policy_description.pol_type, None)
        if policy is None:
            raise Exception('Unsupported policy type')

        self.policy = policy(policy_description, variables)
        self.tmpdir = None
        self.overwrite = overwrite
        return self.connectAndRunInTransaction( GPO, H, sambaopts, credopts, versionopts )


class cmd_list(EoleGPOCommand):
    """List registered policies"""

    synopsis = "%prog [options]"

    takes_options = [
            Option("--detail", help="Display detail on each policy", action="store_true", dest="detail")
            ]
    def run(self, detail=False):
        if detail:
            display_str = "Policy: '{name}'\n\t- destination: {destination}\n\t- variables: {variables}\n\t- template:\n------BEGIN OF TEMPLATE------\n{template}\n------END OF TEMPLATE------\n"
        else:
            display_str = "{num}: {name}\n"
        for num, pol in enumerate(REGISTERED_POLICIES.get_policies_detail()):
            print(display_str.format(num=num+1, name=pol[0], destination=pol[1], variables=', '.join(pol[2]), template=pol[3]))


class cmd_inspect(EoleGPOCommand):
    """Display information on policy"""

    synopsis = "%prog <policy> [options]"

    takes_args = ['policy']

    def run(self, policy):
        pol = REGISTERED_POLICIES.get_policy_by_name(policy)
        if pol is None:
            raise Exception('Unknown policy')
        print("Policy: '{}'\n\t- destination: {}\n\t- variables: {}\n".format(pol.name, pol.get_unix_path(), ', '.join(pol.get_variables())))

class cmd_register(EoleGPOCommand):
    """Add policy definition to known policies"""

    synopsis = "%prog <pol_path> <cse> <pol_type> <GPT_path> <template> [options]"

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
    """ Policy management."""

    subcommands = {}
    subcommands["add"] = cmd_add()
    subcommands["list"] = cmd_list()
    subcommands["inspect"] = cmd_inspect()
    subcommands["register"] = cmd_register()
