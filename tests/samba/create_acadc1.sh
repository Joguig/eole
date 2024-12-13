set -e

#BASE=/home/gilles/NAS1TO
BASE=/root
GW=192.168.1.1

function cloneDepot()
{
    local url
    local project
    url="$1"
    folder="$2"
    project=$(basename "$1")
    project=${project/.git/}
    echo "Actualise '$project'" 
    cd "$folder" || exit 1
    if [ ! -d "$project" ]
    then
        echo "Clone $project"
        git clone "$url"
        cd "$project" || exit 1
    else
        echo "Pull $project"
        cd "$project" || exit 1
        git checkout master
        git pull
    fi
}

mkdir "$BASE"
cd "$BASE" || exit 1

if ! command -v samba
then
	echo "Installer samba 4.11"
	exit 1
fi
if ! command -v named
then
	apt-get install -y bind9
fi

cd "$BASE/eole/" || exit 1
wget -O - https://dev-eole.ac-dijon.fr/repositories/275/download_revision?download_format=tar.gz&rev=2.7.2%2Fmaster |tar xvf
wget -O - https://dev-eole.ac-dijon.fr/git/eole-ad-dc.git "$BASE/eole/"

mkdir -p /etc/eole/
sudo cat >/etc/eole/samba4-vars.conf <<EOF
AD_REALM='domseth.ac-test.fr'
AD_DOMAIN='domseth'
AD_HOST_NAME='dc1'
AD_HOST_IP='192.168.1.5'
NOM_CARTE_NIC1='ens4'
AD_SERVER_ROLE='controleur de domaine'
BASEDN="DC=domseth,DC=ac-test,DC=fr"
NTP_SERVERS='hestia.eole.lan'
# Sur les contrôleurs de domaine donner la liste des autres contrôleurs du même domaine
AD_ADDITIONAL_DC_IP=''
# Only if role is domain controler
AD_DOMAIN_SID=''
AD_ADDITIONAL_DC='non'
AD_DNS_BACKEND='BIND9_DLZ'
# Only if role is domain controler and is additionnal DC
AD_ADMIN='Administrator'
AD_ADMIN_PASSWORD_FILE='/var/lib/samba/.eole-ad-dc'
AD_HOST_KEYTAB_FILE='/var/lib/samba/eole-ad-dc.keytab'
ACTIVER_AD_HOMES_SHARE='non'
ACTIVER_AD_PROFILES_SHARE='non'
AD_HOMES_SHARE_HOST_NAME='file'
AD_PROFILES_SHARE_HOST_NAME='file'
AD_HOME_SHARE_PATH='/home/adhomes'
AD_PROFILE_SHARE_PATH='/home/adprofiles'
AD_INSTANCE_LOCK_FILE='/var/lib/samba/.instance_ok'
AD_BACKEND_STORE='tdb'
AD_PLAINTEXT_SECRETS='non'
EOF
set -x

mkdir -p /etc/samba/
ls -l /etc/samba/
sudo chmod 755 /etc/samba/
sudo chmod 755 /var/lib/samba/private
cat /etc/samba/smb.conf ||true
sudo tee /etc/samba/smb.conf <<EOF
# Global parameters
[global]
  realm = DOMSETH.AC-TEST.FR
  workgroup = DOMSETH
  netbios name = DC1

  # disable netbios legacy protocol, only port 445 !
  disable netbios = yes
  smb ports = 445

  # protection contre 'rpcclient -U "" -c enumdomusers <ip>'
  restrict anonymous = 2

  # déactivation des partages utilsiateurs
  usershare max shares = 0

  # pas de ligne 'vfs objects = dfs_samba4 acl_xattr' sur un DC
  # pas de ligne 'store dos attributes = Yes' sur un DC
  map acl inherit = Yes
  winbind separator = /

  server role = active directory domain controller
  dns zone transfer clients = 
  server services = -dns

  # active TLS (pour LDAPS et la maj des mot de passe !
  tls enabled = yes
  tls keyfile = /var/lib/samba/private/tls/key.pem
  tls certfile = /var/lib/samba/private/tls/cert.pem
  tls cafile = /var/lib/samba/private/tls/ca.pem
  password hash userPassword schemes = CryptSHA256 CryptSHA512
  log level = 0

