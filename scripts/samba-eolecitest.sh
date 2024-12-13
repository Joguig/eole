#!/bin/bash

function ciWsddContextualize()
{
    ciPrintConsole "Début ciWsddContextualize"

    ciGetNamesInterfaces
    
    echo "* stop service systemd : wsdd"
    systemctl stop wsdd.service 2>/dev/null

    /bin/cp "$VM_DIR_EOLE_CI_TEST/scripts/wsdd.py" /usr/bin/wsdd
    chmod 755 /usr/bin/wsdd

	SMB_GROUP=$(samba-tool testparm --suppress-prompt --parameter-name='workgroup' 2>/dev/null)
	SMB_NAME=$(samba-tool testparm --suppress-prompt --parameter-name='netbios name' 2>/dev/null)
    cat >/etc/default/wsdd <<EOF
# Additional arguments for wsdd can be provided here.
# Use, e.g., "-i eth0" to restrict operations to a specific interface
# Refer to the wsdd(8) man page for details
WSDD_PARAMS="-i $VM_INTERFACE0_NAME -v -w $SMB_GROUP -n $SMB_NAME -4"
EOF

    cat >/etc/systemd/system/wsdd.service <<EOF
[Unit]
Description=Web Services Dynamic Discovery host daemon
Documentation=man:wsdd(8)
After=network-online.target
Wants=network-online.target
BindsTo=smbd.service

[Service]
Type=simple
EnvironmentFile=/etc/default/wsdd
; The service is put into an empty runtime directory chroot,
; i.e. the runtime directory which usually resides under /run
ExecStart=/usr/bin/python3.10 /usr/bin/wsdd -i $VM_INTERFACE0_NAME -v -w $SMB_GROUP -n $SMB_NAME -4
AmbientCapabilities=CAP_SYS_CHROOT

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 /etc/systemd/system/wsdd.service
    systemctl daemon-reload
    
    echo "* enable service systemd : wsdd"
    systemctl enable wsdd.service
    
    echo "* Start service systemd : wsdd"
    systemctl restart wsdd.service

    systemctl is-active wsdd.service
    
    echo "* Status service systemd : wsdd"
    journalctl -u wsdd.service --no-pager
    
    ciPrintConsole "Fin ciWsddContextualize : ok"
}
export -f ciWsddContextualize

