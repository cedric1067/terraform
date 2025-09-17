# Exemple de configuration pour le script Install-DAGExchange.ps1
# Copiez ce fichier et modifiez les valeurs selon votre environnement

# Configuration du DAG
$DAGName = "DAG01"                    # Nom de votre DAG
$WitnessServer = "DC01"               # Nom de votre contrôleur de domaine
$WitnessDirectory = "C:\DAGWitness"   # Répertoire témoin sur le DC
$MailboxServers = @("MBX01", "MBX02") # Liste de vos serveurs Exchange
$ExchangeServer = "MBX01"             # Serveur Exchange où exécuter le script

# Exemple d'exécution
Write-Host "Exemple d'exécution du script DAG Exchange:" -ForegroundColor Green
Write-Host ".\Install-DAGExchange.ps1 -DAGName '$DAGName' -WitnessServer '$WitnessServer' -WitnessDirectory '$WitnessDirectory' -MailboxServers @('$($MailboxServers -join "','")') -ExchangeServer '$ExchangeServer'" -ForegroundColor Cyan

# Exécution automatique (décommentez pour utiliser)
# .\Install-DAGExchange.ps1 -DAGName $DAGName -WitnessServer $WitnessServer -WitnessDirectory $WitnessDirectory -MailboxServers $MailboxServers -ExchangeServer $ExchangeServer