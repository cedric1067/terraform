#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Script PowerShell pour installer et configurer un DAG (Database Availability Group) Exchange Server

.DESCRIPTION
    Ce script automatise l'installation et la configuration d'un DAG Exchange Server.
    Il inclut la création du dossier témoin, la configuration des permissions,
    la création du DAG et l'ajout des serveurs membres.

.PARAMETER DAGName
    Nom du DAG à créer

.PARAMETER WitnessServer
    Nom du serveur témoin (généralement un contrôleur de domaine)

.PARAMETER WitnessDirectory
    Répertoire témoin sur le serveur témoin

.PARAMETER MailboxServers
    Liste des serveurs de boîtes aux lettres à ajouter au DAG

.PARAMETER ExchangeServer
    Serveur Exchange où exécuter les commandes

.EXAMPLE
    .\Install-DAGExchange.ps1 -DAGName "DAG01" -WitnessServer "DC01" -WitnessDirectory "C:\DAGWitness" -MailboxServers @("MBX01","MBX02") -ExchangeServer "MBX01"

.NOTES
    Auteur: Assistant IA
    Version: 1.0
    Date: $(Get-Date -Format "yyyy-MM-dd")
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DAGName,
    
    [Parameter(Mandatory = $true)]
    [string]$WitnessServer,
    
    [Parameter(Mandatory = $true)]
    [string]$WitnessDirectory,
    
    [Parameter(Mandatory = $true)]
    [string[]]$MailboxServers,
    
    [Parameter(Mandatory = $false)]
    [string]$ExchangeServer = $env:COMPUTERNAME
)