############################################################################################
#
# Contextualisation machine 'EOLECITEST'
#
############################################################################################
function ciSambaContextualize()
{
    ciPrintConsole "Début ciSambaContextualize"

    ciGetNamesInterfaces
    
    if [ ! -d /home/sauvegardes ]
    then
        echo "* mkdir -p /home/sauvegardes"
        mkdir -p /home/sauvegardes
        chmod 777 /home/sauvegardes
    fi

    /bin/cp "$VM_DIR_EOLE_CI_TEST/scripts/hook_dynlogon" /root/hook_dynlogon
    chmod 755 /root/hook_dynlogon
    
    ciPrintConsole "Configuration SMB (interface=$VM_INTERFACE0_NAME)"
    cat >/etc/samba/smb.conf <<EOF
[global]
        workgroup = WORKGROUP
        # SMB uses ports 139 & 445, as explained in this blog post
        disable netbios = Yes
        smb ports = 445 139
        netbios name = EOLECITESTS
        server string = Samba Server %v
        #unix extensions = No
        #wide links = Yes
        restrict anonymous = 2
        map to guest = never
        #client min protocol = SMB2
        #usershare allow guests = no
        
        #bind interfaces only = yes
        #interfaces = lo $VM_INTERFACE0_NAME
 
        root preexec = /root/hook_dynlogon "ROOT_PREEXEC " "%U" "%a" "%m" "%I" "%d" "%T" "%u" "%M" "%R" "%H"
        root postexec = /root/hook_dynlogon "ROOT_POSTEXEC" "%U" "%a" "%m" "%I" "%d" "%T" "%u" "%M" "%R" "%H"
        log level = 0 tdb:0 printdrivers:0 lanman:0 smb:5 rpc_parse:0 rpc_srv:0 rpc_cli:0 passdb:0 sam:0 auth:0 winbind:0 vfs:0 idmap:0 quota:0 acls:0 locking:0 msdfs:0 dmapi:0 registry:0 scavenger:0 dns:0 ldb:0
        #log level = 5
        log file = /var/log/samba/samba-%I.log
        max log size = 0
        include = /etc/samba/smb.conf.client-%I
        
        #local master = no
        #domain master = no
        usershare max shares = 0
        
        #vfs objects = aio_pthread
        # FORCE THE DISK SYSTEM TO ALLOCATE REAL STORAGE BLOCKS WHEN A FILE IS CREATED OR EXTENDED TO BE A GIVEN SIZE.
        # THIS IS ONLY A GOOD OPTION FOR FILE SYSTEMS THAT SUPPORT UNWRITTEN EXTENTS LIKE XFS, EXT4, BTRFS, OCS2.
        # NOTE: MAY WASTE DRIVE SPACE EVEN ON SUPPORTED FILE SYSTEMS SEE: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=798532
        #strict allocate = Yes

        # THIS IS TO COUNTERACT SPACE WASTAGE THAT CAN BE CAUSED BY THE PREVIOUS OPTION SEE: https://lists.samba.org/archive/samba-technical/2014-July/101304.html
        #allocation roundup size = 4096
    
        # ALLOW READS OF 65535 BYTES IN ONE PACKET. THIS TYPICALLY PROVIDES A MAJOR PERFORMANCE BENEFIT.
        #read raw = Yes
        # SUPPORT RAW WRITE SMBs WHEN TRANSFERRING DATA FROM CLIENTS.
        #write raw = Yes
       
        # SERVER SIGNING SLOWS THINGS DOWN WHEN ENABLED. THIS WAS DISABLED BY DEFAULT PRIOR TO SAMBA 4. Thanks to Joe in the comments section!
        #server signing = No
       
        # WHEN "strict locking = no", THE SERVER PERFORMS FILE LOCK CHECKS ONLY WHEN THE CLIENT EXPLICITLY ASKS FOR THEM.
        # WELL-BEHAVED CLIENTS ALWAYS ASK FOR LOCK CHECKS WHEN IT IS IMPORTANT, SO IN THE VAST MAJORITY OF CASES,
        # "strict locking = auto" OR "strict locking = no" IS ACCEPTABLE.
        strict locking = No
        oplocks = False
        level2 oplocks = False
    
        # TCP_NODELAY: SEND AS MANY PACKETS AS NECESSARY TO KEEP DELAY LOW
        # IPTOS_LOWDELAY: [Linux IPv4 Tweak] MINIMIZE DELAYS FOR INTERACTIVE TRAFFIC
        # SO_RCVBUF: ENLARGE SYSTEM SOCKET RECEIVE BUFFER
        # SO_SNDBUF: ENLARGE SYSTEM SOCKET SEND BUFFER
        #SO_RCVBUF=131072 SO_SNDBUF=131072
        #socket options = TCP_NODELAY IPTOS_LOWDELAY 
    
        # SMBWriteX CALLS GREATER THAN "min receivefile size" WILL BE
        # PASSED DIRECTLY TO KERNEL recvfile/splice SYSTEM CALL.
        # TO ENABLE POSIX LARGE WRITE SUPPORT (SMB/CIFS WRITES UP TO 16MB),
        # THIS OPTION MUST BE NONZERO.
        # THIS OPTION WILL HAVE NO EFFECT IF SET ON A SMB SIGNED CONNECTION.
        # MAX VALUE = 128k
        #min receivefile size = 16384
        # USE THE MORE EFFICIENT sendfile() SYSTEM CALL FOR EXCLUSIVELY OPLOCKED FILES.
        #use sendfile = Yes inutil avec AIO
    
        # NOTE: SAMBA MUST BE BUILT WITH ASYNCHRONOUS I/O SUPPORT
        #aio read size = 16384 # READ FROM FILE ASYNCHRONOUSLY WHEN SIZE OF REQUEST IS BIGGER THAN THIS VALUE.
        #aio write size = 16384 # WRITE TO FILE ASYNCHRONOUSLY WHEN SIZE OF REQUEST IS BIGGER THAN THIS VALUE
        #server multi channel support = yes  (samba >4.4)
        #aio read size = 1
        #aio write size = 1

        #disable printer ...
        load printers = no
        printing = bsd
        printcap name = /dev/null
        disable spoolss = yes
        
        # je désactive tous les acl !!!
        nt acl support = no
  
[eolecitests]
        path = $VM_DIR_EOLE_CI_TEST
        read only = No
        valid users = root
        force create mode = 0777
        force directory mode = 2777
        printable = no
        map acl inherit = yes
        inherit acls = yes        

[wpkg]
        path = /home/wpkg
        read only = No
        valid users = root
        printable = no

[sauvegardes]
        path = /home/sauvegardes
        read only = No
        valid users = root
        printable = no
EOF

	if testparm -v -p -s >/tmp/testparm.log  2>/tmp/testparm.err
	then
        echo "* testparm ok"
	else
        echo "* testparm NOK"
        return
	fi

    echo "* stop service systemd : wsdd"
    systemctl stop wsdd.service 2>/dev/null

    #ciWsddContextualize
    
    ciPrintConsole "Fin ciSambaContextualize : ok"
}
export -f ciSambaContextualize

