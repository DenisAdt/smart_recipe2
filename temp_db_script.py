import sqlite3
import json

db_path = 'backend/data/srp.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

result = {}

# 1. Get tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = [row[0] for row in cursor.fetchall()]
result['tables'] = tables

# 2. Count records
counts = {}
for table in tables:
    try:
        cursor.execute(f"SELECT COUNT(*) FROM {table};")
        counts[table] = cursor.fetchone()[0]
    except Exception as e:
        counts[table] = str(e)
result['counts'] = counts

# 3. Top 10 recipes
try:
    cursor.execute("SELECT * FROM recipes LIMIT 10;")
    rows = cursor.fetchall()
    col_names = [description[0] for description in cursor.description]
    top_10 = [dict(zip(col_names, row)) for row in rows]
    result['top_10_recipes'] = top_10
except Exception as e:
    result['top_10_recipes'] = str(e)

# 4. Schema of recipes
try:
    cursor.execute("PRAGMA table_info(recipes);")
    schema = cursor.fetchall()
    schema_info = [{'cid': row[0], 'name': row[1], 'type': row[2], 'notnull': row[3], 'dflt_value': row[4], 'pk': row[5]} for row in schema]
    result['recipes_schema'] = schema_info
except Exception as e:
    result['recipes_schema'] = str(e)

conn.close()

print(json.dumps(result, indent=2))
