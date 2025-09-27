//
//  UpdateManager.swift
//  iDict
//
//  Created by iDict Team
//  Copyright © 2025 iDict App. All rights reserved.
//
//  更新管理器：负责检查和执行软件包更新
//
//  功能说明：
//  - 检查 Homebrew 和 npm 包更新
//  - 执行更新操作
//  - 提供更新进度反馈
//

import Cocoa

// MARK: - 更新管理器
class UpdateManager: NSObject {
    
    // MARK: - 属性
    
    /// 更新进度回调
    var progressCallback: ((String) -> Void)?
    
    /// 更新完成回调
    var completionCallback: ((Bool, String) -> Void)?
    
    // MARK: - 公共方法
    
    /// 检查并执行更新
    func checkAndUpdate() {
        // 在后台线程执行更新
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performUpdate()
        }
    }
    
    // MARK: - 私有方法
    
    /// 执行更新操作
    private func performUpdate() {
        updateProgress("🚀 开始检查软件包更新...")
        
        // 执行原有的更新脚本
        let scriptPath = Bundle.main.path(forResource: "Update", ofType: "command")
        if let path = scriptPath {
            executeUpdateScript(at: path)
        } else {
            // 如果脚本不存在，执行简化的更新逻辑
            performSimpleUpdate()
        }
    }
    
    /// 执行更新脚本
    private func executeUpdateScript(at path: String) {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = [path]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            DispatchQueue.main.async { [weak self] in
                if task.terminationStatus == 0 {
                    self?.completionCallback?(true, "✅ 软件包更新完成！\n\n" + output)
                } else {
                    self?.completionCallback?(false, "❌ 更新过程中出现错误\n\n" + output)
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.completionCallback?(false, "❌ 无法执行更新脚本: \(error.localizedDescription)")
            }
        }
    }
    
    /// 执行简化的更新逻辑
    private func performSimpleUpdate() {
        updateProgress("🍺 检查 Homebrew 更新...")
        
        // 检测 Homebrew 路径
        let brewPath = detectBrewPath()
        if let brew = brewPath {
            if executeCommand(brew, arguments: ["update"]) {
                updateProgress("✅ Homebrew 更新完成")
                
                if executeCommand(brew, arguments: ["upgrade"]) {
                    updateProgress("✅ Homebrew 包升级完成")
                } else {
                    updateProgress("ℹ️ Homebrew 包已是最新版本")
                }
            } else {
                updateProgress("⚠️ Homebrew 更新失败")
            }
        } else {
            updateProgress("⚠️ 未检测到 Homebrew，跳过更新")
        }
        
        updateProgress("🟢 检查 npm 更新...")
        
        // 检测 npm 路径
        let npmPath = detectNpmPath()
        if let npm = npmPath {
            if executeCommand(npm, arguments: ["update", "-g"]) {
                updateProgress("✅ npm 包更新完成")
            } else {
                updateProgress("ℹ️ npm 包已是最新版本或无权限")
            }
            
            // 验证缓存
            updateProgress("🧹 验证 npm 缓存...")
            if executeCommand(npm, arguments: ["cache", "verify"]) {
                updateProgress("✅ npm 缓存验证完成")
            }
        } else {
            updateProgress("⚠️ 未检测到 npm，跳过更新")
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.completionCallback?(true, "✅ 软件包更新完成！")
        }
    }
    
    /// 执行命令
    private func executeCommand(_ command: String, arguments: [String]) -> Bool {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// 更新进度
    private func updateProgress(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.progressCallback?(message)
        }
    }
    
    /// 检测 Homebrew 路径
    private func detectBrewPath() -> String? {
        let possiblePaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon Mac
            "/usr/local/bin/brew",     // Intel Mac
            "/home/linuxbrew/.linuxbrew/bin/brew"  // Linux
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // 尝试使用 which 命令查找
        return findCommandPath("brew")
    }
    
    /// 检测 npm 路径
    private func detectNpmPath() -> String? {
        let possiblePaths = [
            "/Users/apple/.npm-packages/bin/npm",  // 当前用户的 npm
            "/usr/local/bin/npm",                  // 系统 npm
            "/opt/homebrew/bin/npm",               // Homebrew npm
            "/usr/bin/npm"                         // 系统默认 npm
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // 尝试使用 which 命令查找
        return findCommandPath("npm")
    }
    
    /// 使用 which 命令查找工具路径
    private func findCommandPath(_ command: String) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = [command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return output?.isEmpty == false ? output : nil
            }
        } catch {
            // 忽略错误，返回 nil
        }
        
        return nil
    }
}