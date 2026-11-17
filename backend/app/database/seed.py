"""
Database seeder — loads recipes.csv into SQLite and builds BM25 index.
Run: python -m app.database.seed
"""

import asyncio
import csv
import logging
import os
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from app.core.config import settings

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


async def seed_database():
    """Import recipes.csv into the database."""
    # Ensure data directory exists
    Path(settings.RECIPES_CSV_PATH).parent.mkdir(parents=True, exist_ok=True)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    # Import models to create tables
    from app.models import Recipe, SearchLog, EvaluationResult  # noqa
    from app.database.db import Base

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    csv_path = Path(settings.RECIPES_CSV_PATH)
    if not csv_path.exists():
        logger.error(f"recipes.csv not found at {csv_path}")
        return

    async with Session() as session:
        # Clear existing recipes
        await session.execute(text("DELETE FROM recipes"))
        await session.commit()

        recipes_loaded = 0
        with open(csv_path, encoding="utf-8") as f:
            reader = csv.DictReader(f)
            batch = []
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
                recipes_loaded += 1

                if len(batch) >= 50:
                    session.add_all(batch)
                    await session.commit()
                    batch = []

            if batch:
                session.add_all(batch)
                await session.commit()

    logger.info(f"✅ Seeded {recipes_loaded} recipes successfully.")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed_database())
