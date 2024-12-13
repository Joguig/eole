#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh

function UpdateWpkg()
{
	ciPrintMsgMachine "* git clone wpkg-package.git "
	if [ ! -d /tmp/wpkg-package ]
	then
	    cd /tmp || exit 1
	    git clone https://dev-eole.ac-dijon.fr/git/wpkg-package.git
	else
	    cd /tmp/wpkg-package || exit 1
	    git pull
	fi
	#ls -l /tmp/wpkg-package/packages/
	
	ciPrintMsgMachine "* prepare /home/wpkg "
	cd /tmp/wpkg-package || exit 1
	# les icones
	/bin/cp -rf /tmp/wpkg-package/icones/ /home/wpkg/
	# les logiciels
	/bin/cp -rf /tmp/wpkg-package/softwares/ /home/wpkg/
	# les fichiers configurations (profiles, packages, hosts, settings + wpkg*
	/bin/cp -f "$VM_DIR_EOLE_CI_TEST"/scripts/windows/wpkg/*.xml /home/wpkg/
	/bin/cp -f "$VM_DIR_EOLE_CI_TEST"/scripts/windows/wpkg/wpkg* /home/wpkg/
	grep "package-id" "$VM_DIR_EOLE_CI_TEST/scripts/windows/wpkg/profiles.xml" | sed -e 's/.*="//' -e 's/".*$//' >/tmp/package
	PACKAGE_A_INSTALLER=$(cat /tmp/package)
	
	mkdir -p /home/wpkg/packages/
	/bin/rm -f /home/wpkg/packages/*
	# copie package depuis depot wpkg-package
	/bin/cp -f /tmp/wpkg-package/packages/*.py /home/wpkg/packages/
	# copie package depuis depot eolecitests : ceux specifique aux tests
	/bin/cp -f "$VM_DIR_EOLE_CI_TEST"/scripts/windows/wpkg/packages/*.xml /tmp/wpkg-package/packages/
	
	ciPrintMsgMachine "* PACKAGE_A_INSTALLER = $PACKAGE_A_INSTALLER"
	for f in $PACKAGE_A_INSTALLER
	do
	    ciPrintMsgMachine "* === prepare package $f"
	    if [ -f "/tmp/wpkg-package/packages/$f.xml" ] 
	    then
	        /bin/cp -f "/tmp/wpkg-package/packages/$f.xml" "/home/wpkg/packages/$f.xml" 
	    else
	        ciPrintMsgMachine "* === package $f manquant !"
	    fi
	done
	
	cp -f /tmp/wpkg-package/WPKG* /home/wpkg
	
	cd /home/wpkg/packages/ || exit 1
	#ciPrintMsgMachine "* download_installers"
	#python ./download_installers.py
		
}


function UpdateBinaires()
{
	ciPrintMsgMachine "* wpkg EXE / MSI"
	cd /home/wpkg/binaries  || exit 1
	#/bin/cp -rf "$VM_DIR_EOLE_CI_TEST"/scripts/windows/wpkg/*.exe .
	#/bin/cp -rf "$VM_DIR_EOLE_CI_TEST"/scripts/windows/wpkg/*.msi .
	
	#ciPrintMsgMachine "*** CYGWIN *** "
	/bin/rm -rf /home/wpkg/cygwinDownload
	#[ ! -d /home/wpkg/cygwinDownload ] && mkdir -p /home/wpkg/cygwinDownload
	#[ ! -d /etc/setup ] && mkdir -p /etc/setup
	#cp -vf "$VM_DIR_EOLE_CI_TEST/scripts/windows/cygwin/apt-cyg" /home/wpkg/cygwinDownload/apt-cyg
	#cp -vf "$VM_DIR_EOLE_CI_TEST/scripts/windows/cygwin/setup.rc" /etc/setup/setup.rc
	#cp -vf "$VM_DIR_EOLE_CI_TEST/scripts/windows/cygwin/installed.db" /etc/setup/installed.db
	#cd /home/wpkg/cygwinDownload  || exit 1
	#force telechargement
	#/bin/rm -f setup-x86.exe
	#downloadIfNeeded https://cygwin.com/setup-x86.exe setup-x86.exe
	#/bin/rm -f setup-x86_64.exe
	#downloadIfNeeded https://cygwin.com/setup-x86_64.exe setup-x86_64.exe 
	#/home/wpkg/cygwinDownload/apt-cyg cache /home/wpkg/cygwinDownload
	#apt-update
	
	
	cd /home/wpkg/binaries  || exit 1
	downloadIfNeeded http://www.flos-freeware.ch/zip/notepad2_4.2.25_x86.zip notepad2_4.2.25_x86.zip
	downloadIfNeeded http://sourceforge.net/projects/regshot/files/regshot/1.9.0/Regshot-1.9.0.7z/download Regshot-1.9.0.7z
	downloadIfNeeded http://ultimateoutsider.com/downloads/GWX_control_panel.exe GWX_control_panel.exe
	downloadIfNeeded https://download.sysinternals.com/files/SysinternalsSuite.zip SysinternalsSuite.zip
	
	downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip LGPO.zip
	downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/PolicyAnalyzer.zip PolicyAnalyzer.zip
	
	downloadIfNeeded https://www.portablefreeware.com/download.php?dd=2811 fulleventlogview.zip
	
	# download Salt Minion X64
	#cd /home/wpkg/binaries/x64 || exit 1
	
	#[ ! -d /home/wpkg/wsusoffline ] && mkdir -p /home/wpkg/wsusoffline
	#downloadIfNeeded http://download.wsusoffline.net/wsusoffline111.zip wsusoffline111.zip
	#cd /home/wpkg/wsusoffline || exit 1
	
}

function UpdateRSAT()
{
	# download RSAT x86
	cd /home/wpkg/binaries/x86/Win7 || exit 1
	#downloadIfNeeded https://download.microsoft.com/download/E/D/A/EDA6E3AE-31B9-449D-9E81-4E55F0881707/Windows6.1-KB958830-x86-RefreshPkg.msu Windows6.1-KB958830-x86-RefreshPkg.msu
	
	# download RSAT x64
	#cd /home/wpkg/binaries/x64/Win8.1 || exit 1
	#downloadIfNeeded https://download.microsoft.com/download/1/8/E/18EA4843-C596-4542-9236-DE46F780806E/Windows8.1-KB2693643-x86.msu Windows8.1-KB2693643-x86.msu
	
	cd /home/wpkg/binaries/x64/Win10 || exit 1
	#downloadIfNeeded https://download.microsoft.com/download/1/D/8/1D8B5022-5477-4B9A-8104-6A71FF9D98AB/WindowsTH-KB2693643-x86.msu WindowsTH-KB2693643-x86.msu
	
	#cd /home/wpkg/binaries/x64/Win10.1607 || exit 1
	#downloadIfNeeded https://download.microsoft.com/download/1/D/8/1D8B5022-5477-4B9A-8104-6A71FF9D98AB/WindowsTH-RSAT_WS2016-x64.msu WindowsTH-RSAT_WS2016-x64.msu
	#downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/Windows%2010%20Version%201607%20and%20Windows%20Server%202016%20Security%20Baseline.zip Windows10.1607-SecurityBaseline.zip
	
	#cd /home/wpkg/binaries/x64/Win10.1709 || exit 1
	#downloadIfNeeded https://download.microsoft.com/download/1/D/8/1D8B5022-5477-4B9A-8104-6A71FF9D98AB/WindowsTH-RSAT_WS_1709-x64.msu WindowsTH-RSAT_WS_1709-x64.msu
	#downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/Windows%2010%20Version%201709%20Security%20Baseline.zip Windows10.1709-SecurityBaseline.zip
}

echo "FRESHINSTALL_IMAGE=$FRESHINSTALL_IMAGE"
echo "DAILY_IMAGE=$DAILY_IMAGE"
IMAGE_FINALE=${1:-$DAILY_IMAGE}
IMAGE_SOURCE=${2:-$FRESHINSTALL_IMAGE}
echo "IMAGE_SOURCE=$IMAGE_SOURCE"
echo "IMAGE_FINALE=$IMAGE_FINALE"
export DEBIAN_FRONTEND=noninteractive
    
ciPrintMsgMachine "* installEolecitests"
if [ ! -f "/etc/lsb-release" ]
then
    ciPrintMsg "Eolecitest doit etre ubuntu "
    exit 1
fi
# shellcheck disable=SC1091
source /etc/lsb-release

# pour les test de sauvegardes ! (voir EolECiFunction + tests/sauvegardes !
[ ! -d /home/sauvegardes ] && mkdir -p /home/sauvegardes

/bin/bash /mnt/eole-ci-tests/scripts/service/CheckUpdate.sh

ciPatchFailsafeConf
bootEn1024x768

export DEBIAN_FRONTEND=noninteractive
#export APT_OPTS="--allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages -y "
export APT_OPTS="-y"
doUpgrade

doAptGet remove "$APT_OPTS" -y lighttpd
installPaquetsCommunDebianUbuntu nolighttpd
doAptGet install "$APT_OPTS" -y samba
doAptGet install "$APT_OPTS" -y winbind
doAptGet install "$APT_OPTS" -y acl
installPip
doAptGet install "$APT_OPTS" -y nginx-light

doAptGet remove "$APT_OPTS" -y cloud-init
doAptGet remove "$APT_OPTS" -y nfs-kernel-server nfs-common

removeServiceResolvConf
removeServicesGenant
sshAccesRoot
systemctl enable debug-shell.service
systemctl disable apt-daily.service
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.service
systemctl disable apt-daily-upgrade.timer

if [ -f /etc/default/networking ]
then
	sed -i -e 's/#VERBOSE=no/VERBOSE=yes/' /etc/default/networking
	sed -i -e 's/#CONFIGURE_INTERFACES=yes/CONFIGURE_INTERFACES=no/' /etc/default/networking
fi

mkdir -p /home/wpkg
mkdir -p /home/wpkg/binaries
mkdir -p /home/wpkg/binaries/x86
mkdir -p /home/wpkg/binaries/x64
for ver in 7 8.1 10 10.21H1 10.21H2 11
do
	mkdir -p "/home/wpkg/binaries/x86/Win$ver"
	mkdir -p "/home/wpkg/binaries/x64/Win$ver"
done

UpdateWpkg
UpdateBinaires
UpdateRSAT

# Windows Subsystem for Linux
#Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
#DISM.exe /Online /Enable-Feature /FeatureName:Microsoft-Windows-Subsystem-Linux
doAptGet remove "$APT_OPTS" -y lighttpd

tagImage
