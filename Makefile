# Stolen from https://github.com/airbnb/gosal/blob/master/Makefile
all: build

.PHONY: build

ifndef ($(GOPATH))
	GOPATH = $(HOME)/go
endif

PATH := $(GOPATH)/bin:$(PATH)
VERSION = $(shell git describe --tags --always --dirty)
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
REVISION = $(shell git rev-parse HEAD)
REVSHORT = $(shell git rev-parse --short HEAD)
APP_NAME = gorilla
GO111MODULE = on

ifneq ($(OS), Windows_NT)
	CURRENT_PLATFORM = linux
	# If on macOS, set the shell to bash explicitly
	ifeq ($(shell uname), Darwin)
		SHELL := /bin/bash
		CURRENT_PLATFORM = darwin
	endif

	# To populate version metadata, we use unix tools to get certain data
	GOVERSION = $(shell go version | awk '{print $$3}')
	NOW	= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
else
	CURRENT_PLATFORM = windows

	# To populate version metadata, we use windows tools to get the certain data
	GOVERSION_CMD = "(go version).Split()[2]"
	GOVERSION = $(shell powershell $(GOVERSION_CMD))
	NOW	= $(shell powershell Get-Date -format s)
endif

BUILD_VERSION = "\
	-X github.com/rodchristiansen/gorilla/pkg/version.appName=${APP_NAME} \
	-X github.com/rodchristiansen/gorilla/pkg/version.version=${VERSION} \
	-X github.com/rodchristiansen/gorilla/pkg/version.branch=${BRANCH} \
	-X github.com/rodchristiansen/gorilla/pkg/version.buildDate=${NOW} \
	-X github.com/rodchristiansen/gorilla/pkg/version.revision=${REVISION} \
	-X github.com/rodchristiansen/gorilla/pkg/version.goVersion=${GOVERSION}"

define HELP_TEXT

  Makefile commands

	make deps         - Install dependent programs and libraries
	make clean        - Delete all build artifacts

	make build        - Build the code

	make test         - Run the Go tests
	make lint         - Run the Go linters

endef

help:
	$(info $(HELP_TEXT))

gomodcheck:
	@go help mod > /dev/null || (@echo gorilla requires Go version 1.11 or higher && exit 1)

clean:
	rm -rf build/

.pre-build: gomodcheck
	mkdir -p build/

build: .pre-build
	GOOS=windows GOARCH=amd64 go build -o build/${APP_NAME}.exe -ldflags ${BUILD_VERSION} ./cmd/gorilla

test: gomodcheck
	go test -cover -race ./...

lint:
	@if gofmt -l -s ./cmd/ ./pkg/ | grep .go; then \
	  echo "^- Repo contains improperly formatted go files; run gofmt -w -s *.go" && exit 1; \
	  else echo "All .go files formatted correctly"; fi
	GOOS=windows GOARCH=amd64 go vet ./...
	golint -set_exit_status `go list ./... | grep -v /vendor/`