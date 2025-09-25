//
//  ClipboardManager.swift
//  系统剪贴板管理文件，提供文本读取和验证功能。
//  实现剪贴板内容获取、长度检查和语言检测机制。
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
    func getClipboardText() async -> Result<String, ClipboardError> {
        let pasteboard = NSPasteboard.general
        
        // 1. 检查剪贴板中是否存在字符串内容。
        guard let text = pasteboard.string(forType: .string) else {
            return .failure(.emptyOrNonText)
        }
        
        // 2. 清理字符串首尾的空白和换行符。
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanText.isEmpty {
            return .failure(.emptyOrNonText)
        }
        
        // 3. 检查文本长度是否超出限制。
        if cleanText.count > self.maxTextLength {
            return .failure(.textTooLong)
        }
        
        // 4. 检查文本是否主要由英文字符组成，以避免翻译非英文内容。
        let englishCharCount = cleanText.filter { $0.isLetter && $0.isASCII }.count
        let totalCharCount = cleanText.count
        
        // 如果文本总字符数大于0，计算英文字符比例。
        if totalCharCount > 0 {
            let englishRatio = Double(englishCharCount) / Double(totalCharCount)
            // 如果英文字符比例低于50%，则认为不是有效的翻译对象。
            if englishRatio <= 0.5 {
                return .failure(.notEnglishText)
            }
        }
        
        return .success(cleanText)
    }
}

// MARK: - 错误类型

/// 定义了在访问剪贴板时可能发生的特定错误。
enum ClipboardError: LocalizedError {
    case emptyOrNonText
    case textTooLong
    case notEnglishText
    
    var errorDescription: String? {
        switch self {
        case .emptyOrNonText:
            return "剪贴板中没有文本内容。"
        case .textTooLong:
            return "选中文本过长，请缩短后再试。"
        case .notEnglishText:
            return "选中文本似乎不是英文，暂不支持。"
        }
    }
}
