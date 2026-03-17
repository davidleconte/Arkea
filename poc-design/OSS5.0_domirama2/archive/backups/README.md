# 📦 Sauvegardes des Scripts Shell

**Date** : 2025-01-XX
**Objectif** : Sauvegardes des scripts originaux avant migration

---

## 📋 Contenu

Ce répertoire contient les sauvegardes (`.bak`) de tous les scripts shell qui ont été migrés pour implémenter les priorités 1, 2 et 3 de l'audit.

**Migration effectuée** :

- ✅ Priorité 1 : Standardisation des chemins (détection automatique)
- ✅ Priorité 2 : Standardisation localhost/port (variables d'environnement)
- ✅ Priorité 3 : Amélioration gestion d'erreurs (`set -euo pipefail`)

---

## 🔄 Restauration

Pour restaurer un script original :

```bash
# Restaurer un script spécifique
cp archive/backups/10_setup_domirama2_poc.sh.bak ../10_setup_domirama2_poc.sh

# Restaurer tous les scripts
cd archive/backups
for bak in *.bak; do
    cp "$bak" "../../${bak%.bak}"
done
```

---

## 📊 Statistiques

- **Nombre de sauvegardes** : 58 fichiers `.bak`
- **Date de migration** : 2025-01-XX
- **Script de migration** : `migrate_all_scripts.py`

---

**Note** : Ces fichiers peuvent être supprimés après validation complète de la migration.
