package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"
)

type TeamComposition struct {
	ID          int                  `json:"id" db:"id"`
	CompHash    string               `json:"comp_hash" db:"comp_hash"`
	Patch       string               `json:"patch" db:"patch_version"`
	Region      string               `json:"region" db:"region"`
	Tier        string               `json:"tier" db:"tier"`
	Traits      TraitDataSlice       `json:"traits" db:"traits"`
	Units       UnitDataSlice        `json:"units" db:"units"`
	TotalGames  int                  `json:"total_games" db:"total_games"`
	TotalWins   int                  `json:"total_wins" db:"total_wins"`
	TotalTop4   int                  `json:"total_top4" db:"total_top4"`
	AvgPlace    float64              `json:"avg_placement" db:"avg_placement"`
	WinRate     float64              `json:"win_rate" db:"win_rate"`
	Top4Rate    float64              `json:"top4_rate" db:"top4_rate"`
	PickRate    float64              `json:"pick_rate" db:"pick_rate"`
	TierRank    string               `json:"tier_rank" db:"tier_rank"`
	SampleSize  string               `json:"sample_size" db:"sample_size"`
	FirstSeen   time.Time            `json:"first_seen" db:"first_seen"`
	LastSeen    time.Time            `json:"last_seen" db:"last_seen"`
	LastUpdated time.Time            `json:"last_updated" db:"last_updated"`
}

type CompositionGame struct {
	ID            int           `json:"id" db:"id"`
	MatchID       string        `json:"match_id" db:"match_id"`
	ParticipantID int           `json:"participant_id" db:"participant_id"`
	CompHash      string        `json:"comp_hash" db:"comp_hash"`
	PUUID         string        `json:"puuid" db:"puuid"`
	Placement     int           `json:"placement" db:"placement"`
	Level         int           `json:"level" db:"level"`
	GoldLeft      int           `json:"gold_left" db:"gold_left"`
	TotalDamage   int           `json:"total_damage" db:"total_damage"`
	FinalTraits   TraitDataSlice `json:"final_traits" db:"final_traits"`
	FinalUnits    UnitDataSlice  `json:"final_units" db:"final_units"`
	GameDatetime  int64         `json:"game_datetime" db:"game_datetime"`
	CreatedAt     time.Time     `json:"created_at" db:"created_at"`
}

type TraitData struct {
	Name      string `json:"name"`
	Count     int    `json:"count"`
	Style     int    `json:"style"`
	TierTotal int    `json:"tier_total"`
}

type UnitData struct {
	Champion string `json:"champion"`
	Cost     int    `json:"cost"`
	Items    []int  `json:"items"`
	Tier     int    `json:"tier"`
}

type TraitDataSlice []TraitData

func (t TraitDataSlice) Value() (driver.Value, error) {
	return json.Marshal(t)
}

func (t *TraitDataSlice) Scan(value interface{}) error {
	if value == nil {
		*t = TraitDataSlice{}
		return nil
	}

	switch v := value.(type) {
	case []byte:
		return json.Unmarshal(v, t)
	case string:
		return json.Unmarshal([]byte(v), t)
	default:
		return fmt.Errorf("cannot scan %T into TraitDataSlice", value)
	}
}

type UnitDataSlice []UnitData

func (u UnitDataSlice) Value() (driver.Value, error) {
	return json.Marshal(u)
}

func (u *UnitDataSlice) Scan(value interface{}) error {
	if value == nil {
		*u = UnitDataSlice{}
		return nil
	}

	switch v := value.(type) {
	case []byte:
		return json.Unmarshal(v, t)
	case string:
		return json.Unmarshal([]byte(v), u)
	default:
		return fmt.Errorf("cannot scan %T into UnitDataSlice", value)
	}
}

type CompositionFilters struct {
	Patch     string   `json:"patch" form:"patch"`
	Region    string   `json:"region" form:"region"`
	Tier      string   `json:"tier" form:"tier"`
	TierRank  string   `json:"tier_rank" form:"tier_rank"`
	SortBy    string   `json:"sort_by" form:"sort" validate:"oneof=win_rate pick_rate avg_placement top4_rate total_games"`
	Order     string   `json:"order" form:"order" validate:"oneof=asc desc"`
	Limit     int      `json:"limit" form:"limit" validate:"min=1,max=100"`
	Offset    int      `json:"offset" form:"offset" validate:"min=0"`
	MinGames  int      `json:"min_games" form:"min_games" validate:"min=1"`
	Traits    []string `json:"traits,omitempty" form:"traits"`
	Champions []string `json:"champions,omitempty" form:"champions"`
}

func (f *CompositionFilters) SetDefaults() {
	if f.Patch == "" {
		f.Patch = "15.2c"
	}
	if f.Region == "" {
		f.Region = "kr"
	}
	if f.Tier == "" {
		f.Tier = "CHALLENGER"
	}
	if f.SortBy == "" {
		f.SortBy = "win_rate"
	}
	if f.Order == "" {
		f.Order = "desc"
	}
	if f.Limit == 0 {
		f.Limit = 50
	}
	if f.MinGames == 0 {
		f.MinGames = 100
	}
}

type MetaSnapshot struct {
	Patch       string             `json:"patch"`
	Region      string             `json:"region"`
	TotalGames  int                `json:"total_games"`
	STierComps  []TeamComposition  `json:"s_tier"`
	ATierComps  []TeamComposition  `json:"a_tier"`
	BTierComps  []TeamComposition  `json:"b_tier"`
	TopTraits   []TraitMeta        `json:"top_traits"`
	TopChamps   []ChampionMeta     `json:"top_champions"`
	LastUpdated time.Time          `json:"last_updated"`
}

