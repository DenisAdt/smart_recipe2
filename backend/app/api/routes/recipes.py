"""
Recipes API Route.

GET  /api/recipes          — paginated list
GET  /api/recipes/popular  — most searched recipes
GET  /api/recipes/{id}     — recipe detail
GET  /api/stats            — dataset statistics
"""

import re
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.db import get_db
from app.models.recipe import Recipe
from app.models.search_log import SearchLog
from app.schemas.recipe import RecipeOut, RecipeListOut, DatasetStatsOut

router = APIRouter(prefix="/recipes", tags=["Recipes"])


@router.get("", response_model=RecipeListOut)
async def list_recipes(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    category: Optional[str] = None,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """Paginated recipe list with optional category and text filter."""
    stmt = select(Recipe)

    if category:
        stmt = stmt.where(Recipe.category == category)
    if search:
        stmt = stmt.where(Recipe.title.ilike(f"%{search}%"))

    total_stmt = select(func.count()).select_from(stmt.subquery())
    total = (await db.execute(total_stmt)).scalar_one()

    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    recipes = result.scalars().all()

    return RecipeListOut(
        items=recipes,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/popular", response_model=list[RecipeOut])
async def get_popular_recipes(
    limit: int = Query(default=10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
):
    """Return recipes most frequently appearing as top search results."""
    stmt = (
        select(Recipe)
        .join(SearchLog, SearchLog.top_result_id == Recipe.id, isouter=True)
        .group_by(Recipe.id)
        .order_by(func.count(SearchLog.id).desc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{recipe_id}", response_model=RecipeOut)
async def get_recipe(recipe_id: int, db: AsyncSession = Depends(get_db)):
    """Get a single recipe by ID."""
    recipe = await db.get(Recipe, recipe_id)
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found.")
    return recipe


# ---- Stats endpoint (separate prefix /stats) ----
stats_router = APIRouter(prefix="/stats", tags=["Statistics"])


@stats_router.get("", response_model=DatasetStatsOut)
async def get_stats(db: AsyncSession = Depends(get_db)):
    """Dataset statistics: total recipes, unique ingredients, total searches."""
    total_recipes = (await db.execute(select(func.count(Recipe.id)))).scalar_one()
    total_searches = (await db.execute(select(func.count(SearchLog.id)))).scalar_one()

    # Count unique ingredients (approximate)
    result = await db.execute(select(Recipe.ingredients))
    all_ings = result.scalars().all()

    unique_ings: set[str] = set()
    for ings_text in all_ings:
        parts = re.split(r"[,\n;|]+", ings_text)
        for part in parts:
            cleaned = re.sub(
                r"^\d+[\d\s/.,]*\s*(?:gram|gr|kg|ml|liter|l|sdm|sdt|butir|siung|lembar|"
                r"batang|buah|potong|iris|genggam|sachet|bungkus|sendok|cup|cangkir)?\s*",
                "",
                part.strip(),
                flags=re.IGNORECASE,
            ).strip().lower()
            if cleaned and len(cleaned) > 1:
                unique_ings.add(cleaned)

    # Category counts
    cat_result = await db.execute(
        select(Recipe.category, func.count(Recipe.id))
        .group_by(Recipe.category)
    )
    categories = dict(cat_result.all())

    return DatasetStatsOut(
        total_recipes=total_recipes,
        unique_ingredients=len(unique_ings),
        total_searches=total_searches,
        categories=categories,
    )
