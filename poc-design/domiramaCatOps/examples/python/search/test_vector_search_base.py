#!/usr/bin/env python3
"""
Module de base pour les tests de recherche vectorielle.
Contient les fonctions communes utilisées par tous les tests.
"""

import json
import math
import os
import random
from typing import Any, List, Optional, Tuple

import torch
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from transformers import AutoModel, AutoTokenizer

# Fixer la seed globale pour cohérence
torch.manual_seed(42)
random.seed(42)

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
HF_API_KEY = os.getenv("HF_API_KEY")
KEYSPACE = "domiramacatops_poc"

# Variables globales pour le cache du modèle
_tokenizer = None
_model = None


def load_model():
    """Charge le modèle ByteT5 (avec cache)."""
    global _tokenizer, _model
    if _tokenizer is None or _model is None:
        _tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, token=HF_API_KEY)
        _model = AutoModel.from_pretrained(MODEL_NAME, token=HF_API_KEY)
        _model.eval()
        # S'assurer que le modèle est sur CPU (évite les erreurs device meta vs cpu)
        _model = _model.to("cpu")
    return _tokenizer, _model


def encode_text(tokenizer, model, text: str) -> List[float]:
    """Encode un texte en vecteur d'embedding.

    Note: Le modèle est déterministe si torch.manual_seed() est fixé.
    """
    import random

    if not text or (isinstance(text, str) and text.strip() == ""):
        # Retourner un vecteur normalisé (pas de zéros) pour éviter l'erreur HCD
        # Utiliser un petit vecteur aléatoire normalisé avec seed fixe pour cohérence
        random.seed(42)  # Seed fixe pour cohérence
        vec = [random.gauss(0, 0.01) for _ in range(VECTOR_DIMENSION)]
        magnitude = math.sqrt(sum(x * x for x in vec))
        if magnitude > 0:
            return [x / magnitude for x in vec]
        return [0.001] * VECTOR_DIMENSION

    # Fixer la seed pour rendre le modèle déterministe
    torch.manual_seed(42)

    inputs = tokenizer(
        str(text), return_tensors="pt", truncation=True, padding=True, max_length=512
    )
    with torch.no_grad():
        encoder_outputs = model.encoder(**inputs)
        embeddings = encoder_outputs.last_hidden_state.mean(dim=1)
    result: List[float] = embeddings[0].tolist()

    # Vérifier que le vecteur n'est pas nul
    magnitude = math.sqrt(sum(x * x for x in result))
    if magnitude < 0.001:
        # Si le vecteur est trop petit, ajouter un petit bruit avec seed fixe
        random.seed(42)
        result = [x + random.gauss(0, 0.001) for x in result]
        magnitude = math.sqrt(sum(x * x for x in result))
        if magnitude > 0:
            result = [x / magnitude for x in result]

    return result


def vector_search(
    session, query_embedding: List[float], code_si: str, contrat: str, limit: int = 5
) -> List[Any]:
    """Effectue une recherche vectorielle avec ANN."""
    cql_query = f"""
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence, libelle_embedding
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
    LIMIT {limit}
    """  # nosec B608 - POC demo script, not production

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results
    except Exception as e:
        print(f"   ❌ Erreur: {str(e)}")
        return []


def fulltext_search(session, query: str, code_si: str, contrat: str, limit: int = 5) -> List[Any]:
    """Effectue une recherche full-text avec SAI."""
    # Syntaxe SAI : libelle : 'terme' (opérateur : pour full-text search)
    # Prendre le premier mot de la requête pour la recherche SAI
    # Note: SAI full-text recherche par terme, pas par phrase complète
    query_terms = query.split()
    if not query_terms:
        return []

    # Utiliser le premier terme pour la recherche SAI
    first_term = query_terms[0].replace("'", "''")

    cql_query = f"""
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
      AND libelle : '{first_term}'
    LIMIT {limit}
    """  # nosec B608 - POC demo script, not production

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results
    except Exception as e:
        # Si l'index SAI n'existe pas ou erreur, retourner liste vide
        print(f"   ⚠️  Full-Text Search non disponible : {str(e)}")
        return []


def calculate_cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """Calcule la similarité cosinus entre deux vecteurs.

    .. deprecated:: 1.4.1
        Use :func:`lib.search_utils.calculate_cosine_similarity` instead.
    """
    import math

    dot_product = sum(a * b for a, b in zip(vec1, vec2))
    magnitude1 = math.sqrt(sum(a * a for a in vec1))
    magnitude2 = math.sqrt(sum(a * a for a in vec2))
    if magnitude1 == 0 or magnitude2 == 0:
        return 0.0
    return dot_product / (magnitude1 * magnitude2)


def get_test_account(session) -> Optional[Tuple[str, str]]:
    """Récupère un compte de test (code_si, contrat)."""
    sample_query = (
        f"SELECT code_si, contrat FROM {KEYSPACE}.operations_by_account LIMIT 1"  # nosec B608
    )
    sample = session.execute(sample_query).one()
    if sample:
        return (sample.code_si, sample.contrat)
    return None


def connect_to_hcd():
    """Connexion à HCD."""
    cluster = Cluster(["localhost"], port=9042)
    session = cluster.connect(KEYSPACE)
    return cluster, session
