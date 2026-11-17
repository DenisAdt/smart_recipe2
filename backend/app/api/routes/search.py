"""
Search API Route — Multi-algorithm IR endpoint.

POST /api/search   — supports algorithm selection: bm25 | bm25_stem | tfidf
GET  /api/search/suggestions
"""

import json
import logging
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.bm25_engine import bm25_engine, BM25Result
from app.core.tfidf_engine import tfidf_engine
from app.database.db import get_db
from app.models.search_log import SearchLog
from app.schemas.search import (
    SearchRequest,
    SearchResponse,
    SearchResultItem,
    SuggestionResponse,
)

router = APIRouter(prefix="/search", tags=["Search"])
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _bm25_result_to_item(r: BM25Result) -> SearchResultItem:
    return SearchResultItem(
        recipe_id=r.recipe_id,
        title=r.title,
        category=r.category,
        image_url=r.image_url,
        cooking_time=r.cooking_time,
        difficulty=r.difficulty,
        bm25_score=r.bm25_score,
        match_percentage=r.match_percentage,
        matched_ingredients=r.matched_ingredients,
        missing_ingredients=r.missing_ingredients,
        matched_count=r.matched_count,
        total_query_count=r.total_query_count,
        rank=r.rank,
        relevance_stars=r.relevance_stars,
        relevance_label=r.relevance_label,
    )


def _tfidf_results(
    ingredients: list[str],
    top_k: int,
    filters: dict,
) -> list[SearchResultItem]:
    """
    Execute TF-IDF retrieval and return SearchResultItem list.

    TF-IDF scores (cosine similarity, 0–1) are stored in `bm25_score`
    so the frontend response shape is identical across all algorithms.
    Ingredient match calculation reuses bm25_engine's corpus helper.
    """
    query_text = " ".join(ingredients)
    id_score_pairs = tfidf_engine.get_scores_full(
        query_text, top_k=top_k, apply_stemming=True
    )

    # Build a lookup: recipe_id → cosine_score
    score_map: dict[int, float] = {rid: score for rid, score in id_score_pairs}

    # Fetch matching docs from the BM25 corpus (same source of truth)
    result_items: list[SearchResultItem] = []
    for doc in bm25_engine._corpus:
        if doc.recipe_id not in score_map:
            continue

        # Apply same filters as BM25 path
        if filters.get("category") and doc.category != filters["category"]:
            continue
        if filters.get("max_cooking_time") and doc.cooking_time:
            if doc.cooking_time > filters["max_cooking_time"]:
                continue
        if filters.get("difficulty") and doc.difficulty != filters["difficulty"]:
            continue

        cosine = score_map[doc.recipe_id]
        matched, missing = bm25_engine._match_ingredients(ingredients, doc)
        total = len(ingredients)
        match_pct = (len(matched) / total * 100) if total > 0 else 0.0

        # Map cosine score (0–1) to relevance label using scaled thresholds
        stars, label = _cosine_relevance_label(cosine)

        result_items.append(
            SearchResultItem(
                recipe_id=doc.recipe_id,
                title=doc.title,
                category=doc.category,
                image_url=doc.image_url,
                cooking_time=doc.cooking_time,
                difficulty=doc.difficulty,
                bm25_score=round(cosine, 4),   # cosine score stored here
                match_percentage=round(match_pct, 1),
                matched_ingredients=matched,
                missing_ingredients=missing,
                matched_count=len(matched),
                total_query_count=total,
                rank=0,
                relevance_stars=stars,
                relevance_label=label,
            )
        )

    # Sort by relevance score
    result_items.sort(key=lambda r: r.bm25_score, reverse=True)

    # Assign rank and limit
    result_items = result_items[:top_k]
    for i, item in enumerate(result_items):
        item.rank = i + 1

    return result_items


def _cosine_relevance_label(score: float) -> tuple[int, str]:
    """Map cosine similarity score (0–1) to star rating and label."""
    if score >= 0.5:
        return 5, "Highly Relevant"
    elif score >= 0.3:
        return 4, "Relevant"
    elif score >= 0.15:
        return 3, "Moderate"
    elif score >= 0.05:
        return 2, "Partial"
    else:
        return 1, "Low"


