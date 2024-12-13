#!/bin/bash 
#Usage: [-?XaNPSeV] [-?|--help] [--usage] [--format=STRING]
#       [-p|--smb-ports=STRING] [--basedir=BASEDIR] [--seed=INT]
#       [--num-progs=INT] [--num-ops=INT] [--entries=INT]
#       [--loadfile=STRING] [--list-suites] [--list] [--unclist=STRING]
#       [-t|--timelimit=INT] [-f|--failures=INT] [-D|--parse-dns=STRING]
#       [-X|--dangerous] [--load-module=SOFILE] [--shell]
#       [-T|--target=STRING] [-a|--async] [--num-async=INT]
#       [--maximum-runtime=seconds] [--extra-user=STRING]
#       [--load-list=STRING] [-d|--debuglevel=DEBUGLEVEL] [--debug-stderr]
#       [-s|--configfile=CONFIGFILE] [--option=name=value]
#       [-l|--log-basename=LOGFILEBASE] [--leak-report] [--leak-report-full]
#       [-R|--name-resolve=NAME-RESOLVE-ORDER]
#       [-O|--socket-options=SOCKETOPTIONS] [-n|--netbiosname=NETBIOSNAME]
#       [-S|--signing=on|off|required] [-W|--workgroup=WORKGROUP]
#       [--realm=REALM] [-i|--scope=SCOPE] [-m|--maxprotocol=MAXPROTOCOL]
#       [-U|--user=[DOMAIN/]USERNAME[%PASSWORD]] [-N|--no-pass]
#       [--password=STRING] [-A|--authentication-file=FILE]
#       [-P|--machine-pass] [--simple-bind-dn=STRING] [-k|--kerberos=STRING]
#       [--krb5-ccache=STRING] [-S|--sign] [-e|--encrypt] [-V|--version]
#       <binding>|<unc> TEST1 TEST2 ...
#
#The binding format is:
#
# TRANSPORT:host[flags]
#
# where TRANSPORT is either ncacn_np for SMB, ncacn_ip_tcp for RPC/TCP
# or ncalrpc for local connections.
#
# 'host' is an IP or hostname or netbios name. If the binding string
# identifies the server side of an endpoint, 'host' may be an empty
# string.
#
# 'flags' can include a SMB pipe name if using the ncacn_np transport or
# a TCP port number if using the ncacn_ip_tcp transport, otherwise they
# will be auto-determined.
#
# other recognised flags are:
#
#   sign : enable ntlmssp signing
#   seal : enable ntlmssp sealing
#   connect : enable rpc connect level auth (auth, but no sign or seal)
#   validate: enable the NDR validator
#   print: enable debugging of the packets
#   bigendian: use bigendian RPC
#   padcheck: check reply data for non-zero pad bytes

# For example, these all connect to the samr pipe:

#   ncacn_np:myserver
#   ncacn_np:myserver[samr]
#   ncacn_np:myserver[\pipe\samr]
#   ncacn_np:myserver[/pipe/samr]
#   ncacn_np:myserver[samr,sign,print]
#   ncacn_np:myserver[\pipe\samr,sign,seal,bigendian]
#   ncacn_np:myserver[/pipe/samr,seal,validate]
#   ncacn_np:
#   ncacn_np:[/pipe/samr]
#
#    ncacn_ip_tcp:myserver
#    ncacn_ip_tcp:myserver[1024]
#    ncacn_ip_tcp:myserver[1024,sign,seal]
#
#    ncalrpc:
#
#The UNC format is:
#
#  //server/share
#
#Tests are:

doTests()
{
    while (( "$#" )); do        # While there are arguments still to be shifted
        timeout --preserve-status 60 smbtorture //127.0.0.1/IPC$ "$1" >"/tmp/${1}.log" 2>&1
        if [ "$CDU" = 124 ]
        then
            echo "$MSG : $1 ==> Timeout !"
            cp "/tmp/${1}.log" "$VM_DIR/${1}.log"
            echo "EOLE_CI_PATH ${1}.log"
            echo "====================================================================================="
        else
            if [ "$CDU" == 0 ]
            then
                echo "$MSG : $1 ==> OK"
                echo "====================================================================================="
            else
                if grep -q "smbXcli_negprot_smb1_done: No compatible protocol selected by server" "/tmp/${1}.log"
                then
                    echo "$MSG : $1 ==> ignoré SMB1 !"
                else
                    if grep -q "_smb1_" "/tmp/${1}.log"
                    then
                        echo "$MSG : $1 ==> NOK SMB1 !"
                        cp "/tmp/${1}.log" "$VM_DIR/${1}.log"
                        echo "EOLE_CI_PATH ${1}.log"
                        echo "====================================================================================="
                    else
                        echo "$MSG : $1 ==> NOK ($CDU)"
                        echo "====================================================================================="
                    fi
                fi 
            fi
        fi
        shift
    done
}

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY
ciInitOutput
ciInstallPaquet samba-testsuite

