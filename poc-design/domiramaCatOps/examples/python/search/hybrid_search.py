#!/usr/bin/env python3
"""
Recherche Hybride : Combinaison Full-Text Search (SAI) + Vector Search (ByteT5)
- Filtre avec Full-Text pour la précision
- Trie par similarité vectorielle pour la pertinence
- Tolère les typos grâce au Vector Search
Adapté pour domiramaCatOps (keyspace: domiramacatops_poc)
"""

import os
import sys
import torch
from transformers import AutoTokenizer, AutoModel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
import json

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
HF_API_KEY = os.getenv("HF_API_KEY", "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")
KEYSPACE = "domiramacatops_poc"

def load_model():
    """Charge le modèle ByteT5."""
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, token=HF_API_KEY)
    model = AutoModel.from_pretrained(MODEL_NAME, token=HF_API_KEY)
    model.eval()
    return tokenizer, model

def encode_text(tokenizer, model, text):
    """Encode un texte en vecteur d'embedding."""
    if not text or text.strip() == "":
        return [0.0] * VECTOR_DIMENSION
    
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)
    with torch.no_grad():
        encoder_outputs = model.encoder(**inputs)
        embeddings = encoder_outputs.last_hidden_state.mean(dim=1)
    return embeddings[0].tolist()

def hybrid_search(session, query_text, code_si, contrat, limit=10, use_fulltext=True):
    """
    Recherche hybride : combine Full-Text + Vector Search.
    
    Args:
        session: Session Cassandra
        query_text: Texte de recherche (peut contenir des typos)
        code_si: Code SI de la partition
        contrat: Contrat de la partition
        limit: Nombre de résultats
        use_fulltext: Si True, filtre d'abord avec Full-Text, puis trie par Vector
    
    Returns:
        Liste de résultats
    """
    # Générer l'embedding de la requête
    tokenizer, model = load_model()
    query_embedding = encode_text(tokenizer, model, query_text)
    
    if use_fulltext:
        # Stratégie 1: Filtrer avec Full-Text, puis trier par Vector
        # Extraire le terme principal pour le filtre Full-Text
        # (prendre le premier mot significatif)
        terms = query_text.lower().split()
        main_term = terms[0] if terms else query_text.lower()
        
        # Requête hybride : WHERE (full-text) + ORDER BY (vector)
        cql_query = f"""
        SELECT libelle, montant, cat_auto, cat_user, cat_confidence
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' 
          AND contrat = '{contrat}'
          AND libelle : '{main_term}'
        ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
        LIMIT {limit}
        """
    else:
        # Stratégie 2: Recherche vectorielle pure (pour typos sévères)
        cql_query = f"""
        SELECT libelle, montant, cat_auto, cat_user, cat_confidence
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
        LIMIT {limit}
        """
    
    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results
    except Exception as e:
        # Si la recherche hybride échoue (ex: terme non trouvé en full-text),
        # Fallback sur recherche vectorielle pure
        if use_fulltext:
            return hybrid_search(session, query_text, code_si, contrat, limit, use_fulltext=False)
        else:
            print(f"   ❌ Erreur: {str(e)}")
            return []

def smart_hybrid_search(session, query_text, code_si, contrat, limit=10):
    """
    Recherche hybride intelligente avec fallback automatique :
    1. Essaie d'abord Full-Text + Vector (précision maximale)
    2. Si aucun résultat, fallback sur Vector seul (tolère les typos)
    3. Filtre côté client pour améliorer la pertinence
    """
    tokenizer, model = load_model()
    query_embedding = encode_text(tokenizer, model, query_text)
    
    # Stratégie 1: Essayer Full-Text + Vector (pour requêtes correctes)
    terms = query_text.lower().split()
    main_term = terms[0] if terms and len(terms[0]) > 2 else query_text.lower()
    
    # Essayer la recherche hybride Full-Text + Vector
    try:
        cql_query_hybrid = f"""
        SELECT libelle, montant, cat_auto, cat_user, cat_confidence
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' 
          AND contrat = '{contrat}'
          AND libelle : '{main_term}'
        ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
        LIMIT {limit}
        """
        statement = SimpleStatement(cql_query_hybrid)
        results = list(session.execute(statement))
        
        if results:
            # Recherche hybride réussie
            return results[:limit]
    except:
        pass
    
    # Stratégie 2: Fallback sur Vector Search seul (pour typos)
    try:
        cql_query_vector = f"""
        SELECT libelle, montant, cat_auto, cat_user, cat_confidence
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
        LIMIT {limit * 3}
        """
        statement = SimpleStatement(cql_query_vector)
        results = list(session.execute(statement))
        
        if results:
            # Filtrer côté client pour améliorer la pertinence
            query_lower = query_text.lower()
            terms = [t for t in query_lower.split() if len(t) > 2]
            
            if terms:
                # Score les résultats par similarité sémantique
                # Pour les typos, on utilise la similarité vectorielle déjà calculée
                # et on filtre seulement pour garder les plus pertinents
                scored_results = []
                for result in results:
                    if result.libelle:
                        libelle_lower = result.libelle.lower()
                        score = 0
                        # Vérifier chaque terme avec tolérance
                        for term in terms:
                            # Correspondance exacte = score élevé
                            if term in libelle_lower:
                                score += 3
                            # Correspondance partielle (préfixe de 3+ caractères) = score moyen
                            elif len(term) >= 3:
                                # Vérifier si un préfixe du terme est dans le libellé
                                for i in range(3, min(len(term)+1, 6)):
                                    prefix = term[:i]
                                    if prefix in libelle_lower:
                                        score += 1
                                        break
                        
                        # Même avec score 0, on garde les résultats (car triés par similarité vectorielle)
                        scored_results.append((score, result))
                
                # Trier par score décroissant, puis garder les meilleurs
                scored_results.sort(key=lambda x: x[0], reverse=True)
                filtered = [r[1] for r in scored_results[:limit]]
                
                return filtered
            else:
                return results[:limit]
    except Exception as e:
        print(f"   ⚠️  Erreur Vector Search: {str(e)}")
    
    return []

