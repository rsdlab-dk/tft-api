-- =====================================================
-- TFT Arena - Matches Schema Migration
-- File: migrations/003_create_matches.up.sql
-- =====================================================

-- Create matches schema
CREATE SCHEMA IF NOT EXISTS matches;

-- =====================================================
-- Main Matches Table
-- =====================================================
CREATE TABLE matches.matches (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(50) UNIQUE NOT NULL,
    data_version VARCHAR(10) NOT NULL,
    game_datetime BIGINT NOT NULL,
    game_length REAL NOT NULL,
    game_version VARCHAR(20) NOT NULL,
    patch_version VARCHAR(10) NOT NULL,
    queue_id INTEGER NOT NULL,
    tft_game_type VARCHAR(50),
    tft_set_core_name VARCHAR(50),
    tft_set_number INTEGER,
    region VARCHAR(10) NOT NULL,
    
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_game_length_positive CHECK (game_length > 0),
    CONSTRAINT check_game_datetime_valid CHECK (game_datetime > 1640995200), -- 2022-01-01
    CONSTRAINT check_queue_id_valid CHECK (queue_id IN (1090, 1100, 1130, 1160)),
    CONSTRAINT check_tft_set_valid CHECK (tft_set_number >= 9),
    CONSTRAINT check_region_valid CHECK (region IN (
        'br1', 'eun1', 'euw1', 'jp1', 'kr', 'la1', 'la2', 'na1', 
        'oc1', 'ru', 'sg2', 'tr1', 'tw2', 'vn2'
    ))
);

-- =====================================================
-- Match Participants Table
-- =====================================================
CREATE TABLE matches.participants (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(50) NOT NULL REFERENCES matches.matches(match_id) ON DELETE CASCADE,
    participant_id INTEGER NOT NULL,
    puuid VARCHAR(78) NOT NULL,
    
    placement INTEGER NOT NULL,
    level INTEGER NOT NULL,
    last_round INTEGER NOT NULL,
    time_eliminated REAL,
    gold_left INTEGER,
    total_damage_to_players INTEGER,
    players_eliminated INTEGER,
    
    augments JSONB,
    companion JSONB,
    traits JSONB NOT NULL,
    units JSONB NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_placement_valid CHECK (placement >= 1 AND placement <= 8),
    CONSTRAINT check_level_valid CHECK (level >= 1 AND level <= 11),
    CONSTRAINT check_last_round_valid CHECK (last_round >= 1),
    CONSTRAINT check_gold_valid CHECK (gold_left >= 0),
    CONSTRAINT check_damage_valid CHECK (total_damage_to_players >= 0),
    CONSTRAINT check_participants_valid CHECK (participant_id >= 0 AND participant_id <= 7),
    CONSTRAINT check_puuid_length CHECK (length(puuid) = 78),
    
    UNIQUE(match_id, participant_id)
);

-- =====================================================
-- Match Timeline Events (Optional - for detailed analysis)
-- =====================================================
CREATE TABLE matches.timeline_events (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(50) NOT NULL REFERENCES matches.matches(match_id) ON DELETE CASCADE,
    participant_id INTEGER NOT NULL,
    round_id INTEGER NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    timestamp_ms BIGINT NOT NULL,
    event_data JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_round_id_valid CHECK (round_id >= 1),
    CONSTRAINT check_timestamp_valid CHECK (timestamp_ms >= 0),
    CONSTRAINT check_event_type_valid CHECK (event_type IN (
        'ROUND_START', 'ROUND_END', 'CHAMPION_KILL', 'ITEM_EQUIPPED',
        'CHAMPION_PURCHASED', 'CHAMPION_SOLD', 'CHAMPION_UPGRADED',
        'TRAIT_ACTIVATED', 'AUGMENT_SELECTED', 'SHOP_REFRESH'
    ))
);

-- =====================================================
-- Performance Indexes
-- =====================================================

-- Main match lookups
CREATE INDEX idx_matches_match_id ON matches.matches (match_id);
CREATE INDEX idx_matches_region_datetime ON matches.matches (region, game_datetime DESC);
CREATE INDEX idx_matches_patch_version ON matches.matches (patch_version);
CREATE INDEX idx_matches_queue_id ON matches.matches (queue_id);
CREATE INDEX idx_matches_processed ON matches.matches (processed_at DESC);

