#!/usr/bin/env python3
# -*- coding: utf-8 -*-
""" Deploy VMs with Zephir help """

import getpass
import socket
import base64
import json
import subprocess
import tempfile
import time
import xml.etree.ElementTree as XML
import sys
import os
import shutil
import re
import datetime
import traceback
import termios
import hashlib
from cryptography.fernet import Fernet
#from zephir.lib_zephir import *
from creole.client import CreoleClient

client = CreoleClient()
if client.get_creole('activer_deploiement_automatique') == 'non':
    print("Déploiement automatique désactivé.")
    sys.exit()
from pyeole.ihm import print_line
from pyeole.ansiprint import print_red
try:
    from zephir.zephir_conf.zephir_conf import adresse_zephir
except:
    print_red("Le serveur n'est pas enregistrer sur un serveur Zéphir")
    sys.exit()
from zephir.lib_zephir import convert, xmlrpclib, EoleProxy, TransportEole, flushed_input

VARIABLE_NAME = 'activer_modele_vm'
VARIABLE_VALUE = 'oui'
RNE = client.get_creole('zephir_numero_etab', None)
DPL_ROOT_DIR = '/usr/share/eole/hapy-deploy'
KEY_FILE = os.path.join(DPL_ROOT_DIR, ".dpl.sc")
CRD_FILE = os.path.join(DPL_ROOT_DIR, ".zephir.sc")
MODE = client.get_creole('dp_mode')
STATUS_FILE = os.path.join(DPL_ROOT_DIR, ".hapy-deploy.status")
IMG_DS = client.get_creole('one_ds_image_name')
PROV_DIR = os.path.join(DPL_ROOT_DIR, "scripts")
ZCREDS_NAME = "zcreds.sc"
ZCA_NAME = "zephir-ca.crt"
TMOUT = 360
DEBUG = os.getenv("VM_DEBUG", "0")
throwDeployExceptionCalled = False

socket.setdefaulttimeout(TMOUT)

def printMessage(typemessage, message):
    """
    print message
    """

    for ligne in message.split("\n"):
        print(typemessage + ":" + ligne)

def printDebug(message):
    """
    print debug
    """

    if DEBUG > "1":
        printMessage("DEBUG", message)

def printInfo(message):
    """
    print info
    """

    if DEBUG > "0":
        printMessage("INFO", message)

def silent_run(command):
    """
    call system commande wihtout output
    """

    completProcess = subprocess.run(command.split(), capture_output=True)
    if DEBUG > "1":
        printDebug("command: " + command)
        printDebug("   returnCode: " +str(completProcess.returncode))
        printDebug("   stdout: " + completProcess.stdout.decode().rstrip())
        printDebug("   stderr: " + completProcess.stderr.decode().rstrip())
    return completProcess

def statusLog(context, message):
    """
    write status in log file
    """

    fd = None
    if os.path.exists(STATUS_FILE):
        fd = open(STATUS_FILE, "a")
    else:
        fd = open(STATUS_FILE, "w")
    fd.write(context)
    fd.write(":")
    fd.write(message)
    fd.write("\n")
    fd.close()
    if DEBUG > "0":
        printDebug(context + ":" + message)

def printStatusAndWriteLog(context, status, message):
    """
    print status and write log
    """

    sys.stdout.write("\t" + status + "\n")
    sys.stdout.flush()
    statusLog(context, message)

def logError(context, completProcess, message):
    """
    log error
    """

    global throwDeployExceptionCalled
    throwDeployExceptionCalled = True
    if completProcess is None:
        message = message.rstrip() + ":ERROR:"
    else:
        if completProcess.returncode != 0:
            message = message.rstrip() + ":ERROR:exit=" +str(completProcess.returncode)+ ",stdout=" + completProcess.stdout.decode().rstrip() + ",stderr=" + completProcess.stderr.decode().rstrip()
        else:
            message = message.rstrip() + ":ERROR"
    statusLog(context, message)
    print_red(message)

def throwDeployException(context, completProcess, message):
    """
    log error dans throw exception
    """

    logError(context, completProcess, message)
    sys.stdout.flush()
    raise Exception(message)

def printStatusAndThrowDeployException(context, status, completProcess, message):
    """
    print on console and throw error
    """

    sys.stdout.write("\t")
    sys.stdout.write(status)
    sys.stdout.write("\n")
    sys.stdout.flush()
    throwDeployException(context, completProcess, message)

def crypt(message):
    """Chiffrer une chaine de caractères"""

    key = None
    if not os.path.exists(KEY_FILE):
        key = Fernet.generate_key()
        ckf = open(KEY_FILE, "w")
        ckf.write(key.decode())
        ckf.close()
    else:
        ckf = open(KEY_FILE, 'r')
        key = ckf.readline()
        ckf.close()
    ft = Fernet(key)
    return ft.encrypt(message.encode())

def decrypt(message):
    """Déchiffrer une chaine de caractères"""

    ckf = open(KEY_FILE, 'r')
    key = ckf.readline()
    ckf.close()
    ft = Fernet(key)
    return ft.decrypt(message).decode()

def get_sha256_from_image(imageName):
    """
    get sha256 from image attribut in ONE db
    """

    rsShow = silent_run(f"oneimage show {imageName} -x")
    if rsShow.returncode == 0:
        infos = XML.fromstring(rsShow.stdout)
        if infos is not None:
            infos = infos.find("TEMPLATE")
            if infos is not None:
                sha256Element = infos.find("SHA256")
                if sha256Element is not None:
                    return sha256Element.text
    return None

