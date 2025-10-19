# 腾讯翻译API配置示例

## 1. 获取腾讯云API密钥

1. 访问 [腾讯云控制台](https://console.cloud.tencent.com/)
2. 登录你的腾讯云账号
3. 进入"访问管理 > API密钥管理"
4. 创建新的API密钥或使用现有密钥
5. 记录你的SecretId和SecretKey

## 2. 配置环境变量（推荐方法）

在终端中编辑你的shell配置文件（如.zshrc）：

```bash
# 打开.zshrc文件
open ~/.zshrc

# 添加以下两行到文件末尾
export SecretId=你的SecretId
export SecretKey=你的SecretKey

# 保存文件后，重新加载配置
source ~/.zshrc
```

示例：
```bash
export SecretId=你的SecretId
export SecretKey=你的SecretKey
```

## 3. 重新编译应用

```bash
# 在项目根目录执行
xcodebuild -project iDict.xcodeproj -scheme iDict -configuration Debug build
```

## 4. 使用腾讯翻译

1. 运行iDict应用
2. 点击菜单栏中的iDict图标
3. 选择"Translation Service > 腾讯翻译"
4. 使用快捷键或复制文本进行翻译

## 注意事项

- 请妥善保管你的API密钥，不要泄露给他人
- 腾讯云翻译服务有免费额度，超出后会产生费用
- 如果遇到API调用失败，请检查环境变量是否正确设置、网络是否正常
- 使用环境变量是更安全的配置方式，避免将敏感信息硬编码在代码中
- 确保在运行应用前已经加载了环境变量（可以通过`echo $SecretId`验证）