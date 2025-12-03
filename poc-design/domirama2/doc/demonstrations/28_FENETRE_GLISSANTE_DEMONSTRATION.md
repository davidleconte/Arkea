# 📅 Démonstration : Export Fenêtre Glissante

**Date** : 2025-11-27 04:57:32
**Script** : 28_demo_fenetre_glissante_v2_didactique.sh
**Objectif** : Démontrer la fenêtre glissante pour exports incrémentaux

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Fenêtres Exportées](#fenêtres-exportées)
3. [Résultats par Fenêtre](#résultats-par-fenêtre)
4. [Statistiques Globales](#statistiques-globales)
5. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD (Spark) |
|---------------|------------------------|
| TIMERANGE | WHERE date_op >= start AND date_op < end |
| Fenêtre glissante | Boucle sur plusieurs périodes |
| Export mensuel | Export par fenêtre (mois) |
| Idempotence | Mode overwrite pour rejeux |

### Paramètres

- **Année de début** : 2024
- **Mois de début** : 11
- **Nombre de mois** : 2
- **Compression** : snappy
- **Répertoire base** : /tmp/exports/domirama/incremental

---

## 📅 Fenêtres Exportées

### Tableau Récapitulatif

| Fenêtre | Date Début | Date Fin | Opérations | Vérification | Statut |
|---------|------------|----------|------------|--------------|--------|
| 2024-11 | 2024-11-01 | 2024-12-01 | 10029 | 10029 | ✅ OK |
| 2024-12 | 2024-12-01 | 2025-01-01 | 10029 | 10029 | ✅ OK |

---

## 📊 Résultats par Fenêtre

### Fenêtre 2024-11

- **Période** : 2024-11-01 → 2024-12-01
- **Opérations exportées** : 10029
- **Opérations lues (vérification)** : 10029
- **Cohérence** : ✅ Cohérent
- **Répertoire** : /tmp/exports/domirama/incremental/2024-11
- **Statut** : ✅ Export réussi

### Fenêtre 2024-12

- **Période** : 2024-12-01 → 2025-01-01
- **Opérations exportées** : 10029
- **Opérations lues (vérification)** : 10029
- **Cohérence** : ✅ Cohérent
- **Répertoire** : /tmp/exports/domirama/incremental/2024-12
- **Statut** : ✅ Export réussi

---

## 📊 Statistiques Globales

- **Total fenêtres** : 2
- **Fenêtres avec données** : 2
- **Total opérations** : 20058

---

## ✅ Conclusion

- ✅ Fenêtre glissante démontrée avec succès
- ✅ Export incrémental par période (équivalent TIMERANGE HBase)
- ✅ Idempotence garantie (mode overwrite)
- ✅ Partitionnement par date_op pour performance
- ✅ Format Parquet (cohérent avec ingestion)

---

**✅ Export fenêtre glissante terminé avec succès !**
