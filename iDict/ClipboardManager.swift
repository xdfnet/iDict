//
//  ClipboardManager.swift
//  系统剪贴板管理文件，提供文本读取和验证功能
//  实现剪贴板内容获取、长度检查和语言检测机制
//

import AppKit

/// 一个工具类，用于与系统剪贴板（`NSPasteboard`）交互。
/// 
/// 此类负责从系统剪贴板安全地读取和验证文本内容，包括长度检查和语言检测。
/// 主要用于获取用户选中的文本进行翻译处理。
@MainActor
class ClipboardManager {
    
    // MARK: - 属性
    
    /// 使用翻译服务基类中定义的最大文本长度，避免重复定义。
    private let maxTextLength: Int = 5000
    
    // MARK: - 公共方法
    
    /// 获取并验证剪贴板文本是否符合翻译要求。
    ///
    /// 执行以下验证步骤：
    /// 1. 检查剪贴板中是否存在有效文本内容
    /// 2. 验证文本长度限制
    ///
    /// - Returns: 成功时返回处理后的文本，失败时返回对应的错误信息
    func getClipboardText() async -> Result<String, ClipboardError> {
        let pasteboard = NSPasteboard.general

        // 步骤1：检查剪贴板中是否存在字符串内容
        guard let text = pasteboard.string(forType: .string) else {
            return .failure(.emptyOrNonText)
        }

        // 步骤2：清理和规范化文本内容（去除首尾空白、清理连续空格）
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmedText.components(separatedBy: .whitespaces)
        let normalizedText = components.filter { !$0.isEmpty }.joined(separator: " ")

        // 步骤3：检查清理后的文本是否为空
        guard !normalizedText.isEmpty else {
            return .failure(.emptyOrNonText)
        }

        // 步骤4：检查文本长度是否超出限制
        guard normalizedText.count <= self.maxTextLength else {
            return .failure(.textTooLong)
        }

        return .success(normalizedText)
    }
}

// MARK: - 错误类型

/// 定义了在访问剪贴板时可能发生的特定错误。
enum ClipboardError: LocalizedError {
    case emptyOrNonText
    case textTooLong

    var errorDescription: String? {
        switch self {
        case .emptyOrNonText:
            return "剪贴板中没有文本内容。"
        case .textTooLong:
            return "选中文本过长，请缩短后再试。"
        }
    }
}
