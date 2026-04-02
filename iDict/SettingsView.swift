//
//  SettingsView.swift
//  API 配置界面
//

import SwiftUI

// MARK: - 设置保存通知
extension Notification.Name {
    static let settingsDidSave = Notification.Name("settingsDidSave")
}

// MARK: - 设置视图

struct SettingsView: View {
    @State private var apiURL: String = ""
    @State private var model: String = ""
    @State private var apiKey: String = ""
    @State private var isValidating: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            formFields
            actionButtons
        }
        .padding(20)
        .frame(width: 480)
        .onAppear { loadSettings() }
        .alert("Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 标题

    private var header: some View {
        Text("OpenAI Configuration")
            .font(.headline)
    }

    // MARK: - 表单字段

    private var formFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            FormField(label: "openAI_BASE_URL", placeholder: "https://api.openai.com/v1 (可省略 /chat/completions)", text: $apiURL)
            FormField(label: "openAI_MODEL", placeholder: "gpt-3.5-turbo", text: $model)
            FormField(label: "openAI_API_KEY", placeholder: "sk-...", text: $apiKey)
        }
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Save") {
                save()
            }
            .buttonStyle(AlwaysVisibleButtonStyle())
            .controlSize(.large)

            Button("Validate") {
                validate()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isValidating)

            Spacer()
        }
    }

    // MARK: - 操作

    private func loadSettings() {
        apiURL = UserDefaults.standard.string(forKey: "OPENAI_BASE_URL") ?? ""
        model = UserDefaults.standard.string(forKey: "OPENAI_MODEL") ?? ""
        apiKey = UserDefaults.standard.string(forKey: "OPENAI_API_KEY") ?? ""
    }

    private func save() {
        guard !apiURL.isEmpty, !model.isEmpty else {
            alertMessage = "API URL and Model are required"
            showAlert = true
            return
        }

        OpenAITranslationService.setAPIConfig(openAI_BASE_URL: apiURL, openAI_MODEL: model, openAI_API_KEY: apiKey)
        alertMessage = "Settings saved successfully"
        showAlert = true

        // 发送通知让 MenuBarController 关闭设置窗口
        NotificationCenter.default.post(name: .settingsDidSave, object: nil)
    }

    private func validate() {
        guard !apiURL.isEmpty, !model.isEmpty else {
            alertMessage = "API URL and Model are required"
            showAlert = true
            return
        }

        isValidating = true
        OpenAITranslationService.setAPIConfig(openAI_BASE_URL: apiURL, openAI_MODEL: model, openAI_API_KEY: apiKey)

        Task {
            let result = await OpenAITranslationService.translate("Hello")
            await MainActor.run {
                isValidating = false
                alertMessage = result == "Hello"
                    ? "Validation Failed: Translation returned original text"
                    : "Validation Successful\nResult: \(result)"
                showAlert = true
            }
        }
    }
}

// MARK: - 自定义按钮样式

struct AlwaysVisibleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - 表单字段组件

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }
}

// MARK: - 预览

#Preview {
    SettingsView()
        .frame(width: 480)
}