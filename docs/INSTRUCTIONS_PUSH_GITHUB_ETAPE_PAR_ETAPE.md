# 🚀 Instructions Étape par Étape : Pousser vers GitHub

**Date** : 2025-12-02  
**Guide pratique** : Instructions détaillées pour pousser le dépôt ARKEA vers GitHub

---

## 📋 Vue d'Ensemble

**Objectif** : Envoyer le dépôt Git local vers <https://github.com/davidleconte/Arkea>

**Durée estimée** : 10-15 minutes

**Prérequis** :

- ✅ Compte GitHub : `davidleconte`
- ✅ Accès Internet
- ✅ Personal Access Token GitHub (à créer)

---

## 🎯 ÉTAPE 1 : Créer le Personal Access Token (5 minutes)

### 1.1 Aller sur GitHub Settings

1. Ouvrir <https://github.com/settings/tokens>
2. Se connecter avec votre compte GitHub (`davidleconte`)

### 1.2 Générer un Nouveau Token

1. Cliquer sur **"Generate new token"** → **"Generate new token (classic)"**
2. **Note** : `ARKEA-POC-2025-12-02`
3. **Expiration** : 90 days (ou plus selon vos besoins)
4. **Scopes** : Cocher **`repo`** (accès complet aux dépôts privés)
   - ✅ repo (Full control of private repositories)
5. Cliquer sur **"Generate token"** en bas de la page

### 1.3 Copier le Token

⚠️ **IMPORTANT** : Copier le token immédiatement (il ne sera plus affiché) !

**Exemple** : `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**Sauvegarder** le token dans un endroit sûr (Keychain,
gestionnaire de mots de passe, etc.)

---

## 🎯 ÉTAPE 2 : Créer le Dépôt sur GitHub (2 minutes)

### 2.1 Aller sur GitHub New Repository

1. Ouvrir <https://github.com/new>
2. Se connecter si nécessaire

### 2.2 Configurer le Dépôt

**Repository name** : `Arkea`

**Description** : `POC Migration HBase → HCD - Projet ARKEA`

**Visibility** :

- ✅ **Private** (recommandé pour un projet client)
- ⚠️ **Public** (si vous voulez le rendre public)

**IMPORTANT** :

- ❌ **NE PAS** cocher "Add a README file"
- ❌ **NE PAS** cocher "Add .gitignore"
- ❌ **NE PAS** cocher "Choose a license"

(Le projet a déjà ces fichiers)

### 2.3 Créer le Dépôt

1. Cliquer sur **"Create repository"**
2. **Notez l'URL** : `https://github.com/davidleconte/Arkea.git`

---

## 🎯 ÉTAPE 3 : Configurer le Remote Git (1 minute)

### 3.1 Ouvrir le Terminal

```bash
cd ${ARKEA_HOME}
```

### 3.2 Ajouter le Remote

```bash
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

---

## 🎯 ÉTAPE 4 : Vérifier la Branche (30 secondes)

```bash
# Vérifier la branche actuelle
git branch --show-current

# Si ce n'est pas 'main', renommer
git branch -M main
```

---

## 🎯 ÉTAPE 5 : Pousser vers GitHub (2-5 minutes)

### 5.1 Première Poussée

```bash
# Pousser tous les commits vers GitHub
git push -u origin main
```

### 5.2 Authentification

GitHub va demander :

- **Username** : `davidleconte`
- **Password** : **COLLER VOTRE PERSONAL ACCESS TOKEN** (pas votre mot de passe GitHub)

⚠️ **Important** : Utiliser le token créé à l'Étape 1, pas votre mot de passe !

### 5.3 Attendre la Fin

Le push peut prendre quelques minutes (dépôt de ~1.1 GB de fichiers trackés).

**Progression** : Git affichera la progression du transfert.

---

## ✅ ÉTAPE 6 : Vérification (1 minute)

### 6.1 Vérifier sur GitHub

1. Aller sur <https://github.com/davidleconte/Arkea>
2. Vérifier que :
   - ✅ Les fichiers sont présents
   - ✅ Les commits sont visibles dans l'historique
   - ✅ Le README.md s'affiche correctement

### 6.2 Vérifier en Local

```bash
# Vérifier le statut
git status

# Vérifier les branches distantes
git branch -a

# Voir les commits
git log --oneline --graph --all -10
```

---

## 🔄 Commandes Futures

Une fois configuré, pour pousser les futurs commits :

```bash
# Simple push
git push

# Ou explicitement
git push origin main
```

Pour récupérer les changements :

```bash
# Récupérer
git pull origin main
```

---

## ⚠️ Problèmes Courants

### Erreur : "remote origin already exists"

```bash
# Vérifier le remote actuel
git remote -v

# Si l'URL est incorrecte, la modifier
git remote set-url origin https://github.com/davidleconte/Arkea.git
```

### Erreur : "Authentication failed"

**Solutions** :

1. Vérifier que vous utilisez le **Personal Access Token** (pas le mot de passe)
2. Vérifier que le token a les permissions `repo`
3. Le token peut avoir expiré → créer un nouveau token

### Erreur : "Repository not found"

**Solutions** :

1. Vérifier que le dépôt existe sur GitHub
2. Vérifier que vous avez les droits d'accès
3. Vérifier l'URL : `https://github.com/davidleconte/Arkea.git`

### Push très lent

**Normal** : Le dépôt fait ~1.1 GB de fichiers trackés, le push peut
prendre 5-15 minutes selon la connexion.

**Solution** : Attendre, le push continuera même si lent.

---

## 📊 Résumé des Commandes

```bash
# 1. Aller dans le répertoire
cd ${ARKEA_HOME}

# 2. Ajouter le remote
git remote add origin https://github.com/davidleconte/Arkea.git

# 3. Vérifier
git remote -v

# 4. S'assurer que la branche est 'main'
git branch -M main

# 5. Pousser
git push -u origin main
# → Username : davidleconte
# → Password : [VOTRE PERSONAL ACCESS TOKEN]
```

---

## ✅ Checklist Finale

Avant de pousser, vérifier :

- [ ] Personal Access Token créé et copié
- [ ] Dépôt GitHub créé (<https://github.com/davidleconte/Arkea>)
- [ ] Remote `origin` configuré
- [ ] Branche `main` vérifiée
- [ ] Token prêt pour l'authentification

---

**Date** : 2025-12-02  
**Version** : 1.0.0  
**Statut** : ✅ Guide étape par étape complet
