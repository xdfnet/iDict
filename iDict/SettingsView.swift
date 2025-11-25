//
//  SettingsView.swift
//  API Configuration Interface
//

import SwiftUI

// MARK: - Settings View

/// Tencent Translation API key configuration, validation and management
struct SettingsView: View {
    // MARK: - Properties

    @State private var secretId: String = ""
    @State private var secretKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isValidating = false

    // MARK: - Body

    var body: some View {
        contentView
            .frame(width: 480)
            .fixedSize(horizontal: true, vertical: true)
            .onAppear(perform: loadCurrentAPIKeys)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
    }

    
    // MARK: - Content View

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // SecretId Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Secret ID")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("Enter Tencent Cloud SecretId", text: $secretId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
            }

            // SecretKey Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Secret Key")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("Enter Tencent Cloud SecretKey", text: $secretKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
            }

            // Help Text
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("Get API keys from:")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Link("Tencent Cloud TMT", destination: URL(string: "https://cloud.tencent.com/product/tmt?Is=sdk-topnav")!)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }

            // Action Buttons
            HStack(spacing: 8) {
                // Save Button
                Button("Save") {
                    saveAPIKeys()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(secretId.isEmpty || secretKey.isEmpty)

                // Validate Button
                Button("Validate") {
                    validateAPIKeys()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(secretId.isEmpty || secretKey.isEmpty || isValidating)

                Spacer()

                // Clear Button
                Button("Clear") {
                    clearAPIKeys()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color(NSColor.textBackgroundColor))
    }

    // MARK: - Methods

    /// Load saved API keys
    private func loadCurrentAPIKeys() {
        secretId = UserDefaults.standard.string(forKey: "TencentSecretId") ?? ""
        secretKey = UserDefaults.standard.string(forKey: "TencentSecretKey") ?? ""
    }

    /// Save API keys
    private func saveAPIKeys() {
        guard !secretId.isEmpty && !secretKey.isEmpty else {
            showAlert(title: "Error", message: "Please enter complete API key information")
            return
        }

        TencentTranslationService.setAPIKeys(secretId: secretId, secretKey: secretKey)
        showAlert(title: "Success", message: "API keys saved successfully")
    }

    /// Validate API keys
    private func validateAPIKeys() {
        guard !secretId.isEmpty && !secretKey.isEmpty else {
            showAlert(title: "Error", message: "Please enter API keys first")
            return
        }

        isValidating = true

        // Temporarily set API keys for testing
        TencentTranslationService.setAPIKeys(secretId: secretId, secretKey: secretKey)

        // Perform test translation
        Task {
            let testResult = await TencentTranslationService.translate("Hello")

            await MainActor.run {
                isValidating = false
                if testResult != "腾讯翻译API密钥未配置" && testResult != "Hello" {
                    showAlert(title: "Validation Successful", message: "API keys are valid. Test result: \(testResult)")
                } else {
                    showAlert(title: "Validation Failed", message: "API keys are invalid or network error occurred")
                }
            }
        }
    }

    /// Clear API keys
    private func clearAPIKeys() {
        UserDefaults.standard.removeObject(forKey: "TencentSecretId")
        UserDefaults.standard.removeObject(forKey: "TencentSecretKey")
        secretId = ""
        secretKey = ""
        showAlert(title: "Success", message: "API keys cleared")
    }

    /// Show alert dialog
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .frame(width: 480)
    }
}