# 🎯 Recommandation : Modèles d'Embeddings pour le Domaine Bancaire

**Date** : 2025-01-XX  
**Contexte** : Optimisation des embeddings pour améliorer la pertinence des résultats de recherche vectorielle  
**Modèle actuel** : `google/byt5-small` (1472 dimensions)

---

## 📊 Analyse des Besoins

### Contraintes Techniques

| Contrainte | Valeur Actuelle | Exigence |
|------------|----------------|----------|
| **Dimension vectorielle** | 1472 | Compatible avec HCD (flexible) |
| **Langue principale** | Français | ✅ Obligatoire |
| **Support multilingue** | Optionnel | ✅ Souhaitable |
| **Domaine** | Généraliste | ⚠️ À optimiser pour bancaire |
| **Performance** | Acceptable | ✅ À améliorer |
| **Taille du modèle** | Small (~60M) | ⚠️ Peut être plus grand |

### Problèmes Identifiés avec ByteT5-small

1. **Pertinence faible** : Résultats non pertinents (ex: "LOYER IMPAYE" → "CB PARKING")
2. **Domaine généraliste** : Non optimisé pour le vocabulaire bancaire
3. **Similarité sémantique** : Interprète "LOYER" comme "location" au lieu de "loyer bancaire"

---

## 🏆 Recommandations de Modèles

### 🥇 RECOMMANDATION PRINCIPALE : `intfloat/multilingual-e5-large`

**Modèle** : `intfloat/multilingual-e5-large`  
**Type** : Sentence Transformer  
**Dimensions** : 1024  
**Langues** : 100+ langues (dont français)  
**Taille** : ~560M paramètres

#### ✅ Avantages

1. **Excellent support du français** :
   - Entraîné sur des données multilingues incluant le français
   - Performances supérieures à ByteT5 pour le français
   - Comprend mieux le contexte français

2. **Optimisé pour la similarité sémantique** :
   - Entraîné spécifiquement pour la recherche sémantique
   - Meilleure compréhension des synonymes et variations
   - Résultats plus pertinents que ByteT5

3. **Multilingue robuste** :
   - Supporte 100+ langues
   - Idéal pour les tests multilingues
   - Bonne performance cross-lingue

4. **Performance** :
   - Top performer sur les benchmarks de similarité sémantique
   - Meilleure précision que ByteT5-small
   - Latence acceptable (~50-100ms)

5. **Compatibilité HCD** :
   - 1024 dimensions (compatible avec HCD)
   - Peut nécessiter un ajustement du schéma si dimension fixe à 1472

#### ⚠️ Inconvénients

1. **Dimension différente** : 1024 vs 1472 actuel
   - Nécessite modification du schéma HCD
   - Migration des embeddings existants

2. **Taille du modèle** : Plus grand que ByteT5-small
   - ~560M paramètres vs ~60M
   - Plus de mémoire requise
   - Latence légèrement supérieure

#### 📝 Utilisation

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('intfloat/multilingual-e5-large')
embeddings = model.encode("LOYER IMPAYE", normalize_embeddings=True)
# Dimension : 1024
```

---

### 🥈 ALTERNATIVE 1 : `sentence-transformers/paraphrase-multilingual-mpnet-base-v2`

**Modèle** : `paraphrase-multilingual-mpnet-base-v2`  
**Type** : Sentence Transformer  
**Dimensions** : 768  
**Langues** : 50+ langues (dont français)  
**Taille** : ~420M paramètres

#### ✅ Avantages

1. **Spécialisé paraphrase** :
   - Excellent pour la similarité sémantique
   - Comprend bien les synonymes
   - Bon pour la recherche floue

2. **Support français** :
   - Bonne performance en français
   - Entraîné sur données multilingues

3. **Taille raisonnable** :
   - Plus petit que e5-large
   - Latence acceptable
   - Moins de mémoire

4. **Compatibilité** :
   - 768 dimensions (compatible HCD)
   - Modèle stable et éprouvé

#### ⚠️ Inconvénients

1. **Dimension** : 768 (différent de 1472 actuel)
2. **Domaine généraliste** : Non spécialisé bancaire
3. **Performance** : Légèrement inférieure à e5-large

#### 📝 Utilisation

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('paraphrase-multilingual-mpnet-base-v2')
embeddings = model.encode("LOYER IMPAYE", normalize_embeddings=True)
# Dimension : 768
```

---

### 🥉 ALTERNATIVE 2 : `sujet-ai/Fin-ModernBERT-RAG-embed-base`

**Modèle** : `sujet-ai/Fin-ModernBERT-RAG-embed-base`  
**Type** : Fine-tuned sur données financières  
**Dimensions** : 768  
**Langue** : Principalement anglais (peut fonctionner en français)  
**Taille** : ~110M paramètres

#### ✅ Avantages

