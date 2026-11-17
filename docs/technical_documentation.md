# Smart Recipe Planner — Complete Technical Documentation

---

## PROJECT OVERVIEW

### Application Name
**Smart Recipe Planner** (`smart_recipe_planner`) — Version 1.0.0

### Main Purpose
An academic **Information Retrieval (IR)** project that allows users to find Indonesian recipes by entering available ingredients. The core algorithm is **Okapi BM25**, complemented by Indonesian-language NLP preprocessing. The app also includes a comparative evaluation module that benchmarks BM25 (with and without stemming) against TF-IDF.

### Current Architecture
The project is a **full-stack mobile + backend** system composed of two completely separate codebases:

| Layer | Technology | Role |
|---|---|---|
| **Frontend** | Flutter (Dart) | Android mobile app |
| **Backend** | FastAPI (Python) | REST API + BM25 engine |
| **Database** | SQLite (aiosqlite) | Persistent recipe storage |
| **BM25 Index** | In-memory (rank_bm25) | Runtime search index |

The Flutter app communicates with the FastAPI backend exclusively via HTTP REST calls using the **Dio** HTTP client.

### Tech Stack

**Backend:**
- `FastAPI 0.111.0` — async web framework
- `Uvicorn 0.30.1` — ASGI server
- `SQLAlchemy 2.0.30` (async) — ORM
- `aiosqlite 0.20.0` — async SQLite driver
- `rank-bm25 0.2.2` — Okapi BM25 implementation (`BM25Okapi`)
- `PySastrawi 1.2.1` — Indonesian stemmer
- `NLTK 3.8.1` — Indonesian stopwords
- `scikit-learn 1.5.0` — TF-IDF vectorizer (evaluation only)
- `numpy 1.26.4` — metric averaging
- `pydantic 2.7.1` — request/response validation
- `pydantic-settings 2.3.1` — config management

**Frontend:**
- `Flutter SDK >=3.3.0` — cross-platform framework (only Android configured)
- `flutter_riverpod 2.5.1` — state management
- `go_router 14.2.7` — declarative navigation
- `dio 5.4.3` — HTTP client
- `google_fonts 6.2.1` — typography
- `flutter_animate 4.5.0` — micro-animations
- `shimmer 3.0.0` — loading skeletons
- `cached_network_image 3.3.1` — image caching
- `fl_chart 0.68.0` — bar charts (Evaluation screen)
- `shared_preferences 2.3.2` — local theme persistence
- `file_picker 8.0.7` — CSV file selection (Admin)

### State Management
The frontend uses **Riverpod** (`flutter_riverpod`) with the classic `StateNotifier` pattern (not code-generated):
- `StateNotifierProvider<IngredientsNotifier, List<String>>` — ingredient list
- `StateNotifierProvider<FiltersNotifier, SearchFilters>` — search filters
- `StateNotifierProvider<SearchNotifier, SearchState>` — search lifecycle
- `StateNotifierProvider<ThemeNotifier, bool>` — dark mode toggle
- `FutureProvider<DatasetStats>` — stats (auto-fetched)
- `FutureProvider<List<Recipe>>` — popular recipes (auto-fetched)
- `FutureProvider.family<Recipe, int>` — single recipe by ID
- `FutureProvider.family<List<String>, String>` — autocomplete suggestions

### Folder Structure

```
smart_recipe2/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── routes/
│   │   │       ├── admin.py         # Admin CRUD & upload
│   │   │       ├── evaluation.py    # IR evaluation runner
│   │   │       ├── recipes.py       # Recipe list & detail
│   │   │       └── search.py        # BM25 search endpoint
│   │   ├── core/
│   │   │   ├── bm25_engine.py       # BM25 singleton engine
│   │   │   ├── config.py            # App settings (pydantic-settings)
│   │   │   └── preprocessor.py      # NLP pipeline
│   │   ├── database/
│   │   │   ├── db.py                # Engine, session factory, Base
│   │   │   └── seed.py              # CSV → SQLite importer
│   │   ├── models/
│   │   │   ├── evaluation.py        # EvaluationResult ORM model
│   │   │   ├── recipe.py            # Recipe ORM model
│   │   │   └── search_log.py        # SearchLog ORM model
│   │   ├── schemas/
│   │   │   ├── evaluation.py        # Pydantic I/O schemas
│   │   │   ├── recipe.py            # Pydantic I/O schemas
│   │   │   └── search.py            # Pydantic I/O schemas
│   │   └── main.py                  # FastAPI app entry point
│   ├── data/
│   │   ├── recipes.csv              # Seed dataset (Indonesian recipes)
│   │   └── srp.db                   # SQLite database file
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── lib/
│   │   ├── app/
│   │   │   ├── router/app_router.dart    # GoRouter configuration
│   │   │   └── theme/
│   │   │       ├── app_colors.dart       # Color palette & gradients
│   │   │       └── app_theme.dart        # MaterialApp theme data
│   │   ├── core/
│   │   │   ├── api/api_client.dart       # Dio HTTP client (singleton)
│   │   │   └── constants/app_constants.dart # Base URL, chip lists, etc.
│   │   ├── features/
│   │   │   ├── admin/admin_screen.dart   # Admin dashboard
│   │   │   ├── detail/detail_screen.dart # Recipe detail + explainability
│   │   │   ├── evaluation/evaluation_screen.dart # IR metrics dashboard
│   │   │   ├── home/home_screen.dart     # Landing screen
│   │   │   ├── my_recipes/my_recipes_screen.dart # Saved recipes (stub)
│   │   │   ├── profile/profile_screen.dart # Settings + dev tools
│   │   │   ├── results/results_screen.dart # Search results list
│   │   │   ├── search/search_screen.dart  # Ingredient input
│   │   │   └── splash/splash_screen.dart  # Animated splash
│   │   ├── shared/
│   │   │   ├── models/
│   │   │   │   ├── evaluation.dart        # EvaluationMethodResult, EvaluationRunResult
│   │   │   │   ├── recipe.dart            # Recipe, DatasetStats
│   │   │   │   └── search_result.dart     # SearchResult, SearchResponse
│   │   │   ├── providers/
│   │   │   │   ├── recipe_provider.dart   # statsProvider, popularRecipesProvider, etc.
│   │   │   │   ├── search_provider.dart   # ingredientsProvider, searchProvider, etc.
│   │   │   │   └── theme_provider.dart    # themeProvider
│   │   │   └── widgets/
│   │   │       ├── floating_bottom_nav.dart # Pill-shaped nav widget
│   │   │       └── main_shell.dart          # ShellRoute wrapper
│   │   └── main.dart                        # App bootstrap
│   └── pubspec.yaml
└── docker-compose.yml
```

---

## DATABASE