def add_zephir_credential_file(addr, user, passwd):
    """
    add zephir credential to file
    """

    ds_id = None
    zephirCredentialFile = ZCREDS_NAME

    line = addr + " " + user + " " + passwd
    sha256Credential = hashlib.sha256(line.encode('utf-8')).hexdigest()
    printInfo("sha256Credential = " + sha256Credential)

    tmpdir = "/var/tmp/one/hapy-deploy"
    if not os.path.exists(tmpdir):
        os.makedirs(tmpdir)

    fp = tempfile.NamedTemporaryFile(delete=False, dir=tmpdir)
    fp.write(line.encode())
    fp.close()
    shutil.chown(fp.name, user="oneadmin")

    rs = silent_run("onedatastore list --csv --no-header -f TYPE=fil -l ID")
    if rs.returncode != 0:
        return False

    ds_id = rs.stdout.decode().rstrip()
    printInfo("ds_id  = " + ds_id)

    SHA256_IN_DB = get_sha256_from_image(zephirCredentialFile)
    if SHA256_IN_DB == sha256Credential:
        print("Crédential Zéphir non changé")
        return True

    print("Crédential Zéphir changé, rechargement")
    silent_run(f"oneimage delete {zephirCredentialFile}")

    cmd = f"oneimage create --type CONTEXT --datastore {ds_id} --name {zephirCredentialFile} --path {fp.name}"
    rs = silent_run(cmd)
    if rs.returncode != 0:
        print(rs.stderr.decode() + rs.stdout.decode())
        os.remove(fp.name)
        return False

    time.sleep(2)
    os.remove(fp.name)

    ntmpl = f"SHA256 = {sha256Credential}\n"
    with tempfile.NamedTemporaryFile(delete=False) as fp:
        fp.write(ntmpl.encode())

    printInfo("TEMPLATE IMAGE SHA " + zephirCredentialFile)
    printInfo(str(ntmpl))

    res = silent_run(f"oneimage update {zephirCredentialFile} {fp.name} --append ")
    if res.returncode != 0:
        print(f"Error updating SHA {zephirCredentialFile}")
        print("   {0}".format(res.stdout))
        os.remove(fp.name)
        return False

    os.remove(fp.name)
    return True

def get_pwd(addr, port):
    """
    lecture d'un login/passwd pour l'application zephir
    """

    login_ok = 0
    idx = 0
    user = None
    passwd = None
    proxy = None
    from_hst = False
    while login_ok == 0:
        try:
            # flush de l'entrée standard au cas où l'utilisateur aurait
            # tapé <entrée> pendant l'Upgrade
            termios.tcflush(sys.stdin, termios.TCIOFLUSH)
        except:
            pass
        if os.path.exists(CRD_FILE):
            creds = open(CRD_FILE, 'r').read().split()
            user = decrypt(creds[1].encode())
            passwd = decrypt(creds[0].encode())
            from_hst = True
        if not user:
            user = flushed_input("Entrez votre login zephir (rien pour sortir) : ")
        if user != "":
            if not passwd:
                passwd = getpass.getpass("Mot de passe zephir pour %s : " % user)
            # création du proxy avec zephir
            proxy = EoleProxy("https://%s:%s@%s:%s" % (user, passwd,
                                                       addr, port), transport=TransportEole())
            try:
                res = convert(proxy.get_permissions(user))
                login_ok = 1
                if not from_hst:
                    rep = flushed_input("Voulez-vous retenir ces identifiants pour les prochaines utilisations ? [non] : ")
                    if rep.rstrip() == "":
                        pass
                    elif rep.rstrip() == "oui" or rep.rstrip() == "o":
                        crd = open(CRD_FILE, "w")
                        crd.write(crypt(passwd).decode())
                        crd.write("\n")
                        crd.write(crypt(user).decode())
                        crd.close()
            except xmlrpclib.ProtocolError:
                login_ok = 0
                from_hst = False
                user = None
                passwd = None
                print_line("\n Erreur d'authentification \n")
        else:
            return False, None, "! Abandon de la procédure !"
        idx += 1
        if login_ok == 0 and idx > 9:
            return False, None, "! Nombre de tentative dépassée !"
    if add_zephir_credential_file(addr, user, passwd):
        return True, proxy, "OK"
    else:
        return False, None, "err"

def get_config_from_zephir(id_list, zephir_proxy):
    """ Get the server configuration from zephir server
        writes a file with all the configuration for each server.
    """
    # Recover ssh key
    fic_cle = open("/var/spool/uucp/.ssh/eole.pub", "r")
    cle_pub = fic_cle.readlines()[0] # unquement la 1er ligne !!
    fic_cle.close()

    for id_serveur in id_list:
        raw_conf = zephir_proxy.serveurs.get_config(id_serveur)
        #Write configuraiton file
        dest_dir = os.path.join(DPL_ROOT_DIR, "confs", str(id_serveur))
        try:
            os.makedirs(dest_dir)
        except FileExistsError as err:
            pass
        except:
            e = sys.exc_info()[0]
            print(e)

        dest_file = os.path.join(dest_dir, "config.eol.sc")
        file_conf = open(dest_file, "wb")
        file_conf.write(crypt(json.dumps(raw_conf[1])))
        file_conf.close()
        #return raw_conf
    return True

def get_vms_infos(id_list):
    """ Extract virtual machine informations from the server configuration
    """
    vms = []
    # Get VM Information
    for vm in id_list:
        s_conf_file = os.path.join(DPL_ROOT_DIR, "confs", str(vm), "config.eol.sc")
        printInfo(" conf : " + s_conf_file)
        s_conf = open(s_conf_file, 'r').read()
        c_conf = decrypt(s_conf.encode())
        cnf = json.loads(c_conf)
        idx = 0
        proxy = None
        print("\t " + str(vm) + " : " + cnf['nom_domaine_machine'])
        if "vm_index" in cnf:
            idx = cnf['vm_index']
        if "vm_marketplace" in cnf:
            market = cnf['vm_marketplace']
        else:
            market = 'EOLE'

        if "proxy_client_adresse"  in cnf:
            proxy = f"http://{cnf['proxy_client_adresse']}:{cnf['proxy_client_port']}"

        vmi = {"name" : cnf['nom_domaine_machine'],
               "id_zephir": str(vm),
               "index": idx,
               "market": market,
               "eole_release": cnf['eole_release'],
               "app": cnf['vm_app'],
               "cpu": cnf['vm_cpu'],
               "vcpu": cnf['vm_vcpu'],
               "memory": cnf['vm_memory'],
               "ram": cnf['vm_memory'],
               "disk_size": cnf['vm_disk_size'],
               "proxy" : proxy,
               "net": [],
               "conf": cnf
              }
        for idx in range(int(cnf['nombre_interfaces'])):
            if idx == 0:
                # Force DNS and GW on first interface
                vmi['net'].append({"name": cnf[f'vm_vnet_name{idx}'],
                               "ip": cnf[f"adresse_ip_eth{idx}"],
                               "dns": cnf['adresse_ip_dns'].replace("|", " "),
                               "gw": cnf['adresse_ip_gw']
                               })
            else:
                vmi['net'].append({"name": cnf[f'vm_vnet_name{idx}'],
                               "ip": cnf[f"adresse_ip_eth{idx}"]
                               })

        vms.append(vmi)
    return vms

