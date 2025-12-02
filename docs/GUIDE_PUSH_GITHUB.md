# 🚀 Guide : Pousser le Dépôt Git Local vers GitHub

**Date** : 2025-12-02  
**Objectif** : Instructions pour envoyer le dépôt Git local vers GitHub.com  
**Auteur** : David LECONTE

---

## 📋 Prérequis

### 1. Compte GitHub

- ✅ Compte GitHub actif : `davidleconte` (ou votre username)
- ✅ Accès Internet
- ✅ Authentification configurée (token, SSH, ou credentials)

### 2. Dépôt GitHub

**Option A** : Dépôt existe déjà sur GitHub

- URL : `https://github.com/davidleconte/Arkea.git` (ou votre URL)

**Option B** : Créer un nouveau dépôt sur GitHub

1. Aller sur <https://github.com/new>
2. Nom du dépôt : `Arkea` (ou autre nom)
3. Description : "POC Migration HBase → HCD"
4. Visibilité : Private (recommandé) ou Public
5. **NE PAS** initialiser avec README, .gitignore, ou licence (déjà présents)
6. Cliquer sur "Create repository"

---

## 🔧 Configuration

### 1. Vérifier la Configuration Git

```bash
# Vérifier l'utilisateur Git
git config user.name
git config user.email

# Si nécessaire, configurer
git config user.name "David LECONTE"
git config user.email "david.leconte1@ibm.com"
```

### 2. Vérifier les Remotes

```bash
# Lister les remotes existants
git remote -v

# Si aucun remote n'existe, vous verrez rien
```

---

## 🚀 Méthode 1 : HTTPS (Recommandé pour début)

### Étape 1 : Ajouter le Remote

```bash
cd /Users/david.leconte/Documents/Arkea

# Ajouter le remote GitHub
git remote add origin https://github.com/davidleconte/Arkea.git

# Vérifier
git remote -v
```

**Résultat attendu** :

```bash
origin  https://github.com/davidleconte/Arkea.git (fetch)
origin  https://github.com/davidleconte/Arkea.git (push)
```

### Étape 2 : Renommer la Branche (si nécessaire)

```bash
# S'assurer que la branche principale s'appelle 'main'
git branch -M main
```

### Étape 3 : Pousser vers GitHub

```bash
# Première fois : pousser et configurer le tracking
git push -u origin main
```

**Authentification** :

- Si demandé, utiliser un **Personal Access Token (PAT)**
- **NE PAS** utiliser votre mot de passe GitHub
- Voir section "Authentification" ci-dessous

---

## 🔐 Méthode 2 : SSH (Recommandé pour usage régulier)

### Étape 1 : Vérifier la Clé SSH

```bash
# Vérifier si une clé SSH existe
ls -la ~/.ssh/id_*.pub

# Si aucune clé n'existe, en créer une
ssh-keygen -t ed25519 -C "david.leconte1@ibm.com"
```

### Étape 2 : Ajouter la Clé SSH à GitHub

1. Copier la clé publique :

```bash
cat ~/.ssh/id_ed25519.pub
# Ou pour macOS
pbcopy < ~/.ssh/id_ed25519.pub
```

1. Sur GitHub :
   - Aller sur <https://github.com/settings/keys>
   - Cliquer "New SSH key"
   - Coller la clé
   - Sauvegarder

### Étape 3 : Configurer le Remote SSH

```bash
# Supprimer le remote HTTPS (si existant)
git remote remove origin

# Ajouter le remote SSH
git remote add origin git@github.com:davidleconte/Arkea.git

# Vérifier
git remote -v
```

### Étape 4 : Pousser

```bash
git push -u origin main
```

---

## 🔑 Authentification HTTPS (Personal Access Token)

### Créer un Personal Access Token

1. Aller sur <https://github.com/settings/tokens>
2. Cliquer "Generate new token" → "Generate new token (classic)"
3. Nom : `ARKEA-POC` (ou autre)
4. Expiration : 90 jours (ou plus)
5. Scopes : Cocher `repo` (accès complet aux dépôts)
6. Générer et **COPIER LE TOKEN** (ne sera plus affiché)

### Utiliser le Token

Lors du `git push`, utiliser :

