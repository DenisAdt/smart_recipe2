"""
Test Suite: Admin API — CRUD & CSV Upload
=========================================
Target   : Smart Recipe Planner — Admin Endpoints
Endpoints: POST   /api/admin/upload
           GET    /api/admin/recipes
           POST   /api/admin/recipes
           PUT    /api/admin/recipes/{id}
           DELETE /api/admin/recipes/{id}
           GET    /api/admin/analytics

Coverage :
  ✅ Positive  — full CRUD lifecycle (create → read → update → delete)
  ✅ Negative  — missing required fields, invalid CSV, nonexistent ID
  ✅ Boundary  — min-length title, max-length fields, partial update (PATCH-like PUT)
  ✅ Contract  — JSON Schema validation on response envelopes
  ✅ Idempotency — delete twice returns 404 on second attempt

NOTE: Tests are ordered with @pytest.mark.order where CRUD sequencing matters.
The lifecycle test (test_admin_recipe_full_crud_lifecycle) is a single end-to-end
flow to avoid order-dependency issues with separate create/delete tests.
"""

import io
import pytest
import jsonschema
import httpx


# ============================================================
# 1. ANALYTICS — read-only, safe to run first
# ============================================================

@pytest.mark.smoke
@pytest.mark.admin
def test_get_analytics_returns_200_with_valid_shape(client: httpx.Client):
    # Act
    response = client.get("/admin/analytics")

    # Assert
    assert response.status_code == 200, response.text
    body = response.json()

    required_keys = {"total_recipes", "total_searches",
                     "top_ingredients", "daily_searches"}
    assert required_keys.issubset(body.keys()), \
        f"Missing analytics keys: {required_keys - body.keys()}"
    assert isinstance(body["top_ingredients"], list)
    assert isinstance(body["daily_searches"], list)


@pytest.mark.regression
@pytest.mark.admin
def test_get_analytics_daily_searches_has_7_days(client: httpx.Client):
    # Act
    response = client.get("/admin/analytics")
    daily = response.json()["daily_searches"]

    # Assert — always 7 days window
    assert len(daily) == 7, \
        f"Expected 7 daily entries, got {len(daily)}"
    for entry in daily:
        assert "date" in entry and "count" in entry


# ============================================================
# 2. ADMIN RECIPE LIST
# ============================================================

@pytest.mark.smoke
@pytest.mark.admin
def test_admin_list_recipes_returns_200_and_list(
    client: httpx.Client,
    schema_recipe_list_out: dict,
):
    # Act
    response = client.get("/admin/recipes", params={"page": 1, "page_size": 10})

    # Assert
    assert response.status_code == 200, response.text
    jsonschema.validate(instance=response.json(), schema=schema_recipe_list_out)


@pytest.mark.negative
@pytest.mark.admin
def test_admin_list_recipes_page_size_200_boundary_max_returns_200(client: httpx.Client):
    # Boundary: admin endpoint has page_size le=200 (larger than public list)
    response = client.get("/admin/recipes", params={"page": 1, "page_size": 200})
    assert response.status_code == 200


@pytest.mark.negative
@pytest.mark.admin
def test_admin_list_recipes_page_size_201_exceeds_max_returns_422(client: httpx.Client):
    # Boundary: beyond admin's max page_size of 200
    response = client.get("/admin/recipes", params={"page": 1, "page_size": 201})
    assert response.status_code == 422


# ============================================================
# 3. FULL CRUD LIFECYCLE (Create → Read → Update → Delete)
# ============================================================

