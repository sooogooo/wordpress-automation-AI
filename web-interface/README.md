# WordPress 自动维护系统 - Web 管理界面

这是一个用于配置和管理 WordPress 自动维护系统的现代 Web 界面。

## 📋 功能特性

✅ **用户登录系统** - 安全的 Web 管理界面，支持自定义密码
✅ **WordPress 参数配置** - 配置站点、XML-RPC、用户名、应用密码
✅ **文章分类和标签管理** - 设置默认分类和标签
✅ **兰空图床集成** - 配置图床 API 和相册
✅ **多 AI 模型支持** - 支持 Moonshot (Kimi)、DeepSeek、SiliconFlow
✅ **AI 提示词定制** - 自定义文章生成提示词
✅ **Bash 脚本生成** - 一键生成可执行脚本
✅ **配置文件导出** - 支持下载和复制配置
✅ **本地存储** - 自动保存配置，无需重复输入

## 🚀 快速开始

### 1. 打开 Web 界面

```bash
cd /home/sooogooo/claude/wpauto/web-interface
# 使用 Python 内置服务器启动
python3 -m http.server 8080
```

然后在浏览器中访问：`http://localhost:8080`

### 2. 登录系统

- **用户名**: `admin`
- **默认密码**: `admin9900`

首次登录后建议修改密码。

## 🔧 配置步骤

### 第一步：WordPress 设置

1. **WordPress 网址**: 例如 `https://www.ai.stemcell.gold`
2. **XML-RPC 地址**: 通常是 `https://你的网址/xmlrpc.php`
3. **用户名**: 你的 WordPress 用户名
4. **应用程序密码**: 在 WordPress 用户资料中生成
5. **博客 ID**: 通常是 `1`
6. **发布状态**: `publish` (立即发布) / `draft` (草稿) / `pending` (待审核)
7. **默认分类和标签**: 用逗号分隔

### 第二步：兰空图床设置

1. **兰空图床 API 地址**: 例如 `https://lsky.ai.stemcell.gold/api/v1`
2. **认证 Token**: 在兰空图床设置中生成
3. **默认相册名称**: 例如 `ai`
4. **每篇文章插入图片数量**: 1-10 张

### 第三步：AI 模型设置

#### 选择 AI 提供商

支持三种 AI 提供商：

