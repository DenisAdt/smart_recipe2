"""Pydantic schemas for Search API."""

from typing import Optional
from pydantic import BaseModel, Field


class SearchFilters(BaseModel):
    category: Optional[str] = None          # Goreng|Rebus|Tumis|Panggang
    max_cooking_time: Optional[int] = None  # minutes
    difficulty: Optional[str] = None        # Easy|Medium|Hard
    algorithm: str = "bm25_stem"            # bm25 | bm25_stem | tfidf


class SearchRequest(BaseModel):
    ingredients: list[str] = Field(..., min_length=1, max_length=20)
    filters: SearchFilters = SearchFilters()
    top_k: int = Field(default=20, ge=1, le=100)


class IngredientMatch(BaseModel):
    name: str
    matched: bool


class SearchResultItem(BaseModel):
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
    relevance_stars: int        # 1–5
    relevance_label: str        # Highly Relevant | Relevant | Moderate | Partial | Low


class SearchResponse(BaseModel):
    query: str
    ingredients: list[str]
    total_found: int
    results: list[SearchResultItem]
    processing_steps: list[str]
    algorithm_used: str = "bm25_stem"   # which engine produced these results


class SuggestionResponse(BaseModel):
    suggestions: list[str]

