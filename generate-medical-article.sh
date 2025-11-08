#!/bin/bash

# WordPress 医美文章自动发布脚本
# 整合 AI 生成、兰空图床图片、WordPress 发布全流程

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置检查
if [ ! -f "$SCRIPT_DIR/config/your-website.conf" ]; then
    echo "错误: 配置文件不存在: $SCRIPT_DIR/config/your-website.conf"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/config/wordpress.conf" ]; then
    echo "错误: 配置文件不存在: $SCRIPT_DIR/config/wordpress.conf"
    exit 1
fi

# 加载配置
source "$SCRIPT_DIR/config/your-website.conf"
source "$SCRIPT_DIR/config/wordpress.conf"
source "$SCRIPT_DIR/modules/xmlrpc-api.sh"
source "$SCRIPT_DIR/modules/lsky-gallery.sh"
source "$SCRIPT_DIR/modules/ai-content-generator.sh"

# 显示脚本信息
show_info() {
    cat <<EOF
============================================
WordPress 医美文章自动发布脚本
============================================
站点: $WP_SITE_URL
标题源: $TITLE_URL
AI 模型: $AI_MODEL
兰空图床: $LSKY_BASE_URL
图片相册: $LSKY_ALBUM_NAME
============================================
EOF
}

# 显示帮助信息
show_help() {
    cat <<EOF
用法: $0 [选项] [参数]

选项:
    -h, --help          显示帮助信息
    -n, --number        指定生成文章数量 (默认: 1)
    -t, --title         指定特定标题（不使用随机标题）
    -c, --category      指定分类（覆盖 AI 建议的分类）
    --dry-run           试运行，不实际发布
    -v, --verbose       显示详细信息

示例:
    $0                  # 生成并发布一篇医美文章
    $0 -n 3             # 批量生成3篇文章
    $0 -t \"医美新趋势\"  # 使用指定标题
    $0 --dry-run        # 试运行，测试全流程

配置文件:
    config/your-website.conf    # 您的网站配置
    config/wordpress.conf       # WordPress 通用配置

日志文件:
    $LOG_FILE

EOF
}

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# 检查依赖
check_all_dependencies() {
    log "INFO" "检查依赖..."

    local deps_missing=0

    # 检查系统命令
    for cmd in curl python3 sed grep awk shuf; do
        if ! command -v $cmd >/dev/null 2>&1; then
            log "ERROR" "缺少命令: $cmd"
            deps_missing=1
        fi
    done

    # 检查 Python 模块
    python3 -c "import xmlrpc.client" 2>/dev/null || {
        log "ERROR" "Python xmlrpc.client 库不可用"
        deps_missing=1
    }

    # 检查 jq（可选，但推荐）
    if ! command -v jq >/dev/null 2>&1; then
        log "WARN" "jq 未安装，建议安装以提升 JSON 处理能力"
    fi

    # 验证配置文件中的必需参数
    if [[ -z "$WP_XMLRPC_URL" ]] || [[ "$WP_XMLRPC_URL" == *"your-wordpress-site.com"* ]]; then
        log "ERROR" "请配置 WP_XMLRPC_URL"
        deps_missing=1
    fi

    if [[ -z "$WP_ADMIN_PASSWORD" ]] || [[ "$WP_ADMIN_PASSWORD" == *"your_admin_password"* ]]; then
        log "ERROR" "请配置 WP_ADMIN_PASSWORD"
        deps_missing=1
    fi

    if [[ -z "$AI_API_KEY" ]] || [[ "$AI_API_KEY" == "sk-dpbuvtdcqgqrjwloxhgtvjbxwjoipivxrrmjsofuulvgfwuq" ]]; then
        log "ERROR" "请配置 AI_API_KEY"
        deps_missing=1
    fi

    if [[ $deps_missing -eq 1 ]]; then
        log "FATAL" "依赖检查失败，请修复后重试"
        exit 1
    fi

    log "INFO" "依赖检查通过"
    return 0
}

