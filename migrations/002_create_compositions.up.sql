-- =====================================================
-- TFT Arena - Compositions Schema Migration
-- File: migrations/002_create_compositions.up.sql
-- =====================================================

-- Create compositions schema
CREATE SCHEMA IF NOT EXISTS compositions;

-- =====================================================
-- Main team compositions table
-- =====================================================
CREATE TABLE compositions.team_comps (
    id SERIAL PRIMARY KEY,
    comp_hash VARCHAR(64) UNIQUE NOT NULL,
    patch_version VARCHAR(10) NOT NULL,
    region VARCHAR(10) NOT NULL,
    tier VARCHAR(20) NOT NULL,
    
    -- Composition data (JSONB for performance)
    traits JSONB NOT NULL,
    units JSONB NOT NULL,
    
    -- Calculated statistics
    total_games INTEGER DEFAULT 0,
    total_wins INTEGER DEFAULT 0,
    total_top4 INTEGER DEFAULT 0,
    avg_placement DECIMAL(4,2),
    win_rate DECIMAL(5,2),
    top4_rate DECIMAL(5,2),
    pick_rate DECIMAL(5,2),
    
    -- Metadata timestamps
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT check_patch_format CHECK (patch_version ~ '^15\.[0-9]+[a-z]?$'),
    CONSTRAINT check_region_valid CHECK (region IN (
        'br1', 'eun1', 'euw1', 'jp1', 'kr', 'la1', 'la2', 'na1', 
        'oc1', 'ru', 'sg2', 'tr1', 'tw2', 'vn2'
    )),
    CONSTRAINT check_tier_valid CHECK (tier IN (
        'IRON', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'EMERALD',
        'DIAMOND', 'MASTER', 'GRANDMASTER', 'CHALLENGER'
    )),
    CONSTRAINT check_total_games_positive CHECK (total_games >= 0),
    CONSTRAINT check_win_rate_valid CHECK (win_rate >= 0 AND win_rate <= 100),
    CONSTRAINT check_top4_rate_valid CHECK (top4_rate >= 0 AND top4_rate <= 100),
    CONSTRAINT check_pick_rate_valid CHECK (pick_rate >= 0 AND pick_rate <= 100),
    CONSTRAINT check_avg_placement_valid CHECK (avg_placement >= 1 AND avg_placement <= 8),
    CONSTRAINT check_traits_not_empty CHECK (jsonb_array_length(traits) > 0),
    CONSTRAINT check_units_not_empty CHECK (jsonb_array_length(units) > 0)
);

-- =====================================================
-- Individual composition games for statistics
-- =====================================================
CREATE TABLE compositions.comp_games (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(50) NOT NULL,
    participant_id INTEGER NOT NULL,
    comp_hash VARCHAR(64) NOT NULL REFERENCES compositions.team_comps(comp_hash) ON DELETE CASCADE,
    puuid VARCHAR(78) NOT NULL,
    
    -- Game performance data
    placement INTEGER NOT NULL,
    level INTEGER,
    gold_left INTEGER,
    total_damage INTEGER,
    
    -- Final composition state
    final_traits JSONB,
    final_units JSONB,
    
    -- Timing
    game_datetime BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT check_placement_valid CHECK (placement >= 1 AND placement <= 8),
    CONSTRAINT check_level_valid CHECK (level >= 1 AND level <= 11),
    CONSTRAINT check_gold_valid CHECK (gold_left >= 0),
    CONSTRAINT check_damage_valid CHECK (total_damage >= 0),
    CONSTRAINT check_puuid_format CHECK (length(puuid) = 78),
    
    -- Prevent duplicate games
    UNIQUE(match_id, participant_id)
);

-- =====================================================
-- Performance Indexes
-- =====================================================

-- Primary lookup indexes for team_comps
CREATE INDEX idx_team_comps_patch_region_tier ON compositions.team_comps (patch_version, region, tier);
CREATE INDEX idx_team_comps_comp_hash ON compositions.team_comps (comp_hash);
CREATE INDEX idx_team_comps_last_updated ON compositions.team_comps (last_updated DESC);

