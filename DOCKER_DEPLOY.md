# Docker 部署指南

本指南将帮助您使用 Docker 快速部署 WordPress 自动维护系统。

## 📋 前置要求

在开始之前，请确保您的系统已安装以下软件：

- **Docker** (版本 20.10+)
- **Docker Compose** (版本 2.0+)
- **Git** (用于克隆仓库)

## 🔧 安装 Docker 和 Docker Compose

### Ubuntu/Debian

```bash
# 更新包列表
sudo apt update

# 安装 Docker
sudo apt install -y docker.io docker-compose

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker-compose --version
```

### CentOS/RHEL

```bash
# 安装 Docker
sudo yum install -y docker docker-compose

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker-compose --version
```

## 📦 快速部署

### 1. 克隆项目

```bash
# 克隆仓库
git clone https://github.com/sooogooo/wordpress-automation-AI.git
cd wordpress-automation-AI
```

### 2. 配置环境

```bash
# 复制配置文件
mkdir -p ./config ./logs ./output ./temp

# 将示例配置文件重命名为正式配置文件
cp config/your-website.conf.default config/your-website.conf

# 编辑配置文件，填写实际的 API 密钥和连接信息
vim config/your-website.conf
```

### 3. 构建 Docker 镜像

```bash
# 构建镜像
docker-compose build

# 或者使用 docker build
docker build -t wp-auto-maintenance:1.0.0 .
```

### 4. 启动服务

```bash
# 启动所有服务（主服务 + 定时任务）
docker-compose up -d

# 只启动主服务
docker-compose up -d wp-auto-maintenance

# 查看服务状态
docker-compose ps
```

### 5. 验证部署

```bash
# 查看主容器日志
docker-compose logs -f wp-auto-maintenance

# 查看定时任务日志
docker-compose logs -f wp-cron
```

## 🚀 使用 Docker 运行脚本

### 方法 1: 直接在容器中运行

```bash
# 进入容器
docker-compose exec wp-auto-maintenance bash

# 在容器内运行脚本
cd /app
./generate-medical-article.sh -n 3

# 或者测试配置
./generate-medical-article.sh --dry-run

# 为特色图片篇
./modules/featured-image.sh
```

### 方法 2: 从外部运行

```bash
# 运行单篇文章生成
docker-compose exec wp-auto-maintenance /app/generate-medical-article.sh

# 批量生成 3 篇文章
docker-compose exec wp-auto-maintenance /app/generate-medical-article.sh -n 3

# 设置特色图片
docker-compose exec wp-auto-maintenance /app/modules/featured-image.sh
```

### 方法 3: 使用 docker run（单次执行）

```bash
# 构建镜像后
docker build -t wp-auto-maintenance .

# 运行单次任务
docker run --rm \
  -v $(pwd)/config:/app/config:rw \
  -v $(pwd)/logs:/app/logs:rw \
  -v $(pwd)/output:/app/output:rw \
  wp-auto-maintenance:latest \
  /app/generate-medical-article.sh --dry-run
```

## 🌐 访问 Web 管理界面

```bash
# 在浏览器中打开（如果使用默认端口映射）
open http://localhost:8080

# 或者手动进入容器启动 Web 服务
docker-compose exec wp-auto-maintenance bash
cd /app/web-interface
./start-web.sh 8080
```

然后在浏览器访问：`http://localhost:8080`

## 📂 目录结构

```
project/
├── config/                      # 配置目录（持久化）
│   ├── wordpress.conf          # WordPress 通用配置
│   ├── your-website.conf       # 你的站点配置
│   └── your-website.conf.default # 配置示例
├── logs/                       # 日志目录（持久化）
│   └── wp-auto-maintenance.log # 主日志文件
├── output/                     # 输出目录（持久化）
├── temp/                       # 临时文件目录
├── docker-compose.yml          # Docker Compose 配置
├── Dockerfile                  # Docker 镜像配置
├── .dockerignore               # Docker 忽略文件
├── DOCKER_DEPLOY.md           # 本部署指南
└── ...                         # 其他项目文件
```

## ⚙️ 环境变量

你可以在 docker-compose.yml 中添加更多环境变量：

```yaml
environment:
  - TZ=Asia/Shanghai
  - PYTHONUNBUFFERED=1
  - CONFIG_PATH=/app/config
  - LOG_LEVEL=INFO
```

## 🔄 更新服务

```bash
# 停止服务
docker-compose down

# 更新代码（如果有新版本）
git pull origin main

# 重新构建
docker-compose build --no-cache

# 启动服务
docker-compose up -d
```

## 🔍 监控和日志

### 查看实时日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f wp-auto-maintenance

# 查看最近 100 行日志
docker-compose logs --tail=100

