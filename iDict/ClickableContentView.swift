//
//  ClickableContentView.swift
//  iDict
//
//  Created by iDict Team
//  Copyright © 2025 iDict App. All rights reserved.
//
//  可交互内容视图：支持拖拽和焦点管理
//

import Cocoa

/// 支持拖拽和焦点管理的可交互内容视图。
class ClickableContentView: NSView {
    /// 父窗口引用。
    weak var targetWindow: NSWindow?
    
    /// 拖拽状态标记。
    private var isDragging = false
    /// 拖拽起始位置。
    private var lastMouseLocation: NSPoint = .zero
    
    /// 激活窗口并准备拖拽。
    override func mouseDown(with event: NSEvent) {
        // 激活窗口，使其成为焦点
        targetWindow?.makeKey()
        targetWindow?.makeFirstResponder(self)
        
        // 记录拖拽起始点
        isDragging = true
        lastMouseLocation = event.locationInWindow
        
        super.mouseDown(with: event)
    }
    
    /// 根据鼠标移动更新窗口位置。
    override func mouseDragged(with event: NSEvent) {
        if isDragging, let window = targetWindow {
            let currentLocation = event.locationInWindow
            let deltaX = currentLocation.x - lastMouseLocation.x
            let deltaY = currentLocation.y - lastMouseLocation.y
            
            var newOrigin = window.frame.origin
            newOrigin.x += deltaX
            newOrigin.y += deltaY
            
            window.setFrameOrigin(newOrigin)
        }
        
        super.mouseDragged(with: event)
    }
    
    /// 当鼠标释放时，结束拖拽状态。
    /// 
    /// - Parameter event: 鼠标释放事件
    override func mouseUp(with event: NSEvent) {
        isDragging = false
        super.mouseUp(with: event)
    }
    
    /// 允许此视图成为第一响应者，以接收键盘和鼠标事件。
    /// 
    /// - Returns: 始终返回true，允许视图接收事件
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    /// 设置跟踪区域，以监听鼠标进入和退出事件。
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // 移除旧的跟踪区域，避免重复添加
        trackingAreas.forEach { removeTrackingArea($0) }
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    /// 当鼠标进入视图区域时，自动激活窗口。
    /// 
    /// - Parameter event: 鼠标进入事件
    override func mouseEntered(with event: NSEvent) {
        targetWindow?.makeKey()
        targetWindow?.makeFirstResponder(self)
        super.mouseEntered(with: event)
    }
}
