//
//  SettingsView.swift
//  API 配置界面
//

import SwiftUI

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
            FormField(label: "API URL", placeholder: "https://api.openai.com/v1/chat/completions", text: $apiURL)
            FormField(label: "Model", placeholder: "gpt-3.5-turbo", text: $model)
            FormField(label: "API Key (Optional)", placeholder: "sk-...", text: $apiKey)
        }
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Save") {
                save()
            }
            .buttonStyle(.borderedProminent)
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
        apiURL = UserDefaults.standard.string(forKey: "OpenAIAPIIURL") ?? ""
        model = UserDefaults.standard.string(forKey: "OpenAIModel") ?? ""
        apiKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey") ?? ""
    }

    private func save() {
        guard !apiURL.isEmpty, !model.isEmpty else {
            alertMessage = "API URL and Model are required"
            showAlert = true
            return
        }

        OpenAITranslationService.setAPIConfig(apiURL: apiURL, model: model, apiKey: apiKey)
        DispatchQueue.main.async {
            NSApp.keyWindow?.close()
        }
    }

    private func validate() {
        guard !apiURL.isEmpty, !model.isEmpty else {
            alertMessage = "API URL and Model are required"
            showAlert = true
            return
        }

        isValidating = true
        OpenAITranslationService.setAPIConfig(apiURL: apiURL, model: model, apiKey: apiKey)

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