# 🔍 Analyse : Doublon hcd-1.2.3/

**Date** : 2026-03-13
**Objectif** : Vérifier si `hcd-1.2.3/` à la racine est un doublon de `binaire/hcd-1.2.3/`
**Statut** : ✅ **Analyse complète**

---

## 📊 État Actuel

### Répertoires Identifiés

1. **`hcd-1.2.3/`** (à la racine)
   - Contenu : `logs/` et `resources/` uniquement
   - Taille : ~quelques MB (logs et resources seulement)
   - Usage : Probablement créé par erreur ou lors d'une installation partielle

2. **`binaire/hcd-1.2.3/`** (répertoire principal)
   - Contenu : Installation complète de HCD 1.2.3
   - Taille : ~plusieurs centaines de MB
   - Usage : Installation principale utilisée par tous les scripts

---

## 🔍 Analyse Détaillée

### Contenu de `hcd-1.2.3/` (racine)

```
hcd-1.2.3/
├── logs/
│   └── cassandra/
└── resources/
    └── cassandra/
```

**Caractéristiques** :

- ✅ Contient seulement 2 sous-répertoires : `logs/` et `resources/`
- ✅ Pas de binaires (`bin/`)
- ✅ Pas de configuration principale
- ✅ Probablement créé lors d'une tentative d'installation ou d'un démarrage HCD depuis la racine

### Contenu de `binaire/hcd-1.2.3/` (principal)

```
binaire/hcd-1.2.3/
├── bin/              # Binaires HCD
├── lib/              # Bibliothèques
├── resources/        # Ressources (incluant cassandra/)
├── logs/             # Logs (si HCD a été démarré depuis ici)
└── ... (structure complète)
```

**Caractéristiques** :

- ✅ Installation complète
- ✅ Tous les binaires présents
- ✅ Utilisé par tous les scripts via `HCD_DIR` ou `HCD_HOME`

---

## 🔗 Références dans le Code

### Configuration

**`.poc-config.sh`** :

- Utilise `binaire/hcd-1.2.3/` comme chemin par défaut
- Détection automatique : `BINAIRE_DIR/hcd-1.2.3` ou `ARKEA_HOME/binaire/hcd-1.2.3`

**`.poc-profile`** :

- Utilise maintenant `.poc-config.sh` (qui pointe vers `binaire/hcd-1.2.3/`)

### Scripts

**Tous les scripts** :

- Utilisent `HCD_DIR` ou `HCD_HOME` (défini par `.poc-config.sh`)
- Pointent vers `binaire/hcd-1.2.3/` via `setup_paths()`
- **Aucune référence** à `hcd-1.2.3/` (racine) trouvée

---

## ✅ Conclusion

### `hcd-1.2.3/` (racine) est un Doublon Partiel

**Preuves** :

1. ✅ Contient seulement `logs/` et `resources/` (pas d'installation complète)
2. ✅ Aucune référence dans les scripts ou la configuration
3. ✅ `.gitignore` l'exclut déjà du contrôle de version
4. ✅ Tous les scripts utilisent `binaire/hcd-1.2.3/`

**Origine probable** :

- Créé lors d'une tentative d'installation ou de démarrage HCD depuis la racine
- Ou lors d'une copie partielle accidentelle

---

## 🎯 Recommandations

### Option 1 : Suppression Simple (Recommandée)

**Action** : Supprimer `hcd-1.2.3/` à la racine

**Justification** :

- ✅ Pas utilisé par les scripts
- ✅ Doublon partiel (logs/resources seulement)
- ✅ `.gitignore` l'exclut déjà
- ✅ Pas de risque (installation complète dans `binaire/`)

**Commande** :

```bash
rm -rf hcd-1.2.3/
```

**Avantages** :

- ✅ Nettoyage de la structure
- ✅ Élimination de la confusion
- ✅ Pas d'impact fonctionnel

---

### Option 2 : Archivage (Si Prudent)

**Action** : Archiver avant suppression

**Commande** :

```bash
mkdir -p archive/
mv hcd-1.2.3/ archive/hcd-1.2.3-root-backup-$(date +%Y%m%d)/
```

**Avantages** :

- ✅ Possibilité de restauration si nécessaire
- ✅ Traçabilité

**Inconvénients** :

- ⚠️ Conserve un doublon (même archivé)

---

### Option 3 : Conservation (Non Recommandée)

**Action** : Garder `hcd-1.2.3/` à la racine

**Justification** : Aucune (pas utilisé)

**Inconvénients** :

- ❌ Confusion sur quel répertoire utiliser
- ❌ Pollution de la structure
- ❌ Risque d'utilisation accidentelle

---

## ✅ Recommandation Finale

**Option 1 : Suppression Simple** ✅

**Raison** :

- `hcd-1.2.3/` (racine) n'est **pas utilisé** par les scripts
- C'est un **doublon partiel** (logs/resources seulement)
- L'installation complète est dans `binaire/hcd-1.2.3/`
- `.gitignore` l'exclut déjà
- **Aucun risque** de perte de fonctionnalité

**Action Recommandée** :

```bash
# Vérification finale
ls -la hcd-1.2.3/

# Suppression
rm -rf hcd-1.2.3/

# Vérification
ls -la hcd-1.2.3/  # Devrait retourner "No such file or directory"
```

---

## 📋 Checklist de Suppression

Avant de supprimer, vérifier :

- [x] ✅ Aucune référence dans les scripts
- [x] ✅ Aucune référence dans la configuration
- [x] ✅ `.gitignore` l'exclut
- [x] ✅ Installation complète dans `binaire/hcd-1.2.3/`
- [x] ✅ Tous les scripts utilisent `HCD_DIR`/`HCD_HOME` (pointent vers `binaire/`)

**Conclusion** : ✅ **Sécurisé de supprimer**

---

## 🚀 Action Proposée

**Commande de suppression** :

```bash
cd ${ARKEA_HOME}
rm -rf hcd-1.2.3/
```

**Vérification après suppression** :

```bash
# Vérifier que binaire/hcd-1.2.3/ est toujours présent
ls -d binaire/hcd-1.2.3/

# Vérifier qu'aucun script ne référence hcd-1.2.3/ (racine)
grep -r "hcd-1.2.3/" scripts/ | grep -v "binaire/hcd-1.2.3"
```

---

**Date** : 2026-03-13
**Version** : 1.0
**Statut** : ✅ **Analyse complète - Suppression recommandée**
