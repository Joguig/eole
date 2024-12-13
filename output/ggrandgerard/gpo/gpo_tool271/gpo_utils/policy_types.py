# -*- coding: utf-8 -*-

from os import path
import re
import ntpath
from ConfigParser import ConfigParser
from StringIO import StringIO
from struct import pack, unpack, calcsize
from collections import OrderedDict

# http://msdn.microsoft.com/en-us/library/windows/desktop/aa374407%28v=vs.85%29.aspx
REGFILE_SIGNATURE = 0x67655250
REGFILE_VERSION = 0x00000001

# http://source.winehq.org/source/include/winnt.h
REG_NONE = 0x0
REG_SZ = 0x1
REG_EXPAND_SZ = 0x2
REG_BINARY = 0x3
REG_DWORD = 0x4
REG_DWORD_LITTLE_ENDIAN = 0x4
REG_DWORD_BIG_ENDIAN = 0x5
REG_LINK = 0x6
REG_MULTI_SZ = 0x7
REG_QWORD = 0x11
REG_QWORD_LITTLE_ENDIAN = 0X11

O_BRACKET = pack('H', ord('['))
C_BRACKET = pack('H', ord(']'))
SEPARATOR = pack('H', ord(';'))


def identity(value):
    return value


def to_int(value):
    return int(value)


REG_TYPES = {
    'REG_NONE': {'code': 0x0, 'format': None},
    'REG_SZ': {'code': 0x1, 'format': 'c'},
    'REG_EXPAND_SZ': {'code': 0x2, 'format': None},
    'REG_BINARY': {'code': 0x3, 'format': None},
    'REG_DWORD': {'code': 0x4, 'format': 'I', 'converter': to_int},
    'REG_DWORD_LITTLE_ENDIAN': {'code': 0x4, 'format': 'I', 'converter': to_int},
    'REG_DWORD_BIG_ENDIAN': {'code': 0x5, 'format': '>I', 'converter': to_int},
    'REG_LINK': {'code': 0x6, 'format': None},
    'REG_MULTI_SZ': {'code': 0x7, 'format': None},
    'REG_QWORD': {'code': 0x11, 'format': 'L', 'converter': to_int},
    'REG_QWORD_LITTLE_ENDIAN': {'code': 0X11, 'format': 'L', 'converter': to_int},
}

INV_REG_TYPES = {REG_TYPES[reg_type]['code']: reg_type  for reg_type in REG_TYPES}


def pack_string(string, empty_end=True):
    string = '{}{}'.format(string, '\0' if empty_end else '')
    return (pack('H', ord(i)) for i in string)


def pack_dword(value):
    return pack('I', value)


def pack_key(key):
    return ''.join(pack_string(key))


def pack_value(value):
    return ''.join(pack_string(value))


def pack_type(data_type):
    return pack_dword(data_type)


def pack_size(size):
    return pack_dword(size)


def pack_data(data_type, size, data):
    data_format = REG_TYPES[data_type]['format']
    conv_function = REG_TYPES[data_type].get('converter', identity)
    if REG_TYPES[data_type].get('fixed_size', True) is False:
        data_format = data_format.format(size)
    return pack(data_format, conv_function(data))


def pack_policy(key, value, data_type, size, data):
    if not data_type in REG_TYPES:
        raise Exception('Not a valid data type: {}'.format(data_type))
    else:
        data_type_code = REG_TYPES[data_type]['code']
    try:
        size = int(size)
    except:
        size = calcsize(REG_TYPES.get(size, {}).get('format', '0'))
        size = int(size)

    policy = SEPARATOR.join((pack_key(key),
                             pack_value(value),
                             pack_type(data_type_code),
                             pack_size(size),
                             pack_data(data_type, size, data)
                            ))
    packed_policy = '{}{}{}'.format(O_BRACKET, policy, C_BRACKET)
    return packed_policy


def header_unpack(policy):
    header = policy[:8]
    header = [hex(i) for i in unpack('II', header)]
    if header[0] != '0x67655250':
        raise Exception('Bad format detected')
    return header


