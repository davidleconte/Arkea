#!/usr/bin/env python3
"""
Module de Recherche LIKE et Wildcard pour domirama2
Implémente les patterns LIKE et wildcard via CQL API avec filtrage client-side

Ce module fournit les fonctions nécessaires pour :
- Convertir des patterns avec wildcards (* ou %) en regex
- Parser des requêtes LIKE au format "field LIKE 'pattern'"
- Effectuer des recherches hybrides combinant vector search et LIKE patterns
- Filtrer les résultats client-side avec regex

Basé sur les démonstrations du fichier inputs-ibm/[fuzzy_and_complex_search_with_vector_search].py
"""

import os
import re
import sys
import time
from dataclasses import dataclass

# Imports conditionnels pour éviter erreurs si non installés
try:
    import torch
    from transformers import AutoModel, AutoTokenizer

    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False

try:
    from cassandra.query import ConsistencyLevel

    CASSANDRA_AVAILABLE = True
except ImportError:
    CASSANDRA_AVAILABLE = False

from typing import Any, Dict, List, Optional, Tuple


@dataclass
class SearchMetrics:
    """Métriques de performance pour une recherche hybride LIKE"""

    total_time_ms: float
    embedding_time_ms: float
    cql_execution_time_ms: float
    filtering_time_ms: float
    vector_results_count: int
    filtered_results_count: int
    filter_efficiency: float  # Pourcentage de résultats conservés après filtrage


# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
HF_API_KEY = os.getenv("HF_API_KEY")
KEYSPACE = "domirama2_poc"
TABLE_NAME = "operations_by_account"

# Cache global pour le modèle (évite de recharger à chaque appel)
_model_cache = None
_tokenizer_cache = None


def build_regex_pattern(query_pattern: str) -> str:
    """
    Convertit un pattern avec wildcards (* ou %) en regex pattern.

    Cette fonction permet de simuler le comportement SQL LIKE en convertissant
    les wildcards en expressions régulières pour filtrage client-side.

    Args:
        query_pattern: Pattern avec wildcards (ex: "%LOYER%", "LOYER*", "*LOYER")

    Returns:
        regex_pattern: Pattern regex pour filtrage client-side (ex: ".*LOYER.*")

    Examples:
        >>> build_regex_pattern("%LOYER%")
        '.*LOYER.*'
        >>> build_regex_pattern("LOYER*")
        '^LOYER.*'
        >>> build_regex_pattern("*LOYER")
        '.*LOYER$'
    """
    # Utiliser un placeholder peu probable pour préserver les wildcards
    placeholder = "__WILDCARD__"

    # Détecter si le pattern commence ou se termine par un wildcard
    starts_with_wildcard = query_pattern.startswith("*") or query_pattern.startswith("%")
    ends_with_wildcard = query_pattern.endswith("*") or query_pattern.endswith("%")

    # Remplacer '*' et '%' par le placeholder (les deux sont équivalents)
    temp_pattern = query_pattern.replace("*", placeholder).replace("%", placeholder)

    # Échapper tous les caractères spéciaux regex pour sécurité
    escaped = re.escape(temp_pattern)

    # Remplacer le placeholder par '.*' (regex pour "n'importe quels
    # caractères")
    regex_pattern = escaped.replace(placeholder, ".*")

    # Ajouter les ancres ^ et $ pour correspondre exactement au comportement SQL LIKE
    # - Si le pattern commence par wildcard mais ne se termine pas : ajouter $ à la fin
    #   (ex: '*LOYER' → '.*LOYER$' - doit se terminer par LOYER)
    # - Si le pattern se termine par wildcard mais ne commence pas : ajouter ^ au début
    #   (ex: 'LOYER*' → '^LOYER.*' - doit commencer par LOYER)
    # - Si le pattern commence ET se termine par wildcard : pas d'ancres
    #   (ex: '%LOYER%' → '.*LOYER.*' - peut être n'importe où)

    if starts_with_wildcard and not ends_with_wildcard:
        # Pattern commence par wildcard mais ne se termine pas : doit se
        # terminer par le texte
        if not regex_pattern.endswith("$"):
            regex_pattern = regex_pattern + "$"
    elif ends_with_wildcard and not starts_with_wildcard:
        # Pattern se termine par wildcard mais ne commence pas : doit commencer
        # par le texte
        if not regex_pattern.startswith("^"):
            regex_pattern = "^" + regex_pattern

    return regex_pattern


