
# 📊 Rapport d'Entraînement YOLOv8

**Date** : 07 Février 2026
**Modèle** : `best.pt` (Epoch 30/100 - Early Stopping à 45)
**Dataset** : 19 953 images (Équilibré)

## 🏆 Performance Globale

Le modèle a atteint des performances exceptionnelles très rapidement grâce à la qualité et l'équilibre du jeu de données.

| Métrique | Valeur | Signification |
| :--- | :--- | :--- |
| **mAP50** | **96.5%** | Précision moyenne avec un seuil de chevauchement de 50%. Excellent. |
| **mAP50-95** | **94.7%** | Précision moyenne stricte (seuil 50% à 95%). Très robuste. |
| **Précision** | **92.5%** | Taux de vrais positifs (peu de fausses alertes). |
| **Rappel** | **99.8%** | Taux de détection (presque aucun panneau manqué). |

## 🛑 Early Stopping

L'entraînement s'est arrêté à l'époque **45** car le modèle n'a pas amélioré ses performances pendant 15 époques consécutives (patience).
- **Meilleure époque** : 30
- **Pourquoi ?** Le modèle a convergé très vite. Continuer aurait risqué le sur-apprentissage (overfitting). C'est un comportement sain et attendu.

## 🚀 Déploiement

Le fichier `best.pt` a été automatiquement déployé dans :
`/var/www/nounours/API/python-api/models/best.pt`

L'API utilisera ce nouveau modèle au prochain redémarrage.