############################################################################################
#
# Configuration machine 'EOLECITEST'
#
############################################################################################
function ciSambaConfiguration()
{
    ciPrintConsole "Début ciSambaConfiguration"

    ciPrintConsole "Check hostname eolecitest"
    cat /etc/hosts

    ciConfigureAutomatiqueMinimale

    ciPrintConsole "hostnamectl set-hostname eolecitest"
    # obligatoire, car le hostname par défaut peut avoir plus de 15 car ....
    if [ "$(hostname)" != "eolecitests" ]
    then
        hostnamectl set-hostname eolecitest
    fi
    
    ciSambaRestart
    
    ciPrintConsole "Creation compte samba admin, nobody"
    smbpasswd -an nobody
    if ! id pcadmin >/dev/null
    then
        useradd pcadmin
    fi

    # "-d /mnt" permet le montage \\sshfs\pcadmin@<gw>\eole-ci-tests depuis les postes Windows
    usermod pcadmin -d /mnt

    printf 'eole\neole' | passwd pcadmin
    printf 'eole\neole' | smbpasswd -s -a pcadmin
    
    ciPrintConsole "Creation compte samba root"
    printf 'eole\neole' | smbpasswd -s -a root 

    ciSambaCheckAcces

    #ciPrintConsole "nfs-kernel-server"
    #if ! command -v /usr/sbin/rpc.nfsd  
    #then
    #    ciSetHttproxy
    #    apt-get install nfs-kernel-server -y
    #fi

    #ciPrintConsole "Export /mnt/eole-ci-tests en NFS"
    #ciGetNamesInterfaces
    #ciGetCurrentIp
    #IFS=. read -r i1 i2 i3 i4 <<< "${IP}"
    #echo $i1.$i2.$i3
    #cat >>/etc/exports <<EOF
#/mnt/eole-ci-tests $i1.$i2.$i3.0/24(rw,all_squash,anonuid=1000,anongid=1000,sync,no_subtree_check)
#EOF
    #service nfs-kernel-server reload
    #showmount -e

    #ciExportCurrentStatus
    
    #echo "* cat /etc/systemd/system/network-online.target.wants/networking.service"
    #cat /etc/systemd/system/network-online.target.wants/networking.service

    ciPrintConsole "Fin ciSambaConfiguration : ok"
}
export -f ciSambaConfiguration