def parse_explicit_like(query: str) -> Tuple[Optional[str], Optional[str]]:
    """
    Parse une requête LIKE et extrait le champ et le pattern regex.

    Cette fonction analyse une requête au format SQL-like "field LIKE 'pattern'"
    et retourne le nom du champ et le pattern regex correspondant.

    Args:
        query: Requête au format "field LIKE 'pattern'" (insensible à la casse)

    Returns:
        Tuple (field, regex_pattern):
            - field: Nom du champ (ex: "libelle", "cat_auto")
            - regex_pattern: Pattern regex pour filtrage (ex: ".*LOYER.*")
            - (None, None) si la requête n'est pas valide

    Examples:
        >>> parse_explicit_like("libelle LIKE '%LOYER%'")
        ('libelle', '.*LOYER.*')
        >>> parse_explicit_like("cat_auto LIKE 'IMP*'")
        ('cat_auto', 'IMP.*')
    """
    # Pattern regex pour capturer : field LIKE 'pattern'
    pattern = r"(\w+)\s+LIKE\s+['\"](.+)['\"]"
    match = re.search(pattern, query, re.IGNORECASE)

    if match:
        field = match.group(1)
        like_pattern = match.group(2)
        regex = build_regex_pattern(like_pattern)
        return field, regex

    return None, None


def load_model():
    """
    Charge le modèle ByteT5 pour génération d'embeddings.
    Utilise un cache global pour éviter de recharger le modèle à chaque appel.

    Returns:
        Tuple (tokenizer, model): Tokenizer et modèle ByteT5 chargés

    Raises:
        ImportError: Si torch ou transformers ne sont pas installés
    """
    global _model_cache, _tokenizer_cache

    if not TORCH_AVAILABLE:
        raise ImportError(
            "torch et transformers doivent être installés: pip3 install transformers torch"
        )

    # Utiliser le cache si disponible
    if _model_cache is not None and _tokenizer_cache is not None:
        return _tokenizer_cache, _model_cache

    # Charger le modèle (première fois seulement)
    _tokenizer_cache = AutoTokenizer.from_pretrained(MODEL_NAME, token=HF_API_KEY)
    _model_cache = AutoModel.from_pretrained(MODEL_NAME, token=HF_API_KEY)
    _model_cache.eval()
    return _tokenizer_cache, _model_cache


def encode_text(tokenizer, model, text: str) -> List[float]:
    """
    Encode un texte en vecteur d'embedding ByteT5.

    Args:
        tokenizer: Tokenizer ByteT5
        model: Modèle ByteT5
        text: Texte à encoder

    Returns:
        embedding: Liste de 1472 floats représentant l'embedding
    """
    if not text or text.strip() == "":
        return [0.0] * VECTOR_DIMENSION

    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)

    with torch.no_grad():
        encoder_outputs = model.encoder(**inputs)
        embeddings = encoder_outputs.last_hidden_state.mean(dim=1)

    return embeddings[0].tolist()


