# iDict - macOS 快速翻译工具

一个轻量级的 macOS 菜单栏应用程序，提供快速文本翻译功能。通过全局热键 `Cmd + D` 即可快速翻译选中的英文文本为中文。

## ✨ 功能特性

- 🚀 **一键翻译** - 使用 `Cmd + D` 热键快速翻译选中的英文文本
- 🔄 **多翻译服务** - 支持 Google Translate 和腾讯云翻译，可在菜单栏中切换
- 📊 **服务状态检测** - 自动检测翻译服务可用性，智能提示服务状态
- 🎨 **无边框窗口** - 简洁美观的翻译结果显示界面，支持自定义样式
- 🖱️ **拖拽移动** - 可以自由移动翻译窗口到任意位置，提升用户体验
- 🎯 **智能焦点** - 点击或鼠标悬停时自动恢复窗口焦点，支持键盘操作
- ⌨️ **快捷键支持** - ESC 键和 Cmd+W 快速关闭翻译窗口
- 📏 **内容自适应** - 窗口大小根据翻译内容自动调整，最佳显示效果
- 🪟 **单窗口管理** - 智能管理翻译窗口，避免重复翻译时出现多个窗口
- 🔒 **隐私保护** - 本地处理剪贴板内容，不存储翻译历史
- 🛡️ **权限管理** - 智能检测和请求必要的系统权限
- 🌐 **高质量翻译** - 集成多个翻译服务API，提供高质量翻译结果
- 📝 **智能文本检测** - 自动检测英文文本，过滤非英文内容
- ⚠️ **服务迁移提醒** - 腾讯云翻译将于2025年4月15日停用，建议使用Google Translate

## 🖼️ 界面预览

翻译窗口采用无边框设计，支持拖拽移动，内容自适应大小，提供流畅的用户体验。

## 🚀 快速开始

### 安装要求

- macOS 10.15 或更高版本
- Xcode 命令行工具
- 翻译服务配置（根据使用的服务选择）：
  - Google Translate（推荐，使用公开接口，无需API密钥）
  - 腾讯云机器翻译（使用公开接口，将于2025年4月15日停用）

