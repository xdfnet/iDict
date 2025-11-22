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
    }
    
    static func playPause() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.playPause) }
    static func nextTrack() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.nextTrack) }
    static func previousTrack() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.prevTrack) }
    static func volumeUp() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.volumeUp) }
    static func volumeDown() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.volumeDown) }
    static func toggleMute() async -> Result<Void, MediaControllerError> { await simulateMediaKey(.mute) }
    
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
        
        if path == "/" || path == "/index.html" {
            sendHTML(connection, generateHTML())
        } else if path.hasPrefix("/api/") {
            handleAPI(path: path, connection: connection)
        } else {
            send(connection, 404, "Not Found")
        }
    }
    
    private func handleAPI(path: String, connection: NWConnection) {
        Task {
            let action = String(path.dropFirst(5))
            var result = "success"
            var error: String?
            
            guard MediaController.checkInputMonitoringPermission() else {
                result = "failed"
                error = "缺少辅助功能权限"
                sendJSON(connection, "{\"status\":\"\(result)\",\"error\":\"\(error!)\"}")
                return
            }
            
            switch action {
            case "playpause": _ = await MediaController.playPause()
            case "next": _ = await MediaController.nextTrack()
            case "prev": _ = await MediaController.previousTrack()
            case "volumeup": _ = await MediaController.volumeUp()
            case "volumedown": _ = await MediaController.volumeDown()
            case "mute": _ = await MediaController.toggleMute()
            default: result = "unknown"; error = "未知操作"
            }
            
            let json = error != nil ? "{\"status\":\"\(result)\",\"error\":\"\(error!)\"}" : "{\"status\":\"\(result)\"}"
            sendJSON(connection, json)
        }
    }
    
    private func send(_ conn: NWConnection, _ code: Int, _ body: String, type: String = "text/plain") {
        let status = ["200": "OK", "400": "Bad Request", "404": "Not Found"]["\(code)"] ?? "Error"
        let response = "HTTP/1.1 \(code) \(status)\r\nContent-Type: \(type); charset=UTF-8\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
        conn.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
    }
    
    private func sendHTML(_ conn: NWConnection, _ html: String) { send(conn, 200, html, type: "text/html") }
    private func sendJSON(_ conn: NWConnection, _ json: String) { send(conn, 200, json, type: "application/json") }
    
    private func generateHTML() -> String {
        """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
            <meta name="apple-mobile-web-app-capable" content="yes">
            <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
            <title>iDict Remote</title>
            <style>
                *{margin:0;padding:0;box-sizing:border-box}
                body{font-family:-apple-system,sans-serif;background:linear-gradient(180deg,#1c1c1e,#000);color:#fff;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;-webkit-user-select:none;user-select:none;-webkit-tap-highlight-color:transparent;padding:env(safe-area-inset-top,20px) env(safe-area-inset-right,20px) env(safe-area-inset-bottom,20px) env(safe-area-inset-left,20px)}
                .container{width:100%;max-width:380px;padding:40px 28px;background:rgba(28,28,30,.75);backdrop-filter:blur(30px);-webkit-backdrop-filter:blur(30px);border-radius:32px;box-shadow:0 12px 48px rgba(0,0,0,.6);border:1px solid rgba(255,255,255,.12)}
                h1{font-size:18px;font-weight:600;color:rgba(235,235,245,.65);text-align:center;letter-spacing:1.5px;text-transform:uppercase;margin-bottom:40px}
                .main-controls{display:flex;flex-direction:column;align-items:center;gap:28px;margin-bottom:40px}
                .play-row{display:flex;justify-content:center;align-items:center;gap:36px}
                .volume{display:flex;flex-direction:column;gap:20px}
                .volume-row{display:flex;justify-content:space-between;align-items:center;background:rgba(0,0,0,.3);padding:18px 24px;border-radius:18px;gap:20px}
                button{background:none;border:none;cursor:pointer;color:#fff;transition:all .15s cubic-bezier(.4,0,.2,1);display:flex;align-items:center;justify-content:center;border-radius:50%;-webkit-tap-highlight-color:transparent;touch-action:manipulation}
                button:active{transform:scale(.88);opacity:.75}
                .play{width:100px;height:100px;background:#fff;color:#000;box-shadow:0 6px 24px rgba(255,255,255,.4)}
                .play:active{background:rgba(255,255,255,.85)}
                .secondary{width:68px;height:68px;background:rgba(255,255,255,.12)}
                .secondary:active{background:rgba(255,255,255,.22)}
                .volume-row button{width:60px;height:60px;background:rgba(255,255,255,.1)}
                .volume-row button:active{background:rgba(255,255,255,.2)}
                svg{fill:currentColor;filter:drop-shadow(0 2px 6px rgba(0,0,0,.25))}
                .toast{position:fixed;top:env(safe-area-inset-top,0);left:0;right:0;padding:16px;text-align:center;font-size:14px;font-weight:500;background:rgba(10,132,255,.95);color:#fff;transform:translateY(-100%);transition:transform .3s cubic-bezier(.4,0,.2,1);z-index:1000;backdrop-filter:blur(12px)}
                .toast.show{transform:translateY(0)}
                .toast.error{background:rgba(255,69,58,.95)}
            </style>
        </head>
        <body>
            <div id="toast" class="toast">已发送</div>
            <div class="container">
                <h1>iDict Remote</h1>
                <div class="main-controls">
                    <button class="secondary" onclick="send('prev')" aria-label="上一曲"><svg width="30" height="30" viewBox="0 0 24 24"><path d="M6 6h2v12H6zm3.5 6l8.5 6V6z"/></svg></button>
                    <div class="play-row">
                        <button class="play" onclick="send('playpause')" aria-label="播放/暂停"><svg width="44" height="44" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg></button>
                    </div>
                    <button class="secondary" onclick="send('next')" aria-label="下一曲"><svg width="30" height="30" viewBox="0 0 24 24"><path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"/></svg></button>
                </div>
                <div class="volume">
                    <div class="volume-row">
                        <button onclick="send('volumedown')" aria-label="减小音量"><svg width="26" height="26" viewBox="0 0 24 24"><path d="M18.5 12c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM5 9v6h4l5 5V4L9 9H5z"/></svg></button>
                        <button onclick="send('mute')" aria-label="静音"><svg width="26" height="26" viewBox="0 0 24 24"><path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73 4.27 3zM12 4L9.91 6.09 12 8.18V4z"/></svg></button>
                        <button onclick="send('volumeup')" aria-label="增加音量"><svg width="26" height="26" viewBox="0 0 24 24"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg></button>
                    </div>
                </div>
            </div>
            <script>
                let t;
                async function send(a){
                    if(navigator.vibrate)navigator.vibrate(10);
                    show('发送中...');
                    try{
                        const r=await fetch('/api/'+a);
                        const d=await r.json();
                        show(d.status==='success'?'成功':'失败',d.status!=='success');
                    }catch(e){show('错误',true)}
                }
                function show(m,e){
                    const el=document.getElementById('toast');
                    el.textContent=m;
                    el.className=e?'toast error show':'toast show';
                    clearTimeout(t);
                    t=setTimeout(()=>el.className=e?'toast error':'toast',2000);
                }
                document.addEventListener('gesturestart',e=>e.preventDefault());
            </script>
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