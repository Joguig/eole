"""Supported GPO settings
"""
from os import path
import string
import ntpath
import pickle
from gpo_utils.policy_types import get_supported_policy_types


class PolicyDescription(object):
    """Policy Description implementing methods to display implicit informations
    """
    def __init__(self, name, cse_guid, pol_type, GPT_path, template):
        """
        :param name: policy name (must be unique in a set of policies),
                     i.e. path as found in graphical interface in GPO Editor
        :type name: unicode
        :param cse_guid: CSE GUID
        :type cse_guid: str
        :param pol_type: one of GptTmpl.inf, Registry.pol (more to come)
        :type pol_type: str
        :param context: one of Machine, User
        :type context: str
        :param GPT_path: path in GPT folder relative to GPO subfolder
                         (starting with Machine or User)
        :type GPT_path: str
        :param template: string with named placeholder for variables
        :type template: str
        """
        self.name = name
        self.cse_guid = cse_guid
        self.pol_type = self.valid_pol_type(pol_type)
        self.context, self.GPT_path = self.valid_GPT_path(GPT_path)
        self.template = template

    def valid_pol_type(self, pol_type):
        """Raise exception if pol_type not in supported types, else return unchanged
        """
        if pol_type not in get_supported_policy_types():
            raise Exception('Unsupported policy type')
        return pol_type

    def valid_GPT_path(self, GPT_path):
        """Raise if GPT_path does not start with Machine or User, return tuple
        (context, path relative to context)
        """
        try:
            if GPT_path in ('Machine', 'User'):
                context = GPT_path
                GPT_path = ''
            else:
                context, GPT_path = GPT_path.split('/', 1)
            if context not in ('Machine', 'User'):
                raise Exception('GPT_path must starts with Machine/ or User/')
        except ValueError:
            raise Exception('GPT_path must starts with Machine/ or User/')

        return (context, GPT_path)

    def get_context(self):
        return self.context

    def get_unix_path(self):
        unix_path = path.normpath(path.join(self.context, self.GPT_path))
        return unix_path

    def get_smb_path(self):
        smb_path = ntpath.normpath(ntpath.join(self.context,
                                               self.GPT_path.replace('/', '\\')))
        return smb_path

    def get_variables(self):
        variables = []
        for fp in string.Formatter().parse(self.template):
            variable = fp[1]
            if variable is not None and variable not in variables:
                variables.append(variable)
        return variables

    def get_template(self):
        return self.template

    def export_description(self):
        return {self.name: {'type': self.pol_type,
                            'GPT_path': self.get_unix_path(),
                            'template': self.template}}

    def get_gpc_extension(self):
        return (self.context, self.cse_guid)


class PolicySet(object):
    """Policy set with method to assert uniqueness of name
    """
    policies = {}

    def add_policy(self, policy, update=False):
        """Add policy description to policy set
        :param policy: policy description
        :type policy: PolicyDescription
        """
        if policy.name in self.get_policies_name() and not update:
            raise Exception('Policy already in set')
        self.policies.update({policy.name: policy})

    def get_policies_name(self):
        """Get iterator on policy names in set
        """
        return (pol.name for pol in self.policies.values())

    def get_policies_detail(self):
        """Format details on policies in set
        """
        return ((pol.name, pol.get_unix_path(), pol.get_variables(), pol.get_template())
                for pol in self.policies.values())

    def get_policy_by_name(self, policy):
        """Return PolicyDescription given policy name.
        """
        return self.policies.get(policy, None)

    def load_policies(self, fp):
        """Load policies from persistent storage
        :param fp: persistent storage path
        :type fp: str
        """
        with open(fp, 'rb') as fp_stream:
            self.policies = pickle.load(fp_stream)

    def save_policies(self, fp):
        """Save policies to persistent storage
        :param fp: persistent storage path
        :type fp: str
        """
        with open(fp, 'wb') as fp_stream:
            pickle.dump(self.policies, fp_stream)
