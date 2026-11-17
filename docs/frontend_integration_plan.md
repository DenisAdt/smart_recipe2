# Frontend–Backend Integration Plan
### Smart Recipe Planner — Analisis & Roadmap Integrasi Mobile

> **Basis Analisis:** Kode sumber backend (`FastAPI`) + kode sumber frontend (`Flutter/Dart`)  
> **Tanggal:** 26 Juli 2026  
> **Metodologi:** Analisis statis kode — tidak ada asumsi, tidak ada perubahan kode

---

## BAGIAN 1 — KATALOG API ENDPOINT BACKEND

Semua endpoint dikonfirmasi dari source code backend. Base URL: `http://10.0.2.2:8000/api`

---

### EP-01: `POST /api/search`
| Field | Detail |
|---|---|
| **URL** | `/api/search` |
| **Method** | POST |
| **Tujuan** | Pencarian resep berbasis BM25. Menerima daftar bahan, mengembalikan resep terurut berdasarkan skor relevansi |
| **Request Body** | `{"ingredients": ["ayam", "bawang merah"], "filters": {"category": "Goreng", "max_cooking_time": 30, "difficulty": "Easy", "sort_by": "bm25"}, "top_k": 20}` |
| **Request Params** | Tidak ada query params — semua via body |
| **Response JSON** | `{"query": str, "ingredients": [str], "total_found": int, "results": [SearchResultItem], "processing_steps": [str]}` |
| **Status Codes** | 200 OK, 400 Bad Request (tidak ada bahan), 503 Service Unavailable (BM25 belum ready) |
| **Halaman yang Menggunakan** | Search Screen (trigger), Results Screen (konsumen data) |

**SearchResultItem fields:**
```
recipe_id, title, category, image_url, cooking_time, difficulty,
bm25_score, match_percentage, matched_ingredients, missing_ingredients,
matched_count, total_query_count, rank, relevance_stars, relevance_label
```

---

### EP-02: `GET /api/search/suggestions`
| Field | Detail |
|---|---|
| **URL** | `/api/search/suggestions` |
| **Method** | GET |
| **Tujuan** | Autocomplete nama bahan saat pengguna mengetik |
| **Request Params** | `?q=string` (query string pencarian bahan) |
| **Request Body** | Tidak ada |
| **Response JSON** | `{"suggestions": ["bawang merah", "bawang putih", ...]}` |
| **Status Codes** | 200 OK (selalu, termasuk array kosong) |
| **Halaman yang Menggunakan** | Search Screen |

---

### EP-03: `GET /api/recipes`
| Field | Detail |
|---|---|
| **URL** | `/api/recipes` |
| **Method** | GET |
| **Tujuan** | Daftar resep paginasi dengan filter kategori dan text search |
| **Request Params** | `?page=1&page_size=20&category=Goreng&search=ayam` |
| **Request Body** | Tidak ada |
| **Response JSON** | `{"items": [RecipeOut], "total": int, "page": int, "page_size": int}` |
| **Status Codes** | 200 OK |
| **Halaman yang Menggunakan** | Admin Screen (tab Recipes) |

---

### EP-04: `GET /api/recipes/popular`
| Field | Detail |
|---|---|
| **URL** | `/api/recipes/popular` |
| **Method** | GET |
| **Tujuan** | Resep paling sering muncul sebagai top BM25 result (berdasarkan join search_logs) |
| **Request Params** | `?limit=10` |
| **Request Body** | Tidak ada |
| **Response JSON** | `[RecipeOut, ...]` (array langsung) |
| **Status Codes** | 200 OK |
| **Halaman yang Menggunakan** | Home Screen (section "Resep Populer") |

---

### EP-05: `GET /api/recipes/{id}`
| Field | Detail |
|---|---|
| **URL** | `/api/recipes/{recipe_id}` |
| **Method** | GET |
| **Tujuan** | Mengambil detail lengkap satu resep berdasarkan ID |
| **Request Params** | Path parameter: `recipe_id` (integer) |
| **Request Body** | Tidak ada |
| **Response JSON** | `{"id", "title", "ingredients", "instructions", "category", "image_url", "cooking_time", "difficulty", "created_at"}` |
| **Status Codes** | 200 OK, 404 Not Found |
| **Halaman yang Menggunakan** | Detail Screen |

---

### EP-06: `GET /api/stats`
| Field | Detail |
|---|---|
| **URL** | `/api/stats` |
| **Method** | GET |
| **Tujuan** | Statistik dataset: jumlah resep, bahan unik, total pencarian, distribusi per kategori |
| **Request Params** | Tidak ada |
| **Request Body** | Tidak ada |
| **Response JSON** | `{"total_recipes": int, "unique_ingredients": int, "total_searches": int, "categories": {"Goreng": int, ...}}` |
| **Status Codes** | 200 OK |
| **Halaman yang Menggunakan** | Home Screen (section "Statistik Dataset") |

