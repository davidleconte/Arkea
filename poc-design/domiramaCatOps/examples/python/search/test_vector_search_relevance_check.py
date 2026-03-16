#!/usr/bin/env python3
"""
Fonction utilitaire pour vérifier la pertinence des résultats de recherche.
"""


def check_relevance(query: str, results, min_relevance: float = 0.3) -> dict:
    """Vérifie la pertinence des résultats par rapport à la requête.

    Args:
        query: La requête de recherche
        results: Liste de résultats (objets avec attribut libelle)
        min_relevance: Score minimum pour considérer un résultat pertinent

    Returns:
        dict avec:
        - relevant_count: Nombre de résultats pertinents
        - total_count: Nombre total de résultats
        - relevance_rate: Taux de pertinence
        - relevant_results: Liste des résultats pertinents
        - irrelevant_results: Liste des résultats non pertinents
    """
    # Mapping de synonymes/équivalences (ex: CB = Carte Bleue = PAIEMENT CARTE)
    synonym_mapping = {
        "PAIEMENT CARTE": ["CB", "CARTE BLEUE", "CARTE BANCAIRE", "PAIEMENT CARTE"],
        "CARTE": ["CB", "CARTE BLEUE", "CARTE BANCAIRE"],
        "CB": ["PAIEMENT CARTE", "CARTE BLEUE", "CARTE BANCAIRE", "CARTE"],
    }

    query_upper = query.upper()
    query_words = set(query_upper.split())

    # Étendre les mots de la requête avec les synonymes
    expanded_query_words = set(query_words)
    for word in query_words:
        if word in synonym_mapping:
            expanded_query_words.update(synonym_mapping[word])

    # Vérifier aussi si la requête complète correspond à un synonyme
    if query_upper in synonym_mapping:
        expanded_query_words.update(synonym_mapping[query_upper])

    relevant = []
    irrelevant = []

    for result in results:
        if not hasattr(result, "libelle") or not result.libelle:
            irrelevant.append(result)
            continue

        libelle_upper = result.libelle.upper()
        libelle_words = set(libelle_upper.split())

        # Calculer le score de pertinence (Jaccard similarity) avec les mots
        # étendus
        intersection = len(expanded_query_words & libelle_words)
        union = len(expanded_query_words | libelle_words)
        relevance_score = intersection / union if union > 0 else 0

        # Vérifier aussi si les mots-clés importants sont présents
        important_keywords = {
            "LOYER",
            "IMPAYE",
            "VIREMENT",
            "PAIEMENT",
            "CARTE",
            "CB",
            "CARREFOUR",
            "RESTAURANT",
            "SUPERMARCHE",
            "CARTE BLEUE",
            "CARTE BANCAIRE",
        }
        has_important_keyword = any(
            kw in libelle_upper
            for kw in important_keywords
            if kw in query_upper or any(syn in query_upper for syn in synonym_mapping.get(kw, []))
        )

        # Cas spécial : "PAIEMENT CARTE" ou "CARTE" doit reconnaître "CB"
        if ("PAIEMENT" in query_upper and "CARTE" in query_upper) or "CARTE" in query_upper:
            if "CB" in libelle_upper:
                has_important_keyword = True
                relevance_score = max(relevance_score, 0.5)  # Score minimum pour CB

        if relevance_score >= min_relevance or has_important_keyword:
            relevant.append((result, relevance_score))
        else:
            irrelevant.append((result, relevance_score))

    total = len(results)
    relevant_count = len(relevant)
    relevance_rate = relevant_count / total if total > 0 else 0

    return {
        "relevant_count": relevant_count,
        "total_count": total,
        "relevance_rate": relevance_rate,
        "relevant_results": relevant,
        "irrelevant_results": irrelevant,
        "is_mostly_relevant": relevance_rate >= 0.5,
    }
