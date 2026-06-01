# iDict 架构文档

## 概述

iDict 是一个 macOS 菜单栏翻译工具，附带远程媒体控制功能。采用 SwiftUI 生命周期 + AppKit 混编架构，单一进程内运行翻译引擎和 HTTP 服务器。

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
│  ┌──────────┐  ┌──────────────────┐  │
│  │ 翻译子系统 │  │  远程控制子系统     │  │
│  │          │  │                  │  │
│  │ HotKey   │  │ MediaHTTPServer  │  │
│  │ Keyboard │  │  ├── MediaController│ │
│  │ Clipboard│  │  └── MediaRemote   │  │
│  │ Translate│  │      Bridge        │  │
│  │ Window   │  │                  │  │
│  └──────────┘  └──────────────────┘  │
├─────────────────────────────────────┤
│             共享层                    │
│  AppConfig  PermissionManager       │
│  HTTPResponseHandler                 │
│  WindowPositionCalculator            │
├─────────────────────────────────────┤
│             系统层                    │
│  Carbon    Network    AppKit         │
│  MediaRemote (dlopen)  NSWorkspace  │
└─────────────────────────────────────┘
```

---

## 文件职责

### 入口层

| 文件 | 职责 | 大小 |
|------|------|------|
| `iDictApp.swift` | `@main` 入口，创建空窗口壳，通过 `NSApplicationDelegateAdaptor` 挂载 AppDelegate | ~1 KB |
| `AppDelegate.swift` | 核心协调器：启动时初始化菜单栏、热键、HTTP 服务器；管理翻译窗口生命周期 | ~8 KB |

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

### 远程控制子系统

| 文件 | 职责 |
|------|------|
| `iDictController.swift` | HTTP 服务器 (`NWListener`) + 媒体控制器 + 应用管理器 + 锁屏；包含 `MediaRemoteBridge` 动态桥接 |
| `HTTPResponseHandler.swift` | HTTP 响应构建器：JSON / HTML / 静态资源 / 错误响应 |

### 共享层

| 文件 | 职责 |
|------|------|
| `AppConfig.swift` | 全局常量：窗口尺寸、颜色、时间、端口、应用注册表、权限豁免列表 |
| `PermissionManager.swift` | 辅助功能权限检查和请求 |
| `MenuBarController.swift` | 状态栏图标、菜单、翻译服务切换、朗读命令 |

### 测试

| 文件 | 覆盖范围 |
|------|----------|
| `iDictTests.swift` | 集成测试入口 |
| `HotKeyManagerTests.swift` | 热键注册/注销 |
| `KeyboardSimulatorTests.swift` | 按键模拟 |
| `ClipboardManagerTests.swift` | 剪贴板读写 |
| `HTTPResponseHandlerTests.swift` | HTTP 响应构建 |
| `MediaControllerTests.swift` | 媒体控制逻辑 |
| `MenuBarControllerTests.swift` | 菜单栏行为 |
| `PermissionManagerTests.swift` | 权限检查 |
| `TranslationServiceTests.swift` | 翻译接口 |
| `WindowPositionCalculatorTests.swift` | 窗口位置计算 |

### 静态资源

| 文件 | 用途 |
|------|------|
| `index.html` | 远程控制 Web 页面（下拉刷新、播放控制、锁屏滑块、应用快捷方式） |
| `douyin.png` | 抖音应用图标 |
| `qishui.png` | 汽水音乐应用图标 |

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

### 远程控制流程

```
手机浏览器 → http://<mac-ip>:8888
  → MediaHTTPServer.processRequest()
    → handleAPI()
      → 检查权限 (noPermissionRequired 集合)
      → handleAPIAction() 分派
        ├── status    → MediaController.currentPlaybackState()
        ├── play      → MediaRemoteBridge.sendCommand(.play) → 追踪状态
        ├── pause     → MediaRemoteBridge.sendCommand(.pause) → 追踪状态
        ├── next/prev/volume/mute → CGEvent 模拟按键
        ├── lock      → CGEvent 模拟 Ctrl+Cmd+Q
        ├── toggle_*  → NSWorkspace 管理应用
        └── arrowup/down → CGEvent 方向键
