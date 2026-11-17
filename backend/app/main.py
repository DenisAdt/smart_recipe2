"""
Smart Recipe Planner — FastAPI Application Entry Point.

Startup sequence:
  1. Initialize database (create tables)
  2. Seed from CSV if DB is empty
  3. Build BM25 index

Run with:
  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select, func

from app.core.config import settings
from app.core.bm25_engine import bm25_engine
from app.core.tfidf_engine import tfidf_engine
from app.database.db import init_db, AsyncSessionLocal
from app.models.recipe import Recipe
from app.api.routes.search import router as search_router
from app.api.routes.recipes import router as recipes_router, stats_router
from app.api.routes.admin import router as admin_router
from app.api.routes.evaluation import router as evaluation_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Lifespan (startup / shutdown)
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup: init DB, optionally seed, build BM25 index."""
    logger.info("🚀 Starting Smart Recipe Planner API...")

    # 1. Create tables
    await init_db()

    async with AsyncSessionLocal() as session:
        # 2. Seed from CSV if empty
        count = (await session.execute(select(func.count(Recipe.id)))).scalar_one()
        if count == 0:
            logger.info("Database empty — running seeder...")
            try:
                from app.database.seed import seed_database
                await seed_database()
                # Re-count after seed
                count = (await session.execute(select(func.count(Recipe.id)))).scalar_one()
            except Exception as e:
                logger.warning(f"Seeder error (non-fatal): {e}")

        # 3. Build BM25 index
        result = await session.execute(select(Recipe))
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
        bm25_engine.initialize(recipe_dicts)
        tfidf_engine.initialize(recipe_dicts)

    logger.info(f"✅ Ready! BM25 index and TF-IDF matrix built for {bm25_engine.recipe_count} recipes.")
    yield

    logger.info("Shutting down...")


# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=(
        "Smart Recipe Planner API — Ingredient-based recipe search using Okapi BM25. "
        "Academic Information Retrieval project."
    ),
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
API_PREFIX = "/api"

app.include_router(search_router,     prefix=API_PREFIX)
app.include_router(recipes_router,    prefix=API_PREFIX)
app.include_router(stats_router,      prefix=API_PREFIX)
app.include_router(admin_router,      prefix=API_PREFIX)
app.include_router(evaluation_router, prefix=API_PREFIX)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------
@app.get("/health", tags=["System"])
async def health():
    return {
        "status": "ok",
        "version": settings.APP_VERSION,
        "bm25_ready": bm25_engine.is_ready,
        "recipe_count": bm25_engine.recipe_count,
    }


@app.get("/", tags=["System"])
async def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
    }

