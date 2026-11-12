 ============================================================
--  VERIFY DATABASE TABLES
-- ============================================================

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'categories',
    'competitions',
    'complexes',
    'venues',
    'competitor',
    'competitor_rankings'
)
ORDER BY table_name;
-- ============================================================
-- After cleaning, missing country codes are stored as 'NEU'
-- ============================================================
SELECT COUNT(*) AS missing_country_codes
FROM competitor
WHERE country_code IS NULL OR TRIM(country_code) IN ('', 'NEU');

-- ============================================================
--  VERIFY FOREIGN KEY RELATIONSHIPS
-- ============================================================

SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.constraint_schema = kcu.constraint_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.constraint_schema = tc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
ORDER BY tc.table_name;


-- ============================================================
--  VERIFY TABLE STRUCTURE
-- ============================================================

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN (
    'categories',
    'competitions',
    'complexes',
    'venues',
    'competitor',
    'competitor_rankings'
)
ORDER BY table_name, ordinal_position;


-- ============================================================
--  RECORD COUNTS
-- ============================================================

SELECT 'categories' AS table_name, COUNT(*) AS total_records
FROM categories

UNION ALL

SELECT 'competitions', COUNT(*) FROM competitions

UNION ALL

SELECT 'complexes', COUNT(*) FROM complexes

UNION ALL

SELECT 'venues', COUNT(*) FROM venues

UNION ALL

SELECT 'competitor', COUNT(*) FROM competitor

UNION ALL

SELECT 'competitor_rankings', COUNT(*) FROM competitor_rankings;


-- ============================================================
--  DATA QUALITY CHECKS
-- ============================================================

-- 1. Duplicate category IDs

SELECT
    category_id,
    COUNT(*) AS duplicate_count
FROM categories
GROUP BY category_id
HAVING COUNT(*) > 1;


-- 2. Missing category references

SELECT COUNT(*) AS missing_category_references
FROM competitions c
LEFT JOIN categories ca
    ON c.category_id = ca.category_id
WHERE c.category_id IS NOT NULL
AND ca.category_id IS NULL;


-- 3. Missing complex references

SELECT COUNT(*) AS missing_complex_references
FROM venues v
LEFT JOIN complexes c
    ON v.complex_id = c.complex_id
WHERE v.complex_id IS NOT NULL
AND c.complex_id IS NULL;


-- 4. Missing competitor references

SELECT COUNT(*) AS missing_competitor_references
FROM competitor_rankings cr
LEFT JOIN competitor c
    ON cr.competitor_id = c.competitor_id
WHERE cr.competitor_id IS NOT NULL
AND c.competitor_id IS NULL;


-- 5. Missing competitor country codes

SELECT COUNT(*) AS missing_country_codes
FROM competitor
WHERE country_code IS NULL
   OR TRIM(country_code) = '';


-- 6. Ranking points statistics

SELECT
    MIN(points) AS minimum_points,
    MAX(points) AS maximum_points,
    ROUND(AVG(points), 2) AS average_points
FROM competitor_rankings;


-- ============================================================
--  COMPETITION ANALYSIS
-- ============================================================

-- 1. Competitions with category names

SELECT
    c.competition_name,
    ca.category_name,
    c.type,
    c.gender
FROM competitions c
JOIN categories ca
    ON c.category_id = ca.category_id
ORDER BY c.competition_name;


-- 2. Competitions per category

SELECT
    ca.category_name,
    COUNT(c.competition_id) AS total_competitions
FROM categories ca
JOIN competitions c
    ON ca.category_id = c.category_id
GROUP BY ca.category_name
ORDER BY total_competitions DESC;


-- 3. Competitions by gender

SELECT
    gender,
    COUNT(*) AS total_competitions
FROM competitions
GROUP BY gender
ORDER BY total_competitions DESC;


-- 4. Competitions by type

SELECT
    type,
    COUNT(*) AS total_competitions
FROM competitions
GROUP BY type
ORDER BY total_competitions DESC;


-- 5. Parent and sub-competitions

SELECT
    parent.competition_name AS parent_competition,
    child.competition_name AS sub_competition
FROM competitions child
JOIN competitions parent
    ON child.parent_id = parent.competition_id
ORDER BY parent.competition_name;


-- 6. Competition types by category

