#!/usr/bin/env python3
"""
Shared search utilities for ARKEA POC.

This module centralizes common search functions used across multiple POC
examples to avoid code duplication. Import from here instead of copying
functions between files.

Usage:
    from lib.search_utils import calculate_cosine_similarity, normalize_vector
"""

import math
from typing import List


def calculate_cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """Calculate cosine similarity between two vectors.

    Args:
        vec1: First vector.
        vec2: Second vector.

    Returns:
        Cosine similarity score between -1.0 and 1.0.
        Returns 0.0 if either vector has zero magnitude.
    """
    if len(vec1) != len(vec2):
        raise ValueError(f"Vector dimensions must match: {len(vec1)} != {len(vec2)}")

    dot_product = sum(a * b for a, b in zip(vec1, vec2))
    magnitude1 = math.sqrt(sum(a * a for a in vec1))
    magnitude2 = math.sqrt(sum(a * a for a in vec2))

    if magnitude1 == 0 or magnitude2 == 0:
        return 0.0

    return dot_product / (magnitude1 * magnitude2)


def normalize_vector(vec: List[float]) -> List[float]:
    """Normalize a vector to unit length.

    Args:
        vec: Input vector.

    Returns:
        Normalized vector with unit magnitude.
        Returns original vector if magnitude is zero.
    """
    magnitude = math.sqrt(sum(x * x for x in vec))
    if magnitude == 0:
        return vec
    return [x / magnitude for x in vec]


def euclidean_distance(vec1: List[float], vec2: List[float]) -> float:
    """Calculate Euclidean distance between two vectors.

    Args:
        vec1: First vector.
        vec2: Second vector.

    Returns:
        Euclidean distance (L2 norm of difference).
    """
    if len(vec1) != len(vec2):
        raise ValueError(f"Vector dimensions must match: {len(vec1)} != {len(vec2)}")

    return math.sqrt(sum((a - b) ** 2 for a, b in zip(vec1, vec2)))
