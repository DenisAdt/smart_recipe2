import asyncio
import sys
import os
from sqlalchemy import select

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.bm25_engine import bm25_engine
from app.api.routes.evaluation import _tfidf_search, _compute_metrics
from app.database.db import AsyncSessionLocal
from app.models.recipe import Recipe

async def trace_query():
    query = "ayam bawang merah bawang putih"
    ground_truth = [1, 2, 3, 15, 43, 47, 61, 62, 65, 69]
    top_k = 20
    k_values = [5, 10]

    print(f"--- TRACING QUERY: '{query}' ---")
    print(f"Ground Truth IDs: {ground_truth}")

    async with AsyncSessionLocal() as session:
        db_result = await session.execute(select(Recipe).order_by(Recipe.id))
        db_recipes = db_result.scalars().all()
        
        corpus_docs = [
            f"{r.title} {r.ingredients} {r.instructions}"
            for r in db_recipes
        ]
        idx_to_id = {i: r.id for i, r in enumerate(db_recipes)}

        recipe_dicts = [
            {
                "id": r.id,
                "title": r.title,
                "ingredients": r.ingredients,
                "instructions": r.instructions,
                "category": r.category,
                "image_url": r.image_url,
                "cooking_time": r.cooking_time,
                "difficulty": r.difficulty,
            }
            for r in db_recipes
        ]

        print(f"\nTotal Recipes in DB: {len(db_recipes)}")
        if len(db_recipes) > 0:
            print(f"First 5 IDs in DB: {[r.id for r in db_recipes[:5]]}")
            print(f"Last 5 IDs in DB: {[r.id for r in db_recipes[-5:]]}")

    # Init BM25
    print("Initializing BM25 Engine...")
    bm25_engine.initialize(recipe_dicts)
    if not bm25_engine.is_ready:
        print("BM25 Engine is not ready!")
        return
    print("BM25 Engine is ready!")

    # BM25 tanpa Stemming
    ret_bm25 = bm25_engine.get_top_ids(query_text=query, k=top_k, apply_stemming=False)
    print(f"\n--- BM25 (tanpa Stemming) ---")
    print(f"Returned IDs: {ret_bm25}")
    metrics_bm25 = _compute_metrics([ret_bm25], [ground_truth], k_values)
    tp_bm25 = len(set(ret_bm25) & set(ground_truth))
    fp_bm25 = len(ret_bm25) - tp_bm25
    fn_bm25 = len(ground_truth) - tp_bm25
    print(f"TP: {tp_bm25}, FP: {fp_bm25}, FN: {fn_bm25}")
    print(f"Precision: {metrics_bm25['precision']}, Recall: {metrics_bm25['recall']}, F1: {metrics_bm25['f1_score']}")
    print(f"P@5: {metrics_bm25['precision_at_5']}, P@10: {metrics_bm25['precision_at_10']}")

    # BM25 dengan Stemming
    ret_bm25_stem = bm25_engine.get_top_ids(query_text=query, k=top_k, apply_stemming=True)
    print(f"\n--- BM25 (dengan Stemming) ---")
    print(f"Returned IDs: {ret_bm25_stem}")
    metrics_bm25_stem = _compute_metrics([ret_bm25_stem], [ground_truth], k_values)
    tp_bm25_stem = len(set(ret_bm25_stem) & set(ground_truth))
    fp_bm25_stem = len(ret_bm25_stem) - tp_bm25_stem
    fn_bm25_stem = len(ground_truth) - tp_bm25_stem
    print(f"TP: {tp_bm25_stem}, FP: {fp_bm25_stem}, FN: {fn_bm25_stem}")
    print(f"Precision: {metrics_bm25_stem['precision']}, Recall: {metrics_bm25_stem['recall']}, F1: {metrics_bm25_stem['f1_score']}")
    print(f"P@5: {metrics_bm25_stem['precision_at_5']}, P@10: {metrics_bm25_stem['precision_at_10']}")

    # TF-IDF
    ret_indices = _tfidf_search(corpus_docs=corpus_docs, query=query, top_k=top_k, apply_stemming=True)
    ret_tfidf = [idx_to_id[i] for i in ret_indices if i in idx_to_id]
    print(f"\n--- TF-IDF (dengan Stemming) ---")
    print(f"Returned IDs: {ret_tfidf}")
    metrics_tfidf = _compute_metrics([ret_tfidf], [ground_truth], k_values)
    tp_tfidf = len(set(ret_tfidf) & set(ground_truth))
    fp_tfidf = len(ret_tfidf) - tp_tfidf
    fn_tfidf = len(ground_truth) - tp_tfidf
    print(f"TP: {tp_tfidf}, FP: {fp_tfidf}, FN: {fn_tfidf}")
    print(f"Precision: {metrics_tfidf['precision']}, Recall: {metrics_tfidf['recall']}, F1: {metrics_tfidf['f1_score']}")
    print(f"P@5: {metrics_tfidf['precision_at_5']}, P@10: {metrics_tfidf['precision_at_10']}")

asyncio.run(trace_query())
