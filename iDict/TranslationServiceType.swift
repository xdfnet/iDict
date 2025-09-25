//
//  TranslationServiceType.swift
//  iDict
//
//  Created by iDict Team
//  Copyright © 2025 iDict App. All rights reserved.
//
//  翻译服务类型定义：支持多种翻译服务提供商
//

import Foundation
import Combine

// MARK: - 翻译服务类型枚举
enum TranslationServiceType: String, CaseIterable {
    case google = "Google"
    case tencent = "Tencent"
    
    var displayName: String {
        switch self {
        case .google:
            return "Google Translate"
        case .tencent:
            return "Tencent Translate"
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .google:
            return true
        case .tencent:
            // 腾讯翻译君API将于2025年4月15日关闭
            let calendar = Calendar.current
            let cutoffDate = calendar.date(from: DateComponents(year: 2025, month: 4, day: 15)) ?? Date()
            return Date() < cutoffDate
        }
    }
    
    var deprecationWarning: String? {
        switch self {
        case .google:
            return nil
        case .tencent:
            return "腾讯翻译君API将于2025年4月15日关闭"
        }
    }
}

// MARK: - 翻译服务协议
protocol TranslationServiceProtocol {
    /// 翻译文本
    /// - Parameter text: 要翻译的源文本
    /// - Returns: 翻译后的目标文本
    /// - Throws: 翻译失败时抛出错误
    func translateText(_ text: String) async throws -> String
    
    /// 服务类型
    var serviceType: TranslationServiceType { get }
    
    /// 服务是否可用
    var isAvailable: Bool { get }
}

// MARK: - 翻译服务管理器
@MainActor
class TranslationServiceManager: ObservableObject {
    
    // MARK: - 属性
    
    /// 当前选择的翻译服务类型
    @Published var currentServiceType: TranslationServiceType {
        didSet {
            UserDefaults.standard.set(currentServiceType.rawValue, forKey: "selectedTranslationService")
            updateCurrentService()
        }
    }
    
    /// 当前翻译服务实例
    private var currentService: TranslationServiceProtocol
    
    /// 所有可用的翻译服务
    private let services: [TranslationServiceType: TranslationServiceProtocol]
    
    // MARK: - 初始化
    
    init() {
        // 初始化所有翻译服务
        let servicesDict: [TranslationServiceType: TranslationServiceProtocol] = [
            .google: TranslationService_google(),
            .tencent: TranslationService_Tencent()
        ]
        self.services = servicesDict
        
        // 从用户偏好设置中读取选择的服务
        let savedServiceType = UserDefaults.standard.string(forKey: "selectedTranslationService")
        let serviceType = TranslationServiceType(rawValue: savedServiceType ?? "") ?? .google
        self.currentServiceType = serviceType
        
        // 设置当前服务
        self.currentService = servicesDict[serviceType] ?? servicesDict[.google]!
    }
    
    // MARK: - 公共方法
    
    /// 翻译文本
    /// - Parameter text: 要翻译的文本
    /// - Returns: 翻译结果
    /// - Throws: 翻译错误
    func translateText(_ text: String) async throws -> String {
        guard currentService.isAvailable else {
            throw TranslationError.serviceUnavailable(currentServiceType.displayName)
        }
        
        return try await currentService.translateText(text)
    }
    
    /// 获取所有可用的翻译服务类型
    func getAvailableServices() -> [TranslationServiceType] {
        return TranslationServiceType.allCases.filter { $0.isAvailable }
    }
    
    /// 切换翻译服务
    /// - Parameter serviceType: 新的翻译服务类型
    func switchService(to serviceType: TranslationServiceType) {
        guard serviceType.isAvailable else { return }
        currentServiceType = serviceType
    }
    
    // MARK: - 私有方法
    
    private func updateCurrentService() {
        if let service = services[currentServiceType] {
            currentService = service
        }
    }
}

// MARK: - 翻译错误定义

/// 定义了在翻译过程中可能发生的特定错误
enum TranslationError: LocalizedError {
    case invalidTextLength
    case emptyResult
    case apiError(message: String)
    case networkError(Error)
    case serviceUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .invalidTextLength:
            return "要翻译的文本长度无效"
        case .emptyResult:
            return "翻译服务返回了空结果"
        case .apiError(let message):
            return "翻译服务API错误：\(message)"
        case .networkError(let error):
            return "网络连接问题：\(error.localizedDescription)"
        case .serviceUnavailable(let serviceName):
            return "翻译服务 \(serviceName) 当前不可用"
        }
    }
}