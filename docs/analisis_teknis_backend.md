# Dokumentasi Teknis Backend — Smart Recipe Planner
### Analisis untuk Penelitian: Implementasi dan Perbandingan Algoritma BM25 dan TF-IDF

> **Dibuat oleh:** Analisis Otomatis Kode Sumber  
> **Tanggal:** 25 Juli 2026  
> **Status:** Berdasarkan implementasi nyata — tidak ada asumsi

---

## 1. INVENTARISASI STRUKTUR PROJECT

```
smart_recipe2/
│
├── backend/
│   ├── Dockerfile                            ← Konfigurasi Docker
│   ├── requirements.txt                      ← Dependensi Python
│   ├── install_log.txt                       ← Log instalasi (non-kode)
│   │
│   ├── data/
│   │   ├── recipes.csv                       ← Dataset awal (105 resep)
│   │   ├── recipes_final_3000_standardized.csv ← Dataset utama (~3000 resep)
│   │   ├── srp.db                            ← Database SQLite aktif
│   │   └── srp backup.db                     ← Backup database
│   │
│   └── app/
│       ├── __init__.py
│       ├── main.py                           ← Entry point FastAPI
│       │
│       ├── core/                             ← [ENGINES & CONFIG]
│       │   ├── __init__.py
│       │   ├── config.py                     ← Konfigurasi aplikasi (Settings)
│       │   ├── bm25_engine.py                ← Engine BM25 (Okapi BM25)
│       │   └── preprocessor.py              ← Pipeline NLP Preprocessing
│       │
│       ├── database/                         ← [DATABASE]
│       │   ├── __init__.py
│       │   ├── db.py                         ← Koneksi SQLAlchemy + session
│       │   └── seed.py                       ← Seeder CSV → SQLite
│       │
│       ├── models/                           ← [ORM MODELS]
│       │   ├── __init__.py
│       │   ├── recipe.py                     ← Model tabel recipes
│       │   ├── search_log.py                 ← Model tabel search_logs
│       │   └── evaluation.py                 ← Model tabel evaluation_results
│       │
│       ├── schemas/                          ← [PYDANTIC SCHEMAS]
│       │   ├── __init__.py
│       │   ├── recipe.py                     ← Schema request/response Recipe
│       │   ├── search.py                     ← Schema request/response Search
│       │   └── evaluation.py                 ← Schema request/response Evaluation
│       │
│       └── api/
│           └── routes/                       ← [API ROUTERS]
│               ├── __init__.py
│               ├── search.py                 ← POST /api/search (BM25 endpoint utama)
│               ├── recipes.py                ← GET /api/recipes, /stats
│               ├── evaluation.py             ← POST /api/evaluation/run (BM25 vs TF-IDF)
│               └── admin.py                  ← CRUD Admin + CSV Upload
│
├── docs/
│   ├── API_SPEC.md                           ← Spesifikasi API
│   ├── ERD.md                               ← Entity Relationship Diagram
│   ├── UML.md                               ← Diagram UML
│   └── technical_documentation.md           ← Dokumentasi teknis awal
│
├── frontend/                                 ← Flutter mobile app (bukan fokus penelitian)
├── docker-compose.yml                        ← Orkestrasi Docker
└── README.md
```

**Klasifikasi Komponen:**

| Kategori | File |
|---|---|
| **Configuration** | `core/config.py`, `requirements.txt`, `Dockerfile`, `docker-compose.yml` |
| **Database** | `database/db.py`, `database/seed.py`, `data/srp.db` |
| **Models (ORM)** | `models/recipe.py`, `models/search_log.py`, `models/evaluation.py` |
| **Routers / API** | `api/routes/search.py`, `api/routes/recipes.py`, `api/routes/evaluation.py`, `api/routes/admin.py` |
| **Schemas** | `schemas/recipe.py`, `schemas/search.py`, `schemas/evaluation.py` |
| **Engines (IR Core)** | `core/bm25_engine.py` |
| **Utilities (NLP)** | `core/preprocessor.py` |
| **Evaluation** | `api/routes/evaluation.py` (TF-IDF + BM25 comparison logic inline) |
| **Main Application** | `app/main.py` |
| **Dataset** | `data/recipes_final_3000_standardized.csv` |

---

## 2. IDENTIFIKASI MODUL

### 2.1 `app/main.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/main.py` |
| **Fungsi** | Entry point aplikasi FastAPI. Mengelola lifecycle (startup/shutdown), inisialisasi database, seeding otomatis jika DB kosong, dan pembangunan BM25 index saat startup. |
| **Hubungan Penelitian** | **Kritis** — Urutan startup menentukan kapan corpus BM25 dibangun. BM25 index di-build sekali saat startup dari seluruh data resep di database. |

**Urutan Startup yang Diimplementasikan:**
1. `init_db()` — Buat tabel jika belum ada
2. Cek jumlah resep; jika 0 → `seed_database()`
3. Ambil semua resep dari DB → panggil `bm25_engine.initialize(recipe_dicts)`

---

### 2.2 `app/core/bm25_engine.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/core/bm25_engine.py` |
| **Fungsi** | Implementasi Okapi BM25 sebagai search engine utama. Membangun dua index (dengan dan tanpa stemming), melakukan pencarian, menghitung match ingredient, dan memberikan label relevansi. |
| **Hubungan Penelitian** | **Inti penelitian** — Implementasi BM25 yang dianalisis dan dibandingkan. |

**Parameter BM25:**
- `k1 = 1.2` (term frequency saturation)
- `b = 0.75` (document length normalization)

**Komponen dalam file:**
- `class RecipeDoc` — Dataclass representasi dokumen resep di memori
- `class BM25Result` — Dataclass hasil pencarian BM25
- `class BM25Engine` — Kelas utama engine BM25 (Singleton Pattern)
  - `initialize(recipes)` — Membangun dua BM25 index (stemmed + non-stemmed)
  - `search(ingredients, top_k, filters, apply_stemming)` — Pencarian utama
  - `get_scores_raw(query_text)` — Skor mentah untuk evaluasi
  - `get_top_ids(query_text, k)` — Top-K ID resep untuk evaluasi
  - `get_all_ingredient_names()` — Autocomplete bahan
  - `_match_ingredients(query_ingredients, doc)` — Hitung overlap bahan
  - `_relevance_label(score)` — Label relevansi berdasarkan threshold skor

