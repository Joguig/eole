
. c:\eole\EoleCiFunctions.ps1

Write-Output "install-virtio-win: début"
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-Location c:\eole
[int]$versionMajor = [environment]::OSVersion.version.Major
if( $versionMajor -lt 10)
{ 
    Write-Output "OS non supporté"
    return
}

If ( -Not( Test-Path c:\eole\Download\virtio-win.iso ))
{
    Write-Output "install-virtio-win : téléchargement"
    wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso -OutFile c:\eole\Download\virtio-win.iso
}    

Write-Output "install-virtio-win : mount"
$uniteDiskVirtio = Mount-DiskImage -ImagePath "c:\eole\download\virtio-win.iso" -StorageType ISO -PassThru
$uniteDiskVirtio

# driver virtio + Quiet, N=pas d'affichage, pas de reboot 
CMD.EXE /C "e:\virtio-win-gt-x64.msi /qn /norestart"

# guest agent + Quiet, N=pas d'affichage, pas de reboot
CMD.EXE /C "e:\virtio-win-guest-tools.exe /install /quiet /norestart"
   
   Write-Output "install-virtio-win : umount"
Dismount-DiskImage -ImagePath "c:\eole\download\virtio-win.iso"

#Write-Output "install-virtio-win : installs"
#$ConfirmPreference = "low"
#Get-ChildItem "c:\virtio-win" -Recurse -Filter "*.inf" | ForEach-Object {
#     Write-Output "install-virtio-win : install "$_.FullName 
#    PNPUtil.exe /add-driver $_.FullName /install 
#}

Write-Output "install-virtio-win : fin"
