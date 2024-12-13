# Anthony Houdusse - P�le proximit� du Finist�re - DSII - Acad�mie de Rennes.

# $OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
# $PSDefaultParameterValues['*:Encoding'] = 'utf8'
Param ( 
	[String]$Domaine = "",
	[Switch]$Relaunch
)

$error.Clear()
Clear

$UneErreurAEuLieu = $False
$GPOEcritureRefusee = $False
$GPODejaExistante = $False
$NomCompletDuScriptActuel = $MyInvocation.MyCommand.Definition
$CheminBackup = Split-Path -Path $NomCompletDuScriptActuel -Parent

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host "Installation-GPO.ps1 version 1.8.6" -ForegroundColor Yellow

# Write-Host ; Write-Host -NoNewLine "V�rification des droits 'Administrateur' du script ..."
# $User = [Security.Principal.WindowsIdentity]::GetCurrent()
# $Role = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
# if(!$Role) { 
	# Write-Host
	# Write-Warning "Ce script ne fonctionnera pas sans �l�vation de pouvoir"
	# Exit
# } Else {
	# Write-Host " OK"
# }
Write-Host

If ( !(Test-Path -Path "$CheminBackup\RSAT.tag")) { 
	Write-Warning " Vous devez d'abord ex�cuter le script ''Installation-RSAT'' avant celui-ci."
	Exit
}

# Ou le domaine a �t� indiqu� en param�tre de ligne de commande, sinon il est demand� � l'utilisateur
If ( $Domaine -eq "" ) {
	$Domaine = ((Get-WmiObject Win32_ComputerSystem).Domain).Tolower()
	If ($Domaine -like '*.ac-rennes.fr') { $Domaine = $Domaine.SubString(0, $Domaine.length - 13) } 
	Write-Host -NoNewLine "Le domaine d�tect� est " ; Write-Host "'$Domaine'" -ForegroundColor Green
	$RequeteDomaine = Read-Host "(Laissez tel quel et validez par ''Entr�e'' si le domaine est correct, sinon tapez maintenant son nom correct) "
	If ( $RequeteDomaine -ne "" ) { $Domaine = $RequeteDomaine }
} Else {
	Write-Host -NoNewLine "Le domaine indiqu� en param�tre est " ; Write-Host "'$Domaine'" -ForegroundColor Green
}