# ---------------------------------------------------------------------------
# Debug Page for DB Screenshot
# ---------------------------------------------------------------------------
@app.get("/debug/db", tags=["System"], response_class=HTMLResponse)
async def debug_db():
    import sqlite3
    import os
    import json
    
    # Locate DB robustly relative to the app
    db_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "srp.db")
    if not os.path.exists(db_path):
        return f"<html><body><h2>Database not found at {db_path}</h2></body></html>"
        
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [r[0] for r in cursor.fetchall()]
    
    counts = {}
    for t in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {t};")
        counts[t] = cursor.fetchone()[0]
        
    cursor.execute("SELECT id, title, category, difficulty, ingredients, instructions, image_url, created_at FROM recipes LIMIT 5;")
    rows = cursor.fetchall()
    conn.close()
    
    import html as html_lib
    
    recipes_data = []
    for r in rows:
        recipes_data.append({
            "id": r[0],
            "title": r[1],
            "category": r[2],
            "difficulty": r[3],
            "ingredients": r[4],
            "instructions": r[5],
            "image_url": r[6],
            "created_at": r[7]
        })
    
    recipes_json = json.dumps(recipes_data).replace("</", "<\\/")
    
    html = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Database Implementation - Smart Recipe Planner</title>
        <style>
            :root {{
                --primary: #2e7d32;
                --primary-light: #4caf50;
                --bg: #f5f7fa;
                --card-bg: #ffffff;
                --text-main: #2d3748;
                --text-muted: #718096;
                --border: #e2e8f0;
                --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            }}
            * {{ box-sizing: border-box; margin: 0; padding: 0; }}
            body {{ font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: var(--bg); color: var(--text-main); line-height: 1.6; padding: 40px 20px; }}
            .container {{ max-width: 1000px; margin: 0 auto; }}
            
            /* Section 1: Header */
            .header {{ display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 40px; }}
            .header-titles h1 {{ font-size: 1.8rem; font-weight: 700; color: var(--text-main); margin-bottom: 4px; line-height: 1.2; }}
            .header-titles h2 {{ font-size: 1.2rem; font-weight: 500; color: var(--text-muted); }}
            .badge {{ display: inline-flex; align-items: center; background-color: #e6f4ea; color: var(--primary); padding: 6px 12px; border-radius: 20px; font-size: 0.875rem; font-weight: 600; border: 1px solid #cce8d6; }}
            .badge::before {{ content: '●'; margin-right: 6px; font-size: 0.7rem; }}
            
            /* Cards General */
            .card {{ background: var(--card-bg); border-radius: 12px; border: 1px solid var(--border); box-shadow: var(--shadow); padding: 24px; margin-bottom: 24px; }}
            .card-title {{ font-size: 1.1rem; font-weight: 600; margin-bottom: 20px; color: var(--text-main); border-bottom: 1px solid var(--border); padding-bottom: 12px; }}
            
            /* Section 2: Info Grid */
            .info-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 20px; }}
            .info-item {{ display: flex; flex-direction: column; }}
            .info-label {{ font-size: 0.85rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600; margin-bottom: 4px; }}
            .info-value {{ font-size: 1rem; font-weight: 500; }}
            
            /* Section 3: Stats Grid */
            .stats-grid {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }}
            .stat-card {{ background: var(--card-bg); border-radius: 12px; border: 1px solid var(--border); box-shadow: var(--shadow); padding: 24px; display: flex; flex-direction: column; }}
            .stat-title {{ font-size: 1rem; color: var(--text-muted); font-weight: 600; margin-bottom: 8px; }}
            .stat-value {{ font-size: 2rem; font-weight: 700; color: var(--text-main); margin-bottom: 4px; }}
            .stat-label {{ font-size: 0.9rem; color: var(--text-muted); }}
            
            /* Section 4: Tables List */
            .table-list {{ list-style: none; }}
            .table-item {{ display: flex; align-items: flex-start; margin-bottom: 16px; padding-bottom: 16px; border-bottom: 1px solid var(--border); }}
            .table-item:last-child {{ margin-bottom: 0; padding-bottom: 0; border-bottom: none; }}
            .table-icon {{ color: var(--primary); font-size: 1.2rem; margin-right: 12px; font-weight: bold; }}
            .table-details h4 {{ font-size: 1.05rem; font-weight: 600; margin-bottom: 4px; }}
            .table-details p {{ font-size: 0.9rem; color: var(--text-muted); }}
            
            /* Section 5 & 6: Data Tables */
            .data-table {{ width: 100%; border-collapse: collapse; }}
            .data-table th, .data-table td {{ padding: 12px 16px; text-align: left; border-bottom: 1px solid var(--border); }}
            .data-table th {{ background-color: #f8fafc; font-weight: 600; font-size: 0.9rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; }}
            .data-table tr:last-child td {{ border-bottom: none; }}
            .data-table tbody tr:hover {{ background-color: #f8fafc; }}
            .data-table td {{ font-size: 0.95rem; }}
            
            /* Button */
            .btn {{ background-color: white; border: 1px solid var(--border); color: var(--text-main); padding: 6px 12px; border-radius: 6px; font-size: 0.85rem; font-weight: 500; cursor: pointer; transition: all 0.2s; }}
            .btn:hover {{ border-color: var(--primary); color: var(--primary); }}
            
            /* Modal */
            .modal-overlay {{ display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; }}
            .modal-content {{ background: white; border-radius: 12px; padding: 24px; width: 90%; max-width: 600px; max-height: 80vh; overflow-y: auto; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1); position: relative; }}
            .modal-close {{ position: absolute; top: 20px; right: 20px; background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-muted); line-height: 1; }}
            .modal-body h3 {{ margin-bottom: 16px; color: var(--primary); padding-right: 20px; }}
            .modal-field {{ margin-bottom: 12px; padding-bottom: 12px; border-bottom: 1px solid var(--border); }}
            .modal-field:last-child {{ border-bottom: none; margin-bottom: 0; padding-bottom: 0; }}
            .modal-field strong {{ display: block; font-size: 0.85rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 4px; }}
            .modal-field div {{ font-size: 0.95rem; white-space: pre-wrap; }}
            
            /* Footer */
            .footer {{ text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid var(--border); color: var(--text-muted); font-size: 0.85rem; }}
            
            @media (max-width: 768px) {{
                .stats-grid {{ grid-template-columns: 1fr; }}
                .header {{ flex-direction: column; gap: 16px; }}
            }}
        </style>
    </head>
    <body>
        <div class="container">
            
            <!-- SECTION 1 -->
            <div class="header">
                <div class="header-titles">
                    <h1>Smart Recipe Planner</h1>
                    <h2>Database Implementation</h2>
                </div>
                <div class="badge">Database Connected</div>
            </div>
            
            <!-- SECTION 2 -->
            <div class="card">
                <h3 class="card-title">Database Information</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">Database Name</span>
                        <span class="info-value">srp.db</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Database Type</span>
                        <span class="info-value">SQLite</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Status</span>
                        <span class="info-value" style="color: var(--primary); font-weight: 600;">Connected</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Total Tables</span>
                        <span class="info-value">{len(tables)}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Database Path</span>
                        <span class="info-value">backend/data/srp.db</span>
                    </div>
                </div>
            </div>
            
            <!-- SECTION 3 -->
            <div class="stats-grid" style="margin-bottom: 24px;">
                <div class="stat-card">
                    <div class="stat-title">Recipes</div>
                    <div class="stat-value">{counts.get('recipes', 0)}</div>
                    <div class="stat-label">Records</div>
                </div>
                <div class="stat-card">
                    <div class="stat-title">Evaluation Results</div>
                    <div class="stat-value">{counts.get('evaluation_results', 0)}</div>
                    <div class="stat-label">Records</div>
                </div>
                <div class="stat-card">
                    <div class="stat-title">Search Logs</div>
                    <div class="stat-value">{counts.get('search_logs', 0)}</div>
                    <div class="stat-label">Records</div>
                </div>
            </div>
            
            <!-- SECTION 4 -->
            <div class="card">
                <h3 class="card-title">Database Tables</h3>
                <ul class="table-list">
                    <li class="table-item">
                        <div class="table-icon">&#10003;</div>
                        <div class="table-details">
                            <h4>recipes</h4>
                            <p>Menyimpan dataset resep.</p>
                        </div>
                    </li>
                    <li class="table-item">
                        <div class="table-icon">&#10003;</div>
                        <div class="table-details">
                            <h4>evaluation_results</h4>
                            <p>Menyimpan hasil evaluasi algoritma.</p>
                        </div>
                    </li>
                    <li class="table-item">
                        <div class="table-icon">&#10003;</div>
                        <div class="table-details">
                            <h4>search_logs</h4>
                            <p>Menyimpan histori pencarian.</p>
                        </div>
                    </li>
                </ul>
            </div>
            
            <!-- SECTION 5 -->
            <div class="card">
                <h3 class="card-title">Recipes Table Schema</h3>
                <div style="overflow-x: auto;">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Column</th>
                                <th>Type</th>
                                <th>Description</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr><td>id</td><td>INTEGER</td><td>Primary Key</td></tr>
                            <tr><td>title</td><td>VARCHAR(255)</td><td>Recipe title</td></tr>
                            <tr><td>ingredients</td><td>TEXT</td><td>Recipe ingredients</td></tr>
                            <tr><td>instructions</td><td>TEXT</td><td>Cooking instructions</td></tr>
                            <tr><td>category</td><td>VARCHAR(50)</td><td>Recipe category</td></tr>
                            <tr><td>image_url</td><td>TEXT</td><td>Recipe image</td></tr>
                            <tr><td>cooking_time</td><td>INTEGER</td><td>Cooking duration</td></tr>
                            <tr><td>difficulty</td><td>VARCHAR(20)</td><td>Difficulty level</td></tr>
                            <tr><td>created_at</td><td>DATETIME</td><td>Creation timestamp</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- SECTION 6 -->
            <div class="card">
                <h3 class="card-title">Recipe Preview (Top 5)</h3>
                <div style="overflow-x: auto;">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Title</th>
                                <th>Category</th>
                                <th>Difficulty</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody id="recipe-table-body">
                            <!-- Populated by JS -->
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- SECTION 7 -->
            <div class="footer">
                Database generated from SQLite (srp.db) &bull; Smart Recipe Planner
            </div>
        </div>
        
        <!-- Modal -->
        <div class="modal-overlay" id="detailModal">
            <div class="modal-content">
                <button class="modal-close" onclick="closeModal()">&times;</button>
                <div class="modal-body" id="modalBody">
                    <!-- Populated by JS -->
                </div>
            </div>
        </div>
        
        <script>
            // Inject JSON directly
            const recipes = {recipes_json};
            const tbody = document.getElementById('recipe-table-body');
            
            recipes.forEach((r, index) => {{
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>${{r.id}}</td>
                    <td>${{r.title}}</td>
                    <td>${{r.category || '-'}}</td>
                    <td>${{r.difficulty || '-'}}</td>
                    <td><button class="btn" onclick="openModal(${{index}})">View Detail</button></td>
                `;
                tbody.appendChild(tr);
            }});
            
            window.openModal = function(index) {{
                const r = recipes[index];
                const modalBody = document.getElementById('modalBody');
                modalBody.innerHTML = `
                    <h3>${{r.title}}</h3>
                    <div class="modal-field"><strong>Ingredients</strong><div>${{r.ingredients || '-'}}</div></div>
                    <div class="modal-field"><strong>Instructions</strong><div>${{r.instructions || '-'}}</div></div>
                    <div class="modal-field"><strong>Category</strong><div>${{r.category || '-'}}</div></div>
                    <div class="modal-field"><strong>Difficulty</strong><div>${{r.difficulty || '-'}}</div></div>
                    <div class="modal-field"><strong>Image URL</strong><div>${{r.image_url || '-'}}</div></div>
                    <div class="modal-field"><strong>Created At</strong><div>${{r.created_at || '-'}}</div></div>
                `;
                document.getElementById('detailModal').style.display = 'flex';
            }};
            
            window.closeModal = function() {{
                document.getElementById('detailModal').style.display = 'none';
            }};
            
            // Close on overlay click
            document.getElementById('detailModal').addEventListener('click', function(e) {{
                if (e.target === this) closeModal();
            }});
        </script>
    </body>
    </html>
    """
    return html
