package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/joho/godotenv"
)

type Config struct {
	Server   ServerConfig   `validate:"required"`
	Database DatabaseConfig `validate:"required"`
	Redis    RedisConfig    `validate:"required"`
	NATS     NATSConfig     `validate:"required"`
	Riot     RiotConfig     `validate:"required"`
	Cache    CacheConfig    `validate:"required"`
	Jobs     JobsConfig     `validate:"required"`
	Auth     AuthConfig     `validate:"required"`
	Metrics  MetricsConfig  `validate:"required"`
}

type ServerConfig struct {
	Host            string        `validate:"required" env:"SERVER_HOST"`
	Port            string        `validate:"required" env:"SERVER_PORT"`
	Environment     string        `validate:"required,oneof=development staging production" env:"ENVIRONMENT"`
	ReadTimeout     time.Duration `validate:"required" env:"SERVER_READ_TIMEOUT"`
	WriteTimeout    time.Duration `validate:"required" env:"SERVER_WRITE_TIMEOUT"`
	IdleTimeout     time.Duration `validate:"required" env:"SERVER_IDLE_TIMEOUT"`
	ShutdownTimeout time.Duration `validate:"required" env:"SERVER_SHUTDOWN_TIMEOUT"`
	MaxHeaderBytes  int           `validate:"required,min=1" env:"SERVER_MAX_HEADER_BYTES"`
	TrustedProxies  []string      `env:"SERVER_TRUSTED_PROXIES"`
}

type DatabaseConfig struct {
	Host         string        `validate:"required" env:"DB_HOST"`
	Port         int           `validate:"required,min=1,max=65535" env:"DB_PORT"`
	Name         string        `validate:"required" env:"DB_NAME"`
	User         string        `validate:"required" env:"DB_USER"`
	Password     string        `validate:"required" env:"DB_PASSWORD"`
	SSLMode      string        `validate:"required,oneof=disable require verify-ca verify-full" env:"DB_SSL_MODE"`
	MaxOpenConns int           `validate:"required,min=1" env:"DB_MAX_OPEN_CONNS"`
	MaxIdleConns int           `validate:"required,min=1" env:"DB_MAX_IDLE_CONNS"`
	MaxIdleTime  time.Duration `validate:"required" env:"DB_MAX_IDLE_TIME"`
	MaxLifetime  time.Duration `validate:"required" env:"DB_MAX_LIFETIME"`
}

type RedisConfig struct {
	Host         string        `validate:"required" env:"REDIS_HOST"`
	Port         int           `validate:"required,min=1,max=65535" env:"REDIS_PORT"`
	Password     string        `env:"REDIS_PASSWORD"`
	Database     int           `validate:"min=0,max=15" env:"REDIS_DATABASE"`
	PoolSize     int           `validate:"required,min=1" env:"REDIS_POOL_SIZE"`
	MinIdleConns int           `validate:"required,min=1" env:"REDIS_MIN_IDLE_CONNS"`
	DialTimeout  time.Duration `validate:"required" env:"REDIS_DIAL_TIMEOUT"`
	ReadTimeout  time.Duration `validate:"required" env:"REDIS_READ_TIMEOUT"`
	WriteTimeout time.Duration `validate:"required" env:"REDIS_WRITE_TIMEOUT"`
	PoolTimeout  time.Duration `validate:"required" env:"REDIS_POOL_TIMEOUT"`
}

type NATSConfig struct {
	URLs          []string      `validate:"required,min=1" env:"NATS_URLS"`
	MaxReconnects int           `validate:"min=-1" env:"NATS_MAX_RECONNECTS"`
	ReconnectWait time.Duration `validate:"required" env:"NATS_RECONNECT_WAIT"`
	Timeout       time.Duration `validate:"required" env:"NATS_TIMEOUT"`
	DrainTimeout  time.Duration `validate:"required" env:"NATS_DRAIN_TIMEOUT"`
	PingInterval  time.Duration `validate:"required" env:"NATS_PING_INTERVAL"`
	MaxPingsOut   int           `validate:"required,min=1" env:"NATS_MAX_PINGS_OUT"`
}

type RiotConfig struct {
	APIKey            string        `validate:"required" env:"RIOT_API_KEY"`
	RateLimit         int           `validate:"required,min=1" env:"RIOT_RATE_LIMIT"`
	RateLimitWindow   time.Duration `validate:"required" env:"RIOT_RATE_LIMIT_WINDOW"`
	DefaultRegion     string        `validate:"required" env:"RIOT_DEFAULT_REGION"`
	RequestTimeout    time.Duration `validate:"required" env:"RIOT_REQUEST_TIMEOUT"`
	MaxRetries        int           `validate:"min=0" env:"RIOT_MAX_RETRIES"`
	RetryBackoff      time.Duration `validate:"required" env:"RIOT_RETRY_BACKOFF"`
	UserAgent         string        `validate:"required" env:"RIOT_USER_AGENT"`
}

