//
//  SettingsView.swift
//  快捷设置界面
//

import SwiftUI

// MARK: - 设置保存通知
extension Notification.Name {
    static let settingsDidSave = Notification.Name("settingsDidSave")
}

// MARK: - 设置视图

struct SettingsView: View {
    @AppStorage("autoCopyEnabled") private var autoCopyEnabled: Bool = true
    @AppStorage("translationDelay") private var translationDelay: Double = 150
    
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            header
            
            ScrollView {
                VStack(spacing: 16) {
                    hotKeySection
                    autoCopySection
                    delaySection
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(width: 480, height: 380)
        .alert("Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 标题
    
    private var header: some View {
        Text("Quick Settings")
            .font(.headline)
    }
    
    // MARK: - 热键设置
    
    private var hotKeySection: some View {
        ConfigSection(title: "Translation Hotkey") {
            HStack {
                Text("Current:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatHotKey())
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Button("Change") {
                    alertMessage = "Hotkey can be changed in System Settings > Keyboard > Shortcuts"
                    showAlert = true
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - 自动复制设置
    
    private var autoCopySection: some View {
        ConfigSection(title: "Options") {
            Toggle("Auto-copy selected text on hotkey", isOn: $autoCopyEnabled)
        }
    }
    
    // MARK: - 延迟设置
    
    private var delaySection: some View {
        ConfigSection(title: "Copy Delay (ms)") {
            HStack {
                Slider(value: $translationDelay, in: 50...500, step: 50)
                
                Text("\(Int(translationDelay))ms")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func formatHotKey() -> String {
        let keyCode = UserDefaults.standard.integer(forKey: "hotKeyKeyCode")
        let modifierFlags = UserDefaults.standard.string(forKey: "hotKeyModifierFlags") ?? ""
        
        let modifiers = formatModifiers(modifierFlags)
        let key = formatKeyCode(keyCode)
        
        if modifiers.isEmpty {
            return key
        }
        return "\(modifiers) + \(key)"
    }
    
    private func formatModifiers(_ flags: String) -> String {
        guard let modifierValue = UInt64(flags) else { return "" }
        
        var modifierList: [String] = []
        if modifierValue & UInt64(NSEvent.ModifierFlags.command.rawValue) != 0 {
            modifierList.append("⌘")
        }
        if modifierValue & UInt64(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            modifierList.append("⇧")
        }
        if modifierValue & UInt64(NSEvent.ModifierFlags.option.rawValue) != 0 {
            modifierList.append("⌥")
        }
        if modifierValue & UInt64(NSEvent.ModifierFlags.control.rawValue) != 0 {
            modifierList.append("⌃")
        }
        
        return modifierList.joined(separator: " + ")
    }
    
    private func formatKeyCode(_ code: Int) -> String {
        if code == 0 { return "Not set" }
        let key = keyCodeToString(UInt16(code))
        return key.isEmpty ? "Key \(code)" : key
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G",
            6: "Z", 7: "X", 8: "C", 9: "V", 11: "B", 12: "Q",
            13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 26: "9", 27: "7", 28: "-",
            29: "=", 30: "0", 31: "]", 32: "[", 33: "\\",
            34: ":", 35: "\"", 37: "<", 38: ",", 39: "/",
            40: "T", 41: "O", 42: "I", 43: "P", 45: "L",
            46: "J", 47: "'", 48: ";", 49: "K", 51: "N",
            52: "M", 53: ".", 54: "/", 57: " ", 59: "Tab",
            60: "Return", 51: "Enter",
            53: "Space", 55: "Delete", 57: "Escape"
        ]
        return keyMap[keyCode] ?? "Key\(keyCode)"
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
        .frame(width: 480, height: 380)
}
