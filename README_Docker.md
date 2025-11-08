# WordPress 自动维护系统 (Docker 版)

基于 Docker 容器化的 WordPress 自动化文章生成和发布系统。

## ✨ 功能特性

- 🤖 **AI 文章自动生成** - 支持国内主流大模型（Moonshot/Kimi、DeepSeek、SiliconFlow）
- 🖼️ **兰空图床集成** - 自动从图床获取图片插入文章
- 📝 **WordPress 自动发布** - 支持 XML-RPC 和 REST API
- 🎯 **特色图片设置** - 自动为文章设置特色图片
- 🌐 **Web 管理界面** - 图形化配置管理
- ⏰ **计划任务** - 定时自动发布
- 🐳 **Docker 支持** - 一键部署，环境隔离

## 📁 项目结构

```
wordpress-automation-AI/
├── config/                          # 配置文件
│   ├── wordpress.conf              # WordPress 通用配置
│   ├── your-website.conf         # 网站配置（需自行创建）
│   └── your-website.conf.default # 配置示例
├── modules/                        # 功能模块
│   ├── ai-content-generator.sh   # AI 文章生成
│   ├── xmlrpc-api.sh             # WordPress XML-RPC API
│   ├── lsky-gallery.sh           # 兰空图床集成
│   ├── featured-image.sh         # 特色图片管理
│   └── ...                       # 其他模块
├── web-interface/                  # Web 管理界面
│   ├── index.html               # 主页面
│   ├── style.css                # 样式
│   ├── app.js                   # JavaScript
│   └── README.md                # 使用文档
├── logs/                         # 日志目录
├── output/                       # 输出目录
├── temp/                         # 临时文件
├── Dockerfile                     # Docker 镜像配置
├── docker-compose.yml           # Docker Compose 配置
├── docker-build-and-run.sh      # 一键部署脚本
├── DOCKER_DEPLOY.md            # Docker 部署指南
└── README.md                   # 项目文档
```

## 🚀 快速开始

### 方法 1: 一键部署脚本（推荐）

```bash
# 克隆项目
git clone https://github.com/sooogooo/wordpress-automation-AI.git
cd wordpress-automation-AI

# 运行一键部署脚本
./docker-build-and-run.sh
```

脚本会自动：
1. 检查 Docker 环境
2. 创建必要目录
3. 提示你填写配置文件
4. 构建 Docker 镜像
5. 启动容器和服务

### 方法 2: 手动部署

```bash
# 克隆项目
git clone https://github.com/sooogooo/wordpress-automation-AI.git
cd wordpress-automation-AI

# 创建配置文件
mkdir -p ./config ./logs ./output ./temp
cp config/your-website.conf.default config/your-website.conf

# 编辑配置文件（填写实际参数）
vim config/your-website.conf

# 构建镜像
docker build -t wp-auto-maintenance:1.0.0 .

# 启动服务
docker-compose up -d
```

## ⚙️ 配置要求

### 必需配置

编辑 `config/your-website.conf` 文件：

```bash
# WordPress 配置
WP_SITE_URL="https://your-wordpress-site.com"
WP_XMLRPC_URL="https://your-wordpress-site.com/xmlrpc.php"
WP_ADMIN_USER="your_username"
WP_ADMIN_PASSWORD="your_password_here"

# 兰空图床配置
LSKY_BASE_URL="https://your-lsky-domain.com/api/v1"
LSKY_AUTH="Bearer YOUR_LSKY_API_TOKEN"
LSKY_ALBUM_NAME="ai"

# AI 模型配置（选择一个或多个）
# Moonshot/Kimi
MOONSHOT_API_KEY="sk-xxxxxxxxxxxxxxxx"
# DeepSeek
DEEPSEEK_API_KEY="sk-xxxxxxxxxxxxxxxx"
# SiliconFlow
SILICONFLOW_API_KEY="sk-xxxxxxxxxxxxxxxx"
```

## 📋 Docker 常用命令

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f wp-auto-maintenance

# 进入容器
docker-compose exec wp-auto-maintenance bash

# 在容器内运行脚本
./generate-medical-article.sh -n 3

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新服务
docker-compose pull && docker-compose up -d

# 查看容器状态
docker-compose ps
```

## 🌐 Web 管理界面

### 启动 Web 界面

```bash
# 方式 1: 在容器内启动
docker-compose exec wp-auto-maintenance bash
cd /app/web-interface
./start-web.sh 8080

