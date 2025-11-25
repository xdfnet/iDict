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
@MainActor
class HotKeyManager {
    
    // MARK: - 属性
    
    private var isRegistered = false
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: (() -> Void)?
    private var currentConfig: HotKeyConfig?
    
    // MARK: - 公共方法
    
    /// 注册全局热键。
    /// 
    /// - Parameter handler: 热键触发时执行的回调函数
    /// - Returns: 注册结果，成功时为.success，失败时包含具体错误信息
    func registerHotKey(handler: @escaping () -> Void) async -> Result<Void, HotKeyError> {
        // 检查辅助功能权限
        guard checkAccessibilityPermission() else {
            return .failure(.permissionDenied)
        }
        
        // 先注销现有热键
        await unregisterHotKey()
        
        self.handler = handler
        let config = HotKeyConfig.defaultConfig
        self.currentConfig = config
        
        let hotKeyID = EventHotKeyID(
            signature: config.signature,
            id: config.id
        )
        
        // 注册热键
        let registerStatus = RegisterEventHotKey(
            config.keyCode,
            config.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        guard registerStatus == noErr else {
            return .failure(.registrationFailed(registerStatus))
        }
        
        // 安装事件处理器
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handler?()
                return OSStatus(noErr)
            },
            1,
            [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))],
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        
        guard installStatus == noErr else {
            return .failure(.eventHandlerInstallFailed(installStatus))
        }
        
        isRegistered = true
        return .success(())
    }
    
    /// 注销全局热键并清理相关资源。
    func unregisterHotKey() async {
        if let hotKeyRef = hotKeyRef {
            _ = UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            _ = RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        
        handler = nil
        currentConfig = nil
        isRegistered = false
    }
    
    // MARK: - 权限检查
    
    /// 检查应用是否具有辅助功能权限。
    private func checkAccessibilityPermission() -> Bool {
        return PermissionManager.checkAccessibilityPermission()
    }
    
    // MARK: - 清理资源
    
    nonisolated deinit {
        // 注意：在deinit中我们无法安全地访问主线程隔离的属性
        // 热键的清理应该在unregisterHotKey方法中显式处理
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