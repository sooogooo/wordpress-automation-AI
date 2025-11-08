#!/bin/bash

# WordPress 自动维护系统 - Web 界面启动脚本

WEB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===================================="
echo "WordPress 自动维护系统 - Web 管理界面"
echo "===================================="
echo ""

# 检查 Python3
if ! command -v python3 &> /dev/null; then
    echo "错误: 需要 Python3 但未找到"
    echo "请先安装 Python3"
    exit 1
fi

# 默认端口
PORT=8080

# 检查是否指定端口
if [ $# -gt 0 ]; then
    PORT="$1"
fi

echo "启动 Web 界面..."
echo "访问地址: http://localhost:${PORT}"
echo ""
echo "登录信息:"
echo "  用户名: admin"
echo "  默认密码: admin9900"
echo ""
echo "首次登录后建议修改密码"
echo ""
echo "按 Ctrl+C 停止服务器"
echo "===================================="
echo ""

# 启动 HTTP 服务器
cd "$WEB_DIR" && python3 -m http.server "$PORT"
