# 📦 Archives des Scripts - domiramaCatOps

**Date de création** : 2025-01-XX  
**Objectif** : Sauvegardes des répertoires `scripts/` avant modifications

---

## 📋 Contenu

Ce répertoire contient les archives complètes du répertoire `scripts/` créées avant toute modification majeure.

---

## 📁 Archives Disponibles

Les archives sont nommées avec le format :

```
scripts_backup_YYYYMMDD_HHMMSS.tar.gz
```

**Contenu** :

- Tous les fichiers `.sh` du répertoire `scripts/`
- Tous les fichiers `.py` du répertoire `scripts/`
- Tous les fichiers `.cql` du répertoire `scripts/`
- Structure complète des sous-répertoires

---

## 🔄 Restauration

Pour restaurer une archive :

```bash
cd /Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps
tar -xzf archive/scripts_backups/scripts_backup_YYYYMMDD_HHMMSS.tar.gz
```

**⚠️ Attention** : Cela écrasera le répertoire `scripts/` actuel.

---

## 📝 Notes

- Les archives sont créées avant toute modification majeure
- Chaque archive contient un snapshot complet du répertoire `scripts/`
- Les archives sont compressées (tar.gz) pour économiser l'espace

---

**Date de création** : 2025-01-XX