-- Statistics sorting indexes
CREATE INDEX idx_team_comps_win_rate ON compositions.team_comps (win_rate DESC) WHERE total_games >= 50;
CREATE INDEX idx_team_comps_pick_rate ON compositions.team_comps (pick_rate DESC) WHERE total_games >= 50;
CREATE INDEX idx_team_comps_top4_rate ON compositions.team_comps (top4_rate DESC) WHERE total_games >= 50;
CREATE INDEX idx_team_comps_avg_placement ON compositions.team_comps (avg_placement ASC) WHERE total_games >= 50;
CREATE INDEX idx_team_comps_total_games ON compositions.team_comps (total_games DESC);

-- JSONB indexes for trait/champion filtering
CREATE INDEX idx_team_comps_traits_gin ON compositions.team_comps USING GIN (traits);
CREATE INDEX idx_team_comps_units_gin ON compositions.team_comps USING GIN (units);

-- Composite index for leaderboard queries
CREATE INDEX idx_team_comps_leaderboard ON compositions.team_comps (
    patch_version, region, tier, win_rate DESC, pick_rate DESC
) WHERE total_games >= 100;

-- comp_games indexes
CREATE INDEX idx_comp_games_comp_hash ON compositions.comp_games (comp_hash);
CREATE INDEX idx_comp_games_match_id ON compositions.comp_games (match_id);
CREATE INDEX idx_comp_games_puuid ON compositions.comp_games (puuid);
CREATE INDEX idx_comp_games_datetime ON compositions.comp_games (game_datetime DESC);
CREATE INDEX idx_comp_games_placement ON compositions.comp_games (placement);

-- Composite index for game analysis
CREATE INDEX idx_comp_games_hash_datetime ON compositions.comp_games (comp_hash, game_datetime DESC);

-- =====================================================
-- Materialized View for Leaderboard Performance  
-- =====================================================
CREATE MATERIALIZED VIEW compositions.comp_leaderboard AS
SELECT 
    tc.id,
    tc.comp_hash,
    tc.patch_version,
    tc.region,
    tc.tier,
    tc.traits,
    tc.units,
    tc.total_games,
    tc.total_wins,
    tc.total_top4,
    tc.avg_placement,
    tc.win_rate,
    tc.top4_rate,
    tc.pick_rate,
    
    -- Calculate tier rank based on performance
    CASE 
        WHEN tc.win_rate >= 25 AND tc.pick_rate >= 5 AND tc.total_games >= 500 THEN 'S'
        WHEN tc.win_rate >= 20 AND tc.pick_rate >= 3 AND tc.total_games >= 300 THEN 'A'
        WHEN tc.win_rate >= 15 AND tc.pick_rate >= 1 AND tc.total_games >= 100 THEN 'B'
        WHEN tc.total_games >= 50 THEN 'C'
        ELSE 'D'
    END as tier_rank,
    
    -- Sample size categorization
    CASE 
        WHEN tc.total_games >= 1000 THEN 'high'
        WHEN tc.total_games >= 100 THEN 'medium'
        WHEN tc.total_games >= 50 THEN 'low'
        ELSE 'insufficient'
    END as sample_size,
    
    tc.first_seen,
    tc.last_seen,
    tc.last_updated
FROM compositions.team_comps tc
WHERE tc.total_games >= 50  -- Minimum threshold for leaderboard
ORDER BY 
    tc.patch_version DESC,
    tc.region,
    tc.tier,
    tc.win_rate DESC,
    tc.pick_rate DESC;

-- Index on materialized view
CREATE UNIQUE INDEX idx_comp_leaderboard_id ON compositions.comp_leaderboard (id);
CREATE INDEX idx_comp_leaderboard_tier_rank ON compositions.comp_leaderboard (tier_rank);
CREATE INDEX idx_comp_leaderboard_patch_region ON compositions.comp_leaderboard (patch_version, region);
CREATE INDEX idx_comp_leaderboard_performance ON compositions.comp_leaderboard (
    tier_rank, win_rate DESC, pick_rate DESC
);

