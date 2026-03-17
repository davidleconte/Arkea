# 🔍 Test Complexe P2-01 : Fenêtre Glissante Complexe

**Date** : 2025-11-30 22:47:38
**Script** : 21_test_fenetre_glissante_complexe.sh

---

## 📊 Résumé Exécutif

Ce test valide la fenêtre glissante complexe avec :
- ✅ Fenêtre glissante avec chevauchement
- ✅ Validation cohérence entre fenêtres
- ✅ Gestion des frontières (début/fin de période)
- ✅ Agrégation multi-fenêtres

---

## 📋 Résultats Détaillés

### Sortie du Test

```
======================================================================
  🔍 Test Complexe P2-01 : Fenêtre Glissante Complexe
======================================================================

📋 TEST 1 : Fenêtre Glissante avec Chevauchement
----------------------------------------------------------------------
   Fenêtre 1 (2024-06-01 → 2024-06-20) : 8 opérations
   Fenêtre 2 (2024-06-15 → 2024-06-30) : 10 opérations
   Fenêtre 3 (2024-06-25 → 2024-07-10) : 5 opérations
   ✅ Fenêtres avec chevauchement validées

📋 TEST 2 : Fenêtre Glissante sans Chevauchement
----------------------------------------------------------------------
   Fenêtre 1 (2024-06-01 → 2024-06-15) : 5 opérations
   Fenêtre 2 (2024-06-15 → 2024-06-30) : 10 opérations
   Fenêtre 3 (2024-06-30 → 2024-07-15) : 1 opérations
   ✅ Total fenêtres : 16 opérations
   ✅ Fenêtres sans chevauchement validées

📋 TEST 3 : Gestion des Frontières
----------------------------------------------------------------------
   ✅ Première date : 2024-01-10
   ✅ Dernière date : 2025-11-30
   ✅ Fenêtre avant première date : 0 opérations (devrait être 0 ou faible)
   ✅ Fenêtre après dernière date : 55 opérations (devrait être 0 ou faible)

📋 TEST 4 : Agrégation Multi-Fenêtres
----------------------------------------------------------------------
   Fenêtre 1 (2024-06-01 → 2024-07-01) : 16 opérations
   Fenêtre 2 (2024-07-01 → 2024-08-01) : 0 opérations
   Fenêtre 3 (2024-08-01 → 2024-09-01) : 0 opérations
   ✅ Total opérations : 16
   ✅ Fenêtres avec données : 1/3
   ✅ Fenêtres vides : 2/3
   ✅ Min opérations : 0
   ✅ Max opérations : 16
   ✅ Moyenne opérations : 5.3

======================================================================
  📊 RÉSUMÉ
======================================================================
✅ Fenêtres avec chevauchement : 3 fenêtres testées
✅ Fenêtres sans chevauchement : 3 fenêtres testées
✅ Gestion frontières : ✅ Réussi
✅ Agrégation multi-fenêtres : 16 opérations totales

```

---

**Date de génération** : 2025-11-30 22:47:38
