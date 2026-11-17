"""
Test Suite: Search API — POST /search & GET /search/suggestions
================================================================
Target   : Smart Recipe Planner — BM25 / TF-IDF Search Engine
Endpoint : POST /api/search   |  GET /api/search/suggestions

Coverage :
  ✅ Positive  — valid ingredients, all 3 algorithms, with filters
  ✅ Negative  — empty list, whitespace-only, missing 'ingredients' key
  ✅ Boundary  — single ingredient, max top_k (100), excessive top_k (101)
  ✅ Contract  — JSON Schema validation on every successful response field

Locator Strategy: JSON payload keys match Pydantic SearchRequest schema
exactly. No magic strings beyond schema-defined field names.
"""

import pytest
import jsonschema
import httpx


# ============================================================
# 1. SMOKE — basic happy-path, confirms engine is live
# ============================================================

@pytest.mark.smoke
@pytest.mark.search
def test_search_bm25_stem_returns_200_and_valid_schema(
    client: httpx.Client,
    valid_search_payload: dict,
    schema_search_response: dict,
):
    # Arrange — default algorithm is bm25_stem (explicitly set for clarity)
    payload = valid_search_payload  # {"ingredients": ["ayam", ...], "top_k": 10}

    # Act
    response = client.post("/search", json=payload)

    # Assert — status, schema, semantics
    assert response.status_code == 200, response.text
    body = response.json()
    jsonschema.validate(instance=body, schema=schema_search_response)
    assert body["algorithm_used"] == "bm25_stem"
    assert body["total_found"] >= 0
    assert isinstance(body["results"], list)
    assert isinstance(body["processing_steps"], list)
    assert len(body["processing_steps"]) > 0


@pytest.mark.smoke
@pytest.mark.search
def test_search_returns_results_ranked_by_score_descending(
    client: httpx.Client,
    valid_search_payload: dict,
):
    # Arrange
    payload = {**valid_search_payload, "top_k": 20}

    # Act
    response = client.post("/search", json=payload)
    results = response.json()["results"]

    # Assert — ranked list must be monotonically non-increasing in score
    scores = [r["bm25_score"] for r in results]
    assert scores == sorted(scores, reverse=True), \
        "Results are NOT sorted by bm25_score descending!"


@pytest.mark.smoke
@pytest.mark.search
def test_search_result_rank_field_is_sequential(
    client: httpx.Client,
    valid_search_payload: dict,
):
    # Act
    response = client.post("/search", json=valid_search_payload)
    results = response.json()["results"]

    # Assert — rank must start at 1 and be contiguous
    ranks = [r["rank"] for r in results]
    assert ranks == list(range(1, len(results) + 1)), \
        f"Rank sequence broken: {ranks}"


# ============================================================
# 2. ALGORITHM SELECTION — bm25, bm25_stem, tfidf
# ============================================================

@pytest.mark.regression
@pytest.mark.search
@pytest.mark.parametrize("algorithm", ["bm25", "bm25_stem", "tfidf"])
def test_search_all_three_algorithms_return_200(
    client: httpx.Client,
    algorithm: str,
    schema_search_response: dict,
):
    # Arrange
    payload = {
        "ingredients": ["tempe", "tahu", "bawang putih"],
        "filters": {"algorithm": algorithm},
        "top_k": 10,
    }

    # Act
    response = client.post("/search", json=payload)

    # Assert
    assert response.status_code == 200, \
        f"Algorithm '{algorithm}' returned {response.status_code}: {response.text}"
    body = response.json()
    jsonschema.validate(instance=body, schema=schema_search_response)
    assert body["algorithm_used"] == algorithm


# ============================================================
# 3. FILTER VALIDATION
# ============================================================

@pytest.mark.regression
@pytest.mark.search
@pytest.mark.parametrize("category", ["Goreng", "Rebus", "Tumis", "Panggang"])
def test_search_category_filter_only_returns_matching_category(
    client: httpx.Client,
    category: str,
):
    # Arrange
    payload = {
        "ingredients": ["ayam"],
        "filters": {"algorithm": "bm25_stem", "category": category},
        "top_k": 20,
    }

    # Act
    response = client.post("/search", json=payload)
    assert response.status_code == 200
    results = response.json()["results"]

    # Assert — every returned recipe must match the filtered category
    for item in results:
        assert item["category"] == category, \
            f"Category filter broken: got '{item['category']}' expected '{category}'"