type CacheConfig struct {
	DefaultTTL              time.Duration `validate:"required" env:"CACHE_DEFAULT_TTL"`
	LeaderboardTTL          time.Duration `validate:"required" env:"CACHE_LEADERBOARD_TTL"`
	PlayerTTL               time.Duration `validate:"required" env:"CACHE_PLAYER_TTL"`
	CompositionTTL          time.Duration `validate:"required" env:"CACHE_COMPOSITION_TTL"`
	MetaTTL                 time.Duration `validate:"required" env:"CACHE_META_TTL"`
	MatchTTL                time.Duration `validate:"required" env:"CACHE_MATCH_TTL"`
	CleanupInterval         time.Duration `validate:"required" env:"CACHE_CLEANUP_INTERVAL"`
	CompressionEnabled      bool          `env:"CACHE_COMPRESSION_ENABLED"`
	CompressionThreshold    int           `validate:"min=0" env:"CACHE_COMPRESSION_THRESHOLD"`
}

type JobsConfig struct {
	WorkerCount                    int           `validate:"required,min=1" env:"JOBS_WORKER_COUNT"`
	QueueBuffer                    int           `validate:"required,min=1" env:"JOBS_QUEUE_BUFFER"`
	ProcessingTimeout              time.Duration `validate:"required" env:"JOBS_PROCESSING_TIMEOUT"`
	CollectionInterval             time.Duration `validate:"required" env:"JOBS_COLLECTION_INTERVAL"`
	AnalysisInterval               time.Duration `validate:"required" env:"JOBS_ANALYSIS_INTERVAL"`
	LeaderboardRefreshInterval     time.Duration `validate:"required" env:"JOBS_LEADERBOARD_REFRESH_INTERVAL"`
	MetaUpdateInterval             time.Duration `validate:"required" env:"JOBS_META_UPDATE_INTERVAL"`
	CleanupInterval                time.Duration `validate:"required" env:"JOBS_CLEANUP_INTERVAL"`
	MaxRetries                     int           `validate:"min=0" env:"JOBS_MAX_RETRIES"`
	RetryBackoff                   time.Duration `validate:"required" env:"JOBS_RETRY_BACKOFF"`
}

type AuthConfig struct {
	JWTSecret          string        `validate:"required" env:"JWT_SECRET"`
	JWTExpiration      time.Duration `validate:"required" env:"JWT_EXPIRATION"`
	RefreshExpiration  time.Duration `validate:"required" env:"REFRESH_EXPIRATION"`
	BcryptCost         int           `validate:"min=10,max=15" env:"BCRYPT_COST"`
	SessionTimeout     time.Duration `validate:"required" env:"SESSION_TIMEOUT"`
	MaxLoginAttempts   int           `validate:"min=3" env:"MAX_LOGIN_ATTEMPTS"`
	LockoutDuration    time.Duration `validate:"required" env:"LOCKOUT_DURATION"`
}

type MetricsConfig struct {
	Enabled         bool          `env:"METRICS_ENABLED"`
	Host            string        `validate:"required_if=Enabled true" env:"METRICS_HOST"`
	Port            string        `validate:"required_if=Enabled true" env:"METRICS_PORT"`
	Path            string        `validate:"required_if=Enabled true" env:"METRICS_PATH"`
	CollectInterval time.Duration `validate:"required_if=Enabled true" env:"METRICS_COLLECT_INTERVAL"`
	Namespace       string        `validate:"required_if=Enabled true" env:"METRICS_NAMESPACE"`
}

