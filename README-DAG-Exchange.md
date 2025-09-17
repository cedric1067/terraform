# Script PowerShell pour l'installation de DAG Exchange

Ce package contient des scripts PowerShell pour automatiser l'installation et la configuration d'un DAG (Database Availability Group) Exchange Server.

## Fichiers inclus

- `Install-DAGExchange.ps1` - Script principal d'installation
- `DAG-Config-Example.ps1` - Fichier de configuration d'exemple
- `README-DAG-Exchange.md` - Ce fichier de documentation

## Prérequis

1. **Exchange Server** installé et configuré
2. **Exchange Management Shell** disponible
3. **Permissions d'administrateur** sur tous les serveurs
4. **Clustering de basculement Windows** installé sur les serveurs Exchange
5. **Connectivité réseau** entre tous les serveurs

## Utilisation

### 1. Configuration

Modifiez le fichier `DAG-Config-Example.ps1` avec vos paramètres :

```powershell
$DAGName = "DAG01"                    # Nom de votre DAG
$WitnessServer = "DC01"               # Contrôleur de domaine
$WitnessDirectory = "C:\DAGWitness"   # Répertoire témoin
$MailboxServers = @("MBX01", "MBX02") # Serveurs Exchange
$ExchangeServer = "MBX01"             # Serveur d'exécution
```

### 2. Exécution

Ouvrez PowerShell en tant qu'administrateur et exécutez :

```powershell
.\Install-DAGExchange.ps1 -DAGName "DAG01" -WitnessServer "DC01" -WitnessDirectory "C:\DAGWitness" -MailboxServers @("MBX01","MBX02") -ExchangeServer "MBX01"
```

### 3. Paramètres du script

| Paramètre | Obligatoire | Description |
|-----------|-------------|-------------|
| `-DAGName` | Oui | Nom du DAG à créer |
| `-WitnessServer` | Oui | Nom du serveur témoin (DC) |
| `-WitnessDirectory` | Oui | Répertoire témoin sur le DC |
| `-MailboxServers` | Oui | Liste des serveurs Exchange |
| `-ExchangeServer` | Non | Serveur d'exécution (défaut: local) |

## Fonctionnalités du script

### Vérifications automatiques
- Disponibilité d'Exchange Management Shell
- Connectivité réseau avec tous les serveurs
- Existence des serveurs et services

### Configuration automatique
- Création du dossier témoin
- Configuration des permissions (Exchange Trusted Subsystem)
- Création du DAG
- Ajout des serveurs membres

### Gestion d'erreurs
- Messages d'erreur détaillés
- Vérification des prérequis
- Gestion des cas d'échec

## Exemple de sortie

```
=== SCRIPT D'INSTALLATION DAG EXCHANGE ===
Démarrage de l'installation...

1. Vérifications préliminaires...
✓ Exchange Management Shell disponible
✓ Connectivité avec le serveur témoin OK
✓ Connectivité avec MBX01 OK
✓ Connectivité avec MBX02 OK

2. Configuration du dossier témoin...
Dossier témoin créé: C:\DAGWitness
Permissions configurées pour Exchange Trusted Subsystem

3. Création du DAG...
DAG 'DAG01' créé avec succès!

4. Ajout des serveurs au DAG...
Serveur 'MBX01' ajouté au DAG avec succès!
Serveur 'MBX02' ajouté au DAG avec succès!

=== INFORMATIONS DU DAG ===
Nom du DAG: DAG01
Serveur témoin: DC01
Répertoire témoin: C:\DAGWitness
État: Operational

Serveurs membres:
  - MBX01 (État: Operational)
  - MBX02 (État: Operational)

=== INSTALLATION TERMINÉE ===
Le DAG 'DAG01' a été configuré avec succès!
```

## Prochaines étapes

Après l'installation du DAG, il est recommandé de :

1. **Vérifier l'état des services** de clustering sur tous les serveurs
2. **Configurer les bases de données** de boîtes aux lettres pour la haute disponibilité
3. **Tester le basculement automatique** entre les serveurs
4. **Configurer la surveillance** et les alertes
5. **Documenter la configuration** pour l'équipe de support

## Dépannage

### Erreurs courantes

**"Exchange Management Shell n'est pas disponible"**
- Vérifiez que Exchange Server est installé
- Exécutez le script sur un serveur Exchange
- Importez le module Exchange si nécessaire

**"Impossible de contacter le serveur témoin"**
- Vérifiez la connectivité réseau
- Vérifiez que le serveur témoin est accessible
- Vérifiez les paramètres de pare-feu

**"Erreur lors de la création du DAG"**
- Vérifiez que le clustering de basculement est installé
- Vérifiez les permissions sur le serveur témoin
- Vérifiez que le DAG n'existe pas déjà

### Commandes utiles

```powershell
# Vérifier l'état du DAG
Get-DatabaseAvailabilityGroup -Identity "DAG01"

# Vérifier les serveurs membres
Get-DatabaseAvailabilityGroupServer -Identity "DAG01"

# Vérifier l'état des services de clustering
Get-ClusterNode

# Vérifier les bases de données
Get-MailboxDatabase | Where-Object {$_.MasterServerOrAvailabilityGroup -eq "DAG01"}
```

## Support

Pour toute question ou problème, consultez :
- Documentation officielle Microsoft Exchange
- Forums de la communauté Exchange
- Support technique Microsoft

## Version

- Version: 1.0
- Date: $(Get-Date -Format "yyyy-MM-dd")
- Compatible avec: Exchange Server 2016/2019