//
//  TranslationService.swift
//  翻译服务接口
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
        if case .success(let text) = self { return text }
        return nil
    }

    var errorMessage: String? {
        if case .failed(_, let error) = self { return error }
        return nil
    }
}

// MARK: - 翻译配置

enum TranslationProvider: String, Codable, CaseIterable {
    case google
    case openai

    var menuTitle: String {
        switch self {
        case .google: return "Google"
        case .openai: return "OpenAI Compatible"
        }
    }
}

struct TranslationConfig: Codable, Equatable {
    var provider: TranslationProvider
    var baseURL: String
    var apiKey: String
    var model: String
    var speechEnabled: Bool
    var speechCommand: String

    enum CodingKeys: String, CodingKey, CaseIterable {
        case provider, baseURL, apiKey, model
        case speechEnabled, speechCommand
    }

    init(
        provider: TranslationProvider,
        baseURL: String,
        apiKey: String,
        model: String,
        speechEnabled: Bool = true,
        speechCommand: String = TranslationConfig.defaultSpeechCommand
    ) {
        self.provider = provider
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.speechEnabled = speechEnabled
        self.speechCommand = speechCommand
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provider = try container.decodeIfPresent(TranslationProvider.self, forKey: .provider) ?? .google
        baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? TranslationConfig.defaultConfig.baseURL
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? TranslationConfig.defaultConfig.apiKey
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? TranslationConfig.defaultConfig.model
        speechEnabled = try container.decodeIfPresent(Bool.self, forKey: .speechEnabled) ?? TranslationConfig.defaultConfig.speechEnabled
        speechCommand = try Self.decodeSpeechCommand(from: decoder) ?? TranslationConfig.defaultConfig.speechCommand
    }

    private static func decodeSpeechCommand(from decoder: Decoder) throws -> String? {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let command = try container.decodeIfPresent(String.self, forKey: .speechCommand)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // 缺省字段或老配置中的空字符串都回退到默认命令
        return (command?.isEmpty == false) ? command : nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(provider, forKey: .provider)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(model, forKey: .model)
        try container.encode(speechEnabled, forKey: .speechEnabled)
        try container.encode(speechCommand, forKey: .speechCommand)
    }

    static let defaultSpeechCommand: String = {
        let ivox = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/bin/ivox").path
        return "\(ivox) speak {{text}}"
    }()

    static let defaultConfig = TranslationConfig(
        provider: .google,
        baseURL: "https://api.openai.com/v1",
        apiKey: "",
        model: "gpt-5-mini",
        speechEnabled: true,
        speechCommand: defaultSpeechCommand
    )
}

struct TranslationConfigStore {
    let configURL: URL

    init(configURL: URL = TranslationConfigStore.defaultConfigURL) {
        self.configURL = configURL
    }

    static var defaultConfigURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("idict")
            .appendingPathComponent("config.json")
    }

    func loadOrCreate() throws -> TranslationConfig {
        if !FileManager.default.fileExists(atPath: configURL.path) {
            let config = TranslationConfig.defaultConfig
            try save(config)
            return config
        }

        let data = try Data(contentsOf: configURL)
        let config = try JSONDecoder().decode(TranslationConfig.self, from: data)
        if try shouldMigrateConfig(data) {
            try save(config)
        }
        return config
    }

    func save(_ config: TranslationConfig) throws {
        let directoryURL = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let json = try formatConfigJSON(config)
        let data = Data(json.utf8)
        try data.write(to: configURL, options: .atomic)
    }

    func updateProvider(_ provider: TranslationProvider) throws {
        var config = try loadOrCreate()
        config.provider = provider
        try save(config)
    }

    private func shouldMigrateConfig(_ data: Data) throws -> Bool {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return TranslationConfig.CodingKeys.allCases.contains { object[$0.rawValue] == nil }
    }

    private func formatConfigJSON(_ config: TranslationConfig) throws -> String {
        """
        {
          "provider" : \(try jsonString(config.provider.rawValue)),
          "baseURL" : \(try jsonString(config.baseURL)),
          "apiKey" : \(try jsonString(config.apiKey)),
          "model" : \(try jsonString(config.model)),
          "speechEnabled" : \(config.speechEnabled),
          "speechCommand" : \(try jsonString(config.speechCommand))
        }
        """
    }

    private func jsonString(_ value: String) throws -> String {
        let data = try JSONEncoder().encode(value)
        let encoded = String(data: data, encoding: .utf8) ?? "\"\""
        return encoded.replacingOccurrences(of: "\\/", with: "/")
    }
}

