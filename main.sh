#!/bin/bash

# WordPress 自动维护系统 - 主控制脚本
# 整合所有模块，提供完整的自动化维护功能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config/wordpress.conf"
source "${SCRIPT_DIR}/modules/wordpress-api.sh"
source "${SCRIPT_DIR}/modules/lsky-gallery.sh"
source "${SCRIPT_DIR}/modules/content-generator.sh"
source "${SCRIPT_DIR}/modules/page-manager.sh"
source "${SCRIPT_DIR}/modules/category-tag.sh"

# 显示帮助信息
show_help() {
    cat <<EOF
WordPress 自动维护系统

用法: $0 [选项] [操作]

选项:
    -h, --help          显示帮助信息
    -v, --version       显示版本信息
    --dry-run           试运行，不执行实际操作

操作:
    init                初始化网站（创建必要页面、分类、标签）
    create-post         创建单篇文章
    batch-posts         批量创建文章
    create-pages        创建必要页面
    init-categories     初始化分类
    init-tags           初始化标签
    update-media        从图床更新媒体库
    status              显示网站状态
    cron                执行定时任务（自动发布文章）

示例:
    $0 init                          # 完整初始化网站
    $0 create-post "标题" "内容"      # 创建单篇文章
    $0 batch-posts                   # 批量从源生成文章
    $0 cron                          # 执行定时任务

配置文件: config/wordpress.conf

EOF
}

# 显示版本信息
show_version() {
    echo "WordPress 自动维护系统 v1.0.0"
    echo "作者: Claude Code"
    echo "GitHub: https://github.com/anthropics/claude-code"
}

# 检查依赖
check_dependencies() {
    local deps_missing=0

    # 检查必需命令
    for cmd in curl jq sed grep awk; do
        if ! command -v $cmd >/dev/null 2>&1; then
            echo "错误: 缺少必需的命令: $cmd"
            deps_missing=1
        fi
    done

    # 检查配置
    if [[ -z "$WP_SITE_URL" ]] || [[ "$WP_SITE_URL" == "https://your-wordpress-site.com" ]]; then
        echo "错误: 请在 config/wordpress.conf 中配置 WordPress 站点 URL"
        deps_missing=1
    fi

    if [[ -z "$WP_ADMIN_USER" ]] || [[ "$WP_ADMIN_USER" == "your_admin_username" ]]; then
        echo "错误: 请在 config/wordpress.conf 中配置 WordPress 管理员用户名"
        deps_missing=1
    fi

    if [[ -z "$WP_ADMIN_PASSWORD" ]] || [[ "$WP_ADMIN_PASSWORD" == "your_admin_password" ]]; then
        echo "错误: 请在 config/wordpress.conf 中配置 WordPress 管理员密码"
        deps_missing=1
    fi

    if [[ $deps_missing -eq 1 ]]; then
        exit 1
    fi

    echo "依赖检查通过"
    return 0
}

# 初始化网站
init_website() {
    log "INFO" "开始初始化 WordPress 网站..."

    echo "=== 步骤 1: 初始化分类和标签 ==="
    init_all_categories_and_tags

    echo ""
    echo "=== 步骤 2: 创建必要页面 ==="
    init_required_pages

    echo ""
    echo "=== 步骤 3: 更新媒体库 ==="
    update_media_from_lsky

    log "INFO" "网站初始化完成"
}

# 创建单篇文章
create_single_post() {
    local title=${1:-""}
    local content=${2:-""}

    if [[ -z "$title" ]]; then
        echo "错误: 请提供文章标题"
        echo "用法: $0 create-post \"文章标题\" [\"文章内容\"]"
        return 1
    fi

    if [[ -z "$content" ]]; then
        content="这是一篇自动生成的文章内容。"
    fi

    log "INFO" "创建单篇文章: $title"

    local category_ids=$(wp_get_category_id "技术")
    local tag_ids=$(wp_get_tag_ids "WordPress")

    if wp_create_post "$title" "$content" "$category_ids" "$tag_ids"; then
        log "INFO" "文章创建成功"
        return 0
    else
        log "ERROR" "文章创建失败"
        return 1
    fi
}

