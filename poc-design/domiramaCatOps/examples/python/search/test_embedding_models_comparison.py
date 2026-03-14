#!/usr/bin/env python3
"""
Script de comparaison des modèles d'embeddings pour le domaine bancaire.
Compare les performances de différents modèles sur des requêtes bancaires typiques.
"""

import time
from typing import Any, Dict

# Requêtes de test bancaires
TEST_QUERIES = [
    "LOYER IMPAYE",
    "VIREMENT SALAIRE",
    "PAIEMENT CARTE BANCAIRE",
    "CARREFOUR PARIS",
    "RESTAURANT PARIS",
    "SUPERMARCHE",
    "ASSURANCE HABITATION",
    "TAXE FONCIERE",
]

# Libellés de référence (pertinents pour chaque requête)
REFERENCE_LIBELLES = {
    "LOYER IMPAYE": ["REGULARISATION LOYER IMPAYE", "LOYER IMPAYE PARIS", "LOYER MENSUEL"],
    "VIREMENT SALAIRE": ["VIREMENT SALAIRE MARS 2024", "VIREMENT SALAIRE FEVRIER 2024"],
    "PAIEMENT CARTE BANCAIRE": ["CB RESTAURANT", "CB SUPERMARCHE", "CB CARREFOUR"],
    "CARREFOUR PARIS": ["CB CARREFOUR MARKET PARIS", "CB CARREFOUR CITY PARIS"],
    "RESTAURANT PARIS": ["CB RESTAURANT PARIS", "CB RESTAURANT BRASSERIE PARIS"],
    "SUPERMARCHE": ["CB SUPERMARCHE", "CB MONOPRIX", "CB INTERMARCHE"],
    "ASSURANCE HABITATION": ["ASSURANCE HABITATION", "PRIME ASSURANCE HABITATION"],
    "TAXE FONCIERE": ["TAXE FONCIERE ANNEE 2024", "TAXE FONCIERE"],
}


def test_model(model_name: str, model_type: str = "sentence_transformer") -> Dict[str, Any]:
    """Teste un modèle d'embedding."""
    print(f"\n{'='*70}")
    print(f"  🧪 Test du modèle : {model_name}")
    print(f"{'='*70}\n")

    results = {
        "model_name": model_name,
        "model_type": model_type,
        "dimension": None,
        "latency": [],
        "relevance_scores": [],
        "errors": [],
    }

    try:
        if model_type == "sentence_transformer":
            from sentence_transformers import SentenceTransformer

            print("📥 Chargement du modèle...")
            start = time.time()
            model = SentenceTransformer(model_name)
            load_time = time.time() - start
            print(f"✅ Modèle chargé en {load_time:.2f}s")

            # Obtenir la dimension
            test_embedding = model.encode("test", normalize_embeddings=True)
            results["dimension"] = len(test_embedding)
            print(f"📊 Dimension : {results['dimension']}")

        elif model_type == "byt5":
            import torch
            from transformers import AutoModel, AutoTokenizer

            print("📥 Chargement du modèle...")
            start = time.time()
            tokenizer = AutoTokenizer.from_pretrained(model_name)
            model = AutoModel.from_pretrained(model_name)
            model.eval()
            load_time = time.time() - start
            print(f"✅ Modèle chargé en {load_time:.2f}s")

            # Obtenir la dimension
            inputs = tokenizer("test", return_tensors="pt", truncation=True, padding=True)
            with torch.no_grad():
                outputs = model.encoder(**inputs)
                embeddings = outputs.last_hidden_state.mean(dim=1)
            results["dimension"] = embeddings.shape[1]
            print(f"📊 Dimension : {results['dimension']}")
        else:
            raise ValueError(f"Type de modèle inconnu : {model_type}")

        # Tester chaque requête
        print(f"\n📊 Test de {len(TEST_QUERIES)} requêtes...\n")

        for query in TEST_QUERIES:
            print(f"🔍 Requête : '{query}'")

            # Générer l'embedding
            start = time.time()
            if model_type == "sentence_transformer":
                embedding = model.encode(query, normalize_embeddings=True)
            else:  # byt5
                inputs = tokenizer(query, return_tensors="pt", truncation=True, padding=True)
                with torch.no_grad():
                    outputs = model.encoder(**inputs)
                    embeddings = outputs.last_hidden_state.mean(dim=1)
                _ = embeddings[0].tolist()  # Compute embedding for timing

            latency = (time.time() - start) * 1000  # en ms
            results["latency"].append(latency)
            print(f"   ⏱️  Latence : {latency:.2f} ms")

            # Vérifier la pertinence (simulation - nécessite données réelles)
            if query in REFERENCE_LIBELLES:
                print("   ✅ Requête testée")
                # Dans un vrai test, on comparerait avec les résultats de recherche
                results["relevance_scores"].append(0.5)  # Placeholder

        results["avg_latency"] = sum(results["latency"]) / len(results["latency"])
        results["min_latency"] = min(results["latency"])
        results["max_latency"] = max(results["latency"])

        print(f"\n📊 Résultats globaux :")
        print(f"   Latence moyenne : {results['avg_latency']:.2f} ms")
        print(f"   Latence min : {results['min_latency']:.2f} ms")
        print(f"   Latence max : {results['max_latency']:.2f} ms")

    except Exception as e:
        print(f"❌ Erreur : {str(e)}")
        results["errors"].append(str(e))

    return results


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔬 Comparaison des Modèles d'Embeddings pour le Domaine Bancaire")
    print("=" * 70)

    # Modèles à tester
    models_to_test = [
        {
            "name": "intfloat/multilingual-e5-large",
            "type": "sentence_transformer",
            "description": "🥇 RECOMMANDÉ - Multilingue, excellent pour français",
        },
        {
            "name": "paraphrase-multilingual-mpnet-base-v2",
            "type": "sentence_transformer",
            "description": "🥈 Alternative - Paraphrase multilingue",
        },
        {
            "name": "sujet-ai/Fin-ModernBERT-RAG-embed-base",
            "type": "sentence_transformer",
            "description": "🥉 Spécialisé finance - À évaluer",
        },
        {
            "name": "google/byt5-small",
            "type": "byt5",
            "description": "📊 ACTUEL - Référence pour comparaison",
        },
    ]

    all_results = []

    for model_info in models_to_test:
        print(f"\n{model_info['description']}")
        result = test_model(model_info["name"], model_info["type"])
        result["description"] = model_info["description"]
        all_results.append(result)

    # Résumé comparatif
    print("\n" + "=" * 70)
    print("  📊 RÉSUMÉ COMPARATIF")
    print("=" * 70)
    print()
    print(f"{'Modèle':<50} {'Dimension':<12} {'Latence (ms)':<15} {'Statut'}")
    print("-" * 90)

    for result in all_results:
        status = "✅ OK" if not result["errors"] else "❌ ERREUR"
        latency_str = f"{result.get('avg_latency', 0):.1f}" if result.get("avg_latency") else "N/A"
        dim_str = str(result.get("dimension", "N/A")) if result.get("dimension") else "N/A"

        model_short = result["model_name"].split("/")[-1][:45]
        print(f"{model_short:<50} {dim_str:<12} {latency_str:<15} {status}")

    print("\n💡 Recommandation : Voir doc/16_RECOMMANDATION_MODELES_EMBEDDINGS.md")
    print("   Pour un test complet avec données réelles, utiliser les scripts de test existants")


if __name__ == "__main__":
    main()
