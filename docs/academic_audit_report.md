# Academic Audit Report: Evaluation Module

## 1. Metrics Audit

I have inspected the entire Evaluation pipeline across the Flutter frontend and Python backend. Below is the verification for each metric.

### Precision
- **File:** `backend/app/api/routes/evaluation.py`
- **Function:** `_compute_metrics`
- **Formula:** `tp / len(ret) if ret else 0.0`
- **Mathematically Correct?** Yes. Precision is True Positives divided by total retrieved documents.
- **Calculated Dynamically?** Yes.

### Recall
- **File:** `backend/app/api/routes/evaluation.py`
- **Function:** `_compute_metrics`
- **Formula:** `tp / len(rel_set)`
- **Mathematically Correct?** Yes. Recall is True Positives divided by total relevant documents.
- **Calculated Dynamically?** Yes.

### F1 Score
- **File:** `backend/app/api/routes/evaluation.py`
- **Function:** `_compute_metrics`
- **Formula:** `2 * prec * rec / (prec + rec) if (prec + rec) > 0 else 0.0`
- **Mathematically Correct?** Yes. This is the standard harmonic mean of Precision and Recall.
- **Calculated Dynamically?** Yes.

### Precision@5
- **File:** `backend/app/api/routes/evaluation.py`
- **Function:** `_compute_metrics`
- **Formula:** `tp_k / k` (where `k=5`)
- **Mathematically Correct?** Yes. It calculates True Positives in the top 5 retrieved documents divided by 5.
- **Calculated Dynamically?** Yes.

### Precision@10
- **File:** `backend/app/api/routes/evaluation.py`
- **Function:** `_compute_metrics`
- **Formula:** `tp_k / k` (where `k=10`)
- **Mathematically Correct?** Yes.
- **Calculated Dynamically?** Yes.

### Query Time
- **File/Function:** Not implemented.
- **Mathematically Correct?** N/A.
- **Calculated Dynamically?** N/A. The backend does not measure or return execution time for queries in the evaluation response.

---

## 2. Dataset & Ground Truth

- **Which dataset is used?** The corpus is dynamically pulled from the PostgreSQL database (`RecipeModel`).
- **What is considered the Ground Truth?** The ground truth is a hardcoded map of query strings to relevant Recipe IDs (`_defaultRelevantIds`) stored in `frontend/lib/features/evaluation/evaluation_screen.dart`.
- **How are TP, FP, FN determined?**
  - **TP (True Positives):** `len(set(ret) & rel_set)` (intersection of retrieved IDs and ground truth IDs).
  - **FP (False Positives):** Implied mathematically as `len(ret) - TP`.
  - **FN (False Negatives):** Implied mathematically as `len(rel_set) - TP`.
- **How many queries are used?** **8** queries (e.g., 'ayam bawang merah bawang putih', 'tempe tahu goreng').
- **Is the evaluation reproducible?** **No, not entirely.** The ground truth relies on hardcoded database primary key IDs (e.g., `1, 2, 3, 15...`). If recipes are added, deleted, or the database is re-seeded, those IDs might change, breaking the entire ground truth map.

---

## 3. Algorithm Comparison

I verified the three modes executed during the evaluation:

1. **BM25 (tanpa Stemming):**
   - **Different Algorithm?** Uses Okapi BM25.
   - **Different Function?** Calls `bm25_engine.get_top_ids(..., apply_stemming=False)`.
   - **Different Preprocessing?** Yes. Sastrawi stemming is completely bypassed because `apply_stemming` is passed down to `preprocess()` and `build_document()`.
2. **BM25 + Stemming:**
   - **Different Algorithm?** Uses Okapi BM25.
   - **Different Function?** Calls `bm25_engine.get_top_ids(..., apply_stemming=True)`.
   - **Different Preprocessing?** Yes. Sastrawi stemmer is enabled.
3. **TF-IDF:**
   - **Different Algorithm?** Yes.
   - **Different Function?** Calls a dedicated `_tfidf_search` function.
   - **Different Preprocessing?** Yes. It applies the same custom preprocessing (with stemming) but builds vectors using `sklearn.feature_extraction.text.TfidfVectorizer` and calculates `cosine_similarity`.