func Load(envFiles ...string) (*Config, error) {
	for _, envFile := range envFiles {
		if envFile != "" {
			if err := godotenv.Load(envFile); err != nil {
				return nil, fmt.Errorf("failed to load env file %s: %w", envFile, err)
			}
		}
	}

	config := &Config{
		Server: ServerConfig{
			Host:            getEnvString("SERVER_HOST", "0.0.0.0"),
			Port:            getEnvString("SERVER_PORT", "8080"),
			Environment:     getEnvString("ENVIRONMENT", "development"),
			ReadTimeout:     getEnvDuration("SERVER_READ_TIMEOUT", 30*time.Second),
			WriteTimeout:    getEnvDuration("SERVER_WRITE_TIMEOUT", 30*time.Second),
			IdleTimeout:     getEnvDuration("SERVER_IDLE_TIMEOUT", 120*time.Second),
			ShutdownTimeout: getEnvDuration("SERVER_SHUTDOWN_TIMEOUT", 30*time.Second),
			MaxHeaderBytes:  getEnvInt("SERVER_MAX_HEADER_BYTES", 1048576),
			TrustedProxies:  getEnvStringSlice("SERVER_TRUSTED_PROXIES"),
		},
		Database: DatabaseConfig{
			Host:         getEnvString("DB_HOST", "localhost"),
			Port:         getEnvInt("DB_PORT", 5432),
			Name:         getEnvString("DB_NAME", "tft_arena"),
			User:         getEnvString("DB_USER", "tft_user"),
			Password:     getEnvString("DB_PASSWORD", ""),
			SSLMode:      getEnvString("DB_SSL_MODE", "disable"),
			MaxOpenConns: getEnvInt("DB_MAX_OPEN_CONNS", 25),
			MaxIdleConns: getEnvInt("DB_MAX_IDLE_CONNS", 5),
			MaxIdleTime:  getEnvDuration("DB_MAX_IDLE_TIME", 15*time.Minute),
			MaxLifetime:  getEnvDuration("DB_MAX_LIFETIME", time.Hour),
		},
		Redis: RedisConfig{
			Host:         getEnvString("REDIS_HOST", "localhost"),
			Port:         getEnvInt("REDIS_PORT", 6379),
			Password:     getEnvString("REDIS_PASSWORD", ""),
			Database:     getEnvInt("REDIS_DATABASE", 0),
			PoolSize:     getEnvInt("REDIS_POOL_SIZE", 10),
			MinIdleConns: getEnvInt("REDIS_MIN_IDLE_CONNS", 2),
			DialTimeout:  getEnvDuration("REDIS_DIAL_TIMEOUT", 5*time.Second),
			ReadTimeout:  getEnvDuration("REDIS_READ_TIMEOUT", 3*time.Second),
			WriteTimeout: getEnvDuration("REDIS_WRITE_TIMEOUT", 3*time.Second),
			PoolTimeout:  getEnvDuration("REDIS_POOL_TIMEOUT", 4*time.Second),
		},
		NATS: NATSConfig{
			URLs:          getEnvStringSlice("NATS_URLS", "nats://localhost:4222"),
			MaxReconnects: getEnvInt("NATS_MAX_RECONNECTS", -1),
			ReconnectWait: getEnvDuration("NATS_RECONNECT_WAIT", 2*time.Second),
			Timeout:       getEnvDuration("NATS_TIMEOUT", 30*time.Second),
			DrainTimeout:  getEnvDuration("NATS_DRAIN_TIMEOUT", 30*time.Second),
			PingInterval:  getEnvDuration("NATS_PING_INTERVAL", 2*time.Minute),
			MaxPingsOut:   getEnvInt("NATS_MAX_PINGS_OUT", 2),
		},
		Riot: RiotConfig{
			APIKey:          getEnvString("RIOT_API_KEY", ""),
			RateLimit:       getEnvInt("RIOT_RATE_LIMIT", 100),
			RateLimitWindow: getEnvDuration("RIOT_RATE_LIMIT_WINDOW", 2*time.Minute),
			DefaultRegion:   getEnvString("RIOT_DEFAULT_REGION", "kr"),
			RequestTimeout:  getEnvDuration("RIOT_REQUEST_TIMEOUT", 30*time.Second),
			MaxRetries:      getEnvInt("RIOT_MAX_RETRIES", 3),
			RetryBackoff:    getEnvDuration("RIOT_RETRY_BACKOFF", time.Second),
			UserAgent:       getEnvString("RIOT_USER_AGENT", "TFT-Arena/1.0"),
		},
		Cache: CacheConfig{
			DefaultTTL:           getEnvDuration("CACHE_DEFAULT_TTL", 5*time.Minute),
			LeaderboardTTL:       getEnvDuration("CACHE_LEADERBOARD_TTL", 30*time.Minute),
			PlayerTTL:            getEnvDuration("CACHE_PLAYER_TTL", 15*time.Minute),
			CompositionTTL:       getEnvDuration("CACHE_COMPOSITION_TTL", time.Hour),
			MetaTTL:              getEnvDuration("CACHE_META_TTL", 2*time.Hour),
			MatchTTL:             getEnvDuration("CACHE_MATCH_TTL", 24*time.Hour),
			CleanupInterval:      getEnvDuration("CACHE_CLEANUP_INTERVAL", 10*time.Minute),
			CompressionEnabled:   getEnvBool("CACHE_COMPRESSION_ENABLED", true),
			CompressionThreshold: getEnvInt("CACHE_COMPRESSION_THRESHOLD", 1024),
		},
		Jobs: JobsConfig{
			WorkerCount:                getEnvInt("JOBS_WORKER_COUNT", 5),
			QueueBuffer:                getEnvInt("JOBS_QUEUE_BUFFER", 1000),
			ProcessingTimeout:          getEnvDuration("JOBS_PROCESSING_TIMEOUT", 10*time.Minute),
			CollectionInterval:         getEnvDuration("JOBS_COLLECTION_INTERVAL", 5*time.Minute),
			AnalysisInterval:           getEnvDuration("JOBS_ANALYSIS_INTERVAL", 30*time.Minute),
			LeaderboardRefreshInterval: getEnvDuration("JOBS_LEADERBOARD_REFRESH_INTERVAL", 15*time.Minute),
			MetaUpdateInterval:         getEnvDuration("JOBS_META_UPDATE_INTERVAL", time.Hour),
			CleanupInterval:            getEnvDuration("JOBS_CLEANUP_INTERVAL", 24*time.Hour),
			MaxRetries:                 getEnvInt("JOBS_MAX_RETRIES", 3),
			RetryBackoff:               getEnvDuration("JOBS_RETRY_BACKOFF", 30*time.Second),
		},
		Auth: AuthConfig{
			JWTSecret:         getEnvString("JWT_SECRET", ""),
			JWTExpiration:     getEnvDuration("JWT_EXPIRATION", 24*time.Hour),
			RefreshExpiration: getEnvDuration("REFRESH_EXPIRATION", 7*24*time.Hour),
			BcryptCost:        getEnvInt("BCRYPT_COST", 12),
			SessionTimeout:    getEnvDuration("SESSION_TIMEOUT", 30*time.Minute),
			MaxLoginAttempts:  getEnvInt("MAX_LOGIN_ATTEMPTS", 5),
			LockoutDuration:   getEnvDuration("LOCKOUT_DURATION", 15*time.Minute),
		},
		Metrics: MetricsConfig{
			Enabled:         getEnvBool("METRICS_ENABLED", false),
			Host:            getEnvString("METRICS_HOST", "0.0.0.0"),
			Port:            getEnvString("METRICS_PORT", "9090"),
			Path:            getEnvString("METRICS_PATH", "/metrics"),
			CollectInterval: getEnvDuration("METRICS_COLLECT_INTERVAL", 30*time.Second),
			Namespace:       getEnvString("METRICS_NAMESPACE", "tft_arena"),
		},
	}

	if err := validate(config); err != nil {
		return nil, fmt.Errorf("configuration validation failed: %w", err)
	}

	return config, nil
}

