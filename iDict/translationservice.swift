//
//  TranslationService.swift
//  Google 翻译服务
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

// MARK: - 翻译服务管理器
@MainActor
final class TranslationServiceManager {

    func translateText(_ text: String) async -> TranslationResult {
        return await GoogleTranslationService.translate(text)
    }

    func translateTextWithFallback(_ text: String) async -> String {
        let result = await translateText(text)
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
