package models

import (
	"fmt"
	"strings"
	"time"
)

type Region string

const (
	RegionBR1  Region = "br1"
	RegionEUN1 Region = "eun1"
	RegionEUW1 Region = "euw1"
	RegionJP1  Region = "jp1"
	RegionKR   Region = "kr"
	RegionLA1  Region = "la1"
	RegionLA2  Region = "la2"
	RegionNA1  Region = "na1"
	RegionOC1  Region = "oc1"
	RegionRU   Region = "ru"
	RegionSG2  Region = "sg2"
	RegionTR1  Region = "tr1"
	RegionTW2  Region = "tw2"
	RegionVN2  Region = "vn2"
)

func (r Region) String() string {
	return string(r)
}

func (r Region) IsValid() bool {
	validRegions := map[Region]bool{
		RegionBR1: true, RegionEUN1: true, RegionEUW1: true, RegionJP1: true,
		RegionKR: true, RegionLA1: true, RegionLA2: true, RegionNA1: true,
		RegionOC1: true, RegionRU: true, RegionSG2: true, RegionTR1: true,
		RegionTW2: true, RegionVN2: true,
	}
	return validRegions[r]
}

func (r Region) ToCluster() string {
	clusterMap := map[Region]string{
		RegionBR1: "americas", RegionLA1: "americas", RegionLA2: "americas",
		RegionNA1: "americas", RegionOC1: "americas",
		RegionEUN1: "europe", RegionEUW1: "europe", RegionTR1: "europe", RegionRU: "europe",
		RegionJP1: "asia", RegionKR: "asia", RegionSG2: "asia", RegionTW2: "asia", RegionVN2: "asia",
	}
	return clusterMap[r]
}

type Tier string

const (
	TierIRON        Tier = "IRON"
	TierBRONZE      Tier = "BRONZE"
	TierSILVER      Tier = "SILVER"
	TierGOLD        Tier = "GOLD"
	TierPLATINUM    Tier = "PLATINUM"
	TierEMERALD     Tier = "EMERALD"
	TierDIAMOND     Tier = "DIAMOND"
	TierMASTER      Tier = "MASTER"
	TierGRANDMASTER Tier = "GRANDMASTER"
	TierCHALLENGER  Tier = "CHALLENGER"
)

func (t Tier) String() string {
	return string(t)
}

func (t Tier) IsValid() bool {
	validTiers := map[Tier]bool{
		TierIRON: true, TierBRONZE: true, TierSILVER: true, TierGOLD: true,
		TierPLATINUM: true, TierEMERALD: true, TierDIAMOND: true,
		TierMASTER: true, TierGRANDMASTER: true, TierCHALLENGER: true,
	}
	return validTiers[t]
}

func (t Tier) GetWeight() int {
	weights := map[Tier]int{
		TierIRON: 1, TierBRONZE: 2, TierSILVER: 3, TierGOLD: 4,
		TierPLATINUM: 5, TierEMERALD: 6, TierDIAMOND: 7,
		TierMASTER: 8, TierGRANDMASTER: 9, TierCHALLENGER: 10,
	}
	return weights[t]
}

func (t Tier) IsHighElo() bool {
	return t == TierMASTER || t == TierGRANDMASTER || t == TierCHALLENGER
}

type TierRank string

const (
	TierRankS TierRank = "S"
	TierRankA TierRank = "A"
	TierRankB TierRank = "B"
	TierRankC TierRank = "C"
	TierRankD TierRank = "D"
)

func (tr TierRank) String() string {
	return string(tr)
}

func (tr TierRank) IsValid() bool {
	return tr == TierRankS || tr == TierRankA || tr == TierRankB || tr == TierRankC || tr == TierRankD
}

func (tr TierRank) GetColor() string {
	colors := map[TierRank]string{
		TierRankS: "#ef4444", // red-500
		TierRankA: "#f97316", // orange-500
		TierRankB: "#eab308", // yellow-500
		TierRankC: "#22c55e", // green-500
		TierRankD: "#6b7280", // gray-500
	}
	return colors[tr]
}

type QueueType string

const (
	QueueTFTNormal    QueueType = "RANKED_TFT"
	QueueTFTTurbo     QueueType = "RANKED_TFT_TURBO"
	QueueTFTDoubleUp  QueueType = "RANKED_TFT_DOUBLE_UP"
	QueueTFTHyperRoll QueueType = "RANKED_TFT_HYPER_ROLL"
)

func (q QueueType) String() string {
	return string(q)
}

func (q QueueType) IsValid() bool {
	validQueues := map[QueueType]bool{
		QueueTFTNormal: true, QueueTFTTurbo: true, 
		QueueTFTDoubleUp: true, QueueTFTHyperRoll: true,
	}
	return validQueues[q]
}

