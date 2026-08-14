SHELL         := /bin/bash
.SHELLFLAGS   := -eu -o pipefail -c
.DEFAULT_GOAL := help

PACKAGE := Packages/AnySSHKit

.PHONY: help doctor vendor build test test-sim ui-test run screenshot record lint format sim clean

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk -F':.*?## ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

doctor: ## Verify the toolchain and repair the SDK to runtime mapping
	@Scripts/doctor.sh

vendor: ## Build the pinned libssh2 + OpenSSL xcframework. Add --force to rebuild
	@Scripts/vendor-libssh2.sh $(ARGS)

build: doctor ## Build the app for the simulator
	@Scripts/build.sh

test: ## Tier 1: pure logic on the host. No simulator.
	@cd $(PACKAGE) && swift test

test-sim: doctor ## Tier 2: package tests on the simulator
	@Scripts/test-sim.sh

ui-test: build ## Tier 3: XCUITest flows
	@Scripts/ui-test.sh

run: build ## Boot, install and launch in mock mode
	@Scripts/run.sh

screenshot: build ## Capture a mock-mode screenshot headlessly
	@Scripts/screenshot.sh

record: ## Record video while the app runs. Ctrl-C to finish.
	@xcrun simctl io "$$(Scripts/udid.sh "$${DEVICE:-iPhone 17 Pro}")" \
	  recordVideo --codec=h264 --force .build/artifacts/AnySSH.mp4

lint: ## Formatting, the 300-line budget, comments and the module rules
	@Scripts/lint.sh

format: ## Rewrite sources in place
	@Scripts/format.sh

sim: ## Create a private simulator. make sim NAME=agent-3
	@xcrun simctl create "$(NAME)" "iPhone 17 Pro" \
	  com.apple.CoreSimulator.SimRuntime.iOS-26-2

clean: ## Remove build products
	@rm -rf .build && cd $(PACKAGE) && swift package clean
