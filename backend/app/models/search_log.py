"""SearchLog SQLAlchemy model."""

import json
from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from app.database.db import Base


class SearchLog(Base):
    __tablename__ = "search_logs"

    id = Column(Integer, primary_key=True, index=True)
    query = Column(Text, nullable=False)                    # Raw query string
    ingredients = Column(Text, nullable=False, default="[]")  # JSON array
    results_count = Column(Integer, default=0)
    top_result_id = Column(Integer, ForeignKey("recipes.id"), nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)

    def get_ingredients(self) -> list[str]:
        return json.loads(self.ingredients)

    def set_ingredients(self, ing: list[str]):
        self.ingredients = json.dumps(ing, ensure_ascii=False)

    def __repr__(self) -> str:
        return f"<SearchLog id={self.id} query={self.query!r}>"
