package config

import (
	"fmt"
	"os"
	"strconv"
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
}

type ServerConfig struct {
	Port            string        `validate:"required" env:"SERVER_PORT"`
	Host            string        `validate:"required" env:"SERVER_HOST"`
	Environment     string        `validate:"required,oneof=development staging production" env:"ENVIRONMENT"`
	ReadTimeout     time.Duration `validate:"required" env:"SERVER_READ_TIMEOUT"`
	WriteTimeout    time.Duration `validate:"required" env:"SERVER_WRITE_TIMEOUT"`
	ShutdownTimeout time.Duration `validate:"required" env:"SERVER_SHUTDOWN_TIMEOUT"`
	CORSAllowOrigin string        `validate:"required" env:"CORS_ALLOW_ORIGIN"`
}

type DatabaseConfig struct {
	Host         string `validate:"required" env:"DB_HOST"`
	Port         int    `validate:"required,min=1,max=65535" env:"DB_PORT"`
	Name         string `validate:"required" env:"DB_NAME"`
	User         string `validate:"required" env:"DB_USER"`
	Password     string `validate:"required" env:"DB_PASSWORD"`
	SSLMode      string `validate:"required,oneof=disable require verify-ca verify-full" env:"DB_SSL_MODE"`
	MaxOpenConns int    `validate:"required,min=1" env:"DB_MAX_OPEN_CONNS"`
	MaxIdleConns int    `validate:"required,min=1" env:"DB_MAX_IDLE_CONNS"`
	MaxIdleTime  time.Duration `validate:"required" env:"DB_MAX_IDLE_TIME"`
}

type RedisConfig struct {
	Host         string        `validate:"required" env:"REDIS_HOST"`
	Port         int           `validate:"required,min=1,max=65535" env:"REDIS_PORT"`
	Password     string        `env:"REDIS_PASSWORD"`
	DB           int           `validate:"min=0,max=15" env:"REDIS_DB"`
	PoolSize     int           `validate:"required,min=1" env:"REDIS_POOL_SIZE"`
	DialTimeout  time.Duration `validate:"required" env:"REDIS_DIAL_TIMEOUT"`
	ReadTimeout  time.Duration `validate:"required" env:"REDIS_READ_TIMEOUT"`
	WriteTimeout time.Duration `validate:"required" env:"REDIS_WRITE_TIMEOUT"`
}

type NATSConfig struct {
	URLs           []string      `validate:"required,min=1" env:"NATS_URLS"`
	MaxReconnects  int           `validate:"min=-1" env:"NATS_MAX_RECONNECTS"`
	ReconnectWait  time.Duration `validate:"required" env:"NATS_RECONNECT_WAIT"`
	Timeout        time.Duration `validate:"required" env:"NATS_TIMEOUT"`
	DrainTimeout   time.Duration `validate:"required" env:"NATS_DRAIN_TIMEOUT"`
}

type RiotConfig struct {
	APIKey         string        `validate:"required" env:"RIOT_API_KEY"`
	RateLimit      int           `validate:"required,min=1" env:"RIOT_RATE_LIMIT"`
	RateLimitWindow time.Duration `validate:"required" env:"RIOT_RATE_LIMIT_WINDOW"`
	DefaultRegion  string        `validate:"required" env:"RIOT_DEFAULT_REGION"`
	RequestTimeout time.Duration `validate:"required" env:"RIOT_REQUEST_TIMEOUT"`
}

type CacheConfig struct {
	DefaultTTL        time.Duration `validate:"required" env:"CACHE_DEFAULT_TTL"`
	LeaderboardTTL    time.Duration `validate:"required" env:"CACHE_LEADERBOARD_TTL"`
	PlayerTTL         time.Duration `validate:"required" env:"CACHE_PLAYER_TTL"`
	CompositionTTL    time.Duration `validate:"required" env:"CACHE_COMPOSITION_TTL"`
	MetaTTL           time.Duration `validate:"required" env:"CACHE_META_TTL"`
	CleanupInterval   time.Duration `validate:"required" env:"CACHE_CLEANUP_INTERVAL"`
}

type JobsConfig struct {
	WorkerCount            int           `validate:"required,min=1" env:"JOBS_WORKER_COUNT"`
	QueueBuffer            int           `validate:"required,min=1" env:"JOBS_QUEUE_BUFFER"`
	ProcessingTimeout      time.Duration `validate:"required" env:"JOBS_PROCESSING_TIMEOUT"`
	CollectionInterval     time.Duration `validate:"required" env:"JOBS_COLLECTION_INTERVAL"`
	AnalysisInterval       time.Duration `validate:"required" env:"JOBS_ANALYSIS_INTERVAL"`
	LeaderboardRefreshInterval time.Duration `validate:"required" env:"JOBS_LEADERBOARD_REFRESH_INTERVAL"`
}

