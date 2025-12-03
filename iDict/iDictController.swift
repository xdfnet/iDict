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
    enum Timing {
        static let appTerminateWait: UInt64 = 500_000_000
        static let appLaunchWait: UInt64 = 2_000_000_000
        static let appLaunchCheckInterval: UInt64 = 300_000_000
    }

    enum Retry {
        static let appTerminateAttempts = 10
    }
    
    enum APIAction {
        static let noPermissionRequired = Set(["lock_status", "status_douyin", "status_qishui", "test_apps"])
    }
}

// MARK: - 媒体控制器

final class MediaController {
    fileprivate static let logger = Logger(subsystem: "com.idict.media", category: "MediaController")

    private enum MediaKey: Int32 {
        case playPause = 16, nextTrack = 17, prevTrack = 18
        case volumeUp = 0, volumeDown = 1, mute = 7
        case arrowUp = 126, arrowDown = 125
        case lockScreen = 12
        case space = 49
    }
    
    static func playPause() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.space) }
    static func nextTrack() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.nextTrack) }
    static func previousTrack() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.prevTrack) }
    static func volumeUp() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.volumeUp) }
    static func volumeDown() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.volumeDown) }
    static func toggleMute() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.mute) }
    static func arrowUp() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.arrowUp) }
    static func arrowDown() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.arrowDown) }
    static func pressSpace() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.space) }
    
    static func smartLockOrLogin() async -> Result<Void, MediaControllerError> {
        let isLocked = isScreenLocked()
        logger.info("屏幕锁定状态: \(isLocked ? "已锁定" : "未锁定")")
        
        if isLocked {
            logger.warning("屏幕已锁定，无法通过软件唤醒")
            return .failure(.eventCreationFailed)
        } else {
            logger.info("系统未锁定，执行锁屏操作")
            return await simulateLockScreen()
        }
    }

    static func lockScreen() async -> Result<Void, MediaControllerError> { await simulateLockScreen() }

    // MARK: - 应用管理

    /// 检查应用是否运行
    static func isAppRunning(_ appName: String) -> Bool {
        let bundleId = AppConfig.getBundleId(for: appName)
        let isRunning = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId }
        logger.info("应用状态: \(appName) = \(isRunning ? "运行" : "停止")")
        return isRunning
    }

    /// 切换应用开关
    static func toggleApp(_ appName: String) async -> Result<Void, MediaControllerError> {
        return isAppRunning(appName) ? await closeApp(appName) : await openApp(appName)
    }

    /// 关闭应用（尝试正常终止，失败则强制关闭）
    private static func closeApp(_ appName: String) async -> Result<Void, MediaControllerError> {
        let bundleId = AppConfig.getBundleId(for: appName)

        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) else {
            return .failure(.eventPostFailed)
        }
        
        app.terminate()
        
        if await waitForAppTermination(bundleId: bundleId) {
            return .success(())
        }
        
        if let forceApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first,
           forceApp.forceTerminate() {
            return .success(())
        }
        return .failure(.eventPostFailed)
    }
    
    /// 等待应用终止
    private static func waitForAppTermination(bundleId: String) async -> Bool {
        for _ in 0..<Constants.Retry.appTerminateAttempts {
            try? await Task.sleep(nanoseconds: Constants.Timing.appTerminateWait)
            if !NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == bundleId }) {
                return true
            }
        }
        return false
    }

    // MARK: - 锁屏控制

    /// 检测屏幕是否锁定
    static func isScreenLocked() -> Bool {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier == AppConfig.loginWindowBundleId
    }

    /// 检查辅助功能权限
    static func checkInputMonitoringPermission() -> Bool {
        return PermissionManager.checkAccessibilityPermission()
    }

    /// 请求辅助功能权限
    static func requestInputMonitoringPermission() {
        PermissionManager.requestAccessibilityPermission()
    }
    
    /// 权限检查包装器
    private static func withPermissionCheck<T>(
        _ operation: () async -> Result<T, MediaControllerError>
    ) async -> Result<T, MediaControllerError> {
        guard checkInputMonitoringPermission() else {
            logger.warning("无辅助功能权限")
            return .failure(.permissionDenied)
        }
        return await operation()
    }
    
    /// 模拟媒体按键
    private static func simulateMediaKey(_ key: MediaKey) async -> Result<Void, MediaControllerError> {
        await withPermissionCheck {
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
    }
    
    /// 模拟方向键
    private static func simulateArrowKey(_ key: MediaKey) async -> Result<Void, MediaControllerError> {
        await withPermissionCheck {
            let source = CGEventSource(stateID: .hidSystemState)
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key.rawValue), keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key.rawValue), keyDown: false) else {
                return .failure(.eventCreationFailed)
            }
            
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
            return .success(())
        }
    }
    
    /// 模拟锁屏（Control+Command+Q）
    private static func simulateLockScreen() async -> Result<Void, MediaControllerError> {
        await withPermissionCheck {
            let source = CGEventSource(stateID: .hidSystemState)
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(MediaKey.lockScreen.rawValue), keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(MediaKey.lockScreen.rawValue), keyDown: false) else {
                return .failure(.eventCreationFailed)
            }
            
            keyDown.flags = [.maskControl, .maskCommand]
            keyUp.flags = [.maskControl, .maskCommand]
            
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
            return .success(())
        }
    }

    /// 打开应用
    static func openApp(_ name: String) async -> Result<Void, MediaControllerError> {
        logger.info("尝试打开应用: \(name)")

        guard let appConfig = AppConfig.getAppConfig(for: name) else {
            logger.error("未知应用名称: \(name)")
            return .failure(.eventPostFailed)
        }

        guard FileManager.default.fileExists(atPath: appConfig.path) else {
            logger.error("应用不存在: \(appConfig.path)")
            return .failure(.eventPostFailed)
        }

        // 启动应用
        guard let exitCode = try? executeProcess("/usr/bin/open", arguments: [appConfig.path]) else {
            logger.error("执行open命令时发生异常: \(name)")
            return .failure(.eventPostFailed)
        }
        
        guard exitCode == 0 else {
            logger.error("open命令执行失败: \(name), 退出码: \(exitCode)")
            return .failure(.eventPostFailed)
        }

        // 等待应用启动并激活
        await waitForAppLaunch(name)
        activateApp(appConfig.bundleId)
        logger.info("应用已成功启动并激活: \(appConfig.displayName)")
        return .success(())
    }
    
    /// 等待应用启动
    private static func waitForAppLaunch(_ appName: String) async {
        logger.info("等待应用启动: \(appName)")
        try? await Task.sleep(nanoseconds: Constants.Timing.appLaunchWait)
        
        if isAppRunning(appName) {
            logger.info("应用已成功启动: \(appName)")
        } else {
            logger.info("再次检测应用状态: \(appName)")
            try? await Task.sleep(nanoseconds: Constants.Timing.appLaunchCheckInterval)
            
            if isAppRunning(appName) {
                logger.info("应用延迟启动成功: \(appName)")
            } else {
                logger.warning("应用可能启动失败但命令已执行: \(appName)")
            }
        }
    }
    
    /// 激活应用到前台
    private static func activateApp(_ bundleId: String) {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            if #available(macOS 14.0, *) {
                app.activate()
            } else {
                app.activate(options: .activateIgnoringOtherApps)
            }
            logger.info("应用已激活到前台: \(bundleId)")
        }
    }
    
    /// 执行系统命令并返回退出码
    private static func executeProcess(_ executablePath: String, arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
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
            HTTPResponseHandler.sendBadRequest(connection, message: "Bad Request")
            return
        }
        
        MediaController.logger.info("收到请求: \(path)")
  
        if path == "/" || path == "/index.html" {
            HTTPResponseHandler.sendHTML(connection, generateHTML())
        } else if path.hasPrefix("/api/") {
            handleAPI(path: path, connection: connection)
        } else if path.hasPrefix("/assets/") {
            serveAsset(path: path, connection: connection)
        } else {
            MediaController.logger.warning("未找到路径: \(path)")
            HTTPResponseHandler.sendNotFound(connection)
        }
    }
    
    /// 处理 API 请求
    private func handleAPI(path: String, connection: NWConnection) {
        Task {
            let action = String(path.dropFirst(5))
            MediaController.logger.info("处理API动作: \(action)")
            
            if !Constants.APIAction.noPermissionRequired.contains(action) && 
               !MediaController.checkInputMonitoringPermission() {
                let json = HTTPResponseHandler.buildJSONResponse(status: "failed", error: "缺少辅助功能权限")
                HTTPResponseHandler.sendJSON(connection, json)
                return
            }
            
            let (result, error) = await handleAPIAction(action)
            let json = HTTPResponseHandler.buildJSONResponse(status: result, error: error)
            HTTPResponseHandler.sendJSON(connection, json)
        }
    }
    
    /// 处理具体的 API 动作
    private func handleAPIAction(_ action: String) async -> (result: String, error: String?) {
        switch action {
        case "space": _ = await MediaController.playPause()
        case "next": _ = await MediaController.nextTrack()
        case "prev": _ = await MediaController.previousTrack()
        case "volumeup": _ = await MediaController.volumeUp()
        case "volumedown": _ = await MediaController.volumeDown()
        case "mute": _ = await MediaController.toggleMute()
        case "arrowup": _ = await MediaController.arrowUp()
        case "arrowdown": _ = await MediaController.arrowDown()
            
        case "lock":
            return await handleLockAction()
            
        case "lock_status":
            let isLocked = MediaController.isScreenLocked()
            return (isLocked ? "locked" : "unlocked", nil)
            
        case "toggle_douyin":
            return await handleAppToggle("douyin", displayName: "抖音")
            
        case "toggle_qishui":
            return await handleAppToggle("qishui", displayName: "汽水音乐")
            
        case "status_douyin":
            return (MediaController.isAppRunning("douyin") ? "running" : "stopped", nil)
            
        case "status_qishui":
            return (MediaController.isAppRunning("qishui") ? "running" : "stopped", nil)
            
        case "test_apps":
            let douyinRunning = MediaController.isAppRunning("douyin")
            let qishuiRunning = MediaController.isAppRunning("qishui")
            return ("douyin:\(douyinRunning ? "running" : "stopped"),qishui:\(qishuiRunning ? "running" : "stopped")", nil)
            
        default:
            MediaController.logger.warning("未知API操作: \(action)")
            return ("unknown", "未知操作: \(action)")
        }
        
        return ("success", nil)
    }
    
    /// 处理锁屏动作
    private func handleLockAction() async -> (result: String, error: String?) {
        let isLocked = MediaController.isScreenLocked()
        if isLocked {
            return ("failed", "屏幕已锁定，无法通过软件唤醒")
        } else {
            let lockResult = await MediaController.smartLockOrLogin()
            if case .success = lockResult {
                return ("lock_success", nil)
            } else {
                return ("failed", "锁屏失败")
            }
        }
    }
    
    /// 处理应用切换动作
    private func handleAppToggle(_ appName: String, displayName: String) async -> (result: String, error: String?) {
        let wasRunning = MediaController.isAppRunning(appName)
        MediaController.logger.info("\(displayName)切换前状态: \(wasRunning ? "运行中" : "未运行")")
        
        let toggleResult = await MediaController.toggleApp(displayName)
        if case .success = toggleResult {
            let result = wasRunning ? "closed" : "opened"
            MediaController.logger.info("\(displayName)切换操作完成，结果: \(result)")
            return (result, nil)
        } else {
            return ("failed", "操作失败")
        }
    }

    private func serveAsset(path: String, connection: NWConnection) {
        let filename = String(path.dropFirst(8))
        MediaController.logger.info("请求资源: \(filename)")
        
        guard let fileURL = findAssetFile(filename) else {
            MediaController.logger.error("未找到资源文件: \(filename)")
            HTTPResponseHandler.sendNotFound(connection, message: "Asset Not Found")
            return
        }
        
        guard let data = try? Data(contentsOf: fileURL) else {
            HTTPResponseHandler.sendNotFound(connection, message: "Asset Read Error")
            return
        }
        
        let contentType = getContentType(for: fileURL.pathExtension)
        HTTPResponseHandler.sendDataResponse(connection, code: 200, data: data, contentType: contentType)
    }
    
    /// 查找资源文件
    private func findAssetFile(_ filename: String) -> URL? {
        if let resourcePath = Bundle.main.resourcePath {
            let assetsPath = URL(fileURLWithPath: resourcePath)
                .appendingPathComponent("assets")
                .appendingPathComponent(filename)
            
            if FileManager.default.fileExists(atPath: assetsPath.path) {
                MediaController.logger.info("在assets目录找到文件: \(assetsPath.path)")
                return assetsPath
            }
        }
        
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        if let path = Bundle.main.path(forResource: name, ofType: ext) {
            MediaController.logger.info("在Bundle根目录找到文件: \(path)")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    /// 获取内容类型
    private func getContentType(for ext: String) -> String {
        switch ext.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "svg": return "image/svg+xml"
        default: return "application/octet-stream"
        }
    }
    
    private func generateHTML() -> String {
        if let filepath = Bundle.main.path(forResource: "index", ofType: "html"),
           let content = try? String(contentsOfFile: filepath, encoding: .utf8) {
            return content
        }
        
        MediaController.logger.error("未找到 index.html 资源文件")
        return fallbackHTML
    }
    
    private var fallbackHTML: String {
        """
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
