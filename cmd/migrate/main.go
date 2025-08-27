package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
	"github.com/rsdlab-dk/tft-api/internal/config"
)

func main() {
	var (
		configPath = flag.String("config", ".env.development", "Path to configuration file")
		direction  = flag.String("direction", "up", "Migration direction: up or down")
		steps      = flag.Int("steps", 0, "Number of migration steps (0 = all)")
		version    = flag.Int("version", -1, "Migration version to migrate to")
		force      = flag.Int("force", -1, "Force migration version (use with caution)")
		drop       = flag.Bool("drop", false, "Drop all tables and migrate fresh")
	)
	flag.Parse()

	cfg, err := config.Load(*configPath)
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	db, err := sql.Open("postgres", cfg.DatabaseURL())
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		log.Fatalf("Failed to create postgres driver: %v", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"file://migrations",
		"postgres",
		driver,
	)
	if err != nil {
		log.Fatalf("Failed to create migrate instance: %v", err)
	}
	defer m.Close()

	currentVersion, dirty, err := m.Version()
	if err != nil && err != migrate.ErrNilVersion {
		log.Fatalf("Failed to get current version: %v", err)
	}

	fmt.Printf("Current database version: %d (dirty: %v)\n", currentVersion, dirty)

	if dirty {
		fmt.Println("Database is in dirty state. Consider using -force flag to set version.")
		if *force == -1 {
			os.Exit(1)
		}
	}

	if *force != -1 {
		fmt.Printf("Forcing database version to %d\n", *force)
		if err := m.Force(*force); err != nil {
			log.Fatalf("Failed to force version: %v", err)
		}
		fmt.Println("Database version forced successfully")
		return
	}

	if *drop {
		fmt.Println("Dropping all tables...")
		if err := m.Drop(); err != nil {
			log.Fatalf("Failed to drop tables: %v", err)
		}
		fmt.Println("All tables dropped successfully")
		return
	}

	switch *direction {
	case "up":
		if *version != -1 {
			fmt.Printf("Migrating up to version %d\n", *version)
			if err := m.Migrate(uint(*version)); err != nil && err != migrate.ErrNoChange {
				log.Fatalf("Failed to migrate to version %d: %v", *version, err)
			}
		} else if *steps > 0 {
			fmt.Printf("Migrating up %d steps\n", *steps)
			if err := m.Steps(*steps); err != nil && err != migrate.ErrNoChange {
				log.Fatalf("Failed to migrate up %d steps: %v", *steps, err)
			}
		} else {
			fmt.Println("Migrating up to latest version")
			if err := m.Up(); err != nil && err != migrate.ErrNoChange {
				log.Fatalf("Failed to migrate up: %v", err)
			}
		}

	case "down":
		if *version != -1 {
			fmt.Printf("Migrating down to version %d\n", *version)
			if err := m.Migrate(uint(*version)); err != nil && err != migrate.ErrNoChange {
				log.Fatalf("Failed to migrate to version %d: %v", *version, err)
			}
		} else if *steps > 0 {
			fmt.Printf("Migrating down %d steps\n", *steps)
			if err := m.Steps(-*steps); err != nil && err != migrate.ErrNoChange {
				log.Fatalf("Failed to migrate down %d steps: %v", *steps, err)
			}
		} else {
			fmt.Println("Migrating down to version 0")
			if err := m.Down(); err != nil && err != migrate.ErrNoChange {
				log.Fatalf("Failed to migrate down: %v", err)
			}
		}

	default:
		log.Fatalf("Invalid direction: %s. Use 'up' or 'down'", *direction)
	}

	newVersion, dirty, err := m.Version()
	if err != nil && err != migrate.ErrNilVersion {
		log.Fatalf("Failed to get new version: %v", err)
	}

	if err == migrate.ErrNoChange {
		fmt.Println("No migration changes applied")
	} else {
		fmt.Printf("Migration completed successfully. New version: %d (dirty: %v)\n", newVersion, dirty)
	}
}