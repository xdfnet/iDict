//
//  AppDelegate.swift
//  应用代理、自定义窗口和交互视图
//

import SwiftUI
import Cocoa
@preconcurrency import ApplicationServices

// MARK: - 应用代理

/// 应用核心代理类：管理热键、翻译服务和 UI 显示
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - 属性

    /// 对当前显示的翻译窗口的引用，用于管理其生命周期。
    private var currentTranslationWindow: NSWindow?

    /// 菜单栏控制器
    private var menuBarController: MenuBarController?

    /// 全局热键管理器
    let hotKeyManager = HotKeyManager()

    /// 剪贴板管理器
    let clipboardManager = ClipboardManager()

    /// 辅助功能权限轮询任务
    private var permissionPollingTask: Task<Void, Never>?



    // MARK: - 生命周期
    
    /// 应用启动完成
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用为附件类型，不在Dock中显示图标。
        NSApp.setActivationPolicy(.accessory)

        // 初始化菜单栏控制器
        menuBarController = MenuBarController()

        // 设置翻译窗口显示回调
        menuBarController?.showTranslationWindow = { [weak self] message in
            Task { @MainActor in
                await self?.showTranslationResult(message)
            }
        }
        menuBarController?.showMessage = { [weak self] message in
            Task { @MainActor in
                await self?.showMessage(message)
            }
        }

        setupTranslationConfig()

        // 启动权限轮询 + 热键注册
        startHotKeyWithPermissionPolling()
    }
    
    // MARK: - 私有方法

    /// 初始化翻译配置文件
    private func setupTranslationConfig() {
        do {
            _ = try TranslationConfigStore().loadOrCreate()
        } catch {
            Task { @MainActor in
                await showMessage("翻译配置初始化失败: \(error.localizedDescription)")
            }
        }
    }

    /// 尝试注册热键，权限不足时启动轮询等待
    private func startHotKeyWithPermissionPolling() {
        Task { @MainActor in
            // 首次尝试：弹系统对话框请求权限
            if !PermissionManager.checkAccessibilityPermission() {
                PermissionManager.requestAccessibilityPermission()
            }

            // 尝试注册热键
            if await tryRegisterHotKey() { return }

            // 权限不足，启动轮询
            print("iDict: 等待辅助功能权限授权...")
            startPermissionPolling()
        }
    }

    /// 尝试注册热键，成功返回 true
    private func tryRegisterHotKey() async -> Bool {
        let result = await hotKeyManager.registerHotKey { [weak self] in
            Task { @MainActor in
                await self?.performQuickTranslation()
            }
        }
        if case .success = result {
            print("iDict: Cmd+D 热键已注册")
            permissionPollingTask?.cancel()
            permissionPollingTask = nil
            return true
        }
        return false
    }

    /// 轮询辅助功能权限，授权后自动注册热键
    private func startPermissionPolling() {
        permissionPollingTask?.cancel()
        permissionPollingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
                guard AXIsProcessTrustedWithOptions(options) else { continue }
                print("iDict: 辅助功能已授权，注册热键...")
                _ = await self.tryRegisterHotKey()
                return
            }
        }
    }
    
    /// 执行快速翻译流程
    private func performQuickTranslation() async {
        // 1. 模拟键盘 "Cmd+C" 复制命令。
        let copyResult = await KeyboardSimulator.simulateCopyCommand()
        if case .success = copyResult {
            // 短暂等待，确保剪贴板有时间更新。
            try? await Task.sleep(nanoseconds: AppConfig.Timing.copyDelay)
        }
        
        // 2. 从剪贴板获取文本。
        let clipboardResult = await clipboardManager.getClipboardText()
        guard case .success(let text) = clipboardResult else {
            await showMessage("剪贴板中没有英文文本或文本过长")
            return
        }
        
        // 3. 使用MenuBarController进行翻译（剪贴板文本已清理）
        menuBarController?.performQuickTranslation(text: text)
    }
    
    /// 显示翻译结果窗口
    private func showTranslationResult(_ message: String) async {
        await showMessage(message, reuseExistingWindow: true)
    }
    
    /// 显示消息窗口
    private func showMessage(_ message: String, reuseExistingWindow: Bool = false) async {
        // 确保UI操作在主线程上执行。
        await MainActor.run {
            // --- 1. 计算窗口和内容的尺寸 ---
            let font = NSFont.systemFont(ofSize: AppConfig.Window.fontSize)
            let maxWidth = AppConfig.Window.maxWidth
            let minWidth = AppConfig.Window.minWidth
            let padding = AppConfig.Window.padding
            
            // 使用一个临时的文本字段来测量渲染消息所需的尺寸。
            let tempLabel = NSTextField(labelWithString: message)
            tempLabel.font = font
            tempLabel.lineBreakMode = .byWordWrapping
            tempLabel.maximumNumberOfLines = 0 // 允许多行
            
            // 计算文本在给定最大宽度下的实际尺寸。
            let textSize = tempLabel.sizeThatFits(NSSize(width: maxWidth - padding, height: .greatestFiniteMagnitude))
            let textWidth = max(minWidth - padding, min(maxWidth - padding, textSize.width))
            let textHeight = textSize.height
            
            // 根据文本尺寸和边距计算最终的窗口尺寸。
            let windowWidth = textWidth + padding
            let windowHeight = textHeight + padding
            
            // --- 2. 复用或创建窗口 ---
            let window: BorderlessWindow
            let windowFrame = WindowPositionCalculator.calculateWindowPosition(
                windowWidth: windowWidth,
                windowHeight: windowHeight,
                offsetFromMouse: AppConfig.Window.offsetFromMouse
            )

            if reuseExistingWindow, let existingWindow = currentTranslationWindow as? BorderlessWindow {
                // 复用现有窗口（用于翻译结果）
                window = existingWindow
                window.setFrame(windowFrame, display: true, animate: true)
            } else if let existingWindow = currentTranslationWindow as? BorderlessWindow {
                // 创建新窗口（用于普通消息）
                window = existingWindow
                window.setFrame(windowFrame, display: true, animate: true)
            } else {
                // 创建新窗口
                window = BorderlessWindow(
                    contentRect: windowFrame,
                    styleMask: [.borderless], // 无边框样式
                    backing: .buffered,
                    defer: false
                )

                // 配置窗口属性
                window.isReleasedWhenClosed = false // 关闭时不释放，以便复用
                window.backgroundColor = .clear     // 背景透明
                window.isOpaque = false             // 窗口不透明
                window.hasShadow = true             // 显示阴影
                window.level = .floating            // 窗口置于顶层
                window.hidesOnDeactivate = true     // 应用失活时隐藏窗口
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // 允许在全屏应用中显示

                // 保存窗口引用
                currentTranslationWindow = window
            }
            
            // --- 3. 创建和配置自定义内容视图 ---
            let contentView = ClickableContentView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = NSColor(
                red: AppConfig.Color.backgroundRed,
                green: AppConfig.Color.backgroundGreen,
                blue: AppConfig.Color.backgroundBlue,
                alpha: AppConfig.Window.backgroundAlpha
            ).cgColor
            contentView.layer?.cornerRadius = AppConfig.Window.cornerRadius
            contentView.targetWindow = window // 关联父窗口
            
            // --- 4. 创建并添加文本标签 ---
            let textLabel = NSTextField(labelWithString: message)
            textLabel.frame = NSRect(x: padding / 2, y: padding / 2, width: textWidth, height: textHeight)
            textLabel.font = font
            textLabel.alignment = .left
            textLabel.isEditable = false
            textLabel.isBordered = false
            textLabel.backgroundColor = .clear
            textLabel.textColor = .white
            textLabel.lineBreakMode = .byWordWrapping
            textLabel.maximumNumberOfLines = 0
            textLabel.isSelectable = true
            contentView.addSubview(textLabel)
            
            // 更新窗口内容视图
            window.contentView = contentView
            
            // --- 5. 显示窗口并激活 ---
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true) // 强制激活应用
            
            // 异步确保窗口成为焦点
            DispatchQueue.main.async {
                window.makeKey()
                window.makeFirstResponder(contentView)
            }
        }
    }
    
    /// 应用即将终止时清理资源
    func applicationWillTerminate(_ notification: Notification) {
        permissionPollingTask?.cancel()
        permissionPollingTask = nil

        // 关闭翻译窗口
        currentTranslationWindow?.close()
        currentTranslationWindow = nil
    }
}
