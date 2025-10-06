# iDict - macOS 快速翻译工具

[![Version](https://img.shields.io/badge/version-v1.0.35-blue.svg)](https://github.com/xdfnet/iDict/releases)
[![macOS](https://img.shields.io/badge/macOS-13.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org/)

一个轻量级的 macOS 菜单栏应用程序，提供快速文本翻译功能。通过全局热键 `Cmd + D` 即可快速翻译选中的英文文本为中文。

## 📖 目录

- [功能特性](#-功能特性)
- [界面预览](#-界面预览)
- [快速开始](#-快速开始)
- [使用说明](#-使用说明)
- [翻译服务配置](#-翻译服务配置)
- [技术架构](#-技术架构)
- [开发指南](#-开发指南)
- [故障排除](#-故障排除)
- [许可证](#-许可证)

## ✨ 功能特性

### 核心功能
- 🚀 **一键翻译** - 使用 `Cmd + D` 热键快速翻译选中的英文文本
- 🔄 **多翻译服务** - 支持 Google Translate、Microsoft Translator 和 DeepL 翻译，可在菜单栏中切换
- 📊 **服务状态检测** - 自动检测翻译服务可用性，智能提示服务状态

### 界面体验
- 🎨 **无边框窗口** - 简洁美观的翻译结果显示界面
- 🖱️ **拖拽移动** - 可以自由移动翻译窗口到任意位置
- 🎯 **智能焦点** - 点击或鼠标悬停时自动恢复窗口焦点
- ⌨️ **快捷键支持** - ESC 键和 Cmd+W 快速关闭翻译窗口
- 📏 **内容自适应** - 窗口大小根据翻译内容自动调整

### 安全隐私
- 🔒 **隐私保护** - 本地处理剪贴板内容，不存储翻译历史
- 🛡️ **权限管理** - 智能检测和请求必要的系统权限
- 🪟 **单窗口管理** - 智能管理翻译窗口，避免重复翻译时出现多个窗口

### 智能特性
- 🌐 **高质量翻译** - 集成多个翻译服务API，提供高质量翻译结果
- 📝 **智能文本检测** - 自动检测英文文本，过滤非英文内容
- ⚡ **服务稳定性** - 使用稳定可靠的免费翻译API，确保长期可用性

## 🖼️ 界面预览

翻译窗口采用无边框设计，支持拖拽移动，内容自适应大小，提供流畅的用户体验。

## 🚀 快速开始

### 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 命令行工具

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd iDict
   ```

2. **构建并运行**
   ```bash
   make debug
   ```

### 开发命令

项目提供了简化的 Makefile 构建系统，支持开发和发布的核心流程：

#### 核心命令
```bash
make debug          # 构建并运行 Debug 版本
make push MSG="提交信息"  # 构建、安装、更新版本并推送到Git
make help           # 显示所有可用命令
```

#### 使用示例
```bash
make debug                    # 开发调试
make push MSG="修复翻译bug"    # 完整发布流程
```

### 权限配置

首次运行时，应用会请求以下权限：
- **辅助功能权限** - 用于全局热键 `Cmd + D`
- **输入监控权限** - 用于模拟复制操作 `Cmd + C`

## 📱 使用说明

### 基本操作

1. **选择翻译服务**
   - 点击菜单栏中的 iDict 图标
   - 在下拉菜单中选择翻译服务（Google Translate、Microsoft Translator 或 DeepL 翻译）
   - 系统会自动检测服务可用性并显示状态

2. **翻译文本**
   - 选中要翻译的文本
   - 按下 `Cmd + D` 热键
   - 翻译结果会在浮动窗口中显示

3. **操作翻译窗口**
   - 拖拽移动窗口
   - 按 ESC 或 Cmd+W 关闭窗口
   - 点击窗口恢复焦点

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd + D` | 翻译选中文本 |
| `ESC` | 关闭翻译窗口 |
| `Cmd + W` | 关闭翻译窗口 |

## 🔧 翻译服务配置

本应用使用公开翻译接口，无需配置API密钥。

### Google Translate（推荐）

- **API地址**: `https://translate.googleapis.com/translate_a/single`
- **请求方法**: GET
- **参数说明**:
  - `client=gtx` - 客户端类型
  - `sl=en` - 源语言（英文）
  - `tl=zh` - 目标语言（中文）
  - `dt=t` - 数据类型
  - `q={text}` - 待翻译文本（URL编码）

**示例URL**:
```
https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=zh&dt=t&q=hello
```

**特点**:
- 无需API密钥
- 支持自动语言检测
- 响应速度快，翻译质量高

### Microsoft Translator

- **API地址**: `https://api.mymemory.translated.net/get`
- **请求方法**: GET
- **参数说明**:
  - `q={text}` - 待翻译文本（URL编码）
  - `langpair=en|zh-CN` - 语言对（英文到简体中文）
  - `de=microsoft@mymemory.translated.net` - 指定使用Microsoft引擎

**示例URL**:
```
https://api.mymemory.translated.net/get?q=hello&langpair=en|zh-CN&de=microsoft@mymemory.translated.net
```

**特点**:
- 基于Microsoft Translator引擎
- 无需API密钥配置
- 企业级翻译质量，支持多种语言
- 在技术文档翻译方面表现优秀

### DeepL 翻译

- **API地址**: `https://api.mymemory.translated.net/get`
- **请求方法**: GET
- **参数说明**:
  - `q={text}` - 待翻译文本（URL编码）
  - `langpair=en|zh-CN` - 语言对（英文到简体中文）
  - `de=deepl@mymemory.translated.net` - 指定使用DeepL引擎

**示例URL**:
```
https://api.mymemory.translated.net/get?q=hello&langpair=en|zh-CN&de=deepl@mymemory.translated.net
```

**特点**:
- 基于DeepL高质量翻译引擎
- 无需API密钥配置
- 翻译质量优秀，语义理解准确

## 🏗️ 技术架构

### 技术栈

- **语言**: Swift 6.2+
- **系统要求**: macOS 13.0 (Ventura) 或更高版本
- **UI框架**: SwiftUI + AppKit
- **响应式编程**: Combine Framework
- **系统集成**: Carbon Framework (全局热键) + ApplicationServices (键盘事件)
- **网络**: URLSession
- **翻译API**: Google Translate API + Microsoft Translator API + DeepL API (通过MyMemory代理)
- **构建工具**: Xcode + Makefile

### 核心组件

| 组件 | 功能 |
|------|------|
| `iDictApp.swift` | 应用主入口，SwiftUI App 生命周期 |
| `AppDelegate.swift` | 核心业务逻辑，服务集成和翻译窗口管理 |
| `MenuBarController.swift` | 状态栏菜单管理和翻译功能 |
| `HotKeyManager.swift` | 全局热键注册和管理 |
| `ClipboardManager.swift` | 剪贴板内容获取和文本验证 |
| `translationservice.swift` | 翻译服务类型定义和三种翻译服务实现 |
| `BorderlessWindow.swift` | 无边框窗口实现 |
| `ClickableContentView.swift` | 窗口交互处理和拖拽支持 |
| `KeyboardSimulator.swift` | 键盘事件模拟器 |

### 工作流程

1. 用户选中文本并按下 `Cmd + D`
2. 应用模拟 `Cmd + C` 复制选中文本到剪贴板
3. 从剪贴板获取文本并验证是否为英文
4. 调用选定的翻译服务API进行英译中
5. 在无边框浮动窗口中显示翻译结果

## 🛠️ 开发指南

### 项目结构

```
iDict/
├── iDict.xcodeproj/                  # Xcode 项目文件
├── iDict/                            # 源代码目录
│   ├── iDictApp.swift                # 应用主入口
│   ├── AppDelegate.swift             # 应用委托，核心业务逻辑
│   ├── MenuBarController.swift       # 菜单栏控制器
│   ├── HotKeyManager.swift           # 全局热键管理
│   ├── ClipboardManager.swift        # 剪贴板管理
│   ├── translationservice.swift     # 翻译服务（Google、Microsoft、DeepL）
│   ├── BorderlessWindow.swift        # 无边框窗口实现
│   ├── ClickableContentView.swift    # 可点击内容视图
│   ├── KeyboardSimulator.swift       # 键盘事件模拟
│   ├── Assets.xcassets/              # 应用图标和资源文件
│   ├── Info.plist                    # 应用配置信息
│   └── iDict.entitlements            # 应用权限配置文件
├── Makefile                          # 构建脚本
└── README.md                         # 项目文档
```

### 构建命令

```bash
# 查看所有可用命令
make help

# 构建并运行 Debug 版本
make debug

# 构建、安装、更新版本并推送到Git
make push MSG="提交信息"
```

## 🐛 故障排除

### 常见问题

**热键不响应**
- 检查是否授予了辅助功能权限
- 确保没有其他应用占用相同热键

**翻译失败**
- 检查网络连接
- 确认选中的文本是否为有效的英文内容
- 尝试切换到其他可用的翻译服务
- 检查文本长度是否超过限制（最大5000字符）

**翻译服务不可用**
- 尝试切换到其他可用的翻译服务
- 检查菜单栏中的服务状态提示
- 确认网络连接正常

**窗口无法移动**
- 确保点击窗口内容区域进行拖拽
- 检查窗口是否有焦点

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 支持

如有问题，请提交 Issue 或联系开发者。

---

**注意**: 请确保在使用前授予必要的系统权限，并保持网络连接正常。
