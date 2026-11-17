"""Pydantic schemas for Evaluation API."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class EvaluationRunRequest(BaseModel):
    queries: list[str]                  # Test query set (ingredient strings)
    relevant_recipe_ids: dict[str, list[int]]  # query → list of relevant recipe IDs
    k_values: list[int] = [5, 10]


class MethodMetrics(BaseModel):
    method: str
    precision: float
    recall: float
    precision_at_5: float
    precision_at_10: float
    f1_score: float
    avg_query_time_ms: float = 0.0


class EvaluationRunResponse(BaseModel):
    results: list[MethodMetrics]
    queries_used: list[str]
    total_recipes_in_dataset: int
    timestamp: datetime


class EvaluationResultOut(BaseModel):
    id: int
    method: str
    precision: float
    recall: float
    precision_at_5: float
    precision_at_10: float
    f1_score: float
    avg_query_time_ms: float = 0.0
    created_at: datetime

    model_config = {"from_attributes": True}