[netlogon]
  comment = Network Logon Service
  path = /home/sysvol/domseth.ac-test.fr/scripts
  read only = No
  guest ok = yes

[sysvol]
  comment = Sysvol Service
  path = /home/sysvol
  read only = No
  guest ok = yes
EOF

sudo tee /etc/bind/named.conf <<EOF
// This is the primary configuration file for the BIND DNS server named.
//
// Please read /usr/share/doc/bind9/README.Debian.gz for information on the
// structure of BIND configuration files in Debian, *BEFORE* you customize
// this configuration file.
//
// If you are just adding zones, please do that in /etc/bind/named.conf.local
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
include "/var/lib/samba/bind-dns/named.conf";
EOF

sudo tee /etc/bind/named.conf.options <<EOF
acl transfer_acl {
    none;
};

options {
	directory "/var/cache/bind";

	// If there is a firewall between you and nameservers you want
	// to talk to, you may need to fix the firewall to allow multiple
	// ports to talk.  See http://www.kb.cert.org/vuls/id/800113

	// If your ISP provided one or more IP addresses for stable
	// nameservers, you probably want to use them as forwarders.
	// Uncomment the following block, and insert the addresses replacing
	// the all-0's placeholder.
	forwarders {
                $GW;
	};
	forward only;

	dnssec-enable no;
	dnssec-validation no;

	allow-query {any;};

	allow-transfer {transfer_acl;};

	auth-nxdomain no;    # conform to RFC1035
	listen-on-v6 { any; };
	tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";

    # https://wiki.samba.org/index.php?title=BIND9_DLZ_DNS_Back_End&diff=prev&oldid=15767
    minimal-responses yes;	
};
EOF

sudo tee /var/lib/samba/bind-dns/named.conf <<EOF
dlz "AD DNS Zone" {
     #database "dlopen /usr/lib/x86_64-linux-gnu/samba/bind9/dlz_bind9_11.so";
     database "dlopen /usr/lib/samba/bind9/dlz_bind9_11.so";

};
EOF

