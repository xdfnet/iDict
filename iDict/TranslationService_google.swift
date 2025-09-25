//
//  TranslationService.swift
//  iDict
//
//  Created by iDict Team
//  Copyright © 2025 iDict App. All rights reserved.
//
//  Google翻译服务实现
//  提供文本翻译功能和错误处理机制，支持自动语言检测
//

import Foundation

/// Google翻译服务实现
/// 
/// 此类负责调用Google翻译API执行文本翻译
/// 支持自动语言检测和中文翻译，使用公开接口无需API密钥
class TranslationService_google: BaseTranslationService {
    
    // MARK: - TranslationServiceProtocol 实现
    
    override var serviceType: TranslationServiceType {
        return .google
    }
    
    // MARK: - 初始化

    @MainActor
    override init() {
        // 谷歌翻译使用公开接口，无需API密钥
        super.init()
    }
    
    // MARK: - 受保护的方法
    
    /// 执行Google翻译API调用
    override func performTranslation(_ text: String) async throws -> String {
        return try await performGoogleTranslation(text)
    }
    
    // MARK: - 私有网络与解析
    
    /// 执行对谷歌翻译接口的网络请求。
    /// 
    /// - Parameter text: 需要翻译的文本内容
    /// - Returns: 翻译后的中文文本
    /// - Throws: 网络错误或API错误时抛出TranslationError
    private func performGoogleTranslation(_ text: String) async throws -> String {
        // 使用 URLComponents 安全地构建 URL，它会自动处理参数的百分比编码。
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        components.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: "auto"), // 源语言：自动检测
            URLQueryItem(name: "tl", value: "zh"),   // 目标语言：中文
            URLQueryItem(name: "dt", value: "t"),    // 返回内容：翻译结果
            URLQueryItem(name: "q", value: text)
        ]
        
        guard let url = components.url else {
            throw TranslationError.apiError(message: "无法创建有效的URL")
        }
        
        // 创建带有超时设置的URLRequest
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0 // 10秒超时
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return try parseGoogleResponse(data: data, response: response)
        } catch {
            // 将网络错误转换为更友好的错误信息
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw TranslationError.networkError(NSError(domain: "TranslationService", code: -1001, userInfo: [NSLocalizedDescriptionKey: "请求超时，请检查网络连接"]))
                case .notConnectedToInternet:
                    throw TranslationError.networkError(NSError(domain: "TranslationService", code: -1009, userInfo: [NSLocalizedDescriptionKey: "无网络连接"]))
                case .cannotFindHost:
                    throw TranslationError.networkError(NSError(domain: "TranslationService", code: -1003, userInfo: [NSLocalizedDescriptionKey: "无法连接到翻译服务器"]))
                default:
                    throw TranslationError.networkError(urlError)
                }
            } else {
                throw TranslationError.networkError(error)
            }
        }
    }
    
    /// 解析谷歌翻译API响应数据。
    private func parseGoogleResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw TranslationError.networkError(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP 错误: \(statusCode)"]))
        }
        
        // 首先尝试将响应数据转换为字符串以便调试
        if let responseString = String(data: data, encoding: .utf8) {
            print("API响应: \(responseString)")
        }
        
        do {
            // 尝试将响应解析为通用的JSON对象
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
                throw TranslationError.apiError(message: "响应不是有效的JSON数组格式")
            }
            
            // Google翻译API的响应格式通常是: [[["翻译文本", "原文本", null, null, 0]]]
            // 我们需要安全地导航这个嵌套结构
            guard let firstLevel = jsonObject.first as? [Any],
                  let secondLevel = firstLevel.first as? [Any],
                  let translatedText = secondLevel.first as? String else {
                
                // 如果标准格式解析失败，尝试其他可能的格式
                if let alternativeText = extractTranslationFromAlternativeFormat(jsonObject) {
                    return alternativeText
                }
                
                throw TranslationError.apiError(message: "无法从API响应中提取翻译文本")
            }
            
            if translatedText.isEmpty {
                throw TranslationError.emptyResult
            }
            
            return translatedText
            
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.apiError(message: "解析JSON响应失败: \(error.localizedDescription)")
        }
    }
    
    /// 尝试从备用格式中提取翻译文本
    private func extractTranslationFromAlternativeFormat(_ jsonObject: [Any]) -> String? {
        // 尝试不同的可能格式
        for item in jsonObject {
            if let array = item as? [Any] {
                for subItem in array {
                    if let subArray = subItem as? [Any],
                       let text = subArray.first as? String,
                       !text.isEmpty {
                        return text
                    }
                }
            }
        }
        return nil
    }
}