func (c *Config) IsDevelopment() bool {
	return c.Server.Environment == "development"
}

func (c *Config) IsProduction() bool {
	return c.Server.Environment == "production"
}

func (c *Config) DatabaseURL() string {
	return fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s",
		c.Database.User,
		c.Database.Password,
		c.Database.Host,
		c.Database.Port,
		c.Database.Name,
		c.Database.SSLMode,
	)
}

func (c *Config) RedisAddr() string {
	return fmt.Sprintf("%s:%d", c.Redis.Host, c.Redis.Port)
}

func (c *Config) ServerAddr() string {
	return fmt.Sprintf("%s:%s", c.Server.Host, c.Server.Port)
}

func (c *Config) MetricsAddr() string {
	return fmt.Sprintf("%s:%s", c.Metrics.Host, c.Metrics.Port)
}

func (c *Config) Validate() error {
	return validate(c)
}

func validate(config *Config) error {
	validator := validator.New()
	
	validator.RegisterValidation("required_if", func(fl validator.FieldLevel) bool {
		param := fl.Param()
		parts := strings.Split(param, " ")
		if len(parts) != 2 {
			return false
		}
		
		field := parts[0]
		value := parts[1]
		
		parent := fl.Parent()
		fieldValue := parent.FieldByName(field)
		if !fieldValue.IsValid() {
			return true
		}
		
		if fieldValue.String() == value {
			return fl.Field().String() != ""
		}
		
		return true
	})
	
	return validator.Struct(config)
}

func getEnvString(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return fallback
}

func getEnvBool(key string, fallback bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return fallback
}

func getEnvDuration(key string, fallback time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return fallback
}

func getEnvStringSlice(key string, fallback ...string) []string {
	if value := os.Getenv(key); value != "" {
		return strings.Split(value, ",")
	}
	return fallback
}