# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

iDict 是一个 macOS 快速翻译工具，使用 Swift 和 SwiftUI 开发。它是一个菜单栏应用程序，提供全局热键翻译功能，支持多种翻译服务（腾讯、Google、Microsoft、DeepL）。

## 构建和开发命令

使用 Makefile 进行构建和开发：

```bash
# 查看所有可用命令
make help

# 开发调试 - 构建 Debug 版本并运行
make debug

# 完整发布流程 - 构建、安装、更新版本并推送到 Git
make push MSG="提交信息"
```

注意：推送命令需要提供提交信息参数。

## 核心架构

### 应用结构
- **SwiftUI App 生命周期**: [`iDictApp.swift`](iDict/iDictApp.swift) - 应用入口点
- **AppDelegate**: [`AppDelegate.swift`](iDict/AppDelegate.swift) - 核心业务逻辑协调器
- **菜单栏控制器**: [`MenuBarController.swift`](iDict/MenuBarController.swift) - 状态栏菜单和用户交互

### 关键组件

#### 翻译服务
- **翻译服务管理器**: [`translationservice.swift`](iDict/translationservice.swift) - 统一的翻译服务接口
- 支持四种翻译服务：Tencent、Google、Microsoft、DeepL
- Tencent 需要配置 API 密钥，其他服务使用公开接口

#### 系统集成
- **全局热键**: [`HotKeyManager.swift`](iDict/HotKeyManager.swift) - Cmd+D 热键注册和处理
- **剪贴板管理**: [`ClipboardManager.swift`](iDict/ClipboardManager.swift) - 剪贴板文本获取和验证
- **键盘模拟**: [`KeyboardSimulator.swift`](iDict/KeyboardSimulator.swift) - 模拟 Cmd+C 复制操作

#### UI 组件
- **无边框窗口**: [`BorderlessWindow.swift`](iDict/BorderlessWindow.swift) - 翻译结果显示窗口
- **交互视图**: [`ClickableContentView.swift`](iDict/ClickableContentView.swift) - 支持拖拽和点击的窗口内容
- **设置界面**: [`SettingsView.swift`](iDict/SettingsView.swift) - SwiftUI 设置界面

#### 媒体控制
- **HTTP 服务器**: [`iDictController.swift`](iDict/iDictController.swift) - 远程媒体控制服务器和应用管理
- **常量配置**: 使用 `Constants` 枚举统一管理时间常量和重试次数
  - `appTerminateWait`: 0.5秒 - 应用终止检测间隔
  - `appLaunchWait`: 2秒 - 应用启动等待时间
  - `appLaunchCheckInterval`: 0.3秒 - 应用启动二次检测间隔
  - `appTerminateAttempts`: 10次 - 应用终止最大重试次数

### 工作流程

1. 用户按下 `Cmd+D` 热键
2. `HotKeyManager` 触发翻译流程
3. `KeyboardSimulator` 模拟 `Cmd+C` 复制选中文本
4. `ClipboardManager` 从剪贴板获取文本
5. `TranslationServiceManager` 调用当前选中的翻译服务
6. 翻译结果通过 `BorderlessWindow` 在鼠标位置显示

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 命令行工具
- Swift 5.9+

## 权限配置

应用需要以下系统权限：
- **辅助功能权限** - 全局热键功能
- **输入监控权限** - 键盘事件模拟

## 配置文件

- **项目配置**: [`Info.plist`](iDict/Info.plist) - 应用信息和权限配置
- **权限配置**: [`iDict.entitlements`](iDict/iDict.entitlements) - 系统权限声明
- **构建配置**: [`Makefile`](Makefile) - 构建和发布脚本

## API 密钥配置

腾讯翻译服务需要配置API密钥：
1. 在设置界面中配置 SecretId 和 SecretKey
2. 密钥通过 UserDefaults 存储
3. 其他翻译服务无需配置

## 应用管理功能

支持远程控制应用开关：
- **抖音应用**: Bundle ID `com.bytedance.douyin.desktop`
- **汽水音乐**: Bundle ID `com.soda.music`
- 通过 `/api/toggle_douyin` 和 `/api/toggle_qishui` 控制

### 应用管理流程

**打开应用**：
1. 执行 `open` 命令启动应用
2. 等待 2秒检测应用是否运行
3. 如果未启动，再等待 0.3秒进行二次检测
4. 激活应用到前台

**关闭应用**：
1. 调用 `terminate()` 正常终止
2. 每隔 0.5秒检测一次，最多 10次（总计5秒）
3. 如果超时，调用 `forceTerminate()` 强制关闭

## 注意事项

- 应用采用 `LSUIElement = true`，不在 Dock 中显示图标
- 翻译窗口支持拖拽移动，会自动适应屏幕边界
- 媒体控制服务器默认在端口 8888 运行
- 所有翻译操作都在主线程中执行UI更新
- 窗口复用机制避免重复创建翻译窗口
- 应用开关功能支持中英文应用名，自动识别并映射到正确的应用路径
- 锁屏功能仅支持在未锁屏状态下执行，软件无法唤醒息屏