def get_image_info(disk_id_or_name):
    """
    get image info
    """

    printInfo("get_image_info " + disk_id_or_name)
    res = silent_run(f"oneimage show {disk_id_or_name} -x ")
    if res.returncode != 0:
        print_red("""Impossible de récupérer les infos de l'image !""")
        return None
    infosDisks = XML.fromstring(res.stdout)
    size = None
    _id = None
    name = None
    persistent = None
    state = None
    for attrDisk in infosDisks:
        if attrDisk.tag == "ID":
            _id = int(attrDisk.text)
        if attrDisk.tag == "NAME":
            name = attrDisk.text
        if attrDisk.tag == "SIZE":
            size = int(attrDisk.text)
        if attrDisk.tag == "PERSISTENT":
            persistent = attrDisk.text
        if attrDisk.tag == "STATE":
            state = attrDisk.text
    if _id is not None and size is not None and name is not None and disk_id_or_name in (_id, name):
        return {'id': _id,
                'name': name,
                'size': int(size),
                'persistent': persistent,
                'state' : state,
                }
    else:
        return None

def get_total_cpu_ram():
    """ Get the total CPU units and Memory available in the cluster before deploy.
    """
    tcpu = 0
    tram = 0
    # List all hosts
    cmd = "onehost list -l ID --no-header"
    res = silent_run(cmd)
    if res.returncode == 0:
        hstlst = res.stdout.decode().split()
        # Sum CPU and RAM of all hosts
        for hst in hstlst:
            res = silent_run("onehost show {0} -x".format(hst))
            if res.returncode == 0:
                infos = XML.fromstring(res.stdout)
                for inf in infos:
                    if inf.tag == "HOST_SHARE":
                        for attr in inf:
                            if attr.tag == "MAX_CPU":
                                tcpu += int(attr.text)
                            if attr.tag == "MAX_MEM":
                                tram += int(attr.text)
            else:
                return None, None
    else:
        return None, None
    return tcpu, tram

def check_resources(vm_list):
    """ Validates if what is asked is less than what we have
        return True if everyting is in order
    """
    total_cpu = 0
    total_ram = 0
    total_disk = 0

    ds_size = 0

    # Get image datastore size
    ds_info = None
    res = silent_run("onedatastore show {0} -x".format(IMG_DS))
    if res.returncode == 0:
        ds_info = XML.fromstring(res.stdout)

    for inf in ds_info:
        if inf.tag == "TOTAL_MB":
            ds_size = int(int(inf.text)/1024) # Disk size is in Go

    # Get Total CPU and RAM on cluster
    cl_total_cpu, cl_total_ram = get_total_cpu_ram()

    for vm in vm_list:
        total_cpu += int(float(vm["cpu"])*100)
        total_ram += int(vm["ram"])*1024
        if vm["disk_size"]:
            total_disk += int(vm["disk_size"])

    print("Vérification des resources (Demandé/Disponible):")
    if total_cpu < cl_total_cpu:
        print("\t CPU:  {0}/{1} Un\tOk".format(total_cpu, cl_total_cpu))
    else:
        print_red("\t CPU:  {0}/{1} Un\tErreur pas assez de CPU".format(total_cpu, cl_total_cpu))
    if total_ram < cl_total_ram:
        print("\t RAM:  {0}/{1} MB\tOk".format(int(total_ram/1024), int(cl_total_ram/1024)))
    else:
        print_red("\t RAM:  {0}/{1} MB\tErreur pas assez de mémoires".format(int(total_ram/1024), int(cl_total_ram/1024)))
    if total_disk < ds_size:
        print("\tDISK:  {0}/{1} GB\tOk".format(total_disk, ds_size))
    else:
        print_red("\tDISK:  {0}/{1} GB\tErreur pas assez d'espaces".format(total_disk, ds_size))

    if total_cpu < cl_total_cpu and total_ram < cl_total_ram and total_disk < ds_size:
        return True
    else:
        print_red("Erreur, resources insuffisantes pour déployer les machines virtuelles demandées")
        return False

def check_vnet(vms):
    """ Check if configured virtual networks in the VM are available in the cluster
        return True if everything is in order
        return False if onevnet command failed
        return False and the network names if any network is missing
    """
    vnets = []
    avnets = []
    missing = []
    print("Vérification des réseaux:")
    res = silent_run("onevnet list -l NAME --no-header")
    if res.returncode == 0:
        vnets = res.stdout.decode().split()
    else:
        print_red("Erreur, vérification de la cohérence des réseaux virtuels impossible")
        return False

    for vm in vms:
        for net in vm["net"]:
            vnetName = net["name"]
            if vnetName not in avnets:
                avnets.append(vnetName)

    for net in avnets:
        if net not in vnets:
            missing.append(net)

    if len(missing) != 0:
        print_red("  Disponible: " + str(sorted(vnets)))
        print_red("     Demandé: " + str(sorted(avnets)))
        print_red("Erreur, réseaux virtuels incohérents {0} n'existe.nt pas dans Hâpy".format(missing))
        return False
    else:
        print("          Ok: " + str(sorted(vnets)))
        return True

def convert_ipv4(ip):
    return tuple(int(n) for n in ip.split('.'))

def check_ipv4_in(addr, start, end):
    return convert_ipv4(start) <= convert_ipv4(addr) <= convert_ipv4(end)