### Tables

**1. `recipes`**
| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `title` | VARCHAR(255) | Indexed, required |
| `ingredients` | TEXT | Raw ingredient string (comma/newline/semicolon delimited) |
| `instructions` | TEXT | Raw cooking instruction text |
| `category` | VARCHAR(50) | Default `"Goreng"` |
| `image_url` | TEXT | Nullable; URL to recipe image |
| `cooking_time` | INTEGER | In minutes, nullable |
| `difficulty` | VARCHAR(20) | `Easy` / `Medium` / `Hard`, nullable, default `"Medium"` |
| `created_at` | DATETIME | UTC timestamp, auto-set |

**2. `search_logs`**
| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `query` | TEXT | Space-joined raw ingredient string |
| `ingredients` | TEXT | JSON array of ingredient strings |
| `results_count` | INTEGER | How many recipes were returned |
| `top_result_id` | INTEGER FK → recipes.id | Nullable; the rank-1 result |
| `timestamp` | DATETIME | Indexed, UTC auto-set |

**3. `evaluation_results`**
| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `method` | VARCHAR(100) | e.g. `"BM25 dengan Stemming"` |
| `precision` | FLOAT | Average precision across all queries |
| `recall` | FLOAT | Average recall |
| `precision_at_5` | FLOAT | P@5 |
| `precision_at_10` | FLOAT | P@10 |
| `f1_score` | FLOAT | F1 score |
| `query_set` | TEXT | JSON list of queries used |
| `created_at` | DATETIME | UTC auto-set |

### Relationships
- `search_logs.top_result_id` is a **foreign key** referencing `recipes.id` (nullable, `isouter` join used in popular recipes query).
- No foreign key exists between `evaluation_results` and any other table.

### Local Storage (Frontend)
- **`shared_preferences`** is used exclusively by `ThemeNotifier` to persist one key: `isDarkMode` (bool).
- No recipe data, search history, or favorites are stored locally on the device.

### Caching
- **`cached_network_image`** is used for recipe images (`CachedNetworkImage` widget). It caches images automatically in the device cache directory.
- The BM25 index is held entirely **in memory** on the backend after startup. It is not persisted to disk; it is rebuilt from SQLite on every server start (or after each admin CRUD operation).

---

## NAVIGATION

### Bottom Navigation
Implemented as a **floating pill-shaped bar** (`FloatingBottomNav`) rendered inside a `Stack` overlay by `MainShell`. It has **4 items**:

| Index | Icon | Label | Route |
|---|---|---|---|
| 0 | `house_rounded` | Home | `/home` |
| 1 | `search_rounded` | Search | `/search` |
| 2 | `soup_kitchen_rounded` | My Recipes | `/my-recipes` |
| 3 | `person_rounded` | Profile | `/profile` |

The active item expands into a pill (icon + label). Inactive items show only the icon in muted color.

### Available Pages

| Page | Route | Has Nav Bar | Description |
|---|---|---|---|
| Splash | `/` | No | 2.8s animated intro, then auto-navigates to Home |
| Home | `/home` | Yes | Popular recipes, stats, quick chips |
| Search | `/search` | Yes | Ingredient input, autocomplete, filters |
| Results | `/results` | No | BM25 search result list (passed via `extra`) |
| Detail | `/detail/:id` | No | Full recipe detail + BM25 explainability |
| My Recipes | `/my-recipes` | Yes | Stub — always shows "no saved recipes" |
| Profile | `/profile` | Yes | Theme toggle + links to dev tools |
| Evaluation | `/evaluation` | No | IR metrics dashboard |
| Admin | `/admin` | No | Dataset management + analytics |

### Hidden Pages
`/evaluation` and `/admin` are **developer-only pages** — they are defined in the router but not reachable from the floating nav bar. They are only accessible via:
- Profile screen → "Evaluation" menu card → `context.go('/evaluation')`
- Profile screen → "Admin Dashboard" menu card → `context.go('/admin')`

### Route Flow

```
/  (Splash)
  └─ auto after 2.8s → /home

/home
  ├─ search box tap → /search
  ├─ quick chip tap → /search (with ingredient pre-filled)
  └─ popular recipe card tap → /detail/:id

/search
  ├─ back button → /home
  └─ "Cari Resep" button (with ingredients) → /results (via extra map)

/results
  ├─ back button → /search
  └─ result card tap → /detail/:id (with SearchResult passed as extra)

/detail/:id
  └─ back button → context.pop() (returns to caller, Results or Home)

/profile
  ├─ "Saved Recipes" → /my-recipes
  ├─ "Evaluation" → /evaluation
  └─ "Admin Dashboard" → /admin

/evaluation
  └─ back → /home

/admin
  └─ back → /home
```

### Which Pages Are Connected

- **Home ↔ Search**: bidirectional; Home navigates to Search; Search back-button goes to Home.
- **Search → Results**: one-way; data passed as `extra`.
- **Results → Detail**: one-way; `SearchResult` passed as `extra`.
- **Home → Detail**: direct link from popular recipes cards; no `SearchResult` extra.
- **Profile → Evaluation / Admin**: one-way links.
- **Detail ↔ Results**: `context.pop()` returns to whichever screen pushed Detail.

---

## ALL FEATURES

### 1. Splash Screen
- **Purpose**: Brand intro and loading animation during BM25 engine warm-up.
- **User Flow**: App opens → animated logo, tagline, and "Powered by Okapi BM25" badge fade in → 3 pulsing dots indicate loading → after **2800ms**, automatically navigates to `/home`.
- **Logic**: `AnimationController` with `repeat(reverse: true)` drives the pulsing dots. `Future.delayed(2800ms)` triggers `context.go('/home')`.
- **Data Source**: None (purely UI).
- **Dependencies**: `flutter_animate`, `AppColors.splashGradient`.

---

### 2. Home Screen
- **Purpose**: Landing dashboard showing status, quick access to search, popular recipes, and dataset stats.
- **User Flow**: User sees time-aware greeting → taps search box or quick ingredient chip → navigates to `/search`. Or taps a popular recipe card → navigates to `/detail/:id`.
- **Logic**:
  - Greeting uses `DateTime.now().hour` to produce `Selamat Pagi/Siang/Sore/Malam`.
  - Quick ingredient chips (`AppConstants.quickIngredients`) pre-fill the `ingredientsProvider` before navigating to Search.
  - Popular recipes come from `popularRecipesProvider` (API: `GET /api/recipes/popular`).
  - Stats come from `statsProvider` (API: `GET /api/stats`).
  - Shimmer loading skeleton displays while data loads.
  - Dark mode toggle button calls `themeProvider.notifier.toggle()`.
