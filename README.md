# iDict

macOS 菜单栏翻译工具，通过 `Cmd+D` 快速翻译选中的英文文本。

[![Version](https://img.shields.io/badge/version-v1.0.3-blue.svg)](https://github.com/xdfnet/iDict/releases)
[![macOS](https://img.shields.io/badge/macOS-13.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 功能

### 翻译
- `Cmd+D` 一键翻译选中文本
- Google Translate（免费，无需配置）
- OpenAI 自定义翻译（需配置 API URL 和 Model）

### 远程控制（彩蛋）
通过手机浏览器控制 Mac：
- 媒体播放控制（播放/暂停、上/下一曲、音量）
- 应用开关（抖音、汽水音乐）
- 锁屏

## 安装

1. 下载 [Releases](https://github.com/xdfnet/iDict/releases) 中的 `iDict.app`
2. 拖到应用程序文件夹
3. 首次运行需在「系统设置 → 隐私与安全性」中授权：
   - 辅助功能权限（全局快捷键）
   - 输入监控权限（复制操作）

## 使用

1. 选中任意应用中的英文文本
2. 按 `Cmd+D`
3. 翻译结果弹窗显示
4. 按 `ESC` 或 `Cmd+W` 关闭

## 配置

点击菜单栏图标 → `Settings`：

**OpenAI 翻译服务**：
- API URL：填写你的自建 API 地址
- Model：填写模型名称（如 gpt-3.5-turbo）
- API Key：如有认证需求填写

**Google Translate** 无需配置，直接使用。

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd+D` | 翻译选中文本 |
| `ESC` / `Cmd+W` | 关闭翻译窗口 |

## 开发

```bash
# 调试构建
make debug

# 发布构建（构建、安装、版本更新、推送）
make push MSG="提交信息"
```

## 技术栈

- Swift 6.2+
- macOS 13.0+
- SwiftUI + AppKit
- Carbon (快捷键)

## 许可证

MIT