**Threshold Relevansi (dari config):**
| Label | Threshold Skor |
|---|---|
| Highly Relevant (⭐⭐⭐⭐⭐) | score ≥ 8.0 |
| Relevant (⭐⭐⭐⭐) | score ≥ 5.0 |
| Moderate (⭐⭐⭐) | score ≥ 2.0 |
| Partial (⭐⭐) | score ≥ 0.5 |
| Low (⭐) | score < 0.5 |

---

### 2.3 `app/core/preprocessor.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/core/preprocessor.py` |
| **Fungsi** | Pipeline NLP Preprocessing untuk BM25 dan TF-IDF. Mencakup: case folding, tokenisasi, stopword removal (NLTK + custom), dan stemming (Sastrawi). |
| **Hubungan Penelitian** | **Kritis** — Tahapan preprocessing adalah bagian utama yang diteliti dan dibandingkan. |

**Fungsi-fungsi yang diimplementasikan:**
| Fungsi | Keterangan |
|---|---|
| `case_fold(text)` | Lowercase + strip whitespace |
| `tokenize(text)` | Regex `[a-z0-9]+` — ekstrak token alfanumerik |
| `remove_stopwords(tokens)` | Filter menggunakan gabungan NLTK stopwords + custom culinary stopwords |
| `stem_tokens(tokens)` | Sastrawi IndonesianStemmer (singleton via `@lru_cache`) |
| `preprocess(text, apply_stemming)` | Pipeline penuh (case fold → tokenize → stopword → stem) |
| `preprocess_ingredients_list(text)` | Parse teks bahan menjadi daftar nama bahan (hapus satuan ukuran) |
| `build_document(title, ingredients, instructions, apply_stemming)` | Bangun dokumen BM25 dengan **pembobotan field**: title×3, ingredients×2, instructions×1 |

**Catatan penting:** `preprocess_ingredients_list()` menggunakan regex untuk menghapus satuan ukuran (gram, kg, ml, sdm, sdt, siung, lembar, batang, buah, dst.) sebelum tokenisasi.

---

### 2.4 `app/core/config.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/core/config.py` |
| **Fungsi** | Konfigurasi terpusat menggunakan Pydantic Settings. Mendefinisikan parameter BM25, path database, path dataset, threshold relevansi, dan CORS. |
| **Hubungan Penelitian** | Menyimpan parameter eksperimen (k1, b, threshold relevansi). |

---

### 2.5 `app/database/db.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/database/db.py` |
| **Fungsi** | Setup koneksi SQLite menggunakan SQLAlchemy async (aiosqlite). Menyediakan engine, session factory, dependency injection `get_db()`, dan fungsi `init_db()`. |
| **Hubungan Penelitian** | Corpus resep disimpan di SQLite dan diambil untuk membangun BM25 index. |

---

### 2.6 `app/database/seed.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/database/seed.py` |
| **Fungsi** | Membaca `recipes_final_3000_standardized.csv` dan mengisi tabel `recipes` di SQLite dalam batch 50 baris. |
| **Hubungan Penelitian** | Menyiapkan corpus resep yang menjadi objek pencarian BM25/TF-IDF. |

---

### 2.7 `app/models/recipe.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/models/recipe.py` |
| **Fungsi** | SQLAlchemy ORM model untuk tabel `recipes`. |
| **Hubungan Penelitian** | Mendefinisikan struktur data corpus resep. |

---

### 2.8 `app/models/search_log.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/models/search_log.py` |
| **Fungsi** | SQLAlchemy ORM model untuk tabel `search_logs`. Mencatat setiap permintaan pencarian beserta query dan jumlah hasil. |
| **Hubungan Penelitian** | Data pencarian yang tersimpan dapat digunakan sebagai dasar evaluasi kualitatif penggunaan sistem. |

---

### 2.9 `app/models/evaluation.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/models/evaluation.py` |
| **Fungsi** | SQLAlchemy ORM model untuk tabel `evaluation_results`. Menyimpan hasil evaluasi (Precision, Recall, F1, P@5, P@10) untuk setiap metode. |
| **Hubungan Penelitian** | **Kritis untuk BAB IV** — Menyimpan data hasil perbandingan BM25 vs TF-IDF. |

---

### 2.10 `app/api/routes/search.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/api/routes/search.py` |
| **Fungsi** | Endpoint utama pencarian resep berbasis BM25. Menerima daftar bahan, memanggil BM25 engine, mencatat ke search_log, dan mengembalikan hasil terurut. |
| **Hubungan Penelitian** | **Inti implementasi** — Titik masuk penelitian IR ke dalam sistem. |

---

### 2.11 `app/api/routes/evaluation.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/api/routes/evaluation.py` |
| **Fungsi** | Endpoint evaluasi komparatif. Menjalankan 3 metode sekaligus (BM25 tanpa stemming, BM25 dengan stemming, TF-IDF dengan stemming) dan menghitung Precision, Recall, F1, P@K. |
| **Hubungan Penelitian** | **Inti evaluasi penelitian** — Menghasilkan data perbandingan yang menjadi bukti BAB IV. |

---

### 2.12 `app/api/routes/recipes.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/api/routes/recipes.py` |
| **Fungsi** | Endpoint CRUD publik untuk data resep (list, detail, popular, statistik dataset). |
| **Hubungan Penelitian** | Mendukung tampilan aplikasi, bukan inti IR. Statistik dataset relevan untuk BAB III (deskripsi dataset). |

---

### 2.13 `app/api/routes/admin.py`
| Atribut | Detail |
|---|---|
| **Lokasi** | `backend/app/api/routes/admin.py` |
| **Fungsi** | Endpoint admin: upload CSV (dengan rebuild BM25 index otomatis), CRUD resep, dan analytics pencarian. |
| **Hubungan Penelitian** | Upload CSV + rebuild index menunjukkan kemampuan pembaruan corpus. |

---

## 3. ANALISIS DATABASE

### 3.1 Database yang Digunakan
- **Jenis:** SQLite
- **Library:** SQLAlchemy 2.0 (Async) + aiosqlite
- **Path:** `backend/data/srp.db`
- **Mode Koneksi:** Asynchronous (aiosqlite)

---

### 3.2 Tabel dan Kolom

