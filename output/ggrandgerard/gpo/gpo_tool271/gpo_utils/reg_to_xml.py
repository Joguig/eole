#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import re
import io
import uuid
from time import strftime
from glob import glob
from os import unlink
from os.path import exists, join
from configparser import ConfigParser
from lxml.etree import Element, SubElement, tostring


def read_reg(filename, encoding='utf-16'):
    """
    Returns array of regkey informations from a regfile
    Ret : [[key_path, key_name, key_type, key_value], [......]]
    """
    with io.open(filename, encoding=encoding) as f:
        data = f.read()
    # get rid of non-section strings in the beginning of .reg file
    data = re.sub(r'^[^\[]*\n', '', data, flags=re.S)
    cfg = ConfigParser(strict=False)
    # dirty hack for "disabling" case-insensitive keys in "configparser"
    cfg.optionxform = str
    cfg.read_string(data)
    data = []
    # iterate over sections and keys and generate `data`
    for s in cfg.sections():
        if not cfg[s]:
            data.append([s, None, None, None])
        for key in cfg[s]:
            tp = val = None
            if cfg[s][key]:
                # take care of value type
                if ':' in cfg[s][key]:
                    tp, val = cfg[s][key].split(':')
                else:
                    val = cfg[s][key].replace('"', '').replace(r'\\\n', '')
            data.append([s, key.replace('"', ''), tp, val])
    return data


def hex_to_str(hex_val):
    """
    Returns array of string from regfile hex values
    * hex_val example : "aa, 00, 30, 00, 00, 31, 00, 00, 00"
    """
    ret = []
    hex_values = re.split(",00,00,00,*", hex_val.replace("\\\n", ""))
    try:
        hex_values.remove('00,00')
    except:
        hex_values.remove('')
    for hex_value in hex_values:
        key_value = ""
        for hex_char in hex_value.replace(",00", "").split(','):
            key_value += str(chr(int("0x" + hex_char, 16)))
        ret.append(key_value)
    return ret


def gen_RegXML(data):
    """
    Returns RegXml from array of regkey informations
    """

    if data == []:
        return ""

    Reg_key_type = {"dword":"REG_DWORD",
                    "hex":"REG_BINARY",
                    "hex(7)":"REG_MULTI_SZ",
                    "hex(2)":"REG_EXPAND_SZ",
                    "hex(b)":"REG_QWORD"
                   }
    RegistrySettings_clsid = "{A3CCFC41-DFDB-43a5-8D26-0FE8B954DA51}"
    RegistryElement_clsid = "{9CD4B2F4-923D-47f5-A062-E897DD1DAD50}"
    root_element = Element("RegistrySettings")
    root_element.set("clsid", RegistrySettings_clsid)
    key_change = strftime("%Y-%m-%d %H:%M:%S")
    for reg_entry in data:
        key_name = reg_entry[1]
        if key_name is None:
            continue
        guid = str(uuid.uuid4())
        uid = "{%s}" % guid.upper()
        keypath = reg_entry[0].split('\\')
        key_hive = keypath[0]
        key_location = "\\".join(keypath[1:])
        multi_val = []
        if reg_entry[2] is not None:
            key_type = Reg_key_type[reg_entry[2]]
        else:
            key_type = "REG_SZ"
        if key_type == "REG_BINARY":
            key_image = "17"
            key_value = reg_entry[3].replace(",", "").upper()
        elif key_type == "REG_SZ":
            key_image = "7"
            key_value = reg_entry[3]
        elif key_type == "REG_MULTI_SZ":
            key_image = "7"
            multi_val = hex_to_str(reg_entry[3])
            key_value = " ".join(multi_val)
        elif key_type == "REG_EXPAND_SZ":
            key_image = "7"
            key_value = hex_to_str(reg_entry[3])[0]
        elif key_type == "REG_QWORD":
            key_image = "12"
            key_value = reg_entry[3].replace(",", "").upper()
        else:
            key_image = "12"
            key_value = reg_entry[3]
        RegistryElement = SubElement(root_element, "Registry")
        RegistryElement.set("clsid", RegistryElement_clsid)
        RegistryElement.set("name", key_name)
        RegistryElement.set("status", key_name)
        RegistryElement.set("image", key_image)
        RegistryElement.set("change", key_change)
        RegistryElement.set("uid", uid)
        PropertiesElement = SubElement(RegistryElement, "Properties")
        PropertiesElement.set("action", "U")
        PropertiesElement.set("displayDecimal", "1")
        PropertiesElement.set("default", "0")
        PropertiesElement.set("hive", key_hive)
        PropertiesElement.set("key", key_location)
        PropertiesElement.set("name", key_name)
        PropertiesElement.set("type", key_type)
        PropertiesElement.set("value", key_value)
        if multi_val != []:
            PropertiesElement.set("value", " ".join(multi_val))
            ValuesElement = SubElement(PropertiesElement, "Values")
            for value in multi_val:
                ValueElement = SubElement(ValuesElement, "Value")
                ValueElement.text = value

    return tostring(root_element, encoding="UTF-8", xml_declaration=True)


def regToRegistryXml(reg_path, regxml_path):
    """
    Convert exported registry files to Registry.xml into @reg_files_path@
    * reg_path : path containing reg files to convert to Registry.xml
    """
    data = []
    for regfile in glob(join(reg_path, '*.reg')):
        data += read_reg(regfile)
    RegistryXML = gen_RegXML(data)
    regxml_filepath = join(regxml_path, "Registry.xml")
    if RegistryXML == "":
        if exists(regxml_filepath):
            unlink(regxml_filepath)
    else:
        with open(regxml_filepath, "wb") as reg:
            reg.write(RegistryXML)


def regToXml(reg_path):
    regToRegistryXml(reg_path, reg_path)


if __name__ == "__main__": 
    # Convert Machine registry files to usr/share/eole/gpo/reg/Machine/Registry.xml
    regToXml('/usr/share/eole/gpo/reg/Machine')
    # Convert User registry files to usr/share/eole/gpo/reg/User/Registry.xml
    regToXml('/usr/share/eole/gpo/reg/User')
