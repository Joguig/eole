$error.Clear()
Clear

$NomCompletDuScriptActuel = $MyInvocation.MyCommand.Definition
$CheminBackup = Split-Path -Path $NomCompletDuScriptActuel -Parent
$UneErreurAEuLieu = $False

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Droits administrateur
Write-Host
Write-Host -NoNewLine "Vérification des droits 'Administrateur' du script ..."
$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Role = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if(!$Role) { 
	Write-Host
	Write-Warning "Ce script ne fonctionnera pas sans élévation de pouvoir"
	Exit
} Else {
	Write-Host " OK"
}

# Détermination du domaine
Write-Host ; Write-Host ; Write-Host ; Write-Host ; Write-Host ; Write-Host ; Write-Host
$PositionDansDomaine = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine" -Name Distinguished-Name).'Distinguished-Name'
If ( $PositionDansDomaine.length -ne 0 ) { 
	$PosDC = $PositionDansDomaine.IndexOf("DC")
	$Domaine = $PositionDansDomaine.SubString($PosDC, $PositionDansDomaine.length - $PosDC)
	Write-Host "Structure du Domaine : $Domaine"
} Else {
	Write-Warning "Impossible de déterminer la structure du Domaine Active Directory"
	Write-Host "Votre ordinateur doit être intégré au domaine."
	Exit
}

# Détermination du système d'exploitation et installation de RSAT
$OSVersion = (Get-WmiObject Win32_OperatingSystem).Version
$OSVersion = $OSVersion.SubString(0, 3)
$OSProductType = (Get-WmiObject Win32_OperatingSystem).ProductType

