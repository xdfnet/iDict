#!/bin/bash

# 更新软件脚本
# 更新 Homebrew 安装包和 npm 全局安装包

# 获取当前终端应用的进程ID
TERMINAL_PID=$PPID

echo "=========================================="
echo "🚀 macOS 软件包智能更新工具 v1.0"
echo "=========================================="

# 1. 检查并更新 Homebrew
echo "🍺 [1/3] 更新 Homebrew 自身和包索引 (brew update)..."
brew update
if [ $? -eq 0 ]; then
    echo "✅ Homebrew 本身和列表更新完成"
else
    echo "❌ Homebrew 本身和列表更新失败"
fi

echo "=========================================="
# 2. 检查并更新 brew 安装包
echo "📦 [2/3] 升级所有过期的 Homebrew 安装包 (brew upgrade)..."
HOMEBREW_OUTDATED=$(brew outdated --quiet 2>/dev/null)
if [ -n "$HOMEBREW_OUTDATED" ]; then
    echo "检测到待更新的 Homebrew 安装包："
    echo "$HOMEBREW_OUTDATED" | while read line; do
        echo "   📥 ${line:-未知包}"
    done
    echo "正在执行 Homebrew 安装包升级..."
    brew upgrade
    # 清理 brew 旧版本
    echo "🧹 清理 Homebrew 旧版本文件..."
    brew cleanup
else
    echo "✅ Homebrew 所有包已是最新版本，无需更新"
fi

echo "=========================================="
# 3. 检查并逐个更新 npm 工具包
echo "🟢 [3/3] 检查并逐个更新 npm 工具包..."

# 检查 npm 权限
NPM_PREFIX=$(npm config get prefix 2>/dev/null)
if [ ! -w "$NPM_PREFIX" ]; then
    echo "⚠️  警告：可能没有 npm 全局包写入权限 ($NPM_PREFIX)"
    echo "💡 建议使用 sudo 运行此脚本"
fi

# 安全清理 .DS_Store 文件
if [ -d "$HOME/.npm-packages" ]; then
    # echo "🧹 清理 npm 包目录中的 .DS_Store 文件..."
    find "$HOME/.npm-packages" -name ".DS_Store" -type f -delete 2>/dev/null || true
fi

# 检查需要更新的 npm 工具包
echo "📋 检查需要更新的 npm 工具包..."
NPM_OUTDATED=$(npm outdated -g 2>/dev/null | awk 'NR>1 && NF>0 {print $1" "$2" → "$4}')

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
        if npm install -g "$PACKAGE_NAME@latest"; then
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

# 校验 npm 缓存（带错误处理）
echo "🧹 校验 npm 缓存完整性..."
if npm cache verify; then
    echo "✅ npm 缓存校验完成，缓存完整"
else
    echo "⚠️ npm 缓存校验出现问题，但不影响使用"
fi

echo "=========================================="
echo "✅ 软件更新完成！"
echo "=========================================="

# 保持终端打开
# exec $SHELL

# 等待3秒后关闭终端窗口
# sleep 3

# 关闭当前终端窗口
osascript -e 'tell application "Terminal" to close front window' & >/dev/null 2>&1