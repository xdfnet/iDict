//
//  AppError.swift
//  统一的应用错误处理体系
//
//  定义应用中所有可能的错误类型，提供统一的错误处理接口。
//  所有模块的错误都通过 AppError 枚举进行包装，确保错误处理的一致性。
//

import Foundation

// MARK: - 应用统一错误类型

/// 应用的统一错误类型
///
/// 包装所有子模块的错误类型，提供统一的错误处理接口。
/// 每个子系统的错误都作为关联值存储在对应的 case 中。
enum AppError: LocalizedError {
    
    // MARK: - 热键相关错误
    
    case hotKey(HotKeyError)
    
    // MARK: - 剪贴板相关错误
    
    case clipboard(ClipboardError)
    
    // MARK: - 键盘模拟相关错误
    
    case keyboardSimulator(KeyboardSimulatorError)
    
    // MARK: - 媒体控制相关错误
    
    case mediaControl(MediaControllerError)
    
    // MARK: - HTTP 服务器相关错误
    
    case httpServer(MediaHTTPServerError)
    
    // MARK: - 通用错误
    
    case unknown(String)
    case systemError(Error)
    
    // MARK: - LocalizedError 协议实现
    
    var errorDescription: String? {
        switch self {
        case .hotKey(let error):
            return error.errorDescription
        case .clipboard(let error):
            return error.errorDescription
        case .keyboardSimulator(let error):
            return error.errorDescription
        case .mediaControl(let error):
            return error.errorDescription
        case .httpServer(let error):
            return error.errorDescription
        case .unknown(let message):
            return "未知错误: \(message)"
        case .systemError(let error):
            return "系统错误: \(error.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .hotKey(let error):
            return error.failureReason
        case .clipboard(let error):
            return error.failureReason
        case .keyboardSimulator(let error):
            return error.failureReason
        case .mediaControl(let error):
            return error.recoverySuggestion
        case .httpServer(let error):
            return error.failureReason
        case .unknown, .systemError:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .hotKey(let error):
            return error.recoverySuggestion
        case .clipboard(let error):
            return error.recoverySuggestion
        case .keyboardSimulator(let error):
            return error.recoverySuggestion
        case .mediaControl(let error):
            return error.recoverySuggestion
        case .httpServer:
            return "请检查网络设置和端口占用情况"
        case .unknown, .systemError:
            return "请重试或联系技术支持"
        }
    }
}

// MARK: - 便捷转换扩展

extension AppError {
    
    /// 从 HotKeyError 创建 AppError
    static func from(_ error: HotKeyError) -> AppError {
        return .hotKey(error)
    }
    
    /// 从 ClipboardError 创建 AppError
    static func from(_ error: ClipboardError) -> AppError {
        return .clipboard(error)
    }
    
    /// 从 KeyboardSimulatorError 创建 AppError
    static func from(_ error: KeyboardSimulatorError) -> AppError {
        return .keyboardSimulator(error)
    }
    
    /// 从 MediaControllerError 创建 AppError
    static func from(_ error: MediaControllerError) -> AppError {
        return .mediaControl(error)
    }
    
    /// 从 MediaHTTPServerError 创建 AppError
    static func from(_ error: MediaHTTPServerError) -> AppError {
        return .httpServer(error)
    }
}

// MARK: - Result 类型别名

/// 统一的异步操作结果类型
typealias AppResult<T> = Result<T, AppError>
