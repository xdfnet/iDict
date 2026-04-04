# iDict

macOS 菜单栏翻译工具，通过 `Cmd+D` 快速翻译选中的英文文本。

[![Version](https://img.shields.io/badge/version-v1.0.20-blue.svg)](https://github.com/xdfnet/iDict/releases)
[![macOS](https://img.shields.io/badge/macOS-13.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 安装

1. 下载 [Releases](https://github.com/xdfnet/iDict/releases) 中的 `iDict.app`
2. 拖到应用程序文件夹
3. 在「系统设置 → 隐私与安全性」授权：
   - 辅助功能权限
   - 输入监控权限

## 使用

1. 选中英文文本
2. 按 `Cmd+D`
3. 查看翻译结果
4. 按 `ESC` 关闭

## 翻译服务

| 服务 | 配置 |
|------|------|
| Google Translate | 免费，无需配置 |
| OpenAI 自定义 | 需配置 API URL、Model |

点击菜单栏 → `Settings` 配置。

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd+D` | 翻译选中文本 |
| `ESC` / `Cmd+W` | 关闭翻译窗口 |

## 开发

```bash
make debug    # 调试构建
make push     # 发布构建
```

## 彩蛋：远程控制

通过手机浏览器控制 Mac：

1. 应用启动后自动开启媒体服务器
2. 手机浏览器打开电脑 IP 的 8888 端口（如 `http://192.168.1.100:8888`）

功能：媒体播放控制、应用开关、锁屏。

## 许可证

MIT