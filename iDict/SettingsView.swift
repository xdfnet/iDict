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
    @State private var openAIURL: String = ""
    @State private var openAIModel: String = ""
    @State private var openAIKey: String = ""
    @State private var ollamaURL: String = ""
    @State private var ollamaModel: String = ""
    @State private var isValidating: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                openAISection
                ollamaSection
            }
            .padding(20)
        }
        .frame(width: 520, height: 420)
        .onAppear { loadSettings() }
        .alert("Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 标题

    private var header: some View {
        Text("Translation Configuration")
            .font(.headline)
    }

    // MARK: - 配置区域

    private var openAISection: some View {
        ConfigSection(title: "OpenAI") {
            FormField(label: "OPENAI_BASE_URL", placeholder: "https://api.openai.com/v1 (可省略 /chat/completions)", text: $openAIURL)
            FormField(label: "OPENAI_MODEL", placeholder: "gpt-4o-mini", text: $openAIModel)
            FormField(label: "OPENAI_API_KEY", placeholder: "sk-...", text: $openAIKey)
            sectionActions(
                saveAction: saveOpenAI,
                validateAction: validateOpenAI
            )
        }
    }

    private var ollamaSection: some View {
        ConfigSection(title: "Ollama") {
            FormField(label: "OLLAMA_BASE_URL", placeholder: "http://127.0.0.1:11434", text: $ollamaURL)
            FormField(label: "OLLAMA_MODEL", placeholder: "qwen2.5:7b / llama3.1:8b", text: $ollamaModel)
            sectionActions(
                saveAction: saveOllama,
                validateAction: validateOllama
            )
        }
    }

    @ViewBuilder
    private func sectionActions(saveAction: @escaping () -> Void, validateAction: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button("Save", action: saveAction)
                .buttonStyle(AlwaysVisibleButtonStyle())
                .controlSize(.large)

            Button("Validate", action: validateAction)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isValidating)

            Spacer()
        }
    }

    // MARK: - 操作

    private func loadSettings() {
        openAIURL = UserDefaults.standard.string(forKey: "OPENAI_BASE_URL") ?? ""
        openAIModel = UserDefaults.standard.string(forKey: "OPENAI_MODEL") ?? ""
        openAIKey = UserDefaults.standard.string(forKey: "OPENAI_API_KEY") ?? ""
        ollamaURL = UserDefaults.standard.string(forKey: "OLLAMA_BASE_URL") ?? "http://127.0.0.1:11434"
        ollamaModel = UserDefaults.standard.string(forKey: "OLLAMA_MODEL") ?? ""
    }

    private func saveOpenAI() {
        guard !openAIURL.isEmpty, !openAIModel.isEmpty else {
            alertMessage = "API URL and Model are required"
            showAlert = true
            return
        }

        OpenAITranslationService.setAPIConfig(
            openAI_BASE_URL: openAIURL,
            openAI_MODEL: openAIModel,
            openAI_API_KEY: openAIKey
        )
        alertMessage = "OpenAI settings saved successfully"
        showAlert = true
    }

    private func validateOpenAI() {
        guard !openAIURL.isEmpty, !openAIModel.isEmpty else {
            alertMessage = "API URL and Model are required"
            showAlert = true
            return
        }

        isValidating = true
        OpenAITranslationService.setAPIConfig(
            openAI_BASE_URL: openAIURL,
            openAI_MODEL: openAIModel,
            openAI_API_KEY: openAIKey
        )

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

    private func saveOllama() {
        guard !ollamaURL.isEmpty, !ollamaModel.isEmpty else {
            alertMessage = "Ollama URL and Model are required"
            showAlert = true
            return
        }

        OllamaTranslationService.setAPIConfig(baseURL: ollamaURL, model: ollamaModel)
        alertMessage = "Ollama settings saved successfully"
        showAlert = true
    }

    private func validateOllama() {
        guard !ollamaURL.isEmpty, !ollamaModel.isEmpty else {
            alertMessage = "Ollama URL and Model are required"
            showAlert = true
            return
        }

        isValidating = true
        OllamaTranslationService.setAPIConfig(baseURL: ollamaURL, model: ollamaModel)

        Task {
            let result = await OllamaTranslationService.translate("Hello")
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

struct ConfigSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - 预览

#Preview {
    SettingsView()
        .frame(width: 520, height: 420)
}
