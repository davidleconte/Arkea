# 🔐 Guide : Accès Sécurisé au Dépôt GitHub

**Date** : 2025-12-02  
**Dépôt** : <https://github.com/davidleconte/Arkea>  
**Objectif** : Donner accès au dépôt de manière sécurisée selon les besoins

---

## 📋 Options Disponibles

### 1. **Collaborateurs (Recommandé pour collaboration)**

**Cas d'usage** : Donner accès à des personnes spécifiques pour collaborer sur le projet.

**Avantages** :

- ✅ Contrôle granulaire des permissions (Read, Write, Admin)
- ✅ Accès direct au dépôt
- ✅ Historique des actions tracé
- ✅ Facile à gérer

**Étapes** :

1. **Aller sur GitHub** :

   ```
   https://github.com/davidleconte/Arkea/settings/access
   ```

2. **Cliquer sur "Invite a collaborator"**

3. **Entrer le nom d'utilisateur GitHub ou l'email**

4. **Choisir le niveau d'accès** :
   - **Read** : Lecture seule (recommandé pour consultants, auditeurs)
   - **Write** : Lecture + écriture (recommandé pour développeurs)
   - **Admin** : Accès complet (recommandé uniquement pour responsables)

5. **Envoyer l'invitation**

**Permissions recommandées** :

- **Consultants/Auditeurs** : Read
- **Développeurs** : Write
- **Responsables projet** : Admin

---

### 2. **GitHub Organizations (Pour équipes)**

**Cas d'usage** : Gérer plusieurs personnes, équipes, ou projets.

**Avantages** :

- ✅ Gestion centralisée des accès
- ✅ Création d'équipes avec permissions spécifiques
- ✅ Facturation centralisée (si applicable)
- ✅ Meilleur pour les projets d'entreprise

**Étapes** :

1. **Créer une Organization** :

   ```
   https://github.com/organizations/new
   ```

2. **Transférer ou créer le dépôt dans l'Organization**

3. **Créer des équipes** avec permissions spécifiques

4. **Inviter des membres** aux équipes

**Recommandation** : Utiliser pour ARKEA si plusieurs équipes doivent collaborer.

---

### 3. **Personal Access Tokens (PAT) - Pour CI/CD et scripts**

**Cas d'usage** : Accès automatisé (CI/CD, scripts, outils).

**Avantages** :

- ✅ Contrôle précis des permissions
- ✅ Peut être révoqué facilement
- ✅ Pas besoin de compte utilisateur complet
- ✅ Idéal pour l'automatisation

**Étapes** :

1. **Créer un PAT** :

   ```
   https://github.com/settings/tokens
   ```

2. **Cliquer sur "Generate new token" → "Generate new token (classic)"**

3. **Configurer le token** :
   - **Note** : Description claire (ex: "ARKEA CI/CD - Production")
   - **Expiration** : 90 jours (recommandé) ou personnalisée
   - **Scopes** : Sélectionner uniquement les permissions nécessaires
     - ✅ `repo` (Full control of private repositories) - pour push/pull
     - ✅ `read:org` - si dans une organization
     - ❌ Ne pas cocher plus que nécessaire

4. **Générer et copier le token** (il ne sera plus affiché)

5. **Utiliser le token** :

   ```bash
   # Pour HTTPS
   git clone https://TOKEN@github.com/davidleconte/Arkea.git

   # Ou configurer dans Git
   git remote set-url origin https://TOKEN@github.com/davidleconte/Arkea.git
   ```

**⚠️ Sécurité** :

- Ne jamais commiter le token dans le code
- Utiliser des variables d'environnement
- Stocker dans un gestionnaire de secrets (GitHub Secrets, etc.)

---

### 4. **Clés SSH (Pour accès développeur)**

**Cas d'usage** : Accès développeur avec authentification par clé.

**Avantages** :

- ✅ Pas besoin de mot de passe/token à chaque opération
- ✅ Plus sécurisé que HTTPS avec mot de passe
- ✅ Facile à révoquer

**Étapes** :

1. **Générer une clé SSH** (si pas déjà fait) :

   ```bash
   ssh-keygen -t ed25519 -C "votre_email@example.com"
   ```

2. **Copier la clé publique** :

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

3. **Ajouter sur GitHub** :

   ```
   https://github.com/settings/keys
   ```

   - Cliquer "New SSH key"
   - Coller la clé publique
   - Donner un titre (ex: "MacBook Pro - ARKEA")

4. **Tester la connexion** :

   ```bash
   ssh -T git@github.com
   ```

5. **Configurer le remote** (si nécessaire) :

   ```bash
   git remote set-url origin git@github.com:davidleconte/Arkea.git
   ```

---

### 5. **Deploy Keys (Pour serveurs/déploiements)**

**Cas d'usage** : Accès en lecture seule pour serveurs de déploiement.

**Avantages** :

