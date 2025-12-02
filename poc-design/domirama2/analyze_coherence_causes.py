#!/usr/bin/env python3
"""
Script d'analyse approfondie des causes des incohérences dans les résultats de recherche vectorielle.
Identifie pourquoi certains tests ne retournent pas de résultats pertinents malgré la présence des données.
"""

import json
import os
import sys
from decimal import Decimal

import numpy as np
import torch
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from transformers import AutoModel, AutoTokenizer

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
HF_API_KEY = os.getenv("HF_API_KEY", "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")
CODE_SI = "1"
CONTRAT = "5913101072"


def load_model():
    """Charge le modèle ByteT5."""
    print("📥 Chargement du modèle ByteT5...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, token=HF_API_KEY)
    model = AutoModel.from_pretrained(MODEL_NAME, token=HF_API_KEY)
    model.eval()
    print("✅ Modèle chargé")
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


def cosine_similarity(vec1, vec2):
    """Calcule la similarité cosinus entre deux vecteurs."""
    vec1 = np.array(vec1)
    vec2 = np.array(vec2)
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return dot_product / (norm1 * norm2)


def main():
    """Fonction principale d'analyse."""
    print("=" * 70)
    print("  🔍 ANALYSE APPROFONDIE DES CAUSES D'INCOHÉRENCES")
    print("=" * 70)
    print()

    # Charger le modèle
    tokenizer, model = load_model()
    print()

    # Connexion à HCD
    print("📡 Connexion à HCD...")
    cluster = Cluster(["localhost"], port=9042)
    session = cluster.connect("domirama2_poc")
    print("✅ Connecté à HCD")
    print()

    # Tests à analyser
    test_cases = [
        {
            "query": "loyr",
            "expected_keywords": ["LOYER"],
            "description": "Typo: caractère manquant ('loyr' au lieu de 'loyer')",
        },
        {
            "query": "impay",
            "expected_keywords": ["IMPAYE"],
            "description": "Typo: accent manquant ('impay' au lieu de 'impayé')",
        },
        {
            "query": "viremnt",
            "expected_keywords": ["VIREMENT"],
            "description": "Typo: caractère manquant ('viremnt' au lieu de 'virement')",
        },
    ]

    # Récupérer tous les libellés de la partition avec leurs embeddings
    print("📊 Récupération des données de la partition...")
    all_libelles_query = f"""
    SELECT libelle, libelle_embedding, cat_auto, type_operation
    FROM operations_by_account
    WHERE code_si = '{CODE_SI}'
      AND contrat = '{CONTRAT}';
    """
    all_libelles = list(session.execute(all_libelles_query))
    print(f"✅ {len(all_libelles)} libellés récupérés")
    print()

    # Analyser chaque test
    for test_case in test_cases:
        query_text = test_case["query"]
        expected_keywords = test_case["expected_keywords"]
        description = test_case["description"]

        print("=" * 70)
        print(f"  🔍 ANALYSE : Test '{query_text}'")
        print("=" * 70)
        print()
        print(f"📝 Description : {description}")
        print(f"📋 Mots-clés attendus : {', '.join(expected_keywords)}")
        print()

        # 1. Générer l'embedding de la requête
        print("🔄 Génération de l'embedding de la requête...")
        query_embedding = encode_text(tokenizer, model, query_text)
        print(f"✅ Embedding généré : {len(query_embedding)} dimensions")
        print()

        # 2. Identifier les libellés pertinents
        print("📊 Identification des libellés pertinents...")
        relevant_libelles = []
        for libelle_row in all_libelles:
            if libelle_row.libelle:
                libelle_upper = libelle_row.libelle.upper()
                for keyword in expected_keywords:
                    if keyword in libelle_upper and libelle_row.libelle_embedding is not None:
                        relevant_libelles.append(
                            {
                                "libelle": libelle_row.libelle,
                                "embedding": libelle_row.libelle_embedding,
                                "cat_auto": libelle_row.cat_auto,
                                "type_operation": libelle_row.type_operation,
                            }
                        )
                        break

        print(f"✅ {len(relevant_libelles)} libellé(s) pertinent(s) trouvé(s)")
        if not relevant_libelles:
            print("⚠️  Aucun libellé pertinent trouvé - Problème de données !")
            print()
            continue

        print()

        # 3. Calculer la similarité cosinus pour chaque libellé pertinent
        print("📊 Calcul de la similarité cosinus...")
        similarities = []
        for libelle_data in relevant_libelles:
            libelle_embedding = libelle_data["embedding"]
            similarity = cosine_similarity(query_embedding, libelle_embedding)
            similarities.append(
                {
                    "libelle": libelle_data["libelle"],
                    "similarity": similarity,
                    "cat_auto": libelle_data["cat_auto"],
                    "type_operation": libelle_data["type_operation"],
                }
            )

        # Trier par similarité décroissante
        similarities.sort(key=lambda x: x["similarity"], reverse=True)

        print(f"✅ Similarités calculées pour {len(similarities)} libellé(s)")
        print()

        # 4. Afficher les résultats
        print("📊 Top 10 des libellés pertinents par similarité :")
        print()
        print("| Rang | Libellé | Similarité | Catégorie | Type Opération |")
        print("|------|---------|------------|-----------|----------------|")
        for i, sim_data in enumerate(similarities[:10], 1):
            libelle = sim_data["libelle"]
            if len(libelle) > 50:
                libelle = libelle[:47] + "..."
            similarity = sim_data["similarity"]
            cat = sim_data["cat_auto"] or "N/A"
            type_op = sim_data["type_operation"] or "N/A"
            print(f"| {i} | {libelle} | {similarity:.4f} | {cat} | {type_op} |")
        print()

        # 5. Comparer avec les résultats de la recherche ANN
        print("🔍 Comparaison avec les résultats de la recherche ANN...")
        print()

        # Exécuter la recherche ANN
        cql_query = f"""
        SELECT libelle, montant, cat_auto, libelle_embedding
        FROM operations_by_account
        WHERE code_si = '{CODE_SI}'
          AND contrat = '{CONTRAT}'
        ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
        LIMIT 20
        """

        ann_results = list(session.execute(SimpleStatement(cql_query, fetch_size=20)))

        print(f"📊 Résultats ANN (top 20) :")
        print()
        print("| Rang ANN | Libellé | Contient mot-clé ? |")
        print("|----------|---------|-------------------|")
        ann_rank_in_top5 = None
        ann_rank_in_top20 = None

        for i, row in enumerate(ann_results, 1):
            libelle = row.libelle or "N/A"
            libelle_short = libelle[:50] if len(libelle) > 50 else libelle
            contains_keyword = any(keyword in libelle.upper() for keyword in expected_keywords)
            marker = "✅" if contains_keyword else "❌"

            if contains_keyword:
                if ann_rank_in_top5 is None and i <= 5:
                    ann_rank_in_top5 = i
                if ann_rank_in_top20 is None:
                    ann_rank_in_top20 = i

            print(f"| {i} | {libelle_short} | {marker} |")
        print()

        # 6. Analyse des causes
        print("🔍 ANALYSE DES CAUSES :")
        print()

        if ann_rank_in_top5 is not None:
            print(f"✅ **Résultat pertinent dans le top 5** : Rang {ann_rank_in_top5}")
            print(
                "   → La recherche ANN fonctionne, mais le résultat n'était peut-être pas le premier"
            )
        elif ann_rank_in_top20 is not None:
            print(f"⚠️  **Résultat pertinent trouvé mais hors top 5** : Rang {ann_rank_in_top20}")
            print(
                "   → Cause : La similarité cosinus n'est pas assez élevée pour être dans le top 5"
            )
            print("   → Solution : Augmenter le LIMIT ou utiliser recherche hybride")
        else:
            print("❌ **Aucun résultat pertinent dans le top 20**")
            print("   → Cause : La similarité vectorielle est insuffisante")
            print("   → Les embeddings de la requête typée sont trop différents des libellés réels")

        print()

        # 7. Comparaison des similarités
        if similarities:
            top_similarity = similarities[0]["similarity"]
            print(f"📊 Similarité maximale avec libellé pertinent : {top_similarity:.4f}")

            # Comparer avec les similarités des résultats ANN
            if ann_results:
                ann_similarities = []
                for row in ann_results[:5]:
                    if row.libelle_embedding:
                        sim = cosine_similarity(query_embedding, row.libelle_embedding)
                        ann_similarities.append({"libelle": row.libelle, "similarity": sim})

                if ann_similarities:
                    top_ann_similarity = ann_similarities[0]["similarity"]
                    print(
                        f"📊 Similarité maximale dans résultats ANN (top 5) : {top_ann_similarity:.4f}"
                    )
                    print()

                    if top_similarity > top_ann_similarity:
                        print("⚠️  **Problème identifié** :")
                        print(
                            f"   - La similarité avec les libellés pertinents ({top_similarity:.4f}) est PLUS ÉLEVÉE"
                        )
                        print(
                            f"   - Que la similarité avec les résultats ANN ({top_ann_similarity:.4f})"
                        )
                        print(
                            "   → Cause : Les libellés pertinents ne sont pas indexés correctement ou"
                        )
                        print("     la recherche ANN ne les trouve pas dans le top 5")
                        print()
                        print("💡 **Solutions possibles :**")
                        print("   1. Augmenter le LIMIT de 5 à 10 ou 20")
                        print("   2. Vérifier que l'index SAI vectoriel est bien construit")
                        print("   3. Utiliser la recherche hybride (Full-Text + Vector)")
                    else:
                        print("✅ **Pas de problème de similarité** :")
                        print("   - Les résultats ANN ont une similarité correcte")
                        print("   - Mais ils ne contiennent pas les mots-clés attendus")
                        print("   → Cause : Les embeddings capturent une similarité sémantique")
                        print("     mais pas lexicale (les mots ne correspondent pas)")
                        print()
                        print("💡 **Solution :** Utiliser la recherche hybride (Full-Text + Vector)")

        print()
        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ ANALYSE TERMINÉE")
    print("=" * 70)


if __name__ == "__main__":
    main()
