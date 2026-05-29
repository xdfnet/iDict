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
    private let translationServiceManager: TranslationServiceManager

    /// 翻译配置存储
    private let configStore: TranslationConfigStore

    /// 显示翻译窗口的回调
    var showTranslationWindow: ((String) -> Void)?

    /// 显示普通消息的回调
    var showMessage: ((String) -> Void)?

    // MARK: - 初始化

    init(configStore: TranslationConfigStore = TranslationConfigStore()) {
        self.configStore = configStore
        self.translationServiceManager = TranslationServiceManager(configStore: configStore)
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

        menu.addItem(createTranslationProviderMenu())
        menu.addItem(NSMenuItem.separator())

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

    /// 创建翻译服务菜单
    private func createTranslationProviderMenu() -> NSMenuItem {
        let providerItem = NSMenuItem(title: "Translation Provider", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let currentProvider = (try? configStore.loadOrCreate().provider) ?? TranslationConfig.defaultConfig.provider

        for provider in TranslationProvider.allCases {
            let item = NSMenuItem(
                title: provider.menuTitle,
                action: #selector(changeTranslationProvider(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = provider.rawValue
            item.state = provider == currentProvider ? .on : .off
            submenu.addItem(item)
        }

        providerItem.submenu = submenu
        return providerItem
    }

    // MARK: - 菜单事件处理

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func changeTranslationProvider(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let provider = TranslationProvider(rawValue: rawValue) else {
            return
        }

        do {
            try configStore.updateProvider(provider)
        } catch {
            showMessage?("切换翻译服务失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 翻译功能

    /// 执行翻译
    private func performTranslation(text: String) {
        Task {
            let result = await translationServiceManager.translateText(text)
            self.showTranslationWindow?(result)
            if let speechCommand = speechCommandForTranslationResult() {
                speakWithCommand(result, command: speechCommand)
            }
        }
    }

    private func speechCommandForTranslationResult() -> String? {
        let config = (try? configStore.loadOrCreate()) ?? TranslationConfig.defaultConfig
        guard config.speechEnabled else { return nil }

        let command = config.speechCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        return command.isEmpty ? nil : command
    }

    /// 执行快速翻译（供外部调用）
    func performQuickTranslation(text: String) {
        performTranslation(text: text)
    }

    /// 通过命令模板播放翻译结果（非阻塞，静默失败）
    /// 命令中的 {{text}} 会被替换为翻译文本
    private func speakWithCommand(_ text: String, command: String) {
        Task.detached {
            let escapedText = text.replacingOccurrences(of: "'", with: "'\\''")
            let commandString = command.replacingOccurrences(of: "{{text}}", with: "'\(escapedText)'")

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", commandString]
            try? process.run()
        }
    }

    /// 清理状态栏资源
    func cleanup() {
        if let statusBarItem = statusBarItem {
            NSStatusBar.system.removeStatusItem(statusBarItem)
            self.statusBarItem = nil
        }
    }
}