---

### EP-07: `POST /api/evaluation/run`
| Field | Detail |
|---|---|
| **URL** | `/api/evaluation/run` |
| **Method** | POST |
| **Tujuan** | Menjalankan evaluasi komparatif 3 metode: BM25 tanpa stemming, BM25 dengan stemming, TF-IDF dengan stemming |
| **Request Body** | `{"queries": [str], "relevant_recipe_ids": {"query": [int]}, "k_values": [5, 10]}` |
| **Request Params** | Tidak ada |
| **Response JSON** | `{"results": [MethodMetrics], "queries_used": [str], "timestamp": str}` |
| **Status Codes** | 200 OK, 503 Service Unavailable |
| **Halaman yang Menggunakan** | Evaluation Screen |

**MethodMetrics fields:**
```
method, precision, recall, precision_at_5, precision_at_10, f1_score
```

---

### EP-08: `GET /api/evaluation/results`
| Field | Detail |
|---|---|
| **URL** | `/api/evaluation/results` |
| **Method** | GET |
| **Tujuan** | Mengambil riwayat hasil evaluasi dari database |
| **Request Params** | `?limit=30` |
| **Request Body** | Tidak ada |
| **Response JSON** | `[{id, method, precision, recall, precision_at_5, precision_at_10, f1_score, created_at}, ...]` |
| **Status Codes** | 200 OK |
| **Halaman yang Menggunakan** | Evaluation Screen (riwayat evaluasi) |

---

### EP-09: `POST /api/admin/upload`
| Field | Detail |
|---|---|
| **URL** | `/api/admin/upload` |
| **Method** | POST |
| **Tujuan** | Upload file CSV untuk mengganti seluruh dataset resep dan rebuild BM25 index |
| **Request Body** | Form-data: `file` (binary CSV) |
| **Request Params** | Tidak ada |
| **Response JSON** | `{"message": str, "total": int}` |
| **Status Codes** | 200 OK, 400 Bad Request (bukan CSV / kolom tidak lengkap) |
| **Halaman yang Menggunakan** | Admin Screen (tab Upload) |

---

### EP-10: `GET /api/admin/recipes`
| Field | Detail |
|---|---|
| **URL** | `/api/admin/recipes` |
| **Method** | GET |
| **Tujuan** | Daftar semua resep untuk kebutuhan admin (page size lebih besar, s/d 200) |
| **Request Params** | `?page=1&page_size=50` |
| **Request Body** | Tidak ada |
| **Response JSON** | `{"items": [RecipeOut], "total": int, "page": int, "page_size": int}` |
| **Status Codes** | 200 OK |
| **Halaman yang Menggunakan** | Admin Screen (tab Recipes) — **Note: saat ini admin_screen.dart menggunakan `/api/recipes` bukan `/api/admin/recipes`** |

---

### EP-11: `POST /api/admin/recipes`
| Field | Detail |
|---|---|
| **URL** | `/api/admin/recipes` |
| **Method** | POST |
| **Tujuan** | Tambah satu resep baru + rebuild BM25 index otomatis |
| **Request Body** | `{"title", "ingredients", "instructions", "category", "image_url", "cooking_time", "difficulty"}` |
| **Request Params** | Tidak ada |
| **Response JSON** | RecipeOut |
| **Status Codes** | 201 Created |
| **Halaman yang Menggunakan** | **Tidak ada halaman frontend yang menggunakan endpoint ini saat ini** |

---

### EP-12: `PUT /api/admin/recipes/{id}`
| Field | Detail |
|---|---|
| **URL** | `/api/admin/recipes/{recipe_id}` |
| **Method** | PUT |
| **Tujuan** | Update data resep + rebuild BM25 index |
| **Request Params** | Path: `recipe_id` |
| **Request Body** | Partial update: semua field opsional |
| **Response JSON** | RecipeOut |
| **Status Codes** | 200 OK, 404 Not Found |
| **Halaman yang Menggunakan** | **Tidak ada halaman frontend yang menggunakan endpoint ini saat ini** |

---

### EP-13: `DELETE /api/admin/recipes/{id}`
| Field | Detail |
|---|---|
| **URL** | `/api/admin/recipes/{recipe_id}` |
| **Method** | DELETE |
| **Tujuan** | Hapus resep + rebuild BM25 index |
| **Request Params** | Path: `recipe_id` |
| **Request Body** | Tidak ada |
| **Response JSON** | `{"message": str}` |
| **Status Codes** | 200 OK, 404 Not Found |
| **Halaman yang Menggunakan** | Admin Screen (fungsi `_deleteRecipe`) — melalui `ApiClient.deleteRecipe()` |

---