MSG="Basic SMB tests (imported from the original smbtorture) (base):"

cd /tmp ||exit 1

#doTests base.lock base.delete base.charset base.delaywrite base.aliases base.fdpass 
#doTests base.unlink base.attr base.trans2 base.birthtime base.negnowait base.dir1 
#doTests base.dir2 base.deny1 base.deny2 base.deny3 base.denydos base.ntdeny1 
#doTests base.ntdeny2 base.tcon base.tcondev base.vuid base.rw1 base.open 
#doTests base.defer_open base.xcopy base.iometer base.rename base.properties 
#doTests base.mangle base.openattr base.winattr base.chkpath base.secleak 
#doTests base.disconnect base.samba3error base.casetable base.utable base.smb 
#doTests base.trans2-scan base.nttrans base.createx_access 
#doTests base.createx_sharemodes_file base.createx_sharemodes_dir base.maximum_allowed 
#doTests base.bench-holdcon base.bench-holdopen base.bench-readwrite 
#doTests base.bench-torture base.scan-pipe_number base.scan-ioctl base.scan-maxfid 

#MSG="Tests for the raw SMB interface (raw):"
#doTests raw.sfileinfo raw.search raw.open raw.oplock raw.notify raw.unlink raw.read 
#doTests raw.write raw.lock raw.context raw.session raw.rename raw.streams raw.acls 
#doTests raw.composite raw.bench-oplock raw.ping-pong raw.bench-lock raw.bench-open 
#doTests raw.bench-lookup raw.bench-tcon raw.offline raw.qfsinfo raw.qfileinfo 
#doTests raw.qfileinfo.ipc raw.close raw.mkdir raw.hold-oplock raw.mux raw.ioctl 
#doTests raw.chkpath raw.seek raw.eas raw.samba3hide raw.samba3closeerr 
#doTests raw.samba3rootdirfid raw.samba3checkfsp raw.samba3oplocklogoff 
#doTests raw.samba3badnameblob raw.samba3badpath raw.samba3caseinsensitive 
#doTests raw.samba3posixtimedlock raw.scan-eamax 

MSG="SMB2-specific tests (smb2):"
doTests smb2.scan smb2.getinfo smb2.lock smb2.read smb2.aio_delay smb2.create 
doTests smb2.twrp smb2.fileid smb2.acls smb2.notify smb2.notify-inotify 
doTests smb2.change_notify_disabled smb2.durable-open smb2.durable-open-disconnect 
doTests smb2.durable-v2-open smb2.durable-v2-delay smb2.dir smb2.lease smb2.compound 
doTests smb2.compound_find smb2.oplock smb2.kernel-oplocks smb2.streams smb2.ioctl 
doTests smb2.rename smb2.sharemode smb2.session smb2.replay smb2.credits 
doTests smb2.delete-on-close-perms smb2.multichannel smb2.samba3misc smb2.connect 
doTests smb2.setinfo smb2.set-sparse-ioctl smb2.zero-data-ioctl smb2.bench-oplock 
doTests smb2.hold-oplock smb2.dosmode smb2.maxfid smb2.hold-sharemode 
doTests smb2.check-sharemode 

MSG="WINBIND tests (winbind):"
doTests winbind.struct winbind.wbclient winbind.pac 

MSG="libnetapi convenience interface tests (netapi):"
doTests netapi.server netapi.group netapi.user netapi.initialize 

MSG="libsmbclient interface tests (libsmbclient):"
doTests libsmbclient.version libsmbclient.initialize libsmbclient.configuration 
doTests libsmbclient.setConfiguration libsmbclient.options libsmbclient.opendir 
doTests libsmbclient.list_shares libsmbclient.readdirplus 
doTests libsmbclient.readdirplus_seek 

MSG="Group Policy tests (gpo):"
doTests gpo.apply 

MSG="DCE/RPC protocol and interface tests (rpc):"
doTests rpc.lsa.lookupsids rpc.lsa.lookupnames rpc.lsa.secrets 
doTests rpc.lsa.trusted.domains rpc.lsa.forest.trust rpc.lsa.privileges rpc.echo 
doTests rpc.dfs rpc.frsapi rpc.unixinfo rpc.eventlog rpc.atsvc rpc.wkssvc rpc.handles 
doTests rpc.objectuuid rpc.winreg rpc.spoolss rpc.spoolss.win rpc.spoolss.driver 
doTests rpc.spoolss.access rpc.iremotewinspool rpc.iremotewinspool_driver 
doTests rpc.netlogon rpc.netlogon-s3 rpc.netlogon.admin rpc.pac rpc.srvsvc rpc.svcctl 
doTests rpc.samr.accessmask rpc.samr.machine.auth rpc.samr.passwords.pwdlastset 
doTests rpc.samr.passwords.badpwdcount rpc.samr.passwords.lockout 
doTests rpc.samr.passwords.validate rpc.samr.users.privileges rpc.samr.large-dc 
doTests rpc.samr.priv rpc.epmapper rpc.initshutdown rpc.oxidresolve rpc.remact 
doTests rpc.samba3 rpc.dssetup rpc.browser rpc.ntsvcs rpc.bind rpc.backupkey 
doTests rpc.fsrvp rpc.clusapi rpc.witness rpc.lsa rpc.lsalookup rpc.lsa-getuser 
doTests rpc.samr rpc.samr.users rpc.samr.passwords rpc.samlogon rpc.samsync 
doTests rpc.schannel rpc.schannel2 rpc.bench-schannel1 rpc.schannel_anon_setpw 
doTests rpc.mgmt rpc.scanner rpc.countcalls rpc.authcontext rpc.drsuapi 
doTests rpc.drsuapi_w2k8 rpc.cracknames rpc.altercontext rpc.join rpc.dsgetinfo 
doTests rpc.bench-rpc rpc.asyncbind 