SELECT
    ca.category_name,
    c.type,
    COUNT(*) AS total_competitions
FROM competitions c
JOIN categories ca
    ON c.category_id = ca.category_id
GROUP BY ca.category_name, c.type
ORDER BY ca.category_name, total_competitions DESC;


-- ============================================================
--  COMPLEXES AND VENUES ANALYSIS
-- ============================================================

-- 1. Venues with complex names

SELECT
    v.venue_name,
    v.city_name,
    v.country_name,
    c.complex_name
FROM venues v
JOIN complexes c
    ON v.complex_id = c.complex_id
ORDER BY c.complex_name;


-- 2. Number of venues per complex

SELECT
    c.complex_name,
    COUNT(v.venue_id) AS total_venues
FROM complexes c
LEFT JOIN venues v
    ON c.complex_id = v.complex_id
GROUP BY c.complex_id, c.complex_name
ORDER BY total_venues DESC;


-- 3. Complexes with multiple venues

SELECT
    c.complex_name,
    COUNT(v.venue_id) AS total_venues
FROM complexes c
JOIN venues v
    ON c.complex_id = v.complex_id
GROUP BY c.complex_id, c.complex_name
HAVING COUNT(v.venue_id) > 1
ORDER BY total_venues DESC;


-- 4. Top 10 countries by venue count

SELECT
    country_name,
    COUNT(*) AS total_venues
FROM venues
GROUP BY country_name
ORDER BY total_venues DESC
LIMIT 10;


-- ============================================================
--  COMPETITOR RANKINGS ANALYSIS
-- ============================================================

-- 1. Competitors with rank and points

SELECT
    c.name,
    c.country,
    cr.rank,
    cr.points,
    cr.movement,
    cr.competitions_played
FROM competitor c
JOIN competitor_rankings cr
    ON c.competitor_id = cr.competitor_id
ORDER BY cr.rank, c.name;


-- 2. Top 10 competitors by points

SELECT
    c.name,
    c.country,
    cr.rank,
    cr.points
FROM competitor c
JOIN competitor_rankings cr
    ON c.competitor_id = cr.competitor_id
ORDER BY cr.points DESC
LIMIT 10;


-- 3. Competitors with no rank movement

SELECT
    c.name,
    c.country,
    cr.rank,
    cr.movement
FROM competitor c
JOIN competitor_rankings cr
    ON c.competitor_id = cr.competitor_id
WHERE cr.movement = 0
ORDER BY cr.rank;


-- 4. Latest available ranking week

SELECT
    c.name,
    c.country,
    cr.rank,
    cr.points,
    cr.ranking_year,
    cr.ranking_week
FROM competitor c
JOIN competitor_rankings cr
    ON c.competitor_id = cr.competitor_id
WHERE (cr.ranking_year, cr.ranking_week) = (
    SELECT ranking_year, ranking_week
    FROM competitor_rankings
    WHERE ranking_year IS NOT NULL
      AND ranking_week IS NOT NULL
    ORDER BY ranking_year DESC, ranking_week DESC
    LIMIT 1
)
ORDER BY cr.points DESC
LIMIT 10;


-- 5. Ranking movement distribution

SELECT
    CASE
        WHEN movement > 0 THEN 'Positive Movement'
        WHEN movement < 0 THEN 'Negative Movement'
        ELSE 'No Movement'
    END AS movement_status,
    COUNT(*) AS total_competitors
FROM competitor_rankings
GROUP BY movement_status
ORDER BY total_competitors DESC;


-- 6. Ranking distribution by gender

SELECT
    gender,
    COUNT(*) AS total_rankings,
    ROUND(AVG(points), 2) AS average_points
FROM competitor_rankings
GROUP BY gender
ORDER BY total_rankings DESC;


-- 7. Top 5 competitors in each gender

SELECT
    gender,
    player_name,
    country,
    points,
    player_rank
FROM (
    SELECT
        cr.gender,
        c.name AS player_name,
        c.country,
        cr.points,
        cr.rank AS player_rank,
        RANK() OVER (
            PARTITION BY cr.gender
            ORDER BY cr.points DESC
        ) AS row_num
    FROM competitor c
    JOIN competitor_rankings cr
        ON c.competitor_id = cr.competitor_id
) ranking_data
WHERE row_num <= 5
ORDER BY gender, row_num, player_name;
