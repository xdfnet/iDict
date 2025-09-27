//
//  MenuBarController.swift
//  iDict
//
//  Created by iDict Team
//  Copyright © 2025 iDict App. All rights reserved.
//
//  菜单栏控制器：负责状态栏文本展示与菜单交互
//
//  功能说明：
//  - 展示翻译状态和快捷信息
//  - 构建并响应菜单项（翻译模式、语言选择、设置、关于、退出）
//  - 协调翻译服务与用户界面交互
//
import Cocoa
import SwiftUI
import Combine

// MARK: - 菜单栏控制器
class MenuBarController: NSObject, ObservableObject {
    
    // MARK: - 属性
    
    /// ObservableObject 协议要求
    let objectWillChange = ObservableObjectPublisher()
    
    /// UI 组件
    private var statusBarItem: NSStatusItem?
    
    /// 翻译服务管理器
    private let translationServiceManager: TranslationServiceManager
    
    /// 更新管理器
    private let updateManager: UpdateManager
    
    /// 显示翻译窗口的回调
    var showTranslationWindow: ((String) -> Void)?
    
    // MARK: - 初始化
    
    init(translationServiceManager: TranslationServiceManager) {
        self.translationServiceManager = translationServiceManager
        self.updateManager = UpdateManager()
        super.init()
        setupStatusBar()
        setupUpdateManager()
    }
    
    // MARK: - 生命周期管理
    
    func cleanup() {
        statusBarItem = nil
    }
    
    // MARK: - 私有方法
    
    /// 初始化状态栏按钮
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
    
    /// 设置更新管理器
    private func setupUpdateManager() {
        updateManager.progressCallback = { [weak self] message in
            DispatchQueue.main.async {
                self?.showUpdateProgress(message)
            }
        }
        
        updateManager.completionCallback = { [weak self] success, message in
            DispatchQueue.main.async {
                self?.showUpdateResult(success: success, message: message)
            }
        }
    }
    
    /// 点击状态栏按钮时动态创建菜单
    @objc private func statusBarButtonClicked() {
        statusBarItem?.menu = createMenu()
        statusBarItem?.button?.performClick(nil)
        statusBarItem?.menu = nil
    }
    
    /// 构建主菜单
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Translation Service Selection
        menu.addItem(createServiceSelectionMenu())
        menu.addItem(NSMenuItem.separator())
        
        // Update Menu
        menu.addItem(createUpdateMenu())
        menu.addItem(NSMenuItem.separator())
        
        // About
        menu.addItem(createAboutMenu())
        menu.addItem(NSMenuItem.separator())
        
        // Exit
        menu.addItem(createQuitMenu())
        
        return menu
    }
    
    /// 创建翻译服务选择菜单
    private func createServiceSelectionMenu() -> NSMenuItem {
        let serviceMenuItem = NSMenuItem(title: "Translation Service", action: nil, keyEquivalent: "")
        let serviceSubmenu = NSMenu()
        
        let currentService = translationServiceManager.currentServiceType
        
        for serviceType in TranslationServiceType.allCases {
            let menuItem = NSMenuItem(
                title: serviceType.displayName,
                action: #selector(selectTranslationService(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = serviceType
            
            // 设置当前选中的服务
            if serviceType == currentService {
                menuItem.state = .on
            }
            
            serviceSubmenu.addItem(menuItem)
        }
        
        serviceMenuItem.submenu = serviceSubmenu
        return serviceMenuItem
    }
    
    /// 创建更新菜单
    private func createUpdateMenu() -> NSMenuItem {
        let updateItem = NSMenuItem(title: "检查更新", action: #selector(checkForUpdates), keyEquivalent: "u")
        updateItem.target = self
        return updateItem
    }
    
    /// 选择翻译服务
    @objc private func selectTranslationService(_ sender: NSMenuItem) {
        guard let serviceType = sender.representedObject as? TranslationServiceType else { 
            print("❌ 无法获取服务类型")
            return 
        }
        
        // 确保在主线程执行服务切换
        Task { @MainActor in
            // 执行服务切换
            translationServiceManager.switchService(to: serviceType)
            print("✅ 已切换到: \(serviceType.displayName)")
            
            // 切换服务后重新创建菜单以更新选中状态
            statusBarItem?.menu = createMenu()
        }
    }
    


    
    /// 创建About菜单
    private func createAboutMenu() -> NSMenuItem {
        let aboutItem = NSMenuItem(title: "About", action: nil, keyEquivalent: "")
        let aboutSubmenu = NSMenu()
        
        // 从Info.plist读取版本信息
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let buildRaw = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        
        // 格式化构建号显示
        let formattedBuild = formatBuildNumber(buildRaw)
        
        // Version信息
        let versionItem = NSMenuItem(title: "Version: \(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        aboutSubmenu.addItem(versionItem)
        
        // Build信息
        let buildItem = NSMenuItem(title: "Build: \(formattedBuild)", action: nil, keyEquivalent: "")
        buildItem.isEnabled = false
        aboutSubmenu.addItem(buildItem)
        
        aboutItem.submenu = aboutSubmenu
        return aboutItem
    }
    
    /// 格式化构建号显示
    private func formatBuildNumber(_ buildNumber: String) -> String {
        // 如果是时间戳格式（14位数字），则格式化为可读格式
        if buildNumber.count == 14 && buildNumber.allSatisfy({ $0.isNumber }) {
            let year = String(buildNumber.prefix(4))
            let month = String(buildNumber.dropFirst(4).prefix(2))
            let day = String(buildNumber.dropFirst(6).prefix(2))
            let hour = String(buildNumber.dropFirst(8).prefix(2))
            let minute = String(buildNumber.dropFirst(10).prefix(2))
            let second = String(buildNumber.dropFirst(12).prefix(2))
            
            return "\(year).\(month).\(day) \(hour):\(minute):\(second)"
        }
        
        // 如果不是时间戳格式，直接返回原始值
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
    
    /// 检查更新
    @objc private func checkForUpdates() {
        // 显示开始更新的提示
        showUpdateProgress("🚀 开始检查软件包更新...")
        
        // 执行更新
        updateManager.checkAndUpdate()
    }
    
    /// 显示更新进度
    private func showUpdateProgress(_ message: String) {
        // 创建进度通知
        let notification = NSUserNotification()
        notification.title = "iDict 更新"
        notification.informativeText = message
        notification.soundName = nil
        
        NSUserNotificationCenter.default.deliver(notification)
        
        // 同时在控制台输出
        print("📱 iDict Update: \(message)")
    }
    
    /// 显示更新结果
    private func showUpdateResult(success: Bool, message: String) {
        let notification = NSUserNotification()
        notification.title = "iDict 更新"
        notification.informativeText = message
        notification.soundName = success ? NSUserNotificationDefaultSoundName : nil
        
        NSUserNotificationCenter.default.deliver(notification)
        
        // 显示弹窗确认
        let alert = NSAlert()
        alert.messageText = "软件包更新"
        alert.informativeText = message
        alert.alertStyle = success ? .informational : .warning
        alert.addButton(withTitle: "确定")
        
        if success {
            alert.icon = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Success")
        } else {
            alert.icon = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning")
        }
        
        alert.runModal()
    }
    
    // MARK: - 翻译功能
    
    /// 执行翻译
    private func performTranslation(text: String) {
        Task {
            let result = await translationServiceManager.translateText(text)
            
            DispatchQueue.main.async {
                self.showTranslationWindow?(result)
            }
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
