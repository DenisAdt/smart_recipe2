import sqlite3
import json

db_path = 'backend/data/srp.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

result = {}

cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = [row[0] for row in cursor.fetchall()]
result['tables'] = tables

counts = {}
for table in tables:
    try:
        cursor.execute(f"SELECT COUNT(*) FROM {table};")
        counts[table] = cursor.fetchone()[0]
    except Exception as e:
        counts[table] = str(e)
result['counts'] = counts

with open('db_info.json', 'w') as f:
    json.dump(result, f, indent=2)
conn.close()
