"""Application configuration settings."""
from pydantic_settings import BaseSettings
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Smart Recipe Planner"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = f"sqlite+aiosqlite:///{BASE_DIR}/data/srp.db"
    DATABASE_URL_SYNC: str = f"sqlite:///{BASE_DIR}/data/srp.db"

    # BM25 Parameters
    BM25_K1: float = 1.2
    BM25_B: float = 0.75

    # Search
    DEFAULT_TOP_K: int = 20
    MAX_TOP_K: int = 100

    ALLOWED_ORIGINS: list[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",   # Flutter web dev server
        "http://localhost:8081",
        "http://127.0.0.1",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",   # Flutter web dev server
        "http://127.0.0.1:8081",
        "http://10.0.2.2",         # Android emulator → host
        "http://10.0.2.2:8000",
        "*",
    ]

    # Dataset
    RECIPES_CSV_PATH: str = str(BASE_DIR / "data" / "recipes_final_3000_standardized.csv")

    # Relevance thresholds
    RELEVANCE_HIGHLY: float = 8.0
    RELEVANCE_RELEVANT: float = 5.0
    RELEVANCE_MODERATE: float = 2.0
    RELEVANCE_PARTIAL: float = 0.5

    class Config:
        env_file = ".env"


settings = Settings()