### EP-14: `GET /api/admin/analytics`
| Field | Detail |
|---|---|
| **URL** | `/api/admin/analytics` |
| **Method** | GET |
| **Tujuan** | Analitik pencarian 7 hari terakhir: top bahan, daily search count, total |
| **Request Params** | Tidak ada |
| **Request Body** | Tidak ada |
| **Response JSON** | `{"total_recipes": int, "total_searches": int, "top_ingredients": [{ingredient, count}], "daily_searches": [{date, count}]}` |
| **Status Codes** | 200 OK |
| **Halaman yang Menggunakan** | Admin Screen (tab Analytics) |

---

### EP-15: `GET /health`
| Field | Detail |
|---|---|
| **URL** | `/health` (bukan di bawah `/api`) |
| **Method** | GET |
| **Tujuan** | Health check — status server dan BM25 engine |
| **Request Params** | Tidak ada |
| **Request Body** | Tidak ada |
| **Response JSON** | `{"status": "ok", "version": str, "bm25_ready": bool, "recipe_count": int}` |
| **Status Codes** | 200 OK |
| **Halaman yang Menggunakan** | **Tidak ada halaman frontend yang menggunakan endpoint ini** |

---

## BAGIAN 2 — PEMETAAN ENDPOINT KE HALAMAN

### 2.1 Splash Screen (`/`)
| Item | Detail |
|---|---|
| **File** | `features/splash/splash_screen.dart` |
| **Endpoint yang Dipanggil** | **Tidak ada** |
| **Kapan Dipanggil** | — |
| **Data yang Diterima** | — |
| **Komponen UI** | Loading animation (3 dots pulse), status text cycle, app logo |
| **Perilaku** | Setelah 4.2 detik animasi selesai → `context.go('/home')` |
| **Catatan** | Splash murni UI, tidak ada API call. Semua loading message ("Loading recipe database...") bersifat kosmetik |

---

### 2.2 Home Screen (`/home`)
| Item | Detail |
|---|---|
| **File** | `features/home/home_screen.dart` |
| **Endpoint yang Dipanggil** | EP-04 `GET /api/recipes/popular`, EP-06 `GET /api/stats` |
| **Kapan Dipanggil** | Saat widget build (via Riverpod `FutureProvider`) — otomatis saat halaman dibuka |
| **Data yang Diterima** | Popular recipes list, dataset stats |
| **Komponen UI yang Mengonsumsi Data** | |

`popularAsync` → Section "Resep Populer":
- Kartu resep horizontal scroll (image, title, cooking time)
- `CachedNetworkImage` untuk gambar
- Tap kartu → navigate ke `/detail/{id}`
- Shimmer saat loading

`statsAsync` → Section "Statistik Dataset":
- 3 stat card: Total Resep, Bahan Unik, Total Pencarian

**Data tidak dikonsumsi langsung dari API:** Quick Ingredient Chips (hardcoded di `AppConstants.quickIngredients`), Header greeting (berdasarkan `DateTime.now()`), Daily Recommendation banner (static UI)

---

### 2.3 Search Screen (`/search`)
| Item | Detail |
|---|---|
| **File** | `features/search/search_screen.dart` |
| **Endpoint yang Dipanggil** | EP-02 `GET /api/search/suggestions`, EP-01 `POST /api/search` |
| **Kapan Dipanggil** | Suggestions: saat pengguna mengetik teks (debounce via Riverpod `FutureProvider.family`). Search: saat tombol "Cari Resep" ditekan |
| **Data yang Diterima** | Suggestions list, SearchResponse |
| **Komponen UI yang Mengonsumsi Data** | |

`suggestions` → Dropdown list di bawah input field (max 15 suggestion)

`searchResponse` → Tidak ditampilkan di halaman ini; setelah berhasil → `context.go('/results', extra: {...})` meneruskan hasil ke ResultsScreen

**Data hardcoded (bukan dari API):** Quick Add Chips (12 bahan populer di dalam `search_screen.dart`)

**Loading Dialog:** `_SearchLoadingDialog` — 7 langkah animasi disinkronkan dengan `searchProvider.currentStep` (murni UI, tidak memanggil API tambahan)

---

### 2.4 Results Screen (`/results`)
| Item | Detail |
|---|---|
| **File** | `features/results/results_screen.dart` |
| **Endpoint yang Dipanggil** | **Tidak ada API call baru** |
| **Data yang Diterima** | Data diteruskan via `GoRouter extra`: `ingredients[]`, `results[]`, `totalFound` |
| **Kapan Dipanggil** | Data diterima saat navigate dari SearchScreen |
| **Komponen UI yang Mengonsumsi Data** | |