def hybrid_like_search(
    session,
    query_text: str,
    like_query: str,
    code_si: str,
    contrat: str,
    filter_dict: Optional[Dict[str, Any]] = None,
    limit: int = 10,
    vector_limit: int = 200,
    return_metrics: bool = False,
) -> Tuple[List[Any], Optional[SearchMetrics]]:
    """
    Recherche hybride combinant vector search et LIKE pattern.

    Cette fonction implémente une recherche en deux étapes :
    1. Recherche vectorielle (ANN) pour réduire le nombre de candidats
    2. Filtrage client-side avec regex pour appliquer le pattern LIKE

    Args:
        session: Session Cassandra
        query_text: Texte pour recherche vectorielle (peut contenir typos)
        like_query: Requête LIKE (ex: "libelle LIKE '%LOYER%'")
        code_si: Code SI pour partition
        contrat: Contrat pour partition
        filter_dict: Filtres additionnels CQL (optionnel)
        limit: Nombre de résultats finaux à retourner
        vector_limit: Nombre de résultats vectoriels à récupérer avant filtrage

    Returns:
        Tuple (results, metrics):
            - results: Liste de résultats filtrés et triés par similarité vectorielle
            - metrics: Métriques de performance (None si return_metrics=False)
    """
    start_total = time.time()
    metrics = SearchMetrics(
        total_time_ms=0.0,
        embedding_time_ms=0.0,
        cql_execution_time_ms=0.0,
        filtering_time_ms=0.0,
        vector_results_count=0,
        filtered_results_count=0,
        filter_efficiency=0.0,
    )

    # Parser la requête LIKE
    field, regex_pattern = parse_explicit_like(like_query)

    if not field or not regex_pattern:
        raise ValueError(f"Requête LIKE invalide: {like_query}")

    # Charger le modèle et encoder la requête
    tokenizer, model = load_model()
    query_embedding = encode_text(tokenizer, model, query_text)

    # Construire la requête CQL avec paramètres positionnels
    conditions = ["code_si = ?", "contrat = ?"]

    # Construire les paramètres
    params = [code_si, contrat]

    # Ajouter les filtres additionnels
    if filter_dict:
        for col, val in filter_dict.items():
            if isinstance(val, dict):
                if "$gte" in val and "$lte" in val:
                    conditions.append(f"{col} >= ? AND {col} <= ?")
                    params.extend([val["$gte"], val["$lte"]])
                elif "$gte" in val:
                    conditions.append(f"{col} >= ?")
                    params.append(val["$gte"])
                elif "$lte" in val:
                    conditions.append(f"{col} <= ?")
                    params.append(val["$lte"])
                elif "$in" in val:
                    in_vals = val["$in"]
                    placeholders = ", ".join("?" for _ in in_vals)
                    conditions.append(f"{col} IN ({placeholders})")
                    params.extend(in_vals)
            else:
                conditions.append(f"{col} = ?")
                params.append(val)

    # Construire la clause WHERE
    "WHERE " + " AND ".join(conditions) if conditions else ""

    # Requête CQL complète avec ANN
    cql_query = """
    SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto, cat_user,
           similarity_cosine(libelle_embedding, ?) AS sim
    FROM {KEYSPACE}.{TABLE_NAME}
    {where_clause}
    ORDER BY libelle_embedding ANN OF ? LIMIT ?
    """

    # Ajouter le vecteur pour similarity_cosine, ANN et la limite
    params = [query_embedding] + params + [query_embedding, vector_limit]

    try:
        # Préparer et exécuter la requête
        prepared = session.prepare(cql_query)
        prepared.consistency_level = ConsistencyLevel.LOCAL_ONE

        start_cql = time.time()
        rows = session.execute(prepared, tuple(params))
        results = list(rows)
        metrics.cql_execution_time_ms = (time.time() - start_cql) * 1000
        metrics.vector_results_count = len(results)

        # Filtrer les résultats client-side avec le pattern LIKE
        start_filtering = time.time()
        filtered_results = []
        for row in results:
            # Récupérer la valeur du champ spécifié dans la requête LIKE
            field_value = getattr(row, field, "")

            # Appliquer le filtre regex (insensible à la casse)
            if re.search(regex_pattern, str(field_value), re.IGNORECASE):
                filtered_results.append(row)

        # Trier par similarité décroissante et limiter
        filtered_results.sort(key=lambda x: getattr(x, "sim", 0.0), reverse=True)
        final_results = filtered_results[:limit]
        metrics.filtering_time_ms = (time.time() - start_filtering) * 1000
        metrics.filtered_results_count = len(final_results)

        # Calculer l'efficacité du filtrage
        if metrics.vector_results_count > 0:
            metrics.filter_efficiency = (
                metrics.filtered_results_count / metrics.vector_results_count
            ) * 100

        metrics.total_time_ms = (time.time() - start_total) * 1000

        # Toujours retourner un tuple pour compatibilité
        if return_metrics:
            return final_results, metrics
        return final_results, None

    except Exception as e:
        metrics.total_time_ms = (time.time() - start_total) * 1000
        print(f"❌ Erreur lors de la recherche hybride LIKE: {str(e)}", file=sys.stderr)
        if return_metrics:
            return [], metrics
        return [], None


