
-- ============================================================
-- GAME ANALYTICS: UNLOCKING TENNIS DATA WITH SPORTRADAR
-- DATABASE DESIGN AND SQL ANALYSIS
-- DATABASE: PostgreSQL
-- ============================================================


-- ============================================================
-- 1. DATABASE TABLE CREATION
-- ============================================================

CREATE TABLE IF NOT EXISTS categories (
    category_id VARCHAR(50) PRIMARY KEY,
    category_name VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS competitions (
    competition_id VARCHAR(50) PRIMARY KEY,
    competition_name VARCHAR(100),
    parent_id VARCHAR(50),
    type VARCHAR(20),
    gender VARCHAR(10),
    category_id VARCHAR(50),
    FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
);

CREATE TABLE IF NOT EXISTS complexes (
    complex_id VARCHAR(50) PRIMARY KEY,
    complex_name VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS venues (
    venue_id VARCHAR(50) PRIMARY KEY,
    venue_name VARCHAR(100),
    city_name VARCHAR(100),
    country_name VARCHAR(100),
    country_code CHAR(3),
    timezone VARCHAR(100),
    complex_id VARCHAR(50),
    FOREIGN KEY (complex_id)
        REFERENCES complexes(complex_id)
);

CREATE TABLE IF NOT EXISTS competitor (
    competitor_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150),
    country VARCHAR(100),
    country_code CHAR(10),
    abbreviation VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS competitor_rankings (
    rank_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rank INT NOT NULL,
    movement INT NOT NULL,
    points INT NOT NULL,
    competitions_played INT NOT NULL,
    competitor_id VARCHAR(50),
    FOREIGN KEY (competitor_id)
        REFERENCES competitor(competitor_id)
);


-- ============================================================
-- 2. ADD RANKING METADATA COLUMNS
-- ============================================================

ALTER TABLE competitor_rankings
ADD COLUMN IF NOT EXISTS type_id INT,
ADD COLUMN IF NOT EXISTS ranking_name VARCHAR(50),
ADD COLUMN IF NOT EXISTS ranking_year INT,
ADD COLUMN IF NOT EXISTS ranking_week INT,
ADD COLUMN IF NOT EXISTS gender VARCHAR(10);


-- ============================================================
-- 3. VERIFY DATABASE TABLES
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
-- 4. VERIFY FOREIGN KEY RELATIONSHIPS
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
-- 5. VERIFY TABLE STRUCTURE
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


