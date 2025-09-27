//
//  UpdateManager.swift
//  iDict
//
//  极简更新管理器
//

import Foundation
import Cocoa

class UpdateManager {
    
    static func silentUpdate() {
        DispatchQueue.global().async {
            print("🚀 开始静默更新...")
            
            // 更新 Homebrew
            if let brew = which("brew") {
                let brewUpdateSuccess = run(brew, ["update", "--quiet"])
                let brewUpgradeSuccess = run(brew, ["upgrade", "--quiet"])
                print(brewUpdateSuccess ? "✅ Homebrew 更新成功" : "❌ Homebrew 更新失败")
                print(brewUpgradeSuccess ? "✅ 包升级成功" : "ℹ️ 包已是最新")
            } else {
                print("⚠️ 未找到 Homebrew")
            }
            
            // 更新 npm
            if let npm = which("npm") {
                let npmUpdateSuccess = run(npm, ["update", "-g", "--silent"])
                print(npmUpdateSuccess ? "✅ npm 更新成功" : "❌ npm 更新失败")
            } else {
                print("⚠️ 未找到 npm")
            }
            
            print("🔄 静默更新完成")
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
    

}