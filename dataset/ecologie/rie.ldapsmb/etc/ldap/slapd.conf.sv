# This is the main slapd configuration file. See slapd.conf(5) for more
# info on the configuration options.

#######################################################################
# Global Directives:

# Features to permit
allow bind_v2

# Schema and objectClass definitions
include         /etc/ldap/schema/core.schema
include         /etc/ldap/schema/cosine.schema
include         /etc/ldap/schema/nis.schema
include         /etc/ldap/schema/inetorgperson.schema
include		/etc/ldap/schema/pamela.schema
include		/etc/ldap/schema/rfc2739.schema
include         /etc/ldap/schema/samba.schema

# Schema check allows for forcing entries to
# match schemas for their objectClasses's
#schemacheck     on

# nombre de reponses retourner par requete
sizelimit	20000
timelimit       15
#cg idletimeout     10
idletimeout     300

# Where the pid file is put. The init.d script
# will not stop the server if you change this.
pidfile         /var/run/slapd/slapd.pid

# List of arguments that were passed to the server
argsfile        /var/run/slapd/slapd.args

# Read slapd.conf(5) for possible values
#loglevel        stats
loglevel        stats stats2

# Nombre de connexion
conn_max_pending        3000
conn_max_pending_auth   5000

tool-threads 2
# Lors de la modification de threads, pensez a modifier dbconfig set_tx_max dans
# le slapd.conf dbconfig et dans le DB_CONFIG avec un dbX.Y_recover -e
# avec la valeur dbconfig set_tx_max=3*threads (source openldap)
# http://ti2appli.appli.i2/mantis/view.php?id=2345
threads 32

# Where the dynamically loaded modules are stored
modulepath	/usr/lib/ldap
moduleload	back_hdb
moduleload      back_monitor

# base de recherche par defaut
defaultsearchbase	"dc=equipement,dc=gouv,dc=fr"

# TLS
#pnesr TLSCACertificateFile	/etc/certs/CA2010.pem
#pnesr TLSCertificateFile	/etc/certs/ldapsmbpnes-ida01.ida.melanie2.i2.pem
#pnesr TLSCertificateKeyFile	/etc/certs/ldapsmbpnes-ida01.ida.melanie2.i2.key
TLSCACertificateFile    /etc/certs/CAldap.pem
TLSCertificateFile      /etc/certs/ldapsmb.eole.e2.rie.gouv.fr-cert.pem
TLSCertificateKeyFile   /etc/certs/ldapsmb.eole.e2.rie.gouv.fr-key.pem


#######################################################################
# Specific Backend Directives for bdb:
# Backend specific directives apply to this backend until another
# 'backend' directive occursi
# backend		bdb
# Les alias ne marche pas avce openldap 2.1 et une base BDB. Il faut
# donc utiliser une base ldbm.
# Ce problème est corrigé avec une openldap 2.2.
#backend		bdb

#######################################################################
# Specific Backend Directives for 'other':
# Backend specific directives apply to this backend until another
# 'backend' directive occurs
#backend		<other>

#######################################################################
# Specific Directives for database #1, of type bdb:
# Database specific directives apply to this databasse until another
# 'database' directive occurs
database        hdb

#dbnosync
#cachesize 10000

# The base of your directory in database #1
suffix          "dc=equipement,dc=gouv,dc=fr"
rootdn          "dc=equipement,dc=gouv,dc=fr"

limits dn.exact="cn=admin,ou=admin,ou=ressources,dc=equipement,dc=gouv,dc=fr"
        size.soft=unlimited size.hard=unlimited
        time.soft=unlimited time.hard=unlimited

#PAMELA_LDAP_LIMITS

syncrepl rid=1
        provider=ldaps://ldapma.eole.e2.rie.gouv.fr
        type=refreshAndPersist
        retry="10 3 30 3 60 +"
        searchbase="dc=equipement,dc=gouv,dc=fr"
        filter="(objectClass=*)"
        scope=sub
        schemachecking=off
        bindmethod=simple
        binddn="cn=syncuser.testpnes,ou=admin,ou=ressources,dc=equipement,dc=gouv,dc=fr"
        credentials=eole
	tls_reqcert=never
updateref	ldaps://ldapma.eole.e2.rie.gouv.fr

