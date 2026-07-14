# AppleScript 控制 Terminal.app：launch vs activate vs do script

> 记录 iDict 集成 `Opt+Z` 一键开终端时，在 AppleScript 控制 Terminal.app 上的踩坑经验。

## 三个命令的本质区别

| 命令 | 作用 | 是否抢前台 | 是否开新窗 |
|------|------|----------|----------|
| `launch` | 启动进程（如果没运行） | ❌ | 不会自己开 |
| `activate` | 启动 + 把窗口拉到最前 | ✅ | 不会自己开 |
| `do script` | 在 Terminal 里执行一段命令 | ✅（隐式） | ⚠️ 首次启动会触发「恢复上次窗口」 |

## 一句话总结

> `do script` 自己会激活 Terminal。
> - 前置加 `activate` → 触发双窗口 Bug（多 1 个默认空白窗）
> - 前置加 `launch` → 不会双窗，但 Terminal 不抢前台，窗可能藏在其他 App 后
> - 仅 `do script` → 1 个窗，行为最干净（隐式激活已够用）

## 现象对照（实测）

| AppleScript 写法 | 首次按 Opt+Z 结果 | 后续按 |
|----------------|----------------|--------|
| `launch` + `do script` | 1 个窗（不抢前台，窗在当前 App 下面） | 1 个 |
| `activate` + `do script` | 2 个窗（默认空白 + 命令窗，都抢到前台） | 1 个 |
| **仅 `do script`** | 1 个（理想） | 1 个 |

> 「双窗口」= 1 个 Terminal 默认空白窗 + 1 个跑 `cd ...` 命令的窗。
> `launch` 不会触发双窗，但 Terminal 不会抢前台，新窗可能藏在其他 App 后面。

## 为什么 `do script` 会触发双窗口？

**根因**：macOS 「关闭窗口时保留窗口」默认行为（`NSQuitAlwaysKeepsWindows = true`）。

1. 首次按 `Opt+Z` 时，Terminal.app **没在运行**
2. `do script` 隐式启动 Terminal.app
3. Terminal.app 启动时按 macOS 的「恢复窗口」机制，**重新打开上次关闭时保留的窗口**（一个空白窗）
4. `do script` 自己再开一个新窗跑命令
5. 结果：2 个窗

**后续**按 `Opt+Z` 时 Terminal.app 已在运行，macOS 不再触发「恢复」，所以只剩 1 个。

## 验证方法

```bash
# 1. 退出 Terminal.app
osascript -e 'quit app "Terminal"'

# 2. 清空 Terminal 的保存窗口状态
defaults delete com.apple.Terminal NSWindowFrameAutosaveName 2>/dev/null

# 3. 测试不同写法
osascript -e 'tell application "Terminal" to do script "echo hi"'
# 观察窗口数
osascript -e 'tell application "Terminal" to count windows'
```

## 最终方案（iDict 采用）

```swift
let script = """
tell application "Terminal"
    activate
    do script "cd \\"\(escapedPath)\\""
end tell
"""
```

- ✅ `activate` 抢前台（菜单栏、窗口都置顶，体验最稳）
- ⚠️ 首次启动 Terminal.app 时会有 2 个窗（双窗 Bug 触发条件）。后续 `Opt+Z` 不会复发
- ✅ 日常使用 Terminal 多数常驻，触发双窗概率低

## 如果想根治双窗口

需要在**系统层**关闭 macOS 的「恢复窗口」行为：

```bash
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
```

> ⚠️ 这是全局设置，会影响所有 App 的窗口恢复行为。请评估影响后再启用。

## 参考资料

- [Stack Overflow: How to detect when Terminal.app bring itself to front](https://stackoverflow.com/questions/22886772/how-to-detect-when-terminal-app-bring-itself-to-front)
- [Stack Overflow: Terminal AppleScript do script try block issue](https://stackoverflow.com/questions/26323021/terminal-applescript-do-script-do-shell-script-try-block-issue)
- [MacScripter: Scriptable Terminal that doesn't bring up an empty window first](https://www.macscripter.com/t/scriptable-terminal-that-doesnt-bring-up-an-empty-window-first/62653)
- [Apple 官方文档: 使用 AppleScript 和「终端」自动执行任务](https://support.apple.com/zh-cn/guide/terminal/trml1003/2.8/mac/10.13)
