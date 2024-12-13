# Anthony Houdusse - Pôle proximité du Finistère - DSII - Académie de Rennes.

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

# Write-Host ; Write-Host -NoNewLine "Vérification des droits 'Administrateur' du script ..."
# $User = [Security.Principal.WindowsIdentity]::GetCurrent()
# $Role = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
# if(!$Role) { 
	# Write-Host
	# Write-Warning "Ce script ne fonctionnera pas sans élévation de pouvoir"
	# Exit
# } Else {
	# Write-Host " OK"
# }
Write-Host

If ( !(Test-Path -Path "$CheminBackup\RSAT.tag")) { 
	Write-Warning " Vous devez d'abord exécuter le script ''Installation-RSAT'' avant celui-ci."
	Exit
}

# Ou le domaine a été indiqué en paramètre de ligne de commande, sinon il est demandé à l'utilisateur
If ( $Domaine -eq "" ) {
	$Domaine = ((Get-WmiObject Win32_ComputerSystem).Domain).Tolower()
	If ($Domaine -like '*.ac-rennes.fr') { $Domaine = $Domaine.SubString(0, $Domaine.length - 13) } 
	Write-Host -NoNewLine "Le domaine détecté est " ; Write-Host "'$Domaine'" -ForegroundColor Green
	$RequeteDomaine = Read-Host "(Laissez tel quel et validez par ''Entrée'' si le domaine est correct, sinon tapez maintenant son nom correct) "
	If ( $RequeteDomaine -ne "" ) { $Domaine = $RequeteDomaine }
} Else {
	Write-Host -NoNewLine "Le domaine indiqué en paramètre est " ; Write-Host "'$Domaine'" -ForegroundColor Green
}