def body_unpack(policy, with_value=True):

    def decode_ascii_element(el):
        element = []

        for i in range(len(el)):
            p = el[i * 2:i * 2 + 2]
            up = unpack('H', p)
            if up[0] == 0:
                break
            element.append(chr(up[0]))

        return ''.join(element)

    def decode_type_element(el):
        el = unpack('I', el)[0]
        return INV_REG_TYPES[el]

    def decode_size_element(el):
        return unpack('I', el)[0]

    def decode_data_element(el, el_type):
        el_type = REG_TYPES[decode_type_element(el_type)]['format']
        if el_type == 'c':
            return decode_ascii_element(el)
        if el_type is not None:
            return unpack('{}'.format(el_type), el)[0]

    policy_body = policy[8:]
    if len(policy) > 0:
        registry_policies = [regpol.split(SEPARATOR)
                             for regpol in re.findall(r'{}(.*?){}'.format(O_BRACKET.replace('[', '\\['), C_BRACKET.replace(']', '\\]')), policy_body)]
        for regpol in registry_policies:
            registry_policies = [decode_ascii_element(regpol[0]),
                                 decode_ascii_element(regpol[1])]
            if with_value:
                registry_policies.extend([decode_type_element(regpol[2]),
                                          decode_size_element(regpol[3]),
                                          decode_data_element(regpol[4], regpol[2])])
            else:
                value = O_BRACKET + SEPARATOR.join(regpol) + C_BRACKET
                registry_policies.append(value)
            yield registry_policies


class PolicyRenderer(object):
    """Class implementing common method for accessing policy attributes
    """
    filename = ''

    def __init__(self, policy, variables):
        if policy:
            self.policy = policy
            self.variables = self.extract_variables(variables)

    def extract_variables(self, variables):
        variables = {v.split(':')[0]: v.split(':')[1] for v in variables}
        if set(self.policy.get_variables()) != set(variables.keys()):
            raise Exception('Unsuitable variables')
        return variables

    def render(self):
        raise NotImplemented('Subclass must implement render method')

    def load(self, registry_pol):
        raise NotImplemented('Subclass must implement load method')

    def get_smb_path(self):
        smb_path = ntpath.join(self.policy.get_smb_path(), self.filename)
        return smb_path

    def get_unix_path(self):
        return path.join(self.policy.get_unix_path(), self.filename)

    def get_gpc_extension(self):
        return self.policy.get_gpc_extension()


class RegistryPolicy(PolicyRenderer):
    """Class implementing method for writing Registry.pol files
    """

    def __init__(self, policy=None, variables=None):
        PolicyRenderer.__init__(self, policy, variables)
        self.filename = 'Registry.pol'
        self.rules = OrderedDict()
        if policy:
            self.rule = self.process_rule()
        else:
            self.rule = None

    def process_rule(self):
        key, value, data_type, size, data = self.policy.template.format(**self.variables).split(';')
        packed_policy = pack_policy(key, value, data_type, size, data)
        return {(key, value): packed_policy}

    def render(self):
        header = pack('II', REGFILE_SIGNATURE, REGFILE_VERSION)
        body = self.rules.copy()
        if self.rule:
            body.update(self.rule)
        policies = body.values()
        regcontent = [header] + policies
        return ''.join(regcontent)

    def load(self, registry_pol):
        body = body_unpack(registry_pol, with_value=False)
        for pol in body:
            self.rules.update({(pol[0], pol[1]): pol[2]})

    def read(self, registry_pol):
        return body_unpack(registry_pol, with_value=True)


class RegistryXML(PolicyRenderer):
    pass


class GptTmpl(PolicyRenderer):
    """Class implementing method for writing GptTmpl.inf files
    """

    def __init__(self, policy, variables):
        PolicyRenderer.__init__(self, policy, variables)
        self.filename = 'GptTmpl.inf'
        self.rules = ConfigParser()
        self.rules.optionxform = str
        self.rule = self.process_rule()

    def header(self):
        return '[Unicode]\nunicode = yes\n[Version]\nsignature="$CHICAGO$"\nRevision=1\n'

    def process_rule(self):
        cp = ConfigParser()
        cp.optionxform = str
        rule = self.policy.template.format(**self.variables)
        header = StringIO(self.header())
        body = StringIO(rule)
        cp.readfp(header)
        cp.readfp(body)
        return cp

    def load(self, GptTmpl):
        self.rules.readfp(StringIO(GptTmpl))

    def render(self):
        with open('/tmp/rule', 'w') as rule:
            self.rule.write(rule)
        with open('/tmp/rules', 'w') as rules:
            self.rules.write(rules)
        for section in self.rule.sections():
            if not self.rules.has_section(section):
                self.rules.add_section(section)
            for option in self.rule.options(section):
                value = self.rule.get(section, option)
                self.rules.set(section, option, value)
        rules = StringIO()
        self.rules.write(rules)
        rules.seek(0)
        return rules.read()


GPO_POLICY_TYPES = {
    'GptTmpl.inf': GptTmpl,
    'Registry.pol': RegistryPolicy,
}


def  get_supported_policy_types():
    return GPO_POLICY_TYPES.keys()
