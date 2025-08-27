-- =====================================================
-- TFT Arena - Analytics Schema Migration
-- File: migrations/004_create_analytics.up.sql
-- =====================================================

-- Create analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- =====================================================
-- Meta Analysis Tables
-- =====================================================
CREATE TABLE analytics.trait_meta (
    id SERIAL PRIMARY KEY,
    trait_name VARCHAR(50) NOT NULL,
    patch_version VARCHAR(10) NOT NULL,
    region VARCHAR(10) NOT NULL,
    tier VARCHAR(20) NOT NULL,
    
    play_rate DECIMAL(5,2) NOT NULL,
    win_rate DECIMAL(5,2) NOT NULL,
    avg_placement DECIMAL(4,2) NOT NULL,
    avg_count DECIMAL(4,2) NOT NULL,
    
    total_games INTEGER NOT NULL,
    total_wins INTEGER NOT NULL,
    total_top4 INTEGER NOT NULL,
    
    style_distribution JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_play_rate_valid CHECK (play_rate >= 0 AND play_rate <= 100),
    CONSTRAINT check_win_rate_valid CHECK (win_rate >= 0 AND win_rate <= 100),
    CONSTRAINT check_avg_placement_valid CHECK (avg_placement >= 1 AND avg_placement <= 8),
    CONSTRAINT check_games_positive CHECK (total_games > 0),
    
    UNIQUE(trait_name, patch_version, region, tier)
);

CREATE TABLE analytics.champion_meta (
    id SERIAL PRIMARY KEY,
    champion_name VARCHAR(50) NOT NULL,
    patch_version VARCHAR(10) NOT NULL,
    region VARCHAR(10) NOT NULL,
    tier VARCHAR(20) NOT NULL,
    
    play_rate DECIMAL(5,2) NOT NULL,
    win_rate DECIMAL(5,2) NOT NULL,
    avg_placement DECIMAL(4,2) NOT NULL,
    avg_tier DECIMAL(3,1) NOT NULL,
    cost INTEGER NOT NULL,
    
    total_games INTEGER NOT NULL,
    total_wins INTEGER NOT NULL,
    total_top4 INTEGER NOT NULL,
    
    item_usage JSONB,
    position_stats JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_play_rate_valid CHECK (play_rate >= 0 AND play_rate <= 100),
    CONSTRAINT check_win_rate_valid CHECK (win_rate >= 0 AND win_rate <= 100),
    CONSTRAINT check_avg_placement_valid CHECK (avg_placement >= 1 AND avg_placement <= 8),
    CONSTRAINT check_avg_tier_valid CHECK (avg_tier >= 1 AND avg_tier <= 3),
    CONSTRAINT check_cost_valid CHECK (cost >= 1 AND cost <= 5),
    CONSTRAINT check_games_positive CHECK (total_games > 0),
    
    UNIQUE(champion_name, patch_version, region, tier)
);

CREATE TABLE analytics.item_meta (
    id SERIAL PRIMARY KEY,
    item_name VARCHAR(50) NOT NULL,
    item_id INTEGER NOT NULL,
    patch_version VARCHAR(10) NOT NULL,
    region VARCHAR(10) NOT NULL,
    tier VARCHAR(20) NOT NULL,
    
    play_rate DECIMAL(5,2) NOT NULL,
    win_rate DECIMAL(5,2) NOT NULL,
    avg_placement DECIMAL(4,2) NOT NULL,
    
    total_games INTEGER NOT NULL,
    total_wins INTEGER NOT NULL,
    total_top4 INTEGER NOT NULL,
    
    champion_usage JSONB,
    position_preference JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_play_rate_valid CHECK (play_rate >= 0 AND play_rate <= 100),
    CONSTRAINT check_win_rate_valid CHECK (win_rate >= 0 AND win_rate <= 100),
    CONSTRAINT check_avg_placement_valid CHECK (avg_placement >= 1 AND avg_placement <= 8),
    CONSTRAINT check_games_positive CHECK (total_games > 0),
    CONSTRAINT check_item_id_positive CHECK (item_id > 0),
    
    UNIQUE(item_id, patch_version, region, tier)
);

