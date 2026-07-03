# Opt+Z 在当前 Finder 目录打开终端

## 目标

在 iDict 中集成 Opt+Z 全局快捷键，一键在 Finder 当前目录打开 Terminal。

## 设计原则

- 最小改动 — 不引入新依赖，复用 iDict 现有的 Carbon 热键机制
- 核心逻辑 ~80 行，AppleScript 一把梭，不重蹈 OpenInTerminal 的 ScriptingBridge 复杂度

## 改动清单

### 1. `HotKeyManager.swift` — 扩展为多热键支持

当前状态：只支持单个热键（Cmd+D），`HotKeyConfig` 写死在 `defaultConfig`，`registerHotKey` 无参数。

重构为：

```swift
// 每个热键通过 ID 区分
private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]

// 参数化注册
func registerHotKey(
    config: HotKeyConfig,
    handler: @escaping () -> Void
) async -> Result<Void, HotKeyError>
```

- 事件回调统一入口，根据 `hotKeyID.id` 分发到对应 handler
- 兼容现有 Cmd+D 调用，只改内部实现不改接口签名（接口向后兼容）
- 新增 `unregisterHotKey(id: UInt32)` 支持注销单个热键

### 2. 新增 `FinderTerminalService.swift`

三个方法，逐步组合：

```swift
@MainActor
class FinderTerminalService {

    static let shared = FinderTerminalService()
    private init() {}

    /// 获取 Finder 当前窗口路径（选中文件夹 / 当前窗口 / 桌面）
    func getCurrentFinderPath() -> String?

    /// 在 Terminal 中 cd 到目标路径
    func openTerminal(at path: String)

    /// 一键操作：Finder 当前目录 → Terminal
    func openTerminalAtCurrentFinderLocation()
}
```

**AppleScript 实现：**

```applescript
-- 获取 Finder 路径
tell application "Finder"
    set sel to selection as alias list
    if sel ≠ {} then
        -- 选中了文件或文件夹
        set p to POSIX path of (item 1 of sel)
        -- 如果是文件，取父目录
    else
        -- 没选中，取当前 Finder 窗口
        try
            set p to POSIX path of ((target of front Finder window) as text)
        on error
            -- 没 Finder 窗口，回退到桌面
            set p to POSIX path of (path to desktop folder)
        end try
    end if
end tell

-- 在 Terminal 中 cd
tell application "Terminal"
    activate
    do script "cd " & quoted form of p
end tell
```

不需要 ScriptingBridge，不需要 `open -a Terminal`，干净利落。

### 3. `AppDelegate.swift` — 注册 Opt+Z 热键

在 `applicationDidFinishLaunching` 内，Cmd+D 注册之后追加：

```swift
// 注册 Opt+Z 在当前 Finder 目录打开终端
let terminalHKConfig = HotKeyConfig(
    keyCode: UInt32(kVK_ANSI_Z),
    modifiers: UInt32(optionKey),
    signature: 0x49444954,  // "iDiT"
    id: 2
)
_ = await hotKeyManager.registerHotKey(config: terminalHKConfig) { [weak self] in
    FinderTerminalService.shared.openTerminalAtCurrentFinderLocation()
}
```

### 4. `iDict.entitlements` — 新增 Apple Events 权限

```xml
<key>com.apple.security.temporary-exception.apple-events</key>
<array>
    <string>com.apple.systemevents</string>
    <string>com.apple.Terminal</string>   ← 新增此行
</array>
```

## 边界情况处理

| 场景 | 行为 |
|---|---|
| 有 Finder 窗口但无选中 | 取 Finder 当前窗口目录 |
| 选中了文件 | 取文件所在父目录 |
| 选中了文件夹 | 直接 cd 到该文件夹 |
| 多选（多个文件/文件夹） | 取第一个选中项 |
| 无 Finder 窗口 | 回退到 `~/Desktop` |
| Terminal.app 未运行 | 自动启动 |

## 代码量估算

| 文件 | 操作 | 变更 |
|---|---|---|
| `HotKeyManager.swift` | 重构为多热键 | +30 / -15 行 |
| `FinderTerminalService.swift` | 新建 | ~60 行 |
| `AppDelegate.swift` | 追加 Opt+Z 注册 | +5 行 |
| `iDict.entitlements` | 加 Terminal 条目 | +1 行 |
| **总计** | | **~80 行净增** |

## 后续可扩展

- 支持 iTerm2 / Alacritty / Warp 等其它终端（改 AppleScript 的 app name）
- 在菜单栏显示当前热键状态
- 可配置快捷键（等有人需要再加）