- ✅ Lecture seule par défaut
- ✅ Spécifique à un dépôt
- ✅ Plus sécurisé que PAT pour déploiements

**Étapes** :

1. **Générer une clé SSH** sur le serveur :

   ```bash
   ssh-keygen -t ed25519 -C "deploy@server"
   ```

2. **Ajouter comme Deploy Key** :

   ```
   https://github.com/davidleconte/Arkea/settings/keys
   ```

   - Cliquer "Add deploy key"
   - Coller la clé publique
   - Cocher "Allow write access" si nécessaire (déconseillé)

3. **Utiliser sur le serveur** :

   ```bash
   git clone git@github.com:davidleconte/Arkea.git
   ```

---

### 6. **GitHub Apps (Pour intégrations avancées)**

**Cas d'usage** : Intégrations tierces, outils spécialisés.

**Avantages** :

- ✅ Permissions très granulaires
- ✅ Meilleur pour intégrations tierces
- ✅ Plus complexe à configurer

**Recommandation** : Utiliser uniquement si nécessaire pour des outils spécifiques.

---

## 🎯 Recommandations par Cas d'Usage

### Pour ARKEA - Scénarios Typiques

#### **Scénario 1 : Collaboration avec équipe ARKEA**

```
✅ Option : Collaborateurs (Write)
   - Inviter chaque membre de l'équipe
   - Permissions : Write
   - Accès direct au dépôt
```

#### **Scénario 2 : Audit externe (consultants)**

```
✅ Option : Collaborateurs (Read)
   - Inviter les consultants
   - Permissions : Read (lecture seule)
   - Accès temporaire, révoquer après audit
```

#### **Scénario 3 : CI/CD et automatisation**

```
✅ Option : Personal Access Token (PAT)
   - Créer un PAT avec scope "repo"
   - Stocker dans GitHub Secrets
   - Utiliser dans workflows GitHub Actions
```

#### **Scénario 4 : Déploiement serveur**

```
✅ Option : Deploy Keys
   - Générer clé SSH sur serveur
   - Ajouter comme Deploy Key (lecture seule)
   - Utiliser pour clone/pull automatique
```

#### **Scénario 5 : Développeurs externes**

```
✅ Option : Collaborateurs (Write) + Clés SSH
   - Inviter comme collaborateur
   - Configurer clés SSH pour authentification
   - Permissions : Write
```

---

## 🔒 Bonnes Pratiques de Sécurité

### 1. **Principe du Moindre Privilège**

- ✅ Donner uniquement les permissions nécessaires
- ❌ Ne pas donner Admin si Write suffit
- ❌ Ne pas donner Write si Read suffit

### 2. **Révision Régulière des Accès**

- ✅ Vérifier régulièrement la liste des collaborateurs
- ✅ Révoquer les accès non utilisés
- ✅ Vérifier les tokens actifs

### 3. **Gestion des Tokens**

- ✅ Utiliser des tokens avec expiration
- ✅ Nommer clairement les tokens
- ✅ Ne jamais commiter les tokens
- ✅ Utiliser GitHub Secrets pour CI/CD

### 4. **Audit et Traçabilité**

- ✅ Vérifier les logs d'accès GitHub
- ✅ Activer les notifications de sécurité
- ✅ Examiner les commits suspects

### 5. **Protection des Branches**

- ✅ Activer la protection de branche `main`
- ✅ Exiger des pull requests pour modifications
- ✅ Exiger des reviews avant merge

---

## 📝 Checklist de Sécurité

Avant de donner accès, vérifier :

- [ ] Le niveau d'accès est approprié (Read/Write/Admin)
- [ ] L'utilisateur a un compte GitHub valide
- [ ] Les tokens ont une expiration définie
- [ ] Les clés SSH sont nommées clairement
- [ ] La protection de branche est activée
- [ ] Les notifications de sécurité sont activées
- [ ] Un plan de révocation est en place

---

## 🚨 Révocation d'Accès

### Révoquer un Collaborateur

```
https://github.com/davidleconte/Arkea/settings/access
→ Cliquer sur le collaborateur
→ Cliquer "Remove collaborator"
```

### Révoquer un PAT

```
https://github.com/settings/tokens
→ Trouver le token
→ Cliquer "Revoke"
```

### Révoquer une Clé SSH

```
https://github.com/settings/keys
→ Trouver la clé
→ Cliquer "Delete"
```

### Révoquer une Deploy Key

```
https://github.com/davidleconte/Arkea/settings/keys
→ Trouver la clé
→ Cliquer "Delete"
```

---

## 📚 Ressources

- **Documentation GitHub** : <https://docs.github.com/en/authentication>
- **Gestion des accès** : <https://github.com/davidleconte/Arkea/settings/access>
- **Tokens** : <https://github.com/settings/tokens>
- **Clés SSH** : <https://github.com/settings/keys>
- **Sécurité** : <https://github.com/settings/security>

---

**Dernière mise à jour** : 2025-12-02
