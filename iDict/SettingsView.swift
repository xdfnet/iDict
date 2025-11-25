//
//  SettingsView.swift
//  API 密钥配置界面
//

import SwiftUI

// MARK: - 设置视图

/// 腾讯翻译 API 密钥的配置、验证和管理
struct SettingsView: View {
    // MARK: - 属性
    
    @State private var secretId: String = ""
    @State private var secretKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    // MARK: - 视图主体
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 腾讯翻译密钥配置区域
            VStack(alignment: .leading, spacing: 12) {
                Text("腾讯翻译密钥配置")
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
        .frame(width: 550)
        .onAppear(perform: loadCurrentAPIKeys)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // MARK: - 方法
        
    /// 加载已保存的 API 密钥
    private func loadCurrentAPIKeys() {
        secretId = UserDefaults.standard.string(forKey: "TencentSecretId") ?? ""
        secretKey = UserDefaults.standard.string(forKey: "TencentSecretKey") ?? ""
    }
    
    /// 保存 API 密钥
    private func saveAPIKeys() {
        guard !secretId.isEmpty, !secretKey.isEmpty else {
            showAlert(title: "错误", message: "请输入完整的API密钥信息")
            return
        }
        
        TencentTranslationService.setAPIKeys(secretId: secretId, secretKey: secretKey)
        showAlert(title: "成功", message: "API密钥已保存")
    }
    
    /// 验证 API 密钥有效性
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
    
    /// 清除 API 密钥
    private func clearAPIKeys() {
        UserDefaults.standard.removeObject(forKey: "TencentSecretId")
        UserDefaults.standard.removeObject(forKey: "TencentSecretKey")
        secretId = ""
        secretKey = ""
        showAlert(title: "成功", message: "API密钥已清除")
    }
    
    /// 显示警告对话框
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}