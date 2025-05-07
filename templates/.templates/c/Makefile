.DEFAULT_GOAL := build
CC=gcc
CFLAGS=-Wall -Wextra -Werror -Wshadow -Wpedantic -pedantic-errors -g -fsanitize=address
BINARY_NAME = program
LINUX_COMPILE_IMAGE = docker.io/library/gcc@sha256:16aea78a24ad0c562e63fe3060d3ce85f96101ecd1db09b67b1ccd9bff7dfe4d

.PHONY: build run

build-strict:
	mkdir -p target
	$(CC) $(CFLAGS) -o ./target/${BINARY_NAME} *.c

build:
	mkdir -p target
	$(CC) -o ./target/${BINARY_NAME} *.c

run-strict: build-strict
	./target/${BINARY_NAME}

run: build
	./target/${BINARY_NAME}

linux:
	@podman run --cidfile="$$(pwd)"/.cid-"$$(basename $$(tmux display-message -p '#{pane_tty}'))" \
		-it --rm -v $$(pwd):/app -w /app $(LINUX_COMPILE_IMAGE)
