//
//  BorderlessWindow.swift
//  无边框窗口类：支持多种关闭方式和用户交互
//

import Cocoa

/// 支持多种关闭方式和用户交互的无边框窗口。
///
/// 功能特性：
/// - 点击窗口外部区域自动关闭
/// - 失去焦点时自动关闭
/// - 内存安全的事件监听器管理
class BorderlessWindow: NSWindow {
    
    // MARK: - 属性
    
    /// 全局鼠标事件监听器的引用，用于防止内存泄漏
    private var globalMouseMonitor: Any?
    
    // MARK: - 窗口焦点管理
    
    /// 允许窗口成为键盘焦点，接收键盘事件
    override var canBecomeKey: Bool {
        return true
    }
    
    /// 允许窗口成为应用程序的主窗口
    override var canBecomeMain: Bool {
        return true
    }
    
    // MARK: - 窗口生命周期
    
    /// 窗口即将成为主窗口时的处理
    override func becomeMain() {
        super.becomeMain()
        
        // 设置点击外部关闭功能
        setupClickOutsideToClose()
    }
    
    /// 窗口即将失去主窗口状态时的处理
    override func resignMain() {
        super.resignMain()
        
        // 失去焦点时自动关闭窗口
        close()
    }
    
    /// 窗口关闭时清理资源
    override func close() {
        // 清理事件监听器防止内存泄漏
        removeGlobalMouseMonitor()
        
        super.close()
    }
    
    // MARK: - 点击外部关闭功能
    
    /// 设置点击外部关闭功能
    private func setupClickOutsideToClose() {
        // 移除之前的监听器（如果存在）
        removeGlobalMouseMonitor()
        
        // 添加全局鼠标事件监听器，用于检测点击外部区域
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleGlobalMouseClick(event)
            }
        }
    }
    
    /// 移除全局鼠标事件监听器
    private func removeGlobalMouseMonitor() {
        guard let monitor = globalMouseMonitor else { return }
        
        NSEvent.removeMonitor(monitor)
        globalMouseMonitor = nil
    }
    
    /// 处理全局鼠标点击事件
    private func handleGlobalMouseClick(_ event: NSEvent) {
        let clickLocation = NSEvent.mouseLocation
        let windowFrame = frame
        
        // 检查点击位置是否在窗口外部
        if !windowFrame.contains(clickLocation) {
            close()
        }
    }
    
}
