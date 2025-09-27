//
//  UpdateManager.swift
//  iDict
//
//  极简更新管理器
//

import Foundation
import Cocoa
import UserNotifications

class UpdateManager {
    
    static func silentUpdate() {
        DispatchQueue.global().async {
            print("🚀 开始静默更新...")
            
            var updateResults: [String] = []
            var hasUpdates = false
            
            // 更新 Homebrew
            if let brew = which("brew") {
                let brewUpdateSuccess = run(brew, ["update", "--quiet"])
                let brewUpgradeSuccess = run(brew, ["upgrade", "--quiet"])
                
                if brewUpdateSuccess {
                    print("✅ Homebrew 更新成功")
                    updateResults.append("✅ Homebrew 更新成功")
                    hasUpdates = true
                } else {
                    print("❌ Homebrew 更新失败")
                }
                
                if brewUpgradeSuccess {
                    print("✅ 包升级成功")
                    updateResults.append("✅ 包升级成功")
                    hasUpdates = true
                } else {
                    print("ℹ️ 包已是最新")
                }
            } else {
                print("⚠️ 未找到 Homebrew")
            }
            
            // 更新 npm
            if let npm = which("npm") {
                let npmUpdateSuccess = run(npm, ["update", "-g", "--silent"])
                if npmUpdateSuccess {
                    print("✅ npm 更新成功")
                    updateResults.append("✅ npm 更新成功")
                    hasUpdates = true
                } else {
                    print("❌ npm 更新失败")
                }
            } else {
                print("⚠️ 未找到 npm")
            }
            
            print("🔄 静默更新完成")
            
            // 发送系统通知
            DispatchQueue.main.async {
                sendUpdateNotification(results: updateResults, hasUpdates: hasUpdates)
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
    
    private static func sendUpdateNotification(results: [String], hasUpdates: Bool) {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    let content = UNMutableNotificationContent()
                    content.title = "iDict 更新完成"
                    
                    if hasUpdates && !results.isEmpty {
                        content.body = results.joined(separator: "\n")
                        content.sound = .default
                    } else {
                        content.body = "所有包都已是最新版本"
                        content.sound = nil // 无更新时不播放声音
                    }
                    
                    // 创建通知请求
                    let request = UNNotificationRequest(
                        identifier: "iDict.update.completed",
                        content: content,
                        trigger: nil // 立即显示
                    )
                    
                    // 发送通知
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("发送通知失败: \(error.localizedDescription)")
                        } else {
                            print("📱 系统通知已发送")
                        }
                    }
                }
            } else {
                print("⚠️ 通知权限未授权")
            }
        }
    }

}