# Fonction pour écrire des messages colorés
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Fonction pour vérifier si Exchange Management Shell est disponible
function Test-ExchangeManagementShell {
    try {
        Get-Command Get-ExchangeServer -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Fonction pour créer le dossier témoin et configurer les permissions
function New-WitnessDirectory {
    param(
        [string]$Server,
        [string]$Directory
    )
    
    Write-ColorOutput "Configuration du dossier témoin sur $Server..." "Yellow"
    
    try {
        # Créer le dossier témoin
        Invoke-Command -ComputerName $Server -ScriptBlock {
            param($Dir)
            if (-not (Test-Path $Dir)) {
                New-Item -Path $Dir -ItemType Directory -Force
                Write-Host "Dossier témoin créé: $Dir" -ForegroundColor Green
            } else {
                Write-Host "Dossier témoin existe déjà: $Dir" -ForegroundColor Yellow
            }
        } -ArgumentList $WitnessDirectory
        
        # Configurer les permissions pour Exchange Trusted Subsystem
        Invoke-Command -ComputerName $Server -ScriptBlock {
            param($Dir)
            $acl = Get-Acl $Dir
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Exchange Trusted Subsystem", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($accessRule)
            Set-Acl -Path $Dir -AclObject $acl
            Write-Host "Permissions configurées pour Exchange Trusted Subsystem" -ForegroundColor Green
        } -ArgumentList $WitnessDirectory
        
        return $true
    }
    catch {
        Write-ColorOutput "Erreur lors de la configuration du dossier témoin: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Fonction pour créer le DAG
function New-DatabaseAvailabilityGroup {
    param(
        [string]$Name,
        [string]$WitnessServer,
        [string]$WitnessDirectory
    )
    
    Write-ColorOutput "Création du DAG: $Name..." "Yellow"
    
    try {
        # Vérifier si le DAG existe déjà
        $existingDAG = Get-DatabaseAvailabilityGroup -Identity $Name -ErrorAction SilentlyContinue
        if ($existingDAG) {
            Write-ColorOutput "Le DAG '$Name' existe déjà." "Yellow"
            return $true
        }
        
        # Créer le DAG
        New-DatabaseAvailabilityGroup -Name $Name -WitnessServer $WitnessServer -WitnessDirectory $WitnessDirectory
        Write-ColorOutput "DAG '$Name' créé avec succès!" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "Erreur lors de la création du DAG: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Fonction pour ajouter des serveurs au DAG
function Add-ServersToDAG {
    param(
        [string]$DAGName,
        [string[]]$Servers
    )
    
    Write-ColorOutput "Ajout des serveurs au DAG..." "Yellow"
    
    foreach ($server in $Servers) {
        try {
            Write-ColorOutput "Ajout du serveur: $server" "Cyan"
            
            # Vérifier si le serveur est déjà membre du DAG
            $dagMembers = Get-DatabaseAvailabilityGroupServer -Identity $DAGName -ErrorAction SilentlyContinue
            if ($dagMembers -and ($dagMembers.Name -contains $server)) {
                Write-ColorOutput "Le serveur '$server' est déjà membre du DAG." "Yellow"
                continue
            }
            
            # Ajouter le serveur au DAG
            Add-DatabaseAvailabilityGroupServer -Identity $DAGName -MailboxServer $server
            Write-ColorOutput "Serveur '$server' ajouté au DAG avec succès!" "Green"
        }
        catch {
            Write-ColorOutput "Erreur lors de l'ajout du serveur '$server': $($_.Exception.Message)" "Red"
        }
    }
}

# Fonction pour afficher les informations du DAG
function Show-DAGInformation {
    param(
        [string]$DAGName
    )
    
    Write-ColorOutput "`n=== INFORMATIONS DU DAG ===" "Magenta"
    
    try {
        $dag = Get-DatabaseAvailabilityGroup -Identity $DAGName
        Write-ColorOutput "Nom du DAG: $($dag.Name)" "White"
        Write-ColorOutput "Serveur témoin: $($dag.WitnessServer)" "White"
        Write-ColorOutput "Répertoire témoin: $($dag.WitnessDirectory)" "White"
        Write-ColorOutput "État: $($dag.OperationalState)" "White"
        
        Write-ColorOutput "`nServeurs membres:" "Cyan"
        $members = Get-DatabaseAvailabilityGroupServer -Identity $DAGName
        foreach ($member in $members) {
            Write-ColorOutput "  - $($member.Name) (État: $($member.OperationalState))" "White"
        }
    }
    catch {
        Write-ColorOutput "Erreur lors de la récupération des informations du DAG: $($_.Exception.Message)" "Red"
    }
}

# Fonction principale
function Main {
    Write-ColorOutput "=== SCRIPT D'INSTALLATION DAG EXCHANGE ===" "Magenta"
    Write-ColorOutput "Démarrage de l'installation..." "Green"
    
    # Vérifications préliminaires
    Write-ColorOutput "`n1. Vérifications préliminaires..." "Yellow"
    
    # Vérifier si Exchange Management Shell est disponible
    if (-not (Test-ExchangeManagementShell)) {
        Write-ColorOutput "ERREUR: Exchange Management Shell n'est pas disponible sur ce serveur." "Red"
        Write-ColorOutput "Veuillez exécuter ce script sur un serveur Exchange ou importer le module Exchange." "Red"
        exit 1
    }
    Write-ColorOutput "✓ Exchange Management Shell disponible" "Green"
    
    # Vérifier la connectivité avec le serveur témoin
    Write-ColorOutput "Vérification de la connectivité avec le serveur témoin..." "Yellow"
    if (-not (Test-Connection -ComputerName $WitnessServer -Count 1 -Quiet)) {
        Write-ColorOutput "ERREUR: Impossible de contacter le serveur témoin '$WitnessServer'" "Red"
        exit 1
    }
    Write-ColorOutput "✓ Connectivité avec le serveur témoin OK" "Green"
    
    # Vérifier la connectivité avec les serveurs de boîtes aux lettres
    foreach ($server in $MailboxServers) {
        Write-ColorOutput "Vérification de la connectivité avec $server..." "Yellow"
        if (-not (Test-Connection -ComputerName $server -Count 1 -Quiet)) {
            Write-ColorOutput "ERREUR: Impossible de contacter le serveur '$server'" "Red"
            exit 1
        }
        Write-ColorOutput "✓ Connectivité avec $server OK" "Green"
    }
    
    # 2. Configuration du dossier témoin
    Write-ColorOutput "`n2. Configuration du dossier témoin..." "Yellow"
    if (-not (New-WitnessDirectory -Server $WitnessServer -Directory $WitnessDirectory)) {
        Write-ColorOutput "ERREUR: Échec de la configuration du dossier témoin" "Red"
        exit 1
    }
    
    # 3. Création du DAG
    Write-ColorOutput "`n3. Création du DAG..." "Yellow"
    if (-not (New-DatabaseAvailabilityGroup -Name $DAGName -WitnessServer $WitnessServer -WitnessDirectory $WitnessDirectory)) {
        Write-ColorOutput "ERREUR: Échec de la création du DAG" "Red"
        exit 1
    }
    
    # 4. Ajout des serveurs au DAG
    Write-ColorOutput "`n4. Ajout des serveurs au DAG..." "Yellow"
    Add-ServersToDAG -DAGName $DAGName -Servers $MailboxServers
    
    # 5. Affichage des informations finales
    Show-DAGInformation -DAGName $DAGName
    
    Write-ColorOutput "`n=== INSTALLATION TERMINÉE ===" "Magenta"
    Write-ColorOutput "Le DAG '$DAGName' a été configuré avec succès!" "Green"
    Write-ColorOutput "`nProchaines étapes recommandées:" "Yellow"
    Write-ColorOutput "1. Vérifier l'état des services de clustering sur tous les serveurs" "White"
    Write-ColorOutput "2. Configurer les bases de données de boîtes aux lettres pour la haute disponibilité" "White"
    Write-ColorOutput "3. Tester le basculement automatique" "White"
    Write-ColorOutput "4. Configurer la surveillance et les alertes" "White"
}

# Exécution du script principal
try {
    Main
}
catch {
    Write-ColorOutput "ERREUR CRITIQUE: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" "Red"
    exit 1
}