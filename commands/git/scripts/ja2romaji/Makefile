.PHONY: build test install clean deps run help

BINARY_NAME=ja2romaji
INSTALL_DIR=../bin
GO=go

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

deps: ## Download dependencies
	$(GO) mod download
	$(GO) mod tidy

build: deps ## Build the binary
	$(GO) build -o $(BINARY_NAME) .

test: ## Run tests
	$(GO) test -v ./...

install: build ## Build and install to bin directory
	mkdir -p $(INSTALL_DIR)
	cp $(BINARY_NAME) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(BINARY_NAME)"

clean: ## Remove built binary
	rm -f $(BINARY_NAME)
	rm -f $(INSTALL_DIR)/$(BINARY_NAME)

run: build ## Build and run with example
	./$(BINARY_NAME) "認証機能の実装"

# Cross-compilation targets
build-linux: deps ## Build for Linux AMD64
	GOOS=linux GOARCH=amd64 $(GO) build -o $(BINARY_NAME)-linux-amd64 .

build-mac-intel: deps ## Build for macOS Intel
	GOOS=darwin GOARCH=amd64 $(GO) build -o $(BINARY_NAME)-darwin-amd64 .

build-mac-arm: deps ## Build for macOS ARM (M1/M2)
	GOOS=darwin GOARCH=arm64 $(GO) build -o $(BINARY_NAME)-darwin-arm64 .

build-all: build-linux build-mac-intel build-mac-arm ## Build for all platforms