`results[]` (List<SearchResult>) dikonsumsi oleh:
- Header: menampilkan jumlah hasil dan bahan yang dicari
- Filter chips: Semua/Goreng/Rebus/Tumis/Panggang (filter lokal, tidak memanggil API)
- Sort chips: BM25 Relevansi / Alphabetical / Waktu Masak (sort lokal)
- Daftar kartu resep: title, category, image, cooking time, difficulty, bm25_score, match_percentage, matched_ingredients, missing_ingredients, relevance_stars, relevance_label, rank
- Tap kartu → `/detail/{recipe_id}` dengan `extra: {searchResult: item}`

**Catatan penting:** Filtering dan sorting di halaman ini dilakukan **secara lokal** pada data yang sudah ada, bukan re-call API.

---

### 2.5 Detail Screen (`/detail/:id`)
| Item | Detail |
|---|---|
| **File** | `features/detail/detail_screen.dart` |
| **Endpoint yang Dipanggil** | EP-05 `GET /api/recipes/{id}` |
| **Kapan Dipanggil** | Saat halaman dibuka (via `recipeDetailProvider(recipeId)` yang merupakan `FutureProvider.family`) |
| **Data yang Diterima** | `Recipe` object: id, title, ingredients, instructions, category, image_url, cooking_time, difficulty, created_at |
| **Komponen UI yang Mengonsumsi Data** | |

`Recipe` → Dikonsumsi oleh:
- Hero image (`CachedNetworkImage`)
- Title, category badge, difficulty badge, cooking time
- Ingredient list (via `recipe.ingredientList`)
- Instruction steps (via `recipe.instructionSteps`)
- Shimmer saat loading

**Data opsional dari SearchResult (via router extra):**
- BM25 score card, match percentage, matched/missing ingredients
- Ditampilkan jika datang dari hasil pencarian, disembunyikan jika dari Home

---

### 2.6 Evaluation Screen (`/evaluation`)
| Item | Detail |
|---|---|
| **File** | `features/evaluation/evaluation_screen.dart` |
| **Endpoint yang Dipanggil** | EP-08 `GET /api/evaluation/results` (saat initState), EP-07 `POST /api/evaluation/run` (saat tombol Run ditekan) |
| **Kapan Dipanggil** | GET: otomatis saat halaman dibuka. POST: saat pengguna menekan tombol "Run Evaluation" |
| **Data yang Diterima** | EvaluationRunResult, history list |
| **Komponen UI yang Mengonsumsi Data** | |

`EvaluationRunResult` → Dikonsumsi oleh:
- Tabel komparasi 3 metode (BM25 tanpa Stemming, BM25 dengan Stemming, TF-IDF dengan Stemming)
- Bar chart (fl_chart): Precision, Recall, F1, P@5, P@10 per metode
- Queries used list

`history` (dari GET) → Riwayat evaluasi sebelumnya (tabel history)

**Data hardcoded (bukan dari API):**
- `_defaultQueries`: 8 query test set akademik (hardcoded di file)
- `_defaultRelevantIds`: Ground truth manual (hardcoded di file)

**Akses:** Halaman ini diakses via Profile Screen → "Evaluation" menu item, atau langsung via `/evaluation`

---

### 2.7 Profile Screen (`/profile`)
| Item | Detail |
|---|---|
| **File** | `features/profile/profile_screen.dart` |
| **Endpoint yang Dipanggil** | **Tidak ada** |
| **Data yang Diterima** | — |
| **Komponen UI** | Avatar (ikon statis), nama "Guest User" (hardcoded), menu navigasi |
| **Navigasi dari halaman ini** | My Recipes (`/my-recipes`), Evaluation (`/evaluation`), Admin Dashboard (`/admin`) |

---

### 2.8 Admin Screen (`/admin`)
| Item | Detail |
|---|---|
| **File** | `features/admin/admin_screen.dart` |
| **Endpoint yang Dipanggil** | EP-14 `GET /api/admin/analytics`, EP-03 `GET /api/recipes`, EP-09 `POST /api/admin/upload`, EP-13 `DELETE /api/admin/recipes/{id}` |
| **Kapan Dipanggil** | Analytics & Recipes: `initState()`. Upload: saat file dipilih. Delete: saat konfirmasi hapus |
| **Tab:** | 3 tab: Dataset (Upload), Recipes (List), Analytics (Charts) |
| **Komponen UI** | Bar chart analitik, daftar resep dengan delete button, CSV upload button |

---

### 2.9 My Recipes Screen (`/my-recipes`)
| Item | Detail |
|---|---|
| **File** | `features/my_recipes/my_recipes_screen.dart` |
| **Endpoint yang Dipanggil** | **Tidak ada** |
| **Status** | Placeholder page — menampilkan "Belum ada resep tersimpan" |
| **Catatan** | Fitur "simpan resep" belum diimplementasikan di backend maupun frontend |

---

## BAGIAN 3 — API CONTRACT TABLE