func (q QueueType) GetQueueID() int {
	queueIDs := map[QueueType]int{
		QueueTFTNormal:    1100,
		QueueTFTTurbo:     1130,
		QueueTFTDoubleUp:  1160,
		QueueTFTHyperRoll: 1130,
	}
	return queueIDs[q]
}

type TraitStyle int

const (
	TraitStyleNone      TraitStyle = 0
	TraitStyleBronze    TraitStyle = 1
	TraitStyleSilver    TraitStyle = 2
	TraitStyleGold      TraitStyle = 3
	TraitStyleChromatic TraitStyle = 4
)

func (ts TraitStyle) IsActive() bool {
	return ts > TraitStyleNone
}

func (ts TraitStyle) GetCSSClass() string {
	classes := map[TraitStyle]string{
		TraitStyleNone:      "bg-gray-600 text-gray-300",
		TraitStyleBronze:    "bg-yellow-600 text-yellow-100",
		TraitStyleSilver:    "bg-gray-400 text-gray-900",
		TraitStyleGold:      "bg-yellow-400 text-yellow-900",
		TraitStyleChromatic: "bg-purple-500 text-purple-100",
	}
	return classes[ts]
}

type SampleSize string

const (
	SampleSizeHigh   SampleSize = "high"
	SampleSizeMedium SampleSize = "medium"
	SampleSizeLow    SampleSize = "low"
)

func (ss SampleSize) String() string {
	return string(ss)
}

func (ss SampleSize) GetMinGames() int {
	thresholds := map[SampleSize]int{
		SampleSizeHigh:   1000,
		SampleSizeMedium: 100,
		SampleSizeLow:    10,
	}
	return thresholds[ss]
}

func CalculateSampleSize(games int) SampleSize {
	if games >= 1000 {
		return SampleSizeHigh
	}
	if games >= 100 {
		return SampleSizeMedium
	}
	return SampleSizeLow
}

type Patch string

const (
	Patch1524 Patch = "15.24"
	Patch151  Patch = "15.1"
	Patch152  Patch = "15.2"
	Patch152c Patch = "15.2c"
)

func (p Patch) String() string {
	return string(p)
}

func (p Patch) IsValid() bool {
	return strings.Contains(string(p), "15.")
}

func (p Patch) GetMajorVersion() string {
	parts := strings.Split(string(p), ".")
	if len(parts) >= 2 {
		return parts[0] + "." + parts[1]
	}
	return string(p)
}

type SortOrder string

const (
	SortOrderASC  SortOrder = "asc"
	SortOrderDESC SortOrder = "desc"
)

func (so SortOrder) String() string {
	return string(so)
}

func (so SortOrder) IsValid() bool {
	return so == SortOrderASC || so == SortOrderDESC
}

type SortField string

const (
	SortFieldWinRate      SortField = "win_rate"
	SortFieldPickRate     SortField = "pick_rate"
	SortFieldAvgPlacement SortField = "avg_placement"
	SortFieldTop4Rate     SortField = "top4_rate"
	SortFieldTotalGames   SortField = "total_games"
	SortFieldLastUpdated  SortField = "last_updated"
)

func (sf SortField) String() string {
	return string(sf)
}

func (sf SortField) IsValid() bool {
	validFields := map[SortField]bool{
		SortFieldWinRate: true, SortFieldPickRate: true,
		SortFieldAvgPlacement: true, SortFieldTop4Rate: true,
		SortFieldTotalGames: true, SortFieldLastUpdated: true,
	}
	return validFields[sf]
}

func (sf SortField) GetSQLColumn() string {
	columns := map[SortField]string{
		SortFieldWinRate:      "win_rate",
		SortFieldPickRate:     "pick_rate",
		SortFieldAvgPlacement: "avg_placement",
		SortFieldTop4Rate:     "top4_rate",
		SortFieldTotalGames:   "total_games",
		SortFieldLastUpdated:  "last_updated",
	}
	return columns[sf]
}

type Environment string

const (
	EnvironmentDevelopment Environment = "development"
	EnvironmentStaging     Environment = "staging"
	EnvironmentProduction  Environment = "production"
)

func (e Environment) String() string {
	return string(e)
}

func (e Environment) IsProduction() bool {
	return e == EnvironmentProduction
}

func (e Environment) IsDevelopment() bool {
	return e == EnvironmentDevelopment
}

type APIResponse struct {
	Success   bool        `json:"success"`
	Data      interface{} `json:"data,omitempty"`
	Error     *APIError   `json:"error,omitempty"`
	Timestamp time.Time   `json:"timestamp"`
	RequestID string      `json:"request_id,omitempty"`
}

type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

func NewSuccessResponse(data interface{}) *APIResponse {
	return &APIResponse{
		Success:   true,
		Data:      data,
		Timestamp: time.Now(),
	}
}

func NewErrorResponse(code, message string) *APIResponse {
	return &APIResponse{
		Success: false,
		Error: &APIError{
			Code:    code,
			Message: message,
		},
		Timestamp: time.Now(),
	}
}

