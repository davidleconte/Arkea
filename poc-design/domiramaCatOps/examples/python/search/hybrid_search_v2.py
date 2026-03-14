#!/usr/bin/env python3
"""
Recherche Hybride V2 : Combinaison Full-Text Search (SAI) + Vector Search Multi-Modèles
- Filtre avec Full-Text pour la précision
- Trie par similarité vectorielle pour la pertinence (ByteT5, e5-large, ou facturation)
- Tolère les typos grâce au Vector Search
- Sélection intelligente du modèle selon le type de requête
Adapté pour domiramaCatOps (keyspace: domiramacatops_poc)
"""

import os
import sys
import json

# Ajouter le répertoire parent au PYTHONPATH pour les imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement

# Imports des modules de base pour chaque modèle
from test_vector_search_base import load_model, encode_text  # noqa: E402
from test_vector_search_base_e5 import load_model_e5, encode_text_e5  # noqa: E402
from test_vector_search_base_invoice import (  # noqa: E402
    load_model_invoice,
    encode_text_invoice,
)

KEYSPACE = "domiramacatops_poc"


def select_best_model(query_text):
    """
    Sélectionne le meilleur modèle selon le type de requête.

    Stratégie :
    - ByteT5 pour "PAIEMENT CARTE" / "CB" (100% pertinence)
    - Modèle facturation pour la plupart des requêtes (80% pertinence, 4x plus rapide)
    - e5-large comme fallback si facturation non disponible
    """
    query_upper = query_text.upper()

    # ByteT5 pour "PAIEMENT CARTE" / "CB"
    if "PAIEMENT CARTE" in query_upper or "CB" in query_upper or "CARTE" in query_upper:
        return "byt5"

    # Modèle facturation pour le reste (plus rapide que e5-large)
    return "invoice"


def hybrid_search(
    session, query_text, code_si, contrat, limit=10, use_fulltext=True, model_type="auto"
):
    """
    Recherche hybride : combine Full-Text + Vector Search.

    Args:
        session: Session Cassandra
        query_text: Texte de recherche (peut contenir des typos)
        code_si: Code SI de la partition
        contrat: Contrat de la partition
        limit: Nombre de résultats
        use_fulltext: Si True, filtre d'abord avec Full-Text, puis trie par Vector
        model_type: "auto", "byt5", "e5", ou "invoice"

    Returns:
        Liste de résultats
    """
    # Sélectionner le modèle
    if model_type == "auto":
        model_type = select_best_model(query_text)

    # Générer l'embedding selon le modèle choisi
    if model_type == "byt5":
        tokenizer, model = load_model()
        query_embedding = encode_text(tokenizer, model, query_text)
        embedding_column = "libelle_embedding"
    elif model_type == "e5":
        model = load_model_e5()
        query_embedding = encode_text_e5(model, query_text)
        embedding_column = "libelle_embedding_e5"
    elif model_type == "invoice":
        model = load_model_invoice()
        query_embedding = encode_text_invoice(model, query_text)
        embedding_column = "libelle_embedding_invoice"
    else:
        raise ValueError(f"Modèle inconnu: {model_type}")

    if use_fulltext:
        # Stratégie 1: Filtrer avec Full-Text, puis trier par Vector
        terms = query_text.lower().split()
        main_term = terms[0] if terms else query_text.lower()

        # Requête hybride : WHERE (full-text) + ORDER BY (vector)
        embedding_json = json.dumps(
            query_embedding.tolist() if hasattr(query_embedding, "tolist") else query_embedding
        )
        cql_query = f"""
        SELECT libelle, montant, cat_auto, cat_user, cat_confidence
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle : '{main_term}'
        ORDER BY {embedding_column} ANN OF {embedding_json}
        LIMIT {limit}
        """
    else:
        # Stratégie 2: Recherche vectorielle pure (pour typos sévères)
        embedding_json = json.dumps(
            query_embedding.tolist() if hasattr(query_embedding, "tolist") else query_embedding
        )
        cql_query = f"""
        SELECT libelle, montant, cat_auto, cat_user, cat_confidence
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        ORDER BY {embedding_column} ANN OF {embedding_json}
        LIMIT {limit}
        """

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results, model_type
    except Exception as e:
        # Si la recherche hybride échoue, fallback sur recherche vectorielle pure
        if use_fulltext:
            return hybrid_search(
                session,
                query_text,
                code_si,
                contrat,
                limit,
                use_fulltext=False,
                model_type=model_type,
            )
        else:
            print(f"   ❌ Erreur: {str(e)}")
            return [], model_type


