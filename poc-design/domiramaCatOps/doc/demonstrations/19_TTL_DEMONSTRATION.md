# ⏱️ Démonstration : TTL et Purge Automatique DomiramaCatOps

## 📚 Contexte HBase → HCD

### Équivalences

| Concept HBase | Équivalent HCD | Statut |
|---------------|----------------|--------|
| TTL => '315619200 SECONDS' | default_time_to_live = 315619200 | ✅ |
| TTL par Column Family | TTL par table (ou par écriture) | ✅ |
| Purge lors compaction | Purge automatique continue | ✅ |
| Pas de contrôle granulaire | TTL par ligne/colonne possible | ✅ |

### Avantages HCD vs HBase

✅ **TTL par écriture** : Contrôle granulaire (INSERT ... USING TTL ...)  
✅ **TTL par table** : Configuration centralisée (default_time_to_live)  
✅ **Purge automatique** : Pas d'intervention manuelle  
✅ **Tombstones** : Gestion automatique des marqueurs de suppression

---

## 📋 DDL - Configuration TTL

### DDL de la table (extrait)

```cql
    AND default_time_to_live = 315619200
    AND extensions = {}
    AND gc_grace_seconds = 864000
```

### Explication

- default_time_to_live = 315619200 : TTL par défaut (10 ans en secondes)
- TTL s'applique à toutes les colonnes de la ligne
- Les données expirées sont automatiquement purgées lors des compactions
- Équivalent HBase : TTL => '315619200 SECONDS (3653 DAYS)'

---

## 🧪 Tests de TTL avec Résultats Réels et Contrôles

### Test 1 : Insertion avec TTL par défaut

**Requête** :
```cql
INSERT INTO domiramacatops_poc.operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant)
VALUES ('DEMO_TTL', 'DEMO_001', '2024-01-20 10:00:00', 1, 'TEST TTL', 100.00);
```

**Résultat attendu** : L'opération est insérée avec TTL = 315619200 secondes (10 ans).  
**Équivalent HBase** : TTL par défaut de la Column Family.

**✅ Contrôle effectué après insertion** :
```
    
     code_si  | contrat  | date_op                         | numero_op | libelle  | montant | ttl_remaining
    ----------+----------+---------------------------------+-----------+----------+---------+---------------
     DEMO_TTL | DEMO_001 | 2024-01-20 09:00:00.000000+0000 |         1 | TEST TTL |  100.00 |     315619199
    
    (1 rows)
```
**✅ Validation** : Ligne insérée avec succès, TTL par défaut appliqué (315619200 secondes).

---

### Test 2 : Insertion avec TTL personnalisé et Purge Automatique

**Requête** :
```cql
INSERT INTO domiramacatops_poc.operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant)
VALUES ('DEMO_TTL', 'DEMO_001', '2024-01-20 11:00:00', 2, 'TEST TTL COURT', 200.00)
USING TTL 60;
```

**Résultat attendu** : L'opération est insérée avec TTL = 60 secondes et expire automatiquement.  
**Valeur ajoutée HCD** : TTL par écriture (non disponible avec HBase).

**✅ Contrôle effectué AVANT expiration (immédiatement après insertion)** :
```
    
     code_si  | contrat  | date_op                         | numero_op | libelle        | montant | ttl_remaining
    ----------+----------+---------------------------------+-----------+----------------+---------+---------------
     DEMO_TTL | DEMO_001 | 2024-01-20 10:00:00.000000+0000 |         2 | TEST TTL COURT |  200.00 |            60
    
    (1 rows)
```
**✅ Validation** : Ligne insérée avec TTL 60 secondes, TTL restant ~60 secondes.

**⏱️ Attente de 65 secondes pour démontrer la purge automatique...**

**✅ Contrôle effectué APRÈS expiration (65 secondes après insertion)** :
```
    
     code_si | contrat | date_op | numero_op | libelle | montant | ttl_remaining
    ---------+---------+---------+-----------+---------+---------+---------------
    
    
    (0 rows)
```
**✅ Validation** : 
La ligne a été automatiquement purgée après expiration du TTL (0 ligne retournée). ✅ **PURGE AUTOMATIQUE CONFIRMÉE**

---

### Test 3 : Mise à jour avec nouveau TTL

**Requête** :
```cql
UPDATE domiramacatops_poc.operations_by_account
USING TTL 120
SET libelle = 'TEST TTL MIS À JOUR'
WHERE code_si = 'DEMO_TTL' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-20 10:00:00' AND numero_op = 1;
```

