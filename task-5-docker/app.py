import os
import psycopg
from flask import Flask, jsonify

app = Flask(__name__)
DSN = (f"host={os.environ['DB_HOST']} dbname={os.environ['POSTGRES_DB']} "
       f"user={os.environ['POSTGRES_USER']} password={os.environ['POSTGRES_PASSWORD']}")

@app.get("/health")
def health():
	return {"status":"ok"}

@app.get("/")
def index():
    with psycopg.connect(DSN) as conn:
        conn.execute("CREATE TABLE IF NOT EXISTS visits (id serial PRIMARY KEY, at timestamptz DEFAULT now())")
        conn.execute("INSERT INTO visits DEFAULT VALUES")
        count = conn.execute("SELECT count(*) FROM visits").fetchone()[0]
    return jsonify(message="Elevvo Task 5", visits=count)

