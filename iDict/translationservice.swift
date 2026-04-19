//
//  TranslationService.swift
//  翻译服务管理文件，提供多种翻译引擎支持
//  实现Google、OpenAI翻译服务和统一管理接口
//

import Foundation

// MARK: - 翻译结果类型

enum TranslationResult {
    case success(String)
    case failed(String, error: String)

    var isEmpty: Bool {
        switch self {
        case .success(let text): return text.isEmpty
        case .failed: return true
        }
    }

    var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }

    var text: String? {
        switch self {
        case .success(let text): return text
        case .failed(_, _): return nil
        }
    }

    var errorMessage: String? {
        switch self {
        case .failed(_, let error): return error
        case .success: return nil
        }
    }
}

// MARK: - 翻译服务类型
enum TranslationServiceType: String, CaseIterable {
    case google = "Google"
    case openai = "OpenAI"

    var displayName: String {
        switch self {
        case .google: return "Google Translate"
        case .openai: return "OpenAI Translate"
        }
    }
}

// MARK: - Google翻译服务
struct GoogleTranslationService {
    static func translate(_ text: String) async -> TranslationResult {
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=zh&dt=t&q=\(encodedText)") else {
            return .failed(text, error: "无效的翻译请求 URL")
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [Any],
               let sentences = jsonObject.first as? [[Any]] {
                let translatedText = sentences.compactMap { $0.first as? String }.joined()
                if !translatedText.isEmpty {
                    return .success(translatedText)
                }
            }
        } catch {
            return .failed(text, error: "Google 翻译请求失败: \(error.localizedDescription)")
        }
        return .failed(text, error: "Google 翻译返回空结果")
    }
}

// MARK: - OpenAI 自定义翻译服务
struct OpenAITranslationService {
    private static var openAI_BASE_URL: String {
        return UserDefaults.standard.string(forKey: "OPENAI_BASE_URL") ?? ""
    }

    private static var openAI_MODEL: String {
        return UserDefaults.standard.string(forKey: "OPENAI_MODEL") ?? ""
    }

    private static var openAI_API_KEY: String {
        return UserDefaults.standard.string(forKey: "OPENAI_API_KEY") ?? ""
    }

    static func setAPIConfig(openAI_BASE_URL: String, openAI_MODEL: String, openAI_API_KEY: String) {
        UserDefaults.standard.set(openAI_BASE_URL, forKey: "OPENAI_BASE_URL")
        UserDefaults.standard.set(openAI_MODEL, forKey: "OPENAI_MODEL")
        UserDefaults.standard.set(openAI_API_KEY, forKey: "OPENAI_API_KEY")
    }

    static func isAPIConfigured() -> Bool {
        return !openAI_BASE_URL.isEmpty
    }

   static func translate(_ text: String) async -> TranslationResult {
        guard !openAI_BASE_URL.isEmpty else {
            return .failed(text, error: "OpenAI API 未配置")
        }

        // 补全 URL 路径
        var baseURL = openAI_BASE_URL
        if !baseURL.hasSuffix("/chat/completions") {
            if baseURL.hasSuffix("/") {
                baseURL += "chat/completions"
            } else {
                baseURL += "/chat/completions"
            }
        }

        guard let url = URL(string: baseURL) else {
            return .failed(text, error: "无效的 OpenAI API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 如果设置了 API Key，添加 Authorization header
        if !openAI_API_KEY.isEmpty {
            request.setValue("Bearer \(openAI_API_KEY)", forHTTPHeaderField: "Authorization")
        }

        // 构建请求体，OpenAI 兼容格式
        let prompt = "将下面的文本翻译为中文(简体)：\n\(text)"
        let requestBody: [String: Any] = [
            "model": openAI_MODEL,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 2000
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonObject["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let translatedText = message["content"] as? String,
                   !translatedText.isEmpty {
                     return .success(translatedText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        } catch {
            print("OpenAI翻译错误: \(error.localizedDescription)")
            return .failed(text, error: "OpenAI 翻译请求失败: \(error.localizedDescription)")
        }

        return .failed(text, error: "OpenAI 翻译返回空结果")
    }
}

// MARK: - 翻译服务管理器
@MainActor
final class TranslationServiceManager {
    private var currentServiceType: TranslationServiceType = .google
    
    init() {
        // 从用户偏好设置中恢复上次选择的服务
        if let savedServiceType = UserDefaults.standard.string(forKey: "selectedTranslationService"),
           let serviceType = TranslationServiceType(rawValue: savedServiceType) {
            self.currentServiceType = serviceType
        }
    }
    
    func translateText(_ text: String) async -> TranslationResult {
        switch currentServiceType {
        case .google:
            return await GoogleTranslationService.translate(text)
        case .openai:
            return await OpenAITranslationService.translate(text)
        }
    }
    
    func translateTextWithFallback(_ text: String) async -> String {
        let result = await translateText(text)
        switch result {
        case .success(let text):
            return text
        case .failed(let original, let error):
            print("翻译失败 [\(currentServiceType.displayName)]: \(error)")
            print("原始文本: \(original)")
            return "[翻译失败] \(error)\n原文: \(original)"
        }
    }
    
    func switchService(to serviceType: TranslationServiceType) {
        currentServiceType = serviceType
        UserDefaults.standard.set(serviceType.rawValue, forKey: "selectedTranslationService")
    }
    
    func getCurrentServiceType() -> TranslationServiceType {
        return currentServiceType
    }
}
