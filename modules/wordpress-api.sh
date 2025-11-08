#!/bin/bash

# WordPress API 交互模块
# 提供与WordPress REST API交互的功能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/wordpress.conf"

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# WordPress API 认证
get_auth_header() {
    if [[ -n "$WP_API_TOKEN" ]]; then
        echo "Authorization: Bearer $WP_API_TOKEN"
    else
        local credentials=$(echo -n "$WP_ADMIN_USER:$WP_ADMIN_PASSWORD" | base64)
        echo "Authorization: Basic $credentials"
    fi
}

# 创建文章
wp_create_post() {
    local title=$1
    local content=$2
    local category_ids=$3
    local tag_ids=$4
    local featured_media=$5

    local auth_header=$(get_auth_header)
    local payload=$(cat <<EOF
{
    "title": "$title",
    "content": "$content",
    "status": "$PUBLISH_STATUS",
    "author": $AUTHOR_ID,
    "categories": [$category_ids],
    "tags": [$tag_ids]
}
EOF
)

    if [[ -n "$featured_media" ]]; then
        payload=$(echo "$payload" | jq --arg media "$featured_media" '. + {"featured_media": $media}')
    fi

    response=$(curl -s -X POST "$WP_SITE_URL/wp-json/wp/v2/posts" \
        -H "$auth_header" \
        -H "Content-Type: application/json" \
        -d "$payload")

    if echo "$response" | grep -q '"id"'; then
        local post_id=$(echo "$response" | jq -r '.id')
        log "INFO" "文章创建成功: $title (ID: $post_id)"
        echo "$post_id"
        return 0
    else
        log "ERROR" "文章创建失败: $response"
        return 1
    fi
}

# 创建页面
wp_create_page() {
    local title=$1
    local content=$2
    local page_template=${3:-""}

    local auth_header=$(get_auth_header)
    local payload=$(cat <<EOF
{
    "title": "$title",
    "content": "$content",
    "status": "$PUBLISH_STATUS"
}
EOF
)

    if [[ -n "$page_template" ]]; then
        payload=$(echo "$payload" | jq --arg template "$page_template" '. + {"template": $template}')
    fi

    response=$(curl -s -X POST "$WP_SITE_URL/wp-json/wp/v2/pages" \
        -H "$auth_header" \
        -H "Content-Type: application/json" \
        -d "$payload")

    if echo "$response" | grep -q '"id"'; then
        local page_id=$(echo "$response" | jq -r '.id')
        log "INFO" "页面创建成功: $title (ID: $page_id)"
        echo "$page_id"
        return 0
    else
        log "ERROR" "页面创建失败: $response"
        return 1
    fi
}

# 创建分类
wp_create_category() {
    local name=$1
    local parent=${2:-0}
    local description=${3:-""}

    local auth_header=$(get_auth_header)
    local payload=$(cat <<EOF
{
    "name": "$name",
    "parent": $parent
}
EOF
)

    if [[ -n "$description" ]]; then
        payload=$(echo "$payload" | jq --arg desc "$description" '. + {"description": $desc}')
    fi

    response=$(curl -s -X POST "$WP_SITE_URL/wp-json/wp/v2/categories" \
        -H "$auth_header" \
        -H "Content-Type: application/json" \
        -d "$payload")

    if echo "$response" | grep -q '"id"'; then
        local category_id=$(echo "$response" | jq -r '.id')
        log "INFO" "分类创建成功: $name (ID: $category_id)"
        echo "$category_id"
        return 0
    else
        log "ERROR" "分类创建失败: $response"
        return 1
    fi
}

# 创建标签
wp_create_tag() {
    local name=$1
    local description=${2:-""}

    local auth_header=$(get_auth_header)
    local payload=$(cat <<EOF
{
    "name": "$name"
}
EOF
)

    if [[ -n "$description" ]]; then
        payload=$(echo "$payload" | jq --arg desc "$description" '. + {"description": $desc}')
    fi

    response=$(curl -s -X POST "$WP_SITE_URL/wp-json/wp/v2/tags" \
        -H "$auth_header" \
        -H "Content-Type: application/json" \
        -d "$payload")

    if echo "$response" | grep -q '"id"'; then
        local tag_id=$(echo "$response" | jq -r '.id')
        log "INFO" "标签创建成功: $name (ID: $tag_id)"
        echo "$tag_id"
        return 0
    else
        log "ERROR" "标签创建失败: $response"
        return 1
    fi
}

# 上传媒体文件
wp_upload_media() {
    local file_path=$1
    local title=${2:-"$(basename "$file_path")"}

    if [[ ! -f "$file_path" ]]; then
        log "ERROR" "文件不存在: $file_path"
        return 1
    fi

    local auth_header=$(get_auth_header)
    local mime_type=$(file -b --mime-type "$file_path")

    response=$(curl -s -X POST "$WP_SITE_URL/wp-json/wp/v2/media" \
        -H "$auth_header" \
        -H "Content-Disposition: attachment; filename=\"$title\"" \
        -H "Content-Type: $mime_type" \
        --data-binary "@$file_path")

    if echo "$response" | grep -q '"id"'; then
        local media_id=$(echo "$response" | jq -r '.id')
        log "INFO" "媒体文件上传成功: $title (ID: $media_id)"
        echo "$media_id"
        return 0
    else
        log "ERROR" "媒体文件上传失败: $response"
        return 1
    fi
}

# 获取分类列表
wp_get_categories() {
    local auth_header=$(get_auth_header)
    curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/categories" \
        -H "$auth_header" \
        -H "Content-Type: application/json"
}

# 获取标签列表
wp_get_tags() {
    local auth_header=$(get_auth_header)
    curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/tags" \
        -H "$auth_header" \
        -H "Content-Type: application/json"
}
