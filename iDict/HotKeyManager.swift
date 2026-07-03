//
//  HotKeyManager.swift
//  全局热键管理文件，提供热键注册和事件处理功能
//  实现Cmd+D热键监听、权限检查和错误处理机制
//

import Cocoa
import Carbon

// MARK: - 热键配置

/// 热键配置结构体
struct HotKeyConfig {
    let keyCode: UInt32
    let modifiers: UInt32
    let signature: UInt32
    let id: UInt32

    /// 默认配置：Cmd+D
    static var defaultConfig: HotKeyConfig {
        HotKeyConfig(
            keyCode: UInt32(kVK_ANSI_D),
            modifiers: UInt32(cmdKey),
            signature: 0x49444954, // "iDiT"
            id: 1
        )
    }
}

// MARK: - 热键管理器

/// 全局热键管理器，负责注册和管理系统级热键。
///
/// 此类封装了Carbon框架的热键API，提供简化的热键注册和注销功能。
/// 默认使用Cmd+D作为翻译热键，需要辅助功能权限。
/// 支持注册多个热键，通过 id 区分。
@MainActor
class HotKeyManager {

    // MARK: - 属性

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var eventHandler: EventHandlerRef?
    private var isEventHandlerInstalled = false

    // MARK: - 公共方法

    /// 注册默认热键（Cmd+D），保持向后兼容。
    func registerHotKey(handler: @escaping () -> Void) async -> Result<Void, HotKeyError> {
        await registerHotKey(config: .defaultConfig, handler: handler)
    }

    /// 注册自定义全局热键。
    ///
    /// - Parameters:
    ///   - config: 热键配置（键码、修饰键、签名、ID）
    ///   - handler: 热键触发时执行的回调函数
    /// - Returns: 注册结果
    func registerHotKey(
        config: HotKeyConfig,
        handler: @escaping () -> Void
    ) async -> Result<Void, HotKeyError> {
        // 检查辅助功能权限
        guard PermissionManager.checkAccessibilityPermission() else {
            return .failure(.permissionDenied)
        }

        // 如果该 ID 已注册，先注销
        if hotKeyRefs[config.id] != nil {
            await unregisterHotKey(id: config.id)
        }

        let hotKeyID = EventHotKeyID(
            signature: config.signature,
            id: config.id
        )

        // 注册热键
        var ref: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            config.keyCode,
            config.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard registerStatus == noErr, let ref = ref else {
            return .failure(.registrationFailed(registerStatus))
        }

        hotKeyRefs[config.id] = ref
        handlers[config.id] = handler

        // 安装事件处理器（只需一次）
        if !isEventHandlerInstalled {
            let installStatus = InstallEventHandler(
                GetApplicationEventTarget(),
                { (nextHandler, theEvent, userData) -> OSStatus in
                    guard let userData = userData else {
                        return OSStatus(eventNotHandledErr)
                    }
                    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                    var hotKeyID = EventHotKeyID()
                    let err = GetEventParameter(
                        theEvent,
                        EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hotKeyID
                    )

                    if err == noErr, let handler = manager.handlers[hotKeyID.id] {
                        handler()
                        return OSStatus(noErr)
                    }

                    return OSStatus(eventNotHandledErr)
                },
                1,
                [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))],
                Unmanaged.passUnretained(self).toOpaque(),
                &eventHandler
            )

            guard installStatus == noErr else {
                hotKeyRefs[config.id] = nil
                handlers[config.id] = nil
                return .failure(.eventHandlerInstallFailed(installStatus))
            }

            isEventHandlerInstalled = true
        }

        return .success(())
    }

    /// 注销指定 ID 的热键。
    func unregisterHotKey(id: UInt32) async {
        if let ref = hotKeyRefs[id] {
            UnregisterEventHotKey(ref)
            hotKeyRefs[id] = nil
        }
        handlers[id] = nil
    }

    /// 注销所有热键。
    func unregisterAll() async {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        handlers.removeAll()

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
            isEventHandlerInstalled = false
        }
    }

    /// 清理资源
    nonisolated deinit {
        // 注意：在deinit中无法安全访问 @MainActor 属性
        // 热键的清理应在 unregisterAll() 中显式处理
    }
}

// MARK: - 错误类型

enum HotKeyError: LocalizedError {
    case registrationFailed(OSStatus)
    case eventHandlerInstallFailed(OSStatus)
    case permissionDenied
    case invalidConfiguration
    case alreadyRegistered
    case systemError(Error)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let status):
            return "热键注册失败（错误码: \(status)）"
        case .eventHandlerInstallFailed(let status):
            return "事件处理器安装失败（错误码: \(status)）"
        case .permissionDenied:
            return "需要辅助功能权限才能使用全局热键"
        case .invalidConfiguration:
            return "热键配置无效"
        case .alreadyRegistered:
            return "该热键已被其他应用使用"
        case .systemError(let error):
            return "系统错误：\(error.localizedDescription)"
        }
    }
}