# Where the database file are physically stored for database #1
directory       "/var/lib/ldap/equipement"


# caches bases hdb dc=equipement
cachesize    75000
cachefree      1000
idlcachesize 225000
#searchstack      24
checkpoint 0 10

# Indexing options for database #1
index           objectClass eq
index           entryCSN,entryUUID eq
#Index d'apres LVG\\\\\\\\\\\\\/EOLE
########################
index cn sub,eq
index sn sub,eq
## required to support pdb_getsampwnam
index uid sub,eq
## required to support pdb_getsambapwrid()
index displayName sub,eq
## uncomment these if you are storing posixAccount and
## posixGroup entries in the directory as well
index uidNumber eq
index gidNumber eq
index memberUid eq

#cg
index member eq

index sambaSID eq,sub
index sambaPrimaryGroupSID eq
index sambaDomainName eq
index uniqueMember eq
index info eq
index ipHostNumber eq

#Ajout PAMELA
#############
#Samba par examen des log
index sambaSIDList eq
index sambaGroupType eq
#Ces besoins devront etre revalides

# Save the time that the entry gets modified, for database #1
lastmod         on

# Where to store the replica logs for database #1
# replogfile	/var/lib/ldap/replog

access to filter=(gidNumber=99999)
        by dn="cn=admin,ou=admin,ou=ressources,dc=equipement,dc=gouv,dc=fr" read
        by * none

access to filter=(uid=zcompteur)
        by dn="cn=admin,ou=admin,ou=ressources,dc=equipement,dc=gouv,dc=fr" read
        by * none

include         /etc/ldap/acl-ldapsmb.conf

# The userPassword by default can be changed
# by the entry owning it if they are authenticated.
# Others should not be able to see it, except the
# admin entry below
# These access lines apply to database #1 only
access to attrs=userPassword
        by dn="cn=admin,ou=admin,ou=ressources,dc=equipement,dc=gouv,dc=fr" read
        by anonymous peername.ip=127.0.0.1 auth
        by anonymous peername.ip=172.26.46.240/255.255.255.240 auth
        by anonymous peername.ip=172.26.62.0/255.255.255.254 auth
        by self peername.ip=127.0.0.1 read
        by self peername.ip=172.26.46.240/255.255.255.240 read
        by self peername.ip=172.26.62.0/255.255.255.254 read
        by * none

# Ensure read access to the base for things like
# supportedSASLMechanisms.  Without this you may
# have problems with SASL not knowing what
# mechanisms are available and the like.
# Note that this is covered by the 'access to *'
# ACL below too but if you change that as people
# are wont to do you'll still need this if you
# want SASL (and possible other things) to work 
# happily.
access to dn.base=""        by * none

# The admin dn has full write access, everyone else
# can read everything.
access to *
        by dn="cn=admin,ou=admin,ou=ressources,dc=equipement,dc=gouv,dc=fr" read
        by peername.ip=127.0.0.1 read
        by peername.ip=172.26.46.240/255.255.255.240 read
        by peername.ip=172.26.62.0/255.255.255.254 read
        by * none

# For Netscape Roaming support, each user gets a roaming
# profile for which they have write access to
#access to dn=".*,ou=Roaming,o=morsnet"
#        by dn="cn=admin,dc=equipement,dc=gouv,dc=fr" write
#        by dnattr=owner write

#dbconfig set_flags DB_TXN_NOSYNC
dbconfig set_cachesize 0 100000000 1
dbconfig set_lg_regionmax 2097152
dbconfig set_lg_max 20971520
dbconfig set_lg_bsize 4194304
dbconfig set_lk_max_locks 30000
dbconfig set_lk_max_lockers 30000
dbconfig set_lk_max_objects 30000
dbconfig set_flags DB_LOG_AUTOREMOVE
dbconfig set_tx_max 96

#######################################################################
# Specific Directives for database #2, of type 'other' (can be bdb too):
# Database specific directives apply to this databasse until another
# 'database' directive occurs
#database        <other>

# The base of your directory for database #2
#suffix		"dc=debian,dc=org"

database        monitor

access to dn.subtree="cn=monitor"
        by peername.ip=127.0.0.1 read
        by * none