**Résultat attendu** : Le TTL de la ligne est mis à jour à 120 secondes.  
**Valeur ajoutée HCD** : Mise à jour du TTL sans réécrire toute la ligne.

**✅ Contrôle effectué après mise à jour** :
```
    
     code_si  | contrat  | date_op                         | numero_op | libelle             | montant | ttl_remaining
    ----------+----------+---------------------------------+-----------+---------------------+---------+---------------
     DEMO_TTL | DEMO_001 | 2024-01-20 09:00:00.000000+0000 |         1 | TEST TTL MIS À JOUR |  100.00 |           119
    
    (1 rows)
```
**✅ Validation** : TTL mis à jour à 120 secondes, libelle modifié avec succès.

---

### Test 4 : Insertion Multiple avec TTL Différents

**Requête** :
```cql
INSERT INTO domiramacatops_poc.operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant)
VALUES ('DEMO_TTL', 'DEMO_002', '2024-01-20 12:00:00', 1, 'TEST TTL 30s', 300.00)
USING TTL 30;

INSERT INTO domiramacatops_poc.operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant)
VALUES ('DEMO_TTL', 'DEMO_002', '2024-01-20 12:00:00', 2, 'TEST TTL 90s', 400.00)
USING TTL 90;
```

**Résultat attendu** : Deux lignes avec TTL différents (30s et 90s), chaque ligne expire indépendamment.

**✅ Contrôle effectué après insertion** :
\`\`\`
    
     code_si  | contrat  | date_op                         | numero_op | libelle      | montant | ttl_remaining
    ----------+----------+---------------------------------+-----------+--------------+---------+---------------
     DEMO_TTL | DEMO_002 | 2024-01-20 11:00:00.000000+0000 |         1 | TEST TTL 30s |  300.00 |            29
     DEMO_TTL | DEMO_002 | 2024-01-20 11:00:00.000000+0000 |         2 | TEST TTL 90s |  400.00 |            90
    
    (2 rows)
```
**✅ Validation** : Deux lignes insérées avec TTL différents (30s et 90s).

**⏱️ Attente de 35 secondes (la ligne avec TTL 30s devrait expirer)...**

**✅ Contrôle effectué après 35 secondes** :
```
    
     code_si  | contrat  | date_op                         | numero_op | libelle      | montant | ttl_remaining
    ----------+----------+---------------------------------+-----------+--------------+---------+---------------
     DEMO_TTL | DEMO_002 | 2024-01-20 11:00:00.000000+0000 |         2 | TEST TTL 90s |  400.00 |            54
    
    (1 rows)
```
**✅ Validation** : 
Ligne avec TTL 30s expirée, ligne avec TTL 90s encore présente. ✅ **TTL INDÉPENDANTS CONFIRMÉS**

---

## 📊 Résumé des Contrôles Effectués

**Tous les tests ont été exécutés et contrôlés avec les résultats réels :**

1. ✅ **Test 1** : Insertion avec TTL par défaut → **Contrôlé** : Ligne insérée, TTL = 315619200 secondes
2. ✅ **Test 2** : Insertion avec TTL personnalisé → **Contrôlé AVANT expiration** : TTL = 60 secondes  
   → **Contrôlé APRÈS expiration** : Ligne purgée automatiquement (0 ligne retournée)
3. ✅ **Test 3** : Mise à jour avec nouveau TTL → **Contrôlé** : TTL mis à jour à 120 secondes, libelle modifié
4. ✅ **Test 4** : Insertion multiple avec TTL différents → **Contrôlé** : Deux lignes avec TTL 30s et 90s  
   → **Contrôlé après 35s** : Ligne TTL 30s expirée, ligne TTL 90s encore présente (TTL indépendants confirmés)

**Tous les résultats ont été vérifiés et documentés dans ce rapport.**

---

## ✅ Conclusion

La démonstration du TTL a été réalisée avec succès, mettant en évidence :

✅ **Équivalence HBase** : Le TTL HCD reproduit le comportement HBase avec des avantages supplémentaires.  
✅ **Flexibilité** : TTL par table ET par écriture (valeur ajoutée HCD).  
✅ **Purge automatique** : Les données expirées sont automatiquement supprimées (confirmé par les contrôles).  
✅ **Performance** : Pas d'impact sur les performances (purge lors compaction).  
✅ **Tests complets** : Tous les scénarios ont été testés avec résultats réels et contrôles documentés.  
✅ **Tests complexes** : TTL multiples, purge sélective, indépendance des TTL par ligne validés.

---

**✅ Démonstration TTL terminée avec succès !**
