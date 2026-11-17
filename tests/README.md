# Cara Menjalankan Test Suite Smart Recipe Planner QA

Semua test suite sudah siap di folder ini. Berikut panduan lengkap cara menjalankannya.

---

## Prasyarat

Backend FastAPI harus sudah berjalan terlebih dahulu. Jalankan dari root project:

```powershell
cd backend
# Aktifkan virtual environment backend dulu
venv\Scripts\Activate.ps1

# Jalankan backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verifikasi backend sudah online: buka `http://localhost:8000/docs` di browser.

---

## Menjalankan Test Suite

Gunakan virtual environment dari root workspace (`.venv` sudah ada di root `qa-automation-lab`).

**Penting:** Jalankan semua perintah ini dari folder root project `smart_recipe2`, bukan dari `tests/`.

### Jalankan Semua Test (Full Suite)
```powershell
# Dari folder: qa-automation-lab\projects\smart_recipe2
..\..\..\.venv\Scripts\pytest.exe
```

### Berdasarkan Module
```powershell
# Health check dulu (sistem siap?)
..\..\..\.venv\Scripts\pytest.exe -m health

# Search API (inti fitur BM25/TF-IDF)
..\..\..\.venv\Scripts\pytest.exe -m search

# Recipes CRUD & listing
..\..\..\.venv\Scripts\pytest.exe -m recipes

# Admin CRUD & CSV upload
..\..\..\.venv\Scripts\pytest.exe -m admin

# IR Evaluation metrics
..\..\..\.venv\Scripts\pytest.exe -m evaluation
```

### Berdasarkan Tingkat Keparahan
```powershell
# Hanya smoke test (paling kritis, cepat ~30 detik)
..\..\..\.venv\Scripts\pytest.exe -m smoke

# Hanya negative & boundary tests
..\..\..\.venv\Scripts\pytest.exe -m negative

# Full regression
..\..\..\.venv\Scripts\pytest.exe -m regression
```

### Lihat Laporan HTML
Setelah test selesai, laporan otomatis tersimpan di:
```
tests/reports/test-report.html
```
Buka dengan: `Start-Process tests\reports\test-report.html`

---

## Struktur Test Suite

```
tests/
├── conftest.py              # Fixtures global (HTTP client, schemas, payloads)
├── .env.test                # Konfigurasi environment test (base URL, timeout)
├── test_health.py           # Health check & system readiness
├── test_search_api.py       # POST /search, GET /search/suggestions (27 tests)
├── test_recipes_api.py      # GET /recipes, /popular, /{id}, /stats (21 tests)
├── test_admin_api.py        # Admin CRUD + CSV upload (19 tests)
├── test_evaluation_api.py   # POST /evaluation/run, GET /evaluation/results (10 tests)
└── reports/
    └── test-report.html     # Laporan visual hasil test
```

---

## Ringkasan Coverage per Endpoint

| Endpoint | Positive | Negative | Boundary | Schema |
|---|---|---|---|---|
| `POST /search` | ✅ | ✅ | ✅ | ✅ |
| `GET /search/suggestions` | ✅ | ✅ | - | - |
| `GET /recipes` | ✅ | ✅ | ✅ | ✅ |
| `GET /recipes/popular` | ✅ | ✅ | ✅ | ✅ |
| `GET /recipes/{id}` | ✅ | ✅ | ✅ | ✅ |
| `GET /stats` | ✅ | - | - | ✅ |
| `POST /admin/recipes` | ✅ | ✅ | ✅ | ✅ |
| `PUT /admin/recipes/{id}` | ✅ | ✅ | - | - |
| `DELETE /admin/recipes/{id}` | ✅ | ✅ | - | - |
| `POST /admin/upload` | ✅ | ✅ | - | - |
| `GET /admin/analytics` | ✅ | - | - | ✅ |
| `POST /evaluation/run` | ✅ | ✅ | - | ✅ |
| `GET /evaluation/results` | ✅ | - | - | - |
| `GET /health` | ✅ | - | - | ✅ |
