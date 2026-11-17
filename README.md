# Smart Recipe Planner (SRP)

> Implementasi Okapi BM25 untuk Pencarian Resep Berbasis Bahan Makanan
> Academic Information Retrieval Project

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Material Design 3) |
| Backend | FastAPI (Python 3.11) |
| Search Engine | Okapi BM25 (`rank-bm25`, k1=1.2, b=0.75) |
| NLP Pipeline | Case Folding → Tokenization → Stopword Removal → Sastrawi Stemming |
| Database | SQLite (dev) / PostgreSQL (prod) |
| State Management | Riverpod |
| Navigation | go_router |

---

## Project Structure

```
smart_recipe2/
├── backend/               # FastAPI + BM25 Engine
│   ├── app/
│   │   ├── main.py        # Application entry point
│   │   ├── core/
│   │   │   ├── bm25_engine.py   # ★ Core BM25 search engine
│   │   │   ├── preprocessor.py  # NLP pipeline
│   │   │   └── config.py
│   │   ├── api/routes/
│   │   │   ├── search.py        # POST /api/search
│   │   │   ├── recipes.py       # GET /api/recipes
│   │   │   ├── admin.py         # Admin CRUD + CSV upload
│   │   │   └── evaluation.py    # IR evaluation comparison
│   │   ├── models/              # SQLAlchemy ORM models
│   │   ├── schemas/             # Pydantic schemas
│   │   └── database/            # DB + seeder
│   ├── data/
│   │   └── recipes.csv          # 100 Indonesian recipes
│   └── requirements.txt
├── frontend/              # Flutter Android App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/theme/           # Material Design 3 theme
│   │   ├── app/router/          # go_router config
│   │   ├── core/api/            # Dio HTTP client
│   │   ├── features/
│   │   │   ├── splash/          # Animated splash screen
│   │   │   ├── home/            # Home with search + stats
│   │   │   ├── search/          # Ingredient input + loading
│   │   │   ├── results/         # BM25 ranked results
│   │   │   ├── detail/          # Recipe detail + explainability
│   │   │   ├── evaluation/      # IR metrics dashboard
│   │   │   └── admin/           # Admin CRUD dashboard
│   │   └── shared/              # Models, providers, widgets
│   └── pubspec.yaml
├── docs/
│   ├── ERD.md             # Database entity diagram
│   ├── UML.md             # Class + sequence diagrams
│   └── API_SPEC.md        # REST API specification
└── docker-compose.yml
```

---

## Quick Start

### 1. Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Seed database (auto-runs on first startup too)
python -m app.database.seed

# Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open **http://localhost:8000/docs** for interactive Swagger UI.

### 2. Flutter App

```bash
cd frontend

# Get dependencies
flutter pub get

# Run on emulator (make sure backend is running)
flutter run

# Build APK
flutter build apk --release
```

> **Note:** The app uses `http://10.0.2.2:8000` (Android emulator → host machine).
> For physical device, change `baseUrl` in `lib/core/constants/app_constants.dart` to your computer's IP.

---

## BM25 Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| k1 | 1.2 | Term frequency saturation |
| b | 0.75 | Document length normalization |

### Field Weighting
| Field | Weight | Rationale |
|-------|--------|-----------|
| Title | ×3 | Most discriminative |
| Ingredients | ×2 | Core search field |
| Instructions | ×1 | Supporting context |

---

## Preprocessing Pipeline

```
Raw Text
  → Case Folding (lowercase)
  → Tokenization (regex [a-z0-9]+)
  → Stopword Removal (NLTK Indonesian + 60 custom culinary stopwords)
  → Sastrawi Stemming (IndonesianStemmer)
  → BM25 Token List
```

---

## IR Evaluation

The Evaluation Dashboard compares 3 methods:

| Method | Stemming |
|--------|----------|
| BM25 | ✗ |
| BM25 | ✓ (Sastrawi) |
| TF-IDF | ✓ (Sastrawi) |

Metrics: **Precision**, **Recall**, **P@5**, **P@10**, **F1**

---

## Screens

1. **Splash** — Gradient background, animated logo, BM25 badge
2. **Home** — Search box, quick chips, popular recipes, stats
3. **Search** — Ingredient input, autocomplete, chip management
4. **Loading** — Step-by-step BM25 pipeline animation
5. **Results** — BM25 score cards, match %, relevance stars, filters
6. **Detail** — Hero image, explainability, ingredients, instructions
7. **Evaluation** — Metrics table, bar chart comparison
8. **Admin** — CSV upload, CRUD, analytics

---

## Academic Context

**Research Title:** Implementasi Okapi BM25 pada Smart Recipe Planner untuk Pencarian Resep Berbasis Bahan Makanan

**Focus Areas:** Information Retrieval, BM25 Ranking, Recipe Search, Document Ranking, Search Evaluation
