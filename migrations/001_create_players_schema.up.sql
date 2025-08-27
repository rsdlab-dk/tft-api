-- =====================================================
-- TFT Arena - Players Schema Migration  
-- File: migrations/001_create_players.up.sql
-- =====================================================

-- Create players schema
CREATE SCHEMA IF NOT EXISTS players;

-- =====================================================
-- Base Players Table
-- =====================================================
CREATE TABLE players.summoners (
    id SERIAL PRIMARY KEY,
    puuid VARCHAR(78) UNIQUE NOT NULL,
    summoner_id VARCHAR(63) UNIQUE NOT NULL,
    account_id VARCHAR(56) NOT NULL,
    name VARCHAR(16) NOT NULL,
    game_name VARCHAR(16),
    tag_line VARCHAR(5),
    profile_icon_id INTEGER NOT NULL,
    summoner_level INTEGER NOT NULL,
    region VARCHAR(10) NOT NULL,
    revision_date BIGINT NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_match_update TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT check_puuid_length CHECK (length(puuid) = 78),
    CONSTRAINT check_summoner_level_positive CHECK (summoner_level > 0),
    CONSTRAINT check_region_valid CHECK (region IN (
        'br1', 'eun1', 'euw1', 'jp1', 'kr', 'la1', 'la2', 'na1', 
        'oc1', 'ru', 'sg2', 'tr1', 'tw2', 'vn2'
    ))
);

-- =====================================================
-- League Rankings Table
-- =====================================================
CREATE TABLE players.league_entries (
    id SERIAL PRIMARY KEY,
    puuid VARCHAR(78) NOT NULL REFERENCES players.summoners(puuid) ON DELETE CASCADE,
    league_id VARCHAR(36),
    queue_type VARCHAR(20) NOT NULL,
    tier VARCHAR(20) NOT NULL,
    rank_division VARCHAR(5),
    league_points INTEGER NOT NULL,
    wins INTEGER NOT NULL DEFAULT 0,
    losses INTEGER NOT NULL DEFAULT 0,
    hot_streak BOOLEAN DEFAULT FALSE,
    veteran BOOLEAN DEFAULT FALSE,
    fresh_blood BOOLEAN DEFAULT FALSE,
    inactive BOOLEAN DEFAULT FALSE,
    region VARCHAR(10) NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_queue_type CHECK (queue_type IN (
        'RANKED_TFT', 'RANKED_TFT_TURBO', 'RANKED_TFT_DOUBLE_UP'
    )),
    CONSTRAINT check_tier_valid CHECK (tier IN (
        'IRON', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'EMERALD',
        'DIAMOND', 'MASTER', 'GRANDMASTER', 'CHALLENGER'
    )),
    CONSTRAINT check_rank_division CHECK (rank_division IN ('I', 'II', 'III', 'IV', NULL)),
    CONSTRAINT check_league_points CHECK (league_points >= 0),
    CONSTRAINT check_wins_positive CHECK (wins >= 0),
    CONSTRAINT check_losses_positive CHECK (losses >= 0),
    
    UNIQUE(puuid, queue_type, region)
);