| No | Halaman | Endpoint | Method | Tujuan | Status Integrasi |
|---|---|---|---|---|---|
| 1 | Splash | — | — | — | ✅ Tidak perlu API |
| 2 | Home | `GET /api/recipes/popular` | GET | Tampilkan resep populer | ✅ Terintegrasi |
| 3 | Home | `GET /api/stats` | GET | Tampilkan statistik dataset | ✅ Terintegrasi |
| 4 | Search | `GET /api/search/suggestions` | GET | Autocomplete bahan | ✅ Terintegrasi |
| 5 | Search | `POST /api/search` | POST | Cari resep BM25 | ✅ Terintegrasi |
| 6 | Results | — | — | Data dari router extra | ✅ Tidak perlu API baru |
| 7 | Detail | `GET /api/recipes/{id}` | GET | Ambil detail resep | ✅ Terintegrasi |
| 8 | Evaluation | `GET /api/evaluation/results` | GET | Tampilkan riwayat evaluasi | ✅ Terintegrasi |
| 9 | Evaluation | `POST /api/evaluation/run` | POST | Jalankan evaluasi komparatif | ✅ Terintegrasi |
| 10 | Profile | — | — | Navigasi statis | ✅ Tidak perlu API |
| 11 | Admin | `GET /api/admin/analytics` | GET | Tampilkan analitik pencarian | ✅ Terintegrasi |
| 12 | Admin | `GET /api/recipes` | GET | Daftar resep (admin view) | ✅ Terintegrasi |
| 13 | Admin | `POST /api/admin/upload` | POST | Upload CSV dataset | ✅ Terintegrasi |
| 14 | Admin | `DELETE /api/admin/recipes/{id}` | DELETE | Hapus resep + rebuild index | ✅ Terintegrasi |
| 15 | My Recipes | — | — | Placeholder, belum ada API | ⚠️ Belum ada endpoint |
| 16 | — | `GET /health` | GET | Health check | ❌ Tidak digunakan frontend |
| 17 | — | `POST /api/admin/recipes` | POST | Tambah resep manual | ❌ Tidak digunakan frontend |
| 18 | — | `PUT /api/admin/recipes/{id}` | PUT | Edit resep manual | ❌ Tidak digunakan frontend |
| 19 | — | `GET /api/admin/recipes` | GET | Daftar resep (admin route) | ⚠️ Ada tapi tidak dipakai |

---

## BAGIAN 4 — ANALISIS URUTAN INTEGRASI PER HALAMAN

### 4.1 Search Flow (Alur Utama Penelitian)

```
[Search Screen]
    │
    │ Pengguna mengetik nama bahan
    │
    ▼ Trigger: setiap perubahan teks di TextField
GET /api/search/suggestions?q={text}
    │
    │ Response: {"suggestions": ["bawang merah", ...]}
    │ → Dropdown autocomplete ditampilkan
    │
    │ Pengguna memilih/mengetik bahan → _addIngredient()
    │ → Bahan masuk ke ingredientsProvider (Riverpod state)
    │ → Chip tampil di layar
    │
    │ Pengguna tekan "Cari Resep"
    │
    ▼ Trigger: _doSearch()
    │ → Dialog loading muncul (_SearchLoadingDialog)
    │ → searchProvider.notifier.search()
    │
POST /api/search
Body: {ingredients: [...], filters: {...}, top_k: 20}
    │
    │ Response: {query, total_found, results[...], processing_steps}
    │ → SearchResponse.fromJson(data)
    │
    ▼ Navigate ke /results
context.go('/results', extra: {
  'ingredients': ingredients,
  'results': response.results,    ← List<SearchResult>
  'totalFound': response.totalFound
})
    │
[Results Screen]
    │
    │ Menerima data dari router extra
    │ → Tampilkan daftar SearchResult cards
    │ → Filter/sort lokal (tidak re-call API)
    │
    │ Pengguna tap kartu resep
    │
    ▼ Navigate ke /detail/{id}
context.go('/detail/${r.recipeId}', extra: {
  'searchResult': r    ← SearchResult (untuk menampilkan BM25 score)
})
    │
[Detail Screen]
    │
    ▼ Trigger: saat widget build
GET /api/recipes/{recipe_id}
    │
    │ Response: Recipe object lengkap (ingredients, instructions, dll)
    │ → Tampilkan detail resep
    │ → Jika ada searchResult extra → tampilkan BM25 panel
```

---

### 4.2 Home Flow

```
[Home Screen]
    │
    ▼ Trigger: ref.watch(popularRecipesProvider) — saat build
GET /api/recipes/popular?limit=10
    │
    │ Response: [Recipe, ...] ← Resep paling sering jadi top result
    │ → Shimmer selama loading
    │ → Kartu horizontal scroll setelah data tiba
    │
    ▼ Trigger: ref.watch(statsProvider) — saat build (paralel)
GET /api/stats
    │
    │ Response: {total_recipes, unique_ingredients, total_searches, categories}
    │ → 3 stat card di bawah "Statistik Dataset"
    │
    │ Pengguna tap Quick Ingredient chip
    ▼
    │ → ingredientsProvider.clear() + add(chip)
    │ → context.go('/search')   [tidak ada API call]
    │
    │ Pengguna tap kartu resep populer
    ▼
context.go('/detail/${recipe.id}')  → Detail Screen → GET /api/recipes/{id}
```

