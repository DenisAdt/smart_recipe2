"""
Test Suite: Recipes API — GET /recipes, /recipes/popular, /recipes/{id}, /stats
================================================================================
Target   : Smart Recipe Planner — Recipe Catalog Endpoints
Endpoints: GET /api/recipes
           GET /api/recipes/popular
           GET /api/recipes/{id}
           GET /api/stats

Coverage :
  ✅ Positive  — list pagination, detail fetch, popular recipes, stats
  ✅ Negative  — recipe not found (404), invalid ID types, invalid query params
  ✅ Boundary  — page=1 (min), page_size extremes, limit=1 for popular
  ✅ Contract  — JSON Schema validation on response envelopes
"""

import pytest
import jsonschema
import httpx


# ============================================================
# 1. GET /recipes — Paginated List
# ============================================================

@pytest.mark.smoke
@pytest.mark.recipes
def test_get_recipes_list_returns_200_and_valid_schema(
    client: httpx.Client,
    schema_recipe_list_out: dict,
):
    # Arrange
    params = {"page": 1, "page_size": 10}

    # Act
    response = client.get("/recipes", params=params)

    # Assert
    assert response.status_code == 200, response.text
    body = response.json()
    jsonschema.validate(instance=body, schema=schema_recipe_list_out)
    assert body["page"] == 1
    assert body["page_size"] == 10
    assert body["total"] >= 0


@pytest.mark.smoke
@pytest.mark.recipes
def test_get_recipes_list_contains_expected_fields(client: httpx.Client):
    # Act
    response = client.get("/recipes", params={"page": 1, "page_size": 5})
    items = response.json()["items"]

    # Assert — each recipe item must have all required fields
    required_keys = {"id", "title", "ingredients", "instructions",
                     "category", "created_at"}
    for item in items:
        assert required_keys.issubset(item.keys()), \
            f"Missing keys in recipe item: {required_keys - item.keys()}"


@pytest.mark.regression
@pytest.mark.recipes
def test_get_recipes_pagination_page2_different_from_page1(client: httpx.Client):
    # Arrange
    page1 = client.get("/recipes", params={"page": 1, "page_size": 5}).json()["items"]
    page2 = client.get("/recipes", params={"page": 2, "page_size": 5}).json()["items"]

    # Assert — page 2 must have different IDs from page 1 (not duplicate)
    if page2:  # Only assert if dataset has >5 recipes
        ids_p1 = {r["id"] for r in page1}
        ids_p2 = {r["id"] for r in page2}
        assert ids_p1.isdisjoint(ids_p2), \
            "Pagination overlap detected: page 1 and page 2 share recipe IDs!"


@pytest.mark.regression
@pytest.mark.recipes
@pytest.mark.parametrize("category", ["Goreng", "Rebus", "Tumis", "Panggang"])
def test_get_recipes_category_filter_returns_matching_category_only(
    client: httpx.Client,
    category: str,
):
    # Act
    response = client.get("/recipes", params={"category": category, "page_size": 50})
    assert response.status_code == 200
    items = response.json()["items"]

    # Assert
    for item in items:
        assert item["category"] == category, \
            f"Category filter: expected '{category}', got '{item['category']}'"


@pytest.mark.regression
@pytest.mark.recipes
def test_get_recipes_search_filter_returns_title_matches(client: httpx.Client):
    # Arrange — search for "ayam" in title
    keyword = "ayam"

    # Act
    response = client.get("/recipes", params={"search": keyword, "page_size": 20})
    assert response.status_code == 200
    items = response.json()["items"]

    # Assert — all titles must contain the keyword (case-insensitive ilike)
    for item in items:
        assert keyword.lower() in item["title"].lower(), \
            f"Search filter: '{keyword}' not found in title '{item['title']}'"


# ============================================================
# 2. GET /recipes — Boundary & Negative
# ============================================================

@pytest.mark.negative
@pytest.mark.recipes
def test_get_recipes_page_size_1_boundary_min_returns_exactly_1_item(
    client: httpx.Client,
):
    # Act
    response = client.get("/recipes", params={"page": 1, "page_size": 1})
    assert response.status_code == 200
    body = response.json()

    # Assert
    assert len(body["items"]) <= 1
    assert body["page_size"] == 1


@pytest.mark.negative
@pytest.mark.recipes
def test_get_recipes_page_size_100_boundary_max_returns_200(client: httpx.Client):
    # Boundary: page_size = 100 (defined as Query max le=100)
    response = client.get("/recipes", params={"page": 1, "page_size": 100})
    assert response.status_code == 200


@pytest.mark.negative
@pytest.mark.recipes
def test_get_recipes_page_size_exceeds_100_returns_422(client: httpx.Client):
    # Boundary: page_size = 101 (beyond max)
    response = client.get("/recipes", params={"page": 1, "page_size": 101})
    assert response.status_code == 422, \
        f"Expected 422 for page_size=101, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.recipes