#### Tabel: `recipes`
| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY, INDEX | Auto increment |
| `title` | VARCHAR(255) | NOT NULL, INDEX | Judul resep |
| `ingredients` | TEXT | NOT NULL | Daftar bahan (teks bebas, delimiter koma/newline) |
| `instructions` | TEXT | NOT NULL | Langkah memasak |
| `category` | VARCHAR(50) | NOT NULL, DEFAULT 'Goreng' | Kategori: Goreng/Rebus/Tumis/Panggang |
| `image_url` | TEXT | NULLABLE | URL gambar resep |
| `cooking_time` | INTEGER | NULLABLE | Waktu memasak (dalam menit) |
| `difficulty` | VARCHAR(20) | NULLABLE, DEFAULT 'Medium' | Tingkat kesulitan: Easy/Medium/Hard |
| `created_at` | DATETIME | DEFAULT utcnow | Waktu data dibuat |

#### Tabel: `search_logs`
| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY, INDEX | Auto increment |
| `query` | TEXT | NOT NULL | Query mentah (string bahan digabung) |
| `ingredients` | TEXT | NOT NULL, DEFAULT '[]' | Bahan dalam JSON array |
| `results_count` | INTEGER | DEFAULT 0 | Jumlah hasil yang ditemukan |
| `top_result_id` | INTEGER | FK → recipes.id, NULLABLE | ID resep teratas dari hasil pencarian |
| `timestamp` | DATETIME | DEFAULT utcnow, INDEX | Waktu pencarian |

#### Tabel: `evaluation_results`
| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY, INDEX | Auto increment |
| `method` | VARCHAR(100) | NOT NULL | Nama metode: "BM25 tanpa Stemming", "BM25 dengan Stemming", "TF-IDF dengan Stemming" |
| `precision` | FLOAT | DEFAULT 0.0 | Precision rata-rata |
| `recall` | FLOAT | DEFAULT 0.0 | Recall rata-rata |
| `precision_at_5` | FLOAT | DEFAULT 0.0 | Precision@5 |
| `precision_at_10` | FLOAT | DEFAULT 0.0 | Precision@10 |
| `f1_score` | FLOAT | DEFAULT 0.0 | F1-Score rata-rata |
| `query_set` | TEXT | DEFAULT '[]' | JSON list query yang digunakan |
| `created_at` | DATETIME | DEFAULT utcnow | Waktu evaluasi dijalankan |

---

### 3.3 Relasi Antar Tabel

```
recipes (id) ←──── search_logs (top_result_id)   [1 : Many, FK]
```

- `evaluation_results` **tidak berelasi** secara FK dengan tabel lain.
- Semua relasi lain bersifat independen.

---

### 3.4 Dataset CSV

| File | Deskripsi |
|---|---|
| `recipes.csv` | Dataset awal, 105 baris, kolom: title, ingredients, instructions, category, image_url, cooking_time, difficulty |
| `recipes_final_3000_standardized.csv` | Dataset utama (~3000 resep), format kolom identik, digunakan saat seed produksi |

---

## 4. ANALISIS API ENDPOINT

### 4.1 System Endpoints

| Method | Endpoint | Input | Output | Fungsi |
|---|---|---|---|---|
| GET | `/` | — | JSON: app name, version, docs URL | Root info |
| GET | `/health` | — | JSON: status, version, bm25_ready, recipe_count | Health check + status BM25 |

---

### 4.2 Search Endpoints (Prefix: `/api/search`)

| Method | Endpoint | Input | Output | Fungsi |
|---|---|---|---|---|
| POST | `/api/search` | Body JSON: `{ingredients[], filters{}, top_k}` | `SearchResponse` (query, total_found, results[], processing_steps) | **Pencarian resep BM25 utama** |
| GET | `/api/search/suggestions` | Query param: `q` (string) | `{suggestions[]}` | Autocomplete nama bahan |

**Detail `POST /api/search`:**
- `ingredients`: list[str], min 1, max 20 bahan
- `filters.category`: Goreng/Rebus/Tumis/Panggang (opsional)
- `filters.max_cooking_time`: integer menit (opsional)
- `filters.difficulty`: Easy/Medium/Hard (opsional)
- `filters.sort_by`: bm25 / alphabetical / cooking_time (default: bm25)
- `top_k`: 1–100 (default: 20)

**Setiap item hasil pencarian mengandung:**
- `bm25_score`: Skor BM25 (float)
- `match_percentage`: Persentase bahan yang ditemukan (%)
- `matched_ingredients`: Bahan yang cocok
- `missing_ingredients`: Bahan yang tidak ditemukan
- `rank`: Peringkat hasil
- `relevance_stars`: 1–5
- `relevance_label`: Highly Relevant / Relevant / Moderate / Partial / Low

---

### 4.3 Recipe Endpoints (Prefix: `/api/recipes`)

| Method | Endpoint | Input | Output | Fungsi |
|---|---|---|---|---|
| GET | `/api/recipes` | Query: page, page_size, category, search | `RecipeListOut` (items[], total, page, page_size) | Daftar resep paginasi |
| GET | `/api/recipes/popular` | Query: limit (default 10) | `list[RecipeOut]` | Resep paling sering muncul sebagai top result |
| GET | `/api/recipes/{id}` | Path param: recipe_id | `RecipeOut` | Detail satu resep |
| GET | `/api/stats` | — | `DatasetStatsOut` | Statistik dataset: total resep, bahan unik, total pencarian, per-kategori |

---

### 4.4 Admin Endpoints (Prefix: `/api/admin`)

| Method | Endpoint | Input | Output | Fungsi |
|---|---|---|---|---|
| POST | `/api/admin/upload` | Form: file (CSV) | JSON: message, total | Upload CSV → hapus semua resep → import → rebuild BM25 index |
| GET | `/api/admin/recipes` | Query: page, page_size (max 200) | `RecipeListOut` | Daftar semua resep untuk admin |
| POST | `/api/admin/recipes` | Body JSON: `RecipeCreate` | `RecipeOut` | Tambah resep baru + rebuild index |
| PUT | `/api/admin/recipes/{id}` | Body JSON: `RecipeUpdate` | `RecipeOut` | Update resep + rebuild index |
| DELETE | `/api/admin/recipes/{id}` | Path param: recipe_id | JSON: message | Hapus resep + rebuild index |
| GET | `/api/admin/analytics` | — | JSON: top_ingredients, daily_searches, total_searches, total_recipes | Analitik pencarian 7 hari terakhir |

