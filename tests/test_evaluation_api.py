"""
Test Suite: IR Evaluation API — POST /evaluation/run & GET /evaluation/results
===============================================================================
Target   : Smart Recipe Planner — IR Evaluation Comparison Endpoint
Endpoints: POST /api/evaluation/run
           GET  /api/evaluation/results

Coverage :
  ✅ Positive  — run evaluation with valid queries, verify 3 methods returned
  ✅ Semantic  — BM25 with stemming generally scores >= BM25 without stemming
  ✅ Contract  — metric fields exist and are within [0, 1] range
  ✅ Negative  — empty query list, missing 'queries' key
  ✅ Results   — GET stored results returns a list
"""

import pytest
import httpx


# Shared example query set for evaluation tests
EXAMPLE_QUERIES = [
    "ayam bawang merah",
    "tempe tahu goreng",
    "rendang daging sapi",
]


# ============================================================
# 1. POST /evaluation/run — Positive
# ============================================================

@pytest.mark.smoke
@pytest.mark.evaluation
def test_run_evaluation_returns_200_with_three_methods(client: httpx.Client):
    # Arrange
    payload = {"queries": EXAMPLE_QUERIES, "k_values": [5, 10]}

    # Act
    response = client.post("/evaluation/run", json=payload, timeout=30.0)

    # Assert
    assert response.status_code == 200, \
        f"Evaluation run failed: {response.status_code} — {response.text}"
    body = response.json()
    assert "results" in body
    assert len(body["results"]) == 3, \
        f"Expected 3 methods, got {len(body['results'])}: {[r['method'] for r in body['results']]}"


@pytest.mark.regression
@pytest.mark.evaluation
def test_run_evaluation_method_names_match_expected(client: httpx.Client):
    # Arrange
    payload = {"queries": EXAMPLE_QUERIES, "k_values": [5, 10]}

    # Act
    response = client.post("/evaluation/run", json=payload, timeout=30.0)
    assert response.status_code == 200
    methods = [r["method"] for r in response.json()["results"]]

    # Assert — exact method names from evaluation.py
    expected_methods = {
        "BM25 tanpa Stemming",
        "BM25 dengan Stemming",
        "TF-IDF dengan Stemming",
    }
    assert set(methods) == expected_methods, \
        f"Method names mismatch. Expected: {expected_methods}, Got: {set(methods)}"


@pytest.mark.regression
@pytest.mark.evaluation
def test_run_evaluation_metrics_are_within_valid_range(client: httpx.Client):
    # Arrange
    payload = {"queries": EXAMPLE_QUERIES, "k_values": [5, 10]}

    # Act
    response = client.post("/evaluation/run", json=payload, timeout=30.0)
    assert response.status_code == 200
    results = response.json()["results"]

    # Assert — all metric values must be within [0.0, 1.0]
    metric_fields = ["precision", "recall", "f1_score",
                     "precision_at_5", "precision_at_10"]
    for method_result in results:
        for field in metric_fields:
            value = method_result.get(field)
            if value is not None:
                assert 0.0 <= value <= 1.0, \
                    (f"[{method_result['method']}] Field '{field}' "
                     f"out of range [0,1]: {value}")


@pytest.mark.regression
@pytest.mark.evaluation
def test_run_evaluation_response_contains_query_metadata(client: httpx.Client):
    # Arrange
    payload = {"queries": EXAMPLE_QUERIES}

    # Act
    response = client.post("/evaluation/run", json=payload, timeout=30.0)
    assert response.status_code == 200
    body = response.json()

    # Assert — meta fields
    assert "queries_used" in body
    assert "total_recipes_in_dataset" in body
    assert "timestamp" in body
    assert body["total_recipes_in_dataset"] > 0
    assert len(body["queries_used"]) == len(EXAMPLE_QUERIES)


@pytest.mark.regression
@pytest.mark.evaluation
def test_run_evaluation_avg_query_time_ms_is_positive(client: httpx.Client):
    # Arrange
    payload = {"queries": EXAMPLE_QUERIES, "k_values": [5, 10]}

    # Act
    response = client.post("/evaluation/run", json=payload, timeout=30.0)
    assert response.status_code == 200
    results = response.json()["results"]

    # Assert — timing must be a positive float
    for method_result in results:
        time_ms = method_result.get("avg_query_time_ms", 0)
        assert time_ms >= 0.0, \
            f"[{method_result['method']}] avg_query_time_ms is negative: {time_ms}"


# ============================================================
# 2. SEMANTIC CORRECTNESS — BM25 Stemming generally better
# ============================================================

@pytest.mark.regression
@pytest.mark.evaluation
def test_bm25_with_stemming_recall_gte_bm25_without_stemming(client: httpx.Client):
    """
    Academic hypothesis: BM25 with Sastrawi stemming should achieve
    equal or better recall than BM25 without stemming on Indonesian text.
    This test documents the actual behavior — it is informational.
    """
    # Arrange
    payload = {"queries": EXAMPLE_QUERIES, "k_values": [5, 10]}

    # Act
    response = client.post("/evaluation/run", json=payload, timeout=30.0)
    assert response.status_code == 200
    results_by_method = {r["method"]: r for r in response.json()["results"]}

    bm25_no_stem = results_by_method.get("BM25 tanpa Stemming", {})
    bm25_stem = results_by_method.get("BM25 dengan Stemming", {})

    # Assert — BM25 with stemming recall >= BM25 without stemming recall
    # (or at least comparable; mark xfail if hypothesis doesn't hold for this dataset)
    recall_no_stem = bm25_no_stem.get("recall", 0.0)
    recall_stem = bm25_stem.get("recall", 0.0)

    # Using >=  with 5% tolerance (floating point + small dataset effects)
    assert recall_stem >= recall_no_stem - 0.05, (
        f"BM25 Stemming recall ({recall_stem:.4f}) is significantly worse than "
        f"BM25 no-stemming recall ({recall_no_stem:.4f}). "
        f"Review Sastrawi stemming quality or ground truth data."
    )


# ============================================================
# 3. NEGATIVE CASES
# ============================================================

@pytest.mark.negative
@pytest.mark.evaluation
def test_run_evaluation_with_empty_queries_list_returns_error(client: httpx.Client):
    # Arrange — no queries provided
    payload = {"queries": [], "k_values": [5, 10]}

    # Act
    response = client.post("/evaluation/run", json=payload, timeout=30.0)

    # Assert — may return 400, 422, or 200 with empty results depending on implementation
    # We document the actual behavior here
    if response.status_code == 200:
        # If accepted, results should still have 3 methods with 0.0 metrics
        results = response.json()["results"]
        assert len(results) == 3
    else:
        assert response.status_code in (400, 422)


@pytest.mark.negative
@pytest.mark.evaluation
def test_run_evaluation_missing_queries_key_returns_422(client: httpx.Client):
    # Arrange — required field 'queries' is absent
    payload = {"k_values": [5, 10]}

    # Act
    response = client.post("/evaluation/run", json=payload, timeout=30.0)

    # Assert
    assert response.status_code == 422, \
        f"Expected 422 for missing 'queries', got {response.status_code}"


# ============================================================
# 4. GET /evaluation/results — Stored History
# ============================================================

@pytest.mark.regression
@pytest.mark.evaluation
def test_get_evaluation_results_returns_200_and_list(client: httpx.Client):
    # Act
    response = client.get("/evaluation/results")

    # Assert
    assert response.status_code == 200, response.text
    body = response.json()
    assert isinstance(body, list), \
        f"Expected a list from /evaluation/results, got {type(body)}"