```

### 媒体命令降级链

```
MediaController.play() / pause()
  │
  ├─ 无已知媒体 App 运行 → 跳过（避免唤醒 Apple Music）
  │
  ├─ Apple Music 在运行 → MediaRemoteBridge.sendCommand()
  │   └─ 成功 → 追踪状态 ✓
  │
  └─ 第三方 App（抖音/汽水音乐）在运行
      └─ simulateMediaKey(.playPause)
          → NSEvent.otherEvent + CGEvent.post
          → 状态标记为 unknown
```

---

## HTTP 服务器

### 技术细节

- 基于 `Network.framework` 的 `NWListener`，原生 TCP 无第三方依赖
- 默认端口 **8888**，最大请求体 65536 字节
- 请求解析：取 HTTP 首行 `GET /api/xxx HTTP/1.1` 中第二段为路径
- 响应：手工拼接 HTTP/1.1 响应头 + JSON/HTML/二进制 body
- 连接生命周期：接收 → 处理 → `connection.cancel()`

### 路由

```
/                        → index.html (Bundle)
/index.html              → index.html (Bundle)
/assets/*                → 静态文件 (png/svg/html)
/api/status              → JSON: 播放状态
/api/play                → JSON: 播放
/api/pause               → JSON: 暂停
/api/next                → JSON: 下一首
/api/prev                → JSON: 上一首
/api/volumeup            → JSON: 音量+
/api/volumedown          → JSON: 音量-
/api/mute                → JSON: 静音
/api/arrowup             → JSON: 方向上键
/api/arrowdown           → JSON: 方向下键
/api/lock                → JSON: 锁屏
/api/lock_status         → JSON: 锁屏状态
/api/toggle_douyin       → JSON: 抖音开关
/api/toggle_qishui       → JSON: 汽水音乐开关
/api/status_douyin       → JSON: 抖音状态
/api/status_qishui       → JSON: 汽水音乐状态
```

### 权限分级

**免权限**（`AppConfig.APIAction.noPermissionRequired`）：
`status` `lock_status` `status_douyin` `status_qishui`

**需辅助功能权限**：`play` `pause`（第三方 App 模式需权限，Apple Music 模式不需要）、其余所有端点

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

---

## MediaRemote 桥接

### 设计

通过 `dlopen` + `dlsym` 动态加载私有框架 `/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote`，避免：
- 编译期符号依赖（框架删除不会导致启动崩溃）
- App Store 审核问题（iDict 不走商店分发）

### API 映射

| 函数 | 用途 | 调用方式 |
|------|------|----------|
| `MRMediaRemoteSendCommand` | 发送播放/暂停/切歌命令 | 同步，立即返回 Bool |

### 状态追踪

由于 `MRMediaRemoteGetNowPlayingApplicationIsPlaying`（异步回调）在 macOS 26 beta 中 crash，当前方案：

- 使用 `OSAllocatedUnfairLock` 保护的自追踪状态
- 每次 `play()`/`pause()` 成功后更新
- `/api/status` 返回追踪值（`playing` / `paused` / `unknown`）
- 降级后状态重置为 `unknown`

---

## 应用管理

### 支持的应用

| 应用 | Bundle ID | 路径 |
|------|-----------|------|
| 抖音 | `com.bytedance.douyin.desktop` | `/Applications/抖音.app` |
| 汽水音乐 | `com.soda.music` | `/Applications/汽水音乐.app` |

### 启动流程

```
open <appPath>
  → 等待 2s (appLaunchWait)
  → 检查 NSWorkspace.runningApplications
  → 若未运行，再等 0.3s (appLaunchCheckInterval)
  → 二次检查
  → app.activate() 聚焦到前台
```

### 关闭流程

```
app.terminate()
  → 循环检测 (最多 10 次，每次间隔 0.5s)
  → 超时则 forceTerminate()
```

---

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
| 辅助功能 (AX) | 全局热键、CGEvent 按键模拟、应用管理 | 启动时提示授权 |
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

### 控制页面

- 单文件 HTML，无外部依赖
- 下拉刷新（`overscroll-behavior: none` + touch 事件）
- 播放图标跟随 `/api/status` 响应
- 锁屏滑块（左滑触发锁屏）
- Toast 反馈：播放/暂停/打开/关闭 标签化显示