def main():
    """Fonction principale pour démontrer la recherche hybride."""
    print("=" * 70)
    print("  🔍 Recherche Hybride : Full-Text + Vector Search")
    print("  Keyspace: domiramacatops_poc")
    print("=" * 70)
    print()
    
    # Connexion à HCD
    print("📡 Connexion à HCD...")
    cluster = Cluster(['localhost'], port=9042)
    session = cluster.connect(KEYSPACE)
    print("✅ Connecté à HCD")
    print()
    
    # Récupérer un code_si et contrat pour les tests
    sample_query = f"SELECT code_si, contrat FROM {KEYSPACE}.operations_by_account LIMIT 1"
    sample = session.execute(sample_query).one()
    if not sample:
        print("⚠️  Aucune opération trouvée")
        session.shutdown()
        cluster.shutdown()
        return
    
    code_si = sample.code_si
    contrat = sample.contrat
    print(f"📋 Tests sur: code_si={code_si}, contrat={contrat}")
    print()
    
    # Tests de recherche hybride
    test_cases = [
        {
            "query": "LOYER IMPAYE",
            "description": "Recherche correcte: 'LOYER IMPAYE'",
            "expected": "Devrait trouver 'LOYER IMPAYE REGULARISATION'"
        },
        {
            "query": "loyr impay",
            "description": "Recherche avec typos: 'loyr impay'",
            "expected": "Devrait trouver 'LOYER IMPAYE' grâce au Vector Search"
        },
        {
            "query": "VIREMENT IMPAYE",
            "description": "Recherche correcte: 'VIREMENT IMPAYE'",
            "expected": "Devrait trouver 'VIREMENT IMPAYE REGULARISATION'"
        },
        {
            "query": "viremnt impay",
            "description": "Recherche avec typos: 'viremnt impay'",
            "expected": "Devrait trouver 'VIREMENT IMPAYE' grâce au Vector Search"
        },
        {
            "query": "CARREFOUR",
            "description": "Recherche correcte: 'CARREFOUR'",
            "expected": "Devrait trouver des opérations Carrefour"
        },
        {
            "query": "carrefur",
            "description": "Recherche avec typo: 'carrefur'",
            "expected": "Devrait trouver 'CARREFOUR' grâce au Vector Search"
        },
    ]
    
    print("=" * 70)
    print("  📊 Résultats de la Recherche Hybride")
    print("=" * 70)
    print()
    
    for test_case in test_cases:
        query = test_case["query"]
        description = test_case["description"]
        expected = test_case["expected"]
        
        print(f"🔍 Requête: '{query}'")
        print(f"   {description}")
        print(f"   Attendu: {expected}")
        print()
        
        # Recherche hybride intelligente
        results = smart_hybrid_search(session, query, code_si, contrat, limit=5)
        
        if results:
            print(f"   ✅ {len(results)} résultat(s) trouvé(s):")
            for i, row in enumerate(results, 1):
                libelle = row.libelle[:60] if row.libelle else "N/A"
                montant = row.montant if row.montant else "N/A"
                cat_auto = row.cat_auto if row.cat_auto else "N/A"
                cat_user = row.cat_user if row.cat_user else "N/A"
                confidence = row.cat_confidence if row.cat_confidence else "N/A"
                # Afficher cat_user si présent, sinon cat_auto
                cat_display = cat_user if cat_user != "N/A" else cat_auto
                print(f"      {i}. {libelle}")
                print(f"         Montant: {montant} | Catégorie: {cat_display} (conf: {confidence})")
        else:
            print("   ⚠️  Aucun résultat trouvé")
        
        print()
        print("-" * 70)
        print()
    
    session.shutdown()
    cluster.shutdown()
    
    print("=" * 70)
    print("  ✅ Tests terminés !")
    print("=" * 70)
    print()
    print("💡 Avantages de la Recherche Hybride:")
    print("   ✅ Précision du Full-Text Search (filtre initial)")
    print("   ✅ Tolérance aux typos du Vector Search (tri par similarité)")
    print("   ✅ Meilleure pertinence que chaque approche seule")
    print("   ✅ Adaptatif : détecte automatiquement les typos")

if __name__ == "__main__":
    main()


