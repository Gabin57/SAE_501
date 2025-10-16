# Script d'analyse SonarCloud pour le projet SAE 501
# Prérequis : SonarScanner installé et configuré

# Configuration directe
$SonarToken = "048bc84e4f3feaf68e831da4af2bd777de1ba294"
$ProjectKey = "Gabin57_SAE_501"

# Vérification du scanner SonarQube local
$sonarScannerPath = "$PSScriptRoot\sonar-scanner-5.0.1.3006-windows\bin\sonar-scanner.bat"
if (-not (Test-Path $sonarScannerPath)) {
    Write-Error "Le scanner SonarQube n'a pas été trouvé. Assurez-vous qu'il est correctement extrait dans $PSScriptRoot"
    exit 1
}
Write-Host "Scanner SonarQube trouvé : $sonarScannerPath"

# Vérification du token
if ([string]::IsNullOrEmpty($SonarToken)) {
    Write-Error "Le token SonarCloud est requis"
    exit 1
}

# Exécution de l'analyse
Write-Host "Démarrage de l'analyse SonarCloud..." -ForegroundColor Cyan

$sonarArgs = @(
    "-Dsonar.projectKey=$ProjectKey",
    "-Dsonar.host.url=https://sonarcloud.io",
    "-Dsonar.login=$SonarToken",
    "-Dproject.settings=sonar-project.properties"
)

# Exécution de la commande
& $sonarScannerPath $sonarArgs

# Vérification du code de sortie
if ($LASTEXITCODE -ne 0) {
    Write-Error "L'analyse SonarCloud a échoué avec le code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Analyse SonarCloud terminée avec succès!" -ForegroundColor Green
