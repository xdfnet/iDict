//
//  iDictController.swift
//  iDict主控制器：媒体控制、应用管理、锁屏登录和HTTP服务器的核心实现
//

import Foundation
import Network
import Combine
import CoreGraphics
import ApplicationServices
import OSLog
import AppKit
import IOKit

// MARK: - 常量定义

private enum Constants {
    /// 时间相关常量（纳秒）
    enum Timing {
        static let appTerminateWait: UInt64 = 500_000_000       // 0.5秒
        static let screenWakeDelay: UInt64 = 100_000_000        // 100ms
        static let loginScreenReadyWait: UInt64 = 1_000_000_000 // 1秒
        static let keystrokeDelay: UInt64 = 80_000_000          // 80ms
        static let enterKeyDelay: UInt64 = 100_000_000          // 100ms
        static let appLaunchWait: UInt64 = 5_000_000_000        // 5秒
        static let appLaunchCheckInterval: UInt64 = 500_000_000 // 0.5秒
    }
    
    /// 应用路径常量
    enum AppPath {
        static let douyin = "/Applications/抖音.app"
        static let qishui = "/Applications/汽水音乐.app"
    }
    
    /// Bundle Identifier 常量
    enum BundleID {
        static let douyin = "com.bytedance.douyin.desktop"
        static let qishui = "com.soda.music"
        static let loginWindow = "com.apple.loginwindow"
    }
    
    /// 虚拟键码常量
    enum VirtualKeyCode {
        static let space: CGKeyCode = 49
        static let enter: CGKeyCode = 36
        static let escape: CGKeyCode = 53
    }
    
    /// 重试次数常量
    enum Retry {
        static let appTerminateAttempts = 10
        static let appLaunchAttempts = 10
    }
}

// MARK: - 媒体控制器

final class MediaController {
    fileprivate static let logger = Logger(subsystem: "com.idict.media", category: "MediaController")

    private enum MediaKey: Int32 {
        case playPause = 16, nextTrack = 17, prevTrack = 18
        case volumeUp = 0, volumeDown = 1, mute = 7
        case arrowUp = 126, arrowDown = 125
        case lockScreen = 12  // Q键，配合Control+Command使用
        case space = 49  // 空格键
    }

    // 登录密码 - 从设置管理器获取
    private static var loginPassword: String {
        return SettingsManager.getCurrentPassword()
    }

    // 应用启动状态缓存
    private static var appStates: [String: Bool] = [:]
    
