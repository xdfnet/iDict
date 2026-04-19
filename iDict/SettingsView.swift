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
    @State private var selectedService: TranslationServiceType = .google
    @State private var openAIURL: String = ""
    @State private var openAIModel: String = ""
    @State private var openAIKey: String = ""
    @State private var isValidating: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                serviceSummary
                currentServiceSection
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

    private var serviceSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Service")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(selectedService.displayName)
                .font(.title3.weight(.medium))
        }
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

    private var googleSection: some View {
        ConfigSection(title: "Google Translate") {
            Text("Google Translate 无需额外配置，直接选择后即可使用。")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var currentServiceSection: some View {
        switch selectedService {
        case .google:
            googleSection
        case .openai:
            openAISection
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
        if let rawValue = UserDefaults.standard.string(forKey: "selectedTranslationService"),
           let service = TranslationServiceType(rawValue: rawValue) {
            selectedService = service
        }
        openAIURL = UserDefaults.standard.string(forKey: "OPENAI_BASE_URL") ?? ""
        openAIModel = UserDefaults.standard.string(forKey: "OPENAI_MODEL") ?? ""
       openAIKey = UserDefaults.standard.string(forKey: "OPENAI_API_KEY") ?? ""
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
                switch result {
                case .success(let translated):
                    if translated == "Hello" || translated.lowercased().contains("hello") {
                        alertMessage = translated == "Hello"
                            ? "Validation Failed: Translation returned original text"
                            : "Validation Successful\nResult: \(translated)"
                    } else {
                        alertMessage = "Validation Successful\nResult: \(translated)"
                    }
                case .failed(_, let error):
                    alertMessage = "Validation Failed: \(error)"
                }
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
