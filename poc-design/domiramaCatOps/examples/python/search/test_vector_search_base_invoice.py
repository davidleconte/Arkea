#!/usr/bin/env python3
"""
Module de base pour le modèle spécialisé facturation.
Fonctions communes pour charger le modèle et effectuer des recherches.
"""

import json
import sys

from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement

# Configuration
KEYSPACE = "domiramacatops_poc"

# Modèle spécialisé facturation
MODEL_NAME_INVOICE = "NoureddineSa/Invoices_bilingual-embedding-large"
VECTOR_DIMENSION_INVOICE = 1024

# Cache global pour le modèle
_model_invoice = None


def load_model_invoice():
    """Charge le modèle spécialisé facturation (avec cache)."""
    global _model_invoice

    if _model_invoice is not None:
        return _model_invoice

    try:
        from sentence_transformers import SentenceTransformer

        print(f"📥 Chargement du modèle {MODEL_NAME_INVOICE}...")
        _model_invoice = SentenceTransformer(MODEL_NAME_INVOICE, trust_remote_code=True)
        print(f"✅ Modèle chargé (dimension: {VECTOR_DIMENSION_INVOICE})")
        return _model_invoice
    except ImportError:
        print("❌ sentence-transformers n'est pas installé")
        print("   Installation : pip install sentence-transformers")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erreur lors du chargement du modèle: {e}")
        sys.exit(1)


def encode_text_invoice(model, text: str):
    """Encode un texte en embedding avec le modèle facturation.

    Args:
        model: Le modèle SentenceTransformer chargé
        text: Le texte à encoder

    Returns:
        list: L'embedding normalisé (liste Python pour sérialisation JSON)
    """
    import numpy as np

    if not text or not text.strip():
        # Retourner un vecteur zéro normalisé pour éviter les erreurs HCD
        embedding = np.zeros(VECTOR_DIMENSION_INVOICE, dtype=np.float32)
        embedding[0] = 0.001  # Petite valeur pour éviter vecteur nul
        embedding = embedding / np.linalg.norm(embedding)
        return embedding.tolist()

    # Encoder avec normalisation
    embedding = model.encode(text, normalize_embeddings=True, show_progress_bar=False)
    # Convertir en liste Python (pas ndarray) pour sérialisation JSON
    if isinstance(embedding, np.ndarray):
        return embedding.tolist()
    return list(embedding)


def vector_search_invoice(session, embedding, code_si: str, contrat: str, limit: int = 5):
    """Effectue une recherche vectorielle avec le modèle facturation.

    Args:
        session: Session Cassandra
        embedding: L'embedding de la requête
        code_si: Code SI
        contrat: Numéro de contrat
        limit: Nombre de résultats à retourner

    Returns:
        list: Liste de résultats (objets Row)
    """
    cql_query = f"""
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence, libelle_embedding_invoice
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding_invoice ANN OF {json.dumps(
            embedding if isinstance(embedding, list) else embedding.tolist()
        )}
    LIMIT {limit}
    """

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results
    except Exception as e:
        print(f"❌ Erreur lors de la recherche: {e}")
        return []


def connect_to_hcd():
    """Connexion à HCD."""
    cluster = Cluster(["localhost"])
    session = cluster.connect(KEYSPACE)
    return cluster, session


def get_test_account(session):
    """Récupère un compte de test avec des opérations."""
    query = f"""
    SELECT code_si, contrat
    FROM {KEYSPACE}.operations_by_account
    WHERE libelle IS NOT NULL
    LIMIT 1
    ALLOW FILTERING
    """

    try:
        result = session.execute(query).one()
        if result:
            return (result.code_si, result.contrat)
    except Exception:
        pass

    # Fallback : utiliser un compte par défaut
    return ("6", "600000041")