def check_vnet_range(vms):
    """ Check if IP requested are in the virtual networks range
        return True if everything is in order
        return False if onevnet command failed
    """
    vnets = []
    print("Vérification des adresses / range réseaux:")
    res = silent_run("onevnet list -l NAME --no-header")
    if res.returncode == 0:
        vnets = res.stdout.decode().split()
    else:
        print_red("Erreur, vérification de la cohérence des réseaux virtuels impossible")
        return False

    # je récupere dans localVNet un tableau des range IP par net actuellement configuré dans Hapy.
    localVNet = {}
    for net in vnets:
        res = silent_run("onevnet show " + net)
        if res.returncode == 0:
            lignes = res.stdout.decode().split('\n')
            for l in lignes:
                items = l.split()
                if len(items) > 2:
                    if items[0] == "IP":
                        ipRangeStart = str(items[1])
                        ipRangeEnd = str(items[2])
                        localVNet[net] = {'start': ipRangeStart, 'end': ipRangeEnd}

    errorDetected = False
    for vm in vms:
        for net in vm["net"]:
            vnetName = net["name"]
            if vnetName in localVNet:
                vnetIp = net["ip"]
                ipRangeStart = localVNet[vnetName]['start']
                ipRangeEnd = localVNet[vnetName]['end']
                if not check_ipv4_in(vnetIp, ipRangeStart, ipRangeEnd):
                    print_red("\t" + vnetName + " \t" + vnetIp + "\tNOK n'est pas dans l'adressage (" + ipRangeStart + " - " + ipRangeEnd + ")")
                    errorDetected = True
                else:
                    print("\t" + vnetName + " \t"+ vnetIp + "\tOK (" + ipRangeStart + " - " + ipRangeEnd + ")")

    if errorDetected:
        # les messages ci dessus
        return False
    else:
        print("   Les adresses des VM sont cohérentes")
        return True


def isVmExiste(vmName):
    """
    true if vm exists
    """

    resShow = silent_run(f"onevm show {vmName}")
    return resShow.returncode == 0


def isVMDiskNeedResize( vmName, disk0, disk_size_requested):
    """
    true if requested size is bigger than current disk size
    """

    disk = get_image_info(disk0)
    if disk is None:
        sys.stdout.write("\t[NO_DISK]\n")
        throwDeployException(vmName, None, "CHECK_RESIZE:ERROR:NO_DISK")
        return False# impossible !

    disk_size_requested_in_Mo = int(disk_size_requested) * 1024  # GB -> MB
    currentSize = disk['size']
    if disk_size_requested_in_Mo <= currentSize:
        print(f"   * Dimensionnement du disque correct.")
        return False
    else:
        # ok besoin de redimmensionnement
        print(f"   * Redimensionnement du disque à faire.")
        return True

def onevm_disk0_resize(vmName, disk_size_requested):
    """ Resize first disk of a VM if requested size is bigger than
        original size
    """

    disk_size_requested_in_Mo = int(disk_size_requested) * 1024  # GB -> MB
    # Don't shrink a disk
    res = silent_run(f"onevm disk-resize {vmName} 0 {disk_size_requested_in_Mo}")
    if res.returncode != 0:
        msgErr = res.stdout.decode().strip()
        msgErr = f"Echec lors du redimensionnement du disque 0 de la VM {vmName}:\n {msgErr}\n"
        sys.stdout.write(msgErr)
        throwDeployException(vmName, res, "RESIZEVM:ERROR:" + msgErr)
    else:
        print(f"   * Redimensionnement du disque fait")

def get_disk_name_for_vm(vmName):
    """
    get disk 0 name of the vm
    """
    return f"{vmName}-disk-0"