---

### 4.5 Evaluation Endpoints (Prefix: `/api/evaluation`)

| Method | Endpoint | Input | Output | Fungsi |
|---|---|---|---|---|
| POST | `/api/evaluation/run` | Body JSON: `{queries[], relevant_recipe_ids{}, k_values[]}` | `EvaluationRunResponse` (results[], queries_used[], timestamp) | Jalankan evaluasi komparatif BM25 vs TF-IDF |
| GET | `/api/evaluation/results` | Query: limit (default 30) | `list[EvaluationResultOut]` | Ambil riwayat hasil evaluasi dari DB |

---

## 5. ANALISIS DATA FLOW

### 5.1 Alur Startup (saat server dinyalakan)

```
[Server Start]
      │
      ▼
  init_db()
  (Buat tabel SQLite jika belum ada)
      │
      ▼
  Hitung jumlah resep di DB
      │
  ┌───┴───────────────────┐
  │ count == 0?           │
  │ Ya                    │ Tidak
  ▼                       ▼
seed_database()     Lanjut ke index
(Baca CSV →         
 INSERT batch 50)   
  └───────────┬───────────┘
              ▼
  SELECT * FROM recipes
              │
              ▼
  bm25_engine.initialize(recipe_dicts)
  (Preprocessing semua dokumen
   → Bangun BM25Okapi index stemmed
   → Bangun BM25Okapi index no-stem)
              │
              ▼
  [Server Ready — index di memori]
```

---

### 5.2 Alur Pencarian Resep (Flow Utama Penelitian)

```
[Pengguna]
    │ Masukkan bahan-bahan
    ▼
[Flutter Mobile App]
    │ HTTP POST /api/search
    │ Body: {ingredients: ["ayam", "bawang merah"], top_k: 20}
    ▼
[FastAPI — search.py]
    │ Validasi input (Pydantic)
    │ Cek bm25_engine.is_ready
    ▼
[BM25Engine.search()]
    │ 1. Gabung ingredients → query_text
    │ 2. preprocess(query_text, apply_stemming=True)
    │    → case_fold → tokenize → remove_stopwords → stem_tokens
    │ 3. bm25_stemmed.get_scores(query_tokens)
    │    → Skor BM25 untuk SETIAP dokumen dalam corpus
    │ 4. Filter: score > 0 saja
    │ 5. Apply filters (category, cooking_time, difficulty)
    │ 6. _match_ingredients() → matched, missing
    │ 7. _relevance_label() → stars, label
    │ 8. Sort by bm25_score DESC
    │ 9. Ambil top_k
    │ 10. Assign rank (1, 2, 3, ...)
    ▼
[FastAPI — search.py]
    │ Log ke search_logs (INSERT)
    │ Bangun processing_steps (list string deskripsi)
    ▼
[JSON Response]
    │ {query, total_found, results[], processing_steps}
    ▼
[Flutter Mobile App]
    │ Tampilkan daftar resep terurut berdasarkan skor BM25
    ▼
[Pengguna melihat hasil]
```

---

### 5.3 Alur Evaluasi Komparatif (Flow Penelitian)

```
[Peneliti]
    │ Menyiapkan: queries[], relevant_recipe_ids{}, k_values[]
    ▼
[HTTP POST /api/evaluation/run]
    │
    ▼
[evaluation.py route]
    │ Ambil semua resep dari DB → corpus_docs[]
    │ Buat id_to_idx, idx_to_id mapping
    │
    ├──── Metode 1: BM25 tanpa Stemming ────────────────────────────┐
    │     Untuk setiap query:                                        │
    │       bm25_engine.get_top_ids(query, k, apply_stemming=False) │
    │     _compute_metrics(retrieved_ids, relevant_ids, k_values)   │
    │     Simpan ke evaluation_results DB                           │
    │                                                                │
    ├──── Metode 2: BM25 dengan Stemming ───────────────────────────┤
    │     Untuk setiap query:                                        │
    │       bm25_engine.get_top_ids(query, k, apply_stemming=True)  │
    │     _compute_metrics(retrieved_ids, relevant_ids, k_values)   │
    │     Simpan ke evaluation_results DB                           │
    │                                                                │
    └──── Metode 3: TF-IDF dengan Stemming ─────────────────────────┘
          Untuk setiap query:
            _tfidf_search(corpus_docs, query, apply_stemming=True)
              → preprocess setiap doc + query
              → TfidfVectorizer().fit_transform(docs)
              → cosine_similarity(query_vec, tfidf_matrix)
              → sort by score → return top_k indices
          _compute_metrics(retrieved_ids, relevant_ids, k_values)
          Simpan ke evaluation_results DB
              │
              ▼
      JSON Response: [{method, precision, recall, p@5, p@10, f1}×3]
```

---

## 6. ANALISIS INFORMATION RETRIEVAL

### 6.1 Pembentukan Corpus

1. Dataset resep dibaca dari `recipes_final_3000_standardized.csv`
2. Dimasukkan ke tabel `recipes` SQLite (oleh `seed.py`)
3. Saat startup, semua resep diambil dari DB
4. Setiap resep direpresentasikan sebagai `RecipeDoc` (dataclass in-memory)
5. Dokumen BM25 dibangun via `build_document()` dengan **pembobotan field**:
   - **Title**: diulang 3× (bobot tertinggi)
   - **Ingredients**: diulang 2× (bobot menengah)
   - **Instructions**: 1× (bobot terendah)

### 6.2 Dua Index BM25 yang Dibangun

| Index | Variabel | Preprocessing |
|---|---|---|
| Stemmed | `_bm25_stemmed` | case fold → tokenize → stopword → **stem** |
| Non-stemmed | `_bm25_no_stem` | case fold → tokenize → stopword (tanpa stem) |

### 6.3 Formula BM25 yang Digunakan

Library: `rank-bm25==0.2.2` → `BM25Okapi`

Formula Okapi BM25:

```
               IDF(qi) × f(qi,D) × (k1 + 1)
score(D,Q) = Σ ─────────────────────────────────────────────────
                f(qi,D) + k1 × (1 - b + b × |D|/avgdl)
```

