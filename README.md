# iDict - macOS 快速翻译工具

[![Version](https://img.shields.io/badge/version-v1.0.57-blue.svg)](https://github.com/xdfnet/iDict/releases)
[![macOS](https://img.shields.io/badge/macOS-13.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

一款轻量级的 macOS 菜单栏翻译工具，通过 `Cmd+D` 快速翻译选中的英文文本。支持多种翻译引擎，提供简洁流畅的翻译体验。

> 💡 **彩蛋功能**：内置媒体远程控制服务，可通过手机浏览器控制 Mac 的媒体播放、应用开关等。

## 📖 目录

- [功能特性](#-功能特性)
- [快速开始](#-快速开始)
- [使用说明](#-使用说明)
- [技术架构](#-技术架构)
- [开发指南](#-开发指南)
- [API 文档](#-api-文档)
- [故障排除](#-故障排除)
- [许可证](#-许可证)

## ✨ 核心功能

### 🌐 快速翻译
- **一键翻译** - `Cmd+D` 快速翻译选中的英文文本
- **多引擎支持** - 腾讯翻译、Google、Microsoft、DeepL 四种翻译服务可选
- **智能检测** - 自动检测服务状态，智能切换可用引擎
- **无边框窗口** - 简洁美观的翻译结果展示，支持拖拽移动
- **图形化配置** - 内置设置界面，一键配置 API 密钥

### 🎨 使用体验
- **快捷键支持** - `ESC` / `Cmd+W` 快速关闭翻译窗口
- **内容自适应** - 窗口大小随翻译内容自动调整
- **本地处理** - 不存储翻译历史，保护隐私
- **权限管理** - 智能请求必要的系统权限

### 🎁 彩蛋功能

<details>
<summary>📱 <b>媒体远程控制</b>（可选，点击展开）</summary>

通过内置的 HTTP 服务器，使用手机浏览器远程控制 Mac：

- **媒体控制** - 播放/暂停、上/下一曲、音量调节
- **应用管理** - 远程开关抖音、汽水音乐等应用
- **智能锁屏** - 自动登录功能，支持远程锁屏/解锁
- **移动友好** - 响应式 Web 界面，手机浏览器即可访问

</details>

## 🚀 快速开始

### 系统要求

- **macOS** 13.0 (Ventura) 或更高版本
- **Xcode** 15.0+ （开发需要）

### 安装方式

#### 方式一：下载发布版本（推荐）
1. 前往 [Releases](https://github.com/xdfnet/iDict/releases) 页面
2. 下载最新版本的 `iDict.app`
3. 拖动到 `应用程序` 文件夹
4. 首次打开可能需要在 `系统偏好设置 → 隐私与安全性` 中允许运行

#### 方式二：源码构建
```bash
# 克隆项目
git clone https://github.com/xdfnet/iDict.git
cd iDict

# 构建并运行
make debug
```

### 初始配置

1. **授予权限** - 首次运行时授予以下权限：
   - 辅助功能权限（全局热键）
   - 输入监控权限（复制操作）

2. **配置翻译服务**（可选）：
   - 点击菜单栏图标 → `Settings`
   - 输入腾讯云 API 密钥（SecretId 和 SecretKey）
   - 或使用其他免费翻译服务（Google、Microsoft、DeepL）

3. **启用远程控制**（可选）：
   - 点击菜单栏图标 → `启动媒体服务器`
   - 手机浏览器访问显示的 URL

## 📱 使用说明

### 基本使用

1. **选中文本** → 在任意应用中选中要翻译的英文文本
2. **按下快捷键** → `Cmd+D`
3. **查看结果** → 翻译结果自动弹出显示
4. **关闭窗口** → 按 `ESC` 或 `Cmd+W`

### 切换翻译服务

点击菜单栏图标，选择翻译服务：
- ✅ **腾讯翻译**（需配置 API 密钥，翻译质量高）
- ✅ **Google Translate**（免费，无需配置）
- ✅ **Microsoft Translator**（免费，无需配置）
- ✅ **DeepL 翻译**（免费，无需配置）

### 配置翻译服务

点击菜单栏 → `Settings`：

1. 输入腾讯云 SecretId 和 SecretKey（[获取地址](https://console.cloud.tencent.com/)）
2. 点击 `验证` 测试密钥有效性
3. 点击 `保存` 存储配置

> 💡 其他翻译服务无需配置，开箱即用

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd+D` | 翻译选中文本 |
| `ESC` / `Cmd+W` | 关闭翻译窗口 |

### 🎁 彩蛋：远程控制（可选）

<details>
<summary>点击查看使用方法</summary>

1. **启动服务器**
   - 点击菜单栏 → `启动媒体服务器`
   - 记录显示的访问地址（如 `http://192.168.100.202:8888`）

2. **手机访问**
   - 确保手机和 Mac 在同一 WiFi 网络
   - 用浏览器打开访问地址

3. **可用功能**
   - 🎵 媒体播放控制（播放/暂停、上/下一曲、音量）
   - 🔒 智能锁屏/登录（需在 Settings 中配置密码）
   - 📱 应用开关（抖音、汽水音乐）
   - ⌨️ 方向键控制

</details>



## 🏗️ 技术架构

### 技术栈

- **语言**: Swift 6.2+
- **最低系统**: macOS 13.0 (Ventura)
- **UI 框架**: SwiftUI + AppKit
- **异步编程**: async/await + Combine
- **系统集成**: Carbon (热键) + ApplicationServices (键盘事件)
- **网络**: URLSession + Network Framework
- **构建工具**: Xcode 15+ + Makefile

### 核心模块

```
iDict/
├── 核心应用
│   ├── iDictApp.swift              # SwiftUI App 入口
│   ├── AppDelegate.swift           # 应用生命周期管理
│   └── MenuBarController.swift     # 菜单栏控制
│
├── 翻译功能
│   ├── translationservice.swift    # 翻译服务实现
│   ├── ClipboardManager.swift      # 剪贴板管理
│   └── HotKeyManager.swift         # 全局热键
│
├── 远程控制
│   ├── iDictController.swift       # 媒体/应用/锁屏控制
│   ├── MediaHTTPServer             # HTTP 服务器
│   └── index.html                  # Web 控制界面
│
├── 设置管理
│   ├── SettingsManager.swift       # 配置管理
│   └── SettingsView.swift          # 设置界面
│
├── UI 组件
│   ├── BorderlessWindow.swift      # 无边框窗口
│   └── ClickableContentView.swift  # 可拖拽视图
│
└── 工具类
    ├── KeyboardSimulator.swift     # 键盘模拟
    └── AppError.swift              # 统一错误处理
```

### 工作流程

**翻译流程**：
1. 用户按下 `Cmd+D` → HotKeyManager 触发
2. KeyboardSimulator 模拟 `Cmd+C` 复制文本
3. ClipboardManager 获取剪贴板内容
4. TranslationService 调用翻译 API
5. BorderlessWindow 显示翻译结果

**远程控制流程**：
1. MediaHTTPServer 启动在端口 8888
2. 手机浏览器访问 `http://<IP>:8888`
3. 用户点击控制按钮
4. iDictController 执行对应操作

## 🛠️ 开发指南

### 环境准备

```bash
# 检查 Xcode 版本
xcodebuild -version  # 需要 15.0+

# 克隆项目
git clone https://github.com/xdfnet/iDict.git
cd iDict
```

### 开发命令

```bash
# 构建并运行 Debug 版本
make debug

# 完整发布流程（构建、安装、版本更新、推送）
make push MSG="提交信息"

# 查看所有可用命令
make help
```

### 代码规范

- **错误处理**：统一使用 `Result<T, Error>` 和 `async/await`
- **常量管理**：使用 `Constants` 枚举管理魔法数字
- **日志记录**：使用 `OSLog` 框架
- **命名规范**：遵循 Swift API 设计指南
- **注释规范**：使用 `///` 文档注释

### 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 🐛 故障排除

### 常见问题

#### 热键不响应
- ✅ 检查 `系统偏好设置 → 隐私与安全性 → 辅助功能` 中是否已授权 iDict
- ✅ 确认没有其他应用占用 `Cmd+D` 快捷键

#### 翻译失败
- ✅ 确认网络连接正常
- ✅ 检查选中的文本是否为有效英文（自动过滤中文）
- ✅ 尝试切换其他翻译服务
- ✅ 确认文本长度未超过 5000 字符

#### 远程控制无法访问
- ✅ 确认 Mac 和手机在同一 WiFi 网络
- ✅ 检查防火墙是否阻止端口 8888
- ✅ 尝试重启媒体服务器

#### 自动登录失败
- ✅ 确认已在设置中正确配置登录密码
- ✅ 检查是否开启了自动登录功能开关
- ✅ 确认已授予输入监控权限

### 获取帮助

如遇到其他问题，请在 [Issues](https://github.com/xdfnet/iDict/issues) 中反馈。

## 📚 API 文档

详细的 HTTP API 接口文档请参阅：[Docs/API.md](Docs/API.md)

**主要接口**：
- 🎵 媒体控制（播放/暂停、上/下一曲、音量）
- 🔒 锁屏和自动登录
- 📱 应用管理（抖音、汽水音乐开关）
- ⌨️ 方向键控制

**示例**：
```bash
# 播放/暂停
curl http://192.168.100.202:8888/api/playpause

# 锁屏或自动登录
curl http://192.168.100.202:8888/api/lockorlogin
```

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

<div align="center">

**⭐ 如果觉得有用，请给个 Star 支持一下！**

[提交问题](https://github.com/xdfnet/iDict/issues) · [功能建议](https://github.com/xdfnet/iDict/issues) · [贡献代码](https://github.com/xdfnet/iDict/pulls)

</div>
