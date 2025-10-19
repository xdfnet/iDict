//
//  TranslationService.swift
//  翻译服务管理文件，提供多种翻译引擎支持
//  实现Google、Microsoft、DeepL翻译服务和统一管理接口
//

import Foundation
import CommonCrypto

// MARK: - 翻译服务类型
enum TranslationServiceType: String, CaseIterable {
    case tencent = "Tencent"
    case google = "Google"
    case microsoft = "Microsoft"
    case deepl = "DeepL"
    
    var displayName: String {
        switch self {
        case .tencent: return "Tencent Translate"
        case .google: return "Google Translate"
        case .microsoft: return "Microsoft Translator"
        case .deepl: return "DeepL Translate"
        }
    }
}

// MARK: - 腾讯翻译服务
struct TencentTranslationService {
    // 腾讯云机器翻译API配置
    // 从UserDefaults中获取API密钥
    private static var secretId: String {
        return UserDefaults.standard.string(forKey: "TencentSecretId") ?? ""
    }
    
    private static var secretKey: String {
        return UserDefaults.standard.string(forKey: "TencentSecretKey") ?? ""
    }
    
    private static let region = "ap-beijing"
    private static let endpoint = "tmt.tencentcloudapi.com"
    private static let action = "TextTranslate"
    private static let version = "2018-03-21"
    private static let service = "tmt"
    
    // 提供设置API密钥的方法
    static func setAPIKeys(secretId: String, secretKey: String) {
        UserDefaults.standard.set(secretId, forKey: "TencentSecretId")
        UserDefaults.standard.set(secretKey, forKey: "TencentSecretKey")
    }
    
    // 检查API密钥是否已配置
    static func isAPIKeyConfigured() -> Bool {
        return !secretId.isEmpty && !secretKey.isEmpty
    }
    
    static func translate(_ text: String) async -> String {
        // 检查API密钥是否已配置
        guard !secretId.isEmpty && !secretKey.isEmpty else {
            print("腾讯翻译API密钥未配置，请在设置中配置API密钥")
            return "腾讯翻译API密钥未配置"
        }
        
        // 创建请求参数
        let source = "en"
        let target = "zh"
        let projectId = 0
        
        // 生成时间戳和随机数
        let timestamp = Int(Date().timeIntervalSince1970)
        let nonce = Int.random(in: 1...1000000)
        
        // 构建请求参数
        var params: [String: Any] = [
            "Action": action,
            "Version": version,
            "Region": region,
            "Timestamp": timestamp,
            "Nonce": nonce,
            "SecretId": secretId,
            "SourceText": text,
            "Source": source,
            "Target": target,
            "ProjectId": projectId
        ]
        
        // 生成签名
        let signature = generateSignature(params: params, secretKey: secretKey)
        params["Signature"] = signature
        
        // 创建请求
        guard let url = URL(string: "https://\(endpoint)") else {
            return text
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 构建请求体
        var bodyComponents: [String] = []
        for (key, value) in params {
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
            bodyComponents.append("\(encodedKey)=\(encodedValue)")
        }
        request.httpBody = bodyComponents.joined(separator: "&").data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 检查是否有错误
                    if let responseError = jsonObject["Error"] as? [String: Any],
                       let code = responseError["Code"] as? String {
                        print("腾讯翻译API错误: \(code)")
                        return text
                    }
                    
                    // 获取翻译结果
                    if let responseDict = jsonObject["Response"] as? [String: Any],
                       let translatedText = responseDict["TargetText"] as? String,
                       !translatedText.isEmpty {
                        return translatedText
                    }
                }
            }
        } catch {
            print("腾讯翻译网络错误: \(error.localizedDescription)")
        }
        
        return text
    }
    
    // 生成腾讯云API签名
    private static func generateSignature(params: [String: Any], secretKey: String) -> String {
        // 1. 对参数进行字典序排序
        let sortedParams = params.sorted { $0.key < $1.key }
        
        // 2. 构建查询字符串
        let queryString = sortedParams.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        
        // 3. 构建签名字符串
        let signatureString = "POST\(endpoint)/?\(queryString)"
        
        // 4. 使用HMAC-SHA1计算签名
        let signatureData = signatureString.data(using: .utf8)!
        let keyData = secretKey.data(using: .utf8)!
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyData.withUnsafeBytes { $0.baseAddress }, keyData.count, signatureData.withUnsafeBytes { $0.baseAddress }, signatureData.count, &digest)
        
        let signatureDataResult = Data(digest)
        return signatureDataResult.base64EncodedString()
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
                
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let translatedText = jsonObject["translatedText"] as? String, !translatedText.isEmpty {
                        return translatedText
                    }
                    if let matches = jsonObject["matches"] as? [[String: Any]] {
                        let combinedMatches = matches.compactMap { match -> String? in
                            guard let matchText = match["translation"] as? String else { return nil }
                            return matchText
                        }.joined()
                        if !combinedMatches.isEmpty {
                            return combinedMatches
                        }
                    }
                    if let responseData = jsonObject["responseData"] as? [String: Any],
                       let translatedText = responseData["translatedText"] as? String,
                       !translatedText.isEmpty {
                        return translatedText
                    }
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
                
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let translatedText = jsonObject["translatedText"] as? String, !translatedText.isEmpty {
                        return translatedText
                    }
                    if let matches = jsonObject["matches"] as? [[String: Any]] {
                        let combinedMatches = matches.compactMap { match -> String? in
                            guard let matchText = match["translation"] as? String else { return nil }
                            return matchText
                        }.joined(separator: " ")
                        if !combinedMatches.isEmpty {
                            return combinedMatches
                        }
                    }
                    if let responseData = jsonObject["responseData"] as? [String: Any],
                       let translatedText = responseData["translatedText"] as? String,
                       !translatedText.isEmpty {
                        return translatedText
                    }
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
    private var currentServiceType: TranslationServiceType = .tencent
    
    init() {
        // 从用户偏好设置中恢复上次选择的服务
        if let savedServiceType = UserDefaults.standard.string(forKey: "selectedTranslationService"),
           let serviceType = TranslationServiceType(rawValue: savedServiceType) {
            self.currentServiceType = serviceType
        }
    }
    
    func translateText(_ text: String) async -> String {
        switch currentServiceType {
        case .tencent:
            return await TencentTranslationService.translate(text)
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