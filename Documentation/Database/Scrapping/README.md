# Base de données des panneaux de signalisation

Ce dossier contient un script pour récupérer automatiquement les panneaux et créer une base SQLite avec les métadonnées et les images locales.

## Sources
- https://fr.wikibooks.org/wiki/Code_de_la_route/Liste_des_panneaux
- https://fr.wikibooks.org/wiki/Code_de_la_route/Signalisation_dynamique

## Sorties
- `panneaux.csv` : export CSV avec les colonnes : `id`, `name`, `description`, `type`, `source_url`, `image_url`, `image_path`
- `panneaux.sql` : script SQL (CREATE TABLE + INSERT IGNORE) importable dans phpMyAdmin
- `panneaux.db` (optionnel si `SAVE_SQLITE_FILE=True`) : base SQLite locale
- `images/` : dossier des images téléchargées en local

## Prérequis
- Python 3.9+
- Dépendances (à installer depuis ce dossier) :

```bash
python -m pip install -r requirements.txt
```

## Utilisation
Depuis `Documentation/Database` :

```bash
python scrape_signaux.py
```

Le script va :
- Scraper les deux pages Wikibooks,
- Extraire les noms, descriptions (si disponibles) et images,
- Déterminer un type logique par source (`liste_des_panneaux` ou `signalisation_dynamique`),
- Exporter `panneaux.csv` et `panneaux.sql` (compatibles phpMyAdmin),
- Optionnel: créer `panneaux.db` si `SAVE_SQLITE_FILE=True`.

## Notes
- Les pages MediaWiki évoluent : le parseur est robuste mais heuristique. Si un bloc n'est pas détecté (galerie/thumbnail/listes), ouvrez une issue avec un exemple.
- Les images sont stockées en taille originale quand possible (heuristique Wikimedia `/thumb/` -> original).