# 生成并发布单篇文章
generate_and_publish_single() {
    local title=${1:-""}
    local custom_category=${2:-""}

    log "INFO" "开始生成单篇医美文章..."

    # 如果未指定标题，使用 AI 生成
    if [[ -z "$title" ]]; then
        log "INFO" "从 $TITLE_URL 获取标题..."
        if ! title=$(ai_get_titles "$TITLE_URL"); then
            log "ERROR" "无法获取标题，使用默认标题"
            title="医美新时代：自然美与科技的融合"
        fi
        log "INFO" "选定标题: $title"
    else
        log "INFO" "使用指定标题: $title"
    fi

    # 生成文章内容
    log "INFO" "生成文章内容..."
    local raw_content
    if ! raw_content=$(ai_generate_article "$title"); then
        log "ERROR" "文章生成失败"
        return 1
    fi

    # 处理内容
    log "INFO" "处理文章内容..."
    local article_title=""
    local keywords=""
    local suggested_categories=""
    local article_content=""

    # 解析内容（模拟 ai_process_content 的输出格式）
    article_title="$title"

    # 提取关键词和建议分类
    keywords=$(echo "$raw_content" | grep -E "^关键字标签[:：]" | head -n 1 | sed 's/^关键字标签[:：]\s*//' || echo "")
    suggested_categories=$(echo "$raw_content" | grep -E "^建议分类[:：]" | head -n 1 | sed 's/^建议分类[:：]\s*//' || echo "未分类")

    # 清理内容
    article_content=$(echo "$raw_content" | sed '/^关键字标签[:：]/d; /^建议分类[:：]/d')

    # 使用自定义分类或建议分类
    local final_category="${custom_category:-$suggested_categories}"

    log "INFO" "标题: $article_title"
    log "INFO" "分类: $final_category"
    log "INFO" "关键词: $keywords"

    # 从兰空图床插入图片
    log "INFO" "从兰空图床获取图片..."
    if ! article_content=$(insert_images_into_content "$article_content" "$final_category"); then
        log "WARN" "图片插入失败，继续发布无图片版本"
    fi

    # 检查内容长度
    local content_length=$(echo "$article_content" | wc -c)
    if [[ $content_length -lt $MIN_CONTENT_LENGTH ]]; then
        log "ERROR" "文章内容过短（$content_length 字节），放弃发布"
        return 1
    fi

    # 发布到 WordPress
    log "INFO" "发布文章到 WordPress..."
    local post_id
    if post_id=$(wp_publish_post_xmlrpc "$WP_XMLRPC_URL" "$WP_ADMIN_USER" "$WP_ADMIN_PASSWORD" "$WP_BLOG_ID" \
            "$article_title" "$article_content" "$PUBLISH_STATUS" "$final_category" "$keywords"); then

        # 检查返回结果
        if [[ "$post_id" =~ ^[0-9]+$ ]]; then
            log "SUCCESS" "文章发布成功！文章ID: $post_id"
            log "INFO" "访问链接: ${WP_SITE_URL}/?p=$post_id"

            echo ""
            echo "=================================="
            echo "医美文章发布成功！"
            echo "=================================="
            echo "标题: $article_title"
            echo "分类: $final_category"
            echo "标签: $keywords"
            echo "文章ID: $post_id"
            echo "访问链接: ${WP_SITE_URL}/?p=$post_id"
            echo "=================================="

            return 0
        else
            log "ERROR" "发布失败，返回结果异常: $post_id"
            return 1
        fi
    else
        log "ERROR" "文章发布失败"
        return 1
    fi
}