sudo tee /etc/apparmor.d/local/usr.sbin.named <<EOF
# original file superseded by creole
/run/samba/winbindd/pipe rw,
/var/lib/samba/bind-dns/dns.keytab rk,
/var/lib/samba/bind-dns/named.conf r,
/var/lib/samba/bind-dns/dns/** wrk,
/usr/lib/x86_64-linux-gnu/samba/bind9/dlz_bind9_11.so m,
/usr/lib/samba/bind9/dlz_bind9_11.so m,
/usr/lib/x86_64-linux-gnu/samba/gensec/** m,
/usr/lib/x86_64-linux-gnu/samba/ldb/** m,
/usr/lib/x86_64-linux-gnu/ldb/modules/ldb/** m,
/etc/samba/smb.conf r,
/etc/samba/smb.conf.d/** r,
/var/tmp/** rwmk,
/dev/urandom rw,
EOF

sudo tee /etc/nsswitch.conf <<EOF
# /etc/nsswitch.conf
#
# Example configuration of GNU Name Service Switch functionality.
# If you have the `glibc-doc-reference' and `info' packages installed, try:
# `info libc "Name Service Switch"' for information about this file.

passwd:         compat winbind systemd
group:          compat winbind systemd
shadow:         compat
gshadow:        files

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOF

sudo systemctl reload apparmor

sudo named-checkconf
sudo systemctl restart bind9

sudo systemctl unmask samba-ad-dc.service
sudo systemctl enable samba-ad-dc.service
sudo systemctl start samba-ad-dc.service
sudo journalctl --no-pager -xe -u samba-ad-dc.service

pushd $BASE/eole/eole-ad-dc || exit 1
git checkout 2.7.2/master
git pull
popd

cp -v $BASE/eole/eole-ad-dc/lib/eole/samba4.sh .

cat >run_seth.sh <<EOF
mkdir -p /usr/lib/eole
mkdir -p /usr/share/eole/sbin
cp ./samba4.sh /usr/lib/eole/
cp $BASE/eole/eole-ad-dc/scripts/* /usr/share/eole/sbin
cp $BASE/eole/creole/lib/eole/ihm.sh /usr/lib/eole/
cp $BASE/eole/python-pyeole/bin/tcpcheck /usr/share/eole/sbin
systemctl unmask samba-ad-dc.service
systemctl enable samba-ad-dc.service
sudo chmod 755 /var/lib/samba/private
sudo chmod 755 /var/lib/samba/bind-dns
sudo chgrp bind /var/lib/samba/bind-dns
PATH=/usr/share/eole/sbin:\$PATH
. /etc/eole/samba4-vars.conf
. /usr/lib/eole/samba4.sh
set -x
samba_instance
EOF

sudo bash run_seth.sh

#
#Main commands (example: ./waf build -j4)
#  build       : build all targets
#  clean       : cleans the project
#  configure   : configures the project
#  ctags       : build 'tags' file using ctags
#  dist        : makes a tarball for distribution
#--exec-prefix=#  distcheck   : test that distribution tarball builds and installs
#  distclean   : removes build folders and data
#  etags       : build TAGS file using etags
#  install     : installs the targets on the system
#  list        : lists the targets to execute
#  pep8        : run pep8 validator
#  pydoctor    : build python apidocs
#  reconfigure : reconfigure if config scripts have changed
#  step        : executes tasks in a step-by-step fashion, for debugging
#  test        : Run the test suite (see test options below)
#  testonly    : run tests without doing a build first
#  uninstall   : removes the targets installed
#  wafdocs     : build wafsamba apidocs
#  wildcard_cmd: called on a unknown command
#
#Options:
#  --version
#            show program's version number and exit
#  -c COLORS, --color=COLORS
#            whether to use colors (yes/no/auto) [default: auto]
#  -j JOBS, --jobs=JOBS
#            amount of parallel jobs (1)
#  -k, --keep
#            continue despite errors (-kk to try harder)
#  -v, --verbose
#            verbosity level -v -vv or -vvv [default: 0]
#  --zones=ZONES
#            debugging zones (task_gen, deps, tasks, etc)
#  -h, --help
#            show this help message and exit
#  --with-libiconv=ICONV_OPEN
#            additional directory to search for libiconv
#  --without-gettext
#            Disable use of gettext
#  --enable-coverage
#            enable options necessary for code coverage reporting on selftest (default=no)
#  --disable-python
#            do not generate python modules
#  --disable-tdb-mutex-locking
#            Disable the use of pthread robust mutexes
#  --without-ldb-lmdb
#            disable new LMDB backend for LDB
#  --enable-selftest
#            enable options necessary for selftest (default=no)
#  --with-selftest-prefix=SELFTEST_PREFIX
#            specify location of selftest directory (default=./st)
#  --with-gpgme
#            Build with gpgme support (default=auto). This requires gpgme devel and python packages (e.g. libgpgme11-dev, python-gpgme on debian/ubuntu).
#  --with-static-modules=STATIC_MODULES
#            Comma-separated list of names of modules to statically link in. May include !module to disable 'module'. Can be '!FORCED' to disable all non-required static only modules. Can be '!DEFAULT' to disable all modules defaulting to a static build. Can be 'ALL' to build all default shared modules static. The
#            most specific one wins, while the order is ignored and --with-static-modules is evaluated before --with-shared-modules
#  --with-shared-modules=SHARED_MODULES
#            Comma-separated list of names of modules to build shared. May include !module to disable 'module'. Can be '!FORCED' to disable all non-required shared only modules. Can be '!DEFAULT' to disable all modules defaulting to a shared build. Can be 'ALL' to build all default static modules shared. The most
#            specific one wins, while the order is ignored and --with-static-modules is evaluated before --with-shared-modules
#  --with-winbind
#            Build with winbind support (default=yes)
#  --with-ads
#            Build with ads support (default=yes)
#  --with-ldap
#            Build with ldap support (default=yes)
#  --enable-cups
#            Build with cups support (default=yes)
#  --enable-iprint
#            Build with iprint support (default=yes)
#  --with-pam
#            Build with pam support (default=yes)
#  --with-quotas
#            Build with quotas support (default=auto)
#  --with-sendfile-support
#            Build with sendfile-support support (default=auto)
#  --with-utmp
#            Build with utmp support (default=yes)
#  --enable-avahi
#            Build with avahi support (default=yes)
#  --with-iconv
#            Build with iconv support (default=yes)
#  --with-acl-support
#            Build with acl-support support (default=yes)
#  --with-dnsupdate
#            Build with dnsupdate support (default=yes)
#  --with-syslog
#            Build with syslog support (default=yes)
#  --with-automount
#            Build with automount support (default=yes)
#  --with-dmapi
#            Build with dmapi support (default=auto)
#  --with-fam
#            Build with fam support (default=auto)
#  --with-profiling-data
#            Build with profiling-data support (default=no)
#  --with-libarchive
#            Build with libarchive support (default=yes)
#  --with-cluster-support
#            Build with cluster-support support (default=no)
#  --with-regedit
#            Build with regedit support (default=auto)
#  --with-fake-kaserver
#            Include AFS fake-kaserver support
#  --enable-glusterfs
#            Build with glusterfs support (default=yes)
#  --enable-cephfs
#            Build with cephfs support (default=yes)
#  --enable-vxfs
#            enable support for VxFS (default=no)
#  --enable-spotlight
#            Build with spotlight support (default=no)
#  --disable-fault-handling
#            disable the fault handlers
#  --with-systemd
#            Enable systemd integration
#  --without-systemd
#            Disable systemd integration
#  --with-lttng
#            Enable lttng integration
#  --without-lttng
#            Disable lttng integration
#  --with-gpfs=GPFS_HEADERS_DIR
#            Directory under which gpfs headers are installed
#  --accel-aes=ACCEL_AES
#            Should we use accelerated AES crypto functions. Options are intelaesni|none.
#  --enable-infiniband
#            Turn on infiniband support (default=no)
#  --enable-pmda
#            Turn on PCP pmda support (default=no)
#  --enable-etcd-reclock
#            Enable etcd recovery lock helper (default=no)
#  --with-libcephfs=LIBCEPHFS_DIR
#            Directory under which libcephfs is installed
#  --enable-ceph-reclock
#            Enable Ceph CTDB recovery lock helper (default=no)
#  --with-logdir=CTDB_LOGDIR
#            Path to log directory
#  --with-socketpath=CTDB_SOCKPATH
#            path to CTDB daemon socket
#  --enable-pthreadpool
#            Build with pthreadpool support (default=yes)
#  --with-system-mitkrb5
#            build Samba with system MIT Kerberos. You may specify list of paths where Kerberos is installed (e.g. /usr/local /usr/kerberos) to search krb5-config
#  --with-experimental-mit-ad-dc
#            Enable the experimental MIT Kerberos-backed AD DC.  Note that security patches are not issued for this configuration
#  --with-system-mitkdc=WITH_SYSTEM_MITKDC
#            Specify the path to the krb5kdc binary from MIT Kerberos
#  --with-system-heimdalkrb5
#            conflicts with --with-system-mitkrb5
#  --without-ad-dc
#            disable AD DC functionality (enables only Samba FS (File Server, Winbind, NMBD) and client utilities.
#  --with-ntvfs-fileserver
#            enable the deprecated NTVFS file server from the original Samba4 branch (default if --enable-selftest specified).  Conflicts with --with-system-mitkrb5 and --without-ad-dc
#  --without-ntvfs-fileserver
#            disable the deprecated NTVFS file server from the original Samba4 branch
#  --with-pie
#            Build Position Independent Executables (default if supported by compiler)
#  --without-pie
#            Disable Position Independent Executable builds
#  --with-relro
#            Build with full RELocation Read-Only (RELRO)(default if supported by compiler)
#  --without-relro
#            Disable RELRO builds
#  --with-json
#            Build with JSON support (default=True). This requires the jansson development headers.
#  --without-json
#            Build without JSON support.
#
#  Configuration options:
#    -o OUT, --out=OUT
#            build dir for the project
#    -t TOP, --top=TOP
#            src dir for the project
#    --check-c-compiler=CHECK_C_COMPILER
#            list of C compilers to try [gcc clang icc generic_cc]
#
#  Build and installation options:
#    -p, --progress
#            -p: progress bar; -pp: ide output
#    --targets=TARGETS
#            task generators, e.g. "target1,target2"
#
#  Step options:
#    --files=FILES
#            files to process, by regexp, e.g. "*/main.c,*/test/main.o"
#
#  Installation and uninstallation options:
#    -f, --force
#            force file installation
#    --distcheck-args=ARGS
#            arguments to pass to distcheck
#
#  Installation prefix:
#    By default, "waf install" will put the files in "/usr/local/bin", "/usr/local/lib" etc. An installation prefix other than "/usr/local" can be given using "--prefix", for example "--prefix=$HOME"
#
#    --prefix=PREFIX
#            installation prefix [default: '/usr/local/samba']
#    --destdir=DESTDIR
#            installation root [default: '']
#    --exec-prefix=EXEC_PREFIX
#            installation prefix for binaries [PREFIX]
#
#  Installation directories:
#    --bindir=BINDIR
#            user commands [EXEC_PREFIX/bin]
#    --sbindir=SBINDIR
#            system binaries [EXEC_PREFIX/sbin]
#    --libexecdir=LIBEXECDIR
#            program-specific binaries [EXEC_PREFIX/libexec]
#    --sysconfdir=SYSCONFDIR
#            host-specific configuration [PREFIX/etc]
#    --sharedstatedir=SHAREDSTATEDIR
#            architecture-independent variable data [PREFIX/com]
#    --localstatedir=LOCALSTATEDIR
#            variable data [PREFIX/var]
#    --libdir=LIBDIR
#            object code libraries [EXEC_PREFIX/lib]
#    --includedir=INCLUDEDIR
#            header files [PREFIX/include]
#    --oldincludedir=OLDINCLUDEDIR
#            header files for non-GCC compilers [/usr/include]
#    --datarootdir=DATAROOTDIR
#            architecture-independent data root [PREFIX/share]
#    --datadir=DATADIR
#            architecture-independent data [DATAROOTDIR]
#    --infodir=INFODIR
#            GNU "info" documentation [DATAROOTDIR/info]
#    --localedir=LOCALEDIR
#            locale-dependent data [DATAROOTDIR/locale]
#    --mandir=MANDIR
#            manual pages [DATAROOTDIR/man]
#    --docdir=DOCDIR
#            documentation root [DATAROOTDIR/doc/PACKAGE]
#    --htmldir=HTMLDIR
#            HTML documentation [DOCDIR]
#    --dvidir=DVIDIR
#            DVI documentation [DOCDIR]
#    --pdfdir=PDFDIR
#            PDF documentation [DOCDIR]
#    --psdir=PSDIR
#            PostScript documentation [DOCDIR]
#
#  library handling options:
#    --bundled-libraries=BUNDLED_LIBS
#            comma separated list of bundled libraries. May include !LIBNAME to disable bundling a library. Can be 'NONE' or 'ALL' [auto]
#    --private-libraries=PRIVATE_LIBS
#            comma separated list of normally public libraries to build instead as private libraries. May include !LIBNAME to disable making a library private. Can be 'NONE' or 'ALL' [auto]
#    --private-library-extension=PRIVATE_EXTENSION
#            name extension for private libraries [samba4]
#    --private-extension-exception=PRIVATE_EXTENSION_EXCEPTION
#            comma separated list of libraries to not apply extension to []
#    --builtin-libraries=BUILTIN_LIBRARIES
#            command separated list of libraries to build directly into binaries [NONE]
#    --minimum-library-version=MINIMUM_LIBRARY_VERSION
#            list of minimum system library versions (LIBNAME1:version,LIBNAME2:version)
#    --disable-rpath
#            Disable use of rpath for build binaries
#    --disable-rpath-install
#            Disable use of rpath for library path in installed files
#    --disable-rpath-private-install
#            Disable use of rpath for private library path in installed files
#    --nonshared-binary=NONSHARED_BINARIES
#            Disable use of shared libs for the listed binaries
#    --disable-symbol-versions
#            Disable use of the --version-script linker option
#
#  developer options:
#    -C      enable configure cacheing
#    --enable-auto-reconfigure
#            enable automatic reconfigure on build
#    --enable-debug
#            Turn on debugging symbols
#    --enable-developer
#            Turn on developer warnings and debugging
#    --picky-developer
#            Treat all warnings as errors (enable -Werror)
#    --fatal-errors
#            Stop compilation on first error (enable -Wfatal-errors)
#    --enable-gccdeps
#            Enable use of gcc -MD dependency module
#    --pedantic
#            Enable even more compiler warnings
#    --git-local-changes
#            mark version with + if local git changes
#    --address-sanitizer
#            Enable address sanitizer compile and linker flags
#    --undefined-sanitizer
#            Enable undefined behaviour sanitizer compile and linker flags
#    --abi-check
#            Check ABI signatures for libraries
#    --abi-check-disable
#            Disable ABI checking (used with --enable-developer)
#    --abi-update
#            Update ABI signature files for libraries
#    --show-deps=SHOWDEPS
#            Show dependency tree for the given target
#    --symbol-check
#            check symbols in object files against project rules
#    --dup-symbol-check
#            check for duplicate symbols in object files and system libs (must be configured with --enable-developer)
#    --why-needed=WHYNEEDED
#            TARGET:DEPENDENCY check why TARGET needs DEPENDENCY
#    --show-duplicates
#            Show objects which are included in multiple binaries or libraries
#
#  cross compilation options:
#    --cross-compile
#            configure for cross-compilation
#    --cross-execute=CROSS_EXECUTE
#            command prefix to use for cross-execution in configure
#    --cross-answers=CROSS_ANSWERS
#            answers to cross-compilation configuration (auto modified)
#    --hostcc=HOSTCC
#            set host compiler when cross compiling
#
#  dist options:
#    --sign-release
#            sign the release tarball created by waf dist
#    --tag=TAG_RELEASE
#            tag release in git at the same time
#
#  Samba-specific directory layout:
#    --enable-fhs
#            Use FHS-compliant paths (default no)
#            You should consider using this together with:
#            --prefix=/usr --sysconfdir=/etc --localstatedir=/var
#    --with-privatelibdir=PRIVATELIBDIR
#            Which directory to use for private Samba libraries
#            [STD-Default: ${LIBDIR}/private]
#            [FHS-Default: ${LIBDIR}/samba]
#    --with-modulesdir=MODULESDIR
#            Which directory to use for Samba modules
#            [STD-Default: ${LIBDIR}]
#            [FHS-Default: ${LIBDIR}/samba]
#    --with-pammodulesdir=PAMMODULESDIR
#            Which directory to use for PAM modules
#            [STD-Default: ${LIBDIR}/security]
#            [FHS-Default: ${LIBDIR}/security]
#    --with-configdir=CONFIGDIR
#            Where to put configuration files
#            [STD-Default: ${SYSCONFDIR}]
#            [FHS-Default: ${SYSCONFDIR}/samba]
#    --with-privatedir=PRIVATE_DIR
#            Where to put sam.ldb and other private files
#            [STD-Default: ${PREFIX}/private]
#            [FHS-Default: ${LOCALSTATEDIR}/lib/samba/private]
#    --with-bind-dns-dir=BINDDNS_DIR
#            bind-dns config directory
#            [STD-Default: ${PREFIX}/bind-dns]
#            [FHS-Default: ${LOCALSTATEDIR}/lib/samba/bind-dns]
#    --with-lockdir=LOCKDIR
#            Where to put short term disposable state files
#            [STD-Default: ${LOCALSTATEDIR}/lock]
#            [FHS-Default: ${LOCALSTATEDIR}/lock/samba]
#    --with-piddir=PIDDIR
#            Where to put pid files
#            [STD-Default: ${LOCALSTATEDIR}/run]
#            [FHS-Default: ${LOCALSTATEDIR}/run/samba]
#    --with-statedir=STATEDIR
#            Where to put persistent state files
#            [STD-Default: ${LOCALSTATEDIR}/locks]
#            [FHS-Default: ${LOCALSTATEDIR}/lib/samba]
#    --with-cachedir=CACHEDIR
#            Where to put temporary cache files
#            [STD-Default: ${LOCALSTATEDIR}/cache]
#            [FHS-Default: ${LOCALSTATEDIR}/cache/samba]
#    --with-logfilebase=LOGFILEBASE
#            Where to put log files
#            [STD-Default: ${LOCALSTATEDIR}]
#            [FHS-Default: ${LOCALSTATEDIR}/log/samba]
#    --with-sockets-dir=SOCKET_DIR
#            socket directory
#            [STD-Default: ${LOCALSTATEDIR}/run]
#            [FHS-Default: ${LOCALSTATEDIR}/run/samba]
#    --with-privileged-socket-dir=PRIVILEGED_SOCKET_DIR
#            privileged socket directory
#            [STD-Default: ${LOCALSTATEDIR}/lib]
#            [FHS-Default: ${LOCALSTATEDIR}/lib/samba]
#    --with-smbpasswd-file=SMB_PASSWD_FILE
#            Where to put the smbpasswd file
#            [STD-Default: ${PRIVATE_DIR}/smbpasswd]
#            [FHS-Default: ${PRIVATE_DIR}/smbpasswd]
#
#  systemd installation options:
#    --systemd-install-services
#            install systemd service files to manage daemons (default=no)
#    --with-systemddir=SYSTEMDDIR
#            systemd service directory [PREFIX/lib/systemd/system]
#    --systemd-smb-extra=Option=Value
#            Extra directives added to the smb service file. Can be given multiple times.
#    --systemd-nmb-extra=Option=Value
#            Extra directives added to the nmb service file. Can be used multiple times.
#    --systemd-winbind-extra=Option=Value
#            Extra directives added to the winbind service file. Can be used multiple times.
#    --systemd-samba-extra=Option=Value
#            Extra directives added to the samba service file. Can be used multiple times.
#
#  Python Options:
#    --nopyc
#            Do not install bytecode compiled .pyc files (configuration) [Default:install]
#    --nopyo
#            Do not install optimised compiled .pyo files (configuration) [Default:install]
#    --nopycache
#            Do not use __pycache__ directory to install objects [Default:auto]
#    --python=PYTHON
#            python binary to be used [Default: /usr/bin/python3]
#    --pythondir=PYTHONDIR
#            Installation path for python modules (py, platform-independent .py and .pyc files)
#    --pythonarchdir=PYTHONARCHDIR
#            Installation path for python extension (pyext, platform-dependent .so or .dylib files)
#
#  test options:
#    --load-list=LOAD_LIST
#            Load a test id list from a text file
#    --list  List available tests
#    --tests=TESTS
#            wildcard pattern of tests to run
#    --filtered-subunit
#            output (xfail) filtered subunit
#    --quick
#            enable only quick tests
#    --slow  enable the really slow tests
#    --nb-slowest=NB_SLOWEST
#            Show the n slowest tests (default=10)
#    --testenv
#            start a terminal with the test environment setup
#    --valgrind
#            use valgrind on client programs in the tests
#    --valgrind-log=VALGRINDLOG
#            where to put the valgrind log
#    --valgrind-server
#            use valgrind on the server in the tests (opens an xterm)
#    --screen
#            run the samba servers in screen sessions
#    --gdbtest
#            run the servers within a gdb window
#    --fail-immediately
#            stop tests on first failure
#    --socket-wrapper-pcap
#            create a pcap file for each failing test
#    --socket-wrapper-keep-pcap
#            create a pcap file for all individual test
#    --random-order
#            Run testsuites in random order
#    --perf-test
#            run performance tests only
#    --test-list=TEST_LIST
#            use tests listed here, not defaults (--test-list='FOO|' will execute FOO; --test-list='FOO' will read it)
#    --no-subunit-filter
#            no (xfail) subunit filtering
#
