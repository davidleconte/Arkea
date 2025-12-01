# Test de la Recherche Hybride V2

**Date** : 2025-11-30 22:09:54
**Script** : 18_test_hybrid_search.sh

---

## Tests Exécutés

Tests de recherche hybride combinant Full-Text Search (SAI) et Vector Search Multi-Modèles.

**Modèles disponibles :**
- ByteT5-small (libelle_embedding) : Pour 'PAIEMENT CARTE' / 'CB'
- multilingual-e5-large (libelle_embedding_e5) : Généraliste
- Modèle Facturation (libelle_embedding_invoice) : Spécialisé bancaire

**Sélection intelligente :** Le système choisit automatiquement le meilleur modèle selon le type de requête.

