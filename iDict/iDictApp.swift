//
//  iDictApp.swift
//  应用程序入口文件，定义主应用结构和菜单栏配置
//  连接AppDelegate并配置菜单栏样式和外部事件处理
//

import SwiftUI

/// 应用主入口，配置菜单栏应用。
///
/// 注意：菜单栏功能现在完全由AppDelegate中的MenuBarController管理，
/// 这里只保留基本的应用结构，不再使用MenuBarExtra。
@main
struct iDictApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// 应用的主场景定义。
    ///
    /// 返回空的场景体，所有功能都由 AppDelegate 处理
    var body: some Scene {
        // 空场景体，不创建任何窗口
        createEmptyScene()
    }
}

/// 创建完全隐藏的场景
private extension iDictApp {
    func createEmptyScene() -> some Scene {
        WindowGroup {
            Color.clear
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)
        .commandsRemoved()
    }
}