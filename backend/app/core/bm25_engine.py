"""
Okapi BM25 Search Engine.

Parameters:
  k1 = 1.2
  b  = 0.75

Workflow:
  1. Load all recipes from DB at startup
  2. Build BM25Okapi index over preprocessed documents
  3. search(query) → preprocesses query → scores corpus → returns ranked results
  4. Calculates match% (query ingredient overlap with recipe ingredients)
  5. Assigns relevance label + star rating based on score thresholds
"""

import logging
import re
from dataclasses import dataclass, field
from typing import Optional

from rank_bm25 import BM25Okapi

from app.core.config import settings
from app.core.preprocessor import (
    build_document,
    preprocess,
    preprocess_ingredients_list,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------
@dataclass
class RecipeDoc:
    """Lightweight in-memory representation of a recipe for BM25 indexing."""
    recipe_id: int
    title: str
    ingredients: str
    instructions: str
    category: str
    image_url: Optional[str]
    cooking_time: Optional[int]
    difficulty: Optional[str]
    # Parsed ingredient tokens (no stemming) for match display
    ingredient_names: list[str] = field(default_factory=list)
    # Stemmed ingredient tokens for BM25 matching
    ingredient_tokens_stemmed: list[str] = field(default_factory=list)


@dataclass
class BM25Result:
    recipe_id: int
    title: str
    category: str
    image_url: Optional[str]
    cooking_time: Optional[int]
    difficulty: Optional[str]
    bm25_score: float
    match_percentage: float
    matched_ingredients: list[str]
    missing_ingredients: list[str]
    matched_count: int
    total_query_count: int
    rank: int
    relevance_stars: int
    relevance_label: str


# ---------------------------------------------------------------------------
# BM25 Engine singleton
# ---------------------------------------------------------------------------
class BM25Engine:
    """
    Singleton BM25 search engine.

    Usage:
        engine = BM25Engine()
        await engine.initialize(recipes)      # call once at startup
        results = engine.search(["ayam", "bawang"])
    """

    def __init__(self):
        self._corpus: list[RecipeDoc] = []
        self._bm25_stemmed: Optional[BM25Okapi] = None
        self._bm25_no_stem: Optional[BM25Okapi] = None
        self._ready: bool = False

    # ------------------------------------------------------------------
    # Initialization
    # ------------------------------------------------------------------
    def initialize(self, recipes: list[dict]) -> None:
        """
        Build BM25 indexes from a list of recipe dicts.

        Each dict must have keys: id, title, ingredients, instructions,
        category, image_url, cooking_time, difficulty.
        """
        logger.info(f"Building BM25 index for {len(recipes)} recipes...")

        self._corpus = []
        docs_stemmed: list[list[str]] = []
        docs_no_stem: list[list[str]] = []

        for r in recipes:
            ing_names = preprocess_ingredients_list(r["ingredients"])
            ing_tokens_stemmed = [
                tok
                for name in ing_names
                for tok in preprocess(name, apply_stemming=True)
            ]

            doc = RecipeDoc(
                recipe_id=r["id"],
                title=r["title"],
                ingredients=r["ingredients"],
                instructions=r["instructions"],
                category=r["category"],
                image_url=r.get("image_url"),
                cooking_time=r.get("cooking_time"),
                difficulty=r.get("difficulty"),
                ingredient_names=ing_names,
                ingredient_tokens_stemmed=ing_tokens_stemmed,
            )
            self._corpus.append(doc)

            # Stemmed document (primary index)
            docs_stemmed.append(
                build_document(
                    r["title"], r["ingredients"], r["instructions"],
                    apply_stemming=True,
                )
            )
            # Non-stemmed document (for evaluation comparison)
            docs_no_stem.append(
                build_document(
                    r["title"], r["ingredients"], r["instructions"],
                    apply_stemming=False,
                )
            )

        self._bm25_stemmed = BM25Okapi(
            docs_stemmed,
            k1=settings.BM25_K1,
            b=settings.BM25_B,
        )
        self._bm25_no_stem = BM25Okapi(
            docs_no_stem,
            k1=settings.BM25_K1,
            b=settings.BM25_B,
        )
        self._ready = True
        logger.info("BM25 index built successfully.")

    def rebuild(self, recipes: list[dict]) -> None:
        """Re-build indexes (call when recipes are added/deleted via admin)."""
        self.initialize(recipes)

    # ------------------------------------------------------------------
    # Core Search
    # ------------------------------------------------------------------
    def search(
        self,
        ingredients: list[str],
        top_k: int = 20,
        filters: Optional[dict] = None,
        apply_stemming: bool = True,
    ) -> list[BM25Result]:
        """
        Search recipes using BM25.

        Args:
            ingredients: List of ingredient strings from the user
            top_k: Maximum number of results to return
            filters: Optional dict with keys: category, max_cooking_time, difficulty
            apply_stemming: Use stemmed index (default True)

        Returns:
            List of BM25Result sorted by score descending
        """
        if not self._ready:
            raise RuntimeError("BM25 engine not initialized. Call initialize() first.")

        if not ingredients:
            return []

        filters = filters or {}

        # ----- Preprocess query -----
        query_text = " ".join(ingredients)
        query_tokens = preprocess(query_text, apply_stemming=apply_stemming)

        if not query_tokens:
            return []

        # ----- BM25 scoring -----
        bm25 = self._bm25_stemmed if apply_stemming else self._bm25_no_stem
        scores = bm25.get_scores(query_tokens)

        # ----- Build results -----
        results: list[BM25Result] = []
        query_stemmed = [preprocess(ing, apply_stemming=True) for ing in ingredients]
        query_flat = [tok for toks in query_stemmed for tok in toks]

        for idx, score in enumerate(scores):
            if score <= 0:
                continue

            doc = self._corpus[idx]

            # ----- Apply filters -----
            if filters.get("category") and doc.category != filters["category"]:
                continue
            if filters.get("max_cooking_time") and doc.cooking_time:
                if doc.cooking_time > filters["max_cooking_time"]:
                    continue
            if filters.get("difficulty") and doc.difficulty != filters["difficulty"]:
                continue

            # ----- Ingredient match calculation -----
            matched, missing = self._match_ingredients(ingredients, doc)
            total = len(ingredients)
            match_pct = (len(matched) / total * 100) if total > 0 else 0.0

            # ----- Relevance label -----
            stars, label = self._relevance_label(score)

            results.append(
                BM25Result(
                    recipe_id=doc.recipe_id,
                    title=doc.title,
                    category=doc.category,
                    image_url=doc.image_url,
                    cooking_time=doc.cooking_time,
                    difficulty=doc.difficulty,
                    bm25_score=round(float(score), 4),
                    match_percentage=round(match_pct, 1),
                    matched_ingredients=matched,
                    missing_ingredients=missing,
                    matched_count=len(matched),
                    total_query_count=total,
                    rank=0,          # assigned below
                    relevance_stars=stars,
                    relevance_label=label,
                )
            )

        # ----- Sort -----
        results.sort(key=lambda r: r.bm25_score, reverse=True)

        # ----- Assign rank and limit -----
        results = results[:top_k]
        for i, r in enumerate(results):
            r.rank = i + 1

        return results

    def get_scores_raw(
        self,
        query_text: str,
        apply_stemming: bool = True,
    ) -> list[float]:
        """Return raw BM25 score array for evaluation use."""
        tokens = preprocess(query_text, apply_stemming=apply_stemming)
        bm25 = self._bm25_stemmed if apply_stemming else self._bm25_no_stem
        return list(bm25.get_scores(tokens))

    def get_top_ids(
        self,
        query_text: str,
        k: int = 10,
        apply_stemming: bool = True,
    ) -> list[int]:
        """Return top-k recipe IDs by BM25 score (for evaluation)."""
        scores = self.get_scores_raw(query_text, apply_stemming=apply_stemming)
        ranked = sorted(
            enumerate(scores), key=lambda x: x[1], reverse=True
        )[:k]
        return [self._corpus[idx].recipe_id for idx, _ in ranked]

    def get_all_ingredient_names(self) -> list[str]:
        """Return unique ingredient names across all recipes (for autocomplete)."""
        seen: set[str] = set()
        result: list[str] = []
        for doc in self._corpus:
            for name in doc.ingredient_names:
                key = name.lower()
                if key not in seen:
                    seen.add(key)
                    result.append(name)
        return sorted(result)

    @property
    def recipe_count(self) -> int:
        return len(self._corpus)

    @property
    def is_ready(self) -> bool:
        return self._ready

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------
    def _match_ingredients(
        self, query_ingredients: list[str], doc: RecipeDoc
    ) -> tuple[list[str], list[str]]:
        """
        Determine which query ingredients appear in the recipe.

        Uses stemmed token overlap for robust matching.
        """
        matched: list[str] = []
        missing: list[str] = []

        recipe_stems = set(doc.ingredient_tokens_stemmed)

        for ing in query_ingredients:
            ing_tokens = preprocess(ing, apply_stemming=True)
            if any(tok in recipe_stems for tok in ing_tokens):
                matched.append(ing)
            else:
                missing.append(ing)

        return matched, missing

    @staticmethod
    def _relevance_label(score: float) -> tuple[int, str]:
        """Map BM25 score to star rating and label."""
        if score >= settings.RELEVANCE_HIGHLY:
            return 5, "Highly Relevant"
        elif score >= settings.RELEVANCE_RELEVANT:
            return 4, "Relevant"
        elif score >= settings.RELEVANCE_MODERATE:
            return 3, "Moderate"
        elif score >= settings.RELEVANCE_PARTIAL:
            return 2, "Partial"
        else:
            return 1, "Low"


# ---------------------------------------------------------------------------
# Module-level singleton instance
# ---------------------------------------------------------------------------
bm25_engine = BM25Engine()
