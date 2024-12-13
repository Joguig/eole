Set-ExecutionPolicy Bypass -Scope Process -Force

#$cert=(dir cert:currentuser\my\ -CodeSigningCert)
#Set-AuthentificationSignature ./installMinion.ps1 $cert -TimestampServer http://tiemstamp.comodoca.com/authenticode

# -runtime20
&'.\ps2exe.ps1' -inputFile 'installMinion.ps1' -outputFile 'installMinion.exe' -verbose -noConfigfile -requireAdmin -x86 -iconFile 'eole.ico' -title 'Installateur Client EOLE' -version '1.0.0.0'

&'.\ps2exe.ps1' -inputFile 'installMinion.ps1' -outputFile 'installMinion-x64.exe' -verbose -noConfigfile -requireAdmin -x64 -iconFile 'eole.ico' -title 'Installateur Client EOLE' -version '1.0.0.0'

&'.\ps2exe.ps1' -inputFile 'installMinion.ps1' -outputFile 'installMinionGUI.exe' -verbose -noConsole -noConfigfile -requireAdmin -x86 -iconFile 'eole.ico' -title 'Installateur Client EOLE' -version '1.0.0.0'

&'.\ps2exe.ps1' -inputFile 'installMinion.ps1' -outputFile 'installMinionGUI-x64.exe' -verbose -noConsole -noConfigfile -requireAdmin -x64 -iconFile 'eole.ico' -title 'Installateur Client EOLE' -version '1.0.0.0'