- **Data Source**: Backend (`/api/recipes/popular`, `/api/stats`).
- **Dependencies**: `shimmer`, `cached_network_image`, `flutter_animate`, `statsProvider`, `popularRecipesProvider`, `themeProvider`, `ingredientsProvider`.

---

### 3. Search Screen
- **Purpose**: Ingredient input screen. Users build a list of ingredients to search with.
- **User Flow**:
  1. User types a name in the text field → autocomplete suggestions appear (from backend).
  2. User selects a suggestion or presses Enter/add button → ingredient added as a chip.
  3. User can also tap "Quick Add" preset chips (toggle: add/remove).
  4. Home quick chips pre-populate the list when navigating from Home.
  5. "Hapus Semua" (Clear All) button removes all chips.
  6. "Cari Resep (N bahan)" button is enabled only when ≥1 ingredient exists.
  7. Tap search button → `_SearchLoadingDialog` modal shows step-by-step animation → navigates to `/results`.
- **Logic**:
  - `_textController.addListener(_onTextChanged)` fetches suggestions asynchronously on each keystroke via `suggestionsProvider(query)` FutureProvider.
  - `_doSearch()` calls `ref.read(searchProvider.notifier).search()` which POSTs to `/api/search`.
  - The loading dialog reads `searchProvider.currentStep` (0–7) to animate the 7 processing steps.
- **Data Source**: `ingredientsProvider`, `searchFiltersProvider`, `suggestionsProvider` (API: `GET /api/search/suggestions`).
- **Dependencies**: `searchProvider`, `ingredientsProvider`, `suggestionsProvider`, `themeProvider`.

---

### 4. Results Screen
- **Purpose**: Displays the BM25 search results as a scrollable list of cards.
- **User Flow**: User sees recipe cards sorted by BM25 score by default → can filter by category chip bar → can sort via popup menu → taps a card → navigates to `/detail/:id` with the `SearchResult` object.
- **Logic**:
  - Data is received as `extra` from the Search screen (already-fetched from backend); no additional API call is made.
  - `_applyFilter()` re-filters and re-sorts the in-memory `_filteredResults` list on every chip/menu selection.
  - Category filter: client-side string match on `result.category`.
  - Sort options: `BM25 Relevansi` (default order from backend), `Alphabetical` (title sort), `Waktu Masak` (cookingTime ascending).
  - Empty state shown if no results match the current filter.
- **Data Source**: Data received from `SearchNotifier` via `GoRouter extra` — not re-fetched.
- **Dependencies**: `themeProvider`, `SearchResult` model, `AppConstants.categories`.

---

### 5. Detail Screen
- **Purpose**: Full recipe view with hero image, cooking meta, ingredient list (with match highlighting), step-by-step instructions, and BM25 explainability panel.
- **User Flow**: User arrives from Results (with `SearchResult`) or Home (without `SearchResult`) → sees full recipe → optional "Mengapa resep ini?" panel shows BM25 score, match %, rank, matched/missing ingredients.
- **Logic**:
  - Recipe data is fetched from `recipeDetailProvider(recipeId)` → `GET /api/recipes/:id`.
  - If `SearchResult` is present (from search flow), an **explainability section** appears showing: BM25 score, match percentage, rank, matched ingredients (green chips), missing ingredients (red chips).
  - Ingredient list items are highlighted green if they appear in `matchedIngredients` (substring match).
  - Instructions are split by sentence boundaries (`RegExp(r'(?<=[.!?])\s+')`) and rendered as numbered steps.
  - Shimmer skeleton shown during loading.
- **Data Source**: `recipeDetailProvider` (API: `GET /api/recipes/:id`), `SearchResult` passed as `extra`.
- **Dependencies**: `recipeDetailProvider`, `themeProvider`, `cached_network_image`, `shimmer`, `flutter_animate`.

---

### 6. My Recipes Screen
- **Purpose**: Placeholder for a "Saved Recipes" / favorites feature.
- **User Flow**: User taps "My Recipes" in nav bar → sees empty state ("Belum ada resep tersimpan").
- **Logic**: **No logic implemented.** The screen is a pure UI stub. There is no data model, no API call, no storage mechanism for saved recipes.
- **Data Source**: None.
- **Dependencies**: `themeProvider`, `flutter_animate`.

---

### 7. Profile Screen
- **Purpose**: User profile stub + access gateway to developer tools.
- **User Flow**: Shows avatar + "Guest User" + "Smart Recipe Planner" label → provides access to Saved Recipes, Evaluation dashboard, and Admin dashboard.
- **Logic**: No real user authentication. Theme toggle button present (same as Home). Three `_MenuCard` items:
  - "Saved Recipes" → `/my-recipes`
  - "Evaluation" → `/evaluation`
  - "Admin Dashboard" → `/admin`
  - Subtitle for Saved Recipes is hardcoded as `"0 resep tersimpan"`.
- **Data Source**: None.
- **Dependencies**: `themeProvider`, `go_router`.

---

### 8. Evaluation Screen
- **Purpose**: Academic IR evaluation dashboard comparing BM25 (no stem), BM25 (with stem), and TF-IDF (with stem).
- **User Flow**: User sees description → taps "Jalankan" → backend runs evaluation → results table and bar chart appear → past runs listed from history.
- **Logic**:
  - `_loadHistory()` fetches past evaluation records from `GET /api/evaluation/results` on screen load.
  - `_runEvaluation()` calls `POST /api/evaluation/run` with hardcoded `_defaultQueries` (8 queries) and hardcoded `_defaultRelevantIds` (ground truth IDs per query).
  - Results are displayed in a table: Method × Precision, Recall, P@5, P@10.
  - A grouped bar chart (`fl_chart`) visualizes the same metrics.
  - The 8 default queries are shown as chip tags at the bottom.
- **Data Source**: `ApiClient.runEvaluation()`, `ApiClient.getEvaluationResults()`.
- **Dependencies**: `fl_chart`, `ApiClient`, `EvaluationRunResult`, `themeProvider`.

---

### 9. Admin Screen
- **Purpose**: Developer/admin panel for dataset management and analytics.
- **User Flow**: 3-tab layout: Dataset | Resep | Analitik.
- **Logic**:
  - **Tab 1 (Dataset)**: Shows total recipes and total searches stats. Tap-to-upload CSV zone uses `file_picker` to pick a `.csv` file, reads its bytes, and POSTs multipart to `POST /api/admin/upload`. On success, rebuilds the BM25 index server-side and refreshes local recipe list + analytics.
  - **Tab 2 (Resep)**: Shows paginated recipe list (30 per page). Delete button triggers `DELETE /api/admin/recipes/:id` with confirmation dialog. No Create or Update is implemented in the UI.
  - **Tab 3 (Analitik)**: Shows top 10 searched ingredients with horizontal progress bars, fetched from `GET /api/admin/analytics`.