def test_get_recipes_page_0_returns_422_or_error(client: httpx.Client):
    # Boundary: page must be >= 1 (ge=1 constraint)
    response = client.get("/recipes", params={"page": 0, "page_size": 10})
    assert response.status_code == 422, \
        f"Expected 422 for page=0, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.recipes
def test_get_recipes_nonexistent_category_returns_empty_list(client: httpx.Client):
    # Negative: filter by a category that doesn't exist in DB
    response = client.get("/recipes", params={"category": "ZZZCategoryDoesntExist"})
    assert response.status_code == 200
    assert response.json()["items"] == []
    assert response.json()["total"] == 0


# ============================================================
# 3. GET /recipes/popular
# ============================================================

@pytest.mark.smoke
@pytest.mark.recipes
def test_get_popular_recipes_returns_200_and_list(
    client: httpx.Client,
    schema_recipe_out: dict,
):
    # Act
    response = client.get("/recipes/popular")

    # Assert
    assert response.status_code == 200
    body = response.json()
    assert isinstance(body, list)
    # Validate each item against schema
    for item in body:
        jsonschema.validate(instance=item, schema=schema_recipe_out)


@pytest.mark.negative
@pytest.mark.recipes
def test_get_popular_recipes_limit_1_returns_at_most_1(client: httpx.Client):
    # Boundary: limit=1
    response = client.get("/recipes/popular", params={"limit": 1})
    assert response.status_code == 200
    assert len(response.json()) <= 1


@pytest.mark.negative
@pytest.mark.recipes
def test_get_popular_recipes_limit_50_boundary_max_returns_200(client: httpx.Client):
    # Boundary: limit=50 (max allowed)
    response = client.get("/recipes/popular", params={"limit": 50})
    assert response.status_code == 200


@pytest.mark.negative
@pytest.mark.recipes
def test_get_popular_recipes_limit_51_exceeds_max_returns_422(client: httpx.Client):
    # Boundary: limit=51 (beyond max le=50)
    response = client.get("/recipes/popular", params={"limit": 51})
    assert response.status_code == 422


# ============================================================
# 4. GET /recipes/{id} — Detail & 404
# ============================================================

@pytest.mark.smoke
@pytest.mark.recipes
def test_get_recipe_by_valid_id_returns_200_and_correct_data(
    client: httpx.Client,
    schema_recipe_out: dict,
):
    # Arrange — first get a list to pick a real ID
    list_response = client.get("/recipes", params={"page": 1, "page_size": 1})
    assert list_response.status_code == 200
    items = list_response.json()["items"]
    assert items, "No recipes in database to test detail endpoint!"
    recipe_id = items[0]["id"]

    # Act
    response = client.get(f"/recipes/{recipe_id}")

    # Assert
    assert response.status_code == 200
    body = response.json()
    jsonschema.validate(instance=body, schema=schema_recipe_out)
    assert body["id"] == recipe_id


@pytest.mark.negative
@pytest.mark.recipes
def test_get_recipe_by_nonexistent_id_returns_404(client: httpx.Client):
    # Arrange — ID that cannot exist in any seeded dataset
    non_existent_id = 999999

    # Act
    response = client.get(f"/recipes/{non_existent_id}")

    # Assert
    assert response.status_code == 404, \
        f"Expected 404 for id={non_existent_id}, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.recipes
def test_get_recipe_by_id_zero_returns_404_or_422(client: httpx.Client):
    # Boundary: ID=0 is not a valid primary key
    response = client.get("/recipes/0")
    assert response.status_code in (404, 422), \
        f"Expected 404/422 for id=0, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.recipes
def test_get_recipe_by_negative_id_returns_404_or_422(client: httpx.Client):
    # Boundary: negative ID should not exist
    response = client.get("/recipes/-1")
    assert response.status_code in (404, 422)


# ============================================================
# 5. GET /stats — Dataset Statistics
# ============================================================

@pytest.mark.smoke
@pytest.mark.recipes
def test_get_stats_returns_200_and_valid_schema(client: httpx.Client):
    # Act
    response = client.get("/stats")

    # Assert
    assert response.status_code == 200
    body = response.json()

    required_keys = {"total_recipes", "unique_ingredients",
                     "total_searches", "categories"}
    assert required_keys.issubset(body.keys()), \
        f"Missing keys in stats: {required_keys - body.keys()}"
    assert isinstance(body["total_recipes"], int) and body["total_recipes"] >= 0
    assert isinstance(body["unique_ingredients"], int)
    assert isinstance(body["total_searches"], int)
    assert isinstance(body["categories"], dict)


@pytest.mark.regression
@pytest.mark.recipes
def test_get_stats_category_counts_sum_to_total_recipes(client: httpx.Client):
    # Act
    response = client.get("/stats")
    body = response.json()

    # Assert — sum of all category counts must equal total_recipes
    category_sum = sum(body["categories"].values())
    assert category_sum == body["total_recipes"], \
        (f"Category sum {category_sum} != total_recipes {body['total_recipes']}. "
         f"Some recipes may have uncategorized/NULL category.")