1. **Spécialisé finance** :
   - Fine-tuné sur données financières
   - Comprend le vocabulaire bancaire
   - Meilleure pertinence pour domaines financiers

2. **Taille compacte** :
   - Plus petit que les autres
   - Latence faible
   - Moins de mémoire

3. **Optimisé RAG** :
   - Conçu pour la recherche et récupération
   - Idéal pour la recherche vectorielle

#### ⚠️ Inconvénients

1. **Langue** : Principalement anglais
   - Performance en français non garantie
   - Nécessite évaluation

2. **Dimension** : 768 (différent de 1472)
3. **Disponibilité** : Modèle récent, moins éprouvé

#### 📝 Utilisation

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('sujet-ai/Fin-ModernBERT-RAG-embed-base')
embeddings = model.encode("LOYER IMPAYE", normalize_embeddings=True)
# Dimension : 768
```

---

### 🔍 ALTERNATIVE 3 : `Noureddinesa/Invoices_bilingual-embedding-large`

**Modèle** : `Invoices_bilingual-embedding-large`  
**Type** : Bilingue français-anglais  
**Dimensions** : Variable (à vérifier)  
**Langues** : Français, Anglais  
**Domaine** : Factures/Documents financiers

#### ✅ Avantages

1. **Spécialisé documents financiers** :
   - Entraîné sur factures et documents financiers
   - Comprend le vocabulaire bancaire
   - Bilingue français-anglais

2. **Domaine proche** :
   - Documents financiers similaires aux opérations bancaires
   - Peut être adapté aux libellés bancaires

#### ⚠️ Inconvénients

1. **Spécialisation** : Très spécialisé factures
   - Peut ne pas bien généraliser aux libellés bancaires
   - Nécessite évaluation

2. **Documentation limitée** :
   - Moins de documentation
   - Performance non garantie

---

## 📊 Comparaison des Modèles

| Modèle | Dimensions | Français | Multilingue | Domaine | Performance | Taille | Recommandation |
|--------|------------|----------|-------------|---------|-------------|--------|----------------|
| **multilingual-e5-large** | 1024 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Généraliste | ⭐⭐⭐⭐⭐ | Grande | 🥇 **MEILLEUR** |
| **paraphrase-multilingual-mpnet** | 768 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Généraliste | ⭐⭐⭐⭐ | Moyenne | 🥈 **BON** |
| **Fin-ModernBERT-RAG** | 768 | ⭐⭐⭐ | ⭐⭐ | Finance | ⭐⭐⭐⭐ | Petite | 🥉 **SPÉCIALISÉ** |
| **Invoices_bilingual** | ? | ⭐⭐⭐⭐ | ⭐⭐ | Finance | ⭐⭐⭐ | ? | ⚠️ **À ÉVALUER** |
| **ByteT5-small (actuel)** | 1472 | ⭐⭐⭐ | ⭐⭐⭐⭐ | Généraliste | ⭐⭐⭐ | Petite | ❌ **À REMPLACER** |

---

## 🎯 Recommandation Finale

### Option 1 : Migration vers `multilingual-e5-large` (RECOMMANDÉ)

**Pourquoi** :
- ✅ Meilleure performance en français
- ✅ Excellent pour la similarité sémantique
- ✅ Multilingue robuste
- ✅ Top performer sur benchmarks

**Actions requises** :
1. Modifier le schéma HCD : `VECTOR<FLOAT, 1024>` au lieu de `1472`
2. Régénérer tous les embeddings avec le nouveau modèle
3. Mettre à jour le code Python pour utiliser SentenceTransformer
4. Tester la pertinence des résultats

**Code de migration** :
```python
from sentence_transformers import SentenceTransformer
import torch

# Nouveau modèle
model = SentenceTransformer('intfloat/multilingual-e5-large')

