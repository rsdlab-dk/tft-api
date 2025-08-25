.PHONY: test build clean lint fmt vet mod-tidy mod-verify examples

test:
	go test -v -race -coverprofile=coverage.out ./...

test-coverage:
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

build:
	go build ./...

clean:
	go clean -testcache
	rm -f coverage.out coverage.html

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

pre-commit: fmt vet lint test

release-check: mod-tidy mod-verify pre-commit
	@echo "✅ Ready for release"