Dengan:
- `k1 = 1.2` (dikonfigurasi di `config.py`)
- `b = 0.75` (dikonfigurasi di `config.py`)
- `f(qi,D)` = frekuensi term qi dalam dokumen D
- `|D|` = panjang dokumen (jumlah token)
- `avgdl` = rata-rata panjang dokumen dalam corpus

### 6.4 Pemrosesan Query (BM25)

```
Input: ["ayam", "bawang merah"]
    │
    ▼ Gabung → "ayam bawang merah"
    │
    ▼ case_fold() → "ayam bawang merah"
    │
    ▼ tokenize() → ["ayam", "bawang", "merah"]
    │
    ▼ remove_stopwords() → ["ayam", "bawang", "merah"] (tidak ada stopword)
    │
    ▼ stem_tokens() (Sastrawi) → ["ayam", "bawang", "merah"]
    │
    ▼ bm25_stemmed.get_scores(tokens) → [0.0, 8.52, 3.1, 0.0, ...]
    │ (satu skor untuk setiap dokumen dalam corpus)
    │
    ▼ Filter score > 0
    ▼ Urutkan DESC
    ▼ Ambil top_k
Output: daftar resep terurut berdasarkan relevansi BM25
```

### 6.5 Pemrosesan Query (TF-IDF — hanya untuk evaluasi)

```
Input: query string
    │
    ▼ preprocess(doc, apply_stemming=True) untuk setiap dokumen corpus
    │ preprocess(query, apply_stemming=True)
    │
    ▼ TfidfVectorizer().fit_transform(processed_docs) → TF-IDF matrix
    │ vectorizer.transform([processed_query]) → query vector
    │
    ▼ cosine_similarity(query_vec, tfidf_matrix) → skor per dokumen
    │
    ▼ argsort()[::-1][:top_k] → top index
    │
    ▼ Map index → recipe_id
Output: list[int] recipe IDs
```

**Catatan penting:** TF-IDF hanya digunakan di `evaluation.py` untuk tujuan perbandingan. TF-IDF **tidak digunakan** di endpoint pencarian utama (`POST /api/search`).

### 6.6 Perhitungan Ranking

Setelah scoring BM25:
1. Filter dokumen dengan skor > 0
2. Terapkan filter kategori/waktu/kesulitan
3. Hitung ingredient match (overlap berbasis stemmed tokens)
4. Beri label relevansi (1–5 bintang berdasarkan threshold skor)
5. Sort berdasarkan `sort_by` parameter (default: `bm25_score` DESC)
6. Potong ke `top_k`
7. Assign rank (1, 2, 3, ...)

---

## 7. ANALISIS PREPROCESSING

### 7.1 Library yang Digunakan

| Library | Versi | Kegunaan |
|---|---|---|
| `PySastrawi` | 1.2.1 | Stemming Bahasa Indonesia |
| `nltk` | 3.8.1 | Stopwords Bahasa Indonesia |

### 7.2 Tahapan Preprocessing (Urutan Implementasi)

```
Teks Input
    │
    ▼ [1] CASE FOLDING
    │   text.lower().strip()
    │   Fungsi: case_fold()
    │
    ▼ [2] TOKENIZATION
    │   re.compile(r"[a-z0-9]+").findall(text)
    │   Fungsi: tokenize()
    │   → Memecah teks pada karakter non-alfanumerik
    │   → Hanya token huruf/angka yang dipertahankan
    │
    ▼ [3] STOPWORD REMOVAL
    │   Filter token TIDAK ada di STOPWORDS set
    │   Fungsi: remove_stopwords()
    │   Sumber stopwords:
    │   • NLTK Indonesian stopwords (otomatis diunduh)
    │   • Custom culinary stopwords (hardcoded 50+ kata)
    │     (masak, cara, resep, bumbu, tambahkan, aduk,
    │      panaskan, goreng, tumis, rebus, dll.)
    │   • Juga filter token panjang ≤ 1 karakter
    │
    ▼ [4] STEMMING (opsional — apply_stemming=True)
    │   Sastrawi IndonesianStemmer
    │   Fungsi: stem_tokens()
    │   Implementasi: singleton via @lru_cache(maxsize=1)
    │   Contoh: "menggoreng" → "goreng"
    │           "bawang" → "bawang"
    │           "dimasak" → "masak" (kemudian dihapus stopword culinary)
    │
    ▼ Output: List[str] token preprocessed
```

### 7.3 Preprocessing Khusus untuk Bahan (Corpus)

Fungsi `preprocess_ingredients_list()` melakukan langkah tambahan:
- Split berdasarkan delimiter: `,`, `\n`, `;`, `|`
- Hapus satuan ukuran via regex:
  - `gram`, `gr`, `kg`, `ml`, `liter`, `l`
  - `sdm`, `sdt`, `butir`, `siung`, `lembar`, `batang`
  - `buah`, `potong`, `iris`, `genggam`, `sachet`, `bungkus`
  - `sendok`, `cup`, `cangkir`
- Hapus angka kuantitas di awal

### 7.4 Pembobotan Dokumen dalam BM25

Fungsi `build_document()` menggabungkan field resep dengan **pengulangan token** sebagai pembobotan implisit:

```python
title_tokens      × 3  # Judul paling penting
ingredient_tokens × 2  # Bahan lebih penting dari instruksi
instruction_tokens× 1  # Instruksi bobot standar
```

---

## 8. ANALISIS EVALUATION

### 8.1 Status Implementasi

| Metrik | Status |
|---|---|
| **Precision** | ✅ Diimplementasikan (`evaluation.py`) |
| **Recall** | ✅ Diimplementasikan (`evaluation.py`) |
| **F1-Score** | ✅ Diimplementasikan (`evaluation.py`) |
| **Precision@5 (P@5)** | ✅ Diimplementasikan (`evaluation.py`) |
| **Precision@10 (P@10)** | ✅ Diimplementasikan (`evaluation.py`) |
| **MAP (Mean Average Precision)** | ❌ Tidak ditemukan pada implementasi saat ini |
| **NDCG** | ❌ Tidak ditemukan pada implementasi saat ini |
| **MRR (Mean Reciprocal Rank)** | ❌ Tidak ditemukan pada implementasi saat ini |

### 8.2 Metode yang Dibandingkan

