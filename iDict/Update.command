#!/bin/bash

# 更新软件脚本
# 更新 Homebrew 安装包和 npm 全局安装包

# 获取当前终端应用的进程ID
TERMINAL_PID=$PPID

echo "=========================================="
echo "🚀 macOS 软件包智能更新工具 v1.0"
echo "=========================================="

# 检测 Homebrew 路径
BREW_PATH=""
if [ -f "/opt/homebrew/bin/brew" ]; then
    BREW_PATH="/opt/homebrew/bin/brew"
elif [ -f "/usr/local/bin/brew" ]; then
    BREW_PATH="/usr/local/bin/brew"
elif command -v brew >/dev/null 2>&1; then
    BREW_PATH=$(which brew)
fi

# 检测 npm 路径
NPM_PATH=""
if [ -f "/Users/apple/.npm-packages/bin/npm" ]; then
    NPM_PATH="/Users/apple/.npm-packages/bin/npm"
elif [ -f "/usr/local/bin/npm" ]; then
    NPM_PATH="/usr/local/bin/npm"
elif [ -f "/opt/homebrew/bin/npm" ]; then
    NPM_PATH="/opt/homebrew/bin/npm"
elif command -v npm >/dev/null 2>&1; then
    NPM_PATH=$(which npm)
fi

# 1. 检查并更新 Homebrew
echo "🍺 [1/3] 更新 Homebrew 自身和包索引 (brew update)..."
if [ -n "$BREW_PATH" ]; then
    "$BREW_PATH" update
    if [ $? -eq 0 ]; then
        echo "✅ Homebrew 本身和列表更新完成"
    else
        echo "❌ Homebrew 本身和列表更新失败"
    fi
else
    echo "⚠️ 未检测到 Homebrew，跳过 Homebrew 更新"
fi

echo "=========================================="
# 2. 检查并更新 brew 安装包
echo "📦 [2/3] 升级所有过期的 Homebrew 安装包 (brew upgrade)..."
if [ -n "$BREW_PATH" ]; then
    HOMEBREW_OUTDATED=$("$BREW_PATH" outdated --quiet 2>/dev/null)
    if [ -n "$HOMEBREW_OUTDATED" ]; then
        echo "检测到待更新的 Homebrew 安装包："
        echo "$HOMEBREW_OUTDATED" | while read line; do
            echo "   📥 ${line:-未知包}"
        done
        echo "正在执行 Homebrew 安装包升级..."
        "$BREW_PATH" upgrade
        # 清理 brew 旧版本
        echo "🧹 清理 Homebrew 旧版本文件..."
        "$BREW_PATH" cleanup
    else
        echo "✅ Homebrew 所有包已是最新版本，无需更新"
    fi
else
    echo "⚠️ 未检测到 Homebrew，跳过包升级"
fi

echo "=========================================="
# 3. 检查并逐个更新 npm 工具包
echo "🟢 [3/3] 检查并逐个更新 npm 工具包..."

if [ -n "$NPM_PATH" ]; then
    # 检查 npm 权限
    NPM_PREFIX=$("$NPM_PATH" config get prefix 2>/dev/null)
    if [ ! -w "$NPM_PREFIX" ]; then
        echo "⚠️  警告：可能没有 npm 全局包写入权限 ($NPM_PREFIX)"
        echo "💡 建议使用 sudo 运行此脚本"
    fi
else
    echo "⚠️ 未检测到 npm，跳过 npm 更新"
fi

# 安全清理 .DS_Store 文件
if [ -d "$HOME/.npm-packages" ]; then
    # echo "🧹 清理 npm 包目录中的 .DS_Store 文件..."
    find "$HOME/.npm-packages" -name ".DS_Store" -type f -delete 2>/dev/null || true
fi

# 检查需要更新的 npm 工具包
if [ -n "$NPM_PATH" ]; then
    echo "📋 检查需要更新的 npm 工具包..."
    NPM_OUTDATED=$("$NPM_PATH" outdated -g 2>/dev/null | awk 'NR>1 && NF>0 {print $1" "$2" → "$4}')

    if [ -n "$NPM_OUTDATED" ]; then
        PACKAGE_COUNT=$(echo "$NPM_OUTDATED" | wc -l | tr -d ' ')
        echo "检测到 $PACKAGE_COUNT 个待更新的 npm 工具包："
        echo ""
        
        # 逐个更新包
        echo "$NPM_OUTDATED" | while read line; do
            PACKAGE_NAME=$(echo "$line" | awk '{print $1}')
            CURRENT_VERSION=$(echo "$line" | awk '{print $2}')
            NEW_VERSION=$(echo "$line" | awk '{print $4}')
            
            echo "📦 正在更新: $PACKAGE_NAME"
            echo "📦 当前版本: $CURRENT_VERSION"
            echo "📦 最新版本: $NEW_VERSION"
            
            echo "🔄 $PACKAGE_NAME 开始更新..."
            if "$NPM_PATH" install -g "$PACKAGE_NAME@latest"; then
                echo "✅ $PACKAGE_NAME 更新成功"
            else
                echo "❌ $PACKAGE_NAME 更新失败"
            fi
            echo "---"
        done
        
        echo "✅ 需要更新的工具包逐个更新完成"
    else
        echo "✅ 所有工具包已是最新版本，无需更新"
    fi
else
    echo "⚠️ 未检测到 npm，跳过包更新"
fi

# 校验 npm 缓存（带错误处理）
if [ -n "$NPM_PATH" ]; then
    echo "🧹 校验 npm 缓存完整性..."
    if "$NPM_PATH" cache verify; then
        echo "✅ npm 缓存校验完成，缓存完整"
    else
        echo "⚠️ npm 缓存校验出现问题，但不影响使用"
    fi
fi

echo "=========================================="
echo "✅ 软件更新完成！"
echo "=========================================="

# 保持终端打开
# exec $SHELL

# 等待3秒后关闭终端窗口
# sleep 3

# 关闭当前终端窗口（改进错误处理）
osascript -e 'tell application "Terminal"
    try
        close front window
    on error
        -- 忽略错误，可能窗口已经关闭
    end try
end tell' >/dev/null 2>&1 &