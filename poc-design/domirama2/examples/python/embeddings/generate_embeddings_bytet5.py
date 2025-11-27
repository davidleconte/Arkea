#!/usr/bin/env python3
"""
Script pour générer des embeddings ByteT5 pour les libellés d'opérations.
Utilise le modèle "google/byt5-small" pour créer des vecteurs de dimension 1472.
"""

import sys
import os
import torch
from transformers import AutoTokenizer, AutoModel

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472

# Clé API Hugging Face (depuis variable d'environnement ou valeur par défaut)
HF_API_KEY = os.getenv("HF_API_KEY", "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")

def load_model():
    """Charge le modèle ByteT5 et le tokenizer avec authentification Hugging Face."""
    print(f"📥 Chargement du modèle {MODEL_NAME}...")
    print(f"   Utilisation de la clé API Hugging Face")
    
    # Utiliser la clé API pour le téléchargement
    tokenizer = AutoTokenizer.from_pretrained(
        MODEL_NAME,
        token=HF_API_KEY
    )
    model = AutoModel.from_pretrained(
        MODEL_NAME,
        token=HF_API_KEY
    )
    model.eval()  # Mode évaluation
    print(f"✅ Modèle chargé (dimension: {VECTOR_DIMENSION})")
    return tokenizer, model

def encode_text(tokenizer, model, text):
    """
    Encode un texte en vecteur d'embedding en utilisant ByteT5.
    
    Args:
        tokenizer: Tokenizer ByteT5
        model: Modèle ByteT5
        text: Texte à encoder
    
    Returns:
        Liste de floats représentant l'embedding (dimension 1472)
    """
    # Tokeniser le texte
    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding=True,
        max_length=512  # Limite raisonnable pour les libellés
    )
    
    # Générer l'embedding avec l'encodeur
    with torch.no_grad():
        encoder_outputs = model.encoder(**inputs)
        # Mean pooling sur la dimension des tokens pour obtenir un vecteur unique
        embeddings = encoder_outputs.last_hidden_state.mean(dim=1)
    
    # Convertir en liste Python
    return embeddings[0].tolist()

def main():
    """Fonction principale pour tester la génération d'embeddings."""
    if len(sys.argv) < 2:
        print("Usage: python generate_embeddings_bytet5.py <texte>")
        print("Exemple: python generate_embeddings_bytet5.py 'LOYER IMPAYE PARIS'")
        sys.exit(1)
    
    text = sys.argv[1]
    
    # Charger le modèle
    tokenizer, model = load_model()
    
    # Générer l'embedding
    print(f"\n📝 Encodage du texte: '{text}'")
    embedding = encode_text(tokenizer, model, text)
    
    # Vérifier la dimension
    assert len(embedding) == VECTOR_DIMENSION, f"Dimension attendue: {VECTOR_DIMENSION}, obtenue: {len(embedding)}"
    
    print(f"✅ Embedding généré (dimension: {len(embedding)})")
    print(f"📊 Premiers éléments: {embedding[:5]}...")
    print(f"📊 Derniers éléments: ...{embedding[-5:]}")
    
    return embedding

if __name__ == "__main__":
    main()

