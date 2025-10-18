//
//  AppDelegate.swift
//  应用程序主要组件文件，包含应用代理、自定义窗口和交互视图。
//  实现全局热键监听、剪贴板文本翻译和结果展示功能。
//

import SwiftUI
import Cocoa

// MARK: - 自定义UI组件导入
// 窗口相关类已分离到独立文件以提高可维护性

// MARK: - 应用主代理

/// 应用的核心代理类，负责协调所有服务和UI组件。
/// 
/// 此类管理应用的生命周期，包括热键注册、翻译服务调用和UI显示。
/// 主要功能包括：
/// - 全局热键管理
/// - 剪贴板文本获取
/// - 翻译服务调用
/// - 翻译结果窗口显示
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - 属性
    
    /// 对当前显示的翻译窗口的引用，用于管理其生命周期。
    private var currentTranslationWindow: NSWindow?
    
    /// 菜单栏控制器 - 管理状态栏菜单和翻译功能
    private var menuBarController: MenuBarController?
    
    /// 负责注册和监听全局热键。
    let hotKeyManager = HotKeyManager()
    
    /// 负责从系统剪贴板读取文本。
    let clipboardManager = ClipboardManager()
    
    /// 负责执行文本翻译。
    let translationServiceManager = TranslationServiceManager()
    


    // MARK: - NSApplicationDelegate 生命周期
    
    /// 当应用完成启动后调用。
    /// 
    /// - Parameter notification: 应用启动完成的通知对象
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
        
        // 异步任务，设置全局热键。
        Task {
            await setupHotKey()
        }
        

    }
    
    // MARK: - 私有核心逻辑
    
    /// 设置全局翻译热键。
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
    
    /// 执行完整的快速翻译流程。
    /// 
    /// 该方法包含三个主要步骤：
    /// 1. 模拟Cmd+C复制当前选中的文本
    /// 2. 从剪贴板获取复制的文本
    /// 3. 调用MenuBarController进行翻译并显示翻译结果
    private func performQuickTranslation() async {
        // 1. 模拟键盘 "Cmd+C" 复制命令。
        let copyResult = await KeyboardSimulator.simulateCopyCommand()
        if case .success = copyResult {
            // 短暂等待，确保剪贴板有时间更新。
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
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
    
    /// 以自定义的无边框窗口显示消息。
    /// 
    /// 复用同一个无边框浮动窗口来显示翻译结果，避免每次翻译都创建新窗口。
    /// 窗口会自动调整大小以适应文本内容，并在鼠标点击时自动关闭。
    /// 
    /// - Parameter message: 要显示的消息文本
    private func showMessage(_ message: String) async {
        // 确保UI操作在主线程上执行。
        await MainActor.run {
            // --- 1. 计算窗口和内容的尺寸 ---
            let font = NSFont.systemFont(ofSize: 14)
            let maxWidth: CGFloat = 600  // 窗口最大宽度
            let minWidth: CGFloat = 200  // 窗口最小宽度
            let padding: CGFloat = 40    // 窗口内部左右边距之和
            
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
            _ = NSSize(width: windowWidth, height: windowHeight)
            
            // --- 2. 复用或创建窗口 ---
            let window: BorderlessWindow
            if let existingWindow = currentTranslationWindow as? BorderlessWindow {
                // 复用现有窗口
                window = existingWindow
                
                // 获取鼠标当前位置并在鼠标上方显示窗口
                let mouseLocation = NSEvent.mouseLocation
                
                // 获取鼠标所在的屏幕（支持多显示器环境）
                let mouseScreen = NSScreen.screens.first { screen in
                    let frame = screen.frame
                    return mouseLocation.x >= frame.minX && mouseLocation.x <= frame.maxX &&
                           mouseLocation.y >= frame.minY && mouseLocation.y <= frame.maxY
                } ?? NSScreen.main
                
                
                let visibleScreenFrame = mouseScreen?.visibleFrame ?? NSRect.zero
                let screenFrame = mouseScreen?.frame ?? NSRect.zero
                
                // 将鼠标位置从全局坐标转换为当前屏幕坐标
                let adjustedMouseX = mouseLocation.x - screenFrame.origin.x
                let adjustedMouseY = mouseLocation.y - screenFrame.origin.y
                
                // 检测屏幕方向（竖屏或横屏）
                let isPortrait = screenFrame.height > screenFrame.width
                
                // 计算窗口位置，使其显示在鼠标上方，留出一些间距
                let offsetFromMouse: CGFloat = 20  // 窗口与鼠标的间距
                let windowX = adjustedMouseX - windowWidth / 2  // 水平居中于鼠标
                let windowY = adjustedMouseY + offsetFromMouse  // 在鼠标上方
                
                // 确保窗口不会超出屏幕边界
                var finalX = max(0, min(windowX, visibleScreenFrame.width - windowWidth))
                var finalY = max(0, min(windowY, visibleScreenFrame.height - windowHeight))
                
                // 针对竖屏显示器的特殊处理
                if isPortrait {
                    // 在竖屏上，如果窗口会超出顶部，则显示在鼠标下方
                    if windowY > visibleScreenFrame.height - windowHeight {
                        finalY = adjustedMouseY - windowHeight - offsetFromMouse
                        // 确保不会超出底部
                        finalY = max(0, finalY)
                    }
                    
                    // 在竖屏上，如果窗口会超出左右边界，则调整水平位置
                    if windowX < 0 {
                        finalX = 0
                    } else if windowX > visibleScreenFrame.width - windowWidth {
                        finalX = visibleScreenFrame.width - windowWidth
                    }
                }
                
                
                // 计算窗口在全局坐标系中的位置
                let globalX = finalX + screenFrame.origin.x
                let globalY = finalY + screenFrame.origin.y
                
                let newFrame = NSRect(
                    x: globalX,
                    y: globalY,
                    width: windowWidth,
                    height: windowHeight
                )
                window.setFrame(newFrame, display: true, animate: true)
            } else {
                // 创建新窗口
                window = BorderlessWindow(
                    contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
                    styleMask: [.borderless], // 无边框样式
                    backing: .buffered,
                    defer: false
                )
                
                // 获取鼠标当前位置并在鼠标上方显示窗口
                let mouseLocation = NSEvent.mouseLocation
                
                // 获取鼠标所在的屏幕（支持多显示器环境）
                let mouseScreen = NSScreen.screens.first { screen in
                    let frame = screen.frame
                    return mouseLocation.x >= frame.minX && mouseLocation.x <= frame.maxX &&
                           mouseLocation.y >= frame.minY && mouseLocation.y <= frame.maxY
                } ?? NSScreen.main
                
                
                let visibleScreenFrame = mouseScreen?.visibleFrame ?? NSRect.zero
                let screenFrame = mouseScreen?.frame ?? NSRect.zero
                
                // 将鼠标位置从全局坐标转换为当前屏幕坐标
                let adjustedMouseX = mouseLocation.x - screenFrame.origin.x
                let adjustedMouseY = mouseLocation.y - screenFrame.origin.y
                
                
                // 检测屏幕方向（竖屏或横屏）
                let isPortrait = screenFrame.height > screenFrame.width
                
                // 计算窗口位置，使其显示在鼠标上方，留出一些间距
                let offsetFromMouse: CGFloat = 20  // 窗口与鼠标的间距
                let windowX = adjustedMouseX - windowWidth / 2  // 水平居中于鼠标
                let windowY = adjustedMouseY + offsetFromMouse  // 在鼠标上方
                
                // 确保窗口不会超出屏幕边界
                var finalX = max(0, min(windowX, visibleScreenFrame.width - windowWidth))
                var finalY = max(0, min(windowY, visibleScreenFrame.height - windowHeight))
                
                // 针对竖屏显示器的特殊处理
                if isPortrait {
                    // 在竖屏上，如果窗口会超出顶部，则显示在鼠标下方
                    if windowY > visibleScreenFrame.height - windowHeight {
                        finalY = adjustedMouseY - windowHeight - offsetFromMouse
                        // 确保不会超出底部
                        finalY = max(0, finalY)
                    }
                    
                    // 在竖屏上，如果窗口会超出左右边界，则调整水平位置
                    if windowX < 0 {
                        finalX = 0
                    } else if windowX > visibleScreenFrame.width - windowWidth {
                        finalX = visibleScreenFrame.width - windowWidth
                    }
                }
                
                
                // 计算窗口在全局坐标系中的位置
                let globalX = finalX + screenFrame.origin.x
                let globalY = finalY + screenFrame.origin.y
                
                let mouseFrame = NSRect(
                    x: globalX,
                    y: globalY,
                    width: windowWidth,
                    height: windowHeight
                )
                window.setFrame(mouseFrame, display: true)
                
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
            contentView.layer?.backgroundColor = NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.95).cgColor
            contentView.layer?.cornerRadius = 10
            contentView.targetWindow = window // 关联父窗口
            
            // --- 4. 创建并添加文本标签 ---
            let textLabel = NSTextField(labelWithString: message)
            textLabel.frame = NSRect(x: padding / 2, y: padding / 2, width: textWidth, height: textHeight)
            textLabel.font = font
            textLabel.alignment = .center
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
    }
}