def onetemplate_update(vm, disk0, phase):
    """ Update VM template with what's in the "server" configuration
    """
    tmplName = vm['name']
    eoleRelease = vm['eole_release']
    vmName = vm['name']
    id_zephir = vm["id_zephir"]
    vnets = vm["net"]
    proxy = vm['proxy']
    #disk_size = vm['disk_size']

    ntmpl = f"CPU = {vm['cpu']}\n"
    ntmpl += f"VCPU = {vm['vcpu']}\n"
    ntmpl += f"MEMORY = {vm['memory']}\n"
    #ntmpl += "CPU_MODEL = [ MODEL = \"host-passthrough\" ]\n"
    ntmpl += "FEATURES = [ ACPI = \"yes\", PAE = \"no\" ]\n"
    if eoleRelease >= "2.9.0":
        # UEFI
        ntmpl += "OS = [ ARCH = \"x86_64\", BOOT = \"disk0\", FIRMWARE = \"/usr/share/OVMF/OVMF_CODE.fd\", MACHINE = \"q35\", SD_DISK_BUS = \"scsi\" ]\n"
    else:
        # MBR
        ntmpl += "OS = [ ARCH = \"x86_64\", BOOT = \"disk0\" ]\n"
    
    # TODO : enlever 0.0.0.0 !
    ntmpl += "GRAPHICS = [ KEYMAP = \"fr\", LISTEN = \"0.0.0.0\", TYPE = \"vnc\" ]\n"
    ntmpl += "INPUT = [ BUS = \"usb\", TYPE = \"tablet\" ]\n"

    ntmpl += f"DISK= [ DRIVER=\"qcow2\", IMAGE = \"{disk0}\", IMAGE_UNAME = \"oneadmin\" ]\n" # pas de SIZE pour les disques persistents !
    for net in vm["net"]:
        nicLine = f"NIC = [ NETWORK = \"{net['name']}\", "
        if 'ip' in net:
            nicLine += f"IP = \"{net['ip']}\", "
        if 'mask' in net:
            nicLine += f"NETWORK_MASK = \"{net['mask']}\", "
        if 'gw' in net:
            nicLine += f"GATEWAY = \"{net['gw']}\", "
        if 'dns' in net:
            nicLine += f"DNS = \"{net['dns']}\", "
        if not ( 'dns' in net or 'gw' in net or 'mask' in net ):
            nicLine += "METHOD = \"skip\", "
        nicLine += "MODEL = \"virtio\", "
        nicLine += "NETWORK_UNAME = \"oneadmin\" ]\n"
        ntmpl += nicLine

    ntmpl += "RAW = [ \n"
    ntmpl += "  DATA = \"<devices>  <filesystem type='mount' accessmode='mapped'>    <source dir='/var/log/hapy-deploy'/>    <target dir='hapy-deploy'/>  </filesystem>  </devices>\",\n"
    ntmpl += "  TYPE = \"kvm\",\n"
    ntmpl += "  VALIDATE = \"no\"\n"
    ntmpl += "]\n"

    files = {}
    init_files = {}
    res = silent_run("oneimage list -f TYPE=CX -l USER,NAME --no-header --csv")
    if res.returncode == 0:
        for fle in res.stdout.decode().split():
            owner = fle.split(",")[0]
            name = fle.split(",")[1]
            if name in (ZCA_NAME, ZCREDS_NAME):
                files[name] = owner
            if name.endswith(".sh"):
                if re.match(r'^[0-9][0-9]_', name):
                    init_files[name] = owner

    # toujours un CONTEXT !
    ntmpl += "CONTEXT = [\n"
    if len(files) != 0:
        if phase == 'BOOT2_AVEC_PROVISIONING':
            # lignes FILES_DS et INIT_SCRIPTS uniquement si besoin
            lines = "  FILES_DS = \""
            # Add files and init scripts
            for fl in sorted(files):
                lines += '$FILE[IMAGE=\\"{0}\\", IMAGE_UNAME=\\"{1}\\"] '.format(fl, files[fl])
            for fil in sorted(init_files):
                lines += '$FILE[IMAGE=\\"{0}\\", IMAGE_UNAME=\\"{1}\\"] '.format(fil, init_files[fil])
            lines += "\",\n"
            ntmpl += lines
            # Define init scripts to be started on boot
            #lines = "  INIT_SCRIPTS = \""
            #for fil in sorted(init_files):
            #    lines += fil + ' '
            #lines += '",\n'
            #ntmpl += lines
            scripts = "#!/bin/bash\n"
            for fil in sorted(init_files):
                scripts += f"bash -x {fil}\n"
            printInfo(scripts)
            scripts_bytes = scripts.encode('ascii')
            base64_bytes = base64.b64encode(scripts_bytes)
            base64_scripts = base64_bytes.decode('ascii')
            ntmpl += "  START_SCRIPT_BASE64 = \"" + base64_scripts + "\",\n"

        if phase == 'BOOT1_SANS_PROVISIONING':
            # un seul script qui monte le partage, créer le fichier status, et démonte le partage
            scripts = "#!/bin/bash\n"
            scripts += "mkdir /tmp/hapy-deploy\n"
            scripts += "mount -t 9p -otrans=virtio,version=9p2000.L hapy-deploy /tmp/hapy-deploy\n"
            scripts += f"echo 'MOUNT:DONE:OK' >/tmp/hapy-deploy/{vmName}.bootok\n"
            scripts += "umount /tmp/hapy-deploy\n"
            printInfo(scripts)
            scripts_bytes = scripts.encode('ascii')
            base64_bytes = base64.b64encode(scripts_bytes)
            base64_scripts = base64_bytes.decode('ascii')
            ntmpl += "  START_SCRIPT_BASE64 = \"" + base64_scripts + "\",\n"

    if DEBUG > "0":
        print("HACK: j'injecte un mdp root/Eole12345! pour pouvoir se connecter en SSH")
        # depuis hapy,
        #   ssh root@192.168.0.24
        #   DEBUG=1 /usr/sbin/one-contextd all force
        ntmpl += '  USERNAME = "root",\n'
        ntmpl += '  PASSWORD = "Eole12345!",\n'

    ntmpl += '  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]",\n'
    idx = 0
    for net in vnets:
        if 'ip' in net:
            ntmpl += f'  IP_ETH{idx}=\"{net["ip"]}\",\n'
        if 'mask' in net:
            ntmpl += f'  NETMASK_ETH{idx}=\"{net["mask"]}\",\n'
        if 'dns' in net:
            ntmpl += f'  DNS_ETH{idx}=\"{net["dns"]}\",\n'
        if idx == 0:
            ntmpl += f'  GW_ETH{idx}=\"{net["gw"]}\",\n'
        idx += 1
    ntmpl += f'  ZEPHIR_ID=\"{id_zephir}\",\n'
    ntmpl += f'  VM_NAME=\"{vmName}\",\n'
    ntmpl += '  VM_ID=\"$VMID\",\n'
    if proxy:
        ntmpl += f"  PROXY=\"{proxy}\",\n"
    ntmpl += "  NETWORK=\"YES\",\n"
    if phase == 'BOOT3_CONTEXT_FINAL':
        ntmpl += "  NETCFG_TYPE=\"none\",\n"   # ne touch a rien, c'est EOLE qui controle !!
    else:
        ntmpl += "  NETCFG_TYPE=\"netplan\",\n"   # https://github.com/OpenNebula/addon-context-linux/blob/master/src/etc/one-context.d/loc-10-network
    ntmpl += "  GROW_ROOTFS=\"NO\"\n"
    ntmpl += "]\n"

    with tempfile.NamedTemporaryFile(delete=False) as fp:
        fp.write(ntmpl.encode())

    printInfo("TEMPLATE " + tmplName)
    printInfo(str(ntmpl))

    res = silent_run(f"onetemplate update {tmplName} {fp.name}")
    if res.returncode != 0:
        print(f"Error updating template {vm['app']}")
        print(f"   {res.stdout}")
        throwDeployException(vm["app"], res, "TEMPLATE_APP:ERROR")

    os.remove(fp.name)

def get_vm_status_by_name(vmName):
    """
    get vm status
    """

    res = silent_run(f"onevm list --csv --no-header -f NAME={vmName}")
    #ID,USER,GROUP,NAME,STAT,CPU,MEM,HOST,TIME
    if res.returncode == 0:
        try:
            return res.stdout.decode().strip().split(',')[4], res # 4 = STAT
        except:
            return "VANISHED", res
    else:
        return "VANISHED", res

def wait_vm_vanished(vmName):
    """
    wait vm vanished
    """

    sys.stdout.write("   * Attente terminaisson de la VM")
    time_sleep = 5
    tmout = 240 # 4 minutes pour arreter la VM.
    res = None
    while tmout > 0:
        res = silent_run(f"onevm list --csv --no-header -f NAME={vmName}")
        if res.returncode == 0:
            msg = res.stdout.decode()
            if msg == "":
                printStatusAndWriteLog(vmName, "[OK]", "VM_VANISHED:OK")
                return
        tmout = tmout - time_sleep
        sys.stdout.write(".")
        sys.stdout.flush()
        time.sleep(time_sleep)
    printStatusAndThrowDeployException(vmName, "[TIMEOUT]", res, "WAIT_VANISHED:TIMEOUT")