@pytest.mark.regression
@pytest.mark.search
def test_search_max_cooking_time_filter_respects_limit(client: httpx.Client):
    # Arrange — only recipes ≤ 20 minutes
    payload = {
        "ingredients": ["ayam"],
        "filters": {"algorithm": "bm25_stem", "max_cooking_time": 20},
        "top_k": 20,
    }

    # Act
    response = client.post("/search", json=payload)
    assert response.status_code == 200
    results = response.json()["results"]

    # Assert
    for item in results:
        if item["cooking_time"] is not None:
            assert item["cooking_time"] <= 20, \
                f"cooking_time {item['cooking_time']} exceeded filter limit 20"


@pytest.mark.regression
@pytest.mark.search
@pytest.mark.parametrize("difficulty", ["Easy", "Medium", "Hard"])
def test_search_difficulty_filter_only_returns_matching_difficulty(
    client: httpx.Client,
    difficulty: str,
):
    # Arrange
    payload = {
        "ingredients": ["ayam"],
        "filters": {"algorithm": "bm25_stem", "difficulty": difficulty},
        "top_k": 20,
    }

    # Act
    response = client.post("/search", json=payload)
    assert response.status_code == 200
    results = response.json()["results"]

    # Assert
    for item in results:
        if item["difficulty"] is not None:
            assert item["difficulty"] == difficulty, \
                f"Difficulty filter broken: got '{item['difficulty']}'"


# ============================================================
# 4. MATCH PERCENTAGE & INGREDIENT FIELD INTEGRITY
# ============================================================

@pytest.mark.regression
@pytest.mark.search
def test_search_match_percentage_within_valid_range(
    client: httpx.Client,
    valid_search_payload: dict,
):
    # Act
    response = client.post("/search", json=valid_search_payload)
    results = response.json()["results"]

    # Assert — match_percentage must be [0, 100]
    for item in results:
        assert 0.0 <= item["match_percentage"] <= 100.0, \
            f"match_percentage out of range: {item['match_percentage']}"


@pytest.mark.regression
@pytest.mark.search
def test_search_matched_plus_missing_equals_total_query(
    client: httpx.Client,
):
    # Arrange — 3 ingredients so total_query_count must be 3
    payload = {
        "ingredients": ["ayam", "bawang merah", "cabe"],
        "filters": {"algorithm": "bm25_stem"},
        "top_k": 10,
    }

    # Act
    response = client.post("/search", json=payload)
    results = response.json()["results"]

    # Assert — data integrity: matched + missing == total query ingredients
    for item in results:
        assert item["matched_count"] + len(item["missing_ingredients"]) \
               == item["total_query_count"], \
            f"matched + missing != total_query_count in item: {item['title']}"


# ============================================================
# 5. BOUNDARY VALUE ANALYSIS
# ============================================================

@pytest.mark.negative
@pytest.mark.search
def test_search_with_single_ingredient_returns_200(client: httpx.Client):
    # Arrange — boundary: minimum valid list length = 1
    payload = {
        "ingredients": ["ayam"],
        "filters": {"algorithm": "bm25_stem"},
        "top_k": 5,
    }

    # Act
    response = client.post("/search", json=payload)

    # Assert
    assert response.status_code == 200
    assert isinstance(response.json()["results"], list)


@pytest.mark.negative
@pytest.mark.search
def test_search_top_k_boundary_max_100_returns_200(client: httpx.Client):
    # Arrange — boundary: max allowed top_k = 100 (from SearchRequest schema)
    payload = {
        "ingredients": ["ayam"],
        "filters": {"algorithm": "bm25_stem"},
        "top_k": 100,
    }

    # Act
    response = client.post("/search", json=payload)

    # Assert
    assert response.status_code == 200


