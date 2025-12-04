# 📦 Archive - ARKEA

**Date** : 2025-12-02  
**Objectif** : Répertoire centralisé pour les fichiers obsolètes et les backups

---

## 📋 Structure

```
archive/
├── backups/          # Fichiers de backup (.bak, .old, .backup)
├── README.md         # Ce fichier
└── ...
```

---

## 📁 Contenu

### backups/

Contient les fichiers de backup créés lors des modifications de scripts :

- Fichiers `.bak` : Backups de scripts avant modifications
- Fichiers `.old` : Versions anciennes de fichiers
- Fichiers `.backup` : Autres backups

---

## 🔍 Origine des Fichiers

### domiramaCatOps/scripts/*.bak

Fichiers de backup créés lors de la migration et correction des scripts du POC DomiramaCatOps.

**Date de déplacement** : 2025-12-02  
**Nombre de fichiers** : ~74 fichiers

---

## 📝 Notes

- Les fichiers dans `archive/` ne sont **pas suivis par Git** (via `.gitignore`)
- Les fichiers peuvent être supprimés après validation que les versions actuelles fonctionnent correctement
- Conserver les fichiers pendant au moins 30 jours après la dernière modification

---

**Date** : 2025-12-02  
**Version** : 1.0.0