Write-Host
If ( $OSVersion -eq "10." ) {
	Switch ( $OSProductType ) {
		"1" { Write-Host "Nous sommes sur un Windows 10."
				Write-Host "Téléchargez RSAT sur https://www.microsoft.com/fr-fr/download/details.aspx?id=45520"
				Read-Host "Appuyez sur 'Entrée' pour continuer (ou fermez et relancez le script) une fois RSAT installé."
			}
		"2" { Write-Host "Nous sommes sur un Windows 2016 Server Controleur de Domaine AD. Au revoir..." 
			Exit }
		"3" { Write-Host -NoNewLine "Nous sommes sur un "
			Write-Host "Windows 2016 Server non Controleur de Domaine AD" -ForegroundColor Yellow
			Write-Host "Installation des fonctionnalités :" -ForegroundColor Green
			Write-Host " 'DNS'..."
			Install-WindowsFeature -Name RSAT-DNS-Server -IncludeManagementTools 1>$Null
			Write-Host " 'Gestion des stratégies de groupes'..."
			Install-WindowsFeature -Name GPMC -IncludeManagementTools 1>$Null
			Write-Host " 'Sites et services Active Directory' & 'Utilisateurs et ordinateurs Active Directory'..."
			Install-WindowsFeature -Name RSAT-AD-AdminCenter -IncludeManagementTools 1>$Null
        }
	}
} Else {
	Write-Warning "Le système est un Windows hors gestion. Au revoir..."
	Exit
}
Write-Host " Copie du fichier RSAT.msc de console et création du raccourci sur le bureau..."
Try { Copy-Item -Path "$CheminBackup\RSAT.msc" -Destination "C:\Windows\System32\" -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichier déjà existant ..." }
Catch { Write-Host "Un souci  à eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
# $BureauCourant = [Environment]::GetFolderPath("Desktop")
$BureauCourant = ([Environment]::GetEnvironmentVariable("Public"))+"\Desktop"
Copy-Item -Path "$CheminBackup\RSAT.msc.lnk" -Destination "$BureauCourant\" -Force 1>$Null
Write-Host "Installation terminée" -ForegroundColor Green

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Importation des stratégies
Write-Host 
Write-Host "Importation des stratégies :" -ForegroundColor Green
Get-ChildItem $CheminBackup -Directory -Depth 0 | %{ 
	$FichierXML = $CheminBackup + "\" + $_.Name + "\" + "bkupInfo.xml"
	If ( Test-Path -Path $FichierXML ) {
		[xml]$ContenuTempXML = Get-Content $FichierXML -Encoding UTF8
		$NomGPO = $ContenuTempXML.BackupInst.GPODisplayName.'#cdata-section'
		
		Write-Host -NoNewLine " Création de la stratégie '$NomGPO' ..."
		Try { New-GPO $NomGPO -ErrorAction Stop 3>&1>$Null }
		Catch [System.ArgumentException] { Write-Host ; Write-Host "La GPO existe déjà... Avez-vous déjà importé les GPOs ?" -BackgroundColor Black -ForegroundColor Red
			Write-Host -NoNewLine " Pas"}
		Catch { Write-Host ; Write-Host "Une erreur a eu lieu pour la création de la GPO... Est-ce un compte avec des droits administrateur du domaine ?" -BackgroundColor Black -ForegroundColor Red
			Write-Host -NoNewLine " Pas"
			$UneErreurAEuLieu = $True}
		Write-Host " OK"
		
		Write-Host -NoNewLine " Restauration des paramètres ..."
		Try { Import-GPO -BackupId $_.Name -TargetName $NomGPO -Path $CheminBackup -CreateIfNeeded -ErrorAction Stop 3>&1>$Null }
		Catch { Write-Host "Un souci à eu lieu avec la restauration des paramètres de cette GPO..." -BackgroundColor Black -ForegroundColor Red
			Write-Host -NoNewLine " Pas"
			$UneErreurAEuLieu = $True }
		Write-Host " OK"
	}
}
Write-Host "Importation des stratégies terminée" -ForegroundColor Green
Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# BGInfo
Write-Host "Copie des fichiers BGInfo pour postes clients dans le Netlogon" -ForegroundColor Green
Write-Host -NoNewLine " Copie vers \\ADDC\netlogon\BGInfo ..."
Try { Copy-Item -Path "$CheminBackup\BGInfo" -Destination "\\ADDC\netlogon\BGInfo" -Recurse -Force -ErrorAction Stop 3>&1>$Null }
Catch [System.IO.IOException] { Write-Host -NoNewLine " Fichiers déjà existants ..." }
Catch { Write-Host "Un souci  à eu lieu pendant la copie ..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"
Write-Host "Copie des fichiers terminée" -ForegroundColor Green
Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Liaison des stratégies aux différentes OUs
Write-Host "Liaison des stratégies aux différentes OUs :" -ForegroundColor Green
Write-Host -NoNewLine " Liaison de la stratégie 'GPO Affichage BGInfo' à l'OU 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Affichage BGInfo" -Target "OU=Utilisateurs du Domaine,$Domaine" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch { Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas" 
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Configuration Machine' à l'OU 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Machine" -Target "OU=Ordinateurs du Domaine,$Domaine" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch { Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO UAC normale' à l'OU 'Ordinateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO UAC normale" -Target "OU=Ordinateurs du Domaine,$Domaine" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch { Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Configuration Environnement' à l'OU 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Configuration Environnement" -Target "OU=Utilisateurs du Domaine,$Domaine" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch { Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Redirection Dossiers' à l'OU 'Utilisateurs du Domaine' ..."
Try { $LienTemp = New-GPLink -Name "GPO Redirection Dossiers" -Target "OU=Utilisateurs du Domaine,$Domaine" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch { Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host -NoNewLine " Liaison de la stratégie 'GPO Restrictions Elèves' à l'OU 'Eleves' ..."
Try { $LienTemp = New-GPLink -Name "GPO Restrictions Elèves" -Target "OU=Eleves,OU=Utilisateurs du Domaine,$Domaine" -LinkEnabled Yes -ErrorAction Stop 3>&1>$Null }
Catch { Write-Host "Un souci à eu lieu avec la liaison de cette GPO..." -BackgroundColor Black -ForegroundColor Red 
	Write-Host -NoNewLine " Pas"
	$UneErreurAEuLieu = $True }
Write-Host " OK"

Write-Host "Liaison des stratégies aux différentes OUs terminée" -ForegroundColor Green
Write-Host ; Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If ( $UneErreurAEuLieu ) {
	Write-Host "Une ou plusieurs erreurs importantes ont eu lieu." -BackgroundColor Black -ForegroundColor Red
	Write-Host "La configuration globale du domaine est au mieux incomplète." -BackgroundColor Black -ForegroundColor Red
	Write-Host "Demandez de l'assistance..." -BackgroundColor Black -ForegroundColor Red
	Write-Host
} Else {
	Write-Host "+---------------------------------------------------+" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host "| La configuration globale du domaine est terminée. |" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host "+---------------------------------------------------+" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host
	Write-Host "Maintenant, à vous de lier les GPOs optionnelles aux OUs qui le nécessitent."
	Write-Host "(imprimantes, UAC, Pare-feu, restrictions à lever sur certaines salles...)"
	Write-Host
}