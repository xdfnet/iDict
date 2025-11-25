//
//  KeyboardSimulator.swift
//  键盘事件模拟文件，基于CoreGraphics实现自动化操作
//  提供Cmd+C复制模拟、权限检查和错误处理功能
//

import Foundation
import CoreGraphics
import ApplicationServices

/// 键盘事件模拟器，用于自动化复制操作。
final class KeyboardSimulator {
    
    // MARK: - 内部类型
    
    /// 定义了需要用到的虚拟键码。
    private enum KeyCode: CGKeyCode {
        case c = 0x08
        case command = 0x37
    }
    
    // MARK: - 公共静态方法
    
    /// 模拟Cmd+C复制操作。
    static func simulateCopyCommand() async -> Result<Void, KeyboardSimulatorError> {
        // 模拟键盘事件需要“输入监视”权限。
        guard checkInputMonitoringPermission() else {
            return .failure(.permissionDenied)
        }
        
        do {
            try await performCopyKeySequence()
            return .success(())
        } catch {
            return .failure(error as? KeyboardSimulatorError ?? .eventPostFailed)
        }
    }
    
    /// 检查是否具有输入监视权限。
    static func checkInputMonitoringPermission() -> Bool {
        return PermissionManager.checkInputMonitoringPermission()
    }

    /// 请求输入监视权限。
    static func requestInputMonitoringPermission() {
        PermissionManager.requestInputMonitoringPermission()
    }
    
    // MARK: - 私有实现
    
    /// 执行复制操作的按键序列。
    private static func performCopyKeySequence() async throws {
        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            throw KeyboardSimulatorError.eventCreationFailed
        }
        
        // 定义“复制”操作的精确按键顺序：Cmd按下 -> C按下 -> C释放 -> Cmd释放。
        let eventSequence: [(keyCode: KeyCode, isDown: Bool)] = [
            (.command, true),  // Command 键按下
            (.c, true),        // C 键按下
            (.c, false),       // C 键释放
            (.command, false)  // Command 键释放
        ]
        
        // 依次生成并发送每个键盘事件。
        for (index, eventConfig) in eventSequence.enumerated() {
            guard let event = CGEvent(keyboardEventSource: eventSource, virtualKey: eventConfig.keyCode.rawValue, keyDown: eventConfig.isDown) else {
                throw KeyboardSimulatorError.eventCreationFailed
            }
            // 为除最后一个（Cmd释放）之外的所有事件都附带 Command 修饰键标志。
            if eventConfig.keyCode != .command || eventConfig.isDown {
                event.flags = .maskCommand
            }
            
            event.post(tap: .cghidEventTap)
            
            // 在每个事件之间插入微小的延迟，以模拟真实用户的按键间隔，确保系统能正确处理。
            if index < eventSequence.count - 1 {
                try await Task.sleep(nanoseconds: 2_000_000) // 2ms
            }
        }
    }
}

// MARK: - 错误定义

/// 定义模拟键盘事件时可能发生的错误。
enum KeyboardSimulatorError: LocalizedError, Sendable {
    case permissionDenied
    case eventCreationFailed
    case eventPostFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "缺少“输入监视”权限，无法模拟键盘事件。"
        case .eventCreationFailed:
            return "创建键盘事件失败，可能是系统内部错误。"
        case .eventPostFailed:
            return "发送键盘事件失败，请检查权限设置。"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "请前往“系统设置” > “隐私与安全性” > “输入监视”，然后为 iDict 启用权限。"
        default:
            return "请尝试重启应用。如果问题仍然存在，请联系开发者。"
        }
    }
}