def wait_vm_status(vmName, statusAttendu, message_context):
    """
    wait vm status = statusAttendu
    """

    sys.stdout.write("   * Attente " + message_context)

    time_sleep = 5
    tmout = 240 # 4 minutes pour atteindre le status attendu
    while tmout > 0:
        status, res = get_vm_status_by_name(vmName)
        if status == statusAttendu:
            printStatusAndWriteLog(vmName, "[OK]", "WAIT_STATUS:OK:" + statusAttendu)
            return
        if status == "err":
            printStatusAndThrowDeployException(vmName, "[KO]", res, "WAIT_STATUS:KO:")
            return
        tmout = tmout - time_sleep
        sys.stdout.write(".")
        sys.stdout.flush()
        time.sleep(time_sleep)
    printStatusAndThrowDeployException(vmName, "[TIMEOUT]", res, "WAIT_STATUS:TIMEOUT:" + statusAttendu)

def wait_image_ready(vmName, imageName, message_context):
    """
    wait image status = rdy
    """

    sys.stdout.write("   * Attente image " + message_context)

    # SHORT_IMAGE_STATES = {"init", "rdy", "used", "disa", "lock", "err", "clon", "dele", "used", "lock", "lock"};
    time_sleep = 10
    tmout = 1000 # 10 minutes pour atteindre le status attendu
    while tmout > 0:
        disk = get_image_info(imageName)
        if disk is not None:
            if disk['state'] == "1": # rdy
                printStatusAndWriteLog(vmName, "[OK]", "WAIT_IMAGE_READY:OK:")
                return
            if disk['state'] == "5": # err
                printStatusAndThrowDeployException(vmName, "[KO]", None, "WAIT_IMAGE_READY:KO:")
                return
        tmout = tmout - time_sleep
        sys.stdout.write(".")
        sys.stdout.flush()
        time.sleep(time_sleep)
    printStatusAndThrowDeployException(vmName, "[TIMEOUT]", None, "WAIT_IMAGE_READY:TIMEOUT:")

def wait_bootok_file_created(vmName, bootok_path):
    """
    wait bootok file created
    """

    sys.stdout.write("   * Attente démarrage ")
    time_sleep = 10
    tmout = 1000 # 10 minutes pour le boot et la création de 'bootok'

    while tmout > 0:
        if os.path.isfile(bootok_path):
            printStatusAndWriteLog(vmName, "[OK]", "WAIT_BOOT:OK")
            return
        sys.stdout.write(".")
        sys.stdout.flush()
        tmout = tmout - time_sleep
        time.sleep(time_sleep)

    printStatusAndThrowDeployException(vmName, "[TIMEOUT]", None, "WAIT_BOOT:TIMEOUT:")

def display_step(current_step, status_path):
    """
    display step
    """

    STEPS = {"MOUNT": "montage du contexte",
             "SETUP_NETWORK": "configuration du réseau",
             "MAJAUTO": "mise à jour",
             "ENREGISTREMENT_ZEPHIR": "enregistrement Zéphir",
             "INSTANCE": "instanciation",
             "HALT": "arrêt de la machine"}

    # si le fichier de status existe je lis le STEP
    if not os.path.isfile(status_path):
        if current_step != 'démarrage':
            sys.stdout.write("\n     démarrage")
            current_step = 'démarrage'
    else:
        # une seule ligne dans le fichier !
        with open(status_path) as status_log:
            status = status_log.read().strip()
            try:
                step, state, log = status.split(":", 2)
                step_name = STEPS.get(step, step)
                if state == 'ERROR':
                    print_red(f'Erreur durant {STEPS.get(step, step)} : {log}')
                    return 'ERROR'
                if current_step != step:
                    sys.stdout.write(f"\n     {step_name}")
                    current_step = step
            except:
                sys.stdout.write("\n     status=" + status)
                pass
    return current_step

def display_log(vmName, fileHandeLog, log_vm_path):
    """
    display log if existe
    """

    desLignesOntEteAffichees = False
    if os.path.isfile(log_vm_path):
        if fileHandeLog is None:
            fileHandeLog = open(log_vm_path)

        while True:
            file_stats = os.stat(log_vm_path)
            tell = fileHandeLog.tell()
            size = file_stats.st_size
            if tell == size:
                break
            #sys.stdout.write(f"  {tell} -> {size}\n")
            for ligne in fileHandeLog.readlines():
                sys.stdout.write(f"{vmName}: ")
                sys.stdout.write(ligne)
                desLignesOntEteAffichees = True
            sys.stdout.flush()
    else:
        sys.stdout.write(".")
        sys.stdout.flush()
    return desLignesOntEteAffichees, fileHandeLog

def monitor_provisioning_vm(vmName, status_path, log_vm_path):
    """
    monitor the EOLE provisionning of the VM
    """

    printInfo("monitor_provisioning_vm(" + vmName +")")
    time_sleep = 2
    tmout = 2000 # 10 minutes pour le 1er message
    current_step = ""
    status = None
    res = None
    fileHandeLog = None
    try:
        while tmout > 0:
            # 1 : j'attends
            tmout = tmout - time_sleep
            time.sleep(time_sleep)

            # 2 : j'affiche l'état d'avancement
            current_step = display_step(current_step, status_path)
            if current_step == "ERROR":
                print_red(f"Vous trouverez plus d'informations dans le journal : {log_vm_path}")
                break

            # 3 : dans quel état est la VM
            status, res = get_vm_status_by_name(vmName)
            if status == "poff":
                # si la machine passe en poweroff, c'est que l'instance EOLE est finit
                break

            if status == "err":
                break

            # 4 : affiche le log
            desLignesOntEteAffichees, fileHandeLog = display_log(vmName, fileHandeLog, log_vm_path)
            if desLignesOntEteAffichees:
                # rearme timeout 10 minutes pour le message suivant
                tmout = 600

    finally:
        # dans tous les cas, il faut voir s'il reste des logs à afficher
        desLignesOntEteAffichees, fileHandeLog = display_log(vmName, fileHandeLog, log_vm_path)
        if fileHandeLog is not None:
            fileHandeLog.close()

    if status == "poff":
        # TODO : 2 cas, poweroff normal et poweroff anormal !
        printStatusAndWriteLog(vmName, "[OK]", "PROVISIONNING:OK")
        print("   * fin du provisionning OK") # ce message permet à l'automate de test de sortir de 'Instance dans Instance' cf monitor_eole_ci4.py
        return

    if tmout <= 0:
        printStatusAndThrowDeployException(vmName, "[TIMEOUT]", res, "PROVISIONING:TIMEOUT:")

    printStatusAndThrowDeployException(vmName, "[KO]", res, "PROVISIONING:KO:" + status)

