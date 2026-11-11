import json
import pandas as pd
import os

os.makedirs("data", exist_ok=True)

# 1. COMPETITIONS AND CATEGORIES
with open("data/raw/raw_competitions.json", encoding="utf-8") as f:
    data = json.load(f)

competitions = []
categories = {}

for item in data["competitions"]:
    category = item.get("category") or {}

    if category.get("id"):
        categories[category["id"]] = {
            "category_id": category.get("id"),
            "category_name": category.get("name")
        }

    competitions.append({
        "competition_id": item.get("id"),
        "competition_name": item.get("name"),
        "parent_id": item.get("parent_id"),
        "type": item.get("type"),
        "gender": item.get("gender"),
        "category_id": category.get("id")
    })

pd.DataFrame(competitions).to_csv(
    "data/competitions.csv", index=False
)

pd.DataFrame(categories.values()).to_csv(
    "data/categories.csv", index=False
)


# 2. COMPLEXES AND VENUES
with open("data/raw/raw_complexes.json", encoding="utf-8") as f:
    data = json.load(f)

complexes = []
venues = []

for item in data["complexes"]:
    complexes.append({
        "complex_id": item.get("id"),
        "complex_name": item.get("name")
    })

    for venue in item.get("venues", []):
        venues.append({
            "venue_id": venue.get("id"),
            "venue_name": venue.get("name"),
            "complex_id": item.get("id"),
            "city_name": venue.get("city_name"),
            "city_id": venue.get("city_id"),
            "country_name": venue.get("country_name"),
            "country_code": venue.get("country_code"),
            "timezone": venue.get("timezone")
        })

pd.DataFrame(complexes).to_csv(
    "data/complexes.csv", index=False
)

pd.DataFrame(venues).to_csv(
    "data/venues.csv", index=False
)


# 3. COMPETITORS AND RANKINGS
with open("data/raw/raw_doubles_rankings.json", encoding="utf-8") as f:
    data= json.load(f)

competitors = {}
rankings = []

for group in data["rankings"]:
    for item in group.get("competitor_rankings", []):
        player = item.get("competitor") or {}
        player_id = player.get("id")

        if player_id:
            competitors[player_id] = {
                "competitor_id": player_id,
                "competitor_name": player.get("name"),
                "country": player.get("country"),
                "country_code": player.get("country_code"),
                "abbreviation": player.get("abbreviation")
            }

        rankings.append({
            "competitor_id": player_id,
            "rank": item.get("rank"),
            "movement": item.get("movement"),
            "points": item.get("points"),
            "competitions_played": item.get("competitions_played"),
            "ranking_type": group.get("name"),
            "gender": group.get("gender"),
            "year": group.get("year"),
            "week": group.get("week")
        })

pd.DataFrame(competitors.values()).to_csv(
    "data/competitors.csv", index=False
)

pd.DataFrame(rankings).to_csv(
    "data/competitor_rankings.csv", index=False
)

print("All CSV files created successfully!")

for file in os.listdir("data"):
    if file.endswith(".csv"):
        print(file)