-- =====================================================
-- Augment Analysis Table
-- =====================================================
CREATE TABLE analytics.augment_meta (
    id SERIAL PRIMARY KEY,
    augment_name VARCHAR(100) NOT NULL,
    augment_id VARCHAR(50) NOT NULL,
    tier INTEGER NOT NULL,
    patch_version VARCHAR(10) NOT NULL,
    region VARCHAR(10) NOT NULL,
    player_tier VARCHAR(20) NOT NULL,
    
    pick_rate DECIMAL(5,2) NOT NULL,
    win_rate DECIMAL(5,2) NOT NULL,
    avg_placement DECIMAL(4,2) NOT NULL,
    
    total_picks INTEGER NOT NULL,
    total_wins INTEGER NOT NULL,
    total_top4 INTEGER NOT NULL,
    
    synergy_data JSONB,
    round_picked_stats JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_tier_valid CHECK (tier IN (1, 2, 3)),
    CONSTRAINT check_pick_rate_valid CHECK (pick_rate >= 0 AND pick_rate <= 100),
    CONSTRAINT check_win_rate_valid CHECK (win_rate >= 0 AND win_rate <= 100),
    CONSTRAINT check_avg_placement_valid CHECK (avg_placement >= 1 AND avg_placement <= 8),
    CONSTRAINT check_picks_positive CHECK (total_picks > 0),
    
    UNIQUE(augment_id, tier, patch_version, region, player_tier)
);