**1. Moonshot (月之暗面/Kimi)**
- API Key: 从 [platform.moonshot.cn](https://platform.moonshot.cn) 获取
- API 地址: `https://api.moonshot.cn/v1`
- 模型: `moonshot-v1-128k` (推荐)

**2. DeepSeek**
- API Key: 从 [platform.deepseek.com](https://platform.deepseek.com) 获取
- API 地址: `https://api.deepseek.com`
- 模型: `deepseek-chat` 或 `deepseek-coder`

**3. SiliconFlow**
- API Key: 从 [cloud.siliconflow.cn](https://cloud.siliconflow.cn) 获取
- API 地址: `https://api.siliconflow.cn/v1`
- 模型: `Pro/deepseek-ai/DeepSeek-R1` (推荐)

#### AI 提示词设置

默认提示词（可自定义）：

```
请以以下标题写一篇1200-1500字的医美消费文章。标题： {title}

要求：
1. 文章前面加一段箴言式开篇，保持美观的Markdown排版；
2. 文章正文内容清晰有层次，分段合理；
3. 请在文章末尾单独一行返回文章关键词，格式为 "关键字标签: 关键词1, 关键词2, …"；
4. 请在文章末尾另外单独一行返回文章建议分类，格式为 "建议分类: 分类1, 分类2, …"。
```

#### 其他参数

- **最大 Tokens**: 4000 (推荐)
- **Temperature**: 0.7 (创意程度，0-2 之间)
- **标题源 URL**: 提供文章标题的文本文件地址

### 第四步：其他设置

**Web 管理设置**
- Web 管理用户名: `admin` (不能更改)
- Web 管理密码: 默认为 `admin9900`，建议修改

**日志设置**
- 日志文件路径: `/var/log/wp-auto-maintenance.log`
- 日志级别: INFO (推荐)

**特色图片设置**
- 特色图片质量: 95 (1-100)
- 最小图片尺寸: 600 像素
- 强制裁剪为方形: 建议勾选

**计划任务设置**
- 执行频率: `0 9 * * *` (每天9点)
- 启用计划任务: 勾选
- 每次生成文章数量: 3 (推荐)

## 💾 保存和生成

### 1. 保存配置

点击 "保存配置" 按钮，所有配置将保存到浏览器本地存储。

### 2. 生成 Bash 脚本

点击 "生成 Bash 脚本" 按钮，系统会生成：

1. **配置文件** (`config.txt`)
2. **Bash 脚本** (`generate-article.sh`)

### 3. 下载或使用

你可以：
- **下载配置文件**：保存到 `~/.wp-auto-config.conf`
- **下载 Bash 脚本**：保存到项目目录
- **复制配置**：直接复制内容粘贴到文件
- **复制脚本**：直接复制内容粘贴到文件

## 📋 在 Linux 系统中使用

### 1. 保存配置文件

```bash
# 将下载的配置文件保存到用户主目录
cp ~/Downloads/config.txt ~/.wp-auto-config.conf
```

### 2. 保存并设置 Bash 脚本

```bash
# 进入项目目录
cd /path/to/wp-auto-maintenance

# 将下载的脚本保存为 generate-article.sh
cp ~/Downloads/generate-article.sh ./

# 添加执行权限
chmod +x generate-article.sh
```

### 3. 手动测试运行

```bash
# 单篇文章测试
./generate-article.sh

# 批量生成3篇文章
./generate-article.sh -n 3

# 使用指定标题
./generate-article.sh -t "医美新趋势"

# DRY RUN 测试（不实际发布）
./generate-article.sh --dry-run
```

### 4. 添加到计划任务

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天9点自动执行）
0 9 * * * cd /path/to/wp-auto-maintenance && ./generate-article.sh -n 3 >> /var/log/wp-cron.log 2>&1

# 或者每周一9点执行
0 9 * * 1 cd /path/to/wp-auto-maintenance && ./generate-article.sh -n 3 >> /var/log/wp-cron.log 2>&1
```

### 5. 查看日志

```bash
# 实时查看日志
tail -f /var/log/wp-auto-maintenance.log

# 查看 cron 日志 (如果重定向到文件)
tail -f /var/log/wp-cron.log
```

## 🔒 安全建议

1. **修改默认密码**
   - 首次登录后，在 "其他设置" -> "Web 管理密码" 中修改

2. **保护配置文件**
   ```bash
   chmod 600 ~/.wp-auto-config.conf
   ```

3. **保护 API Key**
   - 不要在公共地方暴露 API Key
   - 定期更换 API Key
   - 使用环境变量存储敏感信息（可选）

4. **日志文件权限**
   ```bash
   sudo touch /var/log/wp-auto-maintenance.log
   sudo chown your-username:your-username /var/log/wp-auto-maintenance.log
   chmod 600 /var/log/wp-auto-maintenance.log
   ```

## 🔧 故障排除

### 1. Web 界面无法打开

确保在项目目录下启动服务器：
```bash
cd /home/sooogooo/claude/wpauto/web-interface
python3 -m http.server 8080
```

### 2. 无法登录

- 确认用户名是 `admin`
- 默认密码是 `admin9900`
- 清除浏览器缓存或 localStorage 后重试

### 3. 配置丢失

配置保存在浏览器 localStorage，如果清除浏览器数据会丢失。
建议定期点击 "保存配置"，或下载配置文件备份。

### 4. 脚本执行失败

- 检查配置文件是否存在: `~/.wp-auto-config.conf`
- 检查日志: `tail -n 50 /var/log/wp-auto-maintenance.log`
- 检查权限: `chmod +x generate-article.sh`
- 测试连接: 使用 `--dry-run` 参数

### 5. AI API 返回错误

- 检查 API Key 是否有效
- 检查是否有足够的余额/配额
- 检查网络连接
- 查看日志中的详细错误信息

## 📝 更新日志

### v1.0.0
- 初始版本发布
- 支持完整的配置管理
- 支持多 AI 提供商
- 支持生成和下载脚本
- 支持登录系统

## 🔮 未来计划

- [ ] 支持实时预览文章
- [ ] 支持手动触发发布
- [ ] 支持查看发布历史
- [ ] 支持多站点管理
- [ ] 支持 API 余额监控
- [ ] 支持模板库管理

## 📞 支持

如有问题或建议：
1. 查看日志文件
2. 检查配置是否正确
3. 测试每个模块的连接
4. 提交 Issue（如果有代码仓库）

## 📄 许可证

MIT License

## 🙏 致谢

- WordPress REST API / XML-RPC
- 兰空图床 (Lsky)
- Moonshot (Kimi)
- DeepSeek
- SiliconFlow
- Bash 社区
