# WordPress 自动维护系统 - Docker 镜像
# 基于 Ubuntu 20.04 LTS
FROM ubuntu:20.04

# 设置环境变量，避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# 维护者信息
LABEL maintainer="sooogooo@gmail.com"
LABEL version="1.0.0"
LABEL description="WordPress 自动维护系统 - AI 文章生成与发布"

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-pil \
    jq \
    cron \
    git \
    unzip \
    vim \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖
RUN pip3 install --no-cache-dir \
    requests \
    Pillow \
    xmlrpc2

# 创建工作目录
WORKDIR /app

# 复制项目文件
COPY . /app/

# 创建必要的目录
RUN mkdir -p /app/logs /app/output /app/temp && \
    chmod +x /app/*.sh /app/modules/*.sh /app/web-interface/*.sh

# 创建日志文件
RUN touch /app/logs/wp-auto-maintenance.log && \
    chmod 666 /app/logs/wp-auto-maintenance.log

# 创建配置文件示例
RUN cp /app/config/wordpress.conf /app/config/wordpress.conf.example && \
    cp /app/config/your-website.conf /app/config/your-website.conf.example

# 设置工作目录权限
RUN chmod -R 755 /app && \
    chown -R root:root /app

# 设置环境变量
ENV PATH="/app:/app/modules:$PATH"
ENV CONFIG_PATH="/app/config"
ENV LOG_FILE="/app/logs/wp-auto-maintenance.log"

# 暴露端口（用于 Web 界面）
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "print('OK')" || exit 1

# 默认命令
CMD ["/bin/bash"]