// MARK: - Google翻译服务

struct GoogleTranslationService {
    static func translate(_ text: String) async -> TranslationResult {
        await translate(text, timeout: AppConfig.Translation.timeoutSeconds)
    }

    // 用 translate_a/t（POST）而非 translate_a/single：同一 IP 下 single 易被
    // Google 限流（302 跳 sorry 页），t 端点更稳。单段 q 响应为 ["译文"]。
    static func translate(_ text: String, timeout: TimeInterval) async -> TranslationResult {
        guard let url = URL(string: "https://translate.googleapis.com/translate_a/t?client=gtx&sl=\(AppConfig.Translation.sourceLanguage)&tl=\(AppConfig.Translation.targetLanguage)&dt=t") else {
            return .failed(text, error: "无效的翻译请求 URL")
        }

        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "q", value: text)]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = timeout
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    return .failed(text, error: "Google 限流：当前网络/代理 IP 被判定为异常流量，请稍后重试或切换网络")
                }
                if !(200...299).contains(httpResponse.statusCode) {
                    return .failed(text, error: "Google 翻译请求失败：HTTP \(httpResponse.statusCode)")
                }
            }
            if let translatedText = parseResponse(data), !translatedText.isEmpty {
                return .success(translatedText)
            }
        } catch {
            return .failed(text, error: "Google 翻译请求失败: \(error.localizedDescription)")
        }
        return .failed(text, error: "Google 翻译返回空结果")
    }

    // t 端点正常返回 ["译文"]；兼容旧版 data[0] 为数组的格式
    private static func parseResponse(_ data: Data) -> String? {
        guard let array = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            return nil
        }
        if let strings = array as? [String] {
            return strings.first
        }
        if let sentences = array.first as? [[Any]] {
            return sentences.compactMap { $0.first as? String }.joined()
        }
        return nil
    }
}

// MARK: - OpenAI兼容翻译服务

struct OpenAICompatibleTranslationService {
    struct ChatCompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }

            let message: Message
        }

        let choices: [Choice]
    }

    static func translate(_ text: String, config: TranslationConfig) async -> TranslationResult {
        guard !config.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failed(text, error: "OpenAI API Key 未配置")
        }

        guard let url = chatCompletionsURL(baseURL: config.baseURL) else {
            return .failed(text, error: "OpenAI Base URL 无效")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = AppConfig.Translation.timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": AppConfig.Translation.systemPrompt],
                ["role": "user", "content": renderUserPrompt(text)]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                return .failed(text, error: "OpenAI 翻译请求失败: \(message)")
            }

            return parseTranslation(data, originalText: text)
        } catch {
            return .failed(text, error: "OpenAI 翻译请求失败: \(error.localizedDescription)")
        }
    }

    static func renderUserPrompt(_ text: String) -> String {
        AppConfig.Translation.userPromptTemplate
            .replacingOccurrences(of: "{{text}}", with: text)
    }

    static func chatCompletionsURL(baseURL: String) -> URL? {
        let trimmedBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmedBaseURL)/chat/completions")
    }

    static func parseTranslation(_ data: Data, originalText: String) -> TranslationResult {
        do {
            let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            let translatedText = response.choices.first?.message.content?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if translatedText.isEmpty {
                return .failed(originalText, error: "OpenAI 翻译返回空结果")
            }

            return .success(translatedText)
        } catch {
            return .failed(originalText, error: "OpenAI 翻译返回格式无效: \(error.localizedDescription)")
        }
    }
}

// MARK: - 翻译服务管理器
@MainActor
final class TranslationServiceManager {
    private let configStore: TranslationConfigStore

    init(configStore: TranslationConfigStore = TranslationConfigStore()) {
        self.configStore = configStore
    }

    func translateText(_ text: String) async -> String {
        let result: TranslationResult

        do {
            let config = try configStore.loadOrCreate()
            switch config.provider {
            case .google:
                result = await GoogleTranslationService.translate(text, timeout: AppConfig.Translation.timeoutSeconds)
            case .openai:
                result = await OpenAICompatibleTranslationService.translate(text, config: config)
            }
        } catch {
            result = .failed(text, error: "读取翻译配置失败: \(error.localizedDescription)")
        }

        switch result {
        case .success(let text):
            return text
        case .failed(let original, let error):
            print("翻译失败: \(error)")
            print("原始文本: \(original)")
            return "[翻译失败] \(error)\n原文: \(original)"
        }
    }
}
