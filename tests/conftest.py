"""
Smart Recipe Planner — Global Test Fixtures & Configuration
============================================================
Provides shared fixtures: HTTP client, base URL, reusable payloads, and
JSON Schema contracts for all test modules.

RULE: No hardcoded credentials or time.sleep(). All env vars via .env.test.
"""
import pytest
import httpx
import os
from pathlib import Path
from dotenv import load_dotenv

# Load project-specific test env file if present, else use defaults
_ENV_FILE = Path(__file__).resolve().parent / ".env.test"
if _ENV_FILE.exists():
    load_dotenv(dotenv_path=_ENV_FILE)

BASE_URL = os.getenv("SRP_BASE_URL", "http://localhost:8000/api")
REQUEST_TIMEOUT = int(os.getenv("SRP_TIMEOUT", "15"))


# ---------------------------------------------------------------------------
# Session-scoped HTTP client
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def base_url() -> str:
    """Single source of truth for the backend API base URL."""
    return BASE_URL


@pytest.fixture(scope="session")
def client(base_url: str) -> httpx.Client:
    """
    Shared synchronous HTTP client for the entire test session.
    httpx.Client handles connection pooling and automatic retries.
    """
    with httpx.Client(base_url=base_url, timeout=REQUEST_TIMEOUT) as c:
        yield c


# ---------------------------------------------------------------------------
# Common payload factories
# ---------------------------------------------------------------------------
@pytest.fixture
def valid_search_payload() -> dict:
    """Standard search request payload with common Indonesian ingredients."""
    return {
        "ingredients": ["ayam", "bawang merah", "bawang putih"],
        "filters": {"algorithm": "bm25_stem"},
        "top_k": 10,
    }


@pytest.fixture
def valid_recipe_payload() -> dict:
    """Minimal valid recipe payload for create/update operations."""
    return {
        "title": "Ayam Goreng QA Test",
        "ingredients": "500 gram ayam, 3 siung bawang putih, 2 sdm kecap manis",
        "instructions": "1. Cuci ayam. 2. Marinasi. 3. Goreng hingga matang.",
        "category": "Goreng",
        "cooking_time": 30,
        "difficulty": "Easy",
    }


# ---------------------------------------------------------------------------
# JSON Schema Contracts (source of truth for response structure validation)
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def schema_search_result_item() -> dict:
    return {
        "type": "object",
        "required": [
            "recipe_id", "title", "category", "bm25_score",
            "match_percentage", "matched_ingredients", "missing_ingredients",
            "matched_count", "total_query_count", "rank",
            "relevance_stars", "relevance_label",
        ],
        "properties": {
            "recipe_id":           {"type": "integer"},
            "title":               {"type": "string"},
            "category":            {"type": "string"},
            "image_url":           {"type": ["string", "null"]},
            "cooking_time":        {"type": ["integer", "null"]},
            "difficulty":          {"type": ["string", "null"]},
            "bm25_score":          {"type": "number"},
            "match_percentage":    {"type": "number", "minimum": 0, "maximum": 100},
            "matched_ingredients": {"type": "array", "items": {"type": "string"}},
            "missing_ingredients": {"type": "array", "items": {"type": "string"}},
            "matched_count":       {"type": "integer", "minimum": 0},
            "total_query_count":   {"type": "integer", "minimum": 1},
            "rank":                {"type": "integer", "minimum": 1},
            "relevance_stars":     {"type": "integer", "minimum": 1, "maximum": 5},
            "relevance_label":     {"type": "string", "enum": [
                "Highly Relevant", "Relevant", "Moderate", "Partial", "Low"
            ]},
        },
    }


@pytest.fixture(scope="session")
def schema_search_response(schema_search_result_item) -> dict:
    return {
        "type": "object",
        "required": ["query", "ingredients", "total_found", "results",
                     "processing_steps", "algorithm_used"],
        "properties": {
            "query":            {"type": "string"},
            "ingredients":      {"type": "array", "items": {"type": "string"}},
            "total_found":      {"type": "integer", "minimum": 0},
            "results":          {"type": "array", "items": schema_search_result_item},
            "processing_steps": {"type": "array", "items": {"type": "string"}},
            "algorithm_used":   {"type": "string"},
        },
    }


@pytest.fixture(scope="session")
def schema_recipe_out() -> dict:
    return {
        "type": "object",
        "required": ["id", "title", "ingredients", "instructions",
                     "category", "created_at"],
        "properties": {
            "id":           {"type": "integer"},
            "title":        {"type": "string"},
            "ingredients":  {"type": "string"},
            "instructions": {"type": "string"},
            "category":     {"type": "string"},
            "image_url":    {"type": ["string", "null"]},
            "cooking_time": {"type": ["integer", "null"]},
            "difficulty":   {"type": ["string", "null"]},
            "created_at":   {"type": "string"},
        },
    }


@pytest.fixture(scope="session")
def schema_recipe_list_out(schema_recipe_out) -> dict:
    return {
        "type": "object",
        "required": ["items", "total", "page", "page_size"],
        "properties": {
            "items":     {"type": "array", "items": schema_recipe_out},
            "total":     {"type": "integer", "minimum": 0},
            "page":      {"type": "integer", "minimum": 1},
            "page_size": {"type": "integer", "minimum": 1},
        },
    }
