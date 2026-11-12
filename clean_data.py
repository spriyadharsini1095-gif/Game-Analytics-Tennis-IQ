# clean_data.py - Fills missing values in the CSV files before loading into PostgreSQL
import os
import pandas as pd

CSV_DIR = "data"                                   # where json_to_csv.py saves the CSVs
CLEAN_DIR = os.path.join("data", "clean")          # cleaned copies go here
os.makedirs(CLEAN_DIR, exist_ok=True)

# Fill missing values and report how many
FILL = {
    "competitions": {"type": "unknown", "gender": "unknown"},
    "venues": {"city_name": "Unknown", "country_name": "Unknown",
               "country_code": "UNK", "timezone": "Unknown"},
    "competitors": {"country": "Unknown", "country_code": "NEU",
                    "abbreviation": "UNK"},
}

# Columns that exist in the CSV but not in our PostgreSQL tables
DROP = {
    "competitions": ["level"],
}

TABLES = ["categories", "competitions", "complexes", "venues",
          "competitors", "competitor_rankings"]

for t in TABLES:
    df = pd.read_csv(os.path.join(CSV_DIR, f"{t}.csv"))
    df = df.drop(columns=DROP.get(t, []), errors="ignore")

    for col, val in FILL.get(t, {}).items():
        if col not in df.columns:
            continue
        n = int(df[col].isna().sum())
        if n:
            print(f"{t}.{col}: filled {n} missing values with '{val}'")
            df[col] = df[col].fillna(val)

    df.to_csv(os.path.join(CLEAN_DIR, f"{t}.csv"), index=False)
    print(f"{t}: saved {len(df)} rows to {CLEAN_DIR}/{t}.csv")