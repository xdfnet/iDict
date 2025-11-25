//
//  MediaController.swift
//  媒体控制文件，基于CoreGraphics实现媒体快捷键模拟和HTTP服务器
//

import Foundation
import Network
import Combine
import CoreGraphics
import ApplicationServices
import OSLog
import AppKit

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
    
    static func playPause() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.playPause) }
    static func nextTrack() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.nextTrack) }
    static func previousTrack() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.prevTrack) }
    static func volumeUp() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.volumeUp) }
    static func volumeDown() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.volumeDown) }
    static func toggleMute() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.mute) }
    static func arrowUp() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.arrowUp) }
    static func arrowDown() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.arrowDown) }
    static func lockScreen() async -> Result<Void, MediaControllerError> { await simulateLockScreen() }
    static func pressSpace() async -> Result<Void, MediaControllerError> { await simulateArrowKey(.space) }
    
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
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        // 使用完整路径而不是 -a 参数，因为某些应用（如汽水音乐）用 -a 无法正常启动
        let appPath = "/Applications/\(name).app"
        process.arguments = [appPath]
        
        // 捕获错误输出
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let exitCode = process.terminationStatus
            if exitCode == 0 {
                logger.info("成功打开应用: \(name), 路径: \(appPath), 退出码: \(exitCode)")
                return .success(())
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? "未知错误"
                logger.error("打开应用失败: \(name), 退出码: \(exitCode), 错误: \(errorOutput)")
                return .failure(.eventPostFailed)
            }
        } catch {
            logger.error("执行open命令失败: \(name), 错误: \(error.localizedDescription)")
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
                if MediaController.checkInputMonitoringPermission() { _ = await MediaController.lockScreen() }
                else { result = "failed"; error = "缺少辅助功能权限" }
            case "open_douyin": 
                MediaController.logger.info("尝试打开抖音")
                _ = await MediaController.openApp("抖音")
            case "open_qishui": 
                MediaController.logger.info("尝试打开汽水音乐")
                _ = await MediaController.openApp("汽水音乐")
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
                return try String(contentsOfFile: filepath)
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