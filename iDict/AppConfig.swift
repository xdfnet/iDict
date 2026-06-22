//
//  AppConfig.swift
//  应用配置管理类
//

import Foundation
import Cocoa

/// 应用配置管理类，统一管理支持的应用配置信息和全局常量
struct AppConfig {

    // MARK: - 窗口常量

    enum Window {
        static let maxWidth: CGFloat = 600
        static let minWidth: CGFloat = 50
        static let padding: CGFloat = 20
        static let offsetFromMouse: CGFloat = 20
        static let cornerRadius: CGFloat = 10
        static let backgroundAlpha: CGFloat = 0.95
        static let fontSize: CGFloat = 14
    }

    // MARK: - 颜色常量

    enum Color {
        static let backgroundRed: CGFloat = 0.2
        static let backgroundGreen: CGFloat = 0.2
        static let backgroundBlue: CGFloat = 0.2
    }

    // MARK: - 时间常量

    enum Timing {
        static let copyDelay: UInt64 = 50_000_000 // 50ms
        static let keyPressInterval: UInt64 = 2_000_000 // 2ms
    }

    // MARK: - 剪贴板常量

    enum Clipboard {
        static let maxTextLength = 5000
    }

    // MARK: - 翻译常量

    enum Translation {
        static let sourceLanguage = "en"
        static let targetLanguage = "zh"
    }
}