---

### 4.3 Evaluation Flow

```
[Evaluation Screen]
    │
    ▼ initState()
GET /api/evaluation/results?limit=30
    │
    │ Response: [{id, method, precision, ...}, ...]
    │ → _history ditampilkan sebagai riwayat evaluasi
    │
    │ Pengguna tekan tombol "Run Evaluation"
    │
    ▼ _runEvaluation()
POST /api/evaluation/run
Body: {
  queries: _defaultQueries (8 queries hardcoded),
  relevant_recipe_ids: _defaultRelevantIds (hardcoded),
  k_values: [5, 10]
}
    │
    │ Response: {
    │   results: [
    │     {method: "BM25 tanpa Stemming", precision: 0.62, recall: 0.50, ...},
    │     {method: "BM25 dengan Stemming", precision: 0.75, recall: 0.60, ...},
    │     {method: "TF-IDF dengan Stemming", precision: 0.50, recall: 0.40, ...}
    │   ],
    │   queries_used: [...],
    │   timestamp: "..."
    │ }
    │
    │ → EvaluationRunResult.fromJson(data)
    │ → Bar chart komparasi (fl_chart)
    │ → Tabel metrik
    │ → _loadHistory() dipanggil lagi untuk refresh riwayat
```

---

### 4.4 Admin Flow

```
[Admin Screen] → initState()
    │
    ├─ _loadAnalytics()
    │   ▼
    │  GET /api/admin/analytics
    │   │ → {top_ingredients, daily_searches, total_recipes, total_searches}
    │   │ → Bar chart analitik
    │
    └─ _loadRecipes(page: 1)
        ▼
       GET /api/recipes?page=1&page_size=30
        │ → {items: [Recipe], total}
        │ → Daftar resep dengan tombol Delete

    │ Pengguna tap "Upload CSV"
    ▼
    FilePicker.platform.pickFiles()    [bukan API]
    ▼
   POST /api/admin/upload   (form-data: file)
    │ → {message, total}
    │ → _loadRecipes() + _loadAnalytics() dipanggil ulang

    │ Pengguna tap ikon Delete pada resep
    ▼
   DELETE /api/admin/recipes/{id}
    │ → {message}
    │ → _loadRecipes(page: _currentPage) dipanggil ulang
```

---

## BAGIAN 5 — IDENTIFIKASI TEMUAN

### 5.1 Endpoint yang Missing (Ada di frontend tapi tidak ada di backend)

| Temuan | Detail |
|---|---|
| **Saved Recipes / Favorit** | `MyRecipesScreen` adalah placeholder. Backend tidak memiliki endpoint apapun untuk menyimpan/mengambil resep favorit pengguna. Tidak ada tabel user atau favorites di database. |
| **User Authentication** | `ProfileScreen` menampilkan "Guest User" hardcoded. Tidak ada sistem login/register di backend maupun frontend. |

---

### 5.2 Endpoint yang Tidak Digunakan Frontend

| Endpoint | Alasan Tidak Digunakan |
|---|---|
| `GET /health` | Frontend tidak memanggil endpoint ini. Berguna untuk monitoring server tapi tidak ada integrasi di sisi Flutter. |
| `POST /api/admin/recipes` | Tidak ada form "tambah resep manual" di `AdminScreen`. Hanya ada upload CSV. |
| `PUT /api/admin/recipes/{id}` | Tidak ada form edit resep di `AdminScreen`. Tidak ada tombol Edit. |
| `GET /api/admin/recipes` | Admin screen menggunakan `GET /api/recipes` (public endpoint) bukan `/api/admin/recipes` untuk load daftar resep. |

---

### 5.3 Endpoint Duplikat / Tumpang Tindih

| Situasi | Detail |
|---|---|
| **`GET /api/recipes` vs `GET /api/admin/recipes`** | Kedua endpoint mengembalikan data yang sama (RecipeListOut). Perbedaan hanya di `page_size` max (100 vs 200) dan prefix path. `AdminScreen` menggunakan `/api/recipes` (public route), bukan `/api/admin/recipes` yang seharusnya digunakan untuk admin. Ini adalah duplikasi fungsionalitas. |

---

### 5.4 Endpoint yang Seharusnya Tidak Diekspos ke Frontend