-- =====================================================
-- Player Statistics Table
-- =====================================================
CREATE TABLE players.player_stats (
    id SERIAL PRIMARY KEY,
    puuid VARCHAR(78) NOT NULL REFERENCES players.summoners(puuid) ON DELETE CASCADE,
    region VARCHAR(10) NOT NULL,
    patch_version VARCHAR(10) NOT NULL,
    queue_type VARCHAR(20) NOT NULL,
    
    total_games INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    top4_finishes INTEGER DEFAULT 0,
    total_damage_dealt BIGINT DEFAULT 0,
    total_gold_earned BIGINT DEFAULT 0,
    
    avg_placement DECIMAL(4,2),
    win_rate DECIMAL(5,2),
    top4_rate DECIMAL(5,2),
    avg_damage_per_game INTEGER,
    avg_gold_per_game INTEGER,
    
    last_game_time BIGINT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_total_games_positive CHECK (total_games >= 0),
    CONSTRAINT check_wins_valid CHECK (wins >= 0 AND wins <= total_games),
    CONSTRAINT check_top4_valid CHECK (top4_finishes >= wins AND top4_finishes <= total_games),
    CONSTRAINT check_avg_placement_valid CHECK (avg_placement >= 1 AND avg_placement <= 8),
    CONSTRAINT check_rates_valid CHECK (
        win_rate >= 0 AND win_rate <= 100 AND 
        top4_rate >= 0 AND top4_rate <= 100
    ),
    
    UNIQUE(puuid, region, patch_version, queue_type)
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Summoners indexes
CREATE INDEX idx_summoners_puuid ON players.summoners (puuid);
CREATE INDEX idx_summoners_summoner_id ON players.summoners (summoner_id);
CREATE INDEX idx_summoners_name ON players.summoners (name);
CREATE INDEX idx_summoners_region ON players.summoners (region);
CREATE INDEX idx_summoners_updated ON players.summoners (updated_at DESC);

-- Game name search (case-insensitive)
CREATE INDEX idx_summoners_game_name ON players.summoners USING gin(to_tsvector('simple', game_name));

-- League entries indexes
CREATE INDEX idx_league_entries_puuid ON players.league_entries (puuid);
CREATE INDEX idx_league_entries_region ON players.league_entries (region);
CREATE INDEX idx_league_entries_tier ON players.league_entries (tier);
CREATE INDEX idx_league_entries_queue ON players.league_entries (queue_type);

-- Leaderboard queries
CREATE INDEX idx_league_entries_leaderboard ON players.league_entries (
    region, queue_type, tier, league_points DESC
) WHERE tier IN ('CHALLENGER', 'GRANDMASTER', 'MASTER');

-- Player stats indexes
CREATE INDEX idx_player_stats_puuid ON players.player_stats (puuid);
CREATE INDEX idx_player_stats_region_patch ON players.player_stats (region, patch_version);
CREATE INDEX idx_player_stats_last_updated ON players.player_stats (last_updated DESC);

-- Performance sorting indexes
CREATE INDEX idx_player_stats_win_rate ON players.player_stats (win_rate DESC) WHERE total_games >= 20;
CREATE INDEX idx_player_stats_avg_placement ON players.player_stats (avg_placement ASC) WHERE total_games >= 20;

-- =====================================================
-- Functions for Player Updates
-- =====================================================
CREATE OR REPLACE FUNCTION players.update_player_stats_from_game(
    p_puuid VARCHAR(78),
    p_region VARCHAR(10),
    p_patch VARCHAR(10),
    p_queue_type VARCHAR(20),
    p_placement INTEGER,
    p_damage INTEGER,
    p_gold INTEGER,
    p_game_time BIGINT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO players.player_stats (
        puuid, region, patch_version, queue_type,
        total_games, wins, top4_finishes, 
        total_damage_dealt, total_gold_earned, last_game_time
    )
    VALUES (
        p_puuid, p_region, p_patch, p_queue_type,
        1, 
        CASE WHEN p_placement = 1 THEN 1 ELSE 0 END,
        CASE WHEN p_placement <= 4 THEN 1 ELSE 0 END,
        p_damage, p_gold, p_game_time
    )
    ON CONFLICT (puuid, region, patch_version, queue_type) 
    DO UPDATE SET
        total_games = players.player_stats.total_games + 1,
        wins = players.player_stats.wins + CASE WHEN p_placement = 1 THEN 1 ELSE 0 END,
        top4_finishes = players.player_stats.top4_finishes + CASE WHEN p_placement <= 4 THEN 1 ELSE 0 END,
        total_damage_dealt = players.player_stats.total_damage_dealt + p_damage,
        total_gold_earned = players.player_stats.total_gold_earned + p_gold,
        last_game_time = GREATEST(players.player_stats.last_game_time, p_game_time),
        last_updated = NOW();
        
    UPDATE players.player_stats 
    SET 
        avg_placement = (
            SELECT AVG(placement) 
            FROM matches.participants mp
            JOIN matches.matches m ON mp.match_id = m.match_id
            WHERE mp.puuid = p_puuid 
              AND m.region = p_region 
              AND m.patch_version = p_patch
              AND m.queue_id = (
                CASE p_queue_type 
                    WHEN 'RANKED_TFT' THEN 1100
                    WHEN 'RANKED_TFT_TURBO' THEN 1130
                    WHEN 'RANKED_TFT_DOUBLE_UP' THEN 1160
                    ELSE 1100
                END
              )
        ),
        win_rate = (wins::DECIMAL / NULLIF(total_games, 0)) * 100,
        top4_rate = (top4_finishes::DECIMAL / NULLIF(total_games, 0)) * 100,
        avg_damage_per_game = total_damage_dealt / NULLIF(total_games, 0),
        avg_gold_per_game = total_gold_earned / NULLIF(total_games, 0)
    WHERE puuid = p_puuid 
      AND region = p_region 
      AND patch_version = p_patch 
      AND queue_type = p_queue_type;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Trigger to Update Summoner Timestamp
-- =====================================================
CREATE OR REPLACE FUNCTION players.update_summoner_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_summoner_timestamp
    BEFORE UPDATE ON players.summoners
    FOR EACH ROW
    EXECUTE FUNCTION players.update_summoner_timestamp();

-- =====================================================
-- View for Complete Player Information
-- =====================================================
CREATE VIEW players.player_overview AS
SELECT 
    s.puuid,
    s.summoner_id,
    s.name,
    s.game_name,
    s.tag_line,
    s.summoner_level,
    s.region,
    s.profile_icon_id,
    
    le.tier,
    le.rank_division,
    le.league_points,
    le.wins as ranked_wins,
    le.losses as ranked_losses,
    ROUND((le.wins::DECIMAL / NULLIF(le.wins + le.losses, 0)) * 100, 2) as ranked_win_rate,
    
    ps.total_games,
    ps.avg_placement,
    ps.win_rate,
    ps.top4_rate,
    ps.avg_damage_per_game,
    
    s.updated_at,
    s.last_match_update
FROM players.summoners s
LEFT JOIN players.league_entries le ON s.puuid = le.puuid AND le.queue_type = 'RANKED_TFT'
LEFT JOIN players.player_stats ps ON s.puuid = ps.puuid AND ps.queue_type = 'RANKED_TFT'
WHERE s.region = le.region OR le.region IS NULL;

-- =====================================================
-- Grant Permissions
-- =====================================================
GRANT USAGE ON SCHEMA players TO tft_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA players TO tft_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA players TO tft_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA players TO tft_user;

-- =====================================================
-- Comments
-- =====================================================
COMMENT ON SCHEMA players IS 'Schema for TFT player data including summoners, league entries and statistics';
COMMENT ON TABLE players.summoners IS 'Base summoner information from Riot API';
COMMENT ON TABLE players.league_entries IS 'Ranked league information for each player';
COMMENT ON TABLE players.player_stats IS 'Aggregated player statistics by patch and queue type';
COMMENT ON VIEW players.player_overview IS 'Complete player information view combining all player data';