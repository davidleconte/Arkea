#!/usr/bin/env python3
"""
Script pour vérifier la disponibilité et les caractéristiques des modèles spécialisés facturation.
"""


# Essayer sentence-transformers d'abord
try:
    from sentence_transformers import SentenceTransformer

    SENTENCE_TRANSFORMERS_AVAILABLE = True
except ImportError:
    SENTENCE_TRANSFORMERS_AVAILABLE = False
    print("⚠️  sentence-transformers non installé")

# Essayer transformers aussi
try:
    from transformers import AutoModel, AutoTokenizer
    import torch

    TRANSFORMERS_AVAILABLE = True
except ImportError:
    TRANSFORMERS_AVAILABLE = False
    print("⚠️  transformers non installé")

# Modèles à tester
MODELS_TO_TEST = [
    "NoureddineSa/Invoices_bilingual-embedding-large",
    "Noureddinesa/Invoices_bilingual-embedding-large",  # Variante
    "Noureddinesa/Invoices_french-document-embedding",
]


def test_with_sentence_transformers(model_name):
    """Test avec sentence-transformers."""
    try:
        print(f"\n📥 Test avec sentence-transformers: {model_name}")
        # Certains modèles nécessitent trust_remote_code=True
        try:
            model = SentenceTransformer(model_name, trust_remote_code=True)
        except TypeError:
            # Si trust_remote_code n'est pas supporté, essayer sans
            model = SentenceTransformer(model_name)

        dim = model.get_sentence_embedding_dimension()
        print("   ✅ Modèle disponible")
        print(f"   📊 Dimensions: {dim}")

        # Test d'encodage
        test_text = "LOYER IMPAYE LOCATION"
        embedding = model.encode(test_text, normalize_embeddings=True)
        print(f"   ✅ Encodage réussi: shape {embedding.shape}")

        return {
            "available": True,
            "dimensions": dim,
            "library": "sentence-transformers",
            "model": model,
        }
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return {"available": False, "error": str(e)}


def test_with_transformers(model_name):
    """Test avec transformers."""
    try:
        print(f"\n📥 Test avec transformers: {model_name}")
        tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
        model = AutoModel.from_pretrained(model_name, trust_remote_code=True)

        # Obtenir les dimensions
        test_text = "LOYER IMPAYE"
        inputs = tokenizer(test_text, return_tensors="pt", padding=True, truncation=True)
        with torch.no_grad():
            outputs = model(**inputs)

        # Dimensions depuis last_hidden_state
        dim = outputs.last_hidden_state.shape[-1]
        print("   ✅ Modèle disponible")
        print(f"   📊 Dimensions: {dim}")

        return {
            "available": True,
            "dimensions": dim,
            "library": "transformers",
            "tokenizer": tokenizer,
            "model": model,
        }
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return {"available": False, "error": str(e)}


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔍 Vérification des Modèles Spécialisés Facturation")
    print("=" * 70)
    print()

    available_models = []

    for model_name in MODELS_TO_TEST:
        print(f"\n{'='*70}")
        print(f"  Test: {model_name}")
        print(f"{'='*70}")

        # Essayer sentence-transformers d'abord
        if SENTENCE_TRANSFORMERS_AVAILABLE:
            result = test_with_sentence_transformers(model_name)
            if result.get("available"):
                available_models.append({"name": model_name, **result})
                continue

        # Essayer transformers si sentence-transformers n'a pas fonctionné
        if TRANSFORMERS_AVAILABLE:
            result = test_with_transformers(model_name)
            if result.get("available"):
                available_models.append({"name": model_name, **result})

    # Résumé
    print("\n" + "=" * 70)
    print("  📊 Résumé")
    print("=" * 70)

    if available_models:
        print(f"\n✅ {len(available_models)} modèle(s) disponible(s):\n")
        for i, model_info in enumerate(available_models, 1):
            print(f"{i}. {model_info['name']}")
            print(f"   - Dimensions: {model_info['dimensions']}")
            print(f"   - Bibliothèque: {model_info['library']}")

        # Recommandation
        print("\n🎯 Recommandation:")
        best_model = available_models[0]
        print(f"   Modèle recommandé: {best_model['name']}")
        print(f"   Dimensions: {best_model['dimensions']}")
        print(f"   Bibliothèque: {best_model['library']}")
    else:
        print("\n❌ Aucun modèle spécialisé facturation disponible")
        print("   Recommandation: Utiliser e5-base comme alternative")

    print()


if __name__ == "__main__":
    main()