| Endpoint | Risiko | Rekomendasi |
|---|---|---|
| `POST /api/admin/upload` | Upload CSV menghapus **seluruh** database resep dan rebuild index. Tidak ada autentikasi. | Sebaiknya dilindungi dengan API key atau basic auth sebelum produksi. |
| `DELETE /api/admin/recipes/{id}` | Dapat menghapus data corpus tanpa autentikasi. | Sama, perlu proteksi. |
| `POST /api/admin/recipes` | Dapat menambah data sembarangan ke corpus. | Perlu proteksi. |
| `PUT /api/admin/recipes/{id}` | Dapat memodifikasi data corpus. | Perlu proteksi. |

**Catatan:** Berdasarkan `API_SPEC.md` — "Authentication: None (development). Admin endpoints should be protected in production." — masalah ini sudah diketahui dan bersifat by-design untuk environment development.

---

### 5.5 Inkonsistensi yang Ditemukan

| Inkonsistensi | Detail |
|---|---|
| **Admin pakai public endpoint** | `AdminScreen._loadRecipes()` memanggil `ApiClient.getRecipes()` (`/api/recipes`) bukan `ApiClient` method yang menggunakan `/api/admin/recipes`. Ini berarti endpoint admin `/api/admin/recipes` tidak pernah dipanggil oleh frontend. |
| **Ground truth hardcoded** | `EvaluationScreen` menggunakan `_defaultRelevantIds` yang di-hardcode di dalam file Dart. Ini bukan masalah integrasi, tapi perlu dicatat bahwa nilai ini adalah data akademik yang harus dipersiapkan secara manual sebelum evaluasi dijalankan. |
| **`GET /health` tidak terintegrasi** | Splash screen menampilkan pesan loading "Preparing search engine..." tapi tidak benar-benar memanggil `/health` untuk mengecek status BM25. Semua pesan loading bersifat kosmetik. |
| **Filter di Results Screen lokal** | Filter kategori dan sort di `ResultsScreen` dilakukan secara lokal pada data yang sudah ada, bukan dengan memanggil ulang `POST /api/search` dengan filter baru. Ini berarti jika pengguna ingin filter, data yang ditampilkan hanya dari batch awal. |

---

## BAGIAN 6 — FRONTEND INTEGRATION ROADMAP

> Diurutkan berdasarkan prioritas: kepentingan untuk fungsionalitas inti dan penelitian

---

### Phase 1 — Core Search Integration ✅ SUDAH SELESAI
**Prioritas: KRITIS — Ini adalah inti aplikasi dan penelitian**

| Task | Status | File |
|---|---|---|
| `ApiClient.search()` → `POST /api/search` | ✅ Selesai | `api_client.dart` |
| `ApiClient.getSuggestions()` → `GET /api/search/suggestions` | ✅ Selesai | `api_client.dart` |
| `SearchProvider` dengan Riverpod StateNotifier | ✅ Selesai | `search_provider.dart` |
| `IngredientsNotifier` (state bahan) | ✅ Selesai | `search_provider.dart` |
| `SearchScreen` — input, chips, autocomplete | ✅ Selesai | `search_screen.dart` |
| `SearchLoadingDialog` — 7 step animasi | ✅ Selesai | `search_screen.dart` |
| `ResultsScreen` — display BM25 results | ✅ Selesai | `results_screen.dart` |
| `SearchResult` model (`fromJson`) | ✅ Selesai | `models/search_result.dart` |

**Validasi:** Jalankan backend → buka Search Screen → tambah bahan → tap Cari → hasil muncul di Results Screen dengan BM25 score.

---

### Phase 2 — Recipe Detail & Home Integration ✅ SUDAH SELESAI
**Prioritas: TINGGI — UX inti aplikasi**

| Task | Status | File |
|---|---|---|
| `ApiClient.getRecipe(id)` → `GET /api/recipes/{id}` | ✅ Selesai | `api_client.dart` |
| `ApiClient.getPopularRecipes()` → `GET /api/recipes/popular` | ✅ Selesai | `api_client.dart` |
| `ApiClient.getStats()` → `GET /api/stats` | ✅ Selesai | `api_client.dart` |
| `recipeDetailProvider` FutureProvider.family | ✅ Selesai | `recipe_provider.dart` |
| `popularRecipesProvider` FutureProvider | ✅ Selesai | `recipe_provider.dart` |
| `statsProvider` FutureProvider | ✅ Selesai | `recipe_provider.dart` |
| `DetailScreen` — hero image, ingredients, instructions, BM25 panel | ✅ Selesai | `detail_screen.dart` |
| `HomeScreen` — popular cards, stats cards | ✅ Selesai | `home_screen.dart` |
| `Recipe` model (`fromJson`) | ✅ Selesai | `models/recipe.dart` |

**Validasi:** Home menampilkan resep populer dan statistik. Tap resep populer → Detail muncul. Tap resep dari hasil pencarian → Detail menampilkan BM25 score card.

