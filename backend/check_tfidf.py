import asyncio
import sys
import os
from sqlalchemy import select

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.api.routes.evaluation import _tfidf_search
from app.database.db import AsyncSessionLocal
from app.models.recipe import Recipe
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from app.core.preprocessor import preprocess

async def trace_query():
    query = "ayam bawang merah bawang putih"
    
    async with AsyncSessionLocal() as session:
        db_result = await session.execute(select(Recipe).order_by(Recipe.id))
        db_recipes = db_result.scalars().all()
        corpus_docs = [
            f"{r.title} {r.ingredients} {r.instructions}"
            for r in db_recipes
        ]
        idx_to_id = {i: r.id for i, r in enumerate(db_recipes)}

    processed_docs = [
        " ".join(preprocess(doc, apply_stemming=True))
        for doc in corpus_docs
    ]
    processed_query = " ".join(preprocess(query, apply_stemming=True))

    vectorizer = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(processed_docs)
    query_vec = vectorizer.transform([processed_query])
    scores = cosine_similarity(query_vec, tfidf_matrix).flatten()
    
    for i in range(len(db_recipes)):
        r_id = idx_to_id[i]
        if r_id in [1, 2, 3, 2188, 176, 2, 139]:
            print(f"TF-IDF ID {r_id}: Score {scores[i]}")

asyncio.run(trace_query())