-- =====================================================
-- Daily Snapshots for Trend Analysis
-- =====================================================
CREATE TABLE analytics.daily_snapshots (
    id SERIAL PRIMARY KEY,
    snapshot_date DATE NOT NULL,
    patch_version VARCHAR(10) NOT NULL,
    region VARCHAR(10) NOT NULL,
    tier VARCHAR(20) NOT NULL,
    
    total_games INTEGER NOT NULL,
    unique_players INTEGER NOT NULL,
    avg_game_length REAL NOT NULL,
    
    top_compositions JSONB NOT NULL,
    top_traits JSONB NOT NULL,
    top_champions JSONB NOT NULL,
    
    meta_diversity_score DECIMAL(5,2),
    average_placement_variance DECIMAL(5,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_games_positive CHECK (total_games > 0),
    CONSTRAINT check_players_positive CHECK (unique_players > 0),
    CONSTRAINT check_game_length_valid CHECK (avg_game_length > 0),
    
    UNIQUE(snapshot_date, patch_version, region, tier)
);

-- =====================================================
-- Patch Transition Analysis
-- =====================================================
CREATE TABLE analytics.patch_transitions (
    id SERIAL PRIMARY KEY,
    from_patch VARCHAR(10) NOT NULL,
    to_patch VARCHAR(10) NOT NULL,
    region VARCHAR(10) NOT NULL,
    tier VARCHAR(20) NOT NULL,
    
    transition_date DATE NOT NULL,
    
    composition_changes JSONB NOT NULL,
    trait_changes JSONB NOT NULL,
    champion_changes JSONB NOT NULL,
    
    meta_shift_score DECIMAL(5,2),
    power_level_change DECIMAL(5,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(from_patch, to_patch, region, tier)
);

-- =====================================================
-- Performance Indexes
-- =====================================================

-- Trait meta indexes
CREATE INDEX idx_trait_meta_patch_region_tier ON analytics.trait_meta (patch_version, region, tier);
CREATE INDEX idx_trait_meta_name ON analytics.trait_meta (trait_name);
CREATE INDEX idx_trait_meta_play_rate ON analytics.trait_meta (play_rate DESC);
CREATE INDEX idx_trait_meta_win_rate ON analytics.trait_meta (win_rate DESC);

-- Champion meta indexes
CREATE INDEX idx_champion_meta_patch_region_tier ON analytics.champion_meta (patch_version, region, tier);
CREATE INDEX idx_champion_meta_name ON analytics.champion_meta (champion_name);
CREATE INDEX idx_champion_meta_cost ON analytics.champion_meta (cost);
CREATE INDEX idx_champion_meta_play_rate ON analytics.champion_meta (play_rate DESC);
CREATE INDEX idx_champion_meta_win_rate ON analytics.champion_meta (win_rate DESC);

-- Item meta indexes
CREATE INDEX idx_item_meta_patch_region_tier ON analytics.item_meta (patch_version, region, tier);
CREATE INDEX idx_item_meta_item_id ON analytics.item_meta (item_id);
CREATE INDEX idx_item_meta_play_rate ON analytics.item_meta (play_rate DESC);

-- Augment meta indexes
CREATE INDEX idx_augment_meta_patch_region_tier ON analytics.augment_meta (patch_version, region, player_tier);
CREATE INDEX idx_augment_meta_tier ON analytics.augment_meta (tier);
CREATE INDEX idx_augment_meta_pick_rate ON analytics.augment_meta (pick_rate DESC);

-- Daily snapshots indexes
CREATE INDEX idx_daily_snapshots_date ON analytics.daily_snapshots (snapshot_date DESC);
CREATE INDEX idx_daily_snapshots_patch_region ON analytics.daily_snapshots (patch_version, region);

-- Patch transitions indexes
CREATE INDEX idx_patch_transitions_patches ON analytics.patch_transitions (from_patch, to_patch);
CREATE INDEX idx_patch_transitions_date ON analytics.patch_transitions (transition_date DESC);

-- =====================================================
-- Materialized Views for Meta Analysis
-- =====================================================
CREATE MATERIALIZED VIEW analytics.current_meta AS
SELECT 
    tm.patch_version,
    tm.region,
    tm.tier,
    
    json_agg(
        json_build_object(
            'name', tm.trait_name,
            'play_rate', tm.play_rate,
            'win_rate', tm.win_rate,
            'avg_placement', tm.avg_placement
        ) ORDER BY tm.play_rate DESC
    ) FILTER (WHERE tm.play_rate >= 10) as top_traits,
    
    json_agg(
        json_build_object(
            'name', cm.champion_name,
            'cost', cm.cost,
            'play_rate', cm.play_rate,
            'win_rate', cm.win_rate,
            'avg_tier', cm.avg_tier
        ) ORDER BY cm.play_rate DESC
    ) FILTER (WHERE cm.play_rate >= 5) as top_champions,
    
    AVG(tm.play_rate) as trait_diversity,
    AVG(cm.play_rate) as champion_diversity,
    
    MAX(tm.updated_at) as last_updated
FROM analytics.trait_meta tm
FULL OUTER JOIN analytics.champion_meta cm 
    ON tm.patch_version = cm.patch_version 
    AND tm.region = cm.region 
    AND tm.tier = cm.tier
WHERE tm.total_games >= 100 OR cm.total_games >= 100
GROUP BY tm.patch_version, tm.region, tm.tier
ORDER BY tm.patch_version DESC, tm.region, tm.tier;

-- Index on materialized view
CREATE UNIQUE INDEX idx_current_meta_patch_region_tier ON analytics.current_meta (
    patch_version, region, tier
);

-- =====================================================
-- Functions for Meta Analysis
-- =====================================================
CREATE OR REPLACE FUNCTION analytics.calculate_meta_diversity(
    p_patch VARCHAR(10),
    p_region VARCHAR(10),
    p_tier VARCHAR(20)
)
RETURNS DECIMAL(5,2) AS $
DECLARE
    diversity_score DECIMAL(5,2);
BEGIN
    SELECT 
        ROUND(
            (1.0 - (SUM(POWER(play_rate/100.0, 2)))) * 100,
            2
        )
    INTO diversity_score
    FROM analytics.trait_meta
    WHERE patch_version = p_patch 
      AND region = p_region 
      AND tier = p_tier
      AND play_rate >= 1;
      
    RETURN COALESCE(diversity_score, 0);
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.update_meta_from_matches()
RETURNS VOID AS $
DECLARE
    current_patch VARCHAR(10);
    target_region VARCHAR(10);
BEGIN
    SELECT DISTINCT patch_version INTO current_patch
    FROM matches.matches
    ORDER BY created_at DESC
    LIMIT 1;
    
    FOR target_region IN 
        SELECT DISTINCT region FROM matches.matches 
        WHERE patch_version = current_patch
    LOOP
        PERFORM analytics.recalculate_trait_meta(current_patch, target_region, 'CHALLENGER');
        PERFORM analytics.recalculate_champion_meta(current_patch, target_region, 'CHALLENGER');
        PERFORM analytics.recalculate_item_meta(current_patch, target_region, 'CHALLENGER');
    END LOOP;
    
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.current_meta;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.recalculate_trait_meta(
    p_patch VARCHAR(10),
    p_region VARCHAR(10), 
    p_tier VARCHAR(20)
)
RETURNS VOID AS $
BEGIN
    INSERT INTO analytics.trait_meta (
        trait_name, patch_version, region, tier,
        play_rate, win_rate, avg_placement, avg_count,
        total_games, total_wins, total_top4,
        style_distribution
    )
    SELECT 
        trait_data->>'name' as trait_name,
        p_patch,
        p_region,
        p_tier,
        
        ROUND((COUNT(*)::DECIMAL / (
            SELECT COUNT(DISTINCT p2.match_id) 
            FROM matches.participants p2 
            JOIN matches.matches m2 ON p2.match_id = m2.match_id
            WHERE m2.patch_version = p_patch AND m2.region = p_region
        )) * 100, 2) as play_rate,
        
        ROUND((COUNT(*) FILTER (WHERE p.placement = 1)::DECIMAL / COUNT(*)) * 100, 2) as win_rate,
        ROUND(AVG(p.placement), 2) as avg_placement,
        ROUND(AVG((trait_data->>'num_units')::int), 2) as avg_count,
        
        COUNT(*)::int as total_games,
        COUNT(*) FILTER (WHERE p.placement = 1) as total_wins,
        COUNT(*) FILTER (WHERE p.placement <= 4) as total_top4,
        
        json_agg(
            json_build_object(
                'style', (trait_data->>'style')::int,
                'count', COUNT(*)
            )
        ) as style_distribution
        
    FROM matches.participants p
    JOIN matches.matches m ON p.match_id = m.match_id
    CROSS JOIN LATERAL jsonb_array_elements(p.traits) as trait_data
    WHERE m.patch_version = p_patch 
      AND m.region = p_region
      AND (trait_data->>'num_units')::int >= 2
      AND (trait_data->>'style')::int > 0
    GROUP BY trait_data->>'name'
    HAVING COUNT(*) >= 50
    
    ON CONFLICT (trait_name, patch_version, region, tier)
    DO UPDATE SET
        play_rate = EXCLUDED.play_rate,
        win_rate = EXCLUDED.win_rate,
        avg_placement = EXCLUDED.avg_placement,
        avg_count = EXCLUDED.avg_count,
        total_games = EXCLUDED.total_games,
        total_wins = EXCLUDED.total_wins,
        total_top4 = EXCLUDED.total_top4,
        style_distribution = EXCLUDED.style_distribution,
        updated_at = NOW();
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.recalculate_champion_meta(
    p_patch VARCHAR(10),
    p_region VARCHAR(10), 
    p_tier VARCHAR(20)
)
RETURNS VOID AS $
BEGIN
    INSERT INTO analytics.champion_meta (
        champion_name, patch_version, region, tier,
        play_rate, win_rate, avg_placement, avg_tier, cost,
        total_games, total_wins, total_top4,
        item_usage, position_stats
    )
    SELECT 
        unit_data->>'character_id' as champion_name,
        p_patch,
        p_region,
        p_tier,
        
        ROUND((COUNT(*)::DECIMAL / (
            SELECT COUNT(DISTINCT p2.match_id) 
            FROM matches.participants p2 
            JOIN matches.matches m2 ON p2.match_id = m2.match_id
            WHERE m2.patch_version = p_patch AND m2.region = p_region
        )) * 100, 2) as play_rate,
        
        ROUND((COUNT(*) FILTER (WHERE p.placement = 1)::DECIMAL / COUNT(*)) * 100, 2) as win_rate,
        ROUND(AVG(p.placement), 2) as avg_placement,
        ROUND(AVG((unit_data->>'tier')::int), 1) as avg_tier,
        (unit_data->>'rarity')::int as cost,
        
        COUNT(*)::int as total_games,
        COUNT(*) FILTER (WHERE p.placement = 1) as total_wins,
        COUNT(*) FILTER (WHERE p.placement <= 4) as total_top4,
        
        json_agg(unit_data->'items') as item_usage,
        json_build_object(
            'avg_items', AVG(jsonb_array_length(unit_data->'items')),
            'carry_rate', (COUNT(*) FILTER (WHERE jsonb_array_length(unit_data->'items') >= 2)::DECIMAL / COUNT(*)) * 100
        ) as position_stats
        
    FROM matches.participants p
    JOIN matches.matches m ON p.match_id = m.match_id
    CROSS JOIN LATERAL jsonb_array_elements(p.units) as unit_data
    WHERE m.patch_version = p_patch 
      AND m.region = p_region
    GROUP BY unit_data->>'character_id', (unit_data->>'rarity')::int
    HAVING COUNT(*) >= 100
    
    ON CONFLICT (champion_name, patch_version, region, tier)
    DO UPDATE SET
        play_rate = EXCLUDED.play_rate,
        win_rate = EXCLUDED.win_rate,
        avg_placement = EXCLUDED.avg_placement,
        avg_tier = EXCLUDED.avg_tier,
        total_games = EXCLUDED.total_games,
        total_wins = EXCLUDED.total_wins,
        total_top4 = EXCLUDED.total_top4,
        item_usage = EXCLUDED.item_usage,
        position_stats = EXCLUDED.position_stats,
        updated_at = NOW();
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.recalculate_item_meta(
    p_patch VARCHAR(10),
    p_region VARCHAR(10), 
    p_tier VARCHAR(20)
)
RETURNS VOID AS $
BEGIN
    -- This would need item mapping data to properly implement
    -- For now, just creating the structure
    RETURN;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- Function to Create Daily Snapshot
-- =====================================================
CREATE OR REPLACE FUNCTION analytics.create_daily_snapshot(
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS VOID AS $
DECLARE
    snapshot_patch VARCHAR(10);
    snapshot_region VARCHAR(10);
BEGIN
    SELECT patch_version INTO snapshot_patch
    FROM matches.matches
    WHERE DATE(to_timestamp(game_datetime)) = p_date
    ORDER BY created_at DESC
    LIMIT 1;
    
    FOR snapshot_region IN 
        SELECT DISTINCT region FROM matches.matches 
        WHERE patch_version = snapshot_patch
        AND DATE(to_timestamp(game_datetime)) = p_date
    LOOP
        INSERT INTO analytics.daily_snapshots (
            snapshot_date, patch_version, region, tier,
            total_games, unique_players, avg_game_length,
            top_compositions, top_traits, top_champions,
            meta_diversity_score
        )
        SELECT 
            p_date,
            snapshot_patch,
            snapshot_region,
            'CHALLENGER',
            
            COUNT(DISTINCT m.match_id),
            COUNT(DISTINCT p.puuid),
            AVG(m.game_length),
            
            '[]'::jsonb,
            '[]'::jsonb,
            '[]'::jsonb,
            
            analytics.calculate_meta_diversity(snapshot_patch, snapshot_region, 'CHALLENGER')
            
        FROM matches.matches m
        JOIN matches.participants p ON m.match_id = p.match_id
        WHERE m.patch_version = snapshot_patch
          AND m.region = snapshot_region
          AND DATE(to_timestamp(m.game_datetime)) = p_date
        GROUP BY snapshot_patch, snapshot_region
        
        ON CONFLICT (snapshot_date, patch_version, region, tier)
        DO UPDATE SET
            total_games = EXCLUDED.total_games,
            unique_players = EXCLUDED.unique_players,
            avg_game_length = EXCLUDED.avg_game_length,
            meta_diversity_score = EXCLUDED.meta_diversity_score;
    END LOOP;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- Grant Permissions
-- =====================================================
GRANT USAGE ON SCHEMA analytics TO tft_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA analytics TO tft_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA analytics TO tft_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA analytics TO tft_user;

-- =====================================================
-- Comments
-- =====================================================
COMMENT ON SCHEMA analytics IS 'Schema for TFT meta analysis and aggregated statistics';
COMMENT ON TABLE analytics.trait_meta IS 'Trait performance statistics by patch, region and tier';
COMMENT ON TABLE analytics.champion_meta IS 'Champion performance statistics and item usage data';
COMMENT ON TABLE analytics.augment_meta IS 'Augment pick rates and performance statistics';
COMMENT ON TABLE analytics.daily_snapshots IS 'Daily meta snapshots for trend analysis';
COMMENT ON MATERIALIZED VIEW analytics.current_meta IS 'Current meta overview with top performing traits and champions';