### 构建和安装

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd iDict
   ```

2. **翻译服务配置**
   
   本应用使用公开翻译接口，无需配置API密钥：
   
   **Google Translate（推荐）**：
   - 使用 Google 公开翻译接口
   - 无需API密钥配置
   - 支持自动语言检测
   
   **腾讯云翻译**：
   - 使用腾讯翻译君公开接口
   - 无需API密钥配置
   - 注意：该服务将于2025年4月15日停用

3. **构建并安装**
   ```bash
   make install
   ```

4. **运行应用**
   ```bash
   make run
   ```

### 使用说明

1. **首次运行** - 应用会请求以下权限：
   - 辅助功能权限（用于全局热键）
   - 输入监控权限（用于模拟复制操作）

2. **选择翻译服务**：
   - 点击菜单栏中的 iDict 图标
   - 在下拉菜单中选择翻译服务（Google Translate 或腾讯云翻译）
   - 系统会自动检测服务可用性并显示状态

3. **翻译文本**：
   - 选中要翻译的文本
   - 按下 `Cmd + D` 热键
   - 翻译结果会在浮动窗口中显示

4. **操作翻译窗口**：
   - 拖拽移动窗口
   - 按 ESC 或 Cmd+W 关闭窗口
   - 点击窗口恢复焦点

## 🔧 技术架构

### 核心技术栈

- **语言**: Swift 5.0+
- **UI 框架**: SwiftUI (菜单栏界面) + AppKit (窗口管理)
- **系统集成**: 
  - Carbon Framework (全局热键)
  - ApplicationServices (键盘事件模拟)
  - CommonCrypto (API 签名)
- **网络**: URLSession (HTTP 请求)
- **翻译服务**: 腾讯云机器翻译 API

### 权限要求

应用需要以下 macOS 系统权限：

1. **辅助功能权限** - 用于注册全局热键 `Cmd + D`
2. **输入监控权限** - 用于模拟 `Cmd + C` 复制操作

首次运行时，应用会自动引导用户授予这些权限。

### 工作流程

1. 用户选中文本并按下 `Cmd + D`
2. 应用模拟 `Cmd + C` 复制选中文本到剪贴板
3. 从剪贴板获取文本并验证是否为英文
4. 调用腾讯云翻译 API 进行英译中
5. 在无边框浮动窗口中显示翻译结果

## 🛠️ 开发

### 项目结构

```
iDict/
├── iDictApp.swift                    # 应用主入口，SwiftUI App 生命周期
├── AppDelegate.swift                 # 应用委托，核心业务逻辑和服务集成
├── MenuBarController.swift           # 菜单栏控制器，状态栏菜单管理和翻译功能
├── HotKeyManager.swift               # 全局热键管理，Carbon 框架集成
├── ClipboardManager.swift            # 剪贴板管理，文本验证和处理
├── TranslationServiceType.swift      # 翻译服务类型定义和管理器，错误处理
├── TranslationService_google.swift   # Google Translate 服务实现
├── TranslationService_Tencent.swift  # 腾讯云翻译服务实现
├── KeyboardSimulator.swift           # 键盘事件模拟，ApplicationServices 集成
├── Assets.xcassets/                  # 应用图标和资源文件
└── iDict.entitlements                # 应用权限配置文件
```

### 核心组件说明

- **iDictApp.swift** - 应用主入口，使用 SwiftUI App 生命周期
- **AppDelegate.swift** - 核心业务逻辑，集成翻译服务管理器，管理翻译窗口和热键
- **MenuBarController.swift** - 状态栏菜单控制器，管理菜单项、翻译功能和服务切换
- **TranslationServiceType.swift** - 翻译服务类型定义、管理器和统一错误处理
- **TranslationService_google.swift** - Google Translate API 集成和实现
- **TranslationService_Tencent.swift** - 腾讯云翻译 API 集成和实现
- **HotKeyManager.swift** - 全局热键注册和管理，使用 Carbon 框架
- **ClipboardManager.swift** - 剪贴板内容获取和文本验证
- **KeyboardSimulator.swift** - 模拟 Cmd+C 复制操作，需要输入监控权限

### 构建命令

```bash
# 查看所有可用命令
make help

# 构建 Release 版本
make release

# 构建并安装
make install

# 运行应用
make run

# 清理构建文件
make clean

# 卸载应用
make uninstall
```

### 技术栈

- **语言**: Swift
- **UI框架**: SwiftUI + AppKit
- **翻译API**: Google Translate + 腾讯翻译君（公开接口）
- **构建系统**: Make + xcodebuild
- **权限管理**: Carbon + ApplicationServices

## 📋 权限说明

应用需要以下 macOS 权限：

1. **辅助功能** - 用于注册全局热键
2. **输入监控** - 用于模拟键盘操作

这些权限在首次使用时由系统自动请求。

## 🔧 配置

### 翻译服务配置

本应用使用公开翻译接口，无需配置API密钥：

**Google Translate（推荐）**：
- 使用 Google 公开翻译接口
- 无需API密钥配置
- 支持自动语言检测

**腾讯云翻译**：
- 使用腾讯翻译君公开接口  
- 无需API密钥配置
- 注意：该服务将于2025年4月15日停用

### 热键配置

默认热键为 `Cmd + D`，可在 `HotKeyManager.swift` 中修改。

## 🐛 故障排除

### 常见问题

1. **热键不响应**
   - 检查是否授予了辅助功能权限
   - 确保没有其他应用占用相同热键

2. **翻译失败**
   - 检查网络连接
   - 确认选中的文本是否为有效的英文内容
   - 尝试切换到其他可用的翻译服务
   - 检查文本长度是否超过限制（最大5000字符）

3. **翻译服务不可用**
   - 腾讯云翻译将于2025年4月15日停用，建议切换到 Google Translate
   - 检查菜单栏中的服务状态提示
   - 确认网络连接正常，可以访问翻译服务

4. **窗口无法移动**
   - 确保点击窗口内容区域进行拖拽
   - 检查窗口是否有焦点

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 支持

如有问题，请提交 Issue 或联系开发者。

---

**注意**: 请确保在使用前授予必要的系统权限（辅助功能和输入监控），并保持网络连接正常。
