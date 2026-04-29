# Makefile for flutter-floating-bottom-bar
#
# Layout:
#   ./                                       -> demo/example app (floating_bottom_bar)
#   packages/flutter_floating_bottom_bar/    -> the published Flutter package
#
# Override the Flutter binary if needed, e.g.:
#   make get FLUTTER="flutter"
# Defaults to fvm (the repo pins a Flutter version in .fvmrc).

FLUTTER ?= fvm flutter
DART    ?= fvm dart

PKG_DIR := packages/flutter_floating_bottom_bar
APP_DIR := .

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

.PHONY: setup
setup: get-pkg get-app ## Fetch deps for both the package and the example app

.PHONY: get
get: setup ## Alias for setup

.PHONY: get-pkg
get-pkg: ## Fetch package dependencies
	cd $(PKG_DIR) && $(FLUTTER) pub get

.PHONY: get-app
get-app: ## Fetch example app dependencies
	cd $(APP_DIR) && $(FLUTTER) pub get

.PHONY: upgrade
upgrade: ## Upgrade dependencies in package and app
	cd $(PKG_DIR) && $(FLUTTER) pub upgrade
	cd $(APP_DIR) && $(FLUTTER) pub upgrade

# ---------------------------------------------------------------------------
# Quality
# ---------------------------------------------------------------------------

.PHONY: format
format: ## Format all Dart code
	$(DART) format .

.PHONY: format-check
format-check: ## Check formatting without writing changes
	$(DART) format --set-exit-if-changed .

.PHONY: analyze
analyze: analyze-pkg analyze-app ## Run static analysis on package and app

.PHONY: analyze-pkg
analyze-pkg:
	cd $(PKG_DIR) && $(FLUTTER) analyze

.PHONY: analyze-app
analyze-app:
	cd $(APP_DIR) && $(FLUTTER) analyze

.PHONY: test
test: test-pkg test-app ## Run tests for package and app

.PHONY: test-pkg
test-pkg:
	cd $(PKG_DIR) && $(FLUTTER) test

.PHONY: test-app
test-app:
	cd $(APP_DIR) && $(FLUTTER) test

.PHONY: check
check: format-check analyze test ## Format check + analyze + test

# ---------------------------------------------------------------------------
# Run example app
# ---------------------------------------------------------------------------

.PHONY: run
run: ## Run the example app on the default device
	cd $(APP_DIR) && $(FLUTTER) run

.PHONY: run-android
run-android: ## Run the example app on Android
	cd $(APP_DIR) && $(FLUTTER) run -d android

.PHONY: run-ios
run-ios: ## Run the example app on iOS
	cd $(APP_DIR) && $(FLUTTER) run -d ios

.PHONY: run-web
run-web: ## Run the example app on Chrome
	cd $(APP_DIR) && $(FLUTTER) run -d chrome

.PHONY: run-macos
run-macos: ## Run the example app on macOS
	cd $(APP_DIR) && $(FLUTTER) run -d macos

# ---------------------------------------------------------------------------
# Build example app
# ---------------------------------------------------------------------------

.PHONY: build-apk
build-apk: ## Build release APK
	cd $(APP_DIR) && $(FLUTTER) build apk --release

.PHONY: build-appbundle
build-appbundle: ## Build release Android App Bundle
	cd $(APP_DIR) && $(FLUTTER) build appbundle --release

.PHONY: build-ios
build-ios: ## Build release iOS app (no codesign)
	cd $(APP_DIR) && $(FLUTTER) build ios --release --no-codesign

.PHONY: build-web
build-web: ## Build release web bundle
	cd $(APP_DIR) && $(FLUTTER) build web --release

.PHONY: build-macos
build-macos: ## Build release macOS app
	cd $(APP_DIR) && $(FLUTTER) build macos --release

.PHONY: build-linux
build-linux: ## Build release Linux app
	cd $(APP_DIR) && $(FLUTTER) build linux --release

.PHONY: build-windows
build-windows: ## Build release Windows app
	cd $(APP_DIR) && $(FLUTTER) build windows --release

# ---------------------------------------------------------------------------
# Publishing the package
# ---------------------------------------------------------------------------

.PHONY: publish-dry-run
publish-dry-run: ## Validate the package for pub.dev without publishing
	cd $(PKG_DIR) && $(FLUTTER) pub publish --dry-run

.PHONY: publish
publish: ## Publish the package to pub.dev
	cd $(PKG_DIR) && $(FLUTTER) pub publish

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

.PHONY: clean
clean: ## Clean build artifacts in package and app
	cd $(PKG_DIR) && $(FLUTTER) clean
	cd $(APP_DIR) && $(FLUTTER) clean

.PHONY: distclean
distclean: clean ## Clean + remove pub caches and lockfiles
	rm -rf $(APP_DIR)/.dart_tool $(PKG_DIR)/.dart_tool
	rm -f $(APP_DIR)/pubspec.lock $(PKG_DIR)/pubspec.lock