func Load(envFile string) (*Config, error) {
	if envFile != "" {
		if err := godotenv.Load(envFile); err != nil {
			return nil, fmt.Errorf("failed to load env file %s: %w", envFile, err)
		}
	}

	config := &Config{
		Server: ServerConfig{
			Port:            getEnvString("SERVER_PORT"),
			Host:            getEnvString("SERVER_HOST"),
			Environment:     getEnvString("ENVIRONMENT"),
			ReadTimeout:     getEnvDuration("SERVER_READ_TIMEOUT"),
			WriteTimeout:    getEnvDuration("SERVER_WRITE_TIMEOUT"),
			ShutdownTimeout: getEnvDuration("SERVER_SHUTDOWN_TIMEOUT"),
			CORSAllowOrigin: getEnvString("CORS_ALLOW_ORIGIN"),
		},
		Database: DatabaseConfig{
			Host:         getEnvString("DB_HOST"),
			Port:         getEnvInt("DB_PORT"),
			Name:         getEnvString("DB_NAME"),
			User:         getEnvString("DB_USER"),
			Password:     getEnvString("DB_PASSWORD"),
			SSLMode:      getEnvString("DB_SSL_MODE"),
			MaxOpenConns: getEnvInt("DB_MAX_OPEN_CONNS"),
			MaxIdleConns: getEnvInt("DB_MAX_IDLE_CONNS"),
			MaxIdleTime:  getEnvDuration("DB_MAX_IDLE_TIME"),
		},
		Redis: RedisConfig{
			Host:         getEnvString("REDIS_HOST"),
			Port:         getEnvInt("REDIS_PORT"),
			Password:     getEnvString("REDIS_PASSWORD"),
			DB:           getEnvInt("REDIS_DB"),
			PoolSize:     getEnvInt("REDIS_POOL_SIZE"),
			DialTimeout:  getEnvDuration("REDIS_DIAL_TIMEOUT"),
			ReadTimeout:  getEnvDuration("REDIS_READ_TIMEOUT"),
			WriteTimeout: getEnvDuration("REDIS_WRITE_TIMEOUT"),
		},
		NATS: NATSConfig{
			URLs:          getEnvStringSlice("NATS_URLS"),
			MaxReconnects: getEnvInt("NATS_MAX_RECONNECTS"),
			ReconnectWait: getEnvDuration("NATS_RECONNECT_WAIT"),
			Timeout:       getEnvDuration("NATS_TIMEOUT"),
			DrainTimeout:  getEnvDuration("NATS_DRAIN_TIMEOUT"),
		},
		Riot: RiotConfig{
			APIKey:          getEnvString("RIOT_API_KEY"),
			RateLimit:       getEnvInt("RIOT_RATE_LIMIT"),
			RateLimitWindow: getEnvDuration("RIOT_RATE_LIMIT_WINDOW"),
			DefaultRegion:   getEnvString("RIOT_DEFAULT_REGION"),
			RequestTimeout:  getEnvDuration("RIOT_REQUEST_TIMEOUT"),
		},
		Cache: CacheConfig{
			DefaultTTL:                 getEnvDuration("CACHE_DEFAULT_TTL"),
			LeaderboardTTL:             getEnvDuration("CACHE_LEADERBOARD_TTL"),
			PlayerTTL:                  getEnvDuration("CACHE_PLAYER_TTL"),
			CompositionTTL:             getEnvDuration("CACHE_COMPOSITION_TTL"),
			MetaTTL:                    getEnvDuration("CACHE_META_TTL"),
			CleanupInterval:            getEnvDuration("CACHE_CLEANUP_INTERVAL"),
		},
		Jobs: JobsConfig{
			WorkerCount:                    getEnvInt("JOBS_WORKER_COUNT"),
			QueueBuffer:                    getEnvInt("JOBS_QUEUE_BUFFER"),
			ProcessingTimeout:              getEnvDuration("JOBS_PROCESSING_TIMEOUT"),
			CollectionInterval:             getEnvDuration("JOBS_COLLECTION_INTERVAL"),
			AnalysisInterval:               getEnvDuration("JOBS_ANALYSIS_INTERVAL"),
			LeaderboardRefreshInterval:     getEnvDuration("JOBS_LEADERBOARD_REFRESH_INTERVAL"),
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

func validate(config *Config) error {
	validator := validator.New()
	return validator.Struct(config)
}

func getEnvString(key string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return ""
}

func getEnvInt(key string) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return 0
}

func getEnvDuration(key string) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return 0
}

func getEnvStringSlice(key string) []string {
	if value := os.Getenv(key); value != "" {
		return []string{value}
	}
	return nil
}