- **Is Sastrawi actually enabled only when expected?** **Yes.** The boolean flag `apply_stemming` strictly controls the execution of `Sastrawi.Stemmer.StemmerFactory` in `backend/app/core/preprocessor.py`.

---

## 4. Flutter Evaluation Screen Data Origination

The values displayed on the frontend originate as follows:

- **Top Cards (Precision, Recall, F1, P@5, P@10):**
  - These are **Real values** returned from the backend *only if* the evaluation runs successfully.
  - **However,** they use **Static demo values** as a fallback (e.g., `currentResult?.precision ?? 0.84`). Before the user presses "Run", the screen displays these fake values instead of 0.0 or a loading state.
- **Algorithm Comparison Bar Chart (F1 Score):**
  - These are **100% Static demo values**.
  - The F1 scores for the chart are hardcoded in `_BarRow` widgets: BM25 (`0.80`), BM25 + Stemming (`0.82`), TF-IDF (`0.72`). **They never update** based on the actual backend response.

---

## 5. Backend API Flow

- **Endpoint:** `POST /api/evaluation/run`
- **Request Schema (`EvaluationRunRequest`):**
  ```json
  {
    "queries": ["string"],
    "relevant_recipe_ids": { "query": [1, 2, 3] },
    "k_values": [5, 10]
  }
  ```
- **Response Schema (`EvaluationRunResponse`):**
  ```json
  {
    "results": [
      {
        "method": "string",
        "precision": 0.0,
        "recall": 0.0,
        "precision_at_5": 0.0,
        "precision_at_10": 0.0,
        "f1_score": 0.0
      }
    ],
    "queries_used": ["string"],
    "timestamp": "datetime"
  }
  ```
- **Flow:**
  Flutter `ApiClient.runEvaluation()`
  ↓
  `POST /api/evaluation/run`
  ↓
  Iterate Methods (BM25, BM25+Stemming, TF-IDF)
  ↓
  Algorithms fetch corpus, preprocess, score, and return Top K indices
  ↓
  `_compute_metrics()` compares retrieved indices against `relevant_recipe_ids`
  ↓
  Averages calculated across all queries
  ↓
  JSON Response returned to Flutter

---

## 6. Academic Readiness Report

| Component | Rating | Notes |
| :--- | :--- | :--- |
| **BM25 Implementation** | ★★★★★ | Flawless. Uses `rank_bm25` properly, tokenization and weighting logic are correct. |
| **TF-IDF Implementation** | ★★★★★ | Standard mathematical implementation using scikit-learn's `TfidfVectorizer` and cosine similarity. |
| **BM25 + Stemming** | ★★★★★ | Stemmer logic is correctly segregated and toggled via strict boolean parameters. |
| **Evaluation Metrics** | ★★★★★ | Mathematics for Precision, Recall, F1, and P@k are completely accurate. |
| **Ground Truth** | ★★☆☆☆ | Risky. Hardcoded integer IDs in frontend are highly volatile if the database is reset. |
| **Academic Validity** | ★★★☆☆ | Valid math, but compromised by frontend display issues (hardcoded charts) and lack of query time logging. |

### Issues to Fix BEFORE Chapter IV

> [!WARNING]
> These issues directly compromise the integrity of the thesis presentation if not resolved.

1. **Hardcoded UI Chart Values:**
   The frontend algorithm comparison bar chart uses static literal values (`0.80`, `0.82`, `0.72`). If a panelist asks to see the real F1 values visually compared, the chart will not reflect the actual output. It must be bound to the `_result` variables.
2. **Fake Fallback Metrics:**
   Before running the evaluation, the UI displays `0.84`, `0.76`, etc. In an academic defense, it looks suspicious to have high metrics before an algorithm is even run. These should default to `0.00` or display a "Not Run" state.
3. **Missing Query Time Metric:**
   System efficiency is a standard IR metric. The backend does not measure execution time (latency per query). This needs to be captured during `get_top_ids` and `_tfidf_search`, averaged, and passed to the frontend.
4. **Fragile Ground Truth:**
   The ground truth relies on hardcoded primary keys (`[1, 2, 3, ...]`). If the database is repopulated during development or defense preparation, the IDs will auto-increment differently, making recall and precision drop to 0%. The ground truth should ideally map to Recipe URLs, Slugs, or exact Titles, or be managed in a static test dataset rather than a live DB.
