# Changelog

## 1.1.13 — 2026-06-19

- 签名改为 ad-hoc（Manual + `-`），不再依赖开发者账号

## 1.1.12 — 2026-06-01

- 媒体控制全部切为纯 MediaRemote：play/pause/next/prev 走 `MRMediaRemoteSendCommand`，去掉 CGEvent 备选
- 移除播放状态追踪和 `OSAllocatedUnfairLock`
- next/prev 免辅助功能权限
- `/api/status` 返回 `running`/`stopped`（Electron 应用不注册 NowPlaying client 无法查询真实状态）
- 清理不可用的 MediaRemote 查询/通知函数
- 更新架构文档

## 1.1.11 — 2026-06-01

- 新增文件日志 `~/.config/idict/daemon.log`，5MB 自动轮转
- 所有媒体控制操作同时输出到 OSLog 和日志文件

## 1.1.10 — 2026-06-01

- 修复：汽水音乐运行时 play/pause 仍唤醒 Apple Music
- play/pause 改为第三方 App 模式时通过 `CGEventPostToPid` 直接向目标进程发 Space 键，不走系统媒体路由

## 1.1.9 — 2026-06-01

- play/pause 发送前检查是否有媒体 App 进程在运行，无则跳过，不再唤醒 Apple Music
- 媒体应用白名单：Apple Music、抖音、汽水音乐

## 1.1.8

- 补全架构文档

## 1.1.7

- 精简 API：移除 space 端点，play/pause 精确控制 + 更新文档

## 1.1.6

- MediaRemote 精确媒体控制 + 控制页面增强（下拉刷新、状态同步、播放/暂停/space 端点）

## 1.1.5

- 新增 `/api/play` 和 `/api/pause` 精确播放控制

## 1.1.4

- 精简代码，修复媒体控制播放/暂停
- 更新 README 语音配置文档
- 默认语音命令从 ivox 切换到 iAura

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
