//
//  SettingsManager.swift
//  设置管理器：负责管理用户配置和偏好设置
//
//  功能说明：
//  - 管理登录密码等敏感信息
//  - 提供配置的读取和写入功能
//  - 支持默认值和数据持久化
//

import Foundation
import SwiftUI
import Combine

// MARK: - 设置管理器

final class SettingsManager: ObservableObject {

    // MARK: - 单例

    static let shared = SettingsManager()

    // MARK: - 配置键

    private enum Keys {
        static let loginPassword = "loginPassword"
        static let autoLoginEnabled = "autoLoginEnabled"
        static let firstLaunch = "firstLaunch"
    }

    // MARK: - 默认值

    private enum Defaults {
        static let autoLoginEnabled = false  // 默认禁用自动登录以提高安全性
    }

    // MARK: - 发布的属性

    @Published var loginPassword: String {
        didSet {
            UserDefaults.standard.set(loginPassword, forKey: Keys.loginPassword)
        }
    }

    @Published var autoLoginEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoLoginEnabled, forKey: Keys.autoLoginEnabled)
        }
    }

    // MARK: - 初始化

    private init() {
        // 从UserDefaults读取设置
        self.loginPassword = UserDefaults.standard.string(forKey: Keys.loginPassword) ?? ""
        self.autoLoginEnabled = UserDefaults.standard.object(forKey: Keys.autoLoginEnabled) as? Bool ?? Defaults.autoLoginEnabled

        // 首次启动时的处理
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: Keys.firstLaunch)
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: Keys.firstLaunch)
            setupDefaultSettings()
        }
    }

    // MARK: - 公共方法

    /// 重置为默认设置
    func resetToDefaults() {
        loginPassword = ""
        autoLoginEnabled = Defaults.autoLoginEnabled
    }

    /// 检查是否设置了密码
    func hasPasswordSet() -> Bool {
        return !loginPassword.isEmpty
    }

    /// 验证密码格式
    func validatePassword(_ password: String) -> Bool {
        // 密码长度在4-20个字符之间
        return password.count >= 4 && password.count <= 20
    }

    /// 获取设置摘要（用于显示）
    func getSettingsSummary() -> String {
        return """
        登录密码: \(String(repeating: "•", count: loginPassword.count))
        自动登录: \(autoLoginEnabled ? "启用" : "禁用")
        """
    }

    // MARK: - 私有方法

    private func setupDefaultSettings() {
        // 首次启动时的默认设置
        loginPassword = ""
        autoLoginEnabled = Defaults.autoLoginEnabled
    }
}

// MARK: - 扩展：为MediaController提供的便捷接口

extension SettingsManager {

    /// 获取当前登录密码
    static func getCurrentPassword() -> String {
        return shared.loginPassword
    }

    /// 更新登录密码
    static func updatePassword(_ newPassword: String) -> Bool {
        guard shared.validatePassword(newPassword) else {
            return false
        }
        shared.loginPassword = newPassword
        return true
    }

    /// 检查自动登录是否启用
    static func isAutoLoginEnabled() -> Bool {
        return shared.autoLoginEnabled
    }

    /// 检查是否设置了密码
    static func hasPasswordSet() -> Bool {
        return shared.hasPasswordSet()
    }
}