@pytest.mark.negative
@pytest.mark.search
def test_search_top_k_exceeds_max_101_returns_422(client: httpx.Client):
    # Arrange — boundary: top_k = 101, beyond schema's max of 100
    payload = {
        "ingredients": ["ayam"],
        "filters": {},
        "top_k": 101,
    }

    # Act
    response = client.post("/search", json=payload)

    # Assert — FastAPI/Pydantic must reject with HTTP 422 Unprocessable Entity
    assert response.status_code == 422, \
        f"Expected 422 for top_k=101, got {response.status_code}"


# ============================================================
# 6. NEGATIVE / ERROR CASES
# ============================================================

@pytest.mark.negative
@pytest.mark.search
def test_search_with_empty_ingredients_list_returns_400(client: httpx.Client):
    # Arrange — ingredients list is empty (violates min_length=1 constraint)
    payload = {
        "ingredients": [],
        "filters": {"algorithm": "bm25_stem"},
        "top_k": 10,
    }

    # Act
    response = client.post("/search", json=payload)

    # Assert — 400 from app logic or 422 from Pydantic min_length validation
    assert response.status_code in (400, 422), \
        f"Expected 400 or 422 for empty ingredients, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.search
def test_search_with_whitespace_only_ingredients_returns_400(client: httpx.Client):
    # Arrange — ingredients are blank strings after strip()
    payload = {
        "ingredients": ["   ", "  "],
        "filters": {"algorithm": "bm25_stem"},
        "top_k": 10,
    }

    # Act
    response = client.post("/search", json=payload)

    # Assert
    assert response.status_code in (400, 422), \
        f"Expected 400 or 422 for whitespace-only ingredients, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.search
def test_search_missing_ingredients_key_returns_422(client: httpx.Client):
    # Arrange — required field 'ingredients' is absent
    payload = {"top_k": 10}

    # Act
    response = client.post("/search", json=payload)

    # Assert — Pydantic validation error must produce 422
    assert response.status_code == 422


@pytest.mark.negative
@pytest.mark.search
def test_search_with_invalid_algorithm_uses_default_or_returns_error(client: httpx.Client):
    # Arrange — algorithm value not in enum
    payload = {
        "ingredients": ["ayam"],
        "filters": {"algorithm": "magic_algo_xyz"},
        "top_k": 5,
    }

    # Act
    response = client.post("/search", json=payload)

    # Assert — API may fall back to default or return 422; both are acceptable
    # Document which behavior the application actually exhibits
    assert response.status_code in (200, 400, 422), \
        f"Unexpected status for invalid algorithm: {response.status_code}"


# ============================================================
# 7. SUGGESTIONS ENDPOINT
# ============================================================

@pytest.mark.smoke
@pytest.mark.search
def test_get_suggestions_without_query_returns_popular_list(client: httpx.Client):
    # Act — no query param → returns popular ingredients list
    response = client.get("/search/suggestions")

    # Assert
    assert response.status_code == 200
    body = response.json()
    assert "suggestions" in body
    assert isinstance(body["suggestions"], list)
    # Expect at least a few suggestions (popular defaults exist)
    assert len(body["suggestions"]) > 0


@pytest.mark.regression
@pytest.mark.search
def test_get_suggestions_with_valid_query_returns_matching_items(client: httpx.Client):
    # Arrange — search for "bawang" prefix
    q = "bawang"

    # Act
    response = client.get("/search/suggestions", params={"q": q})

    # Assert
    assert response.status_code == 200
    suggestions = response.json()["suggestions"]
    # Every returned suggestion must contain the query prefix
    for suggestion in suggestions:
        assert q.lower() in suggestion.lower(), \
            f"Suggestion '{suggestion}' does not contain query '{q}'"


@pytest.mark.negative
@pytest.mark.search
def test_get_suggestions_with_nonexistent_ingredient_returns_empty_list(client: httpx.Client):
    # Arrange — query that cannot match any ingredient
    q = "zzz_ingredient_doesnt_exist_xyz"

    # Act
    response = client.get("/search/suggestions", params={"q": q})

    # Assert
    assert response.status_code == 200
    assert response.json()["suggestions"] == []
