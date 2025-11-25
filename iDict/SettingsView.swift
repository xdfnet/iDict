//
//  SettingsView.swift
//  设置界面：提供API密钥配置功能
//
//  功能说明：
//  - 允许用户配置腾讯翻译API密钥
//  - 提供保存和验证功能
//  - 显示当前配置状态
//

import SwiftUI

struct SettingsView: View {
    @State private var secretId: String = ""
    @State private var secretKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @StateObject private var settings = SettingsManager.shared
    @State private var showingPasswordAlert = false
    @State private var showingResetAlert = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordErrorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("iDict 设置")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)

            // 登录密码设置区域
            VStack(alignment: .leading, spacing: 12) {
                Text("登录密码设置")
                    .font(.headline)

                if !settings.hasPasswordSet() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("未设置密码")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }

                HStack(spacing: 12) {
                    SecureField(settings.hasPasswordSet() ? "输入新密码" : "设置登录密码", text: $settings.loginPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 280)

                    Button(settings.hasPasswordSet() ? "更新" : "设置") {
                        validateAndUpdatePassword()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }

                HStack {
                    Toggle("启用自动登录功能", isOn: $settings.autoLoginEnabled)
                        .font(.body)
                        .disabled(!settings.hasPasswordSet())

                    Spacer()
                }

                Text("用于锁屏后自动登录的密码，支持滑动解锁/登录功能")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !settings.hasPasswordSet() {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("请先设置密码再启用自动登录功能")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.bottom, 10)

            Divider()

            // API密钥配置区域
            VStack(alignment: .leading, spacing: 12) {
                Text("API密钥配置")
                    .font(.headline)

                // SecretId输入框
                VStack(alignment: .leading, spacing: 6) {
                    Text("SecretId:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("请输入腾讯云SecretId", text: $secretId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 400)
                }

                // SecretKey输入框
                VStack(alignment: .leading, spacing: 6) {
                    Text("SecretKey:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("请输入腾讯云SecretKey", text: $secretKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 400)
                }

                // 说明文本
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("获取 API 密钥：")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Link("腾讯云机器翻译", destination: URL(string: "https://cloud.tencent.com/product/tmt?Is=sdk-topnav")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .underline()
                }
                .padding(.top, 8)
            }

            // 按钮区域
            HStack(spacing: 12) {
                // 保存按钮
                Button(action: saveAPIKeys) {
                    Label("保存", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                // 验证按钮
                Button(action: validateAPIKeys) {
                    Label("验证", systemImage: "checkmark.shield")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Spacer()

                // 清除按钮
                Button(action: clearAPIKeys) {
                    Label("清除", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 550, height: 680)
        .onAppear(perform: loadCurrentAPIKeys)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .alert("更新密码", isPresented: $showingPasswordAlert) {
            TextField("新密码", text: $newPassword)
            TextField("确认密码", text: $confirmPassword)
            Button("取消") {
                clearPasswordFields()
            }
            Button("确认") {
                updatePassword()
            }
        } message: {
            Text(passwordErrorMessage.isEmpty ? "请输入新密码（4-20个字符）" : passwordErrorMessage)
        }
        .alert("重置设置", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) { }
            Button("确认重置", role: .destructive) {
                settings.resetToDefaults()
            }
        } message: {
            Text("确定要重置密码设置为默认值吗？")
        }
    }
    
    // 加载当前API密钥
    private func loadCurrentAPIKeys() {
        secretId = UserDefaults.standard.string(forKey: "TencentSecretId") ?? ""
        secretKey = UserDefaults.standard.string(forKey: "TencentSecretKey") ?? ""
    }
    
    // 保存API密钥
    private func saveAPIKeys() {
        guard !secretId.isEmpty, !secretKey.isEmpty else {
            showAlert(title: "错误", message: "请输入完整的API密钥信息")
            return
        }
        
        TencentTranslationService.setAPIKeys(secretId: secretId, secretKey: secretKey)
        showAlert(title: "成功", message: "API密钥已保存")
    }
    
    // 验证API密钥
    private func validateAPIKeys() {
        guard !secretId.isEmpty, !secretKey.isEmpty else {
            showAlert(title: "错误", message: "请先输入API密钥")
            return
        }
        
        // 临时设置API密钥进行测试
        TencentTranslationService.setAPIKeys(secretId: secretId, secretKey: secretKey)
        
        // 执行测试翻译
        Task {
            let testResult = await TencentTranslationService.translate("Hello")
            
            await MainActor.run {
                if testResult != "腾讯翻译API密钥未配置" && testResult != "Hello" {
                    showAlert(title: "验证成功", message: "API密钥有效，测试翻译结果：\(testResult)")
                } else {
                    showAlert(title: "验证失败", message: "API密钥无效或网络错误")
                }
            }
        }
    }
    
    // 清除API密钥
    private func clearAPIKeys() {
        UserDefaults.standard.removeObject(forKey: "TencentSecretId")
        UserDefaults.standard.removeObject(forKey: "TencentSecretKey")
        secretId = ""
        secretKey = ""
        showAlert(title: "成功", message: "API密钥已清除")
    }
    
    // 显示警告
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

    // MARK: - 密码管理方法

    private func validateAndUpdatePassword() {
        passwordErrorMessage = ""

        guard settings.validatePassword(settings.loginPassword) else {
            passwordErrorMessage = "密码长度必须在4-20个字符之间"
            showingPasswordAlert = true
            return
        }

        newPassword = settings.loginPassword
        confirmPassword = settings.loginPassword
        showingPasswordAlert = true
    }

    private func updatePassword() {
        passwordErrorMessage = ""

        guard newPassword == confirmPassword else {
            passwordErrorMessage = "两次输入的密码不一致"
            return
        }

        guard SettingsManager.updatePassword(newPassword) else {
            passwordErrorMessage = "密码格式不正确（4-20个字符）"
            return
        }

        showAlert(title: "成功", message: "登录密码已更新")
        clearPasswordFields()
    }

    private func clearPasswordFields() {
        newPassword = ""
        confirmPassword = ""
        passwordErrorMessage = ""
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}