def check_image_is_persitante(vmName, disk0):
    """
    Vérification disque persistant
    """

    sys.stdout.write("   * Vérification disque persistant ")

    disk = get_image_info(disk0)
    if disk is None:
        sys.stdout.write("\t[NO_DISK]\n")
        throwDeployException(vmName, None, "PERSISTENT:ERROR:NO_DISK")
        return # impossible !

    if disk['persistent'] == "1":
        printStatusAndWriteLog(vmName, "[OK]", "PERSISTENT:OK")
        return

    diskId = disk['id']
    res = silent_run(f"oneimage persistent {diskId}")
    if res.returncode != 0:
        sys.stdout.write("\t[KO] ")
        msgErr = f"Echec lors du redimensionnement du disque {0} de la VM {1}:\n {2}\n".format(diskId, vmName, res.stdout.decode().strip())
        sys.stdout.write(msgErr)
        throwDeployException(vmName, res, "PERSISTENT:ERROR:" + msgErr)
    else:
        printStatusAndWriteLog(vmName, "[OK]", "PERSISTENT:OK")

def onetemplate_instantiate(vmName, message_context):
    """
    onetemplate instantiate wrapper
    """

    sys.stdout.write("   * Création de la machine virtuelle " + message_context)
    resOnetemplateInstantiate = silent_run("onetemplate instantiate " + vmName + " --name " + vmName)
    if resOnetemplateInstantiate.returncode != 0:
        printStatusAndThrowDeployException(vmName, "[KO]", resOnetemplateInstantiate, "TEMPLATE_INSTANTIATE:KO")
    else:
        printStatusAndWriteLog(vmName, "[OK]", "TEMPLATE_INSTANTIATE:OK")

def onevm_terminate(vmName):
    """
    onevm terminate wrapper
    """

    sys.stdout.write("   * Supression VM...")
    resTerminate = silent_run(f"onevm terminate {vmName}")
    if resTerminate.returncode != 0:
        printStatusAndThrowDeployException(vmName, "[KO]", resTerminate, "TERMINATE:KO")
    else:
        printStatusAndWriteLog(vmName, "[OK]", "TERMINATE:OK")

def onevm_poweroff(vmName):

    sys.stdout.write("   * Demande l'arrêt de la VM")
    resPowerOff = silent_run(f"onevm poweroff {vmName}")
    if resPowerOff.returncode != 0:
        printStatusAndThrowDeployException(vmName, "[KO]", resPowerOff, "POWEROFF:KO")
    else:
        printStatusAndWriteLog(vmName, "[OK]", "POWEROFF:OK")


def onevm_resume(vmName):
    """
    onevm resume wrapper
    """

    sys.stdout.write("   * Redémarrage...")
    res = silent_run(f"onevm resume {vmName}")
    if res.returncode == 0:
        printStatusAndWriteLog(vmName, "[OK]", "RESUME:OK")
    else:
        printStatusAndThrowDeployException(vmName, "[KO]", res, "RESUME:KO")

def check_power_on(vmName):
    """
    check if poweronn VM
    """

    sys.stdout.write("   * Vérification démarrage de la machine virtuelle ")
    status, res = get_vm_status_by_name(vmName)
    if status is None:
        printStatusAndThrowDeployException(vmName, "(?) [absente]", res, "RESUME:NOK")

        # si ERROR, on ne peut rien faire, Stop
    if status == "err":
        printStatusAndThrowDeployException(vmName, "[KO]", res, "RESUME:KO")

    # si RUNNING, ok stop
    if status == "runn":
        printStatusAndWriteLog(vmName, "(" + status + ") [OK]", "RESUME:OK:" + status)
        return

    # si POWEROFF, resume and wait running
    if status == "poff":
        printStatusAndWriteLog(vmName, "(poff) à redémarrer...", "RESUME:OK:" + status)
        onevm_resume(vmName)
        wait_vm_status(vmName, "runn", "démarrage")
        return

    printStatusAndWriteLog(vmName, "(" + status + ") [OK]", "RESUME:OK:" + status)
    # si PENDING, attend RUNNING, Stop
    if status == "pend":
        wait_vm_status(vmName, "runn", "démarrage")

def import_apps_from_markets(app):
    """ "Import" appliance from market (download image and base template)
    """

    # Create a list containing the appliances to be imported

    sys.stdout.write(f"   * Importing appliance {app} ")
    # Import Appliance
    res = silent_run(f"onemarketapp export {app} {app} --datastore {IMG_DS}")
    if res.returncode != 0 and res.returncode != 255 :
        throwDeployException(app, res, "IMPORT_APP:KO")

    # en cas de conflit de nom, returnCode = 0 ! mais le message contient l'erreur
    msg = res.stdout.decode()
    if msg.find("NAME is already taken by IMAGE") != -1:
        printStatusAndWriteLog(app, "[EXISTS]", "IMPORT_APP:EXISTS")
        return

    rsShow = silent_run(f"oneimage show {app}")
    if rsShow.returncode != 0:
        sys.stdout.write("\t[FAILED]\n")
        print(f"   {msg}")
        throwDeployException(app, rsShow, "IMPORT_APP:KO")

    printStatusAndWriteLog(app, "[OK]", "IMPORT_APP:OK")

def delete_template(vmName):
    """
    onetemplate delete wrapper
    """

    sys.stdout.write("   * Suppression du modèle de la machine virtuelle ")
    res = silent_run(f"onetemplate delete {vmName}")
    if res.returncode != 0:
        printStatusAndThrowDeployException(vmName, "[KO]", res, "TEMPLATE_DELETE:KO")
    else:
        printStatusAndWriteLog(vmName, "[OK]", "TEMPLATE_DELETE:OK")

def onetemplate_clone(vmName, app):
    """
    onetemplate clone wrapper
    """
    sys.stdout.write("   * Création du modèle pour la machine virtuelle ")
    res = silent_run(f"onetemplate clone --recursive {app} {vmName}")
    if res.returncode != 0 and res.returncode != 255:
        printStatusAndThrowDeployException(vmName, "[KO]", res, "TEMPLATE_CLONE:KO")

    # en cas de conflit de nom, returnCode = 0 ! mais le message contient l'erreur
    msg = res.stdout.decode()
    if msg.find("NAME is already taken by TEMPLATE") != -1:
        printStatusAndWriteLog(vmName, "[EXISTS]", "TEMPLATE_CLONE:EXISTS")
    else:
        printStatusAndWriteLog(vmName, "[OK]", "TEMPLATE_CLONE:OK")

