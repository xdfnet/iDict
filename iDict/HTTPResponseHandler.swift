//
//  HTTPResponseHandler.swift
//  HTTP 响应处理工具类
//

import Foundation
import Network

/// HTTP 响应处理工具类，统一处理各种类型的 HTTP 响应
struct HTTPResponseHandler {

    // MARK: - 响应状态码

    private enum HTTPStatusCode: Int {
        case ok = 200
        case badRequest = 400
        case notFound = 404

        var statusText: String {
            switch self {
            case .ok: return "OK"
            case .badRequest: return "Bad Request"
            case .notFound: return "Not Found"
            }
        }
    }

    // MARK: - 响应发送方法

    /// 发送 HTTP 响应
    /// - Parameters:
    ///   - connection: 网络连接
    ///   - code: HTTP 状态码
    ///   - body: 响应内容
    ///   - contentType: 内容类型
    static func sendResponse(
        _ connection: NWConnection,
        code: Int,
        body: String,
        contentType: String = "text/plain"
    ) {
        let statusCode = HTTPStatusCode(rawValue: code) ?? .ok
        let statusText = statusCode.statusText
        let response = "HTTP/1.1 \(code) \(statusText)\r\n" +
                      "Content-Type: \(contentType); charset=UTF-8\r\n" +
                      "Content-Length: \(body.utf8.count)\r\n" +
                      "Connection: close\r\n\r\n" +
                      body

        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    /// 发送数据响应
    /// - Parameters:
    ///   - connection: 网络连接
    ///   - code: HTTP 状态码
    ///   - data: 响应数据
    ///   - contentType: 内容类型
    static func sendDataResponse(
        _ connection: NWConnection,
        code: Int,
        data: Data,
        contentType: String
    ) {
        let statusCode = HTTPStatusCode(rawValue: code) ?? .ok
        let statusText = statusCode.statusText
        let header = "HTTP/1.1 \(code) \(statusText)\r\n" +
                     "Content-Type: \(contentType)\r\n" +
                     "Content-Length: \(data.count)\r\n" +
                     "Connection: close\r\n\r\n"

        var responseData = header.data(using: .utf8)!
        responseData.append(data)

        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    // MARK: - 便捷方法

    /// 发送 HTML 响应
    static func sendHTML(_ connection: NWConnection, _ html: String) {
        sendResponse(connection, code: 200, body: html, contentType: "text/html")
    }

    /// 发送 JSON 响应
    static func sendJSON(_ connection: NWConnection, _ json: String) {
        sendResponse(connection, code: 200, body: json, contentType: "application/json")
    }

    /// 发送错误响应
    static func sendError(_ connection: NWConnection, code: Int, message: String) {
        sendResponse(connection, code: code, body: message, contentType: "text/plain")
    }

    /// 发送 400 Bad Request 响应
    static func sendBadRequest(_ connection: NWConnection, message: String = "Bad Request") {
        sendError(connection, code: 400, message: message)
    }

    /// 发送 404 Not Found 响应
    static func sendNotFound(_ connection: NWConnection, message: String = "Not Found") {
        sendError(connection, code: 404, message: message)
    }

    /// 发送成功响应
    static func sendSuccess(_ connection: NWConnection, data: Any? = nil) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: data ?? ["status": "success"]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            sendJSON(connection, jsonString)
        } else {
            sendResponse(connection, code: 200, body: "success")
        }
    }

    // MARK: - JSON 构建辅助方法

    /// 构建 JSON 响应字符串
    /// - Parameters:
    ///   - status: 状态
    ///   - error: 错误信息（可选）
    ///   - additionalData: 额外数据（可选）
    /// - Returns: JSON 字符串
    static func buildJSONResponse(
        status: String,
        error: String? = nil,
        additionalData: [String: Any]? = nil
    ) -> String {
        var responseDict: [String: Any] = ["status": status]

        if let error = error {
            responseDict["error"] = error
        }

        if let additionalData = additionalData {
            responseDict.merge(additionalData) { (_, new) in new }
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: responseDict)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            // 如果 JSON 序列化失败，返回简单的字符串格式
            return "{\"status\":\"\(status)\",\"error\":\"\(error.localizedDescription)\"}"
        }

        return "{\"status\":\"error\",\"error\":\"Failed to create response\"}"
    }
}