- **Data Source**: `ApiClient.getAnalytics()`, `ApiClient.getRecipes()`, `ApiClient.uploadCsv()`, `ApiClient.deleteRecipe()`.
- **Dependencies**: `file_picker`, `fl_chart`, `ApiClient`, `themeProvider`, `flutter_animate`.

---

### 10. Dark Mode
- **Purpose**: Toggle between light and dark theme.
- **User Flow**: Tap the theme toggle button (sun/moon icon) on Home or Profile → theme switches instantly and persists across app restarts.
- **Logic**: `ThemeNotifier.toggle()` flips boolean state and writes to `SharedPreferences` under key `isDarkMode`. On `ThemeNotifier()` constructor, `_loadTheme()` reads the persisted value.
- **Data Source**: `SharedPreferences`.
- **Dependencies**: `shared_preferences`, `themeProvider`.

---

## SEARCH SYSTEM

### Input Flow
1. User opens **Search Screen** and types an ingredient name in the text field.
2. On every keystroke, `_onTextChanged()` calls `suggestionsProvider(query).future` which hits `GET /api/search/suggestions?q=<text>`.
3. User selects a suggestion or types manually and taps the `+` button or presses Enter.
4. The ingredient is added to `ingredientsProvider` (a `List<String>` in Riverpod state).
5. Each ingredient displays as a gradient chip with an `×` remove button.
6. User can also tap pre-set "Quick Add" chips to toggle ingredients.
7. When ≥1 ingredient exists, the "Cari Resep" button activates.

### Query Preprocessing (Backend)
The `preprocessor.py` module implements a **4-step NLP pipeline**:

1. **Case Folding** (`case_fold`): `text.lower().strip()`
2. **Tokenization** (`tokenize`): `re.findall(r'[a-z0-9]+', text)` — extracts only alphanumeric tokens.
3. **Stopword Removal** (`remove_stopwords`): Removes tokens that appear in the combined stopword set (NLTK Indonesian + custom culinary noise words). Tokens with length ≤ 1 are also removed.
4. **Stemming** (`stem_tokens`): Applies **PySastrawi `IndonesianStemmer`** to each token. The stemmer is created once and cached with `@lru_cache(maxsize=1)`.

The stopword set merges:
- NLTK `stopwords.words("indonesian")` (~750 words)
- `_CUSTOM_STOPWORDS`: ~60 custom words (general Indonesian + culinary verbs/noise: `masak, goreng, tumis, secukupnya, tambahkan`, etc.)

### Search Process
1. Client POSTs `{"ingredients": ["ayam", "bawang merah"], "filters": {...}, "top_k": 20}` to `POST /api/search`.
2. Backend joins ingredients into a single string: `"ayam bawang merah"`.
3. Runs the preprocessing pipeline → produces a list of stemmed query tokens.
4. `BM25Okapi.get_scores(query_tokens)` scores all documents in the index.
5. Documents with score ≤ 0 are discarded.
6. Filters are applied (category, max_cooking_time, difficulty).
7. For each remaining doc, `_match_ingredients()` is called to determine which query ingredients overlap with recipe ingredients (using stemmed token sets).
8. Results are sorted by BM25 score (descending by default, or alphabetical/cooking_time if specified).
9. Top `top_k` (default 20, max 100) results are returned.
10. Each search is logged to the `search_logs` table.

### Ranking Process
- Primary sort: **BM25 score descending** (highest relevance first).
- Secondary sorts (client-selectable): alphabetical by title, or ascending cooking time.
- After sorting, each result receives a sequential `rank` (1, 2, 3...).

### BM25 Implementation

**Library**: `rank_bm25.BM25Okapi`

**Parameters**:
- `k1 = 1.2` (term frequency saturation)
- `b = 0.75` (document length normalization)

**Two parallel indexes are maintained**:
- `_bm25_stemmed`: built from stemmed documents (used for main search)
- `_bm25_no_stem`: built from non-stemmed documents (used for evaluation comparison)

**Document representation** (`build_document`): Each recipe is converted to a weighted token list by **field repetition**:
```
document = (title_tokens × 3) + (ingredient_tokens × 2) + (instruction_tokens × 1)
```
This weights the title highest and instructions lowest in the BM25 scoring.

**Singleton**: A single `bm25_engine = BM25Engine()` instance is created at module level and initialized during FastAPI lifespan startup. It is **rebuilt** (`bm25_engine.rebuild(recipe_dicts)`) after any admin CRUD operation.

### Stemming Usage
- **PySastrawi `IndonesianStemmer`** is applied in the preprocessing pipeline.
- It is used when `apply_stemming=True` (the default for the main search).
- Both query tokens and document tokens are stemmed, ensuring consistent vocabulary matching.
- For ingredient matching display (showing which ingredients were matched/missing), **non-stemmed** ingredient names are preserved in `RecipeDoc.ingredient_names`.
- Stemmed tokens are stored in `RecipeDoc.ingredient_tokens_stemmed` for the matching logic.

### TF-IDF Usage
TF-IDF is **only used in the evaluation module**, not in the main search:
- `sklearn.feature_extraction.text.TfidfVectorizer` is applied to the entire corpus.
- Cosine similarity (`sklearn.metrics.pairwise.cosine_similarity`) ranks documents.
- This is computed **on-demand** for each evaluation run (no persistent index).

### Data Retrieval
- At startup, all recipes are loaded from SQLite into `BM25Engine._corpus` (a `list[RecipeDoc]`).
- The `RecipeDoc` dataclass holds: `recipe_id`, `title`, `ingredients`, `instructions`, `category`, `image_url`, `cooking_time`, `difficulty`, `ingredient_names` (parsed, non-stemmed), `ingredient_tokens_stemmed`.
- All BM25 scoring happens against this in-memory corpus — no database hit during search.

### Result Generation
Each `BM25Result` contains:
| Field | Type | Description |
|---|---|---|
| `recipe_id` | int | DB primary key |
| `title` | str | Recipe name |
| `category` | str | Cooking method |
| `bm25_score` | float | Raw Okapi BM25 score, rounded to 4 decimal places |
| `match_percentage` | float | `matched_count / total_query_count × 100` |
| `matched_ingredients` | list[str] | Query ingredients found in recipe |
| `missing_ingredients` | list[str] | Query ingredients NOT found in recipe |
| `matched_count` | int | Count of matched ingredients |
| `total_query_count` | int | Count of query ingredients |
| `rank` | int | Position in sorted results (1-based) |
| `relevance_stars` | int | 1–5 star rating |
| `relevance_label` | str | Human-readable label |

