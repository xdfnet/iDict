//
//  AppDelegate.swift
//  应用代理、自定义窗口和交互视图
//

import SwiftUI
import Cocoa

// MARK: - 自定义UI组件导入
// 窗口相关类已分离到独立文件以提高可维护性

// MARK: - 常量定义

private enum Constants {
    /// 窗口相关常量
    enum Window {
        static let maxWidth: CGFloat = 600
        static let minWidth: CGFloat = 200
        static let padding: CGFloat = 40
        static let offsetFromMouse: CGFloat = 20
        static let cornerRadius: CGFloat = 10
        static let backgroundAlpha: CGFloat = 0.95
        static let fontSize: CGFloat = 14
    }
    
    /// 时间相关常量
    enum Timing {
        static let copyDelay: UInt64 = 150_000_000 // 150ms
    }
    
    /// 颜色相关常量
    enum Color {
        static let backgroundRed: CGFloat = 0.2
        static let backgroundGreen: CGFloat = 0.2
        static let backgroundBlue: CGFloat = 0.2
    }
}

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
    
    /// 翻译服务管理器
    let translationServiceManager = TranslationServiceManager()
    
    /// 媒体控制 HTTP 服务器
    private let mediaHTTPServer = MediaHTTPServer()



    // MARK: - 生命周期
    
    /// 应用启动完成
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用为附件类型，不在Dock中显示图标。
        NSApp.setActivationPolicy(.accessory)
        
        // 初始化菜单栏控制器，传递共享的翻译服务管理器
        menuBarController = MenuBarController(translationServiceManager: translationServiceManager)
        
        // 设置翻译窗口显示回调
        menuBarController?.showTranslationWindow = { [weak self] message in
            Task { @MainActor in
                await self?.showMessage(message)
            }
        }
        
        // 设置消息显示回调
        menuBarController?.showMessage = { [weak self] message in
            Task { @MainActor in
                await self?.showMessage(message)
            }
        }
        
        // 异步任务，设置全局热键。
        Task {
            await setupHotKey()
        }
        
        // 启动媒体控制HTTP服务器
        setupMediaControlServer()

    }
    
    // MARK: - 私有方法
    
    /// 设置全局翻译热键
    private func setupHotKey() async {
        let registrationResult = await hotKeyManager.registerHotKey {
            // 当热键被触发时，在主线程上执行翻译流程。
            Task { @MainActor in
                await self.performQuickTranslation()
            }
        }
        
        // 如果热键注册失败，显示错误信息。
        if case .failure(let error) = registrationResult {
            await showMessage("快捷键注册失败: \(error.localizedDescription)")
        }
    }
    
    /// 设置媒体控制服务器
    private func setupMediaControlServer() {
        let result = mediaHTTPServer.start()
        
        switch result {
        case .success:
            print("✅ 媒体控制服务器启动成功")
            if let url = mediaHTTPServer.serverURL {
                print("🌐 访问地址: \(url)")
                // 显示服务器地址给用户
                Task { @MainActor in
                    await showMessage("媒体控制服务器已启动\n访问地址: \(url)")
                }
            }
        case .failure(let error):
            print("❌ 媒体控制服务器启动失败: \(error.localizedDescription)")
            Task { @MainActor in
                await showMessage("媒体控制服务器启动失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 执行快速翻译流程
    private func performQuickTranslation() async {
        // 1. 模拟键盘 "Cmd+C" 复制命令。
        let copyResult = await KeyboardSimulator.simulateCopyCommand()
        if case .success = copyResult {
            // 短暂等待，确保剪贴板有时间更新。
            try? await Task.sleep(nanoseconds: Constants.Timing.copyDelay)
        }
        
        // 2. 从剪贴板获取文本。
        let clipboardResult = await clipboardManager.getClipboardText()
        guard case .success(let text) = clipboardResult else {
            await showMessage("剪贴板中没有英文文本或文本过长")
            return
        }
        
        // 3. 使用MenuBarController进行翻译
        // MenuBarController会处理翻译逻辑和结果显示
        menuBarController?.performQuickTranslation(text: text)
    }
    
    /// 显示消息窗口
    private func showMessage(_ message: String) async {
        // 确保UI操作在主线程上执行。
        await MainActor.run {
            // --- 1. 计算窗口和内容的尺寸 ---
            let font = NSFont.systemFont(ofSize: Constants.Window.fontSize)
            let maxWidth = Constants.Window.maxWidth
            let minWidth = Constants.Window.minWidth
            let padding = Constants.Window.padding
            
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
                offsetFromMouse: Constants.Window.offsetFromMouse
            )

            if let existingWindow = currentTranslationWindow as? BorderlessWindow {
                // 复用现有窗口
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
                window.hidesOnDeactivate = false    // 应用失活时不清空

                // 保存窗口引用
                currentTranslationWindow = window
            }
            
            // --- 3. 创建和配置自定义内容视图 ---
            let contentView = ClickableContentView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = NSColor(
                red: Constants.Color.backgroundRed,
                green: Constants.Color.backgroundGreen,
                blue: Constants.Color.backgroundBlue,
                alpha: Constants.Window.backgroundAlpha
            ).cgColor
            contentView.layer?.cornerRadius = Constants.Window.cornerRadius
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
        // 关闭翻译窗口
        currentTranslationWindow?.close()
        currentTranslationWindow = nil
        
        // 停止媒体控制服务器
        mediaHTTPServer.stop()
    }
}
