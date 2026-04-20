//
//  MenuBarController.swift
//  菜单栏控制器
//

import Cocoa
import Foundation

// MARK: - 菜单栏控制器

/// 状态栏图标和菜单管理
class MenuBarController: NSObject {

    // MARK: - 属性

    /// 状态栏项
    private var statusBarItem: NSStatusItem?

    /// 翻译服务管理器
    private let translationServiceManager: TranslationServiceManager = TranslationServiceManager()

    /// 显示翻译窗口的回调
    var showTranslationWindow: ((String) -> Void)?

    /// 显示消息的回调
    var showMessage: ((String) -> Void)?

    // MARK: - 初始化

    override init() {
        super.init()
        setupStatusBar()
    }

    // MARK: - 生命周期

    func cleanup() {
        statusBarItem = nil
    }

    // MARK: - 私有方法

    /// 初始化状态栏
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusBarItem?.button {
            button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
            button.action = #selector(statusBarButtonClicked)
            button.target = self

            // 设置图标
            if let image = NSImage(systemSymbolName: "translate", accessibilityDescription: "Translate") {
                image.size = NSSize(width: 16, height: 16)
                button.image = image
            }
        }
    }

    /// 点击状态栏时创建菜单
    @objc private func statusBarButtonClicked() {
        statusBarItem?.menu = createMenu()
        statusBarItem?.button?.performClick(nil)
        statusBarItem?.menu = nil
    }

    /// 构建主菜单
    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // 版本信息（一级菜单）
        menu.addItem(createVersionMenu())
        menu.addItem(createBuildMenu())
        menu.addItem(NSMenuItem.separator())

        // 退出
        menu.addItem(createQuitMenu())

        return menu
    }

    /// 创建版本菜单
    private func createVersionMenu() -> NSMenuItem {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let versionItem = NSMenuItem(title: "Version: \(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        return versionItem
    }

    /// 创建构建号菜单
    private func createBuildMenu() -> NSMenuItem {
        let bundle = Bundle.main
        let buildRaw = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        let formattedBuild = formatBuildNumber(buildRaw)
        let buildItem = NSMenuItem(title: "Build: \(formattedBuild)", action: nil, keyEquivalent: "")
        buildItem.isEnabled = false
        return buildItem
    }

    /// 格式化构建号显示
    private func formatBuildNumber(_ buildNumber: String) -> String {
        if buildNumber.count == 14 && buildNumber.allSatisfy({ $0.isNumber }) {
            let year = String(buildNumber.prefix(4))
            let month = String(buildNumber.dropFirst(4).prefix(2))
            let day = String(buildNumber.dropFirst(6).prefix(2))
            let hour = String(buildNumber.dropFirst(8).prefix(2))
            let minute = String(buildNumber.dropFirst(10).prefix(2))
            let second = String(buildNumber.dropFirst(12).prefix(2))
            return "\(year).\(month).\(day) \(hour):\(minute):\(second)"
        }
        return buildNumber
    }

    /// 创建Exit菜单
    private func createQuitMenu() -> NSMenuItem {
        let quitItem = NSMenuItem(title: "Exit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        return quitItem
    }

    // MARK: - 菜单事件处理

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - 翻译功能

    /// 执行翻译
    private func performTranslation(text: String) {
        Task {
            let result = await translationServiceManager.translateTextWithFallback(text)
            self.showTranslationWindow?(result)
        }
    }
}

// MARK: - 公共接口

extension MenuBarController {

    /// 执行快速翻译（供外部调用）
    func performQuickTranslation(text: String) {
        performTranslation(text: text)
    }
}