    static func playPause() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.playPause) }
    static func nextTrack() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.nextTrack) }
    static func previousTrack() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.prevTrack) }
    static func volumeUp() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.volumeUp) }
    static func volumeDown() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.volumeDown) }
    static func toggleMute() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.mute) }
    static func arrowUp() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.arrowUp) }
    static func arrowDown() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.arrowDown) }
    static func smartLockOrLogin() async -> Result<Void, MediaControllerError> {
        let isLocked = isScreenLocked()
        logger.info("屏幕锁定状态: \(isLocked ? "已锁定" : "未锁定")")

        if isLocked {
            // 如果已锁屏，检查是否启用了自动登录且已设置密码
            guard SettingsManager.isAutoLoginEnabled() else {
                logger.info("自动登录功能已禁用")
                return .failure(.permissionDenied)
            }

            guard SettingsManager.hasPasswordSet() else {
                logger.warning("未设置登录密码")
                return .failure(.permissionDenied)
            }

            // 执行登录操作
            return await performLogin()
        } else {
            // 如果未锁屏，执行锁屏操作
            return await simulateLockScreen()
        }
    }

    static func lockScreen() async -> Result<Void, MediaControllerError> { await simulateLockScreen() }
    static func pressSpace() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.space) }

    // MARK: - 应用开关功能

    /// 检查应用是否正在运行（支持Electron应用）
    static func isAppRunning(_ appName: String) -> Bool {
        // 将英文应用名转换为中文应用名
        let chineseAppName: String
        switch appName {
        case "douyin":
            chineseAppName = "抖音"
        case "qishui":
            chineseAppName = "汽水音乐"
        default:
            chineseAppName = appName // 如果已经是中文，直接使用
        }

        let bundleIdentifier = getAppBundleIdentifier(chineseAppName)

        // 方法1: 使用NSWorkspace检查
        let runningApps = NSWorkspace.shared.runningApplications
        let matchedApps = runningApps.filter { app in
            app.bundleIdentifier == bundleIdentifier
        }

        if !matchedApps.isEmpty {
            logger.info("通过NSWorkspace检测到应用运行: \(chineseAppName)")
            return true
        }

        // 方法2: 使用AppleScript检查（更可靠的方法）
        let appleScript = """
        tell application "System Events"
            set found to false
            repeat with appProc in every application process
                try
                    set bundleID to bundle identifier of appProc
                    if bundleID is "\(bundleIdentifier)" then
                        set found to true
                        exit repeat
                    end if
                end try
            end repeat
            return found
        end tell
        """

        var error: NSDictionary?
        let appleScriptObject = NSAppleScript(source: appleScript)
        let result = appleScriptObject?.executeAndReturnError(&error)

        if let error = error {
            logger.warning("AppleScript检查应用状态失败: \(error.description)")
            return false
        }

        // 检查AppleScript的返回值
        if let result = result {
            let isRunning = result.booleanValue
            logger.info("AppleScript检测应用状态: \(chineseAppName) = \(isRunning)")
            return isRunning
        }

        // 方法3: 备用方法 - 使用进程名检查
        let processName = chineseAppName
        let processScript = """
        tell application "System Events"
            set found to false
            repeat with appProc in every application process
                try
                    set procName to name of appProc
                    if procName contains "\(processName)" then
                        set found to true
                        exit repeat
                    end if
                end try
            end repeat
            return found
        end tell
        """

        let processScriptObject = NSAppleScript(source: processScript)
        let processResult = processScriptObject?.executeAndReturnError(&error)

        if let processResult = processResult, processResult.booleanValue == true {
            logger.info("进程名检测应用运行: \(chineseAppName)")
            return true
        }

        logger.info("未检测到应用运行: \(chineseAppName)")
        return false
    }

    /// 获取应用的Bundle Identifier
    private static func getAppBundleIdentifier(_ appName: String) -> String {
        switch appName {
        case "抖音":
            return Constants.BundleID.douyin
        case "汽水音乐":
            return Constants.BundleID.qishui
        default:
            return "com.unknown.\(appName.lowercased())"
        }
    }

    /// 切换应用开关状态
    static func toggleApp(_ appName: String) async -> Result<Void, MediaControllerError> {
        let isRunning = isAppRunning(appName)
        logger.info("应用 '\(appName)' 当前状态: \(isRunning ? "运行中" : "未运行")")

        if isRunning {
            logger.info("执行关闭应用操作: \(appName)")
            return await closeApp(appName)
        } else {
            logger.info("执行打开应用操作: \(appName)")
            return await openApp(appName)
        }
    }

    /// 关闭应用
    private static func closeApp(_ appName: String) async -> Result<Void, MediaControllerError> {
        logger.info("尝试关闭应用: \(appName)")

        let bundleIdentifier = getAppBundleIdentifier(appName)

        do {
            // 使用NSWorkspace终止应用
            let runningApps = NSWorkspace.shared.runningApplications
            if let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
                app.terminate()

                // 等待应用完全退出
                for _ in 0..<Constants.Retry.appTerminateAttempts {
                    try await Task.sleep(nanoseconds: Constants.Timing.appTerminateWait)
                    if !NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == bundleIdentifier }) {
                        logger.info("成功关闭应用: \(appName)")
                        appStates[appName] = false
                        return .success(())
                    }
                }

                // 如果正常关闭失败，强制关闭
                logger.warning("应用正常关闭失败，尝试强制关闭: \(appName)")
                let forceCloseApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
                if let appToForceClose = forceCloseApps.first, appToForceClose.forceTerminate() {
                    logger.info("强制关闭应用成功: \(appName)")
                    appStates[appName] = false
                    return .success(())
                } else {
                    logger.error("强制关闭应用失败: \(appName)")
                    return .failure(.eventPostFailed)
                }
            } else {
                logger.warning("应用未在运行: \(appName)")
                return .failure(.eventPostFailed)
            }
        } catch {
            logger.error("关闭应用时发生错误: \(appName), 错误: \(error.localizedDescription)")
            return .failure(.eventPostFailed)
        }
    }

    // MARK: - 锁屏状态检测和自动登录功能

    /// 检测屏幕是否锁定
    static func isScreenLocked() -> Bool {
        // 方法1: 检查登录窗口是否在前台（最可靠的方法）
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let loginWindowRunning = frontmostApp?.bundleIdentifier == Constants.BundleID.loginWindow

        if loginWindowRunning {
            return true
        }

        
        // 综合判断：只有当登录窗口在前台时才认为是锁屏状态
        // 这样避免了误判系统正常使用状态为锁屏
        return loginWindowRunning
    }

    /// 执行自动登录
    private static func performLogin() async -> Result<Void, MediaControllerError> {
        logger.info("开始执行自动登录...")

        guard checkInputMonitoringPermission() else {
            logger.warning("无辅助功能权限")
            return .failure(.permissionDenied)
        }

        // 步骤1: 按ESC键唤醒屏幕（不会被误认为密码输入）
        let source = CGEventSource(stateID: .hidSystemState)
        guard let wakeEvent = CGEvent(keyboardEventSource: source, virtualKey: Constants.VirtualKeyCode.escape, keyDown: true),
              let wakeEventUp = CGEvent(keyboardEventSource: source, virtualKey: Constants.VirtualKeyCode.escape, keyDown: false) else {
            logger.error("创建唤醒事件失败")
            return .failure(.eventCreationFailed)
        }

        // 发送唤醒按键（按下和抬起）
        wakeEvent.post(tap: .cghidEventTap)
        try? await Task.sleep(nanoseconds: Constants.Timing.screenWakeDelay)
        wakeEventUp.post(tap: .cghidEventTap)

        // 等待更长时间确保屏幕完全唤醒和登录界面准备好
        try? await Task.sleep(nanoseconds: Constants.Timing.loginScreenReadyWait)

        // 步骤2: 再次确认是否仍在锁屏状态，然后输入密码
        if isScreenLocked() {
            logger.info("确认仍在锁屏状态，开始输入密码")
            return await typePassword(loginPassword)
        } else {
            logger.info("系统已解锁，无需输入密码")
            return .success(())
        }
    }

    /// 输入密码并回车
    private static func typePassword(_ password: String) async -> Result<Void, MediaControllerError> {
        guard checkInputMonitoringPermission() else {
            logger.warning("无辅助功能权限")
            return .failure(.permissionDenied)
        }

        let source = CGEventSource(stateID: .hidSystemState)
        logger.info("开始输入密码，密码长度: \(password.count)")

        // 输入密码的每个字符
        for (index, character) in password.enumerated() {
            guard let keyCode = getVirtualKeyCode(for: character) else {
                logger.error("无法获取字符 '\(character)' 的虚拟键码")
                return .failure(.eventCreationFailed)
            }

            logger.info("输入字符 \(index + 1)/\(password.count): '\(character)' (键码: \(keyCode))")

            // 创建按键按下事件
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true) else {
                logger.error("创建按键 '\(character)' 按下事件失败")
                return .failure(.eventCreationFailed)
            }

            // 创建按键抬起事件
            guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false) else {
                logger.error("创建按键 '\(character)' 抬起事件失败")
                return .failure(.eventCreationFailed)
            }

            // 设置按键标志（确保没有意外的修饰键）
            keyDown.flags = []
            keyUp.flags = []

            // 发送按键事件
            keyDown.post(tap: .cghidEventTap)

            // 适当延迟以确保按键被正确识别
            try? await Task.sleep(nanoseconds: Constants.Timing.keystrokeDelay)

            keyUp.post(tap: .cghidEventTap)

            // 字符间延迟
            try? await Task.sleep(nanoseconds: Constants.Timing.keystrokeDelay)
        }

        logger.info("密码字符输入完成，准备发送回车键")

        // 输入回车键确认
        if let enterKeyDown = CGEvent(keyboardEventSource: source, virtualKey: Constants.VirtualKeyCode.enter, keyDown: true),
           let enterKeyUp = CGEvent(keyboardEventSource: source, virtualKey: Constants.VirtualKeyCode.enter, keyDown: false) {

            // 确保回车键没有修饰键
            enterKeyDown.flags = []
            enterKeyUp.flags = []

            enterKeyDown.post(tap: .cghidEventTap)
            try? await Task.sleep(nanoseconds: Constants.Timing.enterKeyDelay)
            enterKeyUp.post(tap: .cghidEventTap)

            logger.info("回车键发送完成")
        } else {
            logger.error("创建回车键事件失败")
            return .failure(.eventCreationFailed)
        }

        logger.info("密码输入完成")
        return .success(())
    }

    /// 获取字符对应的虚拟键码
    private static func getVirtualKeyCode(for character: Character) -> Int32? {
        switch character {
        case "a", "A": return 0
        case "b", "B": return 11
        case "c", "C": return 8
        case "d", "D": return 2
        case "e", "E": return 14
        case "f", "F": return 3
        case "g", "G": return 5
        case "h", "H": return 4
        case "i", "I": return 34
        case "j", "J": return 38
        case "k", "K": return 40
        case "l", "L": return 37
        case "m", "M": return 46
        case "n", "N": return 45
        case "o", "O": return 31
        case "p", "P": return 35
        case "q", "Q": return 12
        case "r", "R": return 15
        case "s", "S": return 1
        case "t", "T": return 17
        case "u", "U": return 32
        case "v", "V": return 9
        case "w", "W": return 13
        case "x", "X": return 7
        case "y", "Y": return 16
        case "z", "Z": return 6
        default:
            // 对于其他字符，使用Unicode映射
            return nil
        }
    }

    static func checkInputMonitoringPermission() -> Bool {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": false] as CFDictionary)
    }
    
    static func requestInputMonitoringPermission() {
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
    
    private static func simulateMediaKey(_ key: MediaKey) async -> Result<Void, MediaControllerError> {
        guard checkInputMonitoringPermission() else {
            logger.warning("无辅助功能权限")
            return .failure(.permissionDenied)
        }
        
        func doKey(down: Bool) {
            let flags = down ? 0xa00 : 0xb00
            let data1 = Int((key.rawValue << 16) | Int32(flags))
            let ev = NSEvent.otherEvent(with: .systemDefined, location: .zero,
                                        modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(flags)),
                                        timestamp: 0, windowNumber: 0, context: nil,
                                        subtype: 8, data1: data1, data2: -1)
            ev?.cgEvent?.post(tap: .cghidEventTap)
        }
        
        doKey(down: true)
        doKey(down: false)
        return .success(())
    }
    
    private static func simulateArrowKey(_ key: MediaKey) async -> Result<Void, MediaControllerError> {
        guard checkInputMonitoringPermission() else {
            logger.warning("无辅助功能权限")
            return .failure(.permissionDenied)
        }
        
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key.rawValue), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key.rawValue), keyDown: false) else {
            return .failure(.eventCreationFailed)
        }
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return .success(())
    }
    
    private static func simulateLockScreen() async -> Result<Void, MediaControllerError> {
        guard checkInputMonitoringPermission() else {
            logger.warning("无辅助功能权限")
            return .failure(.permissionDenied)
        }
        
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(MediaKey.lockScreen.rawValue), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(MediaKey.lockScreen.rawValue), keyDown: false) else {
            return .failure(.eventCreationFailed)
        }
        
        // 设置 Control + Command 组合键
        keyDown.flags = [.maskControl, .maskCommand]
        keyUp.flags = [.maskControl, .maskCommand]
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return .success(())
    }

    static func openApp(_ name: String) async -> Result<Void, MediaControllerError> {
        logger.info("尝试打开应用: \(name)")

        let appPath: String
        let displayName: String

        switch name {
        case "douyin", "抖音":
            appPath = Constants.AppPath.douyin
            displayName = "抖音"
        case "qishui", "汽水音乐":
            appPath = Constants.AppPath.qishui
            displayName = "汽水音乐"
        default:
            logger.error("未知应用名称: \(name)")
            return .failure(.eventPostFailed)
        }

        let appURL = URL(fileURLWithPath: appPath)

        // 先检查应用是否存在
        guard FileManager.default.fileExists(atPath: appURL.path) else {
            logger.error("应用不存在: \(appURL.path)")
            return .failure(.eventPostFailed)
        }

        logger.info("应用路径存在，使用open命令启动Electron应用: \(displayName)")

        // 使用与终端相同的命令方式
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = [appPath]

        do {
            try process.run()
            process.waitUntilExit()

            let exitCode = process.terminationStatus
            if exitCode == 0 {
                logger.info("open命令执行成功: \(name), 退出码: \(exitCode)")
                appStates[name] = true

                // Electron应用需要更长的启动时间
                logger.info("等待Electron应用启动: \(name)")
                try await Task.sleep(nanoseconds: Constants.Timing.appLaunchWait)

                // 再次检查应用状态
                let isNowRunning = isAppRunning(name)
                if isNowRunning {
                    logger.info("Electron应用已成功启动: \(name)")
                    return .success(())
                } else {
                    // 尝试再次检测，因为Electron应用启动较慢
                    logger.info("再次检测Electron应用状态: \(name)")
                    try await Task.sleep(nanoseconds: Constants.Timing.appLaunchWait - Constants.Timing.appLaunchCheckInterval)

                    let isStillRunning = isAppRunning(name)
                    if isStillRunning {
                        logger.info("Electron应用延迟启动成功: \(name)")
                        return .success(())
                    } else {
                        logger.warning("Electron应用可能启动失败但命令已执行: \(name)")
                        // 仍然返回成功，因为open命令已经执行
                        return .success(())
                    }
                }
            } else {
                logger.error("open命令执行失败: \(name), 退出码: \(exitCode)")
                return .failure(.eventPostFailed)
            }
        } catch {
            logger.error("执行open命令时发生异常: \(name), 错误: \(error.localizedDescription)")
            return .failure(.eventPostFailed)
        }
    }

  }

