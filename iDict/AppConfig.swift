//
//  AppConfig.swift
//  应用配置管理类
//

import Foundation

/// 应用配置管理类，统一管理支持的应用配置信息
struct AppConfig {

    // MARK: - 应用配置结构

    struct App {
        let displayName: String      // 显示名称（中文）
        let systemName: String       // 系统名称（英文/Bundle ID中的名称）
        let path: String            // 应用路径
        let bundleId: String        // Bundle Identifier
    }

    // MARK: - 支持的应用

    /// 支持的应用映射（支持中文名称和系统名称）
    static let supportedApps: [String: App] = {
        let apps: [App] = [
            App(
                displayName: "抖音",
                systemName: "douyin",
                path: "/Applications/抖音.app",
                bundleId: "com.bytedance.douyin.desktop"
            ),
            App(
                displayName: "汽水音乐",
                systemName: "qishui",
                path: "/Applications/汽水音乐.app",
                bundleId: "com.soda.music"
            )
        ]

        var dict: [String: App] = [:]
        for app in apps {
            dict[app.systemName] = app
            dict[app.displayName] = app
        }
        return dict
    }()

    // MARK: - 查询方法

    /// 根据名称获取应用配置
    /// - Parameter name: 应用名称（支持中文和英文）
    /// - Returns: 应用配置，如果未找到则返回 nil
    static func getAppConfig(for name: String) -> App? {
        return supportedApps[name]
    }

    /// 获取应用的 Bundle ID
    /// - Parameter name: 应用名称
    /// - Returns: Bundle ID，如果未找到则返回默认值
    static func getBundleId(for name: String) -> String {
        return getAppConfig(for: name)?.bundleId ?? "com.unknown.\(name.lowercased())"
    }

    /// 获取应用路径
    /// - Parameter name: 应用名称
    /// - Returns: 应用路径，如果未找到则返回空字符串
    static func getAppPath(for name: String) -> String {
        return getAppConfig(for: name)?.path ?? ""
    }

    /// 获取应用显示名称
    /// - Parameter name: 应用名称
    /// - Returns: 显示名称，如果未找到则返回原始名称
    static func getDisplayName(for name: String) -> String {
        return getAppConfig(for: name)?.displayName ?? name
    }

    /// 检查应用是否受支持
    /// - Parameter name: 应用名称
    /// - Returns: 是否支持该应用
    static func isAppSupported(_ name: String) -> Bool {
        return supportedApps.keys.contains(name)
    }

    /// 获取所有支持的应用名称
    /// - Returns: 支持的应用名称列表
    static func getSupportedAppNames() -> [String] {
        return Array(supportedApps.keys)
    }

    /// 获取所有支持的应用配置
    /// - Returns: 应用配置列表（去重后的）
    static func getAllApps() -> [App] {
        let uniqueApps = Dictionary(grouping: supportedApps.values) { $0.bundleId }
        return Array(uniqueApps.values.compactMap { $0.first })
    }

    // MARK: - Bundle ID 常量（向后兼容）

    /// 登录窗口 Bundle ID（系统级）
    static let loginWindowBundleId = "com.apple.loginwindow"
}