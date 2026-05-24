# Changelog

## 1.1.3

- 翻译结果可通过配置项 `speechEnabled` 控制是否自动调用 iSpeak 朗读，并可用 `speechCommandPath` 配置命令路径（依赖 ispeakd 守护进程，未运行则静默跳过）。
- 配置目录改为 `~/.config/idict/config.json`。
- 优化 HTTP 服务器请求处理，减少主线程占用。
- Google 翻译请求支持配置化超时时间。
- 远程控制页面图标更新为官方 App 高清图标。

## 1.1.0

- 新增 OpenAI 兼容翻译模式，支持本地模型和第三方兼容接口。
- 首次启动自动创建 `~/.config/idict/config.json`，默认使用 Google 翻译。
- 菜单栏新增 `Translation Provider`，可快速切换 Google / OpenAI Compatible。
- 配置字段改为清晰命名：`systemPrompt` 和 `userPromptTemplate`。
- 配置文件按稳定顺序写入，并保持 URL 中的 `/` 可读。
- 远程控制页面优化按钮尺寸和状态刷新。
- 新增 `/api/status` 健康检查接口。

## 1.0.x

- 支持 `Cmd+D` 划词翻译。
- 支持菜单栏运行、翻译窗口展示和快捷关闭。
- 支持远程媒体控制、应用开关和锁屏。
