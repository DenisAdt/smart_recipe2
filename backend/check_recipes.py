import asyncio
import sys
import os
from sqlalchemy import select

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database.db import AsyncSessionLocal
from app.models.recipe import Recipe

async def main():
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Recipe).filter(Recipe.id.in_([1,2,3,2188,176])))
        recipes = res.scalars().all()
        for r in recipes:
            print(f"ID: {r.id}, Title: {r.title}")

asyncio.run(main())
