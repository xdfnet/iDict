# iDict Makefile

.PHONY: help clean debug release install package push _update_version _require_msg _verify_release

PROJECT_NAME = iDict
SCHEME_NAME = iDict
PROJECT_FILE = $(PROJECT_NAME).xcodeproj
BUILD_ROOT = $(CURDIR)/build
DERIVED_DATA_DIR = $(BUILD_ROOT)/DerivedData
PRODUCTS_DIR = $(DERIVED_DATA_DIR)/Build/Products
DEBUG_APP = $(PRODUCTS_DIR)/Debug/$(PROJECT_NAME).app
RELEASE_APP = $(PRODUCTS_DIR)/Release/$(PROJECT_NAME).app
INSTALL_DIR = /Applications
INSTALL_APP = $(INSTALL_DIR)/$(PROJECT_NAME).app
PACKAGE_DIR = $(BUILD_ROOT)/packages

RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
CYAN = \033[0;36m
NC = \033[0m

.DEFAULT_GOAL := help

help:
	@echo "$(CYAN)iDict build commands$(NC)"
	@echo "$(CYAN)===================$(NC)"
	@echo ""
	@echo "$(GREEN)Core$(NC)"
	@echo "  $(YELLOW)make debug$(NC)                 Build and launch Debug"
	@echo "  $(YELLOW)make release$(NC)               Clean build Release and verify signing"
	@echo "  $(YELLOW)make install$(NC)               Install Release to /Applications with backup"
	@echo "  $(YELLOW)make package$(NC)               Create a zip from the Release app"
	@echo ""
	@echo "$(GREEN)Publish$(NC)"
	@echo "  $(YELLOW)make push MSG=\"message\"$(NC)    Bump version, install, package, commit and push"
	@echo ""
	@echo "$(GREEN)Cleanup$(NC)"
	@echo "  $(YELLOW)make clean$(NC)                 Remove local build artifacts"

clean:
	@echo "$(YELLOW)Cleaning local build artifacts...$(NC)"
	@rm -rf "$(BUILD_ROOT)"
	@echo "$(GREEN)Done$(NC)"

debug:
	@echo "$(BLUE)Building Debug...$(NC)"
	@pkill -x "$(PROJECT_NAME)" 2>/dev/null || true
	@xcodebuild \
		-project "$(PROJECT_FILE)" \
		-scheme "$(SCHEME_NAME)" \
		-configuration Debug \
		-derivedDataPath "$(DERIVED_DATA_DIR)" \
		-destination 'platform=macOS' \
		build
	@if [ ! -d "$(DEBUG_APP)" ]; then \
		echo "$(RED)Debug app not found: $(DEBUG_APP)$(NC)"; \
		exit 1; \
	fi
	@open "$(DEBUG_APP)"
	@echo "$(GREEN)Debug app launched$(NC)"

release: clean
	@echo "$(BLUE)Building Release...$(NC)"
	@xcodebuild \
		-project "$(PROJECT_FILE)" \
		-scheme "$(SCHEME_NAME)" \
		-configuration Release \
		-derivedDataPath "$(DERIVED_DATA_DIR)" \
		-destination 'platform=macOS' \
		build
	@$(MAKE) _verify_release

_verify_release:
	@if [ ! -d "$(RELEASE_APP)" ]; then \
		echo "$(RED)Release app not found: $(RELEASE_APP)$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Verifying code signature...$(NC)"
	@codesign -dv --verbose=2 "$(RELEASE_APP)" >/dev/null
	@spctl --assess --verbose=2 "$(RELEASE_APP)"
	@echo "$(GREEN)Release app passed signing checks$(NC)"

install: release
	@echo "$(BLUE)Installing Release to $(INSTALL_DIR)...$(NC)"
	@pkill -x "$(PROJECT_NAME)" 2>/dev/null || true
	@ts=$$(date +%Y%m%d-%H%M%S); \
	if [ -d "$(INSTALL_APP)" ]; then \
		backup="$(INSTALL_DIR)/$(PROJECT_NAME).backup-$$ts.app"; \
		mv "$(INSTALL_APP)" "$$backup"; \
		echo "$(CYAN)Backed up previous app to $$backup$(NC)"; \
	fi; \
	ditto "$(RELEASE_APP)" "$(INSTALL_APP)"
	@xattr -dr com.apple.quarantine "$(INSTALL_APP)" 2>/dev/null || true
	@open "$(INSTALL_APP)"
	@echo "$(GREEN)Installed $(INSTALL_APP)$(NC)"

package: release
	@echo "$(BLUE)Packaging Release zip...$(NC)"
	@mkdir -p "$(PACKAGE_DIR)"
	@version=$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$(RELEASE_APP)/Contents/Info.plist"); \
	build=$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$(RELEASE_APP)/Contents/Info.plist"); \
	zip_path="$(PACKAGE_DIR)/$(PROJECT_NAME)-$$version-$$build.zip"; \
	rm -f "$$zip_path"; \
	ditto -c -k --keepParent "$(RELEASE_APP)" "$$zip_path"; \
	echo "$(GREEN)Created $$zip_path$(NC)"

_update_version:
	@echo "$(YELLOW)Updating version metadata...$(NC)"
	@PROJECT_PBXPROJ="$(PROJECT_FILE)/project.pbxproj"; \
	README_FILE="README.md"; \
	CURRENT_VERSION=$$(xcodebuild -project "$(PROJECT_FILE)" -scheme "$(SCHEME_NAME)" -configuration Release -showBuildSettings | awk '/MARKETING_VERSION/ { print $$3; exit }'); \
	if [ -z "$$CURRENT_VERSION" ]; then \
		echo "$(RED)Could not determine current version$(NC)"; \
		exit 1; \
	fi; \
	MAJOR=$$(echo "$$CURRENT_VERSION" | cut -d. -f1); \
	MINOR=$$(echo "$$CURRENT_VERSION" | cut -d. -f2); \
	PATCH=$$(echo "$$CURRENT_VERSION" | cut -d. -f3); \
	NEW_VERSION="$$MAJOR.$$MINOR.$$((PATCH + 1))"; \
	BUILD_NUMBER=$$(date +%Y%m%d%H%M%S); \
	echo "$(CYAN)Version $$CURRENT_VERSION -> $$NEW_VERSION$(NC)"; \
	echo "$(CYAN)Build $$BUILD_NUMBER$(NC)"; \
	sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $$NEW_VERSION/g" "$$PROJECT_PBXPROJ"; \
	sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*/CURRENT_PROJECT_VERSION = $$BUILD_NUMBER/g" "$$PROJECT_PBXPROJ"; \
	if [ -f "$$README_FILE" ]; then \
		sed -i '' "s/version-v[0-9][0-9]*\\.[0-9][0-9]*\\.[0-9][0-9]*/version-v$$NEW_VERSION/g" "$$README_FILE"; \
	fi; \
	echo "$(GREEN)Version metadata updated$(NC)"

_require_msg:
	@if [ -z "$(MSG)" ]; then \
		echo "$(RED)Missing commit message$(NC)"; \
		echo "$(YELLOW)Usage: make push MSG=\"your message\"$(NC)"; \
		exit 1; \
	fi

push: _require_msg _update_version install package
	@echo "$(BLUE)Committing and pushing...$(NC)"
	@branch=$$(git branch --show-current); \
	if [ -z "$$branch" ]; then \
		echo "$(RED)Could not determine current branch$(NC)"; \
		exit 1; \
	fi; \
	git add .; \
	git commit -m "$(MSG)"; \
	git push origin "$$branch"; \
	echo "$(GREEN)Pushed to $$branch$(NC)"