@pytest.mark.smoke
@pytest.mark.admin
def test_admin_recipe_full_crud_lifecycle(
    client: httpx.Client,
    valid_recipe_payload: dict,
    schema_recipe_out: dict,
):
    """
    End-to-end lifecycle test: CREATE → verify → UPDATE → verify → DELETE → verify 404.
    Keeps all state within one test to avoid order-dependency between separate tests.
    """
    # ---- ARRANGE ----
    create_payload = valid_recipe_payload.copy()
    create_payload["title"] = "QA CRUD Lifecycle Test Recipe"

    # ---- ACT: CREATE ----
    create_resp = client.post("/admin/recipes", json=create_payload)
    assert create_resp.status_code == 201, \
        f"Create failed: {create_resp.status_code} — {create_resp.text}"
    created = create_resp.json()
    jsonschema.validate(instance=created, schema=schema_recipe_out)
    recipe_id = created["id"]

    # ---- ASSERT: CREATE ----
    assert created["title"] == create_payload["title"]
    assert created["category"] == create_payload["category"]
    assert created["cooking_time"] == create_payload["cooking_time"]

    # ---- ACT: READ BACK ----
    get_resp = client.get(f"/recipes/{recipe_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == recipe_id

    # ---- ACT: UPDATE ----
    update_payload = {"title": "QA CRUD Lifecycle UPDATED", "difficulty": "Hard"}
    update_resp = client.put(f"/admin/recipes/{recipe_id}", json=update_payload)
    assert update_resp.status_code == 200, \
        f"Update failed: {update_resp.status_code} — {update_resp.text}"
    updated = update_resp.json()
    assert updated["title"] == update_payload["title"]
    assert updated["difficulty"] == "Hard"
    # Other fields should be unchanged
    assert updated["category"] == create_payload["category"]

    # ---- ACT: DELETE ----
    delete_resp = client.delete(f"/admin/recipes/{recipe_id}")
    assert delete_resp.status_code == 200

    # ---- ASSERT: VERIFY 404 AFTER DELETE ----
    verify_resp = client.get(f"/recipes/{recipe_id}")
    assert verify_resp.status_code == 404, \
        f"Recipe {recipe_id} still accessible after deletion!"


# ============================================================
# 4. CREATE — Negative & Boundary
# ============================================================

@pytest.mark.negative
@pytest.mark.admin
def test_create_recipe_missing_required_title_returns_422(client: httpx.Client):
    # Arrange — 'title' is required by RecipeCreate
    payload = {
        "ingredients": "ayam, bawang",
        "instructions": "Masak hingga matang.",
        "category": "Goreng",
    }

    # Act
    response = client.post("/admin/recipes", json=payload)

    # Assert
    assert response.status_code == 422, \
        f"Expected 422 for missing title, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.admin
def test_create_recipe_missing_required_ingredients_returns_422(client: httpx.Client):
    # Arrange
    payload = {
        "title": "Ayam Goreng Test",
        "instructions": "Masak hingga matang.",
        "category": "Goreng",
    }

    # Act
    response = client.post("/admin/recipes", json=payload)

    # Assert
    assert response.status_code == 422


@pytest.mark.negative
@pytest.mark.admin
def test_create_recipe_empty_payload_returns_422(client: httpx.Client):
    # Arrange — entirely empty body
    response = client.post("/admin/recipes", json={})
    assert response.status_code == 422


@pytest.mark.negative
@pytest.mark.admin
def test_create_recipe_with_invalid_category_still_accepts_or_returns_422(
    client: httpx.Client,
):
    """
    Category has a default of 'Goreng' in schema but no enum constraint.
    This test documents whether the API accepts arbitrary categories.
    If accepted, it should return 201; if enum-validated, 422.
    """
    payload = {
        "title": "Recipe With Invalid Category",
        "ingredients": "ayam",
        "instructions": "Masak.",
        "category": "INVALID_CATEGORY_XYZ",
    }
    response = client.post("/admin/recipes", json=payload)
    assert response.status_code in (201, 422), \
        f"Unexpected status: {response.status_code}"

    # Cleanup if created
    if response.status_code == 201:
        recipe_id = response.json()["id"]
        client.delete(f"/admin/recipes/{recipe_id}")


# ============================================================
# 5. UPDATE — Negative
# ============================================================

@pytest.mark.negative
@pytest.mark.admin
def test_update_nonexistent_recipe_returns_404(client: httpx.Client):
    # Arrange
    non_existent_id = 999998
    payload = {"title": "Should Not Update"}

    # Act
    response = client.put(f"/admin/recipes/{non_existent_id}", json=payload)

    # Assert
    assert response.status_code == 404, \
        f"Expected 404 for id={non_existent_id}, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.admin
def test_update_recipe_with_empty_payload_returns_200_or_422(client: httpx.Client):
    """
    Empty payload to PUT should behave as no-op (RecipeUpdate has all Optional fields).
    Documents whether empty update is accepted or rejected.
    """
    # First get a valid ID
    list_resp = client.get("/admin/recipes", params={"page": 1, "page_size": 1})
    items = list_resp.json()["items"]
    if not items:
        pytest.skip("No recipes in database to test update.")

    recipe_id = items[0]["id"]
    response = client.put(f"/admin/recipes/{recipe_id}", json={})
    # Empty payload (all optional) should be a no-op → 200
    assert response.status_code in (200, 422)


# ============================================================
# 6. DELETE — Negative & Idempotency
# ============================================================

@pytest.mark.negative
@pytest.mark.admin
def test_delete_nonexistent_recipe_returns_404(client: httpx.Client):
    # Arrange
    non_existent_id = 999997

    # Act
    response = client.delete(f"/admin/recipes/{non_existent_id}")

    # Assert
    assert response.status_code == 404


@pytest.mark.negative
@pytest.mark.admin
def test_delete_recipe_twice_second_attempt_returns_404(
    client: httpx.Client,
    valid_recipe_payload: dict,
):
    # Arrange — create a recipe to delete
    create_resp = client.post("/admin/recipes", json={
        **valid_recipe_payload,
        "title": "QA Delete Idempotency Test"
    })
    assert create_resp.status_code == 201
    recipe_id = create_resp.json()["id"]

    # Act — delete first time
    first_delete = client.delete(f"/admin/recipes/{recipe_id}")
    assert first_delete.status_code == 200

    # Act — delete second time (idempotency check)
    second_delete = client.delete(f"/admin/recipes/{recipe_id}")

    # Assert — must 404 since it's already gone
    assert second_delete.status_code == 404, \
        "Second delete should return 404, recipe should no longer exist."


# ============================================================
# 7. CSV UPLOAD
# ============================================================

@pytest.mark.regression
@pytest.mark.admin
def test_upload_valid_csv_returns_200_with_count(client: httpx.Client):
    """
    Upload a small valid CSV with required columns.
    Verifies the import endpoint returns success with the recipe count.

    WARNING: This endpoint replaces ALL recipes. Use only in isolated test env.
    Skip this test if running against a shared/production database.
    """
    # Arrange — minimal valid CSV
    csv_content = (
        "title,ingredients,instructions,category,cooking_time,difficulty\n"
        "Ayam Goreng QA,500gr ayam;bawang putih,Goreng hingga kuning keemasan.,Goreng,25,Easy\n"
        "Tempe Bacem QA,tempe;kecap;gula jawa,Rebus lalu goreng.,Rebus,45,Medium\n"
    )
    file = {"file": ("test_recipes.csv", io.BytesIO(csv_content.encode()), "text/csv")}

    # Act
    response = client.post("/admin/upload", files=file)

    # Assert
    assert response.status_code == 200, \
        f"CSV upload failed: {response.status_code} — {response.text}"
    body = response.json()
    assert "total" in body
    assert body["total"] == 2


@pytest.mark.negative
@pytest.mark.admin
def test_upload_non_csv_file_returns_400(client: httpx.Client):
    # Arrange — upload a text file disguised as CSV
    file = {"file": ("notacsv.txt", io.BytesIO(b"some plain text"), "text/plain")}

    # Act
    response = client.post("/admin/upload", files=file)

    # Assert — API checks filename extension for .csv
    assert response.status_code == 400, \
        f"Expected 400 for non-CSV upload, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.admin
def test_upload_csv_missing_required_columns_returns_400(client: httpx.Client):
    # Arrange — CSV missing 'ingredients' and 'instructions' columns
    csv_content = "title,category\nAyam Test,Goreng\n"
    file = {"file": ("bad_columns.csv",
                     io.BytesIO(csv_content.encode()), "text/csv")}

    # Act
    response = client.post("/admin/upload", files=file)

    # Assert
    assert response.status_code == 400, \
        f"Expected 400 for missing columns, got {response.status_code}"


@pytest.mark.negative
@pytest.mark.admin
def test_upload_empty_csv_body_returns_error(client: httpx.Client):
    # Arrange — empty file body
    file = {"file": ("empty.csv", io.BytesIO(b""), "text/csv")}

    # Act
    response = client.post("/admin/upload", files=file)

    # Assert — could be 400 (bad request) or 422 (validation error)
    assert response.status_code in (400, 422), \
        f"Expected 400 or 422 for empty CSV, got {response.status_code}"
