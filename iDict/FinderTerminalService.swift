//
//  FinderTerminalService.swift
//  Opt+Z 在当前 Finder 目录打开终端
//

import Cocoa

/// 在 Finder 当前目录打开 Terminal 的服务类。
///
/// 使用 AppleScript 获取 Finder 选中路径或当前窗口路径，
/// 然后在 Terminal 中 `cd` 到该目录。
@MainActor
class FinderTerminalService {

    static let shared = FinderTerminalService()
    private init() {}

    /// 一键操作：Finder 当前目录 → Terminal
    func openTerminalAtCurrentFinderLocation() {
        guard let path = getCurrentFinderPath() else { return }
        openTerminal(at: path)
    }

    /// 获取 Finder 当前窗口路径或选中项路径
    private func getCurrentFinderPath() -> String? {
        let script = """
        tell application "Finder"
            set sel to selection
            if sel ≠ {} then
                set theItem to item 1 of sel
                if class of theItem is folder or class of theItem is disk then
                    set p to POSIX path of (theItem as text)
                else
                    set p to POSIX path of ((container of theItem) as text)
                end if
            else
                try
                    set p to POSIX path of ((target of front Finder window) as text)
                on error
                    set p to POSIX path of (path to desktop folder)
                end try
            end if
        end tell
        return p
        """

        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else { return nil }
        let output = scriptObject.executeAndReturnError(&error)

        if error != nil { return nil }
        return output.stringValue
    }

    /// 一键操作：Finder 当前目录 → Terminal → 执行 claude
    func openTerminalAtCurrentFinderLocationAndRunClaude() {
        guard let path = getCurrentFinderPath() else { return }
        openTerminal(at: path, command: "exec claude")
    }

    /// 一键操作：Finder 当前目录 → Terminal → 执行 qwen
    func openTerminalAtCurrentFinderLocationAndRunQwen() {
        guard let path = getCurrentFinderPath() else { return }
        openTerminal(at: path, command: "exec qwen")
    }

    /// 一键操作：Finder 当前目录 → Terminal → 执行 codex
    func openTerminalAtCurrentFinderLocationAndRunCodex() {
        guard let path = getCurrentFinderPath() else { return }
        openTerminal(at: path, command: "exec codex")
    }

    /// 在 Terminal 中 cd 到目标路径，可选执行额外命令
    private func openTerminal(at path: String, command: String? = nil) {
        let escapedPath = path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script: String
        if let extraCmd = command {
            script = """
            tell application "Terminal"
                activate
                do script "cd \\"\(escapedPath)\\" && \(extraCmd)"
            end tell
            """
        } else {
            script = """
            tell application "Terminal"
                activate
                do script "cd \\"\(escapedPath)\\""
            end tell
            """
        }

        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else { return }
        scriptObject.executeAndReturnError(&error)

        if let error = error {
            print("iDict: 打开 Terminal 失败: \(error)")
        }
    }

    /// 一键操作：Finder 选中项 → 剪贴板（POSIX 路径，多选取第 1 个，无选中回退窗口）
    func copySelectedPathToClipboard() {
        guard let path = getSelectedItemPath() else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(path, forType: .string)
    }

    /// 获取 Finder 选中项的 POSIX 路径，无选中回退窗口路径或 Desktop
    private func getSelectedItemPath() -> String? {
        let script = """
        tell application "Finder"
            set sel to selection
            if sel ≠ {} then
                set p to POSIX path of (item 1 of sel as text)
            else
                try
                    set p to POSIX path of ((target of front Finder window) as text)
                on error
                    set p to POSIX path of (path to desktop folder)
                end try
            end if
        end tell
        return p
        """

        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else { return nil }
        let output = scriptObject.executeAndReturnError(&error)

        if error != nil { return nil }
        return output.stringValue
    }
}