### Relevance Label (Hardcoded Thresholds)
| BM25 Score | Stars | Label |
|---|---|---|
| ≥ 8.0 | 5 | Highly Relevant |
| ≥ 5.0 | 4 | Relevant |
| ≥ 2.0 | 3 | Moderate |
| ≥ 0.5 | 2 | Partial |
| < 0.5 | 1 | Low |

These thresholds are defined in `config.py` as `RELEVANCE_HIGHLY`, `RELEVANCE_RELEVANT`, `RELEVANCE_MODERATE`, `RELEVANCE_PARTIAL`.

---

## EVALUATION MODULE

### Current Evaluation Logic
The evaluation is triggered via the Evaluation Screen → `POST /api/evaluation/run`. It compares **3 methods** in parallel using the same query set and ground truth:

1. **BM25 tanpa Stemming** — `BM25Okapi` without stemming, using `bm25_engine.get_top_ids(query, k, apply_stemming=False)`
2. **BM25 dengan Stemming** — `BM25Okapi` with stemming (default), using `bm25_engine.get_top_ids(query, k, apply_stemming=True)`
3. **TF-IDF dengan Stemming** — `TfidfVectorizer` + cosine similarity, with stemmed documents

### Metrics Used
- **Precision** (`P = TP / (TP + FP)` = `len(set(ret) ∩ rel_set) / len(ret)`)
- **Recall** (`R = TP / (TP + FN)` = `len(set(ret) ∩ rel_set) / len(rel_set)`)
- **F1 Score** (`F1 = 2×P×R / (P+R)`)
- **Precision@5** (`P@5 = len(set(ret[:5]) ∩ rel_set) / 5`)
- **Precision@10** (`P@10 = len(set(ret[:10]) ∩ rel_set) / 10`)

All metrics are **macro-averaged** across all queries in the test set (i.e., computed per query, then averaged).

### Precision Calculation
```python
tp = len(set(retrieved_ids) & set(relevant_ids))
precision = tp / len(retrieved_ids) if retrieved_ids else 0.0
```
Averaged over all queries with `numpy.mean`.

### Recall Calculation
```python
tp = len(set(retrieved_ids) & set(relevant_ids))
recall = tp / len(relevant_ids)
```

### Precision@5
```python
tp_k = len(set(retrieved_ids[:5]) & set(relevant_ids))
precision_at_5 = tp_k / 5
```

### Precision@10
```python
tp_k = len(set(retrieved_ids[:10]) & set(relevant_ids))
precision_at_10 = tp_k / 10
```

### Dynamic vs Hardcoded Values

**Hardcoded (in `evaluation_screen.dart`)**:
- The **8 test queries** (`_defaultQueries`) are hardcoded constants.
- The **ground truth relevant document IDs** (`_defaultRelevantIds`) are hardcoded. The code comment states: *"In a real academic setting, these would be manually annotated. These are demonstration values."*

**Dynamic**:
- The **retrieved document IDs** are computed live at evaluation time by the BM25/TF-IDF engines against the current database state.
- The **metric values** (precision, recall, P@5, P@10, F1) are dynamically calculated at runtime.
- Results are **saved to the `evaluation_results` table** and displayed in history.

### How Comparison Currently Works
The `_compute_metrics` function in `evaluation.py` receives two parallel lists:
- `retrieved_ids[i]` = ordered list of recipe IDs returned by the method for query `i`
- `relevant_ids[i]` = list of manually-annotated relevant IDs for query `i`

It computes per-query metrics, then returns `numpy.mean` of each metric list. The comparison is shown side-by-side in a table and grouped bar chart in the Evaluation Screen.

---

## HISTORY SYSTEM

### Search History
- Every successful search stores a record in the `search_logs` SQLite table (query text, ingredients JSON array, results count, top result ID, timestamp).
- **There is no "view search history" feature** in the frontend. The history is used only for:
  - Populating the "popular recipes" endpoint (`GET /api/recipes/popular`) which JOINs `search_logs` to count top result appearances.
  - The analytics endpoint (`GET /api/admin/analytics`) which reads the last 500 logs.

### Storage Method
- Server-side: **SQLite** (`search_logs` table).
- Client-side: **Nothing** — no search history is stored on the device.

### Favorite Recipes
- **Not implemented.** The My Recipes screen exists as a UI stub showing "Belum ada resep tersimpan" (No saved recipes yet).
- The Profile screen's "Saved Recipes" menu card shows a hardcoded subtitle `"0 resep tersimpan"`.
- There is no `favorites` table in the database.
- There is no `save` button anywhere in the detail or results screens.

### Saved Recipes
- Same as Favorites — **not implemented.** The concept is only surfaced as a placeholder UI in My Recipes Screen and Profile Screen.

---

## ADMIN FEATURES

### Dataset Upload
- **Endpoint**: `POST /api/admin/upload` (multipart form)
- **Frontend**: Admin Screen → Tab "Dataset" → tap upload zone → FilePicker picks `.csv` → bytes are wrapped in `FormData` and sent via Dio.
- **Backend Logic**:
  1. Validates file is `.csv`.
  2. Validates CSV has `title`, `ingredients`, `instructions` columns.
  3. Deletes **all existing recipes** from DB (`DELETE FROM recipes`).
  4. Parses CSV rows in batches of 100, inserts new `Recipe` rows.
  5. Calls `_rebuild_index(db)` to reconstruct the BM25 engine from new data.
- **CSV required columns**: `title`, `ingredients`, `instructions`
- **CSV optional columns**: `category`, `image_url`, `cooking_time`, `difficulty`

### CSV Import (Seed)
- `seed.py` is a standalone script (`python -m app.database.seed`) that loads `data/recipes.csv` into the database in batches of 50. It is also triggered automatically on FastAPI startup if the `recipes` table is empty.

### Recipe CRUD
| Operation | Backend Endpoint | Frontend Implementation |
|---|---|---|
| List | `GET /api/admin/recipes?page=N` | Admin Tab 2, paginated list (30/page) |
| Create | `POST /api/admin/recipes` | **Not in UI** |
| Update | `PUT /api/admin/recipes/:id` | **Not in UI** |
| Delete | `DELETE /api/admin/recipes/:id` | Admin Tab 2, delete icon with confirmation dialog |
| Read (public) | `GET /api/recipes/:id` | Detail Screen |

After any Create, Update, or Delete, the backend calls `_rebuild_index(db)` to keep the BM25 engine in sync.

### Analytics
- **Endpoint**: `GET /api/admin/analytics`
- **Backend Logic**: Reads the last 500 `search_logs`, counts ingredient frequencies (top 15), and computes daily search counts for the last 7 days.
- **Response**: `total_recipes`, `total_searches`, `top_ingredients` (array of `{ingredient, count}`), `daily_searches` (array of `{date, count}`).
- **Frontend**: Admin Tab 3 shows top 10 ingredients with horizontal progress bars. Daily searches are fetched but **not visualized** in the current UI.