func NewErrorResponseWithDetails(code, message, details string) *APIResponse {
	return &APIResponse{
		Success: false,
		Error: &APIError{
			Code:    code,
			Message: message,
			Details: details,
		},
		Timestamp: time.Now(),
	}
}

type PaginationMeta struct {
	Page       int  `json:"page"`
	Limit      int  `json:"limit"`
	Total      int  `json:"total"`
	TotalPages int  `json:"total_pages"`
	HasNext    bool `json:"has_next"`
	HasPrev    bool `json:"has_prev"`
}

func NewPaginationMeta(page, limit, total int) *PaginationMeta {
	totalPages := (total + limit - 1) / limit
	
	return &PaginationMeta{
		Page:       page,
		Limit:      limit,
		Total:      total,
		TotalPages: totalPages,
		HasNext:    page < totalPages,
		HasPrev:    page > 1,
	}
}

type PaginatedResponse struct {
	*APIResponse
	Meta *PaginationMeta `json:"meta"`
}

func NewPaginatedResponse(data interface{}, meta *PaginationMeta) *PaginatedResponse {
	return &PaginatedResponse{
		APIResponse: NewSuccessResponse(data),
		Meta:        meta,
	}
}

type CacheKey struct {
	Prefix string
	Parts  []string
	TTL    time.Duration
}

func NewCacheKey(prefix string, parts ...string) *CacheKey {
	return &CacheKey{
		Prefix: prefix,
		Parts:  parts,
	}
}

func (ck *CacheKey) String() string {
	if len(ck.Parts) == 0 {
		return ck.Prefix
	}
	return fmt.Sprintf("%s:%s", ck.Prefix, strings.Join(ck.Parts, ":"))
}

func (ck *CacheKey) WithTTL(ttl time.Duration) *CacheKey {
	ck.TTL = ttl
	return ck
}

const (
	CacheKeyComposition       = "comp"
	CacheKeyLeaderboard      = "leaderboard"
	CacheKeyPlayer           = "player"
	CacheKeyMeta             = "meta"
	CacheKeyFilterOptions    = "filters"
	CacheKeyCompositionDetail = "comp_detail"
)

type JobType string

const (
	JobTypeCollectChallenger    JobType = "collect_challenger"
	JobTypeCollectPlayer        JobType = "collect_player"
	JobTypeAnalyzeCompositions  JobType = "analyze_compositions"
	JobTypeRefreshLeaderboard   JobType = "refresh_leaderboard"
	JobTypeCleanupCache         JobType = "cleanup_cache"
	JobTypeUpdateMetaData       JobType = "update_meta_data"
)

func (jt JobType) String() string {
	return string(jt)
}

func (jt JobType) IsValid() bool {
	validJobs := map[JobType]bool{
		JobTypeCollectChallenger: true, JobTypeCollectPlayer: true,
		JobTypeAnalyzeCompositions: true, JobTypeRefreshLeaderboard: true,
		JobTypeCleanupCache: true, JobTypeUpdateMetaData: true,
	}
	return validJobs[jt]
}

type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
	Tag     string `json:"tag"`
	Value   string `json:"value,omitempty"`
}

func NewValidationError(field, message, tag string) *ValidationError {
	return &ValidationError{
		Field:   field,
		Message: message,
		Tag:     tag,
	}
}

func (ve *ValidationError) Error() string {
	return fmt.Sprintf("validation failed for field '%s': %s", ve.Field, ve.Message)
}

type ValidationErrors []*ValidationError

func (ve ValidationErrors) Error() string {
	if len(ve) == 0 {
		return "validation errors"
	}
	
	messages := make([]string, len(ve))
	for i, err := range ve {
		messages[i] = err.Error()
	}
	
	return strings.Join(messages, "; ")
}

func AllRegions() []Region {
	return []Region{
		RegionBR1, RegionEUN1, RegionEUW1, RegionJP1, RegionKR,
		RegionLA1, RegionLA2, RegionNA1, RegionOC1, RegionRU,
		RegionSG2, RegionTR1, RegionTW2, RegionVN2,
	}
}

func AllTiers() []Tier {
	return []Tier{
		TierIRON, TierBRONZE, TierSILVER, TierGOLD, TierPLATINUM,
		TierEMERALD, TierDIAMOND, TierMASTER, TierGRANDMASTER, TierCHALLENGER,
	}
}

func AllTierRanks() []TierRank {
	return []TierRank{TierRankS, TierRankA, TierRankB, TierRankC, TierRankD}
}

func ParseRegion(s string) (Region, error) {
	region := Region(strings.ToLower(s))
	if !region.IsValid() {
		return "", fmt.Errorf("invalid region: %s", s)
	}
	return region, nil
}

func ParseTier(s string) (Tier, error) {
	tier := Tier(strings.ToUpper(s))
	if !tier.IsValid() {
		return "", fmt.Errorf("invalid tier: %s", s)
	}
	return tier, nil
}