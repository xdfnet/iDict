//
//  WindowPositionCalculator.swift
//  窗口位置计算工具类
//

import Foundation
import Cocoa

/// 窗口位置计算工具类，处理多显示器环境和窗口边界检查
struct WindowPositionCalculator {

    // MARK: - 主要计算方法

    /// 计算窗口在鼠标位置附近的最优显示位置
    /// - Parameters:
    ///   - windowWidth: 窗口宽度
    ///   - windowHeight: 窗口高度
    ///   - offsetFromMouse: 窗口距离鼠标的偏移量
    /// - Returns: 窗口在全局坐标系中的位置
    static func calculateWindowPosition(
        windowWidth: CGFloat,
        windowHeight: CGFloat,
        offsetFromMouse: CGFloat = 20
    ) -> NSRect {
        // 获取鼠标当前位置
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

        // 计算窗口位置，使窗口左下角在鼠标上方指定距离
        let windowX = adjustedMouseX  // 窗口左边缘对齐鼠标
        let windowY = adjustedMouseY + offsetFromMouse  // 窗口下边缘在鼠标上方

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

        return NSRect(
            x: globalX,
            y: globalY,
            width: windowWidth,
            height: windowHeight
        )
    }

    // MARK: - 辅助方法

    /// 获取鼠标所在的屏幕
    static func getMouseScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            let frame = screen.frame
            return mouseLocation.x >= frame.minX && mouseLocation.x <= frame.maxX &&
                   mouseLocation.y >= frame.minY && mouseLocation.y <= frame.maxY
        } ?? NSScreen.main
    }

    /// 检查给定屏幕是否为竖屏
    static func isPortraitScreen(_ screen: NSScreen) -> Bool {
        return screen.frame.height > screen.frame.width
    }
}