| Metode | Stemming | Engine | Konfigurasi |
|---|---|---|---|
| BM25 tanpa Stemming | ❌ | BM25Okapi | k1=1.2, b=0.75 |
| BM25 dengan Stemming | ✅ Sastrawi | BM25Okapi | k1=1.2, b=0.75 |
| TF-IDF dengan Stemming | ✅ Sastrawi | sklearn TfidfVectorizer + cosine similarity | default sklearn |

### 8.3 Formula Evaluasi yang Diimplementasikan

```
Untuk setiap query:
  TP = |retrieved ∩ relevant|
  Precision = TP / |retrieved|
  Recall    = TP / |relevant|
  F1        = 2 × P × R / (P + R)

Precision@K:
  TP@K = |retrieved[:K] ∩ relevant|
  P@K  = TP@K / K

Semua metrik: rata-rata (mean) atas semua query
```

### 8.4 Cara Menggunakan Evaluation

Input yang dibutuhkan peneliti:
```json
{
  "queries": ["ayam bawang merah", "tempe tahu goreng"],
  "relevant_recipe_ids": {
    "ayam bawang merah": [1, 2, 5, 10, 15],
    "tempe tahu goreng": [4, 13, 29, 45]
  },
  "k_values": [5, 10]
}
```
→ `relevant_recipe_ids` harus ditentukan secara manual oleh peneliti (ground truth)

---

## 9. INVENTARISASI DEPENDENCY

### 9.1 Core Framework
| Library | Versi | Fungsi |
|---|---|---|
| `fastapi` | 0.111.0 | Web framework async (API server) |
| `uvicorn[standard]` | 0.30.1 | ASGI server untuk FastAPI |
| `starlette` | 0.37.2 | Foundation untuk FastAPI (CORS middleware) |

### 9.2 Information Retrieval & NLP
| Library | Versi | Fungsi |
|---|---|---|
| `rank-bm25` | 0.2.2 | Implementasi BM25Okapi |
| `nltk` | 3.8.1 | Indonesian stopwords |
| `PySastrawi` | 1.2.1 | Indonesian stemmer (Sastrawi) |
| `scikit-learn` | 1.5.0 | TfidfVectorizer + cosine_similarity (evaluasi) |

### 9.3 Database
| Library | Versi | Fungsi |
|---|---|---|
| `sqlalchemy` | 2.0.30 | ORM async |
| `aiosqlite` | 0.20.0 | SQLite async driver |
| `alembic` | 1.13.1 | Database migration (terpasang, belum digunakan) |

### 9.4 Data Processing
| Library | Versi | Fungsi |
|---|---|---|
| `pandas` | 2.2.2 | Terpasang, tidak digunakan langsung di kode utama* |
| `numpy` | 1.26.4 | Operasi array (digunakan di `_compute_metrics`) |

> *pandas ada di requirements.txt tapi tidak di-import pada kode yang diperiksa; kemungkinan digunakan saat eksplorasi data atau skrip terpisah.

### 9.5 HTTP & Utilities
| Library | Versi | Fungsi |
|---|---|---|
| `python-multipart` | 0.0.9 | Parsing form-data (file upload CSV) |
| `python-dotenv` | 1.0.1 | Baca .env file |
| `httpx` | 0.27.0 | HTTP client async (testing) |
| `aiofiles` | 23.2.1 | Terpasang, tidak terlihat digunakan di kode utama |
| `Pillow` | 10.3.0 | Terpasang, tidak terlihat digunakan di kode utama |

### 9.6 Validation & Serialization
| Library | Versi | Fungsi |
|---|---|---|
| `pydantic` | 2.7.1 | Validasi request/response schema |
| `pydantic-settings` | 2.3.1 | Konfigurasi via environment variables |

### 9.7 Testing
| Library | Versi | Fungsi |
|---|---|---|
| `pytest` | 8.2.2 | Testing framework |
| `pytest-asyncio` | 0.23.7 | Async test support |

---

## 10. BLUEPRINT TEKNIS

### A. Arsitektur Sistem (High Level)

```
┌─────────────────────────────────────────────────────┐
│                   SISTEM SMART RECIPE PLANNER        │
│                                                       │
│   ┌──────────────┐         ┌──────────────────────┐  │
│   │   Flutter    │ ◄──────►│     FastAPI Backend   │  │
│   │ Mobile App   │  HTTP   │    (port 8000)        │  │
│   │  (Android)   │  REST   │                       │  │
│   └──────────────┘         └──────────┬───────────┘  │
│                                        │              │
│                             ┌──────────▼───────────┐  │
│                             │     SQLite Database   │  │
│                             │     (srp.db)          │  │
│                             └──────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

### B. Arsitektur Backend (Detail Layer)

```
┌─────────────────────────────────────────────────────────────┐
│                     FastAPI Application                      │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    API Layer                          │   │
│  │  /api/search   /api/recipes  /api/admin  /api/eval   │   │
│  └────────────┬────────────────────────────────────────┘   │
│               │                                             │
│  ┌────────────▼────────────────────────────────────────┐   │
│  │                   Core / Engine Layer                 │   │
│  │                                                       │   │
│  │   ┌──────────────────┐   ┌──────────────────────┐   │   │
│  │   │   BM25Engine     │   │   Preprocessor        │   │   │
│  │   │  (bm25_engine.py)│   │  (preprocessor.py)    │   │   │
│  │   │                  │   │                       │   │   │
│  │   │ • BM25Okapi      │   │ • Case Folding        │   │   │
│  │   │   (stemmed)      │◄──┤ • Tokenization        │   │   │
│  │   │ • BM25Okapi      │   │ • Stopword Removal    │   │   │
│  │   │   (no-stem)      │   │ • Sastrawi Stemming   │   │   │
│  │   │ • RecipeDoc[]    │   └──────────────────────┘   │   │
│  │   └──────────────────┘                               │   │
│  │                                                       │   │
│  │   ┌──────────────────────────────────────────────┐   │   │
│  │   │        TF-IDF (sklearn) — Evaluasi Only       │   │   │
│  │   │  TfidfVectorizer + cosine_similarity          │   │   │
│  │   └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│               │                                             │
│  ┌────────────▼────────────────────────────────────────┐   │
│  │                   Database Layer                      │   │
│  │                                                       │   │
│  │   SQLAlchemy Async + aiosqlite                       │   │
│  │   ┌──────────┐ ┌──────────────┐ ┌──────────────┐   │   │
│  │   │ recipes  │ │ search_logs  │ │evaluation    │   │   │
│  │   │ table    │ │ table        │ │_results table│   │   │
│  │   └──────────┘ └──────────────┘ └──────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

