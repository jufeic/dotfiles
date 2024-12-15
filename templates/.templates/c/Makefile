.DEFAULT_GOAL := build
BINARY_NAME = program

.PHONY: build run

build:
	mkdir -p target
	gcc -Wall -o ./target/${BINARY_NAME} *.c

run: build
	./target/${BINARY_NAME}