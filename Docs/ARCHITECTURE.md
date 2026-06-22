# iDict 架构文档

## 概述

iDict 是一个 macOS 菜单栏翻译工具。采用 SwiftUI 生命周期 + AppKit 混编架构。

- **语言**: Swift 6.2
- **最低系统**: macOS 15.0
- **UI 框架**: SwiftUI (壳) + AppKit (翻译窗口 / 菜单栏 / 热键)
- **网络层**: Network.framework (TCP) + URLSession (翻译请求)

---

## 分层架构

```
┌─────────────────────────────────────┐
│             入口层                    │
│  iDictApp.swift  →  AppDelegate      │
├─────────────────────────────────────┤
│             功能层                    │
│  ┌──────────┐                        │
│  │ 翻译子系统 │                        │
│  │          │                        │
│  │ HotKey   │                        │
│  │ Keyboard │                        │
│  │ Clipboard│                        │
│  │ Translate│                        │
│  │ Window   │                        │
│  └──────────┘                        │
├─────────────────────────────────────┤
│             共享层                    │
│  AppConfig  PermissionManager       │
│  WindowPositionCalculator            │
├─────────────────────────────────────┤
│             系统层                    │
│  Carbon    AppKit                    │
└─────────────────────────────────────┘
```

---

## 文件职责

### 入口层

| 文件 | 职责 | 大小 |
|------|------|------|
| `iDictApp.swift` | `@main` 入口，创建空窗口壳，通过 `NSApplicationDelegateAdaptor` 挂载 AppDelegate | ~1 KB |
| `AppDelegate.swift` | 核心协调器：启动时初始化菜单栏、热键；管理翻译窗口生命周期 | ~8 KB |

### 翻译子系统

| 文件 | 职责 |
|------|------|
| `HotKeyManager.swift` | Carbon Event API 注册 `Cmd+D` 全局热键；需辅助功能权限 |
| `KeyboardSimulator.swift` | 模拟 `Cmd+C` 复制、`Cmd+W` 关闭、`ESC` 按键 |
| `ClipboardManager.swift` | 从系统剪贴板获取文本，长度校验（≤5000 字符） |
| `translationservice.swift` | 翻译引擎：Google Translate（免费）/ OpenAI 兼容接口；配置持久化到 `~/.config/idict/config.json` |
| `BorderlessWindow.swift` | 无边框浮动窗口，支持拖拽移动、ESC 关闭 |
| `ClickableContentView.swift` | 窗口内容视图，处理点击穿透和拖拽事件 |
| `WindowPositionCalculator.swift` | 计算翻译窗口在鼠标附近的最佳位置，适配屏幕边界 |

### 共享层

| 文件 | 职责 |
|------|------|
| `AppConfig.swift` | 全局常量：窗口尺寸、颜色、时间配置 |
| `PermissionManager.swift` | 辅助功能权限检查和请求 |
| `MenuBarController.swift` | 状态栏图标、菜单、翻译服务切换、朗读命令 |

### 测试

| 文件 | 覆盖范围 |
|------|----------|
| `iDictTests.swift` | 集成测试入口 |
| `HotKeyManagerTests.swift` | 热键注册/注销 |
| `KeyboardSimulatorTests.swift` | 按键模拟 |
| `ClipboardManagerTests.swift` | 剪贴板读写 |
| `MenuBarControllerTests.swift` | 菜单栏行为 |
| `PermissionManagerTests.swift` | 权限检查 |
| `TranslationServiceTests.swift` | 翻译接口 |
| `WindowPositionCalculatorTests.swift` | 窗口位置计算 |

### 静态资源

| 文件 | 用途 |
|------|------|
| `Assets.xcassets` | 应用图标和颜色资源 |

---

## 核心数据流

### 翻译流程

```
用户选中文本 → 按 Cmd+D
  → HotKeyManager 捕获全局热键
  → AppDelegate.performQuickTranslation()
    → KeyboardSimulator.simulateCopyCommand()   // Cmd+C
    → 等待 50ms (copyDelay)
    → ClipboardManager.getClipboardText()
    → TranslationServiceManager.translateText()
      → GoogleTranslationService (默认)
      或 OpenAICompatibleTranslationService
    → AppDelegate.showMessage()
      → BorderlessWindow 在鼠标位置显示结果
      → 可选：朗读 (speechCommand)
```

---

## 翻译服务

### Google Translate（默认）

```
GET https://translate.googleapis.com/translate_a/single
  ?client=gtx&sl=en&tl=zh&dt=t&q=<urlencoded text>
```

响应为嵌套数组 `[[["译文","原文",...]]]`，取第一层所有首个元素拼接。

### OpenAI 兼容

```
POST <baseURL>/chat/completions
Authorization: Bearer <apiKey>
{
  "model": "<model>",
  "messages": [
    {"role": "developer", "content": "<systemPrompt>"},
    {"role": "user", "content": "<rendered userPromptTemplate>"}
  ]
}
```

`{{text}}` 占位符替换为待翻译文本。

### 配置存储

- 路径: `~/.config/idict/config.json`
- 首次启动自动创建默认配置
- 字段缺失时自动补齐（向后兼容）
- 保存时保持字段顺序：`provider` → `baseURL` → `apiKey` → `model` → `systemPrompt` → `userPromptTemplate` → `timeoutSeconds` → `speechEnabled` → `speechCommand`

## 构建与发布

### Makefile 命令

| 命令 | 说明 |
|------|------|
| `make debug` | 清理 → Debug 构建 → 自动启动 |
| `make install` | 清理 → Release 构建 → 安装到 /Applications |
| `make package` | 打包 Release .app 为 zip |
| `make push MSG="..."` | 版本号+1 → install → package → git commit & push → GitHub Release |

### 版本号规则

- `CFBundleShortVersionString`: `MAJOR.MINOR.PATCH`，patch 每次 push 自动 +1
- `CFBundleVersion`: 时间戳 `YYYYMMDDHHMMSS`

---

## 权限清单

| 权限 | 用途 | 触发场景 |
|------|------|----------|
| 辅助功能 (AX) | 全局热键注册 | 启动时提示授权 |
| 输入监控 | 键盘事件模拟 | macOS 要求 |

---

## 窗口设计

### 翻译窗口

- `BorderlessWindow` 子类
- 透明背景 + 圆角 + 阴影
- `level = .floating`（悬浮于所有窗口之上）
- `hidesOnDeactivate = true`（切换应用自动隐藏）
- 支持全屏应用内显示 (`canJoinAllSpaces`)
- 窗口复用：同一实例 setFrame 移动，避免重复创建
- 位置计算：鼠标右下 20px 偏移，适配屏幕边缘

