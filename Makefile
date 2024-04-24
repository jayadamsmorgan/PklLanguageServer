.PHONY: build buildRelease install

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
