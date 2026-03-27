# iDict

macOS 菜单栏翻译工具，`Cmd+D` 快速翻译选中文本。

[![Version](https://img.shields.io/badge/version-v1.0.3-blue.svg)](https://github.com/xdfnet/iDict/releases)
[![macOS](https://img.shields.io/badge/macOS-13.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 功能

### 翻译
- `Cmd+D` 快速翻译选中英文
- Google Translate（免费）
- OpenAI 自定义（需配置 API）

### 远程控制（彩蛋）
- 媒体播放控制
- 应用开关
- 锁屏

## 快速开始

### 安装

1. 下载 [Releases](https://github.com/xdfnet/iDict/releases) 中的 `iDict.app`
2. 拖到应用程序文件夹
3. 首次运行需在「系统设置 → 隐私与安全性」授权

### 使用

1. 选中英文文本
2. 按 `Cmd+D`
3. 查看翻译结果
4. 按 `ESC` 关闭

### 配置

点击菜单栏 → `Settings` 配置 OpenAI 翻译服务。

## 开发

```bash
make debug    # 调试构建
make push     # 发布构建
```

## 许可证

MIT