-- =====================================================
-- Functions for Composition Hash Calculation
-- =====================================================
CREATE OR REPLACE FUNCTION compositions.calculate_comp_hash(
    traits JSONB,
    units JSONB
) RETURNS VARCHAR(64) AS $$
DECLARE
    comp_string TEXT := '';
    trait_element JSONB;
    unit_element JSONB;
    trait_parts TEXT[] := '{}';
    unit_parts TEXT[] := '{}';
BEGIN
    -- Process active traits (count >= 2)
    FOR trait_element IN SELECT * FROM jsonb_array_elements(traits)
    LOOP
        IF (trait_element->>'count')::int >= 2 THEN
            trait_parts := array_append(trait_parts, 
                trait_element->>'name' || ':' || (trait_element->>'count')::text
            );
        END IF;
    END LOOP;
    
    -- Process high-value units (3+ cost or 2-cost with 2+ stars)
    FOR unit_element IN SELECT * FROM jsonb_array_elements(units)
    LOOP
        IF (unit_element->>'cost')::int >= 3 OR 
           ((unit_element->>'cost')::int >= 2 AND (unit_element->>'tier')::int >= 2) THEN
            unit_parts := array_append(unit_parts, unit_element->>'champion');
        END IF;
    END LOOP;
    
    -- Sort and combine parts for consistency
    SELECT array_to_string(array(SELECT unnest(trait_parts) ORDER BY 1), '|') INTO comp_string;
    comp_string := comp_string || '||' || array_to_string(array(SELECT unnest(unit_parts) ORDER BY 1), '|');
    
    -- Return SHA256 hash
    RETURN encode(digest(comp_string, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- Trigger Functions for Auto-Statistics Updates
-- =====================================================
CREATE OR REPLACE FUNCTION compositions.update_comp_stats()
RETURNS TRIGGER AS $$
DECLARE
    total_games_in_region INTEGER;
BEGIN
    -- Update team composition statistics
    UPDATE compositions.team_comps 
    SET 
        total_games = (
            SELECT COUNT(*) 
            FROM compositions.comp_games 
            WHERE comp_hash = NEW.comp_hash
        ),
        total_wins = (
            SELECT COUNT(*) 
            FROM compositions.comp_games 
            WHERE comp_hash = NEW.comp_hash AND placement = 1
        ),
        total_top4 = (
            SELECT COUNT(*) 
            FROM compositions.comp_games 
            WHERE comp_hash = NEW.comp_hash AND placement <= 4
        ),
        avg_placement = (
            SELECT AVG(placement) 
            FROM compositions.comp_games 
            WHERE comp_hash = NEW.comp_hash
        ),
        last_seen = NOW(),
        last_updated = NOW()
    WHERE comp_hash = NEW.comp_hash;
    
    -- Update calculated rates
    UPDATE compositions.team_comps 
    SET 
        win_rate = ROUND((total_wins::DECIMAL / NULLIF(total_games, 0)) * 100, 2),
        top4_rate = ROUND((total_top4::DECIMAL / NULLIF(total_games, 0)) * 100, 2)
    WHERE comp_hash = NEW.comp_hash;
    
    -- Calculate pick rate (requires total games in region/tier/patch)
    SELECT COUNT(DISTINCT comp_hash) INTO total_games_in_region
    FROM compositions.team_comps tc
    WHERE tc.patch_version = (SELECT patch_version FROM compositions.team_comps WHERE comp_hash = NEW.comp_hash LIMIT 1)
      AND tc.region = (SELECT region FROM compositions.team_comps WHERE comp_hash = NEW.comp_hash LIMIT 1)
      AND tc.tier = (SELECT tier FROM compositions.team_comps WHERE comp_hash = NEW.comp_hash LIMIT 1);
      
    UPDATE compositions.team_comps 
    SET pick_rate = ROUND((total_games::DECIMAL / NULLIF(total_games_in_region, 0)) * 100, 2)
    WHERE comp_hash = NEW.comp_hash;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_update_comp_stats
    AFTER INSERT ON compositions.comp_games
    FOR EACH ROW
    EXECUTE FUNCTION compositions.update_comp_stats();

-- =====================================================
-- Function to Refresh Materialized View
-- =====================================================
CREATE OR REPLACE FUNCTION compositions.refresh_leaderboard()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY compositions.comp_leaderboard;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Function for Composition Cleanup (Remove old/low-sample)
-- =====================================================
CREATE OR REPLACE FUNCTION compositions.cleanup_old_compositions(
    min_games INTEGER DEFAULT 10,
    days_old INTEGER DEFAULT 30
)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete compositions with insufficient games and old data
    DELETE FROM compositions.team_comps 
    WHERE total_games < min_games 
      AND last_updated < NOW() - INTERVAL '1 day' * days_old;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Clean up orphaned games (shouldn't happen due to FK, but just in case)
    DELETE FROM compositions.comp_games 
    WHERE comp_hash NOT IN (SELECT comp_hash FROM compositions.team_comps);
    
    -- Refresh materialized view after cleanup
    PERFORM compositions.refresh_leaderboard();
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Grant Permissions
-- =====================================================
-- Grant usage on schema to application user
GRANT USAGE ON SCHEMA compositions TO tft_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA compositions TO tft_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA compositions TO tft_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA compositions TO tft_user;

-- =====================================================
-- Create Indexes for Common Query Patterns
-- =====================================================

-- Index for finding similar compositions (trait-based similarity)
CREATE INDEX idx_team_comps_trait_similarity ON compositions.team_comps 
USING GIN ((traits -> 0 ->> 'name'), (traits -> 1 ->> 'name'), (traits -> 2 ->> 'name'));

-- Index for champion-based filtering
CREATE INDEX idx_team_comps_champion_filter ON compositions.team_comps 
USING GIN ((units -> 0 ->> 'champion'), (units -> 1 ->> 'champion'), (units -> 2 ->> 'champion'));

-- Partial index for high-performing compositions
CREATE INDEX idx_team_comps_high_performance ON compositions.team_comps (win_rate DESC, pick_rate DESC)
WHERE win_rate >= 20 AND total_games >= 200;

-- Index for time-series analysis
CREATE INDEX idx_comp_games_time_series ON compositions.comp_games (
    comp_hash, 
    date_trunc('day', to_timestamp(game_datetime))
);

-- =====================================================
-- Performance Statistics Table (Optional - for advanced analytics)
-- =====================================================
CREATE TABLE compositions.comp_performance_history (
    id SERIAL PRIMARY KEY,
    comp_hash VARCHAR(64) NOT NULL REFERENCES compositions.team_comps(comp_hash) ON DELETE CASCADE,
    snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
    games_played INTEGER NOT NULL DEFAULT 0,
    win_rate DECIMAL(5,2),
    top4_rate DECIMAL(5,2),
    avg_placement DECIMAL(4,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(comp_hash, snapshot_date)
);

CREATE INDEX idx_comp_performance_history_hash_date ON compositions.comp_performance_history (comp_hash, snapshot_date DESC);
CREATE INDEX idx_comp_performance_history_date ON compositions.comp_performance_history (snapshot_date DESC);

-- =====================================================
-- Comments for Documentation
-- =====================================================
COMMENT ON SCHEMA compositions IS 'Schema for TFT team composition analysis and statistics';
COMMENT ON TABLE compositions.team_comps IS 'Main table storing unique team compositions and their performance statistics';
COMMENT ON TABLE compositions.comp_games IS 'Individual games for each composition, used for statistical calculations';
COMMENT ON MATERIALIZED VIEW compositions.comp_leaderboard IS 'Optimized view for leaderboard queries with pre-calculated tier rankings';
COMMENT ON FUNCTION compositions.calculate_comp_hash(JSONB, JSONB) IS 'Calculates unique hash for composition based on active traits and key units';
COMMENT ON FUNCTION compositions.update_comp_stats() IS 'Trigger function to automatically update composition statistics when new games are added';
COMMENT ON FUNCTION compositions.refresh_leaderboard() IS 'Refreshes the materialized view for leaderboard performance';
COMMENT ON FUNCTION compositions.cleanup_old_compositions(INTEGER, INTEGER) IS 'Removes old compositions with insufficient sample sizes';