"""Pydantic schemas for Recipe API."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, HttpUrl


class RecipeBase(BaseModel):
    title: str
    ingredients: str
    instructions: str
    category: str = "Goreng"
    image_url: Optional[str] = None
    cooking_time: Optional[int] = None
    difficulty: Optional[str] = "Medium"


class RecipeCreate(RecipeBase):
    pass


class RecipeUpdate(BaseModel):
    title: Optional[str] = None
    ingredients: Optional[str] = None
    instructions: Optional[str] = None
    category: Optional[str] = None
    image_url: Optional[str] = None
    cooking_time: Optional[int] = None
    difficulty: Optional[str] = None


class RecipeOut(RecipeBase):
    id: int
    created_at: datetime

    model_config = {"from_attributes": True}


class RecipeListOut(BaseModel):
    items: list[RecipeOut]
    total: int
    page: int
    page_size: int


class DatasetStatsOut(BaseModel):
    total_recipes: int
    unique_ingredients: int
    total_searches: int
    categories: dict[str, int]
