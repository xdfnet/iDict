# iDict API 文档

## 基础信息

- **服务地址**: `http://localhost:8888`
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
| `locked` | 已锁定状态 |
| `unlocked` | 未锁定状态 |
| `opened` | 应用已打开 |
| `closed` | 应用已关闭 |
| `unknown` | 未知操作 |

## 媒体控制接口

### 播放/暂停
- **接口**: `GET /api/space`
- **功能**: 切换音乐/视频播放状态
- **示例**: `curl http://localhost:8888/api/space`
- **响应**: `{"status":"success"}`

### 下一曲
- **接口**: `GET /api/next`
- **功能**: 播放下一个曲目
- **响应**: `{"status":"success"}`

### 上一曲
- **接口**: `GET /api/prev`
- **功能**: 播放上一个曲目
- **响应**: `{"status":"success"}`

### 音量控制

#### 增加音量
- **接口**: `GET /api/volumeup`
- **功能**: 系统音量增加

#### 减小音量
- **接口**: `GET /api/volumedown`
- **功能**: 系统音量减小

#### 静音切换
- **接口**: `GET /api/mute`
- **功能**: 切换系统静音状态

## 方向控制接口

### 向上箭头
- **接口**: `GET /api/arrowup`
- **功能**: 模拟键盘向上箭头按键

### 向下箭头
- **接口**: `GET /api/arrowdown`
- **功能**: 模拟键盘向下箭头按键

## 锁屏接口

### 锁屏操作
- **接口**: `GET /api/lock`
- **功能**: 执行锁屏操作
- **逺辑**:
  - 如果当前未锁屏：执行锁屏操作
  - 如果当前已锁屏：返回错误（软件无法唤醒息屏）
- **前置条件**:
  - 需要授予应用辅助功能权限
- **响应**:
  - 锁屏成功: `{"status":"lock_success"}`
  - 已锁屏: `{"status":"locked","error":"屏幕已锁定，无法通过软件唤醒"}`

### 查询锁屏状态
- **接口**: `GET /api/lock_status`
- **功能**: 查询当前屏幕锁定状态
- **响应**:
  - 已锁定: `{"status":"locked"}`
  - 未锁定: `{"status":"unlocked"}`

## 应用管理接口

### 抖音应用开关
- **接口**: `GET /api/toggle_douyin`
- **功能**: 智能切换抖音应用状态
- **Bundle ID**: `com.bytedance.douyin.desktop`
- **响应**:
  - 打开成功: `{"status":"opened"}`
  - 关闭成功: `{"status":"closed"}`

### 汽水音乐应用开关
- **接口**: `GET /api/toggle_qishui`
- **功能**: 智能切换汽水音乐应用状态
- **Bundle ID**: `com.soda.music`
- **响应**:
  - 打开成功: `{"status":"opened"}`
  - 关闭成功: `{"status":"closed"}`

### 应用状态查询

#### 抖音状态
- **接口**: `GET /api/status_douyin`
- **响应**: `{"status":"running"}` 或 `{"status":"stopped"}`

#### 汽水音乐状态
- **接口**: `GET /api/status_qishui`
- **响应**: `{"status":"running"}` 或 `{"status":"stopped"}`

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

### 权限配置

iDict 需要以下系统权限：

1. **辅助功能权限**: 用于模拟键盘和媒体控制
2. **授予权限**: 确保应用有辅助功能权限

## 使用示例

### Bash 示例

```bash
# 播放/暂停
curl http://localhost:8888/api/space

# 操锁屏
curl http://localhost:8888/api/lock

# 切换抖音应用
curl http://localhost:8888/api/toggle_douyin

# 查询锁屏状态
curl http://localhost:8888/api/lock_status
```

### JavaScript 示例

```javascript
// 媒体控制
async function playPause() {
  const response = await fetch('http://localhost:8888/api/space');
  const data = await response.json();
  console.log('播放/暂停:', data.status);
}

// 锁屏
async function lockScreen() {
  const response = await fetch('http://localhost:8888/api/lock');
  const data = await response.json();

  switch(data.status) {
    case 'lock_success':
      console.log('锁屏成功');
      break;
    case 'locked':
      console.error('屏幕已锁定');
      break;
  }
}

// 应用切换
async function toggleDouyin() {
  const response = await fetch('http://localhost:8888/api/toggle_douyin');
  const data = await response.json();
  console.log('抖音操作:', data.status === 'opened' ? '已打开' : '已关闭');
}
```

### Python 示例

```python
import requests

class iDictAPI:
    def __init__(self, host='localhost', port=8888):
        self.base_url = f"http://{host}:{port}"

    def play_pause(self):
        """播放/暂停"""
        response = requests.get(f"{self.base_url}/api/space")
        return response.json()

    def lock_screen(self):
        """锁屏"""
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
    
    # 锁屏
    lock_result = api.lock_screen()
    if lock_result['status'] == 'lock_success':
        print("锁屏成功")
    else:
        print(f"操作失败: {lock_result.get('error', '未知错误')}")
```

## 错误处理

### 常见错误及解决方案

1. **`缺少辅助功能权限`**
   - 解决方案：在系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能中添加 iDict

2. **`未知操作`**
   - 解决方案：检查API接口路径是否正确

3. **`操作失败`**
   - 解决方案：检查系统状态和应用权限，重试操作

## 应用管理配置

### 时间常量

iDict 应用管理功能使用以下时间配置：

| 常量 | 时间 | 说明 |
|------|------|------|
| `appLaunchWait` | 2秒 | 应用启动等待时间 |
| `appLaunchCheckInterval` | 0.3秒 | 应用启动二次检测间隔 |
| `appTerminateWait` | 0.5秒 | 应用终止检测间隔 |
| `appTerminateAttempts` | 10次 | 应用终止最大重试次数 |

### 应用启动流程

1. 执行 `open` 命令启动应用
2. 等待 **2秒** 检测应用是否运行
3. 如果未启动，再等待 **0.3秒** 进行二次检测
4. 激活应用到前台

### 应用关闭流程

1. 调用 `app.terminate()` 正常终止
2. 每隔 **0.5秒** 检测一次，最多 **10次**（总计5秒）
3. 如果超时仍未终止，调用 `forceTerminate()` 强制关闭

---

**注意**: 使用本 API 前请确保 iDict 应用正在运行，并且已获得必要的系统权限。