---

## UI COMPONENTS

### Floating Bottom Navigation (`FloatingBottomNav`)
- A pill-shaped `Container` (height 64, borderRadius 32) with soft layered box shadows and **no border**.
- Rendered as a `Positioned` overlay in a `Stack` inside `MainShell`, over the page content.
- `extendBody: true` on the `MainShell` `Scaffold` ensures page content renders beneath it.
- `indexFromRoute(location)` maps the current GoRouter path to the active tab index.
- Active item: expands with `AnimatedContainer` to show icon + label in a solid black/white inner pill.
- Animation: entry via `flutter_animate` `.fadeIn().slideY(begin: 0.5)`.

### Cards
- **Recipe cards (Home — popular)**: 160×200px horizontal scroll card with `CachedNetworkImage`, fallback gradient placeholder, title, and cooking time.
- **Result cards (Results Screen)**: Full-width cards with hero image (140px height), rank badge (#N), BM25 score badge, category chip, ingredient match progress bar, star rating, and relevance label.
- **Admin recipe rows**: Simple `Container` with title, category chip, difficulty chip, and delete icon button.

### Filters
- **Category filter** (Results Screen): Horizontal scrollable chip bar with pills. Selected = blue background. Options from `AppConstants.categories`: `['Semua', 'Goreng', 'Rebus', 'Tumis', 'Panggang']`.
- **Sort dropdown** (Results Screen): `PopupMenuButton` with 3 options: `BM25 Relevansi`, `Alphabetical`, `Waktu Masak`.
- These filters are **client-side only** — they filter/sort the already-fetched results in memory.
- There are also filter parameters in the search schema (`SearchFilters` in `search_provider.dart`) but the Search Screen UI currently only exposes the ingredient input — no filter controls are visible in the Search Screen. Filters are only available post-search in the Results Screen.

### Search Screen
- `ConsumerStatefulWidget` with a `TextEditingController` + `FocusNode`.
- **Input row**: `TextField` + gradient `+` button.
- **Suggestions dropdown**: Animated `Container` with `ListTile` entries.
- **Selected ingredient chips**: `Wrap` of gradient pills with `×` remove buttons.
- **Quick Add chips**: `Wrap` of `AnimatedContainer` pills (toggle behavior).
- **Search button**: Full-width button at bottom; gradient when active, neutral when no ingredients.

### Result Screen
- `ConsumerStatefulWidget`.
- Filter bar at top → `ListView.separated` of `_ResultCard` widgets.
- Each card is wrapped in `flutter_animate` for staggered fade-in + slideY entrance.
- `_ResultCard` is a stateless internal widget containing `_ScoreBadge`, `_RelevanceStars`, `_infoChip` helpers.

### Detail Screen
- `ConsumerWidget` with `SliverAppBar` (expandedHeight 260) containing a collapsible hero image.
- If arrived from search: an "explainability" card shows BM25/match stats, matched ingredients (green chips), missing ingredients (red chips).
- Ingredient list items are conditionally highlighted based on matching.
- Instructions split by sentence boundaries into numbered steps (each step in a chat-bubble–style container).

---

## STATE MANAGEMENT

### Providers

| Provider | Type | State | Purpose |
|---|---|---|---|
| `ingredientsProvider` | `StateNotifierProvider<IngredientsNotifier, List<String>>` | `List<String>` | Selected ingredients |
| `searchFiltersProvider` | `StateNotifierProvider<FiltersNotifier, SearchFilters>` | `SearchFilters` | Current filter state |
| `searchProvider` | `StateNotifierProvider<SearchNotifier, SearchState>` | `SearchState` | Search lifecycle |
| `themeProvider` | `StateNotifierProvider<ThemeNotifier, bool>` | `bool` (isDark) | Dark mode |
| `statsProvider` | `FutureProvider<DatasetStats>` | async `DatasetStats` | Dataset stats |
| `popularRecipesProvider` | `FutureProvider<List<Recipe>>` | async list | Popular recipes |
| `recipeDetailProvider` | `FutureProvider.family<Recipe, int>` | async `Recipe` by ID | Single recipe |
| `recipesProvider` | `FutureProvider.family<Map, Map>` | async paginated list | Admin recipe list (unused in UI) |
| `suggestionsProvider` | `FutureProvider.family<List<String>, String>` | async suggestions | Autocomplete |

### Controllers / Notifiers

**`IngredientsNotifier`**: Manages `List<String>` of user-selected ingredients. Methods: `add(String)`, `remove(String)`, `clear()`, `setAll(List<String>)`. Prevents duplicate entries.

**`FiltersNotifier`**: Manages `SearchFilters` value object (category, maxCookingTime, difficulty, sortBy). Methods: `update(SearchFilters)`, `reset()`.

**`SearchNotifier`**: Orchestrates the search flow. `search()` reads from `ingredientsProvider` and `searchFiltersProvider`, animates `currentStep` 1→6 with 300ms delays (simulated pipeline), then calls `ApiClient.search()`, parses the `SearchResponse`, and stores it in state. Exposes `reset()`.

**`ThemeNotifier`**: Simple boolean toggle backed by `SharedPreferences`.

### Services
There is no dedicated service layer. The `ApiClient` class (static methods, singleton Dio instance) acts as the HTTP service layer. All providers call `ApiClient` directly.

### Repository Pattern
**Not used.** The architecture goes: `Provider → ApiClient → HTTP → Backend`. There is no repository abstraction between providers and the HTTP client.

### Data Flow
```
User Interaction
  → Riverpod Provider / Notifier (state update)
  → ApiClient.method() (Dio HTTP call)
  → FastAPI Route Handler
  → BM25Engine / SQLAlchemy
  → JSON Response
  → Pydantic Schema Parsing (backend)
  → Dart Model .fromJson() (frontend)
  → Riverpod state updated
  → Widget rebuild via ref.watch()
```

---

## API

### Available Endpoints

| Method | Path | Tag | Description |
|---|---|---|---|
| `GET` | `/` | System | Root info |
| `GET` | `/health` | System | Health check + BM25 readiness |
| `POST` | `/api/search` | Search | BM25 recipe search |
| `GET` | `/api/search/suggestions` | Search | Autocomplete suggestions |
| `GET` | `/api/recipes` | Recipes | Paginated recipe list |
| `GET` | `/api/recipes/popular` | Recipes | Most-searched recipes |
| `GET` | `/api/recipes/:id` | Recipes | Single recipe detail |
| `GET` | `/api/stats` | Statistics | Dataset statistics |
| `POST` | `/api/admin/upload` | Admin | Upload CSV to replace dataset |
| `GET` | `/api/admin/recipes` | Admin | All recipes (paginated, CRUD list) |
| `POST` | `/api/admin/recipes` | Admin | Create recipe |
| `PUT` | `/api/admin/recipes/:id` | Admin | Update recipe |
| `DELETE` | `/api/admin/recipes/:id` | Admin | Delete recipe |
| `GET` | `/api/admin/analytics` | Admin | Search analytics |
| `POST` | `/api/evaluation/run` | Evaluation | Run comparative IR evaluation |
| `GET` | `/api/evaluation/results` | Evaluation | Stored evaluation results |

### Request Format

**`POST /api/search`**
```json
{
  "ingredients": ["ayam", "bawang merah"],
  "filters": {
    "category": "Goreng",
    "max_cooking_time": 30,
    "difficulty": "Medium",
    "sort_by": "bm25"
  },
  "top_k": 20
}
```

**`POST /api/evaluation/run`**
```json
{
  "queries": ["ayam bawang merah", "tempe tahu goreng"],
  "relevant_recipe_ids": {
    "ayam bawang merah": [1, 2, 3],
    "tempe tahu goreng": [4, 5, 6]
  },
  "k_values": [5, 10]
}
```

**`POST /api/admin/upload`** — multipart form with `file` field (CSV).

### Response Format

**`GET /health`**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "bm25_ready": true,
  "recipe_count": 100
}
```

**`POST /api/search` response**
```json
{
  "query": "ayam bawang merah",
  "ingredients": ["ayam", "bawang merah"],
  "total_found": 15,
  "results": [
    {
      "recipe_id": 1,
      "title": "Ayam Goreng Spesial",
      "category": "Goreng",
      "image_url": "http://...",
      "cooking_time": 30,
      "difficulty": "Medium",
      "bm25_score": 12.3456,
      "match_percentage": 100.0,
      "matched_ingredients": ["ayam", "bawang merah"],
      "missing_ingredients": [],
      "matched_count": 2,
      "total_query_count": 2,
      "rank": 1,
      "relevance_stars": 5,
      "relevance_label": "Highly Relevant"
    }
  ],
  "processing_steps": [
    "Menganalisis bahan-bahan...",
    "Preprocessing teks (case folding, tokenisasi)...",
    "Menghapus stopword Bahasa Indonesia...",
    "Stemming dengan Sastrawi...",
    "Menghitung skor BM25 (k1=1.2, b=0.75)...",
    "Mengurutkan resep berdasarkan relevansi...",
    "Ditemukan 15 resep yang relevan!"
  ]
}
```

---

## FILE STRUCTURE

### Main Folders

| Path | Purpose |
|---|---|
| `backend/app/` | All Python application code |
| `backend/app/core/` | Business logic: BM25 engine, preprocessor, config |
| `backend/app/api/routes/` | FastAPI route handlers |
| `backend/app/models/` | SQLAlchemy ORM models |
| `backend/app/schemas/` | Pydantic request/response schemas |
| `backend/app/database/` | DB engine, session factory, seeder |
| `backend/data/` | SQLite file (`srp.db`) and seed CSV (`recipes.csv`) |
| `frontend/lib/app/` | Router + Theme (app-level config) |
| `frontend/lib/core/` | API client, app constants |
| `frontend/lib/features/` | One folder per screen/feature |
| `frontend/lib/shared/` | Models, providers, widgets used across features |

### Important Files and Their Responsibilities

| File | Responsibility |
|---|---|
| `backend/app/main.py` | FastAPI app factory, lifespan (startup: init DB → seed → build BM25 index), CORS, router registration |
| `backend/app/core/bm25_engine.py` | BM25 singleton: `BM25Engine` class, `RecipeDoc` and `BM25Result` dataclasses, index initialization, `search()`, `get_scores_raw()`, `get_top_ids()`, `get_all_ingredient_names()` |
| `backend/app/core/preprocessor.py` | NLP pipeline: case fold, tokenize, remove stopwords, stem (Sastrawi), `preprocess()`, `preprocess_ingredients_list()`, `build_document()` |
| `backend/app/core/config.py` | All settings via pydantic `BaseSettings`: DB URLs, BM25 params (k1=1.2, b=0.75), relevance thresholds, CORS origins, CSV path |
| `backend/app/api/routes/search.py` | `POST /api/search` (BM25 search + search log), `GET /api/search/suggestions` |
| `backend/app/api/routes/recipes.py` | `GET /api/recipes` (paginated), `GET /api/recipes/popular`, `GET /api/recipes/:id`, `GET /api/stats` |
| `backend/app/api/routes/admin.py` | `POST /api/admin/upload`, Recipe CRUD, `GET /api/admin/analytics` |
| `backend/app/api/routes/evaluation.py` | `POST /api/evaluation/run` (comparative BM25 vs TF-IDF), `GET /api/evaluation/results` |
| `backend/app/models/recipe.py` | `Recipe` SQLAlchemy model |
| `backend/app/models/search_log.py` | `SearchLog` SQLAlchemy model |
| `backend/app/models/evaluation.py` | `EvaluationResult` SQLAlchemy model |
| `backend/app/database/db.py` | Async engine, `AsyncSessionLocal`, `Base` ORM class, `get_db()` dependency, `init_db()` |
| `backend/app/database/seed.py` | CSV → SQLite seeder (batches of 50, also callable standalone) |
| `frontend/lib/main.dart` | Flutter bootstrap: `ProviderScope`, `MaterialApp.router`, theme/dark mode wiring |
| `frontend/lib/app/router/app_router.dart` | GoRouter config: all routes, ShellRoute for bottom-nav pages |
| `frontend/lib/app/theme/app_colors.dart` | Full color palette: light, dark, gradients, semantic, category, star colors |
| `frontend/lib/core/api/api_client.dart` | Singleton Dio client, all HTTP methods (search, recipes, suggestions, evaluation, admin), retry interceptor |
| `frontend/lib/core/constants/app_constants.dart` | `baseUrl` (10.0.2.2:8000), `quickIngredients`, `categories`, `difficulties`, `cookingTimeFilters`, `relevanceLabels` |
| `frontend/lib/shared/providers/search_provider.dart` | `ingredientsProvider`, `searchFiltersProvider`, `searchProvider`, `suggestionsProvider` |
| `frontend/lib/shared/providers/recipe_provider.dart` | `statsProvider`, `popularRecipesProvider`, `recipeDetailProvider`, `recipesProvider` |
| `frontend/lib/shared/providers/theme_provider.dart` | `themeProvider` + SharedPreferences persistence |
| `frontend/lib/shared/models/recipe.dart` | `Recipe` + `DatasetStats` Dart models |
| `frontend/lib/shared/models/search_result.dart` | `SearchResult` + `SearchResponse` Dart models |
| `frontend/lib/shared/models/evaluation.dart` | `EvaluationMethodResult` + `EvaluationRunResult` Dart models |
| `frontend/lib/shared/widgets/floating_bottom_nav.dart` | Pill-shaped floating nav widget |
| `frontend/lib/shared/widgets/main_shell.dart` | ShellRoute wrapper with Stack overlay for nav |

---

## CURRENT APPLICATION FLOW

### App Launch
1. Flutter app starts → `main()` calls `WidgetsFlutterBinding.ensureInitialized()`.
2. `ProviderScope` wraps the entire widget tree (Riverpod DI container).
3. `SmartRecipePlannerApp` (ConsumerWidget) watches `themeProvider` → reads `isDarkMode` from `SharedPreferences` → sets `ThemeMode`.
4. `MaterialApp.router` is built with `appRouter` (GoRouter, initial route `/`).
5. **On Backend**: FastAPI lifespan: `init_db()` creates tables → `seed_database()` if empty → loads all recipes → `bm25_engine.initialize(recipe_dicts)` builds in-memory index.

### Splash (`/`)
6. `SplashScreen` renders: gradient background, logo icon animates in with spring effect, app name and tagline fade in, "Powered by Okapi BM25" badge fades in, pulsing dots animate.
7. After **2800ms**, `context.go('/home')`.

### Home (`/home`)
8. `HomeScreen` renders.
9. `statsProvider` fires → `GET /api/stats` → shows recipe count, unique ingredients, total searches.
10. `popularRecipesProvider` fires → `GET /api/recipes/popular?limit=10` → horizontal scroll row of recipe cards.
11. Shimmer skeletons show during loading.
12. User taps search box or quick chip.

### Search (`/search`)
13. `SearchScreen` renders with optional pre-filled ingredient (from Home chip).
14. User types → `GET /api/search/suggestions?q=...` → suggestions dropdown.
15. User builds ingredient list (chips).
16. User taps "Cari Resep" button.
17. `_SearchLoadingDialog` appears (7 steps animating, 300ms each = ~2.1s total).
18. `searchProvider.notifier.search()` fires → `POST /api/search` → response parsed into `SearchResponse`.
19. Dialog dismissed.
20. `context.go('/results', extra: {ingredients, results, totalFound})`.

### Results (`/results`)
21. `ResultsScreen` receives the data via `extra` — **no additional API call**.
22. All results displayed as `_ResultCard` widgets with staggered animations.
23. User can filter by category (client-side) or sort (client-side).
24. User taps a card → `context.go('/detail/:id', extra: {searchResult})`.

### Detail (`/detail/:id`)
25. `DetailScreen` fires `recipeDetailProvider(recipeId)` → `GET /api/recipes/:id`.
26. Shimmer skeleton while loading.
27. Full recipe shown: hero image, title, category badge, cooking time, difficulty.
28. If from search: explainability panel with BM25 score, match %, rank, matched/missing ingredients.
29. Ingredient list with match highlighting (green = matched).
30. Instructions split into numbered steps.
31. User taps back → `context.pop()` → returns to Results.

### Favorite / My Recipes (`/my-recipes`)
32. `MyRecipesScreen` shows "Belum ada resep tersimpan" empty state.
33. No functionality — placeholder only.

### Profile (`/profile`)
34. `ProfileScreen` shows "Guest User" avatar, "0 resep tersimpan" subtitle.
35. Theme toggle available.
36. Links to `/my-recipes`, `/evaluation`, `/admin`.

---

## KNOWN LIMITATIONS

### Missing Features
1. **No user authentication** — `ProfileScreen` always shows "Guest User". No login/register flow.
2. **No saved/favorite recipes** — `MyRecipesScreen` is a complete stub; no save button exists in Detail or Results screens. No favorites table in DB.
3. **No search history UI** — searches are logged server-side but there is no "recent searches" display anywhere in the frontend.
4. **No Create/Update recipe UI** — `POST /api/admin/recipes` and `PUT /api/admin/recipes/:id` endpoints exist on the backend but have no corresponding UI in Admin Screen.
5. **No daily search chart** — the analytics endpoint returns `daily_searches` data but the Admin Analytics tab does not visualize it (only top ingredients are shown).
6. **No pagination indicator** — Admin Recipe tab shows "Hal N" but no total page count.
7. **No filter UI in Search Screen** — `SearchFilters` state exists in Riverpod and is sent in the API request, but no filter controls (category, difficulty, cooking time) are exposed to users in the Search Screen. Only post-search client-side filtering exists in Results Screen.
8. **iOS not configured** — only Android configuration (`android/` folder) exists.

### Temporary Implementations
1. **Hardcoded evaluation ground truth** — `_defaultRelevantIds` in `evaluation_screen.dart` are hardcoded "demonstration values" with a comment acknowledging they are not real manual annotations.
2. **Simulated processing steps animation** — the `SearchNotifier` artificially delays 300ms × 6 steps before the API call, giving the visual impression of step-by-step processing. The actual server processing is faster.
3. **Hardcoded "0 resep tersimpan"** — Profile Screen subtitle is a literal hardcoded string, not computed from any data.
4. **Hardcoded "Guest User"** — no dynamic user name.

### Hardcoded Values
- `AppConstants.baseUrl = 'http://10.0.2.2:8000'` — hardcoded for Android emulator; physical devices require manual IP change.
- `AppConstants.quickIngredients` — fixed list of 12 popular ingredients.
- BM25 parameters `k1=1.2`, `b=0.75` — in `config.py`.
- Relevance thresholds (`RELEVANCE_HIGHLY=8.0`, `RELEVANCE_RELEVANT=5.0`, `RELEVANCE_MODERATE=2.0`, `RELEVANCE_PARTIAL=0.5`) — in `config.py`.
- Default popular ingredients suggestion list (`["ayam", "bawang merah", ...]`) in `search.py` — returned when `q` is empty.
- Evaluation `_defaultQueries` and `_defaultRelevantIds` — in `evaluation_screen.dart`.
- Pagination in Admin uses hardcoded `pageSize=30`.
- CORS `ALLOWED_ORIGINS` includes `"*"` — wide-open in development.

### Future Improvements (Based on Code Comments / Stubs)
- Implement real manual annotation for evaluation ground truth.
- Add real user authentication and personalized saved recipes.
- Add search history UI panel.
- Add Create/Update recipe forms in Admin.
- Add `fl_chart` line chart for daily search trends.
- Add iOS support (`ios/` folder configuration).
- Add filter controls directly on the Search Screen (pre-search filtering).
- Consider persisting BM25 index to disk to avoid rebuild on restart.
- Replace `"*"` in CORS with specific allowed origins for production.
