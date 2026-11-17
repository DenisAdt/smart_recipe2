# API Specification — Smart Recipe Planner

Base URL: `http://localhost:8000/api`

## Authentication
None (development). Admin endpoints should be protected in production.

---

## Search

### `POST /search`
BM25-based ingredient search.

**Request Body:**
```json
{
  "ingredients": ["ayam", "bawang merah", "kecap"],
  "filters": {
    "category": "Goreng",
    "max_cooking_time": 30,
    "difficulty": "Easy",
    "sort_by": "bm25"
  },
  "top_k": 20
}
```

**Response `200`:**
```json
{
  "query": "ayam bawang merah kecap",
  "ingredients": ["ayam", "bawang merah", "kecap"],
  "total_found": 15,
  "results": [
    {
      "recipe_id": 1,
      "title": "Ayam Goreng Kremes",
      "category": "Goreng",
      "image_url": "https://...",
      "cooking_time": 45,
      "difficulty": "Medium",
      "bm25_score": 8.52,
      "match_percentage": 87.0,
      "matched_ingredients": ["ayam", "bawang merah"],
      "missing_ingredients": ["kecap"],
      "matched_count": 2,
      "total_query_count": 3,
      "rank": 1,
      "relevance_stars": 5,
      "relevance_label": "Highly Relevant"
    }
  ],
  "processing_steps": ["Menganalisis bahan-bahan...", "..."]
}
```

### `GET /search/suggestions?q={query}`
Ingredient autocomplete.

**Response `200`:**
```json
{
  "suggestions": ["bawang merah", "bawang putih", "bawang goreng"]
}
```

---

## Recipes

### `GET /recipes`
Paginated recipe list.

**Query params:** `page`, `page_size`, `category`, `search`

**Response `200`:**
```json
{
  "items": [...],
  "total": 100,
  "page": 1,
  "page_size": 20
}
```

### `GET /recipes/popular`
Most searched recipes.

**Query params:** `limit` (default 10)

### `GET /recipes/{id}`
Single recipe detail.

### `GET /stats`
Dataset statistics.

**Response `200`:**
```json
{
  "total_recipes": 100,
  "unique_ingredients": 256,
  "total_searches": 1450,
  "categories": {
    "Goreng": 35,
    "Rebus": 28,
    "Tumis": 22,
    "Panggang": 15
  }
}
```

---

## Admin

### `POST /admin/upload`
Upload CSV dataset. Replaces all existing recipes and rebuilds BM25 index.

**Form data:** `file` (CSV)

**Required CSV columns:** `title`, `ingredients`, `instructions`

**Optional:** `category`, `image_url`, `cooking_time`, `difficulty`

### `GET /admin/recipes`
All recipes (CRUD list). Query: `page`, `page_size`

### `POST /admin/recipes`
Create recipe.

### `PUT /admin/recipes/{id}`
Update recipe.

### `DELETE /admin/recipes/{id}`
Delete recipe and rebuild index.

### `GET /admin/analytics`
Search analytics: top searched ingredients, daily search counts.

---

## Evaluation

### `POST /evaluation/run`
Run comparative IR evaluation.

**Request Body:**
```json
{
  "queries": ["ayam bawang", "tempe tahu goreng"],
  "relevant_recipe_ids": {
    "ayam bawang": [1, 2, 5, 10],
    "tempe tahu goreng": [4, 13, 29]
  },
  "k_values": [5, 10]
}
```

**Response `200`:**
```json
{
  "results": [
    {
      "method": "BM25 tanpa Stemming",
      "precision": 0.6250,
      "recall": 0.5000,
      "precision_at_5": 0.6000,
      "precision_at_10": 0.5500,
      "f1_score": 0.5556
    },
    {
      "method": "BM25 dengan Stemming",
      "precision": 0.7500,
      "recall": 0.6000,
      "precision_at_5": 0.7200,
      "precision_at_10": 0.6800,
      "f1_score": 0.6667
    },
    {
      "method": "TF-IDF dengan Stemming",
      "precision": 0.5000,
      "recall": 0.4000,
      "precision_at_5": 0.4800,
      "precision_at_10": 0.4200,
      "f1_score": 0.4444
    }
  ],
  "queries_used": ["ayam bawang", "tempe tahu goreng"],
  "timestamp": "2026-06-03T02:00:00Z"
}
```

### `GET /evaluation/results`
Stored evaluation history.

---

## System

### `GET /health`
Health check.

```json
{
  "status": "ok",
  "version": "1.0.0",
  "bm25_ready": true,
  "recipe_count": 100
}
```