def multi_field_like_search(
    session,
    query_text: str,
    like_queries: List[str],
    code_si: str,
    contrat: str,
    filter_dict: Optional[Dict[str, Any]] = None,
    limit: int = 10,
    match_all: bool = False,
    vector_limit: int = 200,
    return_metrics: bool = False,
) -> Tuple[List[Any], Optional[SearchMetrics]]:
    """
    Recherche hybride avec LIKE patterns sur plusieurs champs.

    Args:
        session: Session Cassandra
        query_text: Texte pour recherche vectorielle
        like_queries: Liste de requêtes LIKE (ex: ["libelle LIKE '%LOYER%'", "cat_auto LIKE '%IMP%'"])
        code_si: Code SI pour partition
        contrat: Contrat pour partition
        filter_dict: Filtres additionnels CQL (optionnel)
        limit: Nombre de résultats finaux
        match_all: Si True, tous les patterns doivent matcher (AND), sinon au moins un (OR)
        vector_limit: Nombre de candidats vectoriels à récupérer avant filtrage
        return_metrics: Si True, retourne aussi les métriques de performance

    Returns:
        Tuple (results, metrics):
            - results: Liste de résultats filtrés
            - metrics: Métriques de performance (None si return_metrics=False)
    """
    start_total = time.time()
    metrics = SearchMetrics(
        total_time_ms=0.0,
        embedding_time_ms=0.0,
        cql_execution_time_ms=0.0,
        filtering_time_ms=0.0,
        vector_results_count=0,
        filtered_results_count=0,
        filter_efficiency=0.0,
    )

    # Parser toutes les requêtes LIKE
    parsed_patterns = []
    for like_query in like_queries:
        field, regex_pattern = parse_explicit_like(like_query)
        if field and regex_pattern:
            parsed_patterns.append((field, regex_pattern))

    if not parsed_patterns:
        raise ValueError("Aucune requête LIKE valide fournie")

    # Effectuer la recherche vectorielle de base
    start_embedding = time.time()
    tokenizer, model = load_model()
    query_embedding = encode_text(tokenizer, model, query_text)
    metrics.embedding_time_ms = (time.time() - start_embedding) * 1000

    # Construire la requête CQL avec paramètres positionnels
    conditions = ["code_si = ?", "contrat = ?"]

    params = [code_si, contrat]

    if filter_dict:
        for col, val in filter_dict.items():
            if isinstance(val, dict):
                if "$gte" in val and "$lte" in val:
                    conditions.append(f"{col} >= ? AND {col} <= ?")
                    params.extend([val["$gte"], val["$lte"]])
                elif "$in" in val:
                    in_vals = val["$in"]
                    placeholders = ", ".join("?" for _ in in_vals)
                    conditions.append(f"{col} IN ({placeholders})")
                    params.extend(in_vals)
            else:
                conditions.append(f"{col} = ?")
                params.append(val)

    "WHERE " + " AND ".join(conditions)

    # Requête CQL complète avec ANN
    cql_query = """
    SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto, cat_user,
           similarity_cosine(libelle_embedding, ?) AS sim
    FROM {KEYSPACE}.{TABLE_NAME}
    {where_clause}
    ORDER BY libelle_embedding ANN OF ? LIMIT ?
    """

    # Ajouter le vecteur pour similarity_cosine, ANN et la limite
    params = [query_embedding] + params + [query_embedding, vector_limit]

    try:
        prepared = session.prepare(cql_query)
        prepared.consistency_level = ConsistencyLevel.LOCAL_ONE

        start_cql = time.time()
        rows = session.execute(prepared, tuple(params))
        results = list(rows)
        metrics.cql_execution_time_ms = (time.time() - start_cql) * 1000
        metrics.vector_results_count = len(results)

        # Filtrer avec tous les patterns LIKE
        start_filtering = time.time()
        filtered_results = []
        for row in results:
            matches = []

            for field, regex_pattern in parsed_patterns:
                field_value = getattr(row, field, "")
                if re.search(regex_pattern, str(field_value), re.IGNORECASE):
                    matches.append(True)
                else:
                    matches.append(False)

            # Appliquer la logique AND ou OR
            if match_all:
                if all(matches):
                    filtered_results.append(row)
            else:
                if any(matches):
                    filtered_results.append(row)

        # Trier par similarité et limiter
        filtered_results.sort(key=lambda x: getattr(x, "sim", 0.0), reverse=True)
        final_results = filtered_results[:limit]
        metrics.filtering_time_ms = (time.time() - start_filtering) * 1000
        metrics.filtered_results_count = len(final_results)

        # Calculer l'efficacité du filtrage
        if metrics.vector_results_count > 0:
            metrics.filter_efficiency = (
                metrics.filtered_results_count / metrics.vector_results_count
            ) * 100

        metrics.total_time_ms = (time.time() - start_total) * 1000

        if return_metrics:
            return final_results, metrics
        return final_results, None

    except Exception as e:
        metrics.total_time_ms = (time.time() - start_total) * 1000
        print(
            f"❌ Erreur lors de la recherche multi-champs LIKE: {str(e)}",
            file=sys.stderr,
        )
        if return_metrics:
            return [], metrics
        return [], None