# Déblocage des fichiers téléchargés depuis d'Internet
Get-Childitem "$CheminBackup\" | Unblock-File

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host
Write-Host "Copie dans le Netlogon des fichiers BGInfo pour postes clients" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\BGInfo ..."
Try { Copy-Item -Path "$CheminBackup\BGInfo\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers déjà existants ..." }
Catch { Write-Host "Un souci  à eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"
$Departement = $Domaine.SubString(0, 2)
Write-Host -NoNewLine " Application du modèle \\ADDC\netlogon\BGInfo\Standard$Departement.bgi ..."
Copy-Item "\\ADDC\netlogon\BGInfo\Standard$Departement.bgi" -Destination "\\ADDC\netlogon\BGInfo\Standard.bgi"
Write-Host " OK"

Write-Host "Copie dans le Netlogon des fichiers WAPT pour gestion des icones" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\WAPT ..."
Try { Copy-Item -Path "$CheminBackup\WAPT\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers déjà existants ..." }
Catch { Write-Host "Un souci  à eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Copie dans le Netlogon des fichiers pour gestion des certificats" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\Certificats ..."
Try { Copy-Item -Path "$CheminBackup\Certificats\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers déjà existants ..." }
Catch { Write-Host "Un souci  à eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Copie dans le Netlogon des fichiers pour synchronisation horaire" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\Config ..."
Try { Copy-Item -Path "$CheminBackup\Config\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers déjà existants ..." }
Catch { Write-Host "Un souci  à eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Copie dans le Netlogon des fichiers Veyon pour réparation" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\Veyon ..."
Try { Copy-Item -Path "$CheminBackup\Veyon\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers déjà existants ..." }
Catch { Write-Host "Un souci  à eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

# Write-Host "Copie dans le Netlogon des polices de caractères pour postes clients" -ForegroundColor Green
# Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\Polices ..."
# Try { Copy-Item -Path "$CheminBackup\Polices\" -Destination "\\ADDC\netlogon\" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
# Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers déjà existants ..." }
# Catch { Write-Host "Un souci  à eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	# Write-Host -NoNewLine " Pas"
	# $UneErreurAEuLieu = $True }
# Write-Host " OK"

Write-Host "Copie des fichiers terminée" -ForegroundColor Green
Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host "Importation des stratégies :" -ForegroundColor Green

Try { Remove-GPO -Name "GPO WSUS" -ErrorAction Stop 3>&1>$Null 
		Write-Host " La GPO Windows Update (WSUS) est critique, on la supprime/recrée pour forcer les postes à la réappliquer."
		Write-Host " Suppression de la GPO WSUS... OK"
		Write-Host }
Catch {  }
Try { Remove-GPO -Name "GPO WSUS-P2P" -ErrorAction Stop 3>&1>$Null 
		Write-Host " La GPO Windows Update (WSUS-P2P) est critique, on la supprime/recrée pour forcer les postes à la réappliquer."
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
			Write-Host -NoNewLine " Ecrasement de la" ; Write-Host -NoNewLine " stratégie déjà existante" -ForegroundColor Yellow ; Write-Host -NoNewLine " : '$NomGPO' ..."}
		Catch { Write-Host -NoNewLine " Création de la stratégie '$NomGPO' ..." } 
		
		# Certaines GPO "résistent" à la restauration des paramètres une fois créée, une boucle de 10 tentatives sera tentée si nécessaire.
		# Si une 1ere erreur, on tente maintenant de fiabiliser la chose en l'exécutant en 2 temps, plutôt que laisser Import-GPO le faire, avec parfois des objets impossibles à paramétrer ensuite :
		# d'abord la créer, puis ensuite importer ses paramètres
		$NbreTentativeEcritureRateeGPO = 0
		Do {
			# si il y a déjà eu une erreur, destruction puis re-création de la GPO
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
			Write-Host ; Write-Host "Cette GPO est bloquée en écriture actuellement, relancez le script plus tard." -BackgroundColor Black -ForegroundColor Red
			Write-Host -NoNewLine " Pas" 
			$UneErreurAEuLieu = $True
		}		
		Write-Host " OK"
	}
}

If ( $UneErreurAEuLieu ) { 
	If ( $Relaunch ) {
		Write-Host "Le script est en erreur pour la seconde fois d'affilée, on sort..."
		Write-Host
		$BarreTitre = "-" * ($Domaine.Length + 1)
		Write-Host   "+$BarreTitre-------------------------------------------------------+" -ForegroundColor White -BackgroundColor Red
		Write-Host   "|  La configuration globale du domaine $Domaine est incomplète.  |" -ForegroundColor White -BackgroundColor Red
		Write-Host   "+$BarreTitre-------------------------------------------------------+" -ForegroundColor White -BackgroundColor Red
		Write-Host
		Write-Host "Redémarrez d'abord le ScribeAD puis le SIMAJ, et tentez de relancer le script..." -BackgroundColor Black -ForegroundColor Red
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
Write-Host " Recherche de GPOs obsolètes"
Try { Remove-GPO -Name "GPO WSUS 2" -ErrorAction Stop 3>&1>$Null 
		Write-Host " Suppression de la GPO WSUS 2... OK" }
Catch {  }
Try { Remove-GPO -Name "GPO Firefox et Certificats" -ErrorAction Stop 3>&1>$Null 
		Write-Host " Suppression de la GPO Firefox et Certificats... OK" }
Catch {  }
Write-Host " Recherche de GPOs obsolètes terminée"

Write-Host "Importation des stratégies terminée" -ForegroundColor Green
Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host "Modification de stratégies liées au Domaine :" -ForegroundColor Green
Write-Host -NoNewLine " Edition de la stratégie 'GPO WSUS-P2P' ..."
# Ancienne méthode
# If ( Test-Path -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport.xml ) { Remove-Item -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport.xml -Force }
# If ( Test-Path -Path $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport-original.xml ) {
	# $ContenuTemp = Get-Content $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport-original.xml
	# $ContenuTemp = $ContenuTemp -replace "DOMAINE-peda","$Domaine-peda"
	# $ContenuTemp | Out-file $CheminBackup\"{A216F71A-D268-4F9F-BD1E-080EFB5CB2C2}"\gpreport.xml -Encoding Unicode
	# Write-Host " OK"
# }

# Méthode suivante
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

# Bonne méthode, simple efficace et plus besoin de remettre une valeur par défaut
$TargetGroup = $Domaine + "-peda"
Try { Set-GPRegistryValue -Name "GPO WSUS-P2P" -key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName TargetGroup -Type String -value $TargetGroup -ErrorAction Stop 3>&1>$Null }
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la modification de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"


Write-Host "Modification de la stratégie terminée" -ForegroundColor Green
Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# L'ordre dans lequel sont liées les GPOs fixe la priorité dans laquelle elles sont traitées par les Machines/Utilisateurs concernés (la 1ere est la plus prioritaire si elle est au même niveau d'OU)

Write-Host "Liaison des stratégies essentielles aux différentes OUs :" -ForegroundColor Green
Write-Host -NoNewLine " Liaison de la stratégie 'GPO Configuration Machine' à 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Machine" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO UAC normale' à 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO UAC normale" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO WSUS-P2P' à 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO WSUS-P2P" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

# Write-Host -NoNewLine " Liaison de la stratégie 'GPO Compatibilité Veyon' à 'Ordinateurs du Domaine' ..."
Try {Remove-GPLink -Name "GPO Compatibilité Veyon" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsolète de la stratégie 'GPO Configuration Environnement' à 'Utilisateurs du Domaine' ... OK"}
Catch { }
# Try { $LienTemp = New-GPLink -Name "GPO Compatibilité Veyon" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
# Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	# $GPODejaExistante = $True}
# Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	# Write-Host -NoNewLine " Pas"
	# $UneErreurAEuLieu = $True }
# Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Restrictions Elèves' à 'Eleves' ..."
Try { $LienTemp = New-GPLink -Name "GPO Restrictions Elèves" -Target "ou=Eleves,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Try {Remove-GPLink -Name "GPO Configuration Environnement" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsolète de la stratégie 'GPO Configuration Environnement' à 'Utilisateurs du Domaine' ... OK"}
Catch { }
Write-Host -NoNewLine " Liaison de la stratégie 'GPO Configuration Environnement' à 'Professeurs' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Environnement" -Target "ou=Professeurs,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"
Write-Host -NoNewLine " Liaison de la stratégie 'GPO Configuration Environnement' à 'Administratifs' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Environnement" -Target "ou=Administratifs,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"
Write-Host -NoNewLine " Liaison de la stratégie 'GPO Configuration Environnement' à 'Eleves' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Environnement" -Target "ou=Eleves,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Try {Remove-GPLink -Name "GPO Affichage BGInfo" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsolète de la stratégie 'GPO Affichage BGInfo' à 'Utilisateurs du Domaine' ... OK"}
Catch { }
Write-Host -NoNewLine " Liaison de la stratégie 'GPO Affichage BGInfo' à 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Affichage BGInfo" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas" 
	$UneErreurAEuLieu = $True }
Write-Host " OK"
Write-Host -NoNewLine " Liaison de la stratégie 'GPO Affichage BGInfo' à 'Domain Controllers' ..."
Try { $LienTemp = New-GPLink -Name "GPO Affichage BGInfo" -Target "ou=Domain Controllers,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas" 
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Pas de verrouillage des comptes' à la racine du domaine $Domaine ..."
Try { $LienTemp = New-GPLink -Name "GPO Pas de verrouillage des comptes" -Target "dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Rustine montage des lecteurs réseau EOLE' à 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Rustine montage des lecteurs réseau EOLE" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Try {Remove-GPLink -Name "GPO Redirection Dossiers" -Target "ou=Administratifs,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsolète de la stratégie 'GPO Redirection Dossiers' à 'Administratifs' ... OK"}
Catch { }
Try {Remove-GPLink -Name "GPO Redirection Dossiers" -Target "ou=Professeurs,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsolète de la stratégie 'GPO Redirection Dossiers' à 'Professeurs' ... OK"}
Catch { }
Try {Remove-GPLink -Name "GPO Redirection Dossiers" -Target "ou=Eleves,ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -ErrorAction Stop 3>&1>$Null 
	Write-Host " Suppression de la liaison obsolète de la stratégie 'GPO Redirection Dossiers' à 'Eleves' ... OK"}
Catch { }
Write-Host -NoNewLine " Liaison de la stratégie 'GPO Redirection Dossiers' à 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Redirection Dossiers" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Pas de chgt de mot de passe par CTRL-ALT-SUPP' à 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Pas de chgt de mot de passe par CTRL-ALT-SUPP" -Target "ou=Utilisateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Compatibilité impression PrintNightmare (serveur)' à 'Domain Controllers' ..."
Try { $LienTemp = New-GPLink -Name "GPO Compatibilité impression PrintNightmare (serveur)" -Target "ou=Domain Controllers,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Correction bug EDGE' à 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Correction bug EDGE" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Bureau distant pour Prof.DAIP et Eleve.DAIP' à 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Bureau distant pour Prof.DAIP et Eleve.DAIP" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
	$GPODejaExistante = $True}
Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Liaison des stratégies essentielles aux différentes OUs terminée" -ForegroundColor Green
Write-Host

If ($Domaine -like '29*') {
	Write-Host "Liaison des stratégies typiques du Pôle P29 aux différentes OUs :" -ForegroundColor Green

	Write-Host -NoNewLine " Liaison de la stratégie 'GPO Syncho WAPT-Bureau Public' à 'Ordinateurs du Domaine' ..."
	Try { $LienTemp = New-GPLink -Name "GPO Syncho WAPT-Bureau Public" -Target "ou=Ordinateurs du Domaine,dc=$Domaine,dc=ac-rennes,dc=fr" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
	Catch [System.ArgumentException] { Write-Host -NoNewLine " GPO déjà liée ..." -ForegroundColor Yellow
		$GPODejaExistante = $True}
	Catch { Write-Host ; Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
		Write-Host -NoNewLine " Pas"
		$UneErreurAEuLieu = $True }
	Write-Host " OK"
	
	Write-Host -NoNewLine " La stratégie '" ; Write-Host -NoNewLine "GPO Professeurs administrateurs dans ces salles - A EDITER" -ForegroundColor Yellow ; Write-Host "' n'a pas été liée..."
	Write-Host " Cette GPO doit être éditée manuellement, puis vous pourrez la lier à 'Ordinateurs du Domaine' !!!" -BackgroundColor Black
	Write-Host -NoNewLine " La stratégie '" ; Write-Host -NoNewLine "GPO Certificats S1peda pour Firefox - A EDITER" -ForegroundColor Yellow ; Write-Host "' n'a pas été liée..."
	Write-Host " Cette GPO doit être éditée manuellement, puis vous pourrez la lier à 'Ordinateurs du Domaine' !!!" -BackgroundColor Black
		
	Write-Host "Liaison des stratégies typiques du Pôle P29 aux différentes OUs terminée" -ForegroundColor Green
	Write-Host
	}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host
If ( $UneErreurAEuLieu ) {
	$BarreTitre = "-" * ($Domaine.Length + 1)
	Write-Host   "+$BarreTitre----------------------------------------------------------------+" -ForegroundColor White -BackgroundColor Red
	Write-Host   "|  La configuration globale du domaine $Domaine est au mieux incomplète.  |" -ForegroundColor White -BackgroundColor Red
	Write-Host   "+$BarreTitre----------------------------------------------------------------+" -ForegroundColor White -BackgroundColor Red
	Write-Host
	Write-Host "Une ou plusieurs erreurs importantes ont eu lieu." -BackgroundColor Black -ForegroundColor Red
	Write-Host "Remontez le déroulement du script pour voir ce qui c'est passé, et les corrections demandées"
	Write-Host "Sinon demandez de l'assistance..." -BackgroundColor Black -ForegroundColor Red
	Write-Host
} Else {
	$BarreTitre = "-" * ($Domaine.Length + 1)
	Write-Host   "+$BarreTitre----------------------------------------------------+" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host   "|  La configuration globale du domaine $Domaine est terminée  |" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host   "+$BarreTitre----------------------------------------------------+" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host
	If ( $GPODejaExistante ) { 
		Write-Host "Ce script a déjà du être exécuté auparavant car des GPOs existaient déjà." -ForegroundColor Yellow
		Write-Host "les GPOs ont été mises à jour, et tout s'est déroulé correctement." -ForegroundColor Yellow
		Write-Host "(Si vous aviez modifié les GPOs fournies par une ancienne version de ce script, alors leurs paramètres ont été écrasés."
		Write-Host "Les autres GPOs que vous avez pu créer n'ont pas été modifiées.)"
		Write-Host
	}	
	Write-Host "Maintenant, à vous de lier les GPOs optionnelles aux OUs qui le nécessitent."
	Write-Host "(imprimantes, UAC, Pare-feu, restrictions à lever sur certaines salles...)"
	Write-Host
}