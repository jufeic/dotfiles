.DEFAULT_GOAL := build
MAIN_PACKAGE_PATH = ./cmd/
BINARY_NAME = program

.PHONY: tidy build run

tidy:
	go mod tidy -v -x
	go fmt ./...

build: tidy
	mkdir -p target
	go build -o ./target/${BINARY_NAME} ${MAIN_PACKAGE_PATH} 
	go version -m ./target/${BINARY_NAME}

run: build
	./target/${BINARY_NAME}