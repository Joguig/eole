#!/bin/bash

ADMIN_PASSWORD="Eole12345!"
EXIT_ON_ERROR="${1:-no}"
COMPARE_WITH="${2}"

if [ ! -f /etc/eole/samba4-vars.conf ]
then
    echo "Samba is disabled"
    exit 1
fi

# shellcheck disable=SC1091
. /etc/eole/samba4-vars.conf

function checkExitCode()
{
    local EC
    local MSG
    EC="${1}"
    MSG="${2}"
    if [[ "$EC" -eq 0 ]]
    then
        return 0
    fi
    if [ "$EXIT_ON_ERROR" != "no" ]
    then
        echo "Error: '$MSG' exit=$EC, arret demandé"
        bash sauvegarde-fichier.sh maj_auto
        ciCheckExitCode "$EC" 
    else
        echo "Warning: '$MSG' exit=$EC, mais je continue...."
    fi
}

if [ "$AD_SERVER_ROLE" != 'controleur de domaine' ]
then
    exit 0
fi

function checkId()
{
    local USER_NAME
    local TYPE
    local SID2UID
    local UID2SID
    local SID2NAME
    local NAME2SID
    local GID2SID
    
    USER_NAME="$1"
    TYPE="$2"
    SID=$(id -u "$USER_NAME")
    
    echo "*****************************************"
    echo "$TYPE : '$1'"
    SID2UID=""
    SID2UID=$(wbinfo --sid-to-uid="$SID")
    echo "    UID='$SID2UID'"
    # result UID (example: 3000001 )

    UID2SID=$(wbinfo --uid-to-sid="$SID2UID")
    echo "    SID=$UID2SID"
    # result SID (uid2sid) (example: checkWellKnownSecurityIdentifiers S-1-5-32-549 )

    GID2SID=$(wbinfo --gid-to-sid="$SID2UID")
    echo "    GID=$GID2SID"
    # result SID AGAIN (check)  (gid2sid) (example: checkWellKnownSecurityIdentifiers S-1-5-32-549 )

    SID2NAME=$(wbinfo --sid-to-name="$USER_NAME" |rev|cut -c3-100|rev)
    echo "    NAME=$SID2NAME"
    # result NAME (example: BUILTIN\Server Operators )

    NAME2SID=$(wbinfo --name-to-sid="$SID2NAME"| rev|cut -c15-100|rev)
    echo "    NAME2SID=$NAME2SID"
    # result SID (check) (name2sid)
    if [ "$UID2SID" != "$GID2SID" ]; 
    then
        #echo "Error, UID2SID and GID2SID are not matching, exiting now."
        return 1
    fi
    if [ "${NAME2SID}" != "${DC_SERVER_OPERATORS}" ]; 
    then
        #echo "Error, NAME2SID and DC_SERVER_OPERATORS are not matching, exiting now."
        #echo "The circle check failed, exiting now. "
        return 1
    fi
    SET_GPO_SERVER_OPER_UID="$SID2UID"
    #SET_GPO_SERVER_OPER_GID="$SID2NAME"
    echo "$SID2NAME -> $DC_SERVER_OPERATORS -> $SID2UID"
    exit 0
    return 0
}

function checkWellKnownSecurityIdentifiers()
{
    local SID
    local NAME
    local DESC
    
    SID="${1}"
    NAME="$2"
    
    if ! wbinfo -n "$NAME"
    then
        echo "'$NAME' incconu"
        return 0
    fi 
    
    _UID=$(wbinfo --sid-to-uid="$SID")
    if [ -z "$_UID" ]
    then
        return
    fi

    echo "*****************************************"
    echo "SID=$SID"
    echo "    UID=$_UID"
    UID2SID=$(wbinfo --uid-to-sid="$_UID")
    echo "    SID=$UID2SID"
set -x
    wbinfo --uid-info=$_UID
    wbinfo --gid-info=$_UID
    
    echo "$SID2NAME -> $DC_SERVER_OPERATORS -> $UID"
    return 0
}


while read -r U
do
    echo $U
    #checkId "$U" Group
done <<< $(wbinfo -g)

while read -r U
do
    echo $U
    #checkId "$U" User
done <<< $(wbinfo -u)