def deploy_vms(vms):
    """Déploiement des machines virtuelles"""

    print("Déploiement des machines virtuelles")
    for vm in vms:
        vmName = vm['name']
        app = vm['app']
        disk_size_requested = vm['disk_size']
        print(f"{vmName} :")
        try:
            if isVmExiste(vmName):
                print("   * Existe dèjà. pas de modification.")
                check_power_on(vmName)
            else:
                bootok_path = f"/var/log/hapy-deploy/{vmName}.bootok"
                if os.path.isfile(bootok_path):
                    os.unlink(bootok_path)
                status_path = f"/var/log/hapy-deploy/{vmName}-STATUS.log"
                if os.path.isfile(status_path):
                    os.unlink(status_path)
                log_vm_path = f"/var/log/hapy-deploy/{vmName}.log"
                if os.path.isfile(log_vm_path):
                    os.unlink(log_vm_path)

                # phase 1 : Téléchargement Apps si besoin
                import_apps_from_markets(app)
                wait_image_ready(app, app, "téléchargement apps")

                # phase 2 : Clone Apps en vmName
                image_disk0 = get_disk_name_for_vm(vmName)
                onetemplate_clone(vmName, app)
                wait_image_ready(vmName, image_disk0, "copie image")

                if isVMDiskNeedResize(vmName, image_disk0, disk_size_requested):
                    # phase 3 : boot sans provisionning, attente, puis poweroof, resize disk, terminate
                    onetemplate_update(vm, image_disk0, 'BOOT1_SANS_PROVISIONING')
                    onetemplate_instantiate(vmName, "pour dimensionnement")
                    wait_vm_status(vmName, "runn", "démarrage pour dimensionnement")
                    wait_bootok_file_created(vmName, bootok_path)
                    onevm_poweroff(vmName)
                    wait_vm_status(vmName, "poff", "arrêt")
                    onevm_disk0_resize(vmName, disk_size_requested)
                    # Wait for state DISK_RESIZE_POWEROFF to go off
                    wait_vm_status(vmName, "poff", "arrêt pour redimensionnement")
                    onevm_terminate(vmName)
                    wait_vm_vanished(vmName)

                # phase 4 : check persistante
                check_image_is_persitante(vmName, image_disk0)

                # phase 5 : boot avec provisionning,
                onetemplate_update(vm, image_disk0, 'BOOT2_AVEC_PROVISIONING')
                onetemplate_instantiate(vmName, "pour provisionning EOLE")
                wait_vm_status(vmName, "runn", "démarrage provisionning")
                monitor_provisioning_vm(vmName, status_path, log_vm_path)
                # la fin de provisionning fait un 'halt' -> donc la vm est en poweroff
                onevm_terminate(vmName)
                wait_vm_vanished(vmName)

                # phase 6 : boot sans context
                onetemplate_update(vm, image_disk0, 'BOOT3_CONTEXT_FINAL')
                onetemplate_instantiate(vmName, "pour usage final")
                wait_vm_status(vmName, "runn", "démarrage final")
                print("   * Machine virtuelle démarrée.")

        except Exception as exception:
            print("\nErreur : " + str(exception))
            traceback.print_exc(file=sys.stdout)
            logError(vmName, None, "DEPLOY:KO:" + str(exception))

def main():
    """
    récupére les informations depuis Zéphir
    puis, deploie toutes les VMs.
    """
    if len(sys.argv) == 2:
        if sys.argv[1] == 'reconfigure':
            if not os.path.exists(CRD_FILE):
                print("Pour utiliser le dploiement automatique avec 'reconfigure', vous devez avoir enregistré les paramètres d'accès à Zéphir lors de l'instance.")
                sys.exit(1)

    # import des fonctions communes de Zéphir client
    authentified, proxy, msg_err = get_pwd(adresse_zephir, 7080)
    if not authentified:
        print(msg_err)
        sys.exit(0)

    if not os.path.exists(DPL_ROOT_DIR):
        os.mkdir(DPL_ROOT_DIR)

    if not os.path.exists("/var/log/hapy-deploy"):
        os.mkdir("/var/log/hapy-deploy")

    # on récupère la liste des groupes
    print('Recherche de la liste des serveurs (cette action peut être longue)')
    servers = []
    if MODE in ('site', 'mixte'):
        for rne in RNE:
            try:
                dico = {'rne': rne}
                groupe_vars = {'var_1': (VARIABLE_NAME, VARIABLE_VALUE, False)}
                idx, liste_serveurs = convert(proxy.serveurs.groupe_serveur(dico,
                                                                            groupe_vars, False))
            except xmlrpclib.ProtocolError:
                print_red("""Erreur de permissions ou Zéphir non disponible""")
                sys.exit(1)
            except socket.error as socket_error:
                print_red( f"Erreur de connexion au serveur Zéphir ({socket_error})")
                sys.exit(1)
            if idx != 1:
                print_red(liste_serveurs)
                sys.exit(1)
            for server in liste_serveurs:
                servers.append(server['id'])

    # Sort Servers by zephir_id for "recovered servers"
    servers = sorted(servers)

    if MODE in ("liste manuelle", "mixte"):
        for srv in client.get_creole('dp_server_id_list'):
            servers.append(int(srv))

    print( f"Liste des serveurs : {servers}")
    get_config_from_zephir(servers, proxy)

    vms = get_vms_infos(servers)
    vms = sorted(vms, key=lambda vm: (vm['index'], vm['id_zephir']))
    
    if not check_resources(vms):
        return

    if not check_vnet(vms):
        return

    if not check_vnet_range(vms):
        return

    now = datetime.datetime.now()
    statusLog("DEPLOY-START", now.strftime('%Y-%m-%d %H:%M:%S'))
    deploy_vms(vms)
    now = datetime.datetime.now()
    statusLog("DEPLOY-END", now.strftime('%Y-%m-%d %H:%M:%S'))
    if throwDeployExceptionCalled:
        print_red("Des erreurs ont été détectées. Consulter le fichier " + STATUS_FILE)


if __name__ == '__main__':
    main()