type TraitMeta struct {
	Name        string  `json:"name"`
	PlayRate    float64 `json:"play_rate" db:"play_rate"`
	WinRate     float64 `json:"win_rate" db:"win_rate"`
	AvgCount    float64 `json:"avg_count" db:"avg_count"`
	TotalGames  int     `json:"total_games" db:"total_games"`
	Description string  `json:"description,omitempty"`
}

type ChampionMeta struct {
	Name       string  `json:"name"`
	PlayRate   float64 `json:"play_rate" db:"play_rate"`
	WinRate    float64 `json:"win_rate" db:"win_rate"`
	AvgTier    float64 `json:"avg_tier" db:"avg_tier"`
	Cost       int     `json:"cost" db:"cost"`
	TotalGames int     `json:"total_games" db:"total_games"`
}

type FilterOptions struct {
	Patches   []string `json:"patches"`
	Regions   []string `json:"regions"`
	Tiers     []string `json:"tiers"`
	Traits    []string `json:"traits"`
	Champions []string `json:"champions"`
}

type CompositionDetail struct {
	*TeamComposition
	RecentGames      []CompositionGame    `json:"recent_games"`
	PlacementDist    PlacementDistribution `json:"placement_distribution"`
	TrendData        []TrendDataPoint     `json:"trend_data"`
	SimilarComps     []TeamComposition    `json:"similar_comps"`
	PlayerExamples   []PlayerExample      `json:"player_examples"`
}

type PlacementDistribution struct {
	Place1 int `json:"place_1"`
	Place2 int `json:"place_2"`
	Place3 int `json:"place_3"`
	Place4 int `json:"place_4"`
	Place5 int `json:"place_5"`
	Place6 int `json:"place_6"`
	Place7 int `json:"place_7"`
	Place8 int `json:"place_8"`
}

type TrendDataPoint struct {
	Date     time.Time `json:"date"`
	WinRate  float64   `json:"win_rate"`
	PickRate float64   `json:"pick_rate"`
	Games    int       `json:"games"`
}

type PlayerExample struct {
	PUUID      string  `json:"puuid"`
	GameName   string  `json:"game_name"`
	TagLine    string  `json:"tag_line"`
	Placement  int     `json:"placement"`
	Level      int     `json:"level"`
	Damage     int     `json:"damage"`
	MatchID    string  `json:"match_id"`
	GameDate   int64   `json:"game_date"`
}

type ExtractedComposition struct {
	Traits []TraitData `json:"traits"`
	Units  []UnitData  `json:"units"`
}

type CompositionHash struct {
	MainTraits []string `json:"main_traits"`
	MainUnits  []string `json:"main_units"`
	CoreItems  []int    `json:"core_items,omitempty"`
}

func (tc *TeamComposition) CalculateTierRank() string {
	if tc.WinRate >= 25 && tc.PickRate >= 5 && tc.TotalGames >= 500 {
		return "S"
	}
	if tc.WinRate >= 20 && tc.PickRate >= 3 && tc.TotalGames >= 300 {
		return "A"
	}
	if tc.WinRate >= 15 && tc.PickRate >= 1 && tc.TotalGames >= 100 {
		return "B"
	}
	return "C"
}

func (tc *TeamComposition) GetCompName() string {
	if len(tc.Traits) == 0 {
		return "Flex Comp"
	}

	mainTraits := make([]string, 0, 2)
	for _, trait := range tc.Traits {
		if trait.Count >= 3 && len(mainTraits) < 2 {
			mainTraits = append(mainTraits, trait.Name)
		}
	}

	if len(mainTraits) == 0 {
		return "Flex Comp"
	}

	if len(mainTraits) == 1 {
		return mainTraits[0]
	}

	return mainTraits[0] + " " + mainTraits[1]
}

func (tc *TeamComposition) GetCarryChampions() []string {
	carries := make([]string, 0)
	for _, unit := range tc.Units {
		if unit.Cost >= 4 || (unit.Cost >= 3 && len(unit.Items) >= 2) {
			carries = append(carries, unit.Champion)
		}
	}
	return carries
}

func (tc *TeamComposition) IsValid() bool {
	if len(tc.Traits) < 2 || len(tc.Units) < 6 {
		return false
	}

	activeTraits := 0
	for _, trait := range tc.Traits {
		if trait.Count >= 2 {
			activeTraits++
		}
	}

	return activeTraits >= 2 && tc.TotalGames >= 10
}

func (f *CompositionFilters) ToQueryParams() map[string]interface{} {
	params := make(map[string]interface{})
	
	if f.Patch != "" {
		params["patch_version"] = f.Patch
	}
	if f.Region != "" {
		params["region"] = f.Region
	}
	if f.Tier != "" {
		params["tier"] = f.Tier
	}
	if f.TierRank != "" {
		params["tier_rank"] = f.TierRank
	}
	if f.MinGames > 0 {
		params["min_games"] = f.MinGames
	}
	
	return params
}

func (pd *PlacementDistribution) GetTopPlacements() int {
	return pd.Place1 + pd.Place2 + pd.Place3 + pd.Place4
}

func (pd *PlacementDistribution) GetTotal() int {
	return pd.Place1 + pd.Place2 + pd.Place3 + pd.Place4 + 
		   pd.Place5 + pd.Place6 + pd.Place7 + pd.Place8
}

func (pd *PlacementDistribution) GetTop4Rate() float64 {
	total := pd.GetTotal()
	if total == 0 {
		return 0
	}
	return float64(pd.GetTopPlacements()) / float64(total) * 100
}