-- Time-based queries
CREATE INDEX idx_matches_datetime_desc ON matches.matches (game_datetime DESC);
CREATE INDEX idx_matches_region_patch_datetime ON matches.matches (region, patch_version, game_datetime DESC);

-- Participants lookups
CREATE INDEX idx_participants_match_id ON matches.participants (match_id);
CREATE INDEX idx_participants_puuid ON matches.participants (puuid);
CREATE INDEX idx_participants_placement ON matches.participants (placement);
CREATE INDEX idx_participants_puuid_datetime ON matches.participants (puuid, (
    SELECT game_datetime FROM matches.matches WHERE matches.matches.match_id = matches.participants.match_id
) DESC);

-- JSONB indexes for composition analysis
CREATE INDEX idx_participants_traits ON matches.participants USING GIN (traits);
CREATE INDEX idx_participants_units ON matches.participants USING GIN (units);
CREATE INDEX idx_participants_augments ON matches.participants USING GIN (augments);

-- Composite index for leaderboard queries
CREATE INDEX idx_participants_performance ON matches.participants (puuid, placement, total_damage_to_players DESC);

-- Timeline events indexes
CREATE INDEX idx_timeline_match_participant ON matches.timeline_events (match_id, participant_id);
CREATE INDEX idx_timeline_event_type ON matches.timeline_events (event_type);
CREATE INDEX idx_timeline_round ON matches.timeline_events (round_id);

-- =====================================================
-- Functions for Match Processing
-- =====================================================
CREATE OR REPLACE FUNCTION matches.extract_patch_from_version(game_version VARCHAR(20))
RETURNS VARCHAR(10) AS $$
BEGIN
    RETURN substring(game_version from 'Version ([0-9]+\.[0-9]+[a-z]?)');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION matches.get_queue_type_from_id(queue_id INTEGER)
RETURNS VARCHAR(30) AS $$
BEGIN
    RETURN CASE queue_id
        WHEN 1090 THEN 'NORMAL'
        WHEN 1100 THEN 'RANKED_TFT'
        WHEN 1130 THEN 'RANKED_TFT_TURBO'
        WHEN 1160 THEN 'RANKED_TFT_DOUBLE_UP'
        ELSE 'UNKNOWN'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- Function to Calculate Team Composition Hash
-- =====================================================
CREATE OR REPLACE FUNCTION matches.calculate_comp_hash(
    traits_json JSONB,
    units_json JSONB
) RETURNS VARCHAR(64) AS $$
DECLARE
    comp_string TEXT := '';
    trait_element JSONB;
    unit_element JSONB;
    trait_parts TEXT[] := '{}';
    unit_parts TEXT[] := '{}';
