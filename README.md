# WordPress 自动维护系统

一个功能强大的 WordPress 自动运行维护工具，使用 Bash 脚本编程，支持从 Lsky 图床读取图片、自动生成文章内容并发布到 WordPress。

## 功能特性

### 核心功能
- ✅ **WordPress API 交互** - 完整的 REST API 支持
- ✅ **Lsky 图床集成** - 自动从图床获取图片并上传到 WordPress
- ✅ **文章自动生成** - 从 URL/RSS 读取内容并生成文章
- ✅ **页面管理** - 自动创建必要页面（关于、联系、隐私政策等）
- ✅ **分类标签管理** - 批量创建和管理分类及标签

### 主要特点
- 🔒 安全的 API 认证（支持基础认证和 Bearer Token）
- 📝 完整的日志记录系统
- ⚡ 高效的批量操作
- 🎯 智能特色图片选择
- 🔄 定时任务支持

## 项目结构

```
wp-auto-maintenance/
├── config/
│   └── wordpress.conf          # 配置文件（用户名、密码、API密钥等）
├── modules/
│   ├── wordpress-api.sh        # WordPress API 交互模块
│   ├── lsky-gallery.sh         # Lsky 图床集成模块
│   ├── content-generator.sh    # 文章内容生成模块
│   ├── page-manager.sh         # 页面管理模块
│   └── category-tag.sh         # 分类标签管理模块
├── main.sh                     # 主控制脚本
└── README.md                  # 本文档
```

## 安装要求

### 系统要求
- Linux/Unix 系统
- Bash 4.0+
- curl
- jq (JSON 处理)

### 安装依赖

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install curl jq

# CentOS/RHEL
sudo yum install curl jq

# macOS
brew install curl jq
```

## 快速开始

### 1. 配置 WordPress

编辑 `config/wordpress.conf`：

```bash
# WordPress 站点配置
WP_SITE_URL="https://your-wordpress-site.com"
WP_ADMIN_USER="your_admin_username"
WP_ADMIN_PASSWORD="your_admin_password"

# Lsky 图床配置（可选）
LSKY_BASE_URL="https://your-lsky-site.com"
LSKY_API_TOKEN="your_lsky_api_token"
```

### 2. 运行初始化

```bash
# 进入项目目录
cd /home/sooogooo/claude/wpauto

# 运行初始化（创建必要页面、分类、标签）
./main.sh init
```

### 3. 批量生成文章

```bash
# 从配置的内容源批量生成文章
./main.sh batch-posts

# 指定生成文章数量（最大3篇）
./main.sh batch-posts 3
```

## 使用指南

### 基本命令

#### 显示帮助
```bash
./main.sh --help
./main.sh -h
```

#### 显示版本
```bash
./main.sh --version
./main.sh -v
```

#### 检查网站状态
```bash
./main.sh status
```

### 初始化命令

#### 完整初始化
```bash
./main.sh init
```
这会执行：
- 初始化默认分类和标签
- 创建必要页面（关于、联系、隐私政策等）
- 从 Lsky 图床更新媒体库

#### 单独初始化
```bash
# 仅创建必要页面
./main.sh create-pages

# 仅初始化分类
./main.sh init-categories

# 仅初始化标签
./main.sh init-tags
```

### 文章管理

#### 创建单篇文章
```bash
./main.sh create-post "文章标题" "文章内容"
```

#### 批量创建文章
```bash
./main.sh batch-posts [数量]
```

默认从 `config/wordpress.conf` 中配置的 `CONTENT_SOURCES` 读取内容。

### 媒体库管理

#### 从 Lsky 图床更新媒体库
```bash
./main.sh update-media
```

## 配置说明

### WordPress 配置 (`config/wordpress.conf`)

```bash
# WordPress 站点配置
WP_SITE_URL="https://your-wordpress-site.com"
WP_ADMIN_USER="your_admin_username"
WP_ADMIN_PASSWORD="your_admin_password"

# REST API Token（推荐使用应用密码）
WP_API_TOKEN=""

# Lsky 图床配置
LSKY_BASE_URL="https://your-lsky-site.com"
LSKY_API_TOKEN="your_lsky_api_token"

# 默认分类和标签
DEFAULT_CATEGORIES=("技术" "教程" "新闻" "资源")
DEFAULT_TAGS=("WordPress" "自动化" "工具" "开发")

# 内容源（RSS 或网页 URL）
CONTENT_SOURCES=(
    "https://example.com/rss"
    "https://news.example.com/feed"
)

# 发布设置
PUBLISH_STATUS="publish"  # publish, draft, pending
AUTHOR_ID=1

# 日志配置
LOG_FILE="/var/log/wp-auto-maintenance.log"
```

### 获取 WordPress 应用密码

1. 登录 WordPress 后台
2. 进入 用户 > 个人资料
3. 滚动到"应用密码"部分
4. 创建新的应用密码
5. 将生成的密码填入 `WP_API_TOKEN`

### 获取 Lsky API Token

1. 登录 Lsky 图床
2. 进入设置或个人中心
3. 找到 API 设置
4. 生成 API Token
5. 填入 `LSKY_API_TOKEN`

## 高级用法

### 定时任务配置

将以下内容添加到 crontab：
```bash
# 每天 8:00 自动发布文章
0 8 * * * ./main.sh cron >> /var/log/wp-cron.log 2>&1

# 每周一更新媒体库
0 9 * * 1 cd /home/sooogooo/claude/wpauto && ./main.sh update-media >> /var/log/wp-media.log 2>&1
```

添加定时任务：
```bash
crontab -e
```

粘贴上面的配置并保存。

## 故障排除

### 查看日志
```bash
# 实时查看日志
tail -f /var/log/wp-auto-maintenance.log

# 查看最近100行日志
tail -n 100 /var/log/wp-auto-maintenance.log
```

### 常见问题

#### 1. 认证失败
**解决方法**：
- 检查 `WP_SITE_URL` 是否正确
- 确认用户名和密码正确
- 尝试使用应用密码（推荐）
- 检查 WordPress 是否启用了 REST API

#### 2. 无法连接 Lsky 图床
**解决方法**：
- 确认 `LSKY_BASE_URL` 格式正确
- 检查 API Token 是否有效
- 测试 API：
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" https://your-lsky-site.com/api/v1/images
```

#### 3. curl 命令失败
```bash
错误: curl: (60) SSL certificate problem
```

**解决方法**：
```bash
# 临时跳过 SSL 验证（不推荐生产环境使用）
curl -k https://your-site.com

# 或者更新 CA 证书
sudo apt-get install ca-certificates
```

### 调试模式

在配置文件中设置：
```bash
LOG_LEVEL="DEBUG"
```

这会输出更详细的调试信息。

## 安全建议

1. **配置文件权限**：
```bash
chmod 600 config/wordpress.conf
```

2. **使用应用密码**：推荐在 WordPress 中使用应用密码

3. **日志权限**：
```bash
sudo touch /var/log/wp-auto-maintenance.log
sudo chown sooogooo:sooogooo /var/log/wp-auto-maintenance.log
chmod 600 /var/log/wp-auto-maintenance.log
```

## 许可证

MIT License

## 更新日志

### v1.0.0
- 初始版本发布
- 支持 WordPress API 交互
- 支持 Lsky 图床集成
- 支持文章内容自动生成
- 支持页面、分类、标签管理
- 支持定时任务
