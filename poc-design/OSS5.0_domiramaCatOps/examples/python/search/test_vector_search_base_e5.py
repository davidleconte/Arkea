#!/usr/bin/env python3
"""
Module de base pour les tests de recherche vectorielle avec multilingual-e5-large.
Extension de test_vector_search_base.py pour supporter e5-large.
"""

import math
import os
import random
import sys
from typing import Any, List

# Add project root to path for shared library access
sys.path.insert(0, str(os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "..")))
import torch  # noqa: E402
from cassandra.cluster import Cluster  # noqa: E402
from cassandra.query import SimpleStatement  # noqa: E402
from sentence_transformers import SentenceTransformer  # noqa: E402

from lib.search_utils import calculate_cosine_similarity as _shared_cosine_sim  # noqa: E402

# Configuration
MODEL_NAME_E5 = "intfloat/multilingual-e5-large"
VECTOR_DIMENSION_E5 = 1024
KEYSPACE = "domiramacatops_poc"

# Variables globales pour cache du modèle
_model_e5 = None

# Fixer la seed globale pour cohérence
torch.manual_seed(42)
random.seed(42)


def load_model_e5():
    """Charge le modèle multilingual-e5-large avec cache."""
    global _model_e5
    if _model_e5 is None:
        print(f"📥 Chargement du modèle {MODEL_NAME_E5}...")
        _model_e5 = SentenceTransformer(MODEL_NAME_E5)
        print(f"✅ Modèle chargé (dimension: {VECTOR_DIMENSION_E5})")
    return _model_e5


def encode_text_e5(model, text: str) -> List[float]:
    """Encode un texte en vecteur d'embedding avec e5-large."""
    if not text or (isinstance(text, str) and text.strip() == ""):
        # Retourner un vecteur normalisé (pas de zéros)
        random.seed(42)
        vec = [random.gauss(0, 0.01) for _ in range(VECTOR_DIMENSION_E5)]
        magnitude = math.sqrt(sum(x * x for x in vec))
        if magnitude > 0:
            return [x / magnitude for x in vec]
        return [0.001] * VECTOR_DIMENSION_E5

    # Encoder avec e5-large
    embedding = model.encode(text, normalize_embeddings=True)
    return list(embedding.tolist())


def vector_search_e5(
    session, query_embedding: List[float], code_si: str, contrat: str, limit: int = 5
) -> List[Any]:
    """Effectue une recherche vectorielle avec ANN en utilisant libelle_embedding_e5."""
    cql_query = """
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence, libelle_embedding_e5
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding_e5 ANN OF {json.dumps(query_embedding)}
    LIMIT {limit}
    """  # nosec B608 - POC demo script, not production

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results
    except Exception as e:
        print(f"   ❌ Erreur: {str(e)}")
        return []


def connect_to_hcd():
    """Connexion à HCD."""
    cluster = Cluster(["localhost"])
    session = cluster.connect(KEYSPACE)
    return cluster, session


def get_test_account(session):
    """Récupère un compte de test."""
    query = f"SELECT code_si, contrat FROM {KEYSPACE}.operations_by_account LIMIT 1"  # nosec B608
    result = list(session.execute(query))
    if result:
        return (result[0].code_si, result[0].contrat)
    return None


def calculate_cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """Calcule la similarité cosinus entre deux vecteurs.

    .. deprecated:: 1.4.1
        Use :func:`lib.search_utils.calculate_cosine_similarity` instead.
    """
    return _shared_cosine_sim(vec1, vec2)
