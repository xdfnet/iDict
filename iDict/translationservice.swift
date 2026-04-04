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
    case ollama = "Ollama"

    var displayName: String {
        switch self {
        case .google: return "Google Translate"
        case .openai: return "OpenAI Translate"
        case .ollama: return "Ollama Translate"
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

    static func translate(_ text: String) async -> String {
        guard !openAI_BASE_URL.isEmpty else {
            return text
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
            return text
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
                    return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } catch {
            print("OpenAI翻译错误: \(error.localizedDescription)")
        }

        return text
    }
}

// MARK: - Ollama 翻译服务
struct OllamaTranslationService {
    private static var ollamaBaseURL: String {
        UserDefaults.standard.string(forKey: "OLLAMA_BASE_URL") ?? ""
    }

    private static var ollamaModel: String {
        UserDefaults.standard.string(forKey: "OLLAMA_MODEL") ?? ""
    }

    static func setAPIConfig(baseURL: String, model: String) {
        UserDefaults.standard.set(baseURL, forKey: "OLLAMA_BASE_URL")
        UserDefaults.standard.set(model, forKey: "OLLAMA_MODEL")
    }

    static func isAPIConfigured() -> Bool {
        !ollamaBaseURL.isEmpty && !ollamaModel.isEmpty
    }

    static func translate(_ text: String) async -> String {
        guard isAPIConfigured() else {
            return text
        }

        var baseURL = ollamaBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if baseURL.hasSuffix("/") {
            baseURL.removeLast()
        }
        if baseURL.hasSuffix("/api/generate") {
            baseURL = String(baseURL.dropLast("/api/generate".count))
        }

        guard let url = URL(string: "\(baseURL)/api/generate") else {
            return text
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = """
        请将下面的英文翻译成简体中文，只返回译文，不要解释：
        \(text)
        """
        let requestBody: [String: Any] = [
            "model": ollamaModel,
            "prompt": prompt,
            "stream": false
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return text
            }

            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let translatedText = jsonObject["response"] as? String {
                let trimmed = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? text : trimmed
            }
        } catch {
            print("Ollama翻译错误: \(error.localizedDescription)")
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
        case .ollama:
            return await OllamaTranslationService.translate(text)
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
