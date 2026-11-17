"""Recipe SQLAlchemy model."""

from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime
from app.database.db import Base


class Recipe(Base):
    __tablename__ = "recipes"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False, index=True)
    ingredients = Column(Text, nullable=False)
    instructions = Column(Text, nullable=False)
    category = Column(String(50), nullable=False, default="Goreng")
    image_url = Column(Text, nullable=True)
    cooking_time = Column(Integer, nullable=True)   # in minutes
    difficulty = Column(String(20), nullable=True, default="Medium")
    created_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self) -> str:
        return f"<Recipe id={self.id} title={self.title!r}>"
