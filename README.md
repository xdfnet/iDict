# iDict

macOS 菜单栏翻译工具。选中文本后按 `Cmd+D`，在鼠标附近显示翻译结果。

[![Version](https://img.shields.io/github/v/release/xdfnet/iDict?style=flat-square)](https://github.com/xdfnet/iDict/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-15.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 特性

- `Cmd+D` 划词翻译
- 默认 Google Translate，首次安装无需配置即可使用
- 可切换 OpenAI 兼容翻译服务，适配本地模型和第三方兼容接口
- 菜单栏快速切换翻译服务
- 首次启动自动准备配置文件，不覆盖已有配置

## 安装

1. 下载 [Releases](https://github.com/xdfnet/iDict/releases) 中的 `iDict.app`
2. 拖到应用程序文件夹
3. 打开 iDict
4. 在「系统设置 → 隐私与安全性」授权：
   - 辅助功能权限
   - 输入监控权限

首次启动会自动创建配置文件：

```text
~/.config/idict/config.json
```

默认翻译服务是 Google，无需 API Key。

## 使用

1. 选中英文文本
2. 按 `Cmd+D`
3. 查看翻译结果
4. 按 `ESC` 关闭

## 翻译服务

在菜单栏图标中打开 `Translation Provider`，可切换翻译服务。

| 服务 | 说明 |
|------|------|
| Google | 默认服务，免费，无需配置 |
| OpenAI Compatible | OpenAI 兼容接口，支持本地模型和第三方兼容服务 |

### 配置文件

路径：

```text
~/.config/idict/config.json
```

默认配置：

```json
{
  "provider" : "google",
  "baseURL" : "https://api.openai.com/v1",
  "apiKey" : "",
  "model" : "gpt-5-mini",
  "systemPrompt" : "You are a translation engine. Follow the user's translation instruction exactly. Return only the final translation.",
  "userPromptTemplate" : "将下面的文本翻译为自然、准确的简体中文，只返回译文：\n{{text}}",
  "timeoutSeconds" : 20,
  "speechEnabled" : true,
  "speechCommand" : "/Users/admin/.local/bin/iaura speak {{text}}"
}
```

字段说明：

| 字段 | 说明 |
|------|------|
| `provider` | `google` 或 `openai` |
| `baseURL` | OpenAI 兼容接口地址，例如 `http://127.0.0.1:8000/v1` |
| `apiKey` | OpenAI 兼容接口 Key，本地服务也可填占位值 |
| `model` | 模型名 |
| `systemPrompt` | 系统提示词 |
| `userPromptTemplate` | 用户提示词模板，`{{text}}` 会被替换为待翻译文本 |
| `timeoutSeconds` | 请求超时时间 |
| `speechEnabled` | 是否自动朗读翻译结果 |
| `speechCommand` | 朗读命令模板，`{{text}}` 会被替换为翻译文本。支持 [iAura](https://github.com/xdfnet/iAura)、iSpeak 等 TTS 工具 |

已有配置会被保留；只有缺少字段时，应用才会补齐并重写为完整格式。

## 快捷键

| 快捷键           | 功能             |
|------------------|------------------|
| `Cmd+D`          | 翻译选中文本     |
| `ESC` / `Cmd+W`  | 关闭翻译窗口     |

## 开发

```bash
make debug    # 调试构建
make install  # 安装到 /Applications（删除旧版后覆盖安装）
make package  # 打包 zip
make push MSG="你的提交信息"  # 版本递增、安装、打包、提交并推送
```

发布前建议执行：

```bash
xcodebuild test -project iDict.xcodeproj -scheme iDict -destination platform=macOS -derivedDataPath build
make install
make package
```

如果系统提示应用损坏或无法打开，优先重新从源码执行 `make install`，不要继续复用旧的导出包。

