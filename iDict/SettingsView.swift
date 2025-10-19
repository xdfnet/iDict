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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("腾讯翻译API设置")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            // API密钥配置区域
            VStack(alignment: .leading, spacing: 15) {
                Text("API密钥配置")
                    .font(.headline)
                
                // SecretId输入框
                VStack(alignment: .leading, spacing: 5) {
                    Text("SecretId:")
                        .font(.subheadline)
                    SecureField("请输入腾讯云SecretId", text: $secretId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // SecretKey输入框
                VStack(alignment: .leading, spacing: 5) {
                    Text("SecretKey:")
                        .font(.subheadline)
                    SecureField("请输入腾讯云SecretKey", text: $secretKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 说明文本
                HStack(spacing: 5) {
                    Text("获取 API 密钥：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("访问腾讯云机器翻译", destination: URL(string: "https://cloud.tencent.com/product/tmt?Is=sdk-topnav")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 5)
            }
            
            // 按钮区域
            HStack {
                // 保存按钮
                Button(action: saveAPIKeys) {
                    Text("保存")
                        .frame(minWidth: 80)
                }
                .buttonStyle(.borderedProminent)
                
                // 验证按钮
                Button(action: validateAPIKeys) {
                    Text("验证")
                        .frame(minWidth: 80)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                // 清除按钮
                Button(action: clearAPIKeys) {
                    Text("清除")
                        .frame(minWidth: 80)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 500, height: 300)
        .onAppear(perform: loadCurrentAPIKeys)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}