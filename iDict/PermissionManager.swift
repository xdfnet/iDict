//
//  PermissionManager.swift
//  统一权限管理工具类
//

import Foundation
import ApplicationServices

/// 权限管理工具类，统一处理辅助功能和输入监控权限
struct PermissionManager {

    // MARK: - 权限检查

    /// 检查辅助功能权限
    static func checkAccessibilityPermission() -> Bool {
        let options: [String: Any] = ["AXTrustedCheckOptionPrompt": false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - 权限请求

    /// 请求辅助功能权限
    static func requestAccessibilityPermission() {
        let options: [String: Any] = ["AXTrustedCheckOptionPrompt": true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - 权限状态描述

    /// 获取权限状态的描述信息
    static func getPermissionStatusDescription() -> String {
        if checkAccessibilityPermission() {
            return "已获得辅助功能权限"
        } else {
            return "缺少辅助功能权限，请前往\"系统设置\" > \"隐私与安全性\" > \"辅助功能\"启用权限"
        }
    }
}