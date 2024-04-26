.PHONY: build buildRelease install clean

build:
	./generate_resources
	swift build

buildRelease:
	./generate_resources
	swift build -c release

install:
	./generate_resources
	swift build -c release
	sudo cp ./.build/release/pkl-lsp-server /usr/local/bin/pkl-lsp-server

clean:
	rm Sources/pkl-lsp/Resources.swift
	swift package clean
