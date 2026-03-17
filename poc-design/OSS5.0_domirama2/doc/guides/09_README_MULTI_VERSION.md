# 🔄 Logique Multi-Version avec Time Travel

## Vue d'ensemble

Ce document explique la logique multi-version implémentée dans Domirama2 pour remplacer la temporalité des cellules HBase. La stratégie garantit que **les mises à jour client ne sont jamais perdues** et permet le **time travel** pour voir l'état des données à différentes dates.

---

## 🎯 Objectifs

1. ✅ **Aucune perte de mise à jour client** : Les corrections client sont toujours conservées
2. ✅ **Time travel** : Déterminer quelle catégorie était valide à une date donnée
3. ✅ **Priorité client > batch** : `cat_user` a toujours la priorité sur `cat_auto`

---

## 📋 Stratégie Multi-Version

### Colonnes Utilisées

| Colonne | Type | Écrit par | Description |
|---------|------|-----------|-------------|
| `cat_auto` | TEXT | **Batch uniquement** | Catégorie automatique (moteur IA) |
| `cat_confidence` | DECIMAL | **Batch uniquement** | Score de confiance du moteur (0.0 à 1.0) |
| `cat_user` | TEXT | **Client uniquement** | Catégorie modifiée par le client |
| `cat_date_user` | TIMESTAMP | **Client uniquement** | Date de modification par le client |
| `cat_validee` | BOOLEAN | **Client uniquement** | Acceptation par le client |

### Règles d'Écriture

#### Batch (MapReduce/Spark)

**Le batch écrit UNIQUEMENT** :

- ✅ `cat_auto` : Catégorie automatique
- ✅ `cat_confidence` : Score du moteur

**Le batch NE TOUCHE JAMAIS** :

- ❌ `cat_user` : Jamais modifié par le batch
- ❌ `cat_date_user` : Jamais modifié par le batch
- ❌ `cat_validee` : Jamais modifié par le batch

**Exemple Scala** :

```scala
Operation(
  cat_auto       = catAuto,        // ✅ Batch écrit ici
  cat_confidence = catConf,        // ✅ Batch écrit ici
  cat_user       = null,           // ❌ Batch NE TOUCHE JAMAIS
  cat_date_user  = null,           // ❌ Batch NE TOUCHE JAMAIS
  cat_validee    = false           // ❌ Batch NE TOUCHE JAMAIS
)
```

#### Client (API)

**Le client écrit dans** :

- ✅ `cat_user` : Nouvelle catégorie choisie
- ✅ `cat_date_user` : Date de correction (timestamp réel)
- ✅ `cat_validee` : Acceptation/rejet

**Le client NE TOUCHE JAMAIS** :

- ❌ `cat_auto` : Conservé pour référence
- ❌ `cat_confidence` : Conservé pour référence

**Exemple CQL** :

```cql
UPDATE operations_by_account
SET cat_user = 'RESTAURANT',
    cat_date_user = toTimestamp(now()),
    cat_validee = true
WHERE code_si = '01' AND contrat = '1234567890'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
```

### Logique de Priorité (Application)

**L'application priorise** :

```sql
IF cat_user IS NOT NULL AND cat_date_user IS NOT NULL:
    RETURN cat_user  -- Priorité au client
ELSE:
    RETURN cat_auto  -- Fallback sur batch
```

**Exemple CQL** :

```cql
SELECT
    cat_auto,
    cat_user,
    COALESCE(cat_user, cat_auto) as categorie_finale
FROM operations_by_account
WHERE code_si = '01' AND contrat = '1234567890';
```

---

## 🕐 Time Travel

### Principe

Le **time travel** permet de déterminer quelle catégorie était valide à une date donnée en utilisant `cat_date_user`.

### Logique Time Travel

```python
def get_category_at_date(query_date):
    if cat_user exists AND cat_date_user <= query_date:
        return cat_user  # Correction client était déjà en place
    else:
        return cat_auto  # Seule la catégorie batch était disponible
```

### Exemple de Scénario

1. **2024-01-15 10:00** : Batch insère `cat_auto = 'ALIMENTATION'`
2. **2024-01-16 14:30** : Client corrige → `cat_user = 'RESTAURANT'`, `cat_date_user = '2024-01-16 14:30'`
3. **2024-01-20 08:00** : Batch ré-écrit `cat_auto = 'SUPERMARCHE'` (cat_user conservé)

**Time Travel** :

- **2024-01-15 12:00** : `ALIMENTATION` (batch, correction pas encore faite)
- **2024-01-16 15:00** : `RESTAURANT` (client, correction faite)
- **2024-01-20 09:00** : `RESTAURANT` (client, toujours valide)

---

## ✅ Garanties

### 1. Aucune Perte de Mise à Jour Client

**Scénario critique** : Le batch ré-écrit `cat_auto` après une correction client.

**Résultat** :

- ✅ `cat_user` est **conservé** (non écrasé)
- ✅ `cat_date_user` est **conservé**
- ✅ `cat_validee` est **conservé**
- ✅ Seul `cat_auto` est mis à jour par le batch

**Démonstration** :

