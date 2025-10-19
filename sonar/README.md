# Configuration SonarCloud pour le projet SAE 501

Ce dossier contient la configuration nécessaire pour l'analyse de code avec SonarCloud.

## Prérequis

1. Un compte [SonarCloud](https://sonarcloud.io/)
2. Un jeton d'accès SonarCloud (à générer dans votre compte)
3. Flutter SDK installé
4. Plugin SonarScanner installé

## Configuration initiale

1. Créez un projet sur SonarCloud
2. Récupérez votre jeton d'accès
3. Configurez les variables d'environnement :
   ```bash
   export SONAR_TOKEN=votre_jeton_sonarcloud
   export SONAR_HOST=https://sonarcloud.io
   ```

## Exécution de l'analyse

Depuis le dossier racine du projet, exécutez :

```bash
cd c:\Users\nerfc\Desktop\BUT\3A\SAE_501\sonar
.\run_analysis.ps1
```

## Configuration CI/CD

Pour une intégration continue, ajoutez ces étapes à votre workflow :

1. Installation des dépendances
2. Exécution des tests
3. Génération du rapport de couverture
4. Exécution de l'analyse SonarCloud

## Personnalisation

Vous pouvez modifier le fichier `sonar-project.properties` pour :
- Ajouter des exclusions de fichiers
- Configurer des règles d'analyse spécifiques
- Ajuster les paramètres de qualité
