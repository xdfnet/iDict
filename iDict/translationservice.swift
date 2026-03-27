//
//  TranslationService.swift
//  翻译服务管理文件，提供多种翻译引擎支持
//  实现Google、OpenAI翻译服务和统一管理接口
//

import Foundation

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
    static func translate(_ text: String) async -> String {
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=zh&dt=t&q=\(encodedText)") else {
            return text
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [Any],
               let sentences = jsonObject.first as? [[Any]] {
                let translatedText = sentences.compactMap { $0.first as? String }.joined()
                if !translatedText.isEmpty {
                    return translatedText
                }
            }
        } catch {
            // 网络错误时返回原文
        }
        return text
    }
}

// MARK: - OpenAI 自定义翻译服务
struct OpenAITranslationService {
    private static var apiURL: String {
        return UserDefaults.standard.string(forKey: "OpenAIAPIIURL") ?? ""
    }

    private static var model: String {
        return UserDefaults.standard.string(forKey: "OpenAIModel") ?? ""
    }

    private static var apiKey: String {
        return UserDefaults.standard.string(forKey: "OpenAIAPIKey") ?? ""
    }

    static func setAPIConfig(apiURL: String, model: String, apiKey: String) {
        UserDefaults.standard.set(apiURL, forKey: "OpenAIAPIIURL")
        UserDefaults.standard.set(model, forKey: "OpenAIModel")
        UserDefaults.standard.set(apiKey, forKey: "OpenAIAPIKey")
    }

    static func isAPIConfigured() -> Bool {
        return !apiURL.isEmpty
    }

    static func translate(_ text: String) async -> String {
        guard let url = URL(string: apiURL), !apiURL.isEmpty else {
            return text
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 如果设置了 API Key，添加 Authorization header
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        // 构建请求体，OpenAI 兼容格式
        let prompt = "将下面的文本翻译为中文(简体)：\n\(text)"
        let requestBody: [String: Any] = [
            "model": model,
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
                    return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } catch {
            print("OpenAI翻译错误: \(error.localizedDescription)")
        }

        return text
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
    
    func translateText(_ text: String) async -> String {
        switch currentServiceType {
        case .google:
            return await GoogleTranslationService.translate(text)
        case .openai:
            return await OpenAITranslationService.translate(text)
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