### C. Diagram Data Flow (Pencarian)

```
Pengguna
   │ Input bahan: ["ayam", "bawang merah", "kecap"]
   ▼
Flutter App
   │ POST /api/search
   │ {ingredients: [...], top_k: 20}
   ▼
FastAPI Routes (search.py)
   │ Validasi Pydantic
   │ Cek bm25_engine.is_ready
   ▼
BM25Engine.search()
   │
   ├─ preprocess(query_text, apply_stemming=True)
   │   ├─ case_fold()     → "ayam bawang merah kecap"
   │   ├─ tokenize()      → ["ayam", "bawang", "merah", "kecap"]
   │   ├─ remove_stopwords() → (filter)
   │   └─ stem_tokens()   → stemmed tokens
   │
   ├─ BM25Okapi.get_scores(query_tokens)
   │   → scores[0..N-1] — N = jumlah resep dalam corpus
   │
   ├─ Filter: score > 0
   ├─ Apply category/time/difficulty filters
   ├─ _match_ingredients() → matched[], missing[]
   ├─ _relevance_label()   → stars, label
   ├─ sort by bm25_score DESC
   └─ slice [:top_k], assign rank
   ▼
FastAPI Routes (search.py)
   │ INSERT INTO search_logs
   ▼
JSON Response
   │ {query, total_found, results[{recipe_id, title, bm25_score,
   │  match_percentage, matched_ingredients, missing_ingredients,
   │  rank, relevance_stars, relevance_label, ...}],
   │  processing_steps}
   ▼
Flutter App
   │ Tampilkan hasil terurut
   ▼
Pengguna melihat resep yang relevan
```

---

### D. Diagram Information Retrieval

```
INDEXING PHASE (saat startup)
══════════════════════════════════════════════════════════════

     Dataset CSV (3000 resep)
           │
           ▼ seed_database()
       SQLite DB
           │
           ▼ SELECT * FROM recipes
     Recipe records
           │
           ▼ Untuk setiap resep:
     ┌─────────────────────────────────┐
     │   build_document(               │
     │     title, ingredients,         │
     │     instructions,               │
     │     apply_stemming=True/False)  │
     │                                 │
     │   case_fold → tokenize →        │
     │   stopword_remove → stem        │
     │                                 │
     │   title_tokens × 3              │
     │   ingredient_tokens × 2         │
     │   instruction_tokens × 1        │
     └─────────────┬───────────────────┘
                   │
         ┌─────────┴─────────┐
         ▼                   ▼
   BM25Okapi(stemmed)   BM25Okapi(no-stem)
   [di memori]          [di memori]

══════════════════════════════════════════════════════════════
RETRIEVAL PHASE (saat pencarian)
══════════════════════════════════════════════════════════════

     Query: ["ayam", "bawang merah"]
           │
           ▼ preprocess(apply_stemming=True)
     query_tokens = ["ayam", "bawang", "merah"]
           │
           ▼ BM25Okapi.get_scores(query_tokens)
     scores[0..N-1] = [0.0, 8.52, 0.0, 3.1, 1.2, ...]
           │
           ▼ Ranking
     Sorted: [(idx=1, 8.52), (idx=3, 3.1), (idx=4, 1.2), ...]
           │
           ▼ Map idx → RecipeDoc → BM25Result
     Results: [{recipe_id, title, bm25_score, rank, ...}]
```

---

### E. Diagram Hubungan Antar Modul

```
                    ┌─────────────┐
                    │   main.py   │
                    │  (Startup)  │
                    └──────┬──────┘
                           │ import
         ┌─────────────────┼──────────────────────┐
         ▼                 ▼                      ▼
  ┌────────────┐   ┌──────────────┐    ┌──────────────────┐
  │  database/ │   │    core/     │    │   api/routes/    │
  │    db.py   │   │  config.py   │    │  search.py       │
  │   seed.py  │   │              │    │  recipes.py      │
  └─────┬──────┘   └──────────────┘    │  admin.py        │
        │                │              │  evaluation.py   │
        │           ┌────┴────┐         └────────┬─────────┘
        │           │  core/  │                  │
        ▼           │bm25_    │◄─────────────────┘
  ┌──────────┐      │engine.py│    (semua routes import
  │ models/  │      └────┬────┘     bm25_engine singleton)
  │recipe.py │           │
  │search_   │      ┌────▼────────┐
  │ log.py   │      │   core/     │
  │evaluation│      │preprocessor │
  │  .py     │      │    .py      │
  └──────────┘      └─────────────┘
       ▲                  ▲
       │                  │
  ┌────┴──────────────────┴────┐
  │        schemas/            │
  │  recipe.py  search.py      │
  │  evaluation.py             │
  └────────────────────────────┘
```

---

## 11. MAPPING KE PENELITIAN

| Modul | BAB III — Perancangan | BAB IV — Implementasi & Hasil |
|---|---|---|
| **`config.py`** | Desain Konfigurasi Sistem; Parameter BM25 (k1=1.2, b=0.75) | Implementasi Parameter Penelitian |
| **`preprocessor.py`** | Desain Pipeline Preprocessing (NLP); Tahapan: case folding, tokenisasi, stopword removal, stemming | Implementasi Preprocessing; Penjelasan Sastrawi & NLTK |
| **`bm25_engine.py`** | Desain Algoritma BM25 Okapi; Formula matematika; Pembobotan dokumen; Threshold relevansi | Implementasi BM25; Hasil pencarian; Analisis skor |
| **Dataset CSV** (`recipes_final_3000_standardized.csv`) | Desain dan Deskripsi Dataset; Jumlah data, kolom, distribusi kategori | Persiapan Data; Statistik Corpus |
| **`database/db.py` + `seed.py`** | Desain Basis Data; ERD tabel `recipes`, `search_logs`, `evaluation_results` | Implementasi Basis Data SQLite; Proses seeding |
| **`models/recipe.py`** | Desain Struktur Data Corpus Resep | Implementasi Model ORM |
| **`models/evaluation.py`** | Desain Skema Penyimpanan Hasil Evaluasi | Implementasi Tabel Evaluasi |
| **`api/routes/search.py`** | Desain API Endpoint Pencarian; Desain Alur Data | Implementasi Endpoint; Log pencarian |
| **`api/routes/evaluation.py`** (fungsi `_tfidf_search`, `_compute_metrics`) | Desain Metode Evaluasi IR; Formula Precision, Recall, F1, P@K; Desain Perbandingan BM25 vs TF-IDF | Implementasi Evaluasi Komparatif; **Tabel Hasil Perbandingan BM25 vs TF-IDF** (data utama BAB IV) |
| **`api/routes/admin.py`** | Desain Modul Manajemen Data | Implementasi Upload Dataset & CRUD |
| **`api/routes/recipes.py`** | Desain API Publik Resep | Implementasi Endpoint Resep |
| **`main.py`** (lifespan) | Desain Arsitektur Startup; Alur Inisialisasi Index | Implementasi Startup; Build Index BM25 |