---

### Phase 3 — Evaluation Integration ✅ SUDAH SELESAI
**Prioritas: TINGGI — Inti penelitian perbandingan BM25 vs TF-IDF**

| Task | Status | File |
|---|---|---|
| `ApiClient.runEvaluation()` → `POST /api/evaluation/run` | ✅ Selesai | `api_client.dart` |
| `ApiClient.getEvaluationResults()` → `GET /api/evaluation/results` | ✅ Selesai | `api_client.dart` |
| `EvaluationScreen` — run, chart, history | ✅ Selesai | `evaluation_screen.dart` |
| `EvaluationMethodResult` model | ✅ Selesai | `models/evaluation.dart` |
| Default queries & relevant IDs (ground truth) | ✅ Hardcoded di screen | `evaluation_screen.dart` |
| Bar chart visualisasi (fl_chart) | ✅ Selesai | `evaluation_screen.dart` |

**Catatan penting:** Ground truth (`_defaultRelevantIds`) adalah data akademik yang di-hardcode. Sebelum penelitian final, nilai-nilai ini perlu diverifikasi kebenarannya berdasarkan anotasi manual terhadap dataset yang aktual.

---

### Phase 4 — Admin Integration ✅ SUDAH SELESAI (Parsial)
**Prioritas: MEDIUM — Tools untuk pengelolaan dataset**

| Task | Status | File |
|---|---|---|
| `ApiClient.getAnalytics()` → `GET /api/admin/analytics` | ✅ Selesai | `api_client.dart` |
| `ApiClient.uploadCsv()` → `POST /api/admin/upload` | ✅ Selesai | `api_client.dart` |
| `ApiClient.deleteRecipe(id)` → `DELETE /api/admin/recipes/{id}` | ✅ Selesai | `api_client.dart` |
| `AdminScreen` — 3 tab (Upload, Recipes, Analytics) | ✅ Selesai | `admin_screen.dart` |
| `AdminScreen` menggunakan `/api/recipes` bukan `/api/admin/recipes` | ⚠️ Inkonsistensi | `admin_screen.dart` |
| Tambah Resep (form) → `POST /api/admin/recipes` | ❌ Belum ada UI | — |
| Edit Resep (form) → `PUT /api/admin/recipes/{id}` | ❌ Belum ada UI | — |

---

### Phase 5 — Missing Features (Belum Diimplementasikan)
**Prioritas: RENDAH — Di luar scope penelitian inti**

| Task | Status | Catatan |
|---|---|---|
| **Saved/Favorit Recipes** — Backend endpoint | ❌ Tidak ada | Perlu tabel `favorites` di DB dan endpoint baru |
| **Saved/Favorit Recipes** — Frontend logic | ❌ Placeholder | `MyRecipesScreen` hanya tampilkan empty state |
| **User Authentication** | ❌ Tidak ada | Perlu user management system |
| **Health Check Integration** | ❌ Tidak digunakan | Bisa ditambahkan di Splash untuk validasi backend status |
| **Edit Resep (UI)** | ❌ Tidak ada | Button edit di `AdminScreen` belum ada |
| **Tambah Resep Manual (UI)** | ❌ Tidak ada | Form tambah resep di `AdminScreen` belum ada |
| **Re-search dengan Filter** | ⚠️ Lokal saja | Perlu call API ulang dengan filter baru untuk hasil lebih akurat |

---

## RINGKASAN EKSEKUTIF

### Status Integrasi Saat Ini

| Phase | Fitur | Status |
|---|---|---|
| Phase 1 | Core Search (BM25) | ✅ **100% Terintegrasi** |
| Phase 2 | Recipe Detail & Home | ✅ **100% Terintegrasi** |
| Phase 3 | Evaluation (BM25 vs TF-IDF) | ✅ **100% Terintegrasi** |
| Phase 4 | Admin Tools | ✅ **70% Terintegrasi** (add/edit belum ada UI) |
| Phase 5 | Fitur Tambahan | ❌ **0% — Di luar scope penelitian** |

### Kesimpulan

**Semua fitur yang relevan dengan penelitian Information Retrieval sudah terintegrasi:**
- Pencarian BM25 ✅
- Tampilan skor BM25 ✅  
- Pipeline preprocessing ✅ (ditampilkan via processing_steps)
- Evaluasi komparatif BM25 vs TF-IDF ✅
- Metrik Precision, Recall, F1, P@5, P@10 ✅
- Visualisasi hasil evaluasi ✅

**Yang belum terintegrasi tidak berdampak pada penelitian:**
- Saved recipes (fitur user UX, bukan IR)
- Authentication (bukan scope penelitian)
- Edit/tambah resep manual (admin utility)

---

*Dokumen ini dibuat berdasarkan analisis statis kode sumber. Tidak ada perubahan kode yang dilakukan.*