# 批量创建文章
batch_create_posts() {
    local max_posts=${1:-3}

    log "INFO" "开始批量创建文章，最大数量: $max_posts"

    local posts_created=0

    for source_url in "${CONTENT_SOURCES[@]}"; do
        if [[ "$source_url" =~ ^https?:// ]]; then
            echo "处理内容源: $source_url"
            if count=$(batch_generate_articles "$source_url" "$max_posts"); then
                posts_created=$((posts_created + count))
                if [[ $posts_created -ge $max_posts ]]; then
                    break
                fi
            fi
        fi
    done

    log "INFO" "批量创建文章完成，共创建 $posts_created 篇文章"
}

# 更新媒体库
update_media_from_lsky() {
    log "INFO" "从 Lsky 图床更新媒体库..."

    local image_ids
    if image_ids=$(lsky_to_wordpress "" 10); then
        log "INFO" "媒体库更新成功，上传 $(echo "$image_ids" | tr ',' ' ' | wc -w) 张图片"
        echo "$image_ids"
        return 0
    else
        log "ERROR" "媒体库更新失败"
        return 1
    fi
}

# 显示网站状态
show_status() {
    log "INFO" "获取网站状态..."

    local auth_header=$(get_auth_header)

    echo "=== WordPress 网站状态 ==="
    echo "站点 URL: $WP_SITE_URL"
    echo "管理员用户: $WP_ADMIN_USER"
    echo ""

    # 获取文章数量
    local posts_response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/posts?per_page=1" \
        -H "$auth_header" \
        -H "Content-Type: application/json")
    local posts_count=$(echo "$posts_response" | grep -c '"id"' || echo "0")
    echo "文章数量: $posts_count"

    # 获取页面数量
    local pages_response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/pages?per_page=1" \
        -H "$auth_header" \
        -H "Content-Type: application/json")
    local pages_count=$(echo "$pages_response" | grep -c '"id"' || echo "0")
    echo "页面数量: $pages_count"

    # 获取分类数量
    local categories=$(wp_get_categories)
    local categories_count=$(echo "$categories" | grep -c '"id"' || echo "0")
    echo "分类数量: $categories_count"

    # 获取标签数量
    local tags=$(wp_get_tags)
    local tags_count=$(echo "$tags" | grep -c '"id"' || echo "0")
    echo "标签数量: $tags_count"

    echo ""
    echo "=== Lsky 图床配置 ==="
    if [[ -n "$LSKY_BASE_URL" ]] && [[ "$LSKY_BASE_URL" != "https://your-lsky-site.com" ]]; then
        echo "图床 URL: $LSKY_BASE_URL"
        echo "API Token: $(if [[ -n "$LSKY_API_TOKEN" ]]; then echo "已配置"; else echo "未配置"; fi)"
    else
        echo "Lsky 图床未配置"
    fi

    echo ""
    echo "=== 内容源配置 ==="
    if [[ ${#CONTENT_SOURCES[@]} -gt 0 ]]; then
        echo "内容源数量: ${#CONTENT_SOURCES[@]}"
        for i in "${!CONTENT_SOURCES[@]}"; do
            echo "  $((i+1)). ${CONTENT_SOURCES[$i]}"
        done
    else
        echo "内容源未配置"
    fi

    echo ""
    echo "=== 定时任务 ==="
    echo "定时执行: $CRON_SCHEDULE"
    echo "日志文件: $LOG_FILE"
}

# 执行定时任务
run_cron() {
    log "INFO" "执行定时任务..."

    # 检查是否到了执行时间（简化版，实际需要crontab配置）
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)

    echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"

    # 这里可以添加更多定时任务逻辑
    # 例如：每天8点自动发布文章

    log "INFO" "开始自动发布文章..."
    batch_create_posts 3

    log "INFO" "定时任务执行完成"
}

# 主函数
main() {
    # 检查参数
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    # 检查依赖
    check_dependencies

    # 解析参数
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        init)
            init_website
            ;;
        create-post)
            shift
            create_single_post "$@"
            ;;
        batch-posts)
            shift
            batch_create_posts "$@"
            ;;
        create-pages)
            init_required_pages
            ;;
        init-categories)
            init_default_categories
            ;;
        init-tags)
            init_default_tags
            ;;
        update-media)
            update_media_from_lsky
            ;;
        status)
            show_status
            ;;
        cron)
            run_cron
            ;;
        --dry-run)
            log "INFO" "试运行模式，不执行实际操作"
            ;;
        *)
            echo "错误: 未知的操作: $1"
            echo "使用 -h 或 --help 查看帮助信息"
            exit 1
            ;;
    esac
}

# 脚本入口
main "$@"
