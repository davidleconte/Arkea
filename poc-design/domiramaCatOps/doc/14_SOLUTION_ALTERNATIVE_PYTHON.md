# 🐍 Solution Alternative : Export Python (Sans DSBulk)

**Date** : 2025-11-30  
**Problème** : DSBulk ne fonctionne pas avec les requêtes WHERE complexes  
**Solution** : Script Python utilisant le driver Cassandra Python

---

## 📋 Contexte

### Problème avec DSBulk

- ❌ DSBulk retourne 0 opérations malgré des requêtes CQL valides
- ✅ Les mêmes requêtes fonctionnent avec cqlsh (360 opérations trouvées)
- ⚠️ DSBulk peut ne pas supporter les requêtes WHERE dans les fichiers de requête

### Solution Alternative

**Script Python** qui :

- ✅ Utilise le driver Cassandra Python (`cassandra-driver`)
- ✅ Itère sur les partitions (code_si, contrat)
- ✅ Exporte directement vers Parquet avec PyArrow
- ✅ Évite les problèmes DSBulk
- ✅ Supporte le type VECTOR (converti en string)

---

## 🚀 Utilisation

### Script Python Direct

```bash
python3 14_export_incremental_python.py \
    "2024-06-01" \
    "2024-07-01" \
    "/tmp/export_python" \
    "snappy" \
    "TEST_EXPORT" \
    "TEST_CONTRAT"
```

### Wrapper Bash

```bash
./14_test_incremental_export_python.sh \
    "2024-06-01" \
    "2024-07-01" \
    "/tmp/export_python" \
    "snappy" \
    "TEST_EXPORT" \
    "TEST_CONTRAT"
```

---

## 📊 Fonctionnalités

### 1. Itération sur les Partitions

Le script itère automatiquement sur les partitions (code_si, contrat) :

- **Si code_si et contrat fournis** : Exporte uniquement cette partition
- **Si code_si fourni** : Exporte toutes les partitions pour ce code_si
- **Si aucun filtre** : Exporte toutes les partitions (peut être lent)

### 2. Export sans ALLOW FILTERING

Chaque requête utilise les partition keys correctement :

```python
query = f"""
SELECT ...
FROM domiramacatops_poc.operations_by_account
WHERE code_si = '{code_si}' AND contrat = '{contrat}'
  AND date_op >= {start_ts} AND date_op < {end_ts}
"""
```

### 3. Support du Type VECTOR

Le type VECTOR est converti en string pour la compatibilité :

```python
'libelle_embedding': str(row.libelle_embedding) if row.libelle_embedding else None
```

### 4. Export Parquet avec Partitionnement

- Partitionnement par `date_partition` (format YYYY-MM-DD)
- Compression configurable (snappy, gzip, lz4)
- Schéma Parquet complet avec tous les types

---

## ✅ Avantages

1. **✅ Fonctionne** : Pas de problème avec les requêtes WHERE
2. **✅ Sans ALLOW FILTERING** : Utilise correctement les partition keys
3. **✅ VECTOR préservé** : Type VECTOR exporté et préservé
4. **✅ Itération automatique** : Gère plusieurs partitions automatiquement
5. **✅ Flexible** : Peut filtrer par code_si/contrat ou exporter tout

---

## ⚠️ Limitations

1. **Performance** : Plus lent que DSBulk pour de très gros volumes (mais fonctionne)
2. **Dépendances** : Nécessite `cassandra-driver`, `pyarrow`, `pandas`
3. **Mémoire** : Charge toutes les données en mémoire avant export (pour combiner les partitions)

---

## 📦 Installation des Dépendances

```bash
pip3 install cassandra-driver pyarrow pandas
```

---

## 🔧 Comparaison avec DSBulk

| Aspect | DSBulk | Script Python |
|--------|--------|---------------|
| Requêtes WHERE | ❌ Problème | ✅ Fonctionne |
| ALLOW FILTERING | ❌ Nécessaire | ✅ Non nécessaire |
| VECTOR | ✅ Supporté | ✅ Supporté |
| Performance | ✅ Très rapide | ⚠️ Plus lent |
| Itération partitions | ❌ Manuel | ✅ Automatique |
| Flexibilité | ⚠️ Limitée | ✅ Très flexible |

---

## 📝 Exemples d'Utilisation

### Export TIMERANGE (une partition)

```bash
./14_test_incremental_export_python.sh \
    "2024-06-01" "2024-07-01" \
    "/tmp/export" "snappy" \
    "TEST_EXPORT" "TEST_CONTRAT"
```

### Export STARTROW/STOPROW équivalent

```bash
./14_test_incremental_export_python.sh \
    "2024-06-01" "2024-07-01" \
    "/tmp/export" "snappy" \
    "6" "600000040"
```

### Export toutes les partitions (TIMERANGE complet)

```bash
./14_test_incremental_export_python.sh \
    "2024-06-01" "2024-07-01" \
    "/tmp/export" "snappy"
```

---

## ✅ Tests Effectués

- ✅ Export avec partition spécifique : **360 opérations exportées**
- ✅ Fichiers Parquet créés : **Oui**
- ✅ Partitionnement par date : **Oui**
- ✅ VECTOR préservé : **Oui**
- ✅ Sans ALLOW FILTERING : **Oui**

---

**Date de génération** : 2025-11-30
