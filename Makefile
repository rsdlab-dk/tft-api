.PHONY: test build clean lint fmt vet mod-tidy mod-verify examples
.PHONY: db-up db-down db-reset db-status db-force db-drop db-create-migration
.PHONY: docker-up docker-down docker-logs docker-clean
.PHONY: dev staging prod install-tools

# Go commands
test:
	go test -v -race -coverprofile=coverage.out ./...

test-coverage:
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

build:
	go build -o bin/tft-api ./cmd/api
	go build -o bin/migrate ./cmd/migrate

clean:
	go clean -testcache
	rm -f coverage.out coverage.html
	rm -rf bin/

lint:
	golangci-lint run

fmt:
	go fmt ./...

vet:
	go vet ./...

mod-tidy:
	go mod tidy

mod-verify:
	go mod verify

install-tools:
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Database migrations
db-up:
	./bin/migrate -config .env.development -direction up

db-down:
	./bin/migrate -config .env.development -direction down -steps 1

db-reset:
	./bin/migrate -config .env.development -direction down
	./bin/migrate -config .env.development -direction up

db-status:
	./bin/migrate -config .env.development

db-force:
	@read -p "Enter version to force: " version; \
	./bin/migrate -config .env.development -force $version

db-drop:
	@echo "WARNING: This will drop ALL tables!"
	@read -p "Are you sure? (yes/no): " confirm; \
	[ "$confirm" = "yes" ] && ./bin/migrate -config .env.development -drop

db-create-migration:
	@read -p "Enter migration name: " name; \
	migrate create -ext sql -dir migrations $name

# Database operations for different environments
db-up-staging:
	./bin/migrate -config .env.staging -direction up

db-up-prod:
	./bin/migrate -config .env.production -direction up

# Docker operations
docker-up:
	docker-compose -f docker-compose.services.yml up -d

docker-down:
	docker-compose -f docker-compose.services.yml down

docker-logs:
	docker-compose -f docker-compose.services.yml logs -f

docker-clean:
	docker-compose -f docker-compose.services.yml down -v --remove-orphans
	docker system prune -f

# Environment setup
dev: docker-up
	@echo "Waiting for services to be ready..."
	@sleep 10
	@make db-up
	@echo "Development environment ready!"

staging:
	@echo "Setting up staging environment..."
	@make db-up-staging

prod:
	@echo "Setting up production environment..."
	@make db-up-prod

# Development helpers
dev-reset: docker-clean dev

dev-logs:
	@echo "=== PostgreSQL Logs ==="
	docker logs tft-postgresql --tail 50
	@echo "\n=== Redis Logs ==="
	docker logs tft-redis --tail 50
	@echo "\n=== NATS Logs ==="
	docker logs tft-nats --tail 50

dev-shell-db:
	docker exec -it tft-postgresql psql -U tft_user -d tft_arena_dev

dev-shell-redis:
	docker exec -it tft-redis redis-cli -a $(grep REDIS_PASSWORD .env.development | cut -d '=' -f2)

# Testing helpers
test-db:
	@echo "Setting up test database..."
	docker run --rm -d --name tft-test-db \
		-p 5433:5432 \
		-e POSTGRES_DB=tft_arena_test \
		-e POSTGRES_USER=tft_user \
		-e POSTGRES_PASSWORD=test_password \
		postgres:17.0
	@sleep 5
	@DB_PORT=5433 DB_NAME=tft_arena_test DB_PASSWORD=test_password ./bin/migrate -direction up
	@echo "Test database ready on port 5433"

test-db-clean:
	docker stop tft-test-db || true
	docker rm tft-test-db || true

test-integration: build test-db
	@echo "Running integration tests..."
	@DB_PORT=5433 DB_NAME=tft_arena_test DB_PASSWORD=test_password go test -v -tags=integration ./...
	@make test-db-clean

# Health checks
health-check:
	@echo "Checking service health..."
	@docker exec tft-postgresql pg_isready -U tft_user -d tft_arena_dev || echo "PostgreSQL: UNHEALTHY"
	@docker exec tft-redis redis-cli ping > /dev/null && echo "Redis: HEALTHY" || echo "Redis: UNHEALTHY"
	@curl -sf http://localhost:8222/healthz > /dev/null && echo "NATS: HEALTHY" || echo "NATS: UNHEALTHY"

# Code quality
pre-commit: fmt vet lint test

quality-check: mod-tidy mod-verify pre-commit
	@echo "✅ Code quality check passed"

# Release preparation
release-check: quality-check
	@echo "✅ Ready for release"

# Configuration validation
validate-config:
	@echo "Validating development configuration..."
	@go run ./cmd/validate-config -config .env.development
	@echo "✅ Development config valid"

validate-config-staging:
	@echo "Validating staging configuration..."
	@go run ./cmd/validate-config -config .env.staging
	@echo "✅ Staging config valid"

validate-config-prod:
	@echo "Validating production configuration..."
	@go run ./cmd/validate-config -config .env.production
	@echo "✅ Production config valid"

# Documentation
docs-generate:
	@echo "Generating API documentation..."
	@swag init -g cmd/api/main.go -o docs/
	@echo "✅ Documentation generated in docs/"

# Examples
examples-basic:
	cd examples/basic && go run main.go

examples-server:
	cd examples/server && go run main.go

# Complete setup
setup: install-tools build dev validate-config
	@echo "🎉 TFT Arena setup complete!"
	@echo "🔥 Development server ready at http://localhost:8080"
	@echo "📊 Database accessible at localhost:5432"
	@echo "⚡ Redis accessible at localhost:6379"
	@echo "📨 NATS accessible at localhost:4222"

# Cleanup everything
nuke: docker-clean clean
	docker volume prune -f
	@echo "💥 Everything cleaned up!"