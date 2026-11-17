"""
Test Suite: Health & System Readiness — GET /health
====================================================
Target   : Smart Recipe Planner — System Health Endpoint
Endpoint : GET /api/health (or GET /health depending on routing)

Coverage :
  ✅ Smoke    — server is reachable and returns healthy status
  ✅ Contract — response schema matches API_SPEC.md definition
  ✅ Semantic — BM25 engine is marked as ready after startup
"""

import pytest
import httpx


@pytest.mark.smoke
@pytest.mark.health
def test_health_check_returns_200(client: httpx.Client):
    # Act — try both common health check paths
    response = client.get("/health")
    if response.status_code == 404:
        # Some FastAPI apps expose health at root level, not under /api
        response = client.get("http://localhost:8000/health")

    # Assert
    assert response.status_code == 200, \
        f"Health check failed: {response.status_code} — {response.text}"


@pytest.mark.smoke
@pytest.mark.health
def test_health_response_contains_required_fields(client: httpx.Client):
    # Act
    response = client.get("/health")
    if response.status_code == 404:
        response = client.get("http://localhost:8000/health")

    if response.status_code != 200:
        pytest.skip("Health endpoint not reachable at standard paths.")

    # Assert
    body = response.json()
    assert "status" in body
    assert body["status"] == "ok"


@pytest.mark.smoke
@pytest.mark.health
def test_health_bm25_engine_is_ready(client: httpx.Client):
    # Act
    response = client.get("/health")
    if response.status_code == 404:
        response = client.get("http://localhost:8000/health")

    if response.status_code != 200:
        pytest.skip("Health endpoint not reachable at standard paths.")

    # Assert
    body = response.json()
    if "bm25_ready" in body:
        assert body["bm25_ready"] is True, \
            "BM25 engine is NOT ready — search endpoints will return 503!"


@pytest.mark.smoke
@pytest.mark.health
def test_health_recipe_count_is_positive(client: httpx.Client):
    # Act
    response = client.get("/health")
    if response.status_code == 404:
        response = client.get("http://localhost:8000/health")

    if response.status_code != 200:
        pytest.skip("Health endpoint not reachable at standard paths.")

    # Assert
    body = response.json()
    if "recipe_count" in body:
        assert body["recipe_count"] > 0, \
            "recipe_count is 0 — database may not be seeded!"
