# 🔐 Guide de Sécurité Production - ARKEA

**Date** : 2025-12-02  
**Version** : 1.0.0  
**Objectif** : Guide complet pour sécuriser le déploiement ARKEA en production

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Configuration Sécurisée HCD](#configuration-sécurisée-hcd)
3. [Gestion des Credentials](#gestion-des-credentials)
4. [Rotation des Credentials](#rotation-des-credentials)
5. [Chiffrement des Données](#chiffrement-des-données)
6. [Audit des Accès](#audit-des-accès)
7. [Bonnes Pratiques](#bonnes-pratiques)

---

## 🎯 Vue d'Ensemble

### ⚠️ Important : POC vs Production

Ce guide s'applique à la **production**. Le POC utilise des credentials par défaut (`cassandra/cassandra`) qui **DOIVENT
être changés** avant la mise en production.

### Principes de Sécurité

1. ✅ **Authentification forte** : Mots de passe complexes, rotation régulière
2. ✅ **Autorisation minimale** : Principe du moindre privilège
3. ✅ **Chiffrement** : Données en transit et au repos
4. ✅ **Audit** : Traçabilité des accès et modifications
5. ✅ **Monitoring** : Détection d'anomalies

---

## 🔧 Configuration Sécurisée HCD

### 1. Créer un Superuser Personnalisé

**⚠️ CRITIQUE** : Ne pas utiliser l'utilisateur `cassandra` par défaut en production.

```bash
# Se connecter avec cqlsh
cqlsh ${HCD_HOST:-localhost} ${HCD_PORT:-9042}

# Créer un nouveau superuser
CREATE ROLE admin_prod WITH SUPERUSER = true AND LOGIN = true AND PASSWORD = 'MotDePasseComplexe123!@#';

# Vérifier la création
LIST ROLES;
```

### 2. Désactiver l'Utilisateur par Défaut

```bash
# Se connecter avec le nouveau superuser
cqlsh -u admin_prod -p 'MotDePasseComplexe123!@#' ${HCD_HOST:-localhost} ${HCD_PORT:-9042}

# Désactiver l'utilisateur cassandra par défaut
ALTER ROLE cassandra WITH SUPERUSER = false AND LOGIN = false;
```

### 3. Créer des Rôles Spécifiques

```bash
# Créer un rôle pour les applications
CREATE ROLE app_user WITH LOGIN = true AND PASSWORD = 'MotDePasseApp123!@#';

# Accorder des permissions spécifiques
GRANT SELECT, MODIFY ON KEYSPACE poc_hbase_migration TO app_user;
```

### 4. Configuration HCD Sécurisée

**Fichier** : `conf/cassandra.yaml`

```yaml
# Authentification
authenticator: PasswordAuthenticator
authorizer: CassandraAuthorizer

# Chiffrement en transit
server_encryption_options:
  internode_encryption: all
  keystore: /path/to/keystore.jks
  keystore_password: KeystorePassword123!@#
  truststore: /path/to/truststore.jks
  truststore_password: TruststorePassword123!@#

# Chiffrement au repos
transparent_data_encryption_options:
  enabled: true
  chunk_length_kb: 64
  cipher: AES/CBC/PKCS5Padding
  key_alias: cassandra
  key_provider:
    - class_name: org.apache.cassandra.security.JKSKeyProvider
      parameters:
        - keystore: /path/to/keystore.jks
          keystore_password: KeystorePassword123!@#
          store_type: JKS
          key_password: KeyPassword123!@#
```

---

## 🔑 Gestion des Credentials

### Variables d'Environnement

**⚠️ Ne JAMAIS hardcoder les credentials dans le code.**

```bash
# ✅ BON : Utiliser des variables d'environnement
export HCD_USERNAME="${HCD_USERNAME}"
export HCD_PASSWORD="${HCD_PASSWORD}"

# ❌ MAUVAIS : Credentials hardcodés
export HCD_PASSWORD="cassandra"  # NE JAMAIS FAIRE ÇA
```

### Fichiers de Secrets

**Option 1 : Fichier `.env` (développement uniquement)**

```bash
# .env (NE JAMAIS COMMITTER)
HCD_USERNAME=admin_prod
HCD_PASSWORD=MotDePasseComplexe123!@#
```

**Option 2 : Secrets Manager (production)**

- AWS Secrets Manager
- HashiCorp Vault
- Azure Key Vault
- Kubernetes Secrets

### Exemple avec Kubernetes Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: hcd-credentials
type: Opaque
stringData:
  username: admin_prod
  password: MotDePasseComplexe123!@#
```

---

## 🔄 Rotation des Credentials

### Processus de Rotation

#### 1. Préparation

```bash
# Créer un nouveau rôle avec nouveau mot de passe
CREATE ROLE admin_prod_new WITH SUPERUSER = true AND LOGIN = true AND PASSWORD = 'NouveauMotDePasse456!@#';
```

#### 2. Migration Progressive

```bash
# Mettre à jour les applications une par une
# Application 1
export HCD_USERNAME=admin_prod_new
export HCD_PASSWORD=NouveauMotDePasse456!@#

# Vérifier que l'application fonctionne
# Répéter pour chaque application
```

#### 3. Finalisation

```bash
# Une fois toutes les applications migrées
ALTER ROLE admin_prod WITH LOGIN = false;

# Supprimer l'ancien rôle (optionnel)
DROP ROLE admin_prod;
```

### Script de Rotation Automatique

**Fichier** : `scripts/utils/rotate_credentials.sh`

```bash
#!/bin/bash
set -euo pipefail

# Script de rotation des credentials HCD
# Usage: ./rotate_credentials.sh <old_password> <new_password>

OLD_PASSWORD="$1"
NEW_PASSWORD="$2"

# Créer nouveau rôle
cqlsh -u admin_prod -p "$OLD_PASSWORD" ${HCD_HOST:-localhost} ${HCD_PORT:-9042} <<EOF
CREATE ROLE admin_prod_new WITH SUPERUSER = true AND LOGIN = true AND PASSWORD = '$NEW_PASSWORD';
EOF

# Mettre à jour les applications (à adapter selon votre infrastructure)
# ...

# Désactiver ancien rôle
cqlsh -u admin_prod_new -p "$NEW_PASSWORD" ${HCD_HOST:-localhost} ${HCD_PORT:-9042} <<EOF
ALTER ROLE admin_prod WITH LOGIN = false;
EOF

echo "✅ Rotation des credentials terminée"
```

### Calendrier de Rotation

- **Mots de passe** : Tous les 90 jours
- **Clés de chiffrement** : Tous les 365 jours
- **Certificats TLS** : Avant expiration (généralement 1 an)

---

## 🔒 Chiffrement des Données

### Chiffrement en Transit

#### TLS/SSL pour HCD

```yaml
# conf/cassandra.yaml
server_encryption_options:
  internode_encryption: all
  keystore: /path/to/keystore.jks
  keystore_password: KeystorePassword123!@#
```

#### TLS pour Kafka

```properties
# server.properties
listeners=SSL://localhost:9093
ssl.keystore.location=/path/to/kafka.server.keystore.jks
ssl.keystore.password=KeystorePassword123!@#
ssl.key.password=KeyPassword123!@#
ssl.truststore.location=/path/to/kafka.server.truststore.jks
ssl.truststore.password=TruststorePassword123!@#
```

### Chiffrement au Repos

#### Transparent Data Encryption (TDE)

```yaml
# conf/cassandra.yaml
transparent_data_encryption_options:
  enabled: true
  chunk_length_kb: 64
  cipher: AES/CBC/PKCS5Padding
```

---

## 📊 Audit des Accès

### Activation de l'Audit

```yaml
# conf/cassandra.yaml
audit_logging_options:
  enabled: true
  logger: BinAuditLogger
  audit_logs_dir: /var/log/cassandra/audit
  included_keyspaces: poc_hbase_migration
  excluded_keyspaces: system, system_schema
```

### Exemples de Logs d'Audit

```
2025-12-02 10:00:00,123 | admin_prod | SELECT | poc_hbase_migration.interactions | SUCCESS
2025-12-02 10:01:00,456 | app_user | INSERT | poc_hbase_migration.interactions | SUCCESS
2025-12-02 10:02:00,789 | unknown_user | SELECT | poc_hbase_migration.interactions | UNAUTHORIZED
```

### Monitoring des Accès

- **Alertes** : Accès non autorisés, tentatives d'intrusion
- **Rapports** : Accès par utilisateur, par keyspace, par heure
- **Rétention** : Conserver les logs d'audit pendant 1 an minimum

---

## ✅ Bonnes Pratiques

### Checklist de Sécurité Production

- [ ] ✅ Utilisateur `cassandra` par défaut désactivé
- [ ] ✅ Superuser personnalisé créé avec mot de passe fort
- [ ] ✅ Rôles spécifiques créés avec permissions minimales
- [ ] ✅ Chiffrement en transit activé (TLS/SSL)
- [ ] ✅ Chiffrement au repos activé (TDE)
- [ ] ✅ Audit des accès activé
- [ ] ✅ Credentials stockés dans un secrets manager
- [ ] ✅ Rotation des credentials planifiée
- [ ] ✅ Monitoring et alertes configurés
- [ ] ✅ Backup sécurisé et chiffré

### Mots de Passe Forts

**Critères** :

- Minimum 16 caractères
- Majuscules, minuscules, chiffres, caractères spéciaux
- Pas de mots du dictionnaire
- Pas de patterns répétitifs

**Exemples** :

- ✅ `Kx9#mP2$vL8@nQ4!wR6`
- ❌ `password123`
- ❌ `Cassandra2025`

### Gestion des Secrets

**✅ À FAIRE** :

- Utiliser un secrets manager
- Rotation régulière
- Accès limité aux secrets
- Audit des accès aux secrets

**❌ À ÉVITER** :

- Credentials hardcodés dans le code
- Credentials dans les variables d'environnement non sécurisées
- Partage de credentials par email/chat
- Credentials dans les logs

---

## 📚 Références

- [HCD Security Documentation](https://docs.datastax.com/en/hyper-converged-database/1.2/security/)
- [Cassandra Security Best Practices](https://cassandra.apache.org/doc/latest/cassandra/operating/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

**Date** : 2025-12-02  
**Version** : 1.0.0  
**Statut** : ✅ **Guide complet**
