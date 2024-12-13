# Connect an SFTP mount point
# Version 2010.12.28
# Copyright (GNU GPL) Narcis Garcia

LocalPath="$1"
RemotePassword="$2"
RestrictToUser="$3"

Connect ()
{
	Result=0
	AlreadyMounted="$(mount | grep " $LocalPath ")"
	if [ "$AlreadyMounted" = "" ] ; then
		if [ "$(which sshfs)" = "" ] ; then
			apt-get install -qq -y sshfs
		fi
		if [ "$(which mount.fuse.sshfs)" = "" ] ; then
			ln -s $(which mount.fuse) /sbin/mount.fuse.sshfs
		fi
		if [ ! -d "$LocalPath" ] ; then  # Create the mount point with permissions
			mkdir -p "$LocalPath"
			if [ "$RestrictToUser" = "" ] ; then
				chmod ugo=rwX "$LocalPath"
			else
				LocalGroup="$(id -ng $RestrictToUser)"
				chown $RestrictToUser:$LocalGroup "$LocalPath"
				chmod u=rwX,g=rX,o= "$LocalPath"
			fi
		fi
		echo "$RemotePassword" | mount "$LocalPath" -o password_stdin,allow_other,StrictHostKeyChecking=no
		Result=$?
		if [ $Result -eq 0 ] ; then
			echo "	Right"
		else
			echo "($Result) The command was:"
			echo "echo \"\$RemotePassword\" | mount \"$LocalPath\" -o password_stdin,allow_other,StrictHostKeyChecking=no"
		fi
	else
		echo "The directory was already mounted on $(ReturnWord () { echo $3; }; ReturnWord $AlreadyMounted)"
		Result=1
	fi
	return $Result
}
TempLog="/tmp/sshfs_$(echo "$LocalPath" | tr -s "/" "-" | tr -s " " "_").log"
FirstMessage="Connecting $LocalPath to the server$(if [ -f $TempLog ] ; then echo " (was interrupted)" ; fi)... "
printf "$FirstMessage"
Line1Log="$(date +'%Y-%m-%d %H:%M:%S') $FirstMessage"
Connect > $TempLog 2>&1
cat $TempLog
if [ $(id -g) -eq 0 ] ; then
	echo "$Line1Log$(cat $TempLog)" >>/var/log/sshfs.log
fi
rm $TempLog