# 批量生成并发布
generate_and_publish_batch() {
    local num_articles=$1

    log "INFO" "开始批量生成 $num_articles 篇医美文章..."

    local success_count=0
    local failed_count=0

    for ((i = 1; i <= num_articles; i++)); do
        echo ""
        echo "=================================="
        echo "批量生成 [$i/$num_articles]"
        echo "=================================="

        if generate_and_publish_single; then
            success_count=$((success_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi

        # 非最后一篇文章时暂停，避免请求过快
        if [[ $i -lt $num_articles ]]; then
            log "INFO" "等待5秒后生成下一篇..."
            sleep 5
        fi
    done

    echo ""
    echo "=================================="
    echo "批量生成完成"
    echo "=================================="
    echo "总生成: $num_articles 篇"
    echo "成功: $success_count 篇"
    echo "失败: $failed_count 篇"
    echo "=================================="

    log "INFO" "批量生成完成 - 总: $num_articles, 成功: $success_count, 失败: $failed_count"
}

# 测试功能（不实际发布）
dry_run() {
    log "INFO" "=== DRY RUN 模式 ==="
    log "INFO" "测试所有功能，但不实际发布文章"

    echo ""
    echo "=================================="
    echo "DRY RUN - 功能测试"
    echo "=================================="

    # 测试依赖
    check_all_dependencies
    echo "✓ 依赖检查通过"

    # 测试标题获取
    echo ""
    echo "测试标题获取..."
    local test_title
    if test_title=$(ai_get_titles "$TITLE_URL"); then
        echo "✓ 标题获取成功: $test_title"
    else
        echo "⚠ 标题获取失败"
    fi

    # 测试 AI 生成
    echo ""
    echo "测试 AI 文章生成..."
    local test_content
    if test_content=$(ai_generate_article "$test_title" 1000 0.5); then
        echo "✓ 文章生成成功（长度: $(echo "$test_content" | wc -c) 字节）"
    else
        echo "⚠ 文章生成失败"
    fi

    # 测试兰空图床
    echo ""
    echo "测试兰空图床连接..."
    if curl -s ${LSKY_AUTH} -H "Accept: application/json" -m 10 "$LSKY_BASE_URL/albums?page=1&limit=10" > /dev/null; then
        echo "✓ 兰空图床连接成功"
    else
        echo "⚠ 兰空图床连接失败"
    fi

    # 测试 WordPress 连接
    echo ""
    echo "测试 WordPress 连接..."
    local categories
    if categories=$(wp_get_categories_xmlrpc "$WP_XMLRPC_URL" "$WP_ADMIN_USER" "$WP_ADMIN_PASSWORD" "$WP_BLOG_ID"); then
        echo "✓ WordPress 连接成功"
        echo "  现有分类: $categories"
    else
        echo "⚠ WordPress 连接失败"
    fi

    echo ""
    echo "=================================="
    echo "DRY RUN 完成"
    echo "=================================="
    log "INFO" "DRY RUN 完成"
}

# 主函数
main() {
    # 默认参数
    local num_articles=1
    local custom_title=""
    local custom_category=""
    local dry_run=false
    local verbose=false

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--number)
                num_articles="$2"
                shift 2
                ;;
            -t|--title)
                custom_title="$2"
                shift 2
                ;;
            -c|--category)
                custom_category="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                echo "未知选项: $1"
                echo "使用 -h 或 --help 查看帮助"
                exit 1
                ;;
        esac
    done

    # 显示脚本信息
    show_info

    # 检查依赖
    if ! check_all_dependencies; then
        exit 1
    fi

    # DRY RUN 模式
    if [[ "$dry_run" == "true" ]]; then
        dry_run
        exit 0
    fi

    # 创建输出目录
    mkdir -p "$OUTPUT_DIR"

    # 执行主逻辑
    if [[ $num_articles -eq 1 ]] && [[ -n "$custom_title" ]]; then
        # 单篇文章，使用指定标题
        generate_and_publish_single "$custom_title" "$custom_category"
    elif [[ $num_articles -eq 1 ]]; then
        # 单篇文章，使用随机标题
        generate_and_publish_single
    else
        # 批量生成
        generate_and_publish_batch "$num_articles"
    fi
}

# 脚本入口
main "$@"
