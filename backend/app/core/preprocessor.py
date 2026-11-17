"""
NLP Preprocessing Pipeline for BM25 Search.

Steps:
  1. Case Folding    – lowercase all text
  2. Tokenization    – split on non-alphanumeric characters
  3. Stopword Removal – Indonesian stopwords (NLTK + custom)
  4. Stemming        – Sastrawi IndonesianStemmer
"""

import re
import logging
from functools import lru_cache
from typing import List

import nltk
from Sastrawi.Stemmer.StemmerFactory import StemmerFactory

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# NLTK resource bootstrap
# ---------------------------------------------------------------------------
def _ensure_nltk():
    for res in ["stopwords", "punkt"]:
        try:
            nltk.data.find(f"corpora/{res}" if res == "stopwords" else f"tokenizers/{res}")
        except LookupError:
            nltk.download(res, quiet=True)


_ensure_nltk()

# ---------------------------------------------------------------------------
# Indonesian stopwords (NLTK + custom culinary noise words)
# ---------------------------------------------------------------------------
try:
    from nltk.corpus import stopwords as _sw
    _NLTK_STOPWORDS: set[str] = set(_sw.words("indonesian"))
except Exception:
    _NLTK_STOPWORDS = set()

_CUSTOM_STOPWORDS: set[str] = {
    # General
    "yang", "dan", "di", "ke", "dari", "dengan", "untuk", "pada",
    "adalah", "ini", "itu", "atau", "juga", "sudah", "ada", "tidak",
    "bisa", "agar", "lalu", "kemudian", "hingga", "sampai", "setelah",
    "sebelum", "saat", "ketika", "jika", "maka", "namun", "tetapi",
    "karena", "oleh", "dalam", "luar", "atas", "bawah", "antara",
    "serta", "yaitu", "seperti", "sebagai", "secara", "selama",
    "kembali", "sudah", "masih", "seluruh", "semua", "setiap",
    # Culinary noise
    "masak", "cara", "resep", "bahan", "bumbu", "tambahkan", "aduk",
    "panaskan", "goreng", "tumis", "rebus", "angkat", "sajikan",
    "siapkan", "potong", "iris", "haluskan", "blender", "ulek",
    "secukupnya", "sedikit", "banyak", "kira", "kira-kira", "kurang",
    "lebih", "cukup", "boleh", "dapat", "menggunakan", "digunakan",
    "campurkan", "masukkan", "keluarkan", "gunakan", "lakukan",
    "biarkan", "tunggu", "menit", "jam", "detik",
}

STOPWORDS: set[str] = _NLTK_STOPWORDS | _CUSTOM_STOPWORDS

# ---------------------------------------------------------------------------
# Sastrawi stemmer (singleton)
# ---------------------------------------------------------------------------
@lru_cache(maxsize=1)
def _get_stemmer():
    factory = StemmerFactory()
    return factory.create_stemmer()


# ---------------------------------------------------------------------------
# Core preprocessing functions
# ---------------------------------------------------------------------------
_TOKEN_RE = re.compile(r"[a-z0-9]+")


def case_fold(text: str) -> str:
    """Lowercase and strip leading/trailing whitespace."""
    return text.lower().strip()


def tokenize(text: str) -> List[str]:
    """Extract alphanumeric tokens from text."""
    return _TOKEN_RE.findall(text)


def remove_stopwords(tokens: List[str]) -> List[str]:
    """Remove Indonesian stopwords."""
    return [t for t in tokens if t not in STOPWORDS and len(t) > 1]


def stem_tokens(tokens: List[str], stemmer=None) -> List[str]:
    """Apply Sastrawi stemming to each token."""
    if stemmer is None:
        stemmer = _get_stemmer()
    return [stemmer.stem(t) for t in tokens]


def preprocess(
    text: str,
    apply_stemming: bool = True,
) -> List[str]:
    """
    Full preprocessing pipeline.

    Args:
        text: Raw text input
        apply_stemming: Whether to apply Sastrawi stemming

    Returns:
        List of preprocessed tokens
    """
    folded = case_fold(text)
    tokens = tokenize(folded)
    tokens = remove_stopwords(tokens)
    if apply_stemming:
        tokens = stem_tokens(tokens)
    return tokens


def preprocess_ingredients_list(ingredients_text: str) -> List[str]:
    """
    Parse ingredient list string to individual ingredient names.
    Returns the raw ingredient tokens without stemming (for matching display).
    """
    # Split by common delimiters
    parts = re.split(r"[,\n;|]+", ingredients_text)
    result = []
    for part in parts:
        part = part.strip()
        if part:
            # Remove quantities (numbers + units) to get ingredient name
            cleaned = re.sub(
                r"^\d+[\d\s/.,]*\s*(?:gram|gr|kg|ml|liter|l|sdm|sdt|sdt\.|sdm\.|butir|"
                r"siung|lembar|batang|buah|potong|iris|genggam|sachet|bungkus|sendok|cup|cangkir)?\s*",
                "",
                part,
                flags=re.IGNORECASE,
            ).strip()
            if cleaned:
                result.append(cleaned.lower())
    return result


def build_document(
    title: str,
    ingredients: str,
    instructions: str,
    apply_stemming: bool = True,
) -> List[str]:
    """
    Build a weighted BM25 document from recipe fields.

    Field weighting (by token repetition):
      - Title       × 3
      - Ingredients × 2
      - Instructions× 1
    """
    title_tokens = preprocess(title, apply_stemming) * 3
    ingredient_tokens = preprocess(ingredients, apply_stemming) * 2
    instruction_tokens = preprocess(instructions, apply_stemming)
    return title_tokens + ingredient_tokens + instruction_tokens


logger.info("Preprocessor initialized — Sastrawi stemmer loaded.")
