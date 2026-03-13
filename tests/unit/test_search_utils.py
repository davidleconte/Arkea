#!/usr/bin/env python3
"""Unit tests for lib/search_utils.py shared search utilities."""

import math
import sys
from pathlib import Path

# Add project root to path before third-party imports
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

import pytest  # noqa: E402

from lib.search_utils import (  # noqa: E402
    calculate_cosine_similarity,
    euclidean_distance,
    normalize_vector,
)


class TestCosineSimilarity:
    """Tests for calculate_cosine_similarity."""

    def test_identical_vectors(self) -> None:
        """Identical vectors should have similarity 1.0."""
        vec = [1.0, 2.0, 3.0]
        assert calculate_cosine_similarity(vec, vec) == pytest.approx(1.0)

    def test_orthogonal_vectors(self) -> None:
        """Orthogonal vectors should have similarity 0.0."""
        vec1 = [1.0, 0.0]
        vec2 = [0.0, 1.0]
        assert calculate_cosine_similarity(vec1, vec2) == pytest.approx(0.0)

    def test_opposite_vectors(self) -> None:
        """Opposite vectors should have similarity -1.0."""
        vec1 = [1.0, 0.0]
        vec2 = [-1.0, 0.0]
        assert calculate_cosine_similarity(vec1, vec2) == pytest.approx(-1.0)

    def test_zero_vector_returns_zero(self) -> None:
        """Zero vector should return 0.0 (not NaN)."""
        vec1 = [0.0, 0.0, 0.0]
        vec2 = [1.0, 2.0, 3.0]
        assert calculate_cosine_similarity(vec1, vec2) == 0.0

    def test_both_zero_vectors(self) -> None:
        """Both zero vectors should return 0.0."""
        vec1 = [0.0, 0.0]
        vec2 = [0.0, 0.0]
        assert calculate_cosine_similarity(vec1, vec2) == 0.0

    def test_dimension_mismatch_raises(self) -> None:
        """Mismatched dimensions should raise ValueError."""
        with pytest.raises(ValueError, match="dimensions must match"):
            calculate_cosine_similarity([1.0, 2.0], [1.0, 2.0, 3.0])

    def test_high_dimensional(self) -> None:
        """Should work with high-dimensional vectors (like embeddings)."""
        dim = 1024
        vec1 = [1.0 / math.sqrt(dim)] * dim
        vec2 = [1.0 / math.sqrt(dim)] * dim
        assert calculate_cosine_similarity(vec1, vec2) == pytest.approx(1.0, abs=1e-6)

    def test_known_similarity(self) -> None:
        """Test with known cosine similarity value."""
        vec1 = [1.0, 2.0, 3.0]
        vec2 = [4.0, 5.0, 6.0]
        # Manual: dot=32, mag1=sqrt(14), mag2=sqrt(77)
        expected = 32.0 / (math.sqrt(14) * math.sqrt(77))
        assert calculate_cosine_similarity(vec1, vec2) == pytest.approx(expected)


class TestNormalizeVector:
    """Tests for normalize_vector."""

    def test_unit_vector_unchanged(self) -> None:
        """Already-normalized vector should remain the same."""
        vec = [1.0, 0.0, 0.0]
        result = normalize_vector(vec)
        assert result == pytest.approx([1.0, 0.0, 0.0])

    def test_normalization_produces_unit_length(self) -> None:
        """Result should have magnitude 1.0."""
        vec = [3.0, 4.0]
        result = normalize_vector(vec)
        magnitude = math.sqrt(sum(x * x for x in result))
        assert magnitude == pytest.approx(1.0)

    def test_zero_vector_unchanged(self) -> None:
        """Zero vector should be returned unchanged (avoid division by zero)."""
        vec = [0.0, 0.0, 0.0]
        result = normalize_vector(vec)
        assert result == [0.0, 0.0, 0.0]

    def test_negative_values(self) -> None:
        """Should handle negative values correctly."""
        vec = [-3.0, 4.0]
        result = normalize_vector(vec)
        magnitude = math.sqrt(sum(x * x for x in result))
        assert magnitude == pytest.approx(1.0)


class TestEuclideanDistance:
    """Tests for euclidean_distance."""

    def test_same_vector_zero_distance(self) -> None:
        """Distance between identical vectors should be 0."""
        vec = [1.0, 2.0, 3.0]
        assert euclidean_distance(vec, vec) == 0.0

    def test_known_distance(self) -> None:
        """Test with known distance value."""
        vec1 = [0.0, 0.0]
        vec2 = [3.0, 4.0]
        assert euclidean_distance(vec1, vec2) == pytest.approx(5.0)

    def test_dimension_mismatch_raises(self) -> None:
        """Mismatched dimensions should raise ValueError."""
        with pytest.raises(ValueError, match="dimensions must match"):
            euclidean_distance([1.0], [1.0, 2.0])

    def test_single_dimension(self) -> None:
        """Should work with 1D vectors."""
        assert euclidean_distance([5.0], [2.0]) == pytest.approx(3.0)

    def test_symmetry(self) -> None:
        """Distance(a,b) should equal distance(b,a)."""
        vec1 = [1.0, 2.0, 3.0]
        vec2 = [4.0, 5.0, 6.0]
        assert euclidean_distance(vec1, vec2) == pytest.approx(euclidean_distance(vec2, vec1))
