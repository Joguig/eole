#!/usr/bin/env python3

# general
import sys

# samba
import ldb
from samba.provision import POLICIES_ACL
import samba.getopt as options
from samba.dcerpc import security
from samba.netcmd.gpo import (
    get_gpo_containers,
    del_gpo_link,
    get_gpo_dn,
    Option,
    SuperCommand
)

from .gpo_eole import ( 
    EoleGPOCommand
)

# specifique Eole

class cmd_fix_gpo_acl(EoleGPOCommand):
    """Fix acl gpo."""

    synopsis = "%prog <gpo_name> [options]"

    takes_optiongroups = {
        "sambaopts": options.SambaOptions,
        "versionopts": options.VersionOptions,
        "credopts": options.CredentialsOptions,
    }

    takes_args = [ 'gpo_name' ]

    takes_options = [
        Option("-H", help="LDB URL for database or target server", type=str),
    ]

    def run(self, gpo_name, H=None, container=None, sambaopts=None, credopts=None, versionopts=None):
        
        if self.initialisation(gpo_name, H, sambaopts, credopts, versionopts):
            self.debug ("check_gpos_acl ...")
            self.check_gpos_acl()
            
class cmd_fix_netlogon_scripts_acl(EoleGPOCommand):
    """Create Netlogon script hierachy."""

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
        self.doConnection(H=H, sambaopts=sambaopts, credopts=credopts, versionopts=versionopts)
        connNetlogon = self.smb_connection(self.dc_hostname, "netlogon", lp=self.lp, creds=self.creds)
        self.domain_sid = security.dom_sid(self.samdb.get_domain_sid())
        self.fs_sd = security.descriptor.from_sddl(POLICIES_ACL, self.domain_sid)
        self.create_directory_hier(connNetlogon, self.fs_sd, 'users')
        self.create_directory_hier(connNetlogon, self.fs_sd, 'groups')
        self.create_directory_hier(connNetlogon, self.fs_sd, 'machines')
        self.create_directory_hier(connNetlogon, self.fs_sd, 'os')


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
        try:
            self.samdb.delete(gpo_dn_user)
        except Exception as e:
            pass
        
        gpo_dn_machine = ldb.Dn(self.samdb, "CN=Machine,%s" % str(gpo_dn))
        self.debug2 ("samdb delete gpo machine :" + str(gpo_dn_machine))
        try:
            self.samdb.delete(gpo_dn_machine)
        except Exception as e:
            pass
        
        self.debug2 ("samdb delete:" + str(self.gpo_dn))
        try:
            self.samdb.delete(self.gpo_dn)
        except Exception as e:
            pass

        # Remove GPO files
        self.debug2 ("conn delete:" + self.sharepath)
        try:
            self.conn.deltree(self.sharepath)
        except Exception as e:
            pass

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
            self.errf.write('\n') 
            return 1
        else:
            if attribut is None:
                self.outf.write(str(self.gpc_entry['name'][0]))
            else:
                self.outf.write(str(self.gpc_entry[attribut][0]))
            self.outf.write('\n') 
            
            
class cmd_helper(SuperCommand):
    """Group Policy Object (GPO) Helper EOLE Scripts."""

    subcommands = {}
    subcommands["delete_by_name"] = cmd_delete()
    subcommands["show_by_name"] = cmd_show()
    subcommands["fix_gpo_acl"] = cmd_fix_gpo_acl()
    subcommands["fix_netlogon_scripts_acl"] = cmd_fix_netlogon_scripts_acl()

 
if __name__ == "__main__": 
    # make sure the script dies immediately when hitting control-C,
    # rather than raising KeyboardInterrupt. As we do all database
    # operations using transactions, this is safe.
    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)
     
    cmd = cmd_helper()
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
    