def test_like_patterns():
    """
    Fonction de test pour valider les fonctions LIKE/wildcard.
    """
    print("=" * 70)
    print("  🧪 Tests des Fonctions LIKE/Wildcard")
    print("=" * 70)
    print()

    # Test build_regex_pattern
    print("📝 Test build_regex_pattern:")
    test_cases = [
        ("%LOYER%", ".*LOYER.*"),
        ("LOYER*", "LOYER.*"),
        ("*LOYER", ".*LOYER"),
        ("%LOYER%IMP%", ".*LOYER.*IMP.*"),
    ]

    for pattern, expected in test_cases:
        result = build_regex_pattern(pattern)
        status = "✅" if result == expected else "❌"
        print(f"   {status} '{pattern}' → '{result}' (attendu: '{expected}')")

    print()

    # Test parse_explicit_like
    print("📝 Test parse_explicit_like:")
    like_tests = [
        ("libelle LIKE '%LOYER%'", ("libelle", ".*LOYER.*")),
        ("cat_auto LIKE 'IMP*'", ("cat_auto", "IMP.*")),
        ("libelle LIKE '*LOYER'", ("libelle", ".*LOYER")),
    ]

    for query, expected in like_tests:
        field, regex = parse_explicit_like(query)
        status = "✅" if (field, regex) == expected else "❌"
        print(f"   {status} '{query}' → field='{field}', regex='{regex}'")

    print()
    print("✅ Tests terminés")


if __name__ == "__main__":
    test_like_patterns()
