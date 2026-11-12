# load_to_db.py - Loads the CSV files from data/ into PostgreSQL (Member 4)
import os, math
import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv

load_dotenv(dotenv_path=".env", override=True)

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"), user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    sslmode=os.getenv("DB_SSLMODE", "prefer"),
    connect_timeout=30, keepalives=1, keepalives_idle=30)
cur = conn.cursor()
cur.execute("""TRUNCATE competitor_rankings, competitor, venues,
               complexes, competitions, categories RESTART IDENTITY CASCADE""")

def clean(v):
    """Turn pandas values into plain Python values (NaN -> None, 3.0 -> 3)."""
    if v is None or (isinstance(v, float) and math.isnan(v)):
        return None
    if hasattr(v, "item"):
        v = v.item()
    if isinstance(v, float) and v.is_integer():
        return int(v)
    return v

def load(table, csv_file, mapping, key=None):
    """mapping = {csv_column: table_column}"""
    df = pd.read_csv(os.path.join("data", "clean", csv_file))
    df = df.rename(columns=mapping)[list(mapping.values())]
    if key:
        df = df.drop_duplicates(subset=[key])
    rows = [tuple(clean(v) for v in r) for r in df.itertuples(index=False, name=None)]
    sql = f"INSERT INTO {table} ({', '.join(mapping.values())}) VALUES %s"
    if key:
        sql += f" ON CONFLICT ({key}) DO NOTHING"
    execute_values(cur, sql, rows, page_size=1000)
    print(f"{table:22} {len(rows)} rows")

# Parent tables first, then child tables (foreign keys)
load("categories", "categories.csv",
     {"category_id": "category_id", "category_name": "category_name"}, "category_id")

load("competitions", "competitions.csv",
     {"competition_id": "competition_id", "competition_name": "competition_name",
      "parent_id": "parent_id", "type": "type", "gender": "gender",
      "category_id": "category_id"}, "competition_id")

load("complexes", "complexes.csv",
     {"complex_id": "complex_id", "complex_name": "complex_name"}, "complex_id")

load("venues", "venues.csv",
     {"venue_id": "venue_id", "venue_name": "venue_name", "city_name": "city_name",
      "country_name": "country_name", "country_code": "country_code",
      "timezone": "timezone", "complex_id": "complex_id"}, "venue_id")

load("competitor", "competitors.csv",
     {"competitor_id": "competitor_id", "competitor_name": "name", "country": "country",
      "country_code": "country_code", "abbreviation": "abbreviation"}, "competitor_id")

cur.execute("TRUNCATE competitor_rankings RESTART IDENTITY")
load("competitor_rankings", "competitor_rankings.csv",
     {"rank": "rank", "movement": "movement", "points": "points",
      "competitions_played": "competitions_played", "competitor_id": "competitor_id",
      "ranking_type": "ranking_name", "year": "ranking_year", "week": "ranking_week",
      "gender": "gender"})

conn.commit()
cur.close()
conn.close()
print("Load complete!")