BEGIN
    FOR trait_element IN SELECT * FROM jsonb_array_elements(traits_json)
    LOOP
        IF (trait_element->>'num_units')::int >= 2 AND (trait_element->>'style')::int > 0 THEN
            trait_parts := array_append(trait_parts, 
                trait_element->>'name' || ':' || (trait_element->>'num_units')::text
            );
        END IF;
    END LOOP;
    
    FOR unit_element IN SELECT * FROM jsonb_array_elements(units_json)
    LOOP
        IF (unit_element->>'rarity')::int >= 3 OR 
           ((unit_element->>'rarity')::int >= 2 AND (unit_element->>'tier')::int >= 2) THEN
            unit_parts := array_append(unit_parts, 
                unit_element->>'character_id' || ':' || (unit_element->>'tier')::text
            );
        END IF;
    END LOOP;
    
    SELECT array_to_string(array(SELECT unnest(trait_parts) ORDER BY 1), '|') INTO comp_string;
    comp_string := comp_string || '||' || array_to_string(array(SELECT unnest(unit_parts) ORDER BY 1), '|');
    
    RETURN encode(digest(comp_string, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- Trigger to Auto-Update Patch Version
-- =====================================================
CREATE OR REPLACE FUNCTION matches.extract_patch_trigger()
RETURNS TRIGGER AS $$
BEGIN
    NEW.patch_version = matches.extract_patch_from_version(NEW.game_version);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_extract_patch
    BEFORE INSERT OR UPDATE ON matches.matches
    FOR EACH ROW
    EXECUTE FUNCTION matches.extract_patch_trigger();

-- =====================================================
-- Materialized View for Match Statistics
-- =====================================================
CREATE MATERIALIZED VIEW matches.match_stats AS
SELECT 
    m.region,
    m.patch_version,
    m.queue_id,
    matches.get_queue_type_from_id(m.queue_id) as queue_type,
    DATE(to_timestamp(m.game_datetime)) as game_date,
    
    COUNT(*) as total_matches,
    AVG(m.game_length) as avg_game_length,
    COUNT(DISTINCT p.puuid) as unique_players,
    AVG(p.total_damage_to_players) as avg_damage_per_player,
    AVG(p.level) as avg_level,
    
    COUNT(*) FILTER (WHERE p.placement = 1) as total_wins,
    COUNT(*) FILTER (WHERE p.placement <= 4) as total_top4,
    
    MIN(m.created_at) as first_match,
    MAX(m.created_at) as last_match
FROM matches.matches m
JOIN matches.participants p ON m.match_id = p.match_id
GROUP BY m.region, m.patch_version, m.queue_id, DATE(to_timestamp(m.game_datetime))
ORDER BY m.region, m.patch_version, game_date DESC;

-- Index on materialized view
CREATE UNIQUE INDEX idx_match_stats_unique ON matches.match_stats (
    region, patch_version, queue_id, game_date
);
CREATE INDEX idx_match_stats_region_patch ON matches.match_stats (region, patch_version);
CREATE INDEX idx_match_stats_date ON matches.match_stats (game_date DESC);

-- =====================================================
-- View for Recent Player Matches
-- =====================================================
CREATE VIEW matches.recent_player_matches AS
SELECT 
    p.puuid,
    p.match_id,
    m.game_datetime,
    m.patch_version,
    m.queue_id,
    matches.get_queue_type_from_id(m.queue_id) as queue_type,
    m.game_length,
    
    p.placement,
    p.level,
    p.total_damage_to_players,
    p.gold_left,
    p.last_round,
    
    p.traits,
    p.units,
    p.augments,
    
    matches.calculate_comp_hash(p.traits, p.units) as comp_hash,
    
    to_timestamp(m.game_datetime) as game_date,
    m.region
FROM matches.participants p
JOIN matches.matches m ON p.match_id = m.match_id
ORDER BY m.game_datetime DESC;

-- =====================================================
-- Function to Refresh Match Stats
-- =====================================================
CREATE OR REPLACE FUNCTION matches.refresh_match_stats()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY matches.match_stats;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Function for Match Cleanup (Remove old matches)
-- =====================================================
CREATE OR REPLACE FUNCTION matches.cleanup_old_matches(
    days_old INTEGER DEFAULT 180
)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM matches.matches 
    WHERE created_at < NOW() - INTERVAL '1 day' * days_old;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    PERFORM matches.refresh_match_stats();
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Grant Permissions
-- =====================================================
GRANT USAGE ON SCHEMA matches TO tft_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA matches TO tft_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA matches TO tft_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA matches TO tft_user;

-- =====================================================
-- Comments
-- =====================================================
COMMENT ON SCHEMA matches IS 'Schema for TFT match data including games, participants and timeline events';
COMMENT ON TABLE matches.matches IS 'Main matches table with game metadata';
COMMENT ON TABLE matches.participants IS 'Individual participant data for each match';
COMMENT ON TABLE matches.timeline_events IS 'Optional detailed timeline events for advanced analysis';
COMMENT ON MATERIALIZED VIEW matches.match_stats IS 'Aggregated match statistics by region, patch and date';
COMMENT ON FUNCTION matches.calculate_comp_hash(JSONB, JSONB) IS 'Calculates unique hash for team composition based on traits and units';
COMMENT ON FUNCTION matches.cleanup_old_matches(INTEGER) IS 'Removes matches older than specified days';