# D�blocage des fichiers t�l�charg�s depuis d'Internet
Get-Childitem "$CheminBackup\" | Unblock-File

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host
Write-Host "Copie dans le Netlogon des fichiers BGInfo pour postes clients" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\BGInfo ..."
Try { Copy-Item -Path "$CheminBackup\BGInfo\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers d�j� existants ..." }
Catch { Write-Host "Un souci  � eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"
$Departement = $Domaine.SubString(0, 2)
Write-Host -NoNewLine " Application du mod�le \\ADDC\netlogon\BGInfo\Standard$Departement.bgi ..."
Copy-Item "\\ADDC\netlogon\BGInfo\Standard$Departement.bgi" -Destination "\\ADDC\netlogon\BGInfo\Standard.bgi"
Write-Host " OK"

Write-Host "Copie dans le Netlogon des fichiers WAPT pour gestion des icones" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\WAPT ..."
Try { Copy-Item -Path "$CheminBackup\WAPT\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers d�j� existants ..." }
Catch { Write-Host "Un souci  � eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Copie dans le Netlogon des fichiers pour gestion des certificats" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\Certificats ..."
Try { Copy-Item -Path "$CheminBackup\Certificats\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers d�j� existants ..." }
Catch { Write-Host "Un souci  � eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Copie dans le Netlogon des fichiers pour synchronisation horaire" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\Config ..."
Try { Copy-Item -Path "$CheminBackup\Config\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers d�j� existants ..." }
Catch { Write-Host "Un souci  � eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Copie dans le Netlogon des fichiers Veyon pour r�paration" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\Veyon ..."
Try { Copy-Item -Path "$CheminBackup\Veyon\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers d�j� existants ..." }
Catch { Write-Host "Un souci  � eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

# Write-Host "Copie dans le Netlogon des polices de caract�res pour postes clients" -ForegroundColor Green
# Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\Polices ..."
# Try { Copy-Item -Path "$CheminBackup\Polices\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
# Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers d�j� existants ..." }
# Catch { Write-Host "Un souci  � eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	# Write-Host -NoNewLine " Pas"
	# $UneErreurAEuLieu = $True }
# Write-Host " OK"

Write-Host "Copie des fichiers termin�e" -ForegroundColor Green
Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host "Importation des strat�gies :" -ForegroundColor Green

Try { Remove-GPO -Name "GPO WSUS" -ErrorAction Stop 3>&1>$Null 
		Write-Host " La GPO Windows Update (WSUS) est critique, on la supprime/recr�e pour forcer les postes � la r�appliquer."
		Write-Host " Suppression de la GPO WSUS... OK"
		Write-Host }
Catch {  }
Try { Remove-GPO -Name "GPO WSUS-P2P" -ErrorAction Stop 3>&1>$Null 
		Write-Host " La GPO Windows Update (WSUS-P2P) est critique, on la supprime/recr�e pour forcer les postes � la r�appliquer."
		Write-Host " Suppression de la GPO WSUS-P2P... OK"
		Write-Host }
Catch {  }

Get-ChildItem $CheminBackup -Directory -Depth 0 | %{ 
	$GPO_GUID = $_.Name
	$FichierXML = $CheminBackup + "\" + $GPO_GUID + "\" + "bkupInfo.xml"
	If ( Test-Path -Path $FichierXML ) {
		[xml]$ContenuTempXML = Get-Content $FichierXML -Encoding UTF8
		$NomGPO = $ContenuTempXML.BackupInst.GPODisplayName.'#cdata-section'
		
		# On essaye d'obtenir des infos sur la GPO qui nous interesse, si erreur c'est qu'elle n'existait pas.
		Try { Get-GPO -Name "$NomGPO" -ErrorAction Stop 3>&1>$Null 
			Write-Host -NoNewLine " Ecrasement de la" ; Write-Host -NoNewLine " strat�gie d�j� existante" -ForegroundColor Yellow ; Write-Host -NoNewLine " : '$NomGPO' ..."}
		Catch { Write-Host -NoNewLine " Cr�ation de la strat�gie '$NomGPO' ..." } 
		
		# Certaines GPO "r�sistent" � la restauration des param�tres une fois cr��e, une boucle de 10 tentatives sera tent�e si n�cessaire.
		# Si une 1ere erreur, on tente maintenant de fiabiliser la chose en l'ex�cutant en 2 temps, plut�t que laisser Import-GPO le faire, avec parfois des objets impossibles � param�trer ensuite :
		# d'abord la cr�er, puis ensuite importer ses param�tres
		$NbreTentativeEcritureRateeGPO = 0
		Do {
			# si il y a d�j� eu une erreur, destruction puis re-cr�ation de la GPO
			If ( $NbreTentativeEcritureRateeGPO -gt 0 ) { 
				Start-Sleep -s 5
				Try { Remove-GPO -Name "$NomGPO" -ErrorAction Stop 3>&1>$Null }
				Catch { Write-Host -NoNewLine "s" }
				Start-Sleep -s 5
				Try { New-GPO -Name "$NomGPO" -ErrorAction Stop 3>&1>$Null }
				Catch { Write-Host -NoNewLine "c" }
			}
			
			# Import-GPO -BackupId $GPO_GUID -TargetName "$NomGPO" -Path $CheminBackup -CreateIfNeeded -ErrorAction Stop 3>&1>$Null
			Try { 
				If ( $NbreTentativeEcritureRateeGPO -eq 0 ) {
					Import-GPO -BackupGpoName "$NomGPO" -TargetName "$NomGPO" -Path $CheminBackup -CreateIfNeeded -ErrorAction Stop 3>&1>$Null
					Write-Host -NoNewLine "."
				} Else {
					Import-GPO -BackupGpoName "$NomGPO" -TargetName "$NomGPO" -Path $CheminBackup -ErrorAction Stop 3>&1>$Null
					Write-Host -NoNewLine "o"
				}
				$NbreTentativeEcritureRateeGPO = 0 }
			Catch [System.UnauthorizedAccessException] { # echo $_ | format-list * -Force
				Write-Host -NoNewLine "x"
				$NbreTentativeEcritureRateeGPO++ }
			Catch { # echo $_ | format-list * -Force
				Write-Host -NoNewLine "i"
				$NbreTentativeEcritureRateeGPO++ }
			
		} Until (($NbreTentativeEcritureRateeGPO -eq 0) -Or ($NbreTentativeEcritureRateeGPO -gt 50))
		
		If ( $NbreTentativeEcritureRateeGPO -gt 0 ) {
			Write-Host ; Write-Host "Cette GPO est bloqu�e en �criture actuellement, relancez le script plus tard." -BackgroundColor Black -ForegroundColor Red
			Write-Host -NoNewLine " Pas" 
			$UneErreurAEuLieu = $True
		}		
		Write-Host " OK"
	}
}

If ( $UneErreurAEuLieu ) { 
	If ( $Relaunch ) {
		Write-Host "Le script est en erreur pour la seconde fois d'affil�e, on sort..."
		Write-Host
		$BarreTitre = "-" * ($Domaine.Length + 1)
		Write-Host   "+$BarreTitre-------------------------------------------------------+" -ForegroundColor White -BackgroundColor Red
		Write-Host   "|  La configuration globale du domaine $Domaine est incompl�te.  |" -ForegroundColor White -BackgroundColor Red
		Write-Host   "+$BarreTitre-------------------------------------------------------+" -ForegroundColor White -BackgroundColor Red
		Write-Host
		Write-Host "Red�marrez d'abord le ScribeAD puis le SIMAJ, et tentez de relancer le script..." -BackgroundColor Black -ForegroundColor Red
		Write-Host "Si cela se reproduit, demandez de l'assistance..." -BackgroundColor Black -ForegroundColor Red
		Write-Host
		
		Exit
	} Else {
		$Relaunch = $True
		& "$NomCompletDuScriptActuel" -Domaine $Domaine -Relaunch $Relaunch
		Exit
	} 
}

Write-Host 
Write-Host " Recherche de GPOs obsol�tes"
Try { Remove-GPO -Name "GPO WSUS 2" -ErrorAction Stop 3>&1>$Null 
		Write-Host " Suppression de la GPO WSUS 2... OK" }
Catch {  }
Try { Remove-GPO -Name "GPO Firefox et Certificats" -ErrorAction Stop 3>&1>$Null 
		Write-Host " Suppression de la GPO Firefox et Certificats... OK" }
Catch {  }
Write-Host " Recherche de GPOs obsol�tes termin�e"

Write-Host "Importation des strat�gies termin�e" -ForegroundColor Green
Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host "Modification de strat�gies li�es au Domaine :" -ForegroundColor Green
Write-Host -NoNewLine " Edition de la strat�gie 'GPO WSUS-P2P' ..."
# Ancienne m�thode
# If ( Test-Path -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport.xml ) { Remove-Item -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport.xml -Force }
# If ( Test-Path -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport-original.xml ) {
	# $ContenuTemp = Get-Content $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport-original.xml
	# $ContenuTemp = $ContenuTemp -replace "DOMAINE-peda","$Domaine-peda"
	# $ContenuTemp | Out-file $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport.xml -Encoding Unicode
	# Write-Host " OK"
# }

# M�thode suivante
# If ( !(Test-Path -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\registry.old) ) { 
	# & $CheminBackup\Ressources\LGPO.exe /parse /m $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\registry.pol >> $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\TempRegistry.txt
# } Else { 
	# & $CheminBackup\Ressources\LGPO.exe /parse /m $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\registry.old >> $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\TempRegistry.txt
# }
# $ContenuTemp = Get-Content $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\TempRegistry.txt
# $ContenuTemp = $ContenuTemp -replace "DOMAINE-peda","$Domaine-peda"
# $ContenuTemp | Out-file $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\TempRegistry.txt
# If ( !(Test-Path -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\registry.old) ) { Rename-Item $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\registry.pol -NewName registry.old }
# & $CheminBackup\Ressources\LGPO.exe /r $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\TempRegistry.txt /w $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\registry.pol
# Remove-Item -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\DomainSysvol\GPO\Machine\TempRegistry.txt -Force -ErrorAction Stop 3>&1>$Null

# Bonne m�thode, simple efficace et plus besoin de remettre une valeur par d�faut
$TargetGroup = $Domaine + "-peda"
Try { Set-GPRegistryValue -Name "GPO WSUS-P2P" -key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName TargetGroup -Type String -value $TargetGroup -ErrorAction Stop 3>&1>$Null }
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la modification de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"


Write-Host "Modification de la strat�gie termin�e" -ForegroundColor Green
Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# L'ordre dans lequel sont li�es les GPOs fixe la priorit� dans laquelle elles sont trait�es par les Machines/Utilisateurs concern�s (la 1ere est la plus prioritaire si elle est au m�me niveau d'OU)

Write-Host "Liaison des strat�gies essentielles aux diff�rentes OUs :" -ForegroundColor Green
Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Configuration Machine' � 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Machine" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO UAC normale' � 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO UAC normale" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO WSUS-P2P' � 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO WSUS-P2P" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

# Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Compatibilit� Veyon' � 'Ordinateurs du Domaine' ..."
Try {Remove-GPLink -Name "GPO Compatibilit� Veyon" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsol�te de la strat�gie 'GPO Configuration Environnement' � 'Utilisateurs du Domaine' ... OK"}
Catch { }
# Try { $LienTemp = New-GPLink -Name "GPO Compatibilit� Veyon" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
# Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	# $GPODejaExistante = $True}
# Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	# Write-Host -NoNewLine " Pas"
	# $UneErreurAEuLieu = $True }
# Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Restrictions El�ves' � 'Eleves' ..."
Try { $LienTemp = New-GPLink -Name "GPO Restrictions El�ves" -Target "ou=Eleves,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Try {Remove-GPLink -Name "GPO Configuration Environnement" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsol�te de la strat�gie 'GPO Configuration Environnement' � 'Utilisateurs du Domaine' ... OK"}
Catch { }
Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Configuration Environnement' � 'Professeurs' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Environnement" -Target "ou=Professeurs,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"
Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Configuration Environnement' � 'Administratifs' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Environnement" -Target "ou=Administratifs,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"
Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Configuration Environnement' � 'Eleves' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Environnement" -Target "ou=Eleves,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Try {Remove-GPLink -Name "GPO Affichage BGInfo" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsol�te de la strat�gie 'GPO Affichage BGInfo' � 'Utilisateurs du Domaine' ... OK"}
Catch { }
Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Affichage BGInfo' � 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Affichage BGInfo" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas" 
	$UneErreurAEuLieu = $True }
Write-Host " OK"
Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Affichage BGInfo' � 'Domain Controllers' ..."
Try { $LienTemp = New-GPLink -Name "GPO Affichage BGInfo" -Target "ou=Domain Controllers,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas" 
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Pas de verrouillage des comptes' � la racine du domaine $Domaine ..."
Try { $LienTemp = New-GPLink -Name "GPO Pas de verrouillage des comptes" -Target "dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Rustine montage des lecteurs r�seau EOLE' � 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Rustine montage des lecteurs r�seau EOLE" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Try {Remove-GPLink -Name "GPO Redirection Dossiers" -Target "ou=Administratifs,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsol�te de la strat�gie 'GPO Redirection Dossiers' � 'Administratifs' ... OK"}
Catch { }
Try {Remove-GPLink -Name "GPO Redirection Dossiers" -Target "ou=Professeurs,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsol�te de la strat�gie 'GPO Redirection Dossiers' � 'Professeurs' ... OK"}
Catch { }
Try {Remove-GPLink -Name "GPO Redirection Dossiers" -Target "ou=Eleves,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsol�te de la strat�gie 'GPO Redirection Dossiers' � 'Eleves' ... OK"}
Catch { }
Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Redirection Dossiers' � 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Redirection Dossiers" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Pas de chgt de mot de passe par CTRL-ALT-SUPP' � 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Pas de chgt de mot de passe par CTRL-ALT-SUPP" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Compatibilit� impression PrintNightmare (serveur)' � 'Domain Controllers' ..."
Try { $LienTemp = New-GPLink -Name "GPO Compatibilit� impression PrintNightmare (serveur)" -Target "ou=Domain Controllers,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Correction bug EDGE' � 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Correction bug EDGE" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Bureau distant pour Prof.DAIP et Eleve.DAIP' � 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Bureau distant pour Prof.DAIP et Eleve.DAIP" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Liaison des strat�gies essentielles aux diff�rentes OUs termin�e" -ForegroundColor Green
Write-Host

If ($Domaine -like '29*') {
	Write-Host "Liaison des strat�gies typiques du P�le P29 aux diff�rentes OUs :" -ForegroundColor Green

	Write-Host -NoNewLine " Liaison de la strat�gie 'GPO Syncho WAPT-Bureau Public' � 'Ordinateurs du Domaine' ..."
	Try { $LienTemp = New-GPLink -Name "GPO Syncho WAPT-Bureau Public" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
	Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO d�j� li�e ..." -ForegroundColor Yellow
		$GPODejaExistante = $True}
	Catch { Write-Host ; Write-Host "Un souci � eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
		Write-Host -NoNewLine " Pas"
		$UneErreurAEuLieu = $True }
	Write-Host " OK"
	
	Write-Host -NoNewLine " La strat�gie '" ; Write-Host -NoNewLine "GPO Professeurs administrateurs dans ces salles - A EDITER" -ForegroundColor Yellow ; Write-Host "' n'a pas �t� li�e..."
	Write-Host " Cette GPO doit �tre �dit�e manuellement, puis vous pourrez la lier � 'Ordinateurs du Domaine' !!!" -BackgroundColor Black
	Write-Host -NoNewLine " La strat�gie '" ; Write-Host -NoNewLine "GPO Certificats S1peda pour Firefox - A EDITER" -ForegroundColor Yellow ; Write-Host "' n'a pas �t� li�e..."
	Write-Host " Cette GPO doit �tre �dit�e manuellement, puis vous pourrez la lier � 'Ordinateurs du Domaine' !!!" -BackgroundColor Black
		
	Write-Host "Liaison des strat�gies typiques du P�le P29 aux diff�rentes OUs termin�e" -ForegroundColor Green
	Write-Host
	}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host
If ( $UneErreurAEuLieu ) {
	$BarreTitre = "-" * ($Domaine.Length + 1)
	Write-Host   "+$BarreTitre----------------------------------------------------------------+" -ForegroundColor White -BackgroundColor Red
	Write-Host   "|  La configuration globale du domaine $Domaine est au mieux incompl�te.  |" -ForegroundColor White -BackgroundColor Red
	Write-Host   "+$BarreTitre----------------------------------------------------------------+" -ForegroundColor White -BackgroundColor Red
	Write-Host
	Write-Host "Une ou plusieurs erreurs importantes ont eu lieu." -BackgroundColor Black -ForegroundColor Red
	Write-Host "Remontez le d�roulement du script pour voir ce qui c'est pass�, et les corrections demand�es"
	Write-Host "Sinon demandez de l'assistance..." -BackgroundColor Black -ForegroundColor Red
	Write-Host
} Else {
	$BarreTitre = "-" * ($Domaine.Length + 1)
	Write-Host   "+$BarreTitre----------------------------------------------------+" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host   "|  La configuration globale du domaine $Domaine est termin�e  |" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host   "+$BarreTitre----------------------------------------------------+" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host
	If ( $GPODejaExistante ) { 
		Write-Host "Ce script a d�j� du �tre ex�cut� auparavant car des GPOs existaient d�j�." -ForegroundColor Yellow
		Write-Host "les GPOs ont �t� mises � jour, et tout s'est d�roul� correctement." -ForegroundColor Yellow
		Write-Host "(Si vous aviez modifi� les GPOs fournies par une ancienne version de ce script, alors leurs param�tres ont �t� �cras�s."
		Write-Host "Les autres GPOs que vous avez pu cr�er n'ont pas �t� modifi�es.)"
		Write-Host
	}	
	Write-Host "Maintenant, � vous de lier les GPOs optionnelles aux OUs qui le n�cessitent."
	Write-Host "(imprimantes, UAC, Pare-feu, restrictions � lever sur certaines salles...)"
	Write-Host
}