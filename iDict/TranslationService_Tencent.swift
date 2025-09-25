//
//  TencentTranslationService.swift
//  iDict
//
//  Created by iDict Team
//  Copyright © 2025 iDict App. All rights reserved.
//
//  腾讯翻译君服务实现
//  注意：腾讯翻译君API将于2025年4月15日关闭
//

import Foundation

/// 腾讯翻译君服务实现
/// 
/// 此类负责调用腾讯翻译君API执行文本翻译
/// 注意：该服务将于2025年4月15日关闭
@MainActor
class TranslationService_Tencent: TranslationServiceProtocol {
    
    // MARK: - TranslationServiceProtocol 实现
    
    var serviceType: TranslationServiceType {
        return .tencent
    }
    
    var isAvailable: Bool {
        return serviceType.isAvailable
    }
    
    // MARK: - 属性
    
    /// 定义了可接受的最大文本长度
    private let maxTextLength: Int = 5000
    
    // MARK: - 初始化
    
    init() {
        // 腾讯翻译君使用公开接口，无需API密钥
    }
    
    // MARK: - 公共方法
    
    /// 翻译给定的文本
    /// - Parameter text: 要翻译的源文本
    /// - Returns: 翻译后的目标文本
    /// - Throws: 如果文本无效或翻译失败，则抛出 `TranslationError`
    func translateText(_ text: String) async throws -> String {
        guard !text.isEmpty && text.count <= maxTextLength else {
            throw TranslationError.invalidTextLength
        }
        
        guard isAvailable else {
            throw TranslationError.serviceUnavailable("腾讯翻译君")
        }
        
        return try await performTencentTranslation(text)
    }
    
    // MARK: - 私有网络与解析
    
    /// 执行对腾讯翻译君接口的网络请求
    /// 
    /// - Parameter text: 需要翻译的文本内容
    /// - Returns: 翻译后的文本
    /// - Throws: 网络错误或解析错误
    private func performTencentTranslation(_ text: String) async throws -> String {
        // 构建请求URL
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://fanyi.qq.com/api/translate") else {
            throw TranslationError.apiError(message: "无法构建请求URL")
        }
        
        // 创建POST请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("https://fanyi.qq.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        // 构建请求体
        let postData = "source=auto&target=zh&sourceText=\(encodedText)"
        request.httpBody = postData.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return try parseTencentResponse(data: data, response: response)
        } catch {
            throw TranslationError.networkError(error)
        }
    }
    
    /// 解析腾讯翻译君API响应
    /// 
    /// - Parameters:
    ///   - data: 响应数据
    ///   - response: HTTP响应
    /// - Returns: 翻译结果
    /// - Throws: 解析错误
    private func parseTencentResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TranslationError.apiError(message: "HTTP请求失败")
        }
        
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let translate = jsonObject["translate"] as? [String: Any],
               let records = translate["records"] as? [[String: Any]],
               let firstRecord = records.first,
               let targetText = firstRecord["targetText"] as? String {
                
                guard !targetText.isEmpty else {
                    throw TranslationError.emptyResult
                }
                
                return targetText
            } else {
                throw TranslationError.apiError(message: "无法解析响应数据")
            }
        } catch {
            throw TranslationError.apiError(message: "JSON解析失败: \(error.localizedDescription)")
        }
    }
}