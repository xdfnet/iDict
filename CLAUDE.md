# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

iDict 是一个 macOS 菜单栏应用程序，提供快速文本翻译功能。通过全局热键 `Cmd + D` 即可快速翻译选中的英文文本为中文。应用支持 Google Translate、Microsoft Translator 和 DeepL 三种翻译服务。

## 核心开发命令

### 构建和运行
```bash
make debug          # 构建并运行 Debug 版本（开发首选）
make push MSG="提交信息"  # 构建、安装、更新版本并推送到Git（发布流程）
make help           # 显示所有可用命令
```

### 快速开发
```bash
# 开发调试流程
make debug

# 完整发布流程（包含版本更新）
make push MSG="功能描述"
```

## 项目架构

### 技术栈
- **语言**: Swift 6.2+
- **UI框架**: SwiftUI + AppKit 混合架构
- **响应式编程**: Combine Framework
- **系统集成**: Carbon Framework（全局热键） + ApplicationServices（键盘事件）
- **网络**: URLSession
- **构建工具**: Xcode + Makefile

### 核心组件架构

#### 应用入口层
- `iDictApp.swift`: SwiftUI App 主入口，配置应用为菜单栏附件类型

#### 核心业务层
- `AppDelegate.swift`: 应用主代理，协调所有服务和UI组件，管理热键、翻译流程和窗口生命周期
- `MenuBarController.swift`: 菜单栏控制器，管理状态栏菜单和翻译服务切换
- `HotKeyManager.swift`: 全局热键管理器，使用 Carbon Framework 注册 `Cmd + D` 热键
- `ClipboardManager.swift`: 剪贴板管理器，获取和验证剪贴板文本内容
- `translationervice.swift`: 翻译服务管理器，实现三种翻译服务（Google、Microsoft、DeepL）

#### UI交互层
- `BorderlessWindow.swift`: 无边框浮动窗口实现，用于显示翻译结果
- `ClickableContentView.swift`: 可点击内容视图，支持窗口拖拽和焦点管理
- `KeyboardSimulator.swift`: 键盘事件模拟器，模拟 `Cmd + C` 复制操作

### 工作流程
1. 用户按下 `Cmd + D` 热键
2. `HotKeyManager` 捕获热键事件并调用 `AppDelegate`
3. `KeyboardSimulator` 模拟 `Cmd + C` 复制选中文本
4. `ClipboardManager` 获取剪贴板文本并验证是否为英文
5. `TranslationServiceManager` 调用选定的翻译服务API
6. `BorderlessWindow` 显示翻译结果在无边框浮动窗口中

## 关键技术实现

### 权限管理
应用需要以下系统权限：
- **辅助功能权限**: 用于全局热键 `Cmd + D`
- **输入监控权限**: 用于模拟复制操作 `Cmd + C`

### 翻译服务架构
采用策略模式，通过 `TranslationServiceManager` 统一管理三种翻译服务：
- Google Translate API（推荐，速度快，质量高）
- Microsoft Translator（技术文档翻译优秀）
- DeepL（语义理解准确）

### 窗口管理
- 单窗口模式，避免重复翻译时出现多个窗口
- 无边框窗口支持拖拽移动
- 智能焦点管理，点击或鼠标悬停时自动恢复焦点

## 开发注意事项

### 版本管理
- 版本信息存储在 `Info.plist` 和 Xcode 项目文件中
- 使用 `make push` 命令会自动更新版本号（PATCH 版本递增）
- README.md 中的版本徽章会自动同步更新

### 构建优化
- Makefile 自动清理构建文件和缓存
- 支持开发和发布两种构建配置
- 自动安装到 `/Applications` 目录

### 错误处理
- 热键注册失败时会显示具体的错误信息
- 翻译服务不可用时会智能提示并建议切换服务
- 网络请求有超时和错误处理机制

### 性能考虑
- 使用 `@MainActor` 确保UI操作在主线程执行
- 异步处理翻译流程，避免阻塞用户界面
- 智能的剪贴板文本验证，过滤非英文内容