- **Username** : `davidleconte` (votre username GitHub)
- **Password** : Le **Personal Access Token** (pas votre mot de passe)

### Stocker le Token (Optionnel)

```bash
# macOS Keychain
git credential-osxkeychain store
# Puis entrer : https://davidleconte@github.com
# Password : [votre token]

# Ou utiliser Git Credential Manager
git config --global credential.helper osxkeychain
```

---

## 📊 Vérification

### Après le Push

```bash
# Vérifier que le remote est configuré
git remote -v

# Vérifier le statut
git status

# Vérifier les branches distantes
git branch -a

# Voir les commits sur GitHub
git log --oneline --graph --all
```

### Sur GitHub.com

1. Aller sur <https://github.com/davidleconte/Arkea>
2. Vérifier que les fichiers sont présents
3. Vérifier les commits dans l'historique

---

## ⚠️ Problèmes Courants

### Erreur : "remote origin already exists"

```bash
# Vérifier le remote actuel
git remote -v

# Si l'URL est incorrecte, la modifier
git remote set-url origin https://github.com/davidleconte/Arkea.git

# Ou supprimer et recréer
git remote remove origin
git remote add origin https://github.com/davidleconte/Arkea.git
```

### Erreur : "Authentication failed"

**Solutions** :

1. Vérifier que vous utilisez un **Personal Access Token** (pas le mot de passe)
2. Vérifier que le token a les permissions `repo`
3. Régénérer un nouveau token si nécessaire

### Erreur : "Repository not found"

**Solutions** :

1. Vérifier que le dépôt existe sur GitHub
2. Vérifier que vous avez les droits d'accès
3. Vérifier l'URL du remote : `git remote -v`

### Erreur : "Large files detected"

Si Git détecte des fichiers > 100 MB :

```bash
# Vérifier les gros fichiers
find . -type f -size +100M -not -path "./.git/*"

# Ajouter au .gitignore si nécessaire
echo "binaire/hcd-1.2.3/" >> .gitignore
echo "binaire/spark-3.5.1/" >> .gitignore
```

---

## 🎯 Commandes Complètes (Résumé)

### Pour un Nouveau Dépôt GitHub

```bash
cd /Users/david.leconte/Documents/Arkea

# 1. Vérifier l'état
git status

# 2. S'assurer que tout est commité
git add .
git commit -m "Initial commit"  # Si nécessaire

# 3. Ajouter le remote
git remote add origin https://github.com/davidleconte/Arkea.git

# 4. Renommer la branche
git branch -M main

# 5. Pousser
git push -u origin main
```

### Pour un Dépôt GitHub Existant

```bash
# Si le remote existe déjà mais l'URL est incorrecte
git remote set-url origin https://github.com/davidleconte/Arkea.git

# Pousser
git push -u origin main
```

---

## 📝 Notes Importantes

### Fichiers à Exclure

Le `.gitignore` devrait déjà exclure :

- `binaire/` (binaires volumineux)
- `logs/` (logs)
- `data/` (données générées)
- `*.parquet` (fichiers de données)

### Taille du Dépôt

- **Taille actuelle** : ~2.6 GB (avec .git)
- **Taille .git** : 1.0 GB
- **Fichiers trackés** : 1.1 GB

**Recommandation** : Vérifier que les binaires sont bien dans
`.gitignore` avant de pousser.

---

## ✅ Checklist Avant de Pousser

- [ ] Vérifier que `.gitignore` exclut les binaires
- [ ] Vérifier que tous les changements sont commités
- [ ] Vérifier l'URL du remote GitHub
- [ ] Avoir un Personal Access Token (HTTPS) ou clé SSH configurée
- [ ] Le dépôt GitHub existe (ou est créé)
- [ ] Authentification testée

---

## 🔄 Commandes de Mise à Jour Futures

Une fois le remote configuré, pour pousser les futurs commits :

```bash
# Pousser les commits locaux
git push

# Ou explicitement
git push origin main
```

Pour récupérer les changements depuis GitHub :

```bash
# Récupérer les changements
git fetch origin

# Fusionner
git merge origin/main

# Ou en une commande
git pull origin main
```

---

**Date** : 2025-12-02  
**Version** : 1.0.0  
**Statut** : ✅ Guide complet
