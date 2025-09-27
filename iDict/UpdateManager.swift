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

import Foundation
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
        
        // 检查 Homebrew 是否安装
        guard isHomebrewInstalled() else {
            updateProgress("⚠️ 未检测到 Homebrew，跳过 Homebrew 更新")
            checkNpmUpdates()
            return
        }
        
        // 更新 Homebrew
        updateHomebrew()
        
        // 更新 npm 包
        checkNpmUpdates()
        
        // 完成
        DispatchQueue.main.async { [weak self] in
            self?.completionCallback?(true, "✅ 软件包更新完成！")
        }
    }
    
    /// 检查 Homebrew 是否安装
    private func isHomebrewInstalled() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["brew"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// 更新 Homebrew
    private func updateHomebrew() {
        updateProgress("🍺 正在更新 Homebrew...")
        
        // 更新 Homebrew 本身
        if executeCommand("/opt/homebrew/bin/brew", arguments: ["update"]) {
            updateProgress("✅ Homebrew 索引更新完成")
        } else {
            updateProgress("❌ Homebrew 索引更新失败")
            return
        }
        
        // 检查过期包
        let outdatedPackages = getOutdatedBrewPackages()
        if outdatedPackages.isEmpty {
            updateProgress("✅ 所有 Homebrew 包已是最新版本")
        } else {
            updateProgress("📦 发现 \(outdatedPackages.count) 个待更新的包")
            
            // 升级包
            if executeCommand("/opt/homebrew/bin/brew", arguments: ["upgrade"]) {
                updateProgress("✅ Homebrew 包升级完成")
                
                // 清理旧版本
                if executeCommand("/opt/homebrew/bin/brew", arguments: ["cleanup"]) {
                    updateProgress("🧹 Homebrew 清理完成")
                }
            } else {
                updateProgress("❌ Homebrew 包升级失败")
            }
        }
    }
    
    /// 获取过期的 Homebrew 包
    private func getOutdatedBrewPackages() -> [String] {
        let task = Process()
        task.launchPath = "/opt/homebrew/bin/brew"
        task.arguments = ["outdated", "--quiet"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        } catch {
            return []
        }
    }
    
    /// 检查并更新 npm 包
    private func checkNpmUpdates() {
        updateProgress("🟢 正在检查 npm 全局包...")
        
        // 检查 npm 是否安装
        guard isNpmInstalled() else {
            updateProgress("⚠️ 未检测到 npm，跳过 npm 更新")
            return
        }
        
        // 获取过期的 npm 包
        let outdatedPackages = getOutdatedNpmPackages()
        if outdatedPackages.isEmpty {
            updateProgress("✅ 所有 npm 全局包已是最新版本")
        } else {
            updateProgress("📦 发现 \(outdatedPackages.count) 个待更新的 npm 包")
            
            // 逐个更新包
            for package in outdatedPackages {
                updateProgress("🔄 正在更新: \(package)")
                if executeCommand("/usr/local/bin/npm", arguments: ["install", "-g", "\(package)@latest"]) {
                    updateProgress("✅ \(package) 更新成功")
                } else {
                    updateProgress("❌ \(package) 更新失败")
                }
            }
        }
        
        // 验证 npm 缓存
        updateProgress("🧹 正在验证 npm 缓存...")
        if executeCommand("/usr/local/bin/npm", arguments: ["cache", "verify"]) {
            updateProgress("✅ npm 缓存验证完成")
        } else {
            updateProgress("⚠️ npm 缓存验证出现问题")
        }
    }
    
    /// 检查 npm 是否安装
    private func isNpmInstalled() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["npm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// 获取过期的 npm 包
    private func getOutdatedNpmPackages() -> [String] {
        let task = Process()
        task.launchPath = "/usr/local/bin/npm"
        task.arguments = ["outdated", "-g", "--parseable"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // 解析输出，提取包名
            return output.components(separatedBy: .newlines)
                .compactMap { line in
                    let components = line.components(separatedBy: ":")
                    return components.count > 1 ? components[1].components(separatedBy: "/").last : nil
                }
                .filter { !$0.isEmpty }
        } catch {
            return []
        }
    }
    
    /// 执行命令
    private func executeCommand(_ command: String, arguments: [String]) -> Bool {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
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
}