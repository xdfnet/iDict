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
class TranslationService_Tencent: BaseTranslationService {
    
    // MARK: - TranslationServiceProtocol 实现
    
    override var serviceType: TranslationServiceType {
        return .tencent
    }
    
    override var isAvailable: Bool {
        let isAvailable = super.isAvailable
        if !isAvailable {
            print("⚠️ 警告：腾讯翻译君API已于2025年4月15日关闭")
        }
        return isAvailable
    }
    
    // MARK: - 初始化

    @MainActor
    override init() {
        // 腾讯翻译君使用公开接口，无需API密钥
        super.init()
    }
    
    // MARK: - 受保护的方法
    
    /// 执行腾讯翻译API调用
    override func performTranslation(_ text: String) async throws -> String {
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
