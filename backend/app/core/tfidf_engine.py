"""
TF-IDF Search Engine.

Workflow:
  1. Load all recipes from DB at startup (parallel to BM25).
  2. Build TF-IDF Vectorizer and Matrix over preprocessed documents.
  3. get_top_ids(query) → transforms query → computes cosine_similarity → returns ranked results.
"""

import logging
from typing import Optional
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from app.core.preprocessor import preprocess

logger = logging.getLogger(__name__)


class TFIDFEngine:
    """
    Singleton TF-IDF search engine.

    Usage:
        engine = TFIDFEngine()
        engine.initialize(recipes)      # call once at startup
        results = engine.get_top_ids("ayam", k=20)
    """

    def __init__(self):
        # We maintain two vectorizers to match BM25 architecture
        self.vectorizer_stemmed = TfidfVectorizer()
        self.vectorizer_no_stem = TfidfVectorizer()
        
        self.matrix_stemmed = None
        self.matrix_no_stem = None
        
        self.idx_to_id: dict[int, int] = {}
        self.is_ready: bool = False

    def initialize(self, recipes: list[dict]) -> None:
        """
        Build TF-IDF matrix from a list of recipe dicts.
        """
        logger.info(f"Building TF-IDF matrix for {len(recipes)} recipes...")

        corpus_stemmed = []
        corpus_no_stem = []
        self.idx_to_id = {}

        for i, r in enumerate(recipes):
            doc = f"{r['title']} {r['ingredients']} {r['instructions']}"
            
            doc_stemmed = " ".join(preprocess(doc, apply_stemming=True))
            doc_no_stem = " ".join(preprocess(doc, apply_stemming=False))
            
            corpus_stemmed.append(doc_stemmed)
            corpus_no_stem.append(doc_no_stem)
            
            self.idx_to_id[i] = r["id"]

        if corpus_stemmed:
            self.matrix_stemmed = self.vectorizer_stemmed.fit_transform(corpus_stemmed)
            self.matrix_no_stem = self.vectorizer_no_stem.fit_transform(corpus_no_stem)

        self.is_ready = True
        logger.info("TF-IDF matrix built successfully.")

    def get_top_ids(self, query_text: str, k: int = 20, apply_stemming: bool = True) -> list[int]:
        """
        Execute TF-IDF search on a query and return top k recipe IDs.
        """
        if not self.is_ready:
            return []

        processed_query = " ".join(preprocess(query_text, apply_stemming=apply_stemming))
        
        if apply_stemming:
            if self.matrix_stemmed is None: return []
            query_vec = self.vectorizer_stemmed.transform([processed_query])
            scores = cosine_similarity(query_vec, self.matrix_stemmed).flatten()
        else:
            if self.matrix_no_stem is None: return []
            query_vec = self.vectorizer_no_stem.transform([processed_query])
            scores = cosine_similarity(query_vec, self.matrix_no_stem).flatten()

        top_indices = scores.argsort()[::-1][:k]
        return [self.idx_to_id[i] for i in top_indices if scores[i] > 0]

    def get_scores_full(
        self,
        query_text: str,
        top_k: int = 20,
        apply_stemming: bool = True,
    ) -> list[tuple[int, float]]:
        """
        Execute TF-IDF search and return top_k (recipe_id, cosine_score) pairs.

        Used by the search route to build full SearchResultItem objects.
        Only returns pairs with score > 0, sorted descending by score.
        """
        if not self.is_ready:
            return []

        processed_query = " ".join(preprocess(query_text, apply_stemming=apply_stemming))

        if apply_stemming:
            if self.matrix_stemmed is None:
                return []
            query_vec = self.vectorizer_stemmed.transform([processed_query])
            scores = cosine_similarity(query_vec, self.matrix_stemmed).flatten()
        else:
            if self.matrix_no_stem is None:
                return []
            query_vec = self.vectorizer_no_stem.transform([processed_query])
            scores = cosine_similarity(query_vec, self.matrix_no_stem).flatten()

        # Sort by score descending, keep only positive-score results
        ranked = sorted(
            ((self.idx_to_id[i], float(scores[i])) for i in range(len(scores)) if scores[i] > 0),
            key=lambda x: x[1],
            reverse=True,
        )
        return ranked[:top_k]


# Global singleton instance
tfidf_engine = TFIDFEngine()