checkWellKnownSecurityIdentifiers S-1-0       "Null Authority" "An identifier authority."
checkWellKnownSecurityIdentifiers S-1-0-0     "Nobody"  "No security principal."
checkWellKnownSecurityIdentifiers S-1-1       "World Authority"     "An identifier authority."
checkWellKnownSecurityIdentifiers S-1-1-0     "Everyone"    "A group that includes all users, even anonymous users and guests. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-2       "Local Authority"     "An identifier authority."
checkWellKnownSecurityIdentifiers S-1-2-0     "Local"   "A group that includes all users who have logged on locally."
checkWellKnownSecurityIdentifiers S-1-3       "Creator Authority"   "An identifier authority."
checkWellKnownSecurityIdentifiers S-1-3-0     "Creator Owner"   "A placeholder in an inheritable access control entry (ACE). When the ACE is inherited, the system replaces this SID with the SID for the object's creator."
checkWellKnownSecurityIdentifiers S-1-3-1     "Creator Group"   "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the primary group of the object's creator. The primary group is used only by the POSIX subsystem."
checkWellKnownSecurityIdentifiers S-1-3-4     "Owner Rights"    "A group that represents the current owner of the object. When an ACE that carries this SID is applied to an object, the system ignores the implicit READ_CONTROL and WRITE_DAC permissions for the object owner."
checkWellKnownSecurityIdentifiers S-1-4       "Non-unique Authority"    "An identifier authority."
checkWellKnownSecurityIdentifiers S-1-5       "NT Authority"    "An identifier authority."
checkWellKnownSecurityIdentifiers S-1-5-1     "Dialup"  "A group that includes all users who have logged on through a dial-up connection. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-2     "Network"     "A group that includes all users that have logged on through a network connection. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-3     "Batch"   "A group that includes all users that have logged on through a batch queue facility. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-4     "Interactive"     "A group that includes all users that have logged on interactively. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-5-X-Y     "Logon Session"   "A logon session. The X and Y values for these SIDs are different for each session."
checkWellKnownSecurityIdentifiers S-1-5-6     "Service"     "A group that includes all security principals that have logged on as a service. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-7     "Anonymous"   "A group that includes all users that have logged on anonymously. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-9     "Enterprise Domain Controllers"   "A group that includes all domain controllers in a forest that uses an Active Directory directory service. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-10    "Principal Self"  "A placeholder in an inheritable ACE on an account object or group object in Active Directory. When the ACE is inherited, the system replaces this SID with the SID for the security principal who holds the account."
checkWellKnownSecurityIdentifiers S-1-5-11    "Authenticated Users"     "A group that includes all users whose identities were authenticated when they logged on. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-12    "Restricted Code"     "This SID is reserved for future use."
checkWellKnownSecurityIdentifiers S-1-5-13    "Terminal Server Users"   "A group that includes all users that have logged on to a Terminal Services server. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-14    "Remote Interactive Logon"    "A group that includes all users who have logged on through a terminal services logon."
checkWellKnownSecurityIdentifiers S-1-5-17    "This Organization"   "An account that is used by the default Internet Information Services (IIS) user."
checkWellKnownSecurityIdentifiers S-1-5-18    "Local System"    "A service account that is used by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-19    "NT Authority"    "Local Service"
checkWellKnownSecurityIdentifiers S-1-5-20    "NT Authority"    "Network Service"
checkWellKnownSecurityIdentifiers S-1-5-21domain-500  "Administrator"   "A user account for the system administrator. By default, it is the only user account that is given full control over the system."
checkWellKnownSecurityIdentifiers S-1-5-21domain-501  "Guest"   "A user account for people who do not have individual accounts. This user account does not require a password. By default, the Guest account is disabled."
checkWellKnownSecurityIdentifiers S-1-5-21domain-502  "KRBTGT"  "A service account that is used by the Key Distribution Center (KDC) service."
checkWellKnownSecurityIdentifiers S-1-5-21domain-512  "Domain Admins"   "A global group whose members are authorized to administer the domain. By default, the Domain Admins group is a member of the Administrators group on all computers that have joined a domain, including the domain controllers. Domain Admins is the default owner of any object that is created by any member of the group."
checkWellKnownSecurityIdentifiers S-1-5-21domain-513  "Domain Users"    "A global group that, by default, includes all user accounts in a domain. When you create a user account in a domain, it is added to this group by default."
checkWellKnownSecurityIdentifiers S-1-5-21domain-514  "Domain Guests"   "A global group that, by default, has only one member, the domain s built-in Guest account."
checkWellKnownSecurityIdentifiers S-1-5-21domain-515  "Domain Computers"    "A global group that includes all clients and servers that have joined the domain."
checkWellKnownSecurityIdentifiers S-1-5-21domain-516  "Domain Controllers"  "A global group that includes all domain controllers in the domain. New domain controllers are added to this group by default."
checkWellKnownSecurityIdentifiers S-1-5-21domain-517  "Cert Publishers"     "A global group that includes all computers that are running an enterprise certification authority. Cert Publishers are authorized to publish certificates for User objects in Active Directory."
checkWellKnownSecurityIdentifiers S-1-5-21root domain-518     "Schema Admins"   "A universal group in a native-mode domain; a global group in a mixed-mode domain. The group is authorized to make schema changes in Active Directory. By default, the only member of the group is the Administrator account for the forest root domain."
checkWellKnownSecurityIdentifiers S-1-5-21root domain-519     "Enterprise Admins"   "A universal group in a native-mode domain; a global group in a mixed-mode domain. The group is authorized to make forest-wide changes in Active Directory, such as adding child domains. By default, the only member of the group is the Administrator account for the forest root domain."
checkWellKnownSecurityIdentifiers S-1-5-21domain-520  "Group Policy Creator Owners"     "A global group that is authorized to create new Group Policy objects in Active Directory. By default, the only member of the group is Administrator."
checkWellKnownSecurityIdentifiers S-1-5-21domain-526  "Key Admins"  "A security group. The intention for this group is to have delegated write access on the msdsKeyCredentialLink attribute only. The group is intended for use in scenarios where trusted external authorities (for example, Active Directory Federated Services) are responsible for modifying this attribute. Only trusted administrators should be made a member of this group."
checkWellKnownSecurityIdentifiers S-1-5-21domain-527  "Enterprise Key Admins"   "A security group. The intention for this group is to have delegated write access on the msdsKeyCredentialLink attribute only. The group is intended for use in scenarios where trusted external authorities (for example, Active Directory Federated Services) are responsible for modifying this attribute. Only trusted administrators should be made a member of this group."
checkWellKnownSecurityIdentifiers S-1-5-21domain-553  "RAS and IAS Servers"     "A domain local group. By default, this group has no members. Servers in this group have Read Account Restrictions and Read Logon Information access to User objects in the Active Directory domain local group."
checkWellKnownSecurityIdentifiers S-1-5-32-544    "Administrators"  "A built-in group. After the initial installation of the operating system, the only member of the group is the Administrator account. When a computer joins a domain, the Domain Admins group is added to the Administrators group. When a server becomes a domain controller, the Enterprise Admins group also is added to the Administrators group."
checkWellKnownSecurityIdentifiers S-1-5-32-545    "Users"   "A built-in group. After the initial installation of the operating system, the only member is the Authenticated Users group. When a computer joins a domain, the Domain Users group is added to the Users group on the computer."
checkWellKnownSecurityIdentifiers S-1-5-32-546    "Guests"  "A built-in group. By default, the only member is the Guest account. The Guests group allows occasional or one-time users to log on with limited privileges to a computer s built-in Guest account."
checkWellKnownSecurityIdentifiers S-1-5-32-547    "Power Users"     "A built-in group. By default, the group has no members. Power users can create local users and groups; modify and delete accounts that they have created; and remove users from the Power Users, Users, and Guests groups. Power users also can install programs; create, manage, and delete local printers; and create and delete file shares."
checkWellKnownSecurityIdentifiers S-1-5-32-548    "Account Operators"   "A built-in group that exists only on domain controllers. By default, the group has no members. By default, Account Operators have permission to create, modify, and delete accounts for users, groups, and computers in all containers and organizational units of Active Directory except the Builtin container and the Domain Controllers OU. Account Operators do not have permission to modify the Administrators and Domain Admins groups, nor do they have permission to modify the accounts for members of those groups."
checkWellKnownSecurityIdentifiers S-1-5-32-549    "Server Operators"    "A built-in group that exists only on domain controllers. By default, the group has no members. Server Operators can log on to a server interactively; create and delete network shares; start and stop services; back up and restore files; format the hard disk of the computer; and shut down the computer."
checkWellKnownSecurityIdentifiers S-1-5-32-550    "Print Operators"     "A built-in group that exists only on domain controllers. By default, the only member is the Domain Users group. Print Operators can manage printers and document queues."
checkWellKnownSecurityIdentifiers S-1-5-32-551    "Backup Operators"    "A built-in group. By default, the group has no members. Backup Operators can back up and restore all files on a computer, regardless of the permissions that protect those files. Backup Operators also can log on to the computer and shut it down."
checkWellKnownSecurityIdentifiers S-1-5-32-552    "Replicators"     "A built-in group that is used by the File Replication service on domain controllers. By default, the group has no members. Do not add users to this group."
checkWellKnownSecurityIdentifiers S-1-5-32-582    "Storage Replica Administrators"  "A built-in group that grants complete and unrestricted access to all features of Storage Replica."
checkWellKnownSecurityIdentifiers S-1-5-64-10     "NTLM Authentication"     "An SID that is used when the NTLM authentication package authenticated the client."
checkWellKnownSecurityIdentifiers S-1-5-64-14     "SChannel Authentication"     "An SID that is used when the SChannel authentication package authenticated the client."
checkWellKnownSecurityIdentifiers S-1-5-64-21     "Digest Authentication"   "An SID that is used when the Digest authentication package authenticated the client."
checkWellKnownSecurityIdentifiers S-1-5-80    "NT Service"  "An NT Service account prefix."
checkWellKnownSecurityIdentifiers S-1-3-2     "Creator Owner Server"    "This SID is not used in Windows 2000."
checkWellKnownSecurityIdentifiers S-1-3-3     "Creator Group Server"    "This SID is not used in Windows 2000."
checkWellKnownSecurityIdentifiers S-1-5-8     "Proxy"   "This SID is not used in Windows 2000."
checkWellKnownSecurityIdentifiers S-1-5-15    "This Organization"   "A group that includes all users from the same organization. Only included with AD accounts and only added by a Windows Server 2003 or later domain controller."
checkWellKnownSecurityIdentifiers S-1-5-32-554    "Builtin\Pre-Windows 2000 Compatible Access"  "An alias added by Windows 2000. A backward compatibility group which allows read access on all users and groups in the domain."
checkWellKnownSecurityIdentifiers S-1-5-32-555    "Builtin\Remote Desktop Users"    "An alias. Members in this group are granted the right to log on remotely."
checkWellKnownSecurityIdentifiers S-1-5-32-556    "Builtin\Network Configuration Operators"     "An alias. Members in this group can have some administrative privileges to manage configuration of networking features."
checkWellKnownSecurityIdentifiers S-1-5-32-557    "Builtin\Incoming Forest Trust Builders"  "An alias. Members of this group can create incoming, one-way trusts to this forest."
checkWellKnownSecurityIdentifiers S-1-5-32-558    "Builtin\Performance Monitor Users"   "An alias. Members of this group have remote access to monitor this computer."
checkWellKnownSecurityIdentifiers S-1-5-32-559    "Builtin\Performance Log Users"   "An alias. Members of this group have remote access to schedule logging of performance counters on this computer."
checkWellKnownSecurityIdentifiers S-1-5-32-560    "Builtin\Windows Authorization Access Group"  "An alias. Members of this group have access to the computed tokenGroupsGlobalAndUniversal attribute on User objects."
checkWellKnownSecurityIdentifiers S-1-5-32-561    "Builtin\Terminal Server License Servers"     "An alias. A group for Terminal Server License Servers. When Windows Server 2003 Service Pack 1 is installed, a new local group is created."
checkWellKnownSecurityIdentifiers S-1-5-32-562    "Builtin\Distributed COM Users"   "An alias. A group for COM to provide computerwide access controls that govern access to all call, activation, or launch requests on the computer."
checkWellKnownSecurityIdentifiers S-1-2-1     "Console Logon"   "A group that includes users who are logged on to the physical console."
checkWellKnownSecurityIdentifiers S-1-5-21domain-498  "Enterprise Read-only Domain Controllers"     "A universal group. Members of this group are read-only domain controllers in the enterprise."
checkWellKnownSecurityIdentifiers S-1-5-21domain-521  "Read-only Domain Controllers"    "A global group. Members of this group are read-only domain controllers in the domain."
checkWellKnownSecurityIdentifiers S-1-5-21domain-571  "Allowed RODC Password Replication Group"     "A domain local group. Members in this group can have their passwords replicated to all read-only domain controllers in the domain."
checkWellKnownSecurityIdentifiers S-1-5-21domain-572  "Denied RODC Password Replication Group"  "A domain local group. Members in this group cannot have their passwords replicated to any read-only domain controllers in the domain."
checkWellKnownSecurityIdentifiers S-1-5-32-569    "Builtin\Cryptographic Operators"     "A built-in local group. Members are authorized to perform cryptographic operations."
checkWellKnownSecurityIdentifiers S-1-5-32-573    "Builtin\Event Log Readers"   "A built-in local group. Members of this group can read event logs from local computer."
checkWellKnownSecurityIdentifiers S-1-5-32-574    "Builtin\Certificate Service DCOM Access"     "A built-in local group. Members of this group are allowed to connect to Certification Authorities in the enterprise."
checkWellKnownSecurityIdentifiers S-1-5-80-0  "NT Services\All Services"    "A group that includes all service processes that are configured on the system. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-80-0  "All Services"    "A group that includes all service processes configured on the system. Membership is controlled by the operating system."
checkWellKnownSecurityIdentifiers S-1-5-83-0  "NT Virtual Machine\Virtual Machines"     "A built-in group. The group is created when the Hyper-V role is installed. Membership in the group is maintained by the Hyper-V Management Service (VMMS). This group requires the Create Symbolic Links right (SeCreateSymbolicLinkPrivilege), and also the Log on as a Service right (SeServiceLogonRight)."
checkWellKnownSecurityIdentifiers S-1-5-90-0  "Windows Manager\Windows Manager Group"   "A built-in group that is used by the Desktop Window Manager (DWM). DWM is a Windows service that manages information display for Windows applications."
checkWellKnownSecurityIdentifiers S-1-16-0    "Untrusted Mandatory Level"   "An untrusted integrity level."
checkWellKnownSecurityIdentifiers S-1-16-4096     "Low Mandatory Level"     "A low integrity level."
checkWellKnownSecurityIdentifiers S-1-16-8192     "Medium Mandatory Level"  "A medium integrity level."
checkWellKnownSecurityIdentifiers S-1-16-8448     "Medium Plus Mandatory Level"     "A medium plus integrity level."
checkWellKnownSecurityIdentifiers S-1-16-12288    "High Mandatory Level"    "A high integrity level."
checkWellKnownSecurityIdentifiers S-1-16-16384    "System Mandatory Level"  "A system integrity level."
checkWellKnownSecurityIdentifiers S-1-16-20480    "Protected Process Mandatory Level"   "A protected-process integrity level."
checkWellKnownSecurityIdentifiers S-1-16-28672    "Secure Process Mandatory Level"  "A secure process integrity level."
checkWellKnownSecurityIdentifiers S-1-5-21-domain-522     "Cloneable Domain Controllers"    "A global group. Members of this group that are domain controllers may be cloned."
checkWellKnownSecurityIdentifiers S-1-5-32-575    "Builtin\RDS Remote Access Servers"   "A built-in local group. Servers in this group enable users of RemoteApp programs and personal virtual desktops access to these resources. In Internet-facing deployments, these servers are typically deployed in an edge network. This group needs to be populated on servers running RD Connection Broker. RD Gateway servers and RD Web Access servers used in the deployment need to be in this group."
checkWellKnownSecurityIdentifiers S-1-5-32-576    "Builtin\RDS Endpoint Servers"    "A built-in local group. Servers in this group run virtual machines and host sessions where users RemoteApp programs and personal virtual desktops run. This group needs to be populated on servers running RD Connection Broker. RD Session Host servers and RD Virtualization Host servers used in the deployment need to be in this group."
checkWellKnownSecurityIdentifiers S-1-5-32-577    "Builtin\RDS Management Servers"  "A builtin local group. Servers in this group can perform routine administrative actions on servers running Remote Desktop Services. This group needs to be populated on all servers in a Remote Desktop Services deployment. The servers running the RDS Central Management service must be included in this group."
checkWellKnownSecurityIdentifiers S-1-5-32-578    "Builtin\Hyper-V Administrators"  "A built-in local group. Members of this group have complete and unrestricted access to all features of Hyper-V."
checkWellKnownSecurityIdentifiers S-1-5-32-579    "Builtin\Access Control Assistance Operators"     "A built-in local group. Members of this group can remotely query authorization attributes and permissions for resources on this computer."
checkWellKnownSecurityIdentifiers S-1-5-32-580    "Builtin\Remote Management Users"     "A built-in local group. Members of this group can access WMI resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces that grant access to the user."

echo $?    
