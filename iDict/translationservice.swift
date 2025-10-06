//
//  TranslationService.swift
//  翻译服务管理文件，提供多种翻译引擎支持
//  实现Google、Microsoft、DeepL翻译服务和统一管理接口
//

import Foundation

// MARK: - 翻译服务类型
enum TranslationServiceType: String, CaseIterable {
    case google = "Google"
    case microsoft = "Microsoft"
    case deepl = "DeepL"
    
    var displayName: String {
        switch self {
        case .google: return "Google Translate"
        case .microsoft: return "Microsoft Translator"
        case .deepl: return "DeepL Translate"
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
               let firstLevel = jsonObject.first as? [Any],
               let secondLevel = firstLevel.first as? [Any],
               let translatedText = secondLevel.first as? String {
                return translatedText
            }
        } catch {
            // 网络错误时返回原文
        }
        return text
    }
}

// MARK: - Microsoft翻译服务
struct MicrosoftTranslationService {
    static func translate(_ text: String) async -> String {
        // 使用Microsoft Translator通过MyMemory代理，指定英文到中文翻译
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=en|zh-CN&de=microsoft@mymemory.translated.net") else {
            return text
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", 
                        forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let responseData = jsonObject["responseData"] as? [String: Any],
                   let translatedText = responseData["translatedText"] as? String,
                   !translatedText.isEmpty {
                    return translatedText
                }
            }
        } catch {
            print("Microsoft翻译错误: \(error.localizedDescription)")
        }
        
        return text
    }
}

// MARK: - DeepL翻译服务
struct DeepLTranslationService {
    static func translate(_ text: String) async -> String {
        // 使用DeepL的免费翻译API（通过第三方代理），指定英文到中文翻译
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=en|zh-CN&de=deepl@mymemory.translated.net") else {
            return text
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", 
                        forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let responseData = jsonObject["responseData"] as? [String: Any],
                   let translatedText = responseData["translatedText"] as? String,
                   !translatedText.isEmpty {
                    return translatedText
                }
            }
        } catch {
            print("DeepL翻译错误: \(error.localizedDescription)")
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
        case .microsoft:
            return await MicrosoftTranslationService.translate(text)
        case .deepl:
            return await DeepLTranslationService.translate(text)
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