############################################################################################
#
# restart samba 'EOLECITEST'
#
############################################################################################
function ciSambaRestart()
{
    ciPrintConsole "ciSambaRestart"
    local CDU=0
    local HOST_TO_TEST="${1:-localhost}"
    
    if [ "$(samba-tool testparm --parameter-name='server role' 2>/dev/null | tail -1)" = "active directory domain controller" ]
    then
         exit 0
    fi

    NMBD_DISABLED="$(samba-tool testparm --parameter-name='disable netbios' 2>/dev/null)"
    
    ciPrintConsole "Arret SAMBA"
    service nmbd stop 2>/dev/null
    service smbd stop 2>/dev/null
    service winbind stop 2>/dev/null
    
    # cleear log ...
    rm -rf /var/log/samba/samba.log
    
    ciPrintConsole "Démarrage SAMBA"
    service smbd start
    if [ "$NMBD_DISABLED" != Yes ] 
    then
        service nmbd start 2>/dev/null
    fi
    service winbind start
    
    if ! ciWaitTcpPort "$HOST_TO_TEST" 445 10
    then
        CDU=1
        ciSambaStatus
    fi
    
    if [ "$NMBD_DISABLED" != Yes ] 
    then
        if ! ciWaitTcpPort "$HOST_TO_TEST" 139 10
        then
            CDU=2
            ciSambaStatus
        fi
    fi
    
    ( 
    echo "**************************************************************"
    if command -v samba 
    then
        samba -b
    fi
    echo "**************************************************************"
    if command -v smbd
    then
        smbd -b
    fi
    ) >>"$VM_DIR/samba_build_options.log" 2>&1
    
    ciPrintConsole "ciSambaRestart : ok $CDU"
    return $CDU
}
export -f ciSambaRestart

############################################################################################
#
# check samba 'EOLECITEST'
#
############################################################################################
function ciSambaCheckAndRestartIfNeeded()
{
    ciPrintConsole "Début ciSambaCheckAndRestartIfNeeded"
    local CDU=0
    
    if ciWaitTcpPort localhost 445 2
    then
        ciPrintMsgMachine "samba localhost 445 ok"
    else
        ciPrintMsgMachine "samba localhost ERREUR"
        ciSignalWarning "Redémarrage de samba car manquant !"
        ciSambaRestart
    fi
    ciPrintConsole "ciSambaCheckAndRestartIfNeeded : ok $CDU"
    return $CDU
}
export -f ciSambaCheckAndRestartIfNeeded
    
############################################################################################
#
# check acces samba 'EOLECITEST'
#
############################################################################################
function ciSambaCheckAcces()
{
    local HOST_TO_TEST="${1:-localhost}"
    ciPrintConsole "Début ciSambaCheckAcces ${HOST_TO_TEST}"
    
    ciPrintConsole "Check smbclient"
    if ! command -v smbclient >/dev/null 2>/dev/null
    then
        apt-get -y --force-yes install smbclient
    fi
    
    # biarrement, il faut attendre la 2eme tentative pour le OK !
    for iter in $(seq 1 3)
    do
        ciPrintConsole "Check SAMBA $iter $HOST_TO_TEST"
        if smbclient -L "$HOST_TO_TEST" -Uroot%eole -m SMB3
        then
            ciPrintConsole "ciSambaCheckAcces : Ok"
            return 0
        else
            ciPrintConsole "ciSambaCheckAcces : erreur $HOST_TO_TEST $?"
        fi
    done
    
    ciSambaStatus
    ciPrintConsole "ciSambaCheckAcces : exit=1"
    return 1
}
export -f ciSambaCheckAcces

