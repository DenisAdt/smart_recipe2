"""
Admin API Route.

POST   /api/admin/upload              — upload CSV dataset
GET    /api/admin/recipes             — all recipes (CRUD list)
POST   /api/admin/recipes             — create recipe
PUT    /api/admin/recipes/{id}        — update recipe
DELETE /api/admin/recipes/{id}        — delete recipe
GET    /api/admin/analytics           — search analytics
"""

import csv
import io
import json
import logging
from collections import Counter
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy import select, func, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.bm25_engine import bm25_engine
from app.database.db import get_db
from app.models.recipe import Recipe
from app.models.search_log import SearchLog
from app.schemas.recipe import RecipeCreate, RecipeUpdate, RecipeOut, RecipeListOut

router = APIRouter(prefix="/admin", tags=["Admin"])
logger = logging.getLogger(__name__)


async def _rebuild_index(db: AsyncSession):
    """Helper to reload all recipes and rebuild BM25 index."""
    result = await db.execute(select(Recipe))
    recipes = result.scalars().all()
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
        for r in recipes
    ]
    bm25_engine.rebuild(recipe_dicts)
    logger.info(f"BM25 index rebuilt with {len(recipe_dicts)} recipes.")


# ------------------------------------------------------------------
# CSV Upload
# ------------------------------------------------------------------
@router.post("/upload")
async def upload_csv(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    """Upload a CSV file to import/replace recipes in the database."""
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only CSV files are supported.")

    content = await file.read()
    text = content.decode("utf-8")
    reader = csv.DictReader(io.StringIO(text))

    required_fields = {"title", "ingredients", "instructions"}
    if not required_fields.issubset(set(reader.fieldnames or [])):
        raise HTTPException(
            status_code=400,
            detail=f"CSV must contain columns: {required_fields}",
        )

    # Clear existing and import
    await db.execute(delete(Recipe))
    await db.commit()

    batch = []
    count = 0
    for row in reader:
        recipe = Recipe(
            title=row["title"].strip(),
            ingredients=row["ingredients"].strip(),
            instructions=row["instructions"].strip(),
            category=row.get("category", "Goreng").strip(),
            image_url=row.get("image_url", "").strip() or None,
            cooking_time=int(row["cooking_time"]) if row.get("cooking_time") else None,
            difficulty=row.get("difficulty", "Medium").strip(),
        )
        batch.append(recipe)
        count += 1

        if len(batch) >= 100:
            db.add_all(batch)
            await db.commit()
            batch = []

    if batch:
        db.add_all(batch)
        await db.commit()

    await _rebuild_index(db)
    return {"message": f"Successfully imported {count} recipes.", "total": count}


# ------------------------------------------------------------------
# CRUD
# ------------------------------------------------------------------
@router.get("/recipes", response_model=RecipeListOut)
async def admin_list_recipes(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Recipe).offset((page - 1) * page_size).limit(page_size)
    total_stmt = select(func.count(Recipe.id))
    total = (await db.execute(total_stmt)).scalar_one()
    result = await db.execute(stmt)
    return RecipeListOut(
        items=result.scalars().all(),
        total=total,
        page=page,
        page_size=page_size,
    )


@router.post("/recipes", response_model=RecipeOut, status_code=201)
async def create_recipe(
    data: RecipeCreate,
    db: AsyncSession = Depends(get_db),
):
    recipe = Recipe(**data.model_dump())
    db.add(recipe)
    await db.commit()
    await db.refresh(recipe)
    await _rebuild_index(db)
    return recipe


@router.put("/recipes/{recipe_id}", response_model=RecipeOut)
async def update_recipe(
    recipe_id: int,
    data: RecipeUpdate,
    db: AsyncSession = Depends(get_db),
):
    recipe = await db.get(Recipe, recipe_id)
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found.")

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(recipe, field, value)

    await db.commit()
    await db.refresh(recipe)
    await _rebuild_index(db)
    return recipe


@router.delete("/recipes/{recipe_id}")
async def delete_recipe(
    recipe_id: int,
    db: AsyncSession = Depends(get_db),
):
    recipe = await db.get(Recipe, recipe_id)
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found.")

    await db.delete(recipe)
    await db.commit()
    await _rebuild_index(db)
    return {"message": f"Recipe {recipe_id} deleted."}


# ------------------------------------------------------------------
# Analytics
# ------------------------------------------------------------------
@router.get("/analytics")
async def get_analytics(db: AsyncSession = Depends(get_db)):
    """Search analytics: top queries, most searched ingredients, daily counts."""
    result = await db.execute(select(SearchLog).order_by(SearchLog.timestamp.desc()).limit(500))
    logs = result.scalars().all()

    # Top ingredients
    ing_counter: Counter = Counter()
    for log in logs:
        try:
            ings = json.loads(log.ingredients)
            for ing in ings:
                ing_counter[ing.lower()] += 1
        except Exception:
            pass

    top_ingredients = [
        {"ingredient": k, "count": v}
        for k, v in ing_counter.most_common(15)
    ]

    # Daily search counts (last 7 days)
    from datetime import datetime, timedelta

    daily_counts = {}
    for i in range(7):
        day = (datetime.utcnow() - timedelta(days=i)).strftime("%Y-%m-%d")
        daily_counts[day] = 0

    for log in logs:
        day = log.timestamp.strftime("%Y-%m-%d")
        if day in daily_counts:
            daily_counts[day] += 1

    total_recipes = (await db.execute(select(func.count(Recipe.id)))).scalar_one()
    total_searches = (await db.execute(select(func.count(SearchLog.id)))).scalar_one()

    return {
        "total_recipes": total_recipes,
        "total_searches": total_searches,
        "top_ingredients": top_ingredients,
        "daily_searches": [
            {"date": k, "count": v}
            for k, v in sorted(daily_counts.items())
        ],
    }
