# iDict API Documentation

## 概述

iDict 是一个 macOS 桌面应用，提供了远程控制功能，包括媒体控制、应用管理、锁屏登录等特性。通过 HTTP API 可以实现对这些功能的远程调用。

## 基础信息

- **服务地址**: `http://localhost:端口号`
- **请求格式**: GET 请求
- **响应格式**: JSON
- **字符编码**: UTF-8

## 通用响应格式

所有API请求都返回统一的JSON格式：

```json
{
  "status": "状态码",
  "error": "错误信息（可选）"
}
```

### 状态码说明

| 状态码 | 说明 |
|--------|------|
| `success` | 操作成功 |
| `failed` | 操作失败 |
| `lock_success` | 锁屏成功 |
| `login_success` | 登录成功 |
| `locked` | 已锁定状态 |
| `unlocked` | 未锁定状态 |
| `opened` | 应用已打开 |
| `closed` | 应用已关闭 |
| `auto_login_disabled` | 自动登录功能已禁用 |
| `password_not_set` | 未设置登录密码 |
| `unknown` | 未知操作 |

## 媒体控制接口

### 播放/暂停
- **接口**: `GET /api/space`
- **功能**: 切换音乐/视频播放状态
- **示例**:
  ```bash
  curl http://localhost:8080/api/space
  ```
- **响应**: `{"status":"success"}`

### 下一曲
- **接口**: `GET /api/next`
- **功能**: 播放下一个曲目
- **示例**:
  ```bash
  curl http://localhost:8080/api/next
  ```

### 上一曲
- **接口**: `GET /api/prev`
- **功能**: 播放上一个曲目
- **示例**:
  ```bash
  curl http://localhost:8080/api/prev
  ```

### 音量控制

#### 增加音量
- **接口**: `GET /api/volumeup`
- **功能**: 系统音量增加
- **示例**:
  ```bash
  curl http://localhost:8080/api/volumeup
  ```

#### 减小音量
- **接口**: `GET /api/volumedown`
- **功能**: 系统音量减小
- **示例**:
  ```bash
  curl http://localhost:8080/api/volumedown
  ```

#### 静音切换
- **接口**: `GET /api/mute`
- **功能**: 切换系统静音状态
- **示例**:
  ```bash
  curl http://localhost:8080/api/mute
  ```

## 方向控制接口

### 向上箭头
- **接口**: `GET /api/arrowup`
- **功能**: 模拟键盘向上箭头按键
- **示例**:
  ```bash
  curl http://localhost:8080/api/arrowup
  ```

### 向下箭头
- **接口**: `GET /api/arrowdown`
- **功能**: 模拟键盘向下箭头按键
- **示例**:
  ```bash
  curl http://localhost:8080/api/arrowdown
  ```

## 锁屏和登录接口

### 智能锁屏/登录
- **接口**: `GET /api/lock`
- **功能**: 根据当前状态智能执行锁屏或登录操作
- **逻辑**:
  - 如果当前未锁屏：执行锁屏操作
  - 如果当前已锁屏：执行自动登录（需要启用自动登录功能并设置密码）
- **前置条件**:
  - 需要授予应用辅助功能权限
  - 自动登录功能需要在设置中启用
  - 需要设置登录密码
- **示例**:
  ```bash
  curl http://localhost:8080/api/lock
  ```
- **响应**:
  - 锁屏成功: `{"status":"lock_success"}`
  - 登录成功: `{"status":"login_success"}`
  - 自动登录未启用: `{"status":"auto_login_disabled","error":"自动登录功能已禁用"}`
  - 未设置密码: `{"status":"password_not_set","error":"未设置登录密码"}`

### 查询锁屏状态
- **接口**: `GET /api/lock_status`
- **功能**: 查询当前屏幕锁定状态
- **示例**:
  ```bash
  curl http://localhost:8080/api/lock_status
  ```
- **响应**:
  - 已锁定: `{"status":"locked"}`
  - 未锁定: `{"status":"unlocked"}`

## 应用管理接口

### 抖音应用开关
- **接口**: `GET /api/toggle_douyin`
- **功能**: 智能切换抖音应用状态
- **逻辑**:
  - 如果抖音未运行：打开抖音
  - 如果抖音正在运行：关闭抖音
- **Bundle ID**: `com.bytedance.douyin.desktop`
- **示例**:
  ```bash
  curl http://localhost:8080/api/toggle_douyin
  ```
- **响应**:
  - 打开成功: `{"status":"opened"}`
  - 关闭成功: `{"status":"closed"}`

### 汽水音乐应用开关
- **接口**: `GET /api/toggle_qishui`
- **功能**: 智能切换汽水音乐应用状态
- **逻辑**:
  - 如果汽水音乐未运行：打开汽水音乐
  - 如果汽水音乐正在运行：关闭汽水音乐
- **Bundle ID**: `com.soda.music`
- **示例**:
  ```bash
  curl http://localhost:8080/api/toggle_qishui
  ```
- **响应**:
  - 打开成功: `{"status":"opened"}`
  - 关闭成功: `{"status":"closed"}`

### 应用状态查询

#### 抖音状态
- **接口**: `GET /api/status_douyin`
- **功能**: 查询抖音应用运行状态
- **示例**:
  ```bash
  curl http://localhost:8080/api/status_douyin
  ```
- **响应**:
  - 运行中: `{"status":"running"}`
  - 未运行: `{"status":"stopped"}`

#### 汽水音乐状态
- **接口**: `GET /api/status_qishui`
- **功能**: 查询汽水音乐应用运行状态
- **示例**:
  ```bash
  curl http://localhost:8080/api/status_qishui
  ```
- **响应**:
  - 运行中: `{"status":"running"}`
  - 未运行: `{"status":"stopped"}`