MSG="DRSUAPI RPC Tests Suite (drs.rpc):"
doTests drs.rpc.dssync drs.rpc.msDSIntId 

MSG="DRSUAPI Unit Tests Suite (drs.unit):"
doTests drs.unit.prefixMap drs.unit.schemaInfo 

MSG="Tests for the BIND 9 DLZ module (dlz_bind9):"
doTests dlz_bind9.version dlz_bind9.create dlz_bind9.configure 
doTests dlz_bind9.destroyoldestfirst dlz_bind9.destroynewestfirst 
doTests dlz_bind9.multipleconfigure dlz_bind9.gssapi dlz_bind9.spnego 
doTests dlz_bind9.lookup dlz_bind9.zonedump dlz_bind9.update01 

MSG="Tests for the internal DNS server (dns_internal):"
doTests dns_internal.queryself dns_internal.updateself 

MSG="Remote Administration Protocol tests (rap):"
doTests rap.basic rap.rpc rap.printing rap.sam rap.scan 

MSG="DFS referrals calls (dfs):"
doTests dfs.domain 

MSG="Local, Samba-specific tests (local):"
doTests local.binding local.ntlmssp local.smbencrypt local.messaging local.irpc 
doTests local.strlist local.file local.str local.time local.datablob local.binsearch 
doTests local.asn1 local.anonymous_shared local.strv local.strv_util local.util 
doTests local.idtree local.dlinklist local.genrand local.iconv local.socket local.pac 
doTests local.resolve local.sddl local.ndr local.tdr local.share local.loadparm 
doTests local.charset local.convert_string_handle local.convert_string 
doTests local.string_case_handle local.string_case_handle local.compression 
doTests local.event local.tevent_req local.torture local.dbspeed local.credentials 
doTests local.ldb local.dsdb.dn local.dsdb.syntax local.registry local.verif_trailer 
doTests local.nss local.fsrvp_state local.util_str_escape local.tfork local.talloc 
doTests local.replace local.crypto.md4 local.crypto.aes_cmac_128 
doTests local.crypto.aes_ccm_128 local.crypto.aes_gcm_128 

MSG="Kerberos tests (krb5):"
doTests krb5.kdc 

MSG="Benchmarks (bench):"
doTests bench.nbench 

MSG="CIFS UNIX extensions tests (unix):"
doTests unix.whoami unix.info2 

MSG="LDAP and CLDAP tests (ldap):"
doTests ldap.bench-cldap ldap.basic ldap.sort ldap.cldap ldap.netlogon-udp 
doTests ldap.netlogon-tcp ldap.schema ldap.uptodatevector ldap.nested-search 

MSG="NetBIOS over TCP/IP and WINS tests (nbt):"
doTests nbt.register nbt.wins nbt.dgram nbt.winsreplication nbt.bench nbt.bench-wins 

MSG="libnet convenience interface tests (net):"
doTests net.userinfo net.useradd net.userdel net.usermod net.domopen net.groupinfo 
doTests net.groupadd net.api.lookup net.api.lookuphost net.api.lookuppdc 
doTests net.api.lookupname net.api.createuser net.api.deleteuser net.api.modifyuser 
doTests net.api.userinfo net.api.userlist net.api.groupinfo net.api.grouplist 
doTests net.api.creategroup net.api.rpcconn.bind net.api.rpcconn.srv 
doTests net.api.rpcconn.pdc net.api.rpcconn.dc net.api.rpcconn.dcinfo 
doTests net.api.listshares net.api.delshare net.api.domopenlsa net.api.domcloselsa 
doTests net.api.domopensamr net.api.domclosesamr net.api.become.dc net.api.domlist 

MSG="NTP tests (ntp):"
doTests ntp.signd 

MSG="VFS modules tests (vfs):"
doTests vfs.fruit vfs.fruit_netatalk vfs.acl_xattr vfs.fruit_file_id 
doTests vfs.fruit_timemachine vfs.fruit_conversion 

MSG="DSDB tests (dsdb):"
doTests dsdb.no_attrs 

MSG="libcli/echo interface tests (echo):"
doTests echo.udp 

MSG="The default test is ALL."
