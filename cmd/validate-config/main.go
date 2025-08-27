package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/rsdlab-dk/tft-api/internal/config"
)

func main() {
	var (
		configPath = flag.String("config", ".env.development", "Path to configuration file")
		verbose    = flag.Bool("verbose", false, "Verbose output")
	)
	flag.Parse()

	cfg, err := config.Load(*configPath)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	if err := cfg.Validate(); err != nil {
		log.Fatalf("Configuration validation failed: %v", err)
	}

	if *verbose {
		printConfigSummary(cfg)
	}

	fmt.Printf("✅ Configuration file '%s' is valid!\n", *configPath)
}

func printConfigSummary(cfg *config.Config) {
	fmt.Println("\n📋 Configuration Summary:")
	fmt.Println("========================")
	
	fmt.Printf("🏠 Environment: %s\n", cfg.Server.Environment)
	fmt.Printf("🌐 Server: %s\n", cfg.ServerAddr())
	fmt.Printf("🗄️  Database: %s:%d/%s\n", cfg.Database.Host, cfg.Database.Port, cfg.Database.Name)
	fmt.Printf("⚡ Redis: %s\n", cfg.RedisAddr())
	fmt.Printf("📨 NATS: %v\n", cfg.NATS.URLs)
	fmt.Printf("🎮 Riot API: %s (Region: %s)\n", 
		maskAPIKey(cfg.Riot.APIKey), cfg.Riot.DefaultRegion)
	
	if cfg.Metrics.Enabled {
		fmt.Printf("📊 Metrics: %s\n", cfg.MetricsAddr())
	} else {
		fmt.Printf("📊 Metrics: disabled\n")
	}
	
	fmt.Printf("💾 Cache TTL - Default: %v, Player: %v, Meta: %v\n",
		cfg.Cache.DefaultTTL, cfg.Cache.PlayerTTL, cfg.Cache.MetaTTL)
	
	fmt.Printf("⚙️  Jobs: %d workers, %v collection interval\n",
		cfg.Jobs.WorkerCount, cfg.Jobs.CollectionInterval)
}

func maskAPIKey(key string) string {
	if len(key) == 0 {
		return "NOT_SET"
	}
	if len(key) < 10 {
		return "***"
	}
	return key[:4] + "..." + key[len(key)-4:]
}