## 权限要求

### 辅助功能权限
以下功能需要应用获得辅助功能权限：

1. **媒体控制**: 所有媒体按键模拟
2. **方向控制**: 箭头按键模拟
3. **锁屏登录**: 密码输入和按键模拟
4. **应用关闭**: 强制终止应用进程

### 权限检查
应用会在执行需要权限的操作前自动检查权限状态，如果缺少权限会返回失败响应。

## 配置要求

### 登录密码设置
要使用自动登录功能，需要：

1. **设置密码**: 在应用设置中配置登录密码（4-20个字符）
2. **启用自动登录**: 在设置中开启"启用自动登录功能"
3. **授予权限**: 确保应用有辅助功能权限

### 密码验证规则
- **长度**: 4-20个字符
- **字符**: 支持字母和数字
- **存储**: 使用 UserDefaults 安全存储
- **验证**: 支持实时验证和更新

## 错误处理

### 常见错误及解决方案

1. **`缺少辅助功能权限`**
   - 解决方案：在系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能中添加 iDict

2. **`自动登录功能已禁用`**
   - 解决方案：在应用设置中启用自动登录功能

3. **`未设置登录密码`**
   - 解决方案：在应用设置中配置登录密码

4. **`未知操作`**
   - 解决方案：检查API接口路径是否正确

5. **`操作失败`**
   - 解决方案：检查系统状态和应用权限，重试操作

## 使用示例

### JavaScript/TypeScript 示例

```javascript
// 媒体控制
async function playPause() {
  const response = await fetch('/api/space');
  const data = await response.json();
  console.log('播放/暂停:', data.status);
}

// 锁屏/登录
async function smartLock() {
  const response = await fetch('/api/lock');
  const data = await response.json();

  switch(data.status) {
    case 'lock_success':
      console.log('锁屏成功');
      break;
    case 'login_success':
      console.log('登录成功');
      break;
    case 'auto_login_disabled':
      console.error('自动登录功能已禁用');
      break;
    case 'password_not_set':
      console.error('未设置登录密码');
      break;
  }
}

// 应用切换
async function toggleDouyin() {
  const response = await fetch('/api/toggle_douyin');
  const data = await response.json();
  console.log('抖音操作:', data.status === 'opened' ? '已打开' : '已关闭');
}
```

### Swift 示例

```swift
import Foundation

class iDictAPIClient {
    private let baseURL: String

    init(port: Int = 8080) {
        self.baseURL = "http://localhost:\(port)"
    }

    func playPause() async throws -> String {
        let url = URL(string: "\(baseURL)/api/space")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(APIResponse.self, from: data)
        return response.status
    }

    func smartLock() async throws -> LockResponse {
        let url = URL(string: "\(baseURL)/api/lock")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(LockResponse.self, from: data)
    }
}

struct APIResponse: Codable {
    let status: String
    let error: String?
}

struct LockResponse: Codable {
    let status: String
    let error: String?
}
```

### Python 示例

```python
import requests
import json

class iDictAPI:
    def __init__(self, port=8080):
        self.base_url = f"http://localhost:{port}"

    def play_pause(self):
        """播放/暂停"""
        response = requests.get(f"{self.base_url}/api/space")
        return response.json()

    def smart_lock(self):
        """智能锁屏/登录"""
        response = requests.get(f"{self.base_url}/api/lock")
        return response.json()

    def toggle_douyin(self):
        """切换抖音应用"""
        response = requests.get(f"{self.base_url}/api/toggle_douyin")
        return response.json()

    def get_lock_status(self):
        """获取锁屏状态"""
        response = requests.get(f"{self.base_url}/api/lock_status")
        return response.json()

# 使用示例
if __name__ == "__main__":
    api = iDictAPI()

    # 播放/暂停
    result = api.play_pause()
    print(f"播放控制: {result['status']}")

    # 智能锁屏
    lock_result = api.smart_lock()
    if lock_result['status'] == 'lock_success':
        print("锁屏成功")
    elif lock_result['status'] == 'login_success':
        print("登录成功")
    else:
        print(f"操作失败: {lock_result.get('error', '未知错误')}")
```

## 文件结构

### 核心文件

- **iDictController.swift** - 主控制器，包含：
  - `MediaController` 类：媒体控制、应用管理、锁屏登录
  - `MediaHTTPServer` 类：HTTP服务器和API处理
  - 错误定义和日志记录

- **SettingsManager.swift** - 设置管理器：
  - 用户配置管理
  - 密码验证和存储
  - 自动登录设置

- **SettingsView.swift** - 设置界面：
  - 密码配置界面
  - API密钥管理
  - 安全设置选项

- **index.html** - 远程控制界面：
  - 响应式Web界面
  - 触摸友好的控制按钮
  - 实时状态显示

## 更新日志

### v2.2.0 (2024-11-25)
- 修复抖音和汽水音乐应用无法打开的问题
- `openApp` 函数现在同时支持中英文应用名
- 优化应用状态检测逻辑，支持多种检测方法
- 新增 `SettingsManager` 统一管理所有配置
- 改进错误处理和日志记录

### v2.1.0
- 重命名 `MediaController.swift` 为 `iDictController.swift` 以更好地反映文件功能
- 优化应用开关逻辑，修复重复执行问题
- 添加详细的日志记录和错误处理

### v2.0.0
- 新增智能锁屏/登录功能
- 新增应用开关功能（抖音、汽水音乐）
- 新增密码设置和自动登录配置
- 优化权限检查和错误处理
- 改进远程控制界面

### v1.0.0
- 基础媒体控制功能
- HTTP API 接口
- 远程控制界面

---

**注意**: 使用本 API 前请确保 iDict 应用正在运行，并且已获得必要的系统权限。