# 方式 2: 使用 docker-compose.yml 中的端口映射访问
# docker-compose.yml 已经将 8080 端口映射到主机
# 直接访问: http://localhost:8080
```

### Web 界面功能

- 🔐 用户登录（默认密码: admin9900）
- ⚙️ WordPress 参数配置
- 🖼️ 兰空图床配置
- 🤖 AI 模型配置（支持多提供商）
- 📝 AI 提示词定制
- ⚡ 一键生成 Bash 脚本
- 💾 导出配置文件

## 🎯 使用场景

### 场景 1: 医美文章自动生成

```bash
# 在容器内执行
docker-compose exec wp-auto-maintenance /app/generate-medical-article.sh -n 3
```

自动执行：
1. 从标题源获取随机标题
2. 使用 AI 生成 1200-1500 字文章
3. 从兰空图床插入图片
4. 发布到 WordPress
5. 设置特色图片

### 场景 2: 特色图片批量设置

```bash
# 为所有文章设置特色图片
docker-compose exec wp-auto-maintenance /app/modules/featured-image.sh
```

### 场景 3: WordPress 网站初始化

```bash
# 进入容器
docker-compose exec wp-auto-maintenance bash

# 初始化网站
./main.sh init
```

### 场景 4: 定时自动发布

Docker Compose 已包含定时任务服务（wp-cron），在 `docker-compose.yml` 中可以配置：

```yaml
# 默认配置: 每天9点自动发布3篇文章
cron_schedule: "0 9 * * *"
max_posts: 3
```

## 📦 环境变量

可以在运行容器时传入以下环境变量：

```bash
docker run -e TZ=Asia/Shanghai \
           -e LOG_LEVEL=INFO \
           -v $(pwd)/config:/app/config \
           wp-auto-maintenance:latest
```

支持的变量：
- `TZ`: 时区 (默认: Asia/Shanghai)
- `LOG_LEVEL`: 日志级别 (DEBUG/INFO/WARN/ERROR)
- `CONFIG_PATH`: 配置文件路径
- `PYTHONUNBUFFERED`: Python 输出缓冲

## 📂 数据持久化

以下目录已配置为持久化卷：

- `./config` - 配置文件
- `./logs` - 日志文件
- `./output` - 输出目录
- `./temp` - 临时文件

**重要**: 请定期备份 `./config` 目录！

## 🔧 开发调试

### 本地开发

```bash
# 克隆项目
git clone https://github.com/sooogooo/wordpress-automation-AI.git
cd wordpress-automation-AI

# 创建本地开发环境
pip install Pillow requests

# 运行测试
./docker-build-and-run.sh --dry-run
```

### 调试模式

```bash
# 在 docker-compose.yml 中添加
debug_mode: true
log_level: DEBUG

# 重建并启动
docker-compose up --build
```

## 🐛 故障排除

### 配置错误

```bash
# 进入容器检查配置
docker-compose exec wp-auto-maintenance bash

# 测试配置文件
cd /app
source config/your-website.conf
```

### API 连接问题

```bash
# 测试 WordPress 连接
docker-compose exec wp-auto-maintenance \
  python3 -c "import xmlrpc.client; wp = xmlrpc.client.ServerProxy('YOUR_XMLRPC_URL'); print('OK')"

# 测试兰空图床
docker-compose exec wp-auto-maintenance \
  curl -H "Authorization: Bearer YOUR_TOKEN" https://your-lsky.com/api/v1/albums
```

### 查看详细日志

```bash
# 进入容器查看日志
docker-compose exec wp-auto-maintenance bash
cat /app/logs/wp-auto-maintenance.log

# 或者从宿主机查看
 tail -f logs/wp-auto-maintenance.log
```

## 🔄 更新升级

```bash
# 1. 停止当前服务
docker-compose down

# 2. 更新代码
git pull origin main

# 3. 重建镜像
docker-compose build --no-cache

# 4. 启动服务
docker-compose up -d

# 5. 验证
docker-compose logs -f --tail=100
```

## 🛡️ 安全建议

1. **保护配置文件**
   ```bash
   chmod 600 config/your-website.conf
   ```

2. **使用环境变量存储敏感信息**
   ```bash
   export WP_PASSWORD="your_password"
   docker-compose up -d
   ```

3. **定期备份 config 目录**
   ```bash
   tar -czf config-backup-$(date +%Y%m%d).tar.gz config/
   ```

4. **限制容器资源使用**
   ```yaml
   # 在 docker-compose.yml 中添加
   deploy:
     resources:
       limits:
         memory: 2G
         cpus: '2'
   ```

## 📄 许可证

MIT License

## 📞 支持

如有问题：

1. 查看日志: `docker-compose logs`
2. 检查配置: `cat config/your-website.conf`
3. 提交 Issue: [GitHub Issues](https://github.com/sooogooo/wordpress-automation-AI/issues)

## 🙏 致谢

- WordPress REST API / XML-RPC
- 兰空图床 (Lsky)
- Moonshot (Kimi)
- DeepSeek
- SiliconFlow
- Docker 社区

---

**开始使用 Docker 部署你的 WordPress 自动维护系统！** 🚀
