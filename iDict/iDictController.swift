//
//  iDictController.swift
//  媒体控制、应用管理、锁屏和 HTTP 服务器
//

import Foundation
import Network
import Combine
import CoreGraphics
import ApplicationServices
import OSLog
import AppKit

// MARK: - 常量定义

private enum Constants {
    /// 时间相关常量（纳秒）
    enum Timing {
        static let appTerminateWait: UInt64 = 500_000_000       // 0.5秒
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
    
    /// 重试次数常量
    enum Retry {
        static let appTerminateAttempts = 10
    }
}

// MARK: - 媒体控制器

/// 媒体播放、应用管理、锁屏等系统控制功能
final class MediaController {
    fileprivate static let logger = Logger(subsystem: "com.idict.media", category: "MediaController")

    private enum MediaKey: Int32 {
        case playPause = 16, nextTrack = 17, prevTrack = 18
        case volumeUp = 0, volumeDown = 1, mute = 7
        case arrowUp = 126, arrowDown = 125
        case lockScreen = 12  // Q键，配合Control+Command使用
        case space = 49  // 空格键
    }
    
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
            // 已锁屏状态，不执行任何操作
            logger.warning("屏幕已锁定，无法通过软件唤醒")
            return .failure(.eventCreationFailed)
        } else {
            // 如果未锁屏，则执行锁屏操作
            logger.info("系统未锁定，执行锁屏操作")
            return await simulateLockScreen()
        }
    }

    static func lockScreen() async -> Result<Void, MediaControllerError> { await simulateLockScreen() }
    static func pressSpace() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.space) }

    // MARK: - 应用管理

    /// 检查应用是否运行
    static func isAppRunning(_ appName: String) -> Bool {
        let bundleId = getBundleId(appName)
        let isRunning = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId }
        logger.info("应用状态: \(appName) = \(isRunning ? "运行" : "停止")")
        return isRunning
    }

    /// 获取应用 Bundle ID
    private static func getBundleId(_ name: String) -> String {
        switch name {
        case "douyin", "抖音": return Constants.BundleID.douyin
        case "qishui", "汽水音乐": return Constants.BundleID.qishui
        default: return "com.unknown.\(name.lowercased())"
        }
    }

    /// 切换应用开关
    static func toggleApp(_ appName: String) async -> Result<Void, MediaControllerError> {
        return isAppRunning(appName) ? await closeApp(appName) : await openApp(appName)
    }

    /// 关闭应用（尝试正常终止，失败则强制关闭）
    private static func closeApp(_ appName: String) async -> Result<Void, MediaControllerError> {
        let bundleId = getBundleId(appName)

        do {
            guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) else {
                return .failure(.eventPostFailed)
            }
            
            app.terminate()

                for _ in 0..<Constants.Retry.appTerminateAttempts {
                    try await Task.sleep(nanoseconds: Constants.Timing.appTerminateWait)
                    if !NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == bundleId }) {
                        return .success(())
                    }
                }

                // 强制关闭
                if let forceApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first,
                   forceApp.forceTerminate() {
                    return .success(())
                }
                return .failure(.eventPostFailed)
        } catch {
            return .failure(.eventPostFailed)
        }
    }

    // MARK: - 锁屏控制

    /// 检测屏幕是否锁定
    static func isScreenLocked() -> Bool {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Constants.BundleID.loginWindow
    }

    /// 检查辅助功能权限
    static func checkInputMonitoringPermission() -> Bool {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": false] as CFDictionary)
    }
    
    /// 请求辅助功能权限
    static func requestInputMonitoringPermission() {
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
    
    /// 模拟媒体按键
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
    
    /// 模拟方向键
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
    
    /// 模拟锁屏（Control+Command+Q）
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

    /// 打开应用
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

/// 媒体控制 HTTP 服务器
@MainActor
class MediaHTTPServer: ObservableObject {
    private var listener: NWListener?
    private let port: UInt16
    @Published var isRunning = false
    @Published var serverURL: String?
    
    init(port: UInt16 = 8888) { self.port = port }
    
    /// 启动服务器
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
                        self?.serverURL = "http://127.0.0.1:\(self?.port ?? 8888)"
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
    
    /// 停止服务器
    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        serverURL = nil
    }
    
    /// 处理客户端连接
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
    
    /// 处理 HTTP 请求
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
    
    /// 处理 API 请求
    private func handleAPI(path: String, connection: NWConnection) {
        Task {
            let action = String(path.dropFirst(5))
            MediaController.logger.info("处理API动作: \(action)")
            var result = "success"
            var error: String?
            
            // 对需要权限的操作提前检查
            let needsPermission = !["lock_status", "status_douyin", "status_qishui", "test_apps"].contains(action)
            
            if needsPermission && !MediaController.checkInputMonitoringPermission() {
                result = "failed"
                error = "缺少辅助功能权限"
                let json = "{\"status\":\"\(result)\",\"error\":\"\(error!)\"}"
                sendJSON(connection, json)
                return
            }
            
            switch action {
            case "playpause": _ = await MediaController.playPause()
            case "space": _ = await MediaController.pressSpace()
            case "next": _ = await MediaController.nextTrack()
            case "prev": _ = await MediaController.previousTrack()
            case "volumeup": _ = await MediaController.volumeUp()
            case "volumedown": _ = await MediaController.volumeDown()
            case "mute": _ = await MediaController.toggleMute()
            case "arrowup": _ = await MediaController.arrowUp()
            case "arrowdown": _ = await MediaController.arrowDown()
                
            case "lock":
                let isLocked = MediaController.isScreenLocked()
                if isLocked {
                    result = "locked"
                    error = "屏幕已锁定，无法通过软件唤醒"
                } else {
                    let lockResult = await MediaController.smartLockOrLogin()
                    if case .success = lockResult {
                        result = "lock_success"
                    } else {
                        result = "failed"
                        error = "锁屏失败"
                    }
                }
                
            case "lock_status":
                let isLocked = MediaController.isScreenLocked()
                result = isLocked ? "locked" : "unlocked"
                
            case "toggle_douyin":
                let wasRunning = MediaController.isAppRunning("douyin")
                MediaController.logger.info("抖音切换前状态: \(wasRunning ? "运行中" : "未运行")")
                let toggleResult = await MediaController.toggleApp("抖音")
                if case .success = toggleResult {
                    result = wasRunning ? "closed" : "opened"
                    MediaController.logger.info("抖音切换操作完成，结果: \(result)")
                } else {
                    result = "failed"
                    error = "操作失败"
                }
                
            case "toggle_qishui":
                let wasRunning = MediaController.isAppRunning("qishui")
                MediaController.logger.info("汽水音乐切换前状态: \(wasRunning ? "运行中" : "未运行")")
                let toggleResult = await MediaController.toggleApp("汽水音乐")
                if case .success = toggleResult {
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