# Encoder un texte
embedding = model.encode("LOYER IMPAYE", normalize_embeddings=True)
# Dimension : 1024
```

---

### Option 2 : Fine-tuning de `multilingual-e5-large` sur données bancaires (OPTIMAL)

**Pourquoi** :
- ✅ Combine les avantages de e5-large
- ✅ Optimisé spécifiquement pour le vocabulaire bancaire
- ✅ Meilleure pertinence attendue

**Actions requises** :
1. Collecter un corpus de libellés bancaires (10K-100K exemples)
2. Fine-tuner le modèle sur ce corpus
3. Évaluer les performances
4. Déployer le modèle fine-tuné

**Avantages** :
- Meilleure compréhension du vocabulaire bancaire
- Distinction entre "LOYER" (bancaire) et "location" (général)
- Résultats plus pertinents

---

### Option 3 : Hybrid Search (RECOMMANDÉ EN COMPLÉMENT)

**Pourquoi** :
- ✅ Combine recherche vectorielle + full-text
- ✅ Meilleure précision
- ✅ Tolérance aux typos (vector) + pertinence (full-text)

**Implémentation** :
- Utiliser `multilingual-e5-large` pour la partie vectorielle
- Utiliser l'index SAI full-text existant
- Combiner les résultats avec scoring

---

## 📋 Plan d'Implémentation

### Phase 1 : Évaluation (1-2 jours)

1. **Tester les modèles recommandés** :
   ```bash
   # Créer un script de test
   python3 test_embedding_models.py
   ```

2. **Comparer les performances** :
   - Mesurer la pertinence des résultats
   - Comparer avec ByteT5-small
   - Évaluer la latence

3. **Choisir le modèle** :
   - Basé sur les résultats de test
   - Considérer les contraintes (dimension, performance)

### Phase 2 : Migration (2-3 jours)

1. **Modifier le schéma HCD** :
   ```cql
   ALTER TABLE operations_by_account 
   ALTER libelle_embedding TYPE VECTOR<FLOAT, 1024>;
   ```

2. **Régénérer les embeddings** :
   ```python
   # Script de migration
   python3 migrate_embeddings.py
   ```

3. **Mettre à jour le code** :
   - Modifier `test_vector_search_base.py`
   - Utiliser SentenceTransformer
   - Tester tous les scripts

### Phase 3 : Fine-tuning (Optionnel, 1 semaine)

1. **Collecter les données** :
   - Libellés bancaires réels
   - Paires de libellés similaires
   - 10K-100K exemples

2. **Fine-tuner le modèle** :
   ```python
   from sentence_transformers import SentenceTransformer, InputExample, losses
   from torch.utils.data import DataLoader
   
   model = SentenceTransformer('intfloat/multilingual-e5-large')
   # Fine-tuning sur données bancaires
   ```

3. **Évaluer et déployer** :
   - Tester la pertinence
   - Comparer avec le modèle de base
   - Déployer si amélioration significative

---

## 🔧 Code d'Exemple : Migration vers multilingual-e5-large

```python
#!/usr/bin/env python3
"""
Migration des embeddings vers multilingual-e5-large
"""

from sentence_transformers import SentenceTransformer
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
import json

# Configuration
KEYSPACE = "domiramacatops_poc"
MODEL_NAME = "intfloat/multilingual-e5-large"
NEW_DIMENSION = 1024

# Charger le nouveau modèle
print(f"📥 Chargement du modèle {MODEL_NAME}...")
model = SentenceTransformer(MODEL_NAME)
print(f"✅ Modèle chargé (dimension: {NEW_DIMENSION})")

# Connexion HCD
cluster = Cluster(['localhost'])
session = cluster.connect(KEYSPACE)

# Récupérer tous les libellés
query = f"""
SELECT code_si, contrat, date_op, numero_op, libelle
FROM {KEYSPACE}.operations_by_account
WHERE libelle IS NOT NULL
LIMIT 1000
"""

print("📊 Récupération des libellés...")
rows = list(session.execute(query))
print(f"✅ {len(rows)} libellés récupérés")

# Régénérer les embeddings
print("🔄 Régénération des embeddings...")
for i, row in enumerate(rows):
    if row.libelle:
        # Générer le nouvel embedding
        embedding = model.encode(row.libelle, normalize_embeddings=True)
        
        # Mettre à jour dans HCD
        update_query = f"""
        UPDATE {KEYSPACE}.operations_by_account
        SET libelle_embedding = {json.dumps(embedding)}
        WHERE code_si = '{row.code_si}'
          AND contrat = '{row.contrat}'
          AND date_op = {row.date_op}
          AND numero_op = {row.numero_op}
        """
        session.execute(update_query)
        
        if (i + 1) % 100 == 0:
            print(f"   {i + 1}/{len(rows)} embeddings régénérés...")

print("✅ Migration terminée !")
session.shutdown()
cluster.shutdown()
```

---

## 📊 Métriques d'Évaluation

### Critères d'Évaluation

1. **Pertinence** :
   - Score de pertinence pour requêtes bancaires
   - Comparaison avec ByteT5-small
   - Taux de résultats pertinents

2. **Performance** :
   - Latence de génération d'embedding
   - Latence de recherche
   - Throughput

3. **Cohérence** :
   - Stabilité des résultats
   - Répétabilité

4. **Multilingue** :
   - Performance en français
   - Performance en anglais
   - Performance cross-lingue

---

## ✅ Conclusion

**Recommandation principale** : **`intfloat/multilingual-e5-large`**

**Raisons** :
1. ✅ Meilleure performance en français
2. ✅ Excellent pour la similarité sémantique
3. ✅ Multilingue robuste
4. ✅ Top performer sur benchmarks
5. ✅ Compatible avec HCD (1024 dimensions)

**Prochaines étapes** :
1. Tester le modèle sur un échantillon de données
2. Comparer les performances avec ByteT5-small
3. Décider de la migration complète
4. Optionnel : Fine-tuner sur données bancaires

---

**Date de génération** : 2025-11-30  
**Version** : 1.0