# ---------------------------------------------------------------------------
# Route
# ---------------------------------------------------------------------------
@router.post("", response_model=SearchResponse)
async def search_recipes(
    request: SearchRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Multi-algorithm recipe search.

    Accepts a list of ingredients and optional filters including `algorithm`:
      - "bm25"       → BM25 without stemming
      - "bm25_stem"  → BM25 with Indonesian stemming (default)
      - "tfidf"      → TF-IDF with cosine similarity + stemming

    Returns recipes ranked by the chosen algorithm's score (descending).
    """
    if not bm25_engine.is_ready:
        raise HTTPException(status_code=503, detail="Search engine not ready.")

    ingredients = [ing.strip() for ing in request.ingredients if ing.strip()]
    if not ingredients:
        raise HTTPException(status_code=400, detail="At least one ingredient is required.")

    filters = request.filters.model_dump()
    algorithm = filters.get("algorithm", "bm25_stem")

    # ----- Dispatch to the correct engine -----
    result_items: list[SearchResultItem] = []

    if algorithm == "tfidf":
        if not tfidf_engine.is_ready:
            raise HTTPException(status_code=503, detail="TF-IDF engine not ready.")
        result_items = _tfidf_results(ingredients, request.top_k, filters)

        processing_steps = [
            "Menganalisis bahan-bahan...",
            "Preprocessing teks (case folding, tokenisasi)...",
            "Stemming dengan Sastrawi...",
            "Membangun vektor TF-IDF...",
            "Menghitung cosine similarity...",
            "Mengurutkan resep berdasarkan relevansi...",
            f"Ditemukan {len(result_items)} resep yang relevan! (TF-IDF)",
        ]

    elif algorithm == "bm25":
        # BM25 without stemming
        raw_results = bm25_engine.search(
            ingredients=ingredients,
            top_k=request.top_k,
            filters=filters,
            apply_stemming=False,
        )
        result_items = [_bm25_result_to_item(r) for r in raw_results]

        processing_steps = [
            "Menganalisis bahan-bahan...",
            "Preprocessing teks (case folding, tokenisasi)...",
            "Menghapus stopword Bahasa Indonesia...",
            "Menghitung skor BM25 tanpa stemming (k1=1.2, b=0.75)...",
            "Mengurutkan resep berdasarkan relevansi...",
            f"Ditemukan {len(result_items)} resep yang relevan! (BM25)",
        ]

    else:
        # Default: BM25 with stemming (bm25_stem)
        algorithm = "bm25_stem"
        raw_results = bm25_engine.search(
            ingredients=ingredients,
            top_k=request.top_k,
            filters=filters,
            apply_stemming=True,
        )
        result_items = [_bm25_result_to_item(r) for r in raw_results]

        processing_steps = [
            "Menganalisis bahan-bahan...",
            "Preprocessing teks (case folding, tokenisasi)...",
            "Menghapus stopword Bahasa Indonesia...",
            "Stemming dengan Sastrawi...",
            "Menghitung skor BM25 (k1=1.2, b=0.75)...",
            "Mengurutkan resep berdasarkan relevansi...",
            f"Ditemukan {len(result_items)} resep yang relevan! (BM25+Stemming)",
        ]

    # ----- Log search -----
    top_result_id = result_items[0].recipe_id if result_items else None
    log = SearchLog(
        query=" ".join(ingredients),
        ingredients=json.dumps(ingredients, ensure_ascii=False),
        results_count=len(result_items),
        top_result_id=top_result_id,
        timestamp=datetime.utcnow(),
    )
    db.add(log)
    await db.commit()

    return SearchResponse(
        query=" ".join(ingredients),
        ingredients=ingredients,
        total_found=len(result_items),
        results=result_items,
        processing_steps=processing_steps,
        algorithm_used=algorithm,
    )


@router.get("/suggestions", response_model=SuggestionResponse)
async def get_suggestions(q: str = ""):
    """
    Return autocomplete ingredient suggestions matching query string.
    """
    if not bm25_engine.is_ready:
        return SuggestionResponse(suggestions=[])

    all_ingredients = bm25_engine.get_all_ingredient_names()
    q = q.strip().lower()

    if not q:
        # Return popular ingredients
        popular = [
            "ayam", "bawang merah", "bawang putih", "tempe", "tahu",
            "cabe merah", "tomat", "wortel", "kentang", "udang",
        ]
        return SuggestionResponse(suggestions=popular)

    matches = [
        ing for ing in all_ingredients
        if q in ing.lower()
    ][:15]

    return SuggestionResponse(suggestions=matches)

