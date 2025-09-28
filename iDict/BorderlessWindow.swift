//
//  BorderlessWindow.swift
//  无边框窗口类：支持键盘焦点和快捷键关闭
//

import Cocoa

/// 支持键盘焦点和快捷键关闭的无边框窗口。
class BorderlessWindow: NSWindow {
    /// 允许窗口成为键盘焦点。
    override var canBecomeKey: Bool {
        return true
    }
    
    /// 允许窗口成为应用程序的主窗口。
    override var canBecomeMain: Bool {
        return true
    }
    
    /// 监听键盘事件，支持ESC和Cmd+W关闭窗口。
    override func keyDown(with event: NSEvent) {
        // 检查是否按下了 ESC (keyCode 53) 或 Cmd+W (keyCode 13 + command)
        if event.keyCode == 53 || (event.keyCode == 13 && event.modifierFlags.contains(.command)) {
            close()
        } else {
            super.keyDown(with: event)
        }
    }
}
