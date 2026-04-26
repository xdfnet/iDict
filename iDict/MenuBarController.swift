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

    // MARK: - 初始化

    override init() {
        super.init()
        setupStatusBar()
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

        // 版本信息
        menu.addItem(createVersionMenu())
        menu.addItem(createBuildMenu())
        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(title: "Exit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

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
        let buildItem = NSMenuItem(title: "Build: \(buildRaw)", action: nil, keyEquivalent: "")
        buildItem.isEnabled = false
        return buildItem
    }

    // MARK: - 菜单事件处理

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - 翻译功能

    /// 执行翻译
    private func performTranslation(text: String) {
        Task {
            let result = await translationServiceManager.translateText(text)
            self.showTranslationWindow?(result)
        }
    }

    /// 执行快速翻译（供外部调用）
    func performQuickTranslation(text: String) {
        performTranslation(text: text)
    }
}
