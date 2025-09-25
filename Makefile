# iDict Makefile
# 用于构建 macOS 应用程序
# 作者: David
# 版本: 2.0

.PHONY: all clean debug release run install uninstall help info test lint format archive

# =============================================================================
# 项目配置
# =============================================================================

PROJECT_NAME = iDict
SCHEME_NAME = iDict
BUILD_DIR = build
DERIVED_DATA_DIR = ~/Library/Developer/Xcode/DerivedData
INSTALL_DIR = /Applications
ARCHIVE_DIR = archive

# 颜色定义
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
PURPLE = \033[0;35m
CYAN = \033[0;36m
WHITE = \033[0;37m
NC = \033[0m # No Color

# =============================================================================
# 默认目标
# =============================================================================

all: help

# =============================================================================
# 帮助信息
# =============================================================================

help:
	@echo "$(CYAN)iDict 构建系统$(NC)"
	@echo "$(CYAN)================$(NC)"
	@echo ""
	@echo "$(GREEN)构建命令:$(NC)"
	@echo "  $(YELLOW)debug$(NC)      - 构建 Debug 版本 (开发用)"
	@echo "  $(YELLOW)release$(NC)    - 构建 Release 版本 (生产用)"
	@echo "  $(YELLOW)archive$(NC)    - 创建发布归档"
	@echo ""
	@echo "$(GREEN)运行命令:$(NC)"
	@echo "  $(YELLOW)run$(NC)        - 构建并运行 Debug 版本"
	@echo "  $(YELLOW)run-release$(NC) - 构建并运行 Release 版本"
	@echo ""
	@echo "$(GREEN)安装命令:$(NC)"
	@echo "  $(YELLOW)install$(NC)    - 安装 Release 版本到 Applications"
	@echo "  $(YELLOW)uninstall$(NC)  - 从 Applications 卸载应用"
	@echo ""
	@echo "$(GREEN)工具命令:$(NC)"
	@echo "  $(YELLOW)clean$(NC)      - 清理所有构建文件"
	@echo "  $(YELLOW)test$(NC)       - 运行测试"
	@echo "  $(YELLOW)lint$(NC)       - 代码检查"
	@echo "  $(YELLOW)format$(NC)     - 代码格式化"
	@echo "  $(YELLOW)info$(NC)       - 显示项目信息"
	@echo "  $(YELLOW)help$(NC)       - 显示此帮助信息"

# =============================================================================
# 清理命令
# =============================================================================

clean:
	@echo "$(YELLOW)清理构建文件...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DERIVED_DATA_DIR)/$(PROJECT_NAME)-*
	@rm -rf $(ARCHIVE_DIR)
	@echo "$(GREEN)清理完成$(NC)"

# =============================================================================
# 构建命令
# =============================================================================

debug: clean
	@echo "$(BLUE)构建 Debug 版本...$(NC)"
	@xcodebuild \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME_NAME) \
		-configuration Debug \
		-derivedDataPath $(BUILD_DIR) \
		-destination 'platform=macOS' \
		build
	@echo "$(GREEN)Debug 构建完成$(NC)"

release: clean
	@echo "$(BLUE)构建 Release 版本...$(NC)"
	@$(MAKE) _update_version
	@xcodebuild \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME_NAME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		-destination 'platform=macOS' \
		build
	@echo "$(GREEN)Release 构建完成$(NC)"

_update_version:
	@echo "$(YELLOW)更新版本信息...$(NC)"
	@INFO_PLIST="$(PROJECT_NAME)/Info.plist"; \
	PROJECT_FILE="$(PROJECT_NAME).xcodeproj/project.pbxproj"; \
	if [ -f "$$INFO_PLIST" ] && [ -f "$$PROJECT_FILE" ]; then \
		CURRENT_VERSION=$$(xcodebuild -project $(PROJECT_NAME).xcodeproj -showBuildSettings | grep "MARKETING_VERSION" | head -1 | awk '{print $$3}' || echo "1.0.0"); \
		echo "$(CYAN)当前版本: $$CURRENT_VERSION$(NC)"; \
		MAJOR=$$(echo $$CURRENT_VERSION | cut -d. -f1); \
		MINOR=$$(echo $$CURRENT_VERSION | cut -d. -f2); \
		PATCH=$$(echo $$CURRENT_VERSION | cut -d. -f3 2>/dev/null || echo "0"); \
		NEW_PATCH=$$((PATCH + 1)); \
		NEW_VERSION="$$MAJOR.$$MINOR.$$NEW_PATCH"; \
		BUILD_NUMBER=$$(date +%Y%m%d%H%M%S); \
		echo "$(CYAN)新版本: $$NEW_VERSION$(NC)"; \
		echo "$(CYAN)构建号: $$BUILD_NUMBER$(NC)"; \
		plutil -replace CFBundleShortVersionString -string "$$NEW_VERSION" "$$INFO_PLIST"; \
		plutil -replace CFBundleVersion -string "$$BUILD_NUMBER" "$$INFO_PLIST"; \
		sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $$NEW_VERSION/g" "$$PROJECT_FILE"; \
		sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*/CURRENT_PROJECT_VERSION = $$BUILD_NUMBER/g" "$$PROJECT_FILE"; \
		echo "$(GREEN)版本信息已更新$(NC)"; \
	else \
		echo "$(RED)错误: 找不到 Info.plist 或项目文件$(NC)"; \
		exit 1; \
	fi

# =============================================================================
# 运行命令
# =============================================================================

run: debug
	@echo "$(BLUE)启动 Debug 应用...$(NC)"
	@$(MAKE) _run_app

run-release: release
	@echo "$(BLUE)启动 Release 应用...$(NC)"
	@$(MAKE) _run_app

_run_app:
	@APP_PATH=$$(find $(BUILD_DIR) -name "$(PROJECT_NAME).app" -type d | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		echo "$(GREEN)启动应用: $$APP_PATH$(NC)"; \
		open "$$APP_PATH"; \
	else \
		echo "$(RED)错误: 找不到构建的应用程序$(NC)"; \
		exit 1; \
	fi

# =============================================================================
# 安装命令
# =============================================================================

install: release
	@echo "$(BLUE)安装应用到 Applications 文件夹...$(NC)"
	@$(MAKE) _stop_app
	@$(MAKE) _uninstall_app
	@$(MAKE) _install_app

_stop_app:
	@echo "$(YELLOW)关闭正在运行的应用...$(NC)"
	@pkill -f "$(PROJECT_NAME)" 2>/dev/null || echo "$(CYAN)应用未运行$(NC)"

_uninstall_app:
	@echo "$(YELLOW)卸载旧版本应用...$(NC)"
	@if [ -d "$(INSTALL_DIR)/$(PROJECT_NAME).app" ]; then \
		rm -rf "$(INSTALL_DIR)/$(PROJECT_NAME).app"; \
		echo "$(GREEN)旧版本已卸载$(NC)"; \
	else \
		echo "$(CYAN)未找到已安装的应用$(NC)"; \
	fi

_install_app:
	@APP_PATH=$$(find $(BUILD_DIR) -name "$(PROJECT_NAME).app" -type d | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		echo "$(YELLOW)复制应用到 $(INSTALL_DIR)...$(NC)"; \
		cp -R "$$APP_PATH" $(INSTALL_DIR)/; \
		echo "$(GREEN)安装完成: $(INSTALL_DIR)/$(PROJECT_NAME).app$(NC)"; \
		echo "$(CYAN)应用已注册到 Launch Services$(NC)"; \
	else \
		echo "$(RED)错误: 找不到构建的应用程序$(NC)"; \
		exit 1; \
	fi

uninstall:
	@echo "$(YELLOW)从 Applications 卸载应用...$(NC)"
	@if [ -d "$(INSTALL_DIR)/$(PROJECT_NAME).app" ]; then \
		rm -rf "$(INSTALL_DIR)/$(PROJECT_NAME).app"; \
		echo "$(GREEN)卸载完成$(NC)"; \
	else \
		echo "$(YELLOW)应用未安装$(NC)"; \
	fi

# =============================================================================
# 归档命令
# =============================================================================

archive: release
	@echo "$(BLUE)创建发布归档...$(NC)"
	@mkdir -p $(ARCHIVE_DIR)
	@APP_PATH=$$(find $(BUILD_DIR) -name "$(PROJECT_NAME).app" -type d | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		ARCHIVE_NAME="$(PROJECT_NAME)-$$(date +%Y%m%d-%H%M%S).app"; \
		cp -R "$$APP_PATH" "$(ARCHIVE_DIR)/$$ARCHIVE_NAME"; \
		echo "$(GREEN)归档完成: $(ARCHIVE_DIR)/$$ARCHIVE_NAME$(NC)"; \
	else \
		echo "$(RED)错误: 找不到构建的应用程序$(NC)"; \
		exit 1; \
	fi

# =============================================================================
# 工具命令
# =============================================================================

test:
	@echo "$(BLUE)运行测试...$(NC)"
	@xcodebuild test \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME_NAME) \
		-destination 'platform=macOS'
	@echo "$(GREEN)测试完成$(NC)"

lint:
	@echo "$(BLUE)代码检查...$(NC)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint; \
		echo "$(GREEN)代码检查完成$(NC)"; \
	else \
		echo "$(YELLOW)SwiftLint 未安装，跳过代码检查$(NC)"; \
	fi

format:
	@echo "$(BLUE)代码格式化...$(NC)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --fix; \
		echo "$(GREEN)代码格式化完成$(NC)"; \
	else \
		echo "$(YELLOW)SwiftLint 未安装，跳过代码格式化$(NC)"; \
	fi

info:
	@echo "$(CYAN)项目信息:$(NC)"
	@echo "$(CYAN)==========$(NC)"
	@xcodebuild -project $(PROJECT_NAME).xcodeproj -list
	@echo ""
	@echo "$(CYAN)构建状态:$(NC)"
	@if [ -d "$(BUILD_DIR)" ]; then \
		echo "$(GREEN)构建目录存在: $(BUILD_DIR)$(NC)"; \
		ls -la $(BUILD_DIR)/Build/Products/*/$(PROJECT_NAME).app 2>/dev/null || echo "$(YELLOW)未找到构建的应用$(NC)"; \
	else \
		echo "$(YELLOW)构建目录不存在$(NC)"; \
	fi
	@echo ""
	@echo "$(CYAN)安装状态:$(NC)"
	@if [ -d "$(INSTALL_DIR)/$(PROJECT_NAME).app" ]; then \
		echo "$(GREEN)应用已安装: $(INSTALL_DIR)/$(PROJECT_NAME).app$(NC)"; \
	else \
		echo "$(YELLOW)应用未安装$(NC)"; \
	fi