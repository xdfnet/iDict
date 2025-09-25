//
//  iDictApp.swift
//  应用程序入口文件，定义主应用结构和菜单栏配置。
//  连接AppDelegate并配置菜单栏样式和外部事件处理。
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
    /// 由于使用了MenuBarController来管理状态栏，这里返回一个空的场景。
    /// 所有的菜单栏交互都通过MenuBarController处理。
    var body: some Scene {
        // 返回一个空的窗口组，因为我们使用MenuBarController管理状态栏
        WindowGroup {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)
    }
}