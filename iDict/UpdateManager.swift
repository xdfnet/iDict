//
//  UpdateManager.swift
//  iDict
//
//  极简更新管理器
//

import Foundation
import Cocoa

class UpdateManager {
    
    static func update() {
        DispatchQueue.global().async {
            var message = "🚀 开始更新...\n"
            
            // 更新 Homebrew
            if let brew = which("brew") {
                message += run(brew, ["update"]) ? "✅ Homebrew 更新成功\n" : "❌ Homebrew 更新失败\n"
                message += run(brew, ["upgrade"]) ? "✅ 包升级成功\n" : "ℹ️ 包已是最新\n"
            } else {
                message += "⚠️ 未找到 Homebrew\n"
            }
            
            // 更新 npm
            if let npm = which("npm") {
                message += run(npm, ["update", "-g"]) ? "✅ npm 更新成功\n" : "❌ npm 更新失败\n"
            } else {
                message += "⚠️ 未找到 npm\n"
            }
            
            DispatchQueue.main.async {
                showAlert(message)
            }
        }
    }
    
    private static func which(_ cmd: String) -> String? {
        // 常见的命令路径
        let commonPaths = [
            "/usr/bin/\(cmd)",
            "/usr/local/bin/\(cmd)",
            "/opt/homebrew/bin/\(cmd)",
            "/Users/\(NSUserName())/.npm-packages/bin/\(cmd)",
            "/Users/\(NSUserName())/.local/bin/\(cmd)"
        ]
        
        // 检查每个路径是否存在可执行文件
        for path in commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        // 如果常见路径都没找到，尝试使用 which 命令
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = [cmd]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {}
        
        return nil
    }
    
    private static func run(_ path: String, _ args: [String]) -> Bool {
        let task = Process()
        task.launchPath = path
        task.arguments = args
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private static func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "更新完成"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}