############################################################################################
#
# check acces samba 'EOLECITEST'
#
############################################################################################
function ciSambaStatus()
{
    ciPrintConsole "Début ciSambaStatus"
    local CDU=0
    
    ciPrintConsole "lsof"
    lsof -ni :139,445
    
    ciPrintConsole "netstat"
    (command -v netstat || apt-get install -y net-tools ) >/dev/null
    netstat -ntlp | grep '445\|139'

    ciPrintConsole "ps fax"
    # shellcheck disable=SC2009
    ps fax | grep 'samba\|smbd\|nmbd\|winbindd' | grep -v grep
    
    ciPrintConsole "ciSambaStatus : exit=$CDU"
    return $CDU
}
export -f ciSambaStatus

############################################################################################
#
# export samba 
#
############################################################################################
function ciSambaExport()
{
    DESTINATION="$VM_DIR/${1}"
    mkdir -p "${DESTINATION}"
    echo "* Export samba dans ${DESTINATION}"
    
    for f in /var/lib/samba/private/sam.ldb /var/lib/samba/private/sam.ldb.d/*
    do
        nom=$(basename "$f")
        nom=${nom,,}
        echo "$nom" 
        ldbsearch -H "$f" "*" -o ldif-wrap=no | python3 "${VM_DIR_EOLE_CI_TEST}/scripts/ldbsearchUnWrap.py" >"${DESTINATION}/${nom}.ldif"
    done
}
export -f ciSambaExport

############################################################################################
#
# active logs
#
############################################################################################
function ciSambaActivateLogs()
{
    cat >/etc/samba/smb.conf.client-debug <<EOF
[global]
    # no log file size limitation
    max log size = 0
    # specific log file name
    log file = /var/log/samba/log.%I
    # set the debug level
    log level = 10
    # add the pid to the log
    debug pid = yes
    # add the uid to the log
    debug uid = yes
    # add the debug class to the log
    debug class = yes
    # add microsecond resolution to timestamp
    debug hires timestamp = yes
EOF

    if ! grep -q "smb.conf.client" /etc/samba/smb.conf ; 
    then
        sed -e '/[global]/a #include = /etc/samba/smb.conf.client-%I#' /etc/samba/smb.conf
    fi
}
export -f ciSambaActivateLogs


############################################################################################
#
# samba tool usage 
#
############################################################################################
function ciSambaUsage()
{
    echo "usage:"
    echo "    --configuration "
    echo "    --contextualize "
    echo "    --restart "
    echo "    --check "
    echo "    --check-acces <ip>"
    echo "    --export-samba <folder>"
    echo "    --logs"
    echo "    --status "
    echo "    --help "
}

############################################################################################
#
# samba tool 
#
############################################################################################
function ciSambaMain()
{
    if [ -z "$EOLE_CI_FUNCTIONS_LOADED" ]
    then
        # shellcheck disable=SC1091,SC1090
        source /root/getVMContext.sh NO_DISPLAY
    fi
    
    if [ -z "${1}" ]
    then
        ciSambaUsage
        return 1
    fi
    
    while [ -n "${1}" ]
    do
	    case "${1}" in
	        --configuration)
	            ciSambaConfiguration
	            ;;
	    
	        --contextualize)
	            ciSambaContextualize
	            ;;
	    
	        --restart)
	            shift
	            ciSambaRestart "${1}"
	            ;;
	    
	        --check)
	            ciSambaCheckAndRestartIfNeeded
	            ;;
	    
	        --check-acces)
	            shift
	            ciSambaCheckAcces "${1}"
	            ;;
	            
	        --export-samba)
	            shift
	            ciSambaExport "${1}"
	            ;;
	            
	        --status)
	            ciSambaStatus
	            ;;
	    
	        --logs)
	            shift
	            ciSambaActivateLogs "${1}"
	            ;;
	    
	        --help)
	            ciSambaUsage
	            ;;
	            
	            
	        *)
	            ciSambaUsage
	            ;;
	    esac
	    shift
	done
	return 0
}

# execute main si non sourcé
if [[ "${BASH_SOURCE[0]}" == "$0" ]] 
then
   ciSambaMain "$@"
fi
