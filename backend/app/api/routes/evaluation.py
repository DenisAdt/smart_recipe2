"""
Evaluation API Route.

POST /api/evaluation/run     — run comparative IR evaluation
GET  /api/evaluation/results — stored evaluation results
"""

import logging
import time
from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.bm25_engine import bm25_engine
from app.core.tfidf_engine import tfidf_engine
from app.core.preprocessor import preprocess
from app.database.db import get_db
from app.models.evaluation import EvaluationResult
from app.schemas.evaluation import (
    EvaluationRunRequest,
    EvaluationRunResponse,
    MethodMetrics,
    EvaluationResultOut,
)
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

router = APIRouter(prefix="/evaluation", tags=["Evaluation"])
logger = logging.getLogger(__name__)


def _compute_metrics(
    retrieved_ids: list[list[int]],
    relevant_ids: list[list[int]],
    k_values: list[int] = None,
) -> dict:
    """
    Compute precision, recall, P@k for a set of queries.
    retrieved_ids[i] = ordered list of recipe IDs for query i
    relevant_ids[i]  = list of relevant recipe IDs for query i
    """
    k_values = k_values or [5, 10]
    precisions, recalls, f1s = [], [], []
    pk = {k: [] for k in k_values}

    for ret, rel in zip(retrieved_ids, relevant_ids):
        rel_set = set(rel)
        if not rel_set:
            continue

        tp = len(set(ret) & rel_set)
        prec = tp / len(ret) if ret else 0.0
        rec = tp / len(rel_set)
        f1 = 2 * prec * rec / (prec + rec) if (prec + rec) > 0 else 0.0

        precisions.append(prec)
        recalls.append(rec)
        f1s.append(f1)

        for k in k_values:
            tp_k = len(set(ret[:k]) & rel_set)
            pk[k].append(tp_k / k)

    def avg(lst):
        return round(float(np.mean(lst)), 4) if lst else 0.0

    return {
        "precision": avg(precisions),
        "recall": avg(recalls),
        "f1_score": avg(f1s),
        **{f"precision_at_{k}": avg(pk[k]) for k in k_values},
    }



@router.post("/run", response_model=EvaluationRunResponse)
async def run_evaluation(
    request: EvaluationRunRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Run comparative IR evaluation across 3 methods:
    1. BM25 without stemming
    2. BM25 with stemming
    3. TF-IDF with stemming
    """
    if not bm25_engine.is_ready:
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail="Search engine not ready.")

    queries = request.queries
    import sys
    import os
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
    if project_root not in sys.path:
        sys.path.insert(0, project_root)
    from ground_truth import GROUND_TRUTH
    
    relevant_map = GROUND_TRUTH
    k_values = request.k_values or [5, 10]
    top_k = max(k_values + [20])

    methods_config = [
        {"name": "BM25 tanpa Stemming",  "use_bm25": True,  "stemming": False},
        {"name": "BM25 dengan Stemming", "use_bm25": True,  "stemming": True},
        {"name": "TF-IDF dengan Stemming","use_bm25": False, "stemming": True},
    ]

    saved_results: list[MethodMetrics] = []

    for method_cfg in methods_config:
        retrieved_ids_per_query: list[list[int]] = []
        relevant_ids_per_query: list[list[int]] = []

        start_time = time.perf_counter()

        for query in queries:
            rel_ids = relevant_map.get(query, [])
            relevant_ids_per_query.append(rel_ids)

            if method_cfg["use_bm25"]:
                ret_recipe_ids = bm25_engine.get_top_ids(
                    query_text=query,
                    k=top_k,
                    apply_stemming=method_cfg["stemming"],
                )
            else:
                ret_recipe_ids = tfidf_engine.get_top_ids(
                    query_text=query,
                    k=top_k,
                    apply_stemming=method_cfg["stemming"],
                )

            retrieved_ids_per_query.append(ret_recipe_ids)

        end_time = time.perf_counter()
        avg_time_ms = ((end_time - start_time) / len(queries)) * 1000 if queries else 0.0

        metrics = _compute_metrics(
            retrieved_ids=retrieved_ids_per_query,
            relevant_ids=relevant_ids_per_query,
            k_values=k_values,
        )

        method_result = MethodMetrics(
            method=method_cfg["name"],
            precision=metrics["precision"],
            recall=metrics["recall"],
            precision_at_5=metrics.get("precision_at_5", 0.0),
            precision_at_10=metrics.get("precision_at_10", 0.0),
            f1_score=metrics["f1_score"],
            avg_query_time_ms=avg_time_ms,
        )
        saved_results.append(method_result)

        # Save to DB
        # eval_row = EvaluationResult(
        #     method=method_cfg["name"],
        #     precision=metrics["precision"],
        #     recall=metrics["recall"],
        #     precision_at_5=metrics.get("precision_at_5", 0.0),
        #     precision_at_10=metrics.get("precision_at_10", 0.0),
        #     f1_score=metrics["f1_score"],
        #     avg_query_time_ms=avg_time_ms,
        #     query_set=str(queries),
        # )
        # db.add(eval_row)

    # await db.commit()

    return EvaluationRunResponse(
        results=saved_results,
        queries_used=queries,
        total_recipes_in_dataset=bm25_engine.recipe_count,
        timestamp=datetime.utcnow(),
    )


@router.get("/results", response_model=list[EvaluationResultOut])
async def get_evaluation_results(
    limit: int = 30,
    db: AsyncSession = Depends(get_db),
):
    """Return stored evaluation results, newest first."""
    result = await db.execute(
        select(EvaluationResult)
        .order_by(EvaluationResult.created_at.desc())
        .limit(limit)
    )
    return result.scalars().all()
