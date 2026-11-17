import asyncio
import sys
import os
from sqlalchemy import select

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.bm25_engine import bm25_engine
from app.database.db import AsyncSessionLocal
from app.models.recipe import Recipe

async def trace_query():
    query = "ayam bawang merah bawang putih"
    ground_truth = [1, 2, 3, 15, 43, 47, 61, 62, 65, 69]

    async with AsyncSessionLocal() as session:
        db_result = await session.execute(select(Recipe).order_by(Recipe.id))
        db_recipes = db_result.scalars().all()
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

    bm25_engine.initialize(recipe_dicts)
    
    # Get scores
    scores_stem = bm25_engine.get_scores_raw(query, apply_stemming=True)
    
    print("BM25 Scores (Stemmed):")
    for doc_idx, score in enumerate(scores_stem):
        r_id = bm25_engine._corpus[doc_idx].recipe_id
        if r_id in [1, 2, 3, 2188, 176]:
            print(f"ID {r_id}: Score {score}")

asyncio.run(trace_query())
