//
//  UpdateManager.swift
//  iDict
//
//  简化的更新管理器
//

import Cocoa

class UpdateManager: NSObject {
    
    // MARK: - 回调
    var progressCallback: ((String) -> Void)?
    var completionCallback: ((Bool, String) -> Void)?
    
    // MARK: - 公共方法
    func checkAndUpdate() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performUpdate()
        }
    }
    
    // MARK: - 私有方法
    private func performUpdate() {
        updateProgress("🚀 开始检查更新...")
        
        var results: [String] = []
        var hasError = false
        
        // 更新 Homebrew
        if let brewPath = findCommand("brew") {
            updateProgress("🍺 更新 Homebrew...")
            if runCommand(brewPath, args: ["update", "--quiet"]) {
                results.append("✅ Homebrew 更新成功")
                if runCommand(brewPath, args: ["upgrade", "--quiet"]) {
                    results.append("✅ Homebrew 包升级成功")
                }
            } else {
                results.append("❌ Homebrew 更新失败")
                hasError = true
            }
        } else {
            results.append("⚠️ 未找到 Homebrew")
        }
        
        // 更新 npm
        if let npmPath = findCommand("npm") {
            updateProgress("🟢 更新 npm 包...")
            if runCommand(npmPath, args: ["update", "-g", "--silent"]) {
                results.append("✅ npm 包更新成功")
            } else {
                results.append("❌ npm 包更新失败")
                hasError = true
            }
        } else {
            results.append("⚠️ 未找到 npm")
        }
        
        // 完成回调
        let message = results.joined(separator: "\n")
        DispatchQueue.main.async { [weak self] in
            self?.completionCallback?(!hasError, message)
        }
    }
    
    private func findCommand(_ command: String) -> String? {
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
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {}
        
        return nil
    }
    
    private func runCommand(_ path: String, args: [String]) -> Bool {
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
    
    private func updateProgress(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.progressCallback?(message)
        }
    }
}