# 查看特定时间的日志
docker-compose logs --since="2024-01-01T00:00:00"
```

### 查看容器状态

```bash
# 查看运行状态
docker-compose ps

# 查看资源使用
docker stats wordpress-automation-ai_wp-auto-maintenance_1

# 进入容器检查
docker-compose exec wp-auto-maintenance bash
```

## 🐛 故障排除

### 1. 构建失败

```bash
# 清理所有镜像和缓存
docker system prune -a
docker-compose build --no-cache
```

### 2. 权限问题

```bash
# 设置正确的目录权限
sudo chown -R $USER:$USER ./config ./logs ./output ./temp

# 或使用 Docker 用户
docker-compose exec wp-auto-maintenance \
  bash -c "chown -R root:root /app/config && chmod -R 755 /app/config"
```

### 3. 配置文件未加载

```bash
# 检查配置文件是否存在
ls -la ./config/

# 检查配置格式
docker-compose exec wp-auto-maintenance \
  bash -c "source /app/config/your-website.conf && echo '配置加载成功'"
```

### 4. 计划任务不执行

```bash
# 检查 cron 服务
docker-compose exec wp-cron bash -c "crontab -l"

# 手动触发一次
docker-compose exec wp-cron bash -c "cd /app && ./generate-article.sh -n 1"
```

### 5. 网络连接问题

```bash
# 测试容器内网络
docker-compose exec wp-auto-maintenance curl -I https://www.google.com

# 测试 WordPress 连接
docker-compose exec wp-auto-maintenance \
  python3 -c "
import xmlrpc.client
wp = xmlrpc.client.ServerProxy('YOUR_XMLRPC_URL')
print('连接成功')
"
```

## 📋 常用命令

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 重启
docker-compose restart

# 停止并删除所有数据（注意！）
docker-compose down -v --remove-orphans

# 查看日志
docker-compose logs -f

# 进入容器
docker-compose exec wp-auto-maintenance bash

# 重建
docker-compose build --no-cache

# 查看版本
docker-compose exec wp-auto-maintenance \
  bash -c "cat /app/README.md | grep '版本'"
```

## 🔧 自定义配置

### 修改定时任务

```bash
# 编辑 docker-compose.yml 中的 cron 部分
environment:
  - CRON_SCHEDULE=0 9 * * *   # 每天9点
  - CRON_SCHEDULE=0 */6 * * * # 每6小时
  - CRON_SCHEDULE=0 9 * * 1   # 每周一9点
```

### 修改资源限制

```yaml
# 在 docker-compose.yml 中添加
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      cpus: '0.5'
      memory: 512M
```

### 添加更多服务

你可以添加 Redis、数据库等额外服务：

```yaml
version: '3.8'
services:
  wp-auto-maintenance:
    # ... existing config ...
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    restart: unless-stopped
```

## 🚀 生产环境部署

### 1. 使用环境变量

```bash
# 创建 .env 文件
cat > .env <<EOF
WP_SITE_URL=https://your-website.com
WP_ADMIN_PASSWORD=your_password
AI_API_KEY=your_api_key
LSKY_TOKEN=your_lsky_token
EOF

# 在 docker-compose.yml 中引用
environment:
  - WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
```

### 2. 使用 Docker Secrets

```bash
# 创建 secret
echo "your_password" | docker secret create wp_admin_password -

# 在 docker-compose.yml 中使用
secrets:
  wp_admin_password:
    external: true

services:
  wp-auto-maintenance:
    secrets:
      - wp_admin_password
```

### 3. 使用反向代理

```yaml
# 在 docker-compose.yml 中添加 nginx
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
    - ./ssl:/etc/nginx/ssl
  depends_on:
    - wp-auto-maintenance
```

## 📊 性能监控

```bash
# 查看资源使用
docker stats

# 查看日志大小
docker system df

# 清理日志文件 (如果需要)
echo "" > logs/wp-auto-maintenance.log
```

## 🔄 CI/CD 集成

### GitHub Actions 示例

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t wp-auto-maintenance .

      - name: Push to registry
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          docker tag wp-auto-maintenance your-registry/wp-auto-maintenance:latest
          docker push your-registry/wp-auto-maintenance:latest
```

## 📖 参考文档

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [Bash 自动任务](https://www.redhat.com/sysadmin/cron-linux)
- [WordPress XML-RPC API](https://wordpress.org/support/article/xml-rpc-pingback/)

## 🆘 获取帮助

如果部署过程中遇到问题：

1. 查看容器日志：`docker-compose logs -f`
2. 检查配置文件：`cat config/your-website.conf`
3. 测试网络连接：`docker-compose exec wp-auto-maintenance curl -I https://www.google.com`
4. 提交 Issue 到 GitHub 仓库

## 📄 许可证

MIT License

---

**开始部署你的 WordPress 自动维护系统吧！** 🚀
