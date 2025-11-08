#!/bin/bash

# Docker 构建和运行脚本
# WordPress 自动维护系统

set -e

# 配置
IMAGE_NAME="wp-auto-maintenance"
IMAGE_TAG=${1:-"latest"}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "WordPress 自动维护系统 Docker 部署"
echo "=========================================="
echo ""

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未找到 Docker，请先安装 Docker${NC}"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}警告: 未找到 docker-compose，安装 Docker Compose...${NC}"
    sudo apt install -y docker-compose || sudo yum install -y docker-compose
fi

# 创建必要目录
echo "创建必要目录..."
mkdir -p "${PROJECT_DIR}/config" "${PROJECT_DIR}/logs" "${PROJECT_DIR}/output" "${PROJECT_DIR}/temp"

# 设置目录权限
echo "设置目录权限..."
chmod 755 "${PROJECT_DIR}/config" "${PROJECT_DIR}/logs" "${PROJECT_DIR}/output" "${PROJECT_DIR}/temp"

# 检查配置文件
if [ ! -f "${PROJECT_DIR}/config/your-website.conf" ]; then
    echo -e "${YELLOW}配置文件不存在，复制示例文件...${NC}"
    cp "${PROJECT_DIR}/config/your-website.conf.default" "${PROJECT_DIR}/config/your-website.conf"
    echo -e "${YELLOW}请编辑 ${PROJECT_DIR}/config/your-website.conf 并填入实际的配置信息${NC}"
    echo ""
    echo "配置文件需要填写的关键信息:"
    echo "  - WordPress 站点 URL 和 XML-RPC 地址"
    echo "  - WordPress 用户名和应用密码"
    echo "  - 兰空图床 API Token"
    echo "  - AI 模型 API Key（Moonshot/DeepSeek/SiliconFlow）"
    echo ""
    read -p "现在要编辑配置文件吗? (y/n): " edit_now

    if [ "$edit_now" = "y" ]; then
        if command -v vim &> /dev/null; then
            vim "${PROJECT_DIR}/config/your-website.conf"
        elif command -v nano &> /dev/null; then
            nano "${PROJECT_DIR}/config/your-website.conf"
        else
            echo -e "${YELLOW}请手动编辑: ${PROJECT_DIR}/config/your-website.conf${NC}"
        fi
    fi
fi

# 构建镜像
echo ""
echo "=========================================="
echo "开始构建 Docker 镜像..."
echo "=========================================="
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo ""
echo -e "${GREEN}✓ 镜像构建成功: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
echo ""

# 询问是否启动
echo "=========================================="
read -p "是否现在启动服务? (y/n): " start_now

if [ "$start_now" = "y" ]; then
    echo ""
    echo "启动 Docker Compose 服务..."
    echo "=========================================="

    # 停止旧服务（如果存在）
    docker-compose down 2>/dev/null || true

    # 启动服务
    docker-compose up -d

    echo ""
    echo -e "${GREEN}✓ 服务已启动！${NC}"
    echo ""
    echo "访问信息:"
    echo "  Web 管理界面: http://localhost:8080"
    echo ""
    echo "容器名称:"
    echo "  主服务:     wp-auto-maintenance"
    echo "  定时任务:   wp-auto-cron"
    echo ""
    echo "查看日志:"
    echo "  docker-compose logs -f"
    echo ""
    echo "进入容器:"
    echo "  docker-compose exec wp-auto-maintenance bash"
    echo ""
    echo "=========================================="

    # 显示启动的服务
    docker-compose ps

    # 显示管理界面访问提示
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}      Web 管理界面已就绪${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo "登录地址: http://localhost:8080"
    echo "用户名: admin"
    echo ""
    echo "首次登录后:"
    echo "1. 填写 WordPress 配置"
    echo "2. 填写 兰空图床 配置"
    echo "3. 选择 AI 提供商并配置 API Key"
    echo "4. 点击 '生成 Bash 脚本'"
    echo "5. 按照说明使用生成的脚本"
    echo ""
    read -p "是否要查看 Web 界面访问命令? (y/n): " show_web

    if [ "$show_web" = "y" ]; then
        echo ""
        echo "启动 Web 界面:"
        echo "  docker-compose exec wp-auto-maintenance bash"
        echo "  cd /app/web-interface"
        echo "  ./start-web.sh 8080"
        echo ""
        echo "然后在浏览器访问: http://localhost:8080"
    fi
else
    echo ""
    echo "=========================================="
    echo -e "${YELLOW}镜像构建完成，但未启动服务${NC}"
    echo ""
    echo "手动启动命令:"
    echo "  docker-compose up -d"
    echo ""
    echo "其他有用命令:"
    echo "  查看日志:    docker-compose logs -f"
    echo "  停止服务:    docker-compose down"
    echo "  重启服务:    docker-compose restart"
    echo "  进入容器:    docker-compose exec wp-auto-maintenance bash"
    echo "=========================================="
fi

echo ""
echo "部署完成！"
echo ""