# iDict - macOS 快速翻译工具

[![Version](https://img.shields.io/badge/version-v1.0.52-blue.svg)](https://github.com/xdfnet/iDict/releases)
[![macOS](https://img.shields.io/badge/macOS-13.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)

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
- 🔄 **多翻译服务** - 支持 腾讯翻译、Google Translate、Microsoft Translator 和 DeepL 翻译，可在菜单栏中切换
- 📊 **服务状态检测** - 自动检测翻译服务可用性，智能提示服务状态
- 🎮 **媒体远程控制** - 内置 HTTP 服务器，通过手机浏览器远程控制 Mac 的媒体播放和音量。界面经过精心设计，提供美观易用的移动端体验。

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
   - 在下拉菜单中选择翻译服务（腾讯翻译、Google Translate、Microsoft Translator 或 DeepL 翻译）
   - 系统会自动检测服务可用性并显示状态

2. **翻译文本**
   - 选中要翻译的文本
   - 按下 `Cmd + D` 热键
   - 翻译结果会在浮动窗口中显示

3. **操作翻译窗口**
   - 拖拽移动窗口
   - 按 ESC 或 Cmd+W 关闭窗口
   - 点击窗口恢复焦点

4. **媒体远程控制**
   - 点击菜单栏图标，选择"启动媒体服务器"
   - 使用手机浏览器访问显示的 URL（如 `http://192.168.100.202:8888`）
   - 在手机上控制 Mac 的媒体播放、音量和方向键

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd + D` | 翻译选中文本 |
| `ESC` | 关闭翻译窗口 |
| `Cmd + W` | 关闭翻译窗口 |

### 媒体控制功能

远程控制界面提供以下功能：

| 控制 | 功能 |
|------|------|
| ⏮️ 上一曲 | 切换到上一首歌曲 |
| ⏭️ 下一曲 | 切换到下一首歌曲 |
| ▶️ 播放/暂停 | 播放或暂停当前媒体 |
| ⬆️ 向上 | 模拟键盘向上方向键 |
| ⬇️ 向下 | 模拟键盘向下方向键 |
| 🔉 音量减 | 降低系统音量 |
| 🔇 静音 | 切换静音状态 |
| 🔊 音量加 | 提高系统音量 |
| 🔒 锁屏 | 锁定屏幕（Control + Command + Q） |

### 设置界面

应用提供了图形化的设置界面，方便配置腾讯翻译API密钥：

- **访问方式**：点击菜单栏图标 → 选择 "Settings"
- **功能特性**：
  - 安全的API密钥输入和存储
  - 实时验证API密钥有效性
  - 一键清除配置功能
  - 直观的状态反馈

- **配置步骤**：
  1. 在设置界面输入腾讯云 SecretId 和 SecretKey
  2. 点击"保存"按钮存储配置
  3. 使用"验证"按钮测试API密钥是否有效
  4. 如需重置，可点击"清除"按钮删除所有配置

## 🔧 翻译服务配置

本应用支持多种翻译服务，其中腾讯翻译需要配置API密钥，其他服务使用公开接口。

### 腾讯翻译（默认，推荐）

腾讯翻译提供高质量的中文翻译结果，是本应用的默认翻译服务。

#### 获取API密钥

1. 访问 [腾讯云控制台](https://console.cloud.tencent.com/)
2. 登录你的腾讯云账号
3. 进入"访问管理 > API密钥管理"
4. 创建新的API密钥或使用现有密钥
5. 记录你的SecretId和SecretKey

#### 配置环境变量

在终端中编辑你的shell配置文件（如.zshrc）：

```bash
# 打开.zshrc文件
open ~/.zshrc

# 添加以下两行到文件末尾
export SecretId=你的SecretId
export SecretKey=你的SecretKey

# 保存文件后，重新加载配置
source ~/.zshrc
```

#### 验证配置

确保环境变量已正确设置：

```bash
echo $SecretId
echo $SecretKey
```

#### 注意事项

- 请妥善保管你的API密钥，不要泄露给他人
- 腾讯云翻译服务有免费额度，超出后会产生费用
- 如果遇到API调用失败，请检查环境变量是否正确设置、网络是否正常
- 使用环境变量是更安全的配置方式，避免将敏感信息硬编码在代码中

### Google Translate

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

- **语言**: Swift 5.9+
- **系统要求**: macOS 13.0 (Ventura) 或更高版本
- **UI框架**: SwiftUI + AppKit
- **响应式编程**: Combine Framework
- **系统集成**: Carbon Framework (全局热键) + ApplicationServices (键盘事件)
- **网络**: URLSession + Network Framework (HTTP服务器)
- **翻译API**: 腾讯翻译API + Google Translate API + Microsoft Translator API + DeepL API (通过MyMemory代理)
- **构建工具**: Xcode + Makefile

### 核心组件

| 组件 | 功能 |
|------|------|
| `iDictApp.swift` | 应用主入口，SwiftUI App 生命周期 |
| `AppDelegate.swift` | 核心业务逻辑，服务集成和翻译窗口管理 |
| `MenuBarController.swift` | 状态栏菜单管理和翻译功能 |
| `HotKeyManager.swift` | 全局热键注册和管理 |
| `ClipboardManager.swift` | 剪贴板内容获取和文本验证 |
| `translationservice.swift` | 翻译服务类型定义和四种翻译服务实现（腾讯、Google、Microsoft、DeepL） |
| `MediaController.swift` | 媒体控制和 HTTP 服务器，支持远程控制媒体播放、音量和方向键 |
| `SettingsView.swift` | SwiftUI 设置界面，提供API密钥配置和管理功能 |
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
│   ├── MediaController.swift         # 媒体控制和 HTTP 服务器
│   ├── SettingsView.swift            # SwiftUI 设置界面
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

## 🎨 图标设计规范

### 基本形状与设计风格

- **形状**：圆角矩形形状（squircle）
- **视角**：正面透视视角
- **位置**：水平位置
- **阴影效果**：统一的阴影效果，确保系统中的视觉一致性
- **不透明度**：图标应完全不透明，避免使用透明背景

### 尺寸规范（必须提供所有尺寸）

| 尺寸 | 用途 |
|------|------|
| 16×16 | Finder、菜单栏等小尺寸显示 |
| 32×32 | Finder、文件信息等 |
| 64×64 | 32×32 的 @2x 版本（Retina 显示屏） |
| 128×128 | Finder 图标视图等 |
| 256×256 | 各种中等尺寸显示 |
| 512×512 | Dock、大图标视图等 |
| 1024×1024 | 512×512 的 @2x 版本（Retina 显示屏） |

### 设计注意事项

- **避免使用照片**：小尺寸下照片细节难以辨认
- **避免使用屏幕截图**：可能导致图标过于复杂
- **避免使用界面元素**：影响图标的识别度
- **简洁背景**：使用简单的背景，避免影响附近的其他应用图标
- **测试不同背景**：在不同壁纸和背景下测试图标可见性

### macOS Big Sur 及以后的设计风格

- **统一外观**：强调统一的外观轮廓和精致的细节
- **一致性**：与系统其他图标保持视觉一致性
- **正面透视**：采用正面透视视角
- **阴影效果**：加入一致的阴影效果

### 在 Xcode 中实现

- **Asset Catalog**：使用 Xcode 的 Asset Catalog 添加应用图标
- **AppIcon 集合**：在 Assets.xcassets 中创建 AppIcon 图标集
- **文件格式**：提供 PNG 格式的各尺寸图标
- **自动生成**：Xcode 会自动生成 .icns 文件

### 图标文件格式

- **最终格式**：macOS 应用图标最终使用 .icns 格式
- **包含内容**：一个 .icns 文件包含多种尺寸的图标
- **生成方式**：通过 Xcode 的 Asset Catalog 自动生成

## 📞 支持

如有问题，请提交 Issue 或联系开发者。

---

**注意**: 请确保在使用前授予必要的系统权限，并保持网络连接正常。
