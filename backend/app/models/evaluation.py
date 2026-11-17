"""Evaluation SQLAlchemy model."""

import json
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Text, DateTime
from app.database.db import Base


class EvaluationResult(Base):
    __tablename__ = "evaluation_results"

    id = Column(Integer, primary_key=True, index=True)
    method = Column(String(100), nullable=False)     # e.g. "BM25+Stemming"
    precision = Column(Float, default=0.0)
    recall = Column(Float, default=0.0)
    precision_at_5 = Column(Float, default=0.0)
    precision_at_10 = Column(Float, default=0.0)
    f1_score = Column(Float, default=0.0)
    avg_query_time_ms = Column(Float, default=0.0)
    query_set = Column(Text, default="[]")           # JSON list of queries used
    created_at = Column(DateTime, default=datetime.utcnow)

    def get_query_set(self) -> list[str]:
        return json.loads(self.query_set)

    def set_query_set(self, queries: list[str]):
        self.query_set = json.dumps(queries, ensure_ascii=False)

    def __repr__(self) -> str:
        return f"<EvaluationResult method={self.method!r} precision={self.precision:.3f}>"