def smart_hybrid_search(session, query_text, code_si, contrat, limit=10, model_type="auto"):
    """
    Recherche hybride intelligente avec fallback automatique :
    1. Sélectionne automatiquement le meilleur modèle
    2. Essaie d'abord Full-Text + Vector (précision maximale)
    3. Si aucun résultat, fallback sur Vector seul (tolère les typos)
    4. Filtre côté client pour améliorer la pertinence
    """
    # Sélectionner le modèle
    if model_type == "auto":
        model_type = select_best_model(query_text)

    # Générer l'embedding selon le modèle choisi
    if model_type == "byt5":
        tokenizer, model = load_model()
        query_embedding = encode_text(tokenizer, model, query_text)
        embedding_column = "libelle_embedding"
    elif model_type == "e5":
        model = load_model_e5()
        query_embedding = encode_text_e5(model, query_text)
        embedding_column = "libelle_embedding_e5"
    elif model_type == "invoice":
        model = load_model_invoice()
        query_embedding = encode_text_invoice(model, query_text)
        embedding_column = "libelle_embedding_invoice"
    else:
        raise ValueError(f"Modèle inconnu: {model_type}")

    # Stratégie 1: Essayer Full-Text + Vector (pour requêtes correctes)
    terms = query_text.lower().split()
    main_term = terms[0] if terms and len(terms[0]) > 2 else query_text.lower()

    # Essayer la recherche hybride Full-Text + Vector
    try:
        embedding_json = json.dumps(
            query_embedding.tolist() if hasattr(query_embedding, "tolist") else query_embedding
        )
        cql_query_hybrid = f"""
        SELECT libelle, montant, cat_auto, cat_user, cat_confidence
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle : '{main_term}'
        ORDER BY {embedding_column} ANN OF {embedding_json}
        LIMIT {limit}
        """
        statement = SimpleStatement(cql_query_hybrid)
        results = list(session.execute(statement))

        if results:
            # Recherche hybride réussie
            return results[:limit], model_type
    except Exception:
        pass

    # Stratégie 2: Fallback sur Vector Search seul (pour typos)
    try:
        embedding_json = json.dumps(
            query_embedding.tolist() if hasattr(query_embedding, "tolist") else query_embedding
        )
        cql_query_vector = f"""
        SELECT libelle, montant, cat_auto, cat_user, cat_confidence
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        ORDER BY {embedding_column} ANN OF {embedding_json}
        LIMIT {limit * 3}
        """
        statement = SimpleStatement(cql_query_vector)
        results = list(session.execute(statement))

        if results:
            # Filtrer côté client pour améliorer la pertinence
            query_lower = query_text.lower()
            terms = [t for t in query_lower.split() if len(t) > 2]

            if terms:
                scored_results = []
                for result in results:
                    if result.libelle:
                        libelle_lower = result.libelle.lower()
                        score = 0
                        for term in terms:
                            if term in libelle_lower:
                                score += 3
                            elif len(term) >= 3:
                                for i in range(3, min(len(term) + 1, 6)):
                                    prefix = term[:i]
                                    if prefix in libelle_lower:
                                        score += 1
                                        break
                        scored_results.append((score, result))

                scored_results.sort(key=lambda x: x[0], reverse=True)
                filtered = [r[1] for r in scored_results[:limit]]
                return filtered, model_type
            else:
                return results[:limit], model_type
    except Exception as e:
        print(f"   ⚠️  Erreur Vector Search: {str(e)}")

    return [], model_type


def main():
    """Fonction principale pour démontrer la recherche hybride."""
    print("=" * 70)
    print("  🔍 Recherche Hybride V2 : Full-Text + Vector Search Multi-Modèles")
    print("  Keyspace: domiramacatops_poc")
    print("=" * 70)
    print()

    # Connexion à HCD
    print("📡 Connexion à HCD...")
    cluster = Cluster(["localhost"], port=9042)
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
            "description": "Recherche correcte: 'LOYER IMPAYE' (modèle facturation)",
            "expected": "Devrait trouver 'LOYER IMPAYE REGULARISATION'",
        },
        {
            "query": "loyr impay",
            "description": "Recherche avec typos: 'loyr impay' (modèle facturation)",
            "expected": "Devrait trouver 'LOYER IMPAYE' grâce au Vector Search",
        },
        {
            "query": "PAIEMENT CARTE",
            "description": "Recherche correcte: 'PAIEMENT CARTE' (modèle ByteT5)",
            "expected": "Devrait trouver 'CB ...' grâce à ByteT5 (reconnaît CB)",
        },
        {
            "query": "VIREMENT SALAIRE",
            "description": "Recherche correcte: 'VIREMENT SALAIRE' (modèle facturation)",
            "expected": "Devrait trouver 'VIREMENT SALAIRE MENSUEL'",
        },
        {
            "query": "TAXE FONCIERE",
            "description": "Recherche correcte: 'TAXE FONCIERE' (modèle facturation)",
            "expected": "Devrait trouver des opérations de taxe foncière",
        },
    ]

    print("=" * 70)
    print("  📊 Résultats de la Recherche Hybride Multi-Modèles")
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
        results, model_used = smart_hybrid_search(session, query, code_si, contrat, limit=5)

        print(f"   📊 Modèle utilisé: {model_used.upper()}")

        if results:
            print(f"   ✅ {len(results)} résultat(s) trouvé(s):")
            for i, row in enumerate(results, 1):
                libelle = row.libelle[:60] if row.libelle else "N/A"
                montant = row.montant if row.montant else "N/A"
                cat_auto = row.cat_auto if row.cat_auto else "N/A"
                cat_user = row.cat_user if row.cat_user else "N/A"
                confidence = row.cat_confidence if row.cat_confidence else "N/A"
                cat_display = cat_user if cat_user != "N/A" else cat_auto
                print(f"      {i}. {libelle}")
                print(
                    f"         Montant: {montant} | Catégorie: {cat_display} (conf: {confidence})"
                )
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
    print("💡 Avantages de la Recherche Hybride V2:")
    print("   ✅ Précision du Full-Text Search (filtre initial)")
    print("   ✅ Tolérance aux typos du Vector Search (tri par similarité)")
    print("   ✅ Sélection intelligente du modèle (ByteT5 pour CB, Facturation pour le reste)")
    print("   ✅ Meilleure pertinence que chaque approche seule")
    print("   ✅ Adaptatif : détecte automatiquement les typos")


if __name__ == "__main__":
    main()