// MARK: - HTTP服务器

@MainActor
class MediaHTTPServer: ObservableObject {
    private var listener: NWListener?
    private let port: UInt16
    @Published var isRunning = false
    @Published var serverURL: String?
    
    init(port: UInt16 = 8888) { self.port = port }
    
    func start() -> Result<Void, MediaHTTPServerError> {
        stop()
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.handleConnection(connection) }
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.serverURL = "http://192.168.100.202:\(self?.port ?? 8888)"
                    case .failed(let error):
                        self?.isRunning = false
                        self?.serverURL = "启动失败: \(error.localizedDescription)"
                    case .cancelled:
                        self?.isRunning = false
                    default: break
                    }
                }
            }
            
            listener?.start(queue: .global())
            return .success(())
        } catch {
            return .failure(.startFailed(error))
        }
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        serverURL = nil
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { if case .failed = $0 { connection.cancel() } }
        connection.start(queue: .global())
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, _ in
            if let data = data, !data.isEmpty {
                Task { @MainActor in self?.processRequest(data: data, connection: connection) }
            }
            if isComplete { connection.cancel() }
        }
    }
    
    private func processRequest(data: Data, connection: NWConnection) {
        guard let request = String(data: data, encoding: .utf8),
              let line = request.components(separatedBy: "\r\n").first,
              let path = line.components(separatedBy: " ").dropFirst().first else {
            send(connection, 400, "Bad Request")
            return
        }
        
        MediaController.logger.info("收到请求: \(path)")
        
        if path == "/" || path == "/index.html" {
            sendHTML(connection, generateHTML())
        } else if path.hasPrefix("/api/") {
            handleAPI(path: path, connection: connection)
        } else if path.hasPrefix("/assets/") {
            serveAsset(path: path, connection: connection)
        } else {
            MediaController.logger.warning("未找到路径: \(path)")
            send(connection, 404, "Not Found")
        }
    }
    
    private func handleAPI(path: String, connection: NWConnection) {
        Task {
            let action = String(path.dropFirst(5))
            MediaController.logger.info("处理API动作: \(action)")
            var result = "success"
            var error: String?
            
            switch action {
            case "playpause": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.playPause() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "space": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.pressSpace() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "next": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.nextTrack() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "prev": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.previousTrack() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "volumeup": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.volumeUp() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "volumedown": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.volumeDown() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "mute": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.toggleMute() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "arrowup": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.arrowUp() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "arrowdown": 
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.arrowDown() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "lock":
                if MediaController.checkInputMonitoringPermission() {
                    let isLocked = MediaController.isScreenLocked()
                    if isLocked && !SettingsManager.isAutoLoginEnabled() {
                        result = "auto_login_disabled"
                        error = "自动登录功能已禁用"
                    } else if isLocked && !SettingsManager.hasPasswordSet() {
                        result = "password_not_set"
                        error = "未设置登录密码"
                    } else {
                        let loginResult = await MediaController.smartLockOrLogin()
                        if case .success = loginResult {
                            // 返回当前状态信息给前端
                            result = isLocked ? "login_success" : "lock_success"
                        } else {
                            result = "failed"
                            error = "操作失败"
                        }
                    }
                }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "lock_status":
                // 新增API：获取锁屏状态
                let isLocked = MediaController.isScreenLocked()
                result = isLocked ? "locked" : "unlocked"
            case "toggle_douyin":
                // 先检查状态，然后执行相反操作
                let wasRunning = MediaController.isAppRunning("douyin")
                MediaController.logger.info("抖音切换前状态: \(wasRunning ? "运行中" : "未运行")")

                let toggleResult = await MediaController.toggleApp("抖音")
                if case .success = toggleResult {
                    // 根据操作前的状态推断操作后的状态
                    result = wasRunning ? "closed" : "opened"
                    MediaController.logger.info("抖音切换操作完成，结果: \(result)")
                } else {
                    result = "failed"
                    error = "操作失败"
                }
            case "toggle_qishui":
                // 先检查状态，然后执行相反操作
                let wasRunning = MediaController.isAppRunning("qishui")
                MediaController.logger.info("汽水音乐切换前状态: \(wasRunning ? "运行中" : "未运行")")

                let toggleResult = await MediaController.toggleApp("汽水音乐")
                if case .success = toggleResult {
                    // 根据操作前的状态推断操作后的状态
                    result = wasRunning ? "closed" : "opened"
                    MediaController.logger.info("汽水音乐切换操作完成，结果: \(result)")
                } else {
                    result = "failed"
                    error = "操作失败"
                }
            case "status_douyin":
                result = MediaController.isAppRunning("douyin") ? "running" : "stopped"
            case "status_qishui":
                result = MediaController.isAppRunning("qishui") ? "running" : "stopped"
            case "test_apps":
                // 测试应用状态检测
                let douyinRunning = MediaController.isAppRunning("douyin")
                let qishuiRunning = MediaController.isAppRunning("qishui")
                result = "douyin:\(douyinRunning ? "running" : "stopped"),qishui:\(qishuiRunning ? "running" : "stopped")"
            default: 
                result = "unknown"
                error = "未知操作: \(action)"
                MediaController.logger.warning("未知API操作: \(action)")
            }
            
            let json = error != nil ? "{\"status\":\"\(result)\",\"error\":\"\(error!)\"}" : "{\"status\":\"\(result)\"}"
            sendJSON(connection, json)
        }
    }

    private func serveAsset(path: String, connection: NWConnection) {
        let filename = String(path.dropFirst(8)) // Remove /assets/
        MediaController.logger.info("请求资源: \(filename)")
        var fileURL: URL?
        
        // Try to find in assets subdirectory of bundle resources
        if let resourcePath = Bundle.main.resourcePath {
            let assetsPath = URL(fileURLWithPath: resourcePath).appendingPathComponent("assets")
            let potentialFile = assetsPath.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: potentialFile.path) {
                fileURL = potentialFile
                MediaController.logger.info("在assets目录找到文件: \(potentialFile.path)")
            }
        }
        
        // Fallback: try finding it in main bundle directly
        if fileURL == nil {
             let name = (filename as NSString).deletingPathExtension
             let ext = (filename as NSString).pathExtension
             if let path = Bundle.main.path(forResource: name, ofType: ext) {
                 fileURL = URL(fileURLWithPath: path)
                 MediaController.logger.info("在Bundle根目录找到文件: \(path)")
             }
        }

        if let url = fileURL, let data = try? Data(contentsOf: url) {
            let ext = url.pathExtension.lowercased()
            let contentType: String
            switch ext {
            case "png": contentType = "image/png"
            case "jpg", "jpeg": contentType = "image/jpeg"
            case "svg": contentType = "image/svg+xml"
            default: contentType = "application/octet-stream"
            }
            sendData(connection, 200, data, type: contentType)
        } else {
            MediaController.logger.error("未找到资源文件: \(filename)")
            send(connection, 404, "Asset Not Found")
        }
    }
    
    private func send(_ conn: NWConnection, _ code: Int, _ body: String, type: String = "text/plain") {
        let status = ["200": "OK", "400": "Bad Request", "404": "Not Found"]["\(code)"] ?? "Error"
        let response = "HTTP/1.1 \(code) \(status)\r\nContent-Type: \(type); charset=UTF-8\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
        conn.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
    }

    private func sendData(_ conn: NWConnection, _ code: Int, _ data: Data, type: String) {
        let status = ["200": "OK", "400": "Bad Request", "404": "Not Found"]["\(code)"] ?? "Error"
        let header = "HTTP/1.1 \(code) \(status)\r\nContent-Type: \(type)\r\nContent-Length: \(data.count)\r\nConnection: close\r\n\r\n"
        var responseData = header.data(using: .utf8)!
        responseData.append(data)
        conn.send(content: responseData, completion: .contentProcessed { _ in conn.cancel() })
    }
    
    private func sendHTML(_ conn: NWConnection, _ html: String) { send(conn, 200, html, type: "text/html") }
    private func sendJSON(_ conn: NWConnection, _ json: String) { send(conn, 200, json, type: "application/json") }
    
    private func generateHTML() -> String {
        if let filepath = Bundle.main.path(forResource: "index", ofType: "html") {
            do {
                return try String(contentsOfFile: filepath, encoding: .utf8)
            } catch {
                MediaController.logger.error("无法读取 index.html: \(error.localizedDescription)")
            }
        } else {
            MediaController.logger.error("未找到 index.html 资源文件")
        }
        
        // Fallback HTML in case file load fails
        return """
        <!DOCTYPE html>
        <html>
        <head><title>Error</title></head>
        <body>
            <h1>Error Loading Interface</h1>
            <p>Could not load index.html from bundle.</p>
        </body>
        </html>
        """
    }
}

// MARK: - 错误定义

enum MediaControllerError: LocalizedError, Sendable {
    case permissionDenied, eventCreationFailed, eventPostFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "缺少\"辅助功能\"权限"
        case .eventCreationFailed: return "创建媒体控制事件失败"
        case .eventPostFailed: return "发送媒体控制事件失败"
        }
    }
    
    var recoverySuggestion: String? {
        self == .permissionDenied ? "请前往\"系统设置\" > \"隐私与安全性\" > \"辅助功能\"启用权限" : "请尝试重启应用"
    }
}

enum MediaHTTPServerError: LocalizedError {
    case startFailed(Error), invalidPort, networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .startFailed(let e): return "HTTP服务器启动失败: \(e.localizedDescription)"
        case .invalidPort: return "无效的端口号"
        case .networkError(let e): return "网络错误: \(e.localizedDescription)"
        }
    }
}