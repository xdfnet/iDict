//
//  BaseTranslationService.swift
//  iDict
//
//  Created by iDict Team
//  Copyright © 2025 iDict App. All rights reserved.
//
//  翻译服务基类：提供通用的文本验证和错误处理
//

import Foundation

/// 翻译服务基类
/// 
/// 此类提供翻译服务的通用功能，包括文本验证和错误处理
/// 具体的翻译服务应该继承此类并实现具体的翻译逻辑
class BaseTranslationService: TranslationServiceProtocol {
    
    // MARK: - TranslationServiceProtocol 实现
    
    var serviceType: TranslationServiceType {
        fatalError("子类必须重写此属性")
    }
    
    var isAvailable: Bool {
        return serviceType.isAvailable
    }
    
    // MARK: - 属性
    
    /// 定义了可接受的最大文本长度
    let maxTextLength: Int = 5000
    
    // MARK: - 公共方法
    
    /// 翻译给定的文本
    /// - Parameter text: 要翻译的源文本
    /// - Returns: 翻译后的目标文本
    /// - Throws: 如果文本无效或翻译失败，则抛出 `TranslationError`
    func translateText(_ text: String) async throws -> String {
        try validateText(text)
        return try await performTranslation(text)
    }
    
    // MARK: - 受保护的方法（子类可重写）
    
    /// 执行具体的翻译逻辑
    /// - Parameter text: 要翻译的文本
    /// - Returns: 翻译结果
    /// - Throws: 翻译错误
    func performTranslation(_ text: String) async throws -> String {
        fatalError("子类必须实现此方法")
    }
    
    // MARK: - 私有方法
    
    /// 验证文本是否有效
    /// - Parameter text: 要验证的文本
    /// - Throws: 如果文本无效，抛出 `TranslationError.invalidTextLength`
    private func validateText(_ text: String) throws {
        guard !text.isEmpty && text.count <= maxTextLength else {
            throw TranslationError.invalidTextLength
        }
    }
}