---

## 12. LAPORAN AKHIR

### 12.1 Komponen Backend yang Sudah Tersedia ✅

| Komponen | Keterangan |
|---|---|
| API Server | FastAPI async, berjalan di port 8000 |
| Database | SQLite async (aiosqlite + SQLAlchemy) |
| ORM Models | `recipes`, `search_logs`, `evaluation_results` |
| Corpus Dataset | `recipes_final_3000_standardized.csv` (~3000 resep) |
| BM25 Engine | `BM25Okapi` dari `rank-bm25`, dua index (stemmed + no-stem) |
| Preprocessing Pipeline | Case folding, tokenisasi, stopword removal (NLTK + custom), Sastrawi stemming |
| Field Weighting | Title×3, Ingredients×2, Instructions×1 |
| Relevance Labeling | 5 level (Highly Relevant → Low) berdasarkan skor |
| Ingredient Match | Hitung matched/missing ingredients per query |
| Pencarian Utama | `POST /api/search` dengan filter dan sorting |
| Autocomplete | `GET /api/search/suggestions` |
| Search Logging | Otomatis log setiap pencarian ke `search_logs` |
| TF-IDF (Evaluasi) | `sklearn TfidfVectorizer` + `cosine_similarity` |
| Modul Evaluasi | `POST /api/evaluation/run` — 3 metode sekaligus |
| Metrik Evaluasi | Precision, Recall, F1, Precision@5, Precision@10 |
| Penyimpanan Hasil Evaluasi | Tabel `evaluation_results` di SQLite |
| Docker | Dockerfile + docker-compose.yml |
| Dokumentasi API | OpenAPI (Swagger UI `/docs`, ReDoc `/redoc`) |

---

### 12.2 Komponen yang Belum Ada / Perlu Diperhatikan ⚠️

| Komponen | Status |
|---|---|
| Ground truth / relevant_recipe_ids | **Peneliti harus menyiapkan secara manual** (tidak ada di kode) |
| MAP (Mean Average Precision) | ❌ Tidak diimplementasikan |
| NDCG (Normalized Discounted Cumulative Gain) | ❌ Tidak diimplementasikan |
| MRR (Mean Reciprocal Rank) | ❌ Tidak diimplementasikan |
| Alembic migrations | Terpasang tapi tidak digunakan — tabel dibuat via `create_all()` |
| Autentikasi admin | Belum ada (disebutkan di API_SPEC sebagai "None, development") |
| pandas (di requirements.txt) | Terpasang tapi tidak terlihat digunakan di kode produksi |
| aiofiles, Pillow | Terpasang tapi tidak terlihat digunakan di kode yang dianalisis |

---

### 12.3 Komponen yang Tidak Digunakan (Terdaftar di Requirements tapi Tidak Ditemukan di Kode)

| Library | Status |
|---|---|
| `alembic` | Terpasang, tidak digunakan — migration dilakukan via `Base.metadata.create_all()` |
| `pandas` | Terpasang, tidak di-import di kode yang diperiksa |
| `aiofiles` | Terpasang, tidak di-import di kode yang diperiksa |
| `Pillow` | Terpasang, tidak di-import di kode yang diperiksa |

---

### 12.4 Komponen yang Harus Dijelaskan di BAB III

1. **Arsitektur Sistem** — FastAPI + SQLite + Flutter
2. **Desain Basis Data** — 3 tabel, ERD, relasi
3. **Desain Dataset** — Struktur CSV, kolom, jumlah data
4. **Desain Algoritma BM25** — Formula Okapi BM25, parameter k1 & b
5. **Desain Pipeline Preprocessing** — Urutan 4 tahap + library
6. **Desain Pembobotan Dokumen** — Field weighting (title×3, ingredients×2)
7. **Desain Metode Evaluasi** — Precision, Recall, F1, P@K
8. **Desain Perbandingan** — BM25 tanpa stemming vs BM25 dengan stemming vs TF-IDF
9. **Desain API** — Endpoint utama dan alur data
10. **Desain Corpus** — Bagaimana dokumen BM25 dibentuk dari resep

---

### 12.5 Komponen yang Menjadi Bukti Implementasi di BAB IV

1. **Listing Kode** `preprocessor.py` — Bukti implementasi preprocessing 4 tahap
2. **Listing Kode** `bm25_engine.py` — Bukti implementasi BM25 Okapi
3. **Listing Kode** `evaluation.py` (fungsi `_tfidf_search`, `_compute_metrics`) — Bukti implementasi TF-IDF & evaluasi
4. **Tabel dari `evaluation_results`** — Hasil eksperimen perbandingan (data utama BAB IV)
5. **Screenshot** aplikasi Flutter menampilkan hasil pencarian BM25
6. **Screenshot** respons JSON endpoint `/api/search` dengan skor BM25
7. **Screenshot** respons JSON endpoint `/api/evaluation/run` dengan perbandingan 3 metode
8. **Statistik dataset** dari `/api/stats` — total resep, bahan unik, kategori
9. **Log Processing Steps** yang dikembalikan API — bukti urutan preprocessing

---

*Dokumentasi ini dibuat berdasarkan analisis kode sumber yang ada. Tidak ada asumsi — seluruh informasi berdasarkan implementasi nyata.*