```python
# Après ré-écriture batch
cat_auto: 'SUPERMARCHE' (nouveau batch)
cat_user: 'RESTAURANT' (✅ CONSERVÉ - non écrasé)
cat_date_user: '2024-01-16 14:30' (✅ CONSERVÉ)
```

### 2. Priorité Client > Batch

**Logique** : Si `cat_user` existe, il a toujours la priorité sur `cat_auto`.

**Application** :

```sql
SELECT COALESCE(cat_user, cat_auto) as categorie_finale
FROM operations_by_account
WHERE ...
```

### 3. Traçabilité

**`cat_date_user`** permet de :

- ✅ Savoir quand la correction client a été faite
- ✅ Faire du time travel (quelle catégorie était valide à une date)
- ✅ Auditer les modifications client

---

## ⚠️ Limitations vs HBase

### HBase (Temporalité des Cellules)

- ✅ Garde **plusieurs versions** avec timestamps
- ✅ Time travel complet (voir toutes les versions)
- ✅ Historique complet de `cat_auto` et `cat_user`

### Cassandra (Stratégie Multi-Version)

- ⚠️ Garde **une seule version** (pas d'historique)
- ⚠️ Pas d'historique de `cat_auto` (seule la dernière valeur visible)
- ✅ Historique de `cat_user` via `cat_date_user` (mais seulement la dernière correction)

### Solution pour Historique Complet

**Table séparée** : `domirama-meta-categories` (comme proposé par IBM)

- Stocker l'historique des corrections client
- Stocker l'historique des catégories batch
- Permettre le time travel complet

---

## 🧪 Test de Validation

### Script de Test

**Fichier** : `test_multi_version_time_travel.py`

**Exécution** :

```bash
python3 test_multi_version_time_travel.py
# ou
./26_test_multi_version_time_travel.sh
```

### Scénarios Testés

1. ✅ Insertion initiale par batch (`cat_auto`)
2. ✅ Correction client (`cat_user`, `cat_date_user`)
3. ✅ Ré-écriture batch (vérification que `cat_user` n'est pas écrasé)
4. ✅ Time travel à différentes dates
5. ✅ Test de non-écrasement (batch ne touche jamais `cat_user`)
6. ✅ Logique de priorité (application)
7. ✅ Plusieurs corrections client (historique)

### Résultats Attendus

- ✅ Les mises à jour client ne sont jamais perdues
- ✅ Le batch ne touche jamais `cat_user` (stratégie respectée)
- ✅ Time travel fonctionne correctement
- ✅ Priorité client > batch respectée
- ✅ `cat_date_user` permet la traçabilité

---

## 📊 Comparaison HBase vs Domirama2

| Aspect | HBase (Temporalité) | Domirama2 (Multi-Version) |
|--------|---------------------|--------------------------|
| **Versions multiples** | ✅ Oui (timestamps) | ⚠️ Non (une seule version) |
| **Historique cat_auto** | ✅ Complet | ⚠️ Seule dernière valeur |
| **Historique cat_user** | ✅ Complet | ⚠️ Seule dernière correction |
| **Time travel** | ✅ Complet | ⚠️ Partiel (via cat_date_user) |
| **Complexité** | ⚠️ Implicite (timestamps) | ✅ Explicite (colonnes séparées) |
| **Perte données client** | ⚠️ Possible (écrasement) | ✅ Impossible (colonnes séparées) |
| **Traçabilité** | ⚠️ Via timestamps | ✅ Via cat_date_user |
| **Maintenabilité** | ⚠️ Complexe | ✅ Simple |

---

## 💡 Avantages de la Stratégie Multi-Version

1. ✅ **Logique explicite** : Batch vs Client clairement séparé
2. ✅ **Pas de perte de données** : `cat_user` jamais écrasé par batch
3. ✅ **Traçabilité** : `cat_date_user` pour audit
4. ✅ **Simplicité** : Plus simple à comprendre que temporalité HBase
5. ✅ **Time travel partiel** : Via `cat_date_user` pour corrections client

---

## 🔧 Recommandations Production

### Validation Applicative

**Le batch doit valider** qu'il ne touche jamais `cat_user` :

```scala
// Validation dans le code batch
require(operation.cat_user == null, "Batch ne doit jamais toucher cat_user")
```

### Historique Complet

**Pour l'historique complet**, utiliser une table séparée :

- `domirama-meta-categories` (comme proposé par IBM)
- Stocker chaque correction avec timestamp
- Permettre le time travel complet

### Monitoring

**Surveiller** :

- Nombre de corrections client par jour
- Taux de validation (`cat_validee = true`)
- Évolution de `cat_confidence` (qualité du moteur)

---

## 📝 Conclusion

La stratégie multi-version de Domirama2 :

- ✅ **Garantit** qu'aucune mise à jour client n'est perdue
- ✅ **Permet** le time travel partiel (via `cat_date_user`)
- ✅ **Simplifie** la logique vs temporalité HBase
- ⚠️ **Limite** : Pas d'historique complet (solution = table séparée)

**Cette stratégie est conforme à la proposition IBM** et offre un bon compromis entre simplicité et fonctionnalité.

---

**Script de test** : `test_multi_version_time_travel.py`
**Script shell** : `26_test_multi_version_time_travel.sh`
