#!/bin/bash

# WordPress 分类和标签管理模块
# 批量创建和管理文章分类及标签

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/wordpress.conf"
source "${SCRIPT_DIR}/wordpress-api.sh"

# 初始化默认分类
init_default_categories() {
    log "INFO" "开始初始化默认分类..."

    local categories_created=0

    for category_name in "${DEFAULT_CATEGORIES[@]}"; do
        if category_exists "$category_name"; then
            log "INFO" "分类已存在，跳过: $category_name"
        else
            log "INFO" "创建分类: $category_name"
            if wp_create_category "$category_name"; then
                categories_created=$((categories_created + 1))
            fi
        fi
    done

    log "INFO" "分类初始化完成，共创建 $categories_created 个新分类"
    echo "$categories_created"
    return 0
}

# 初始化默认标签
init_default_tags() {
    log "INFO" "开始初始化默认标签..."

    local tags_created=0

    for tag_name in "${DEFAULT_TAGS[@]}"; do
        if tag_exists "$tag_name"; then
            log "INFO" "标签已存在，跳过: $tag_name"
        else
            log "INFO" "创建标签: $tag_name"
            if wp_create_tag "$tag_name"; then
                tags_created=$((tags_created + 1))
            fi
        fi
    done

    log "INFO" "标签初始化完成，共创建 $tags_created 个新标签"
    echo "$tags_created"
    return 0
}

# 检查分类是否存在
category_exists() {
    local category_name=$1
    local auth_header=$(get_auth_header)

    local response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/categories?search=$(echo "$category_name" | jq -s -R -r @uri)" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    local category_count=$(echo "$response" | jq -r 'length')

    if [[ $category_count -gt 0 ]]; then
        return 0  # 分类存在
    else
        return 1  # 分类不存在
    fi
}

# 检查标签是否存在
tag_exists() {
    local tag_name=$1
    local auth_header=$(get_auth_header)

    local response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/tags?search=$(echo "$tag_name" | jq -s -R -r @uri)" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    local tag_count=$(echo "$response" | jq -r 'length')

    if [[ $tag_count -gt 0 ]]; then
        return 0  # 标签存在
    else
        return 1  # 标签不存在
    fi
}

# 从文件批量创建分类
batch_create_categories() {
    local category_file=${1:-""}

    if [[ ! -f "$category_file" ]]; then
        log "ERROR" "分类文件不存在: $category_file"
        return 1
    fi

    log "INFO" "从文件批量创建分类: $category_file"

    local categories_created=0

    while IFS= read -r category_line; do
        # 跳过空行和注释
        if [[ -z "$category_line" ]] || [[ "$category_line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # 格式: 分类名称|父分类ID|描述
        local category_name=$(echo "$category_line" | cut -d'|' -f1)
        local parent_id=$(echo "$category_line" | cut -d'|' -f2)
        local description=$(echo "$category_line" | cut -d'|' -f3)

        # 设置默认值
        if [[ "$parent_id" == "$category_name" ]]; then
            parent_id=0
        fi
        if [[ "$description" == "$category_line" ]]; then
            description=""
        fi

        # 创建分类
        if ! category_exists "$category_name"; then
            log "INFO" "创建分类: $category_name"
            if wp_create_category "$category_name" "$parent_id" "$description"; then
                categories_created=$((categories_created + 1))
            fi
        else
            log "INFO" "分类已存在，跳过: $category_name"
        fi
    done < "$category_file"

    log "INFO" "批量创建分类完成，共创建 $categories_created 个分类"
    echo "$categories_created"
    return 0
}

# 从文件批量创建标签
batch_create_tags() {
    local tag_file=${1:-""}

    if [[ ! -f "$tag_file" ]]; then
        log "ERROR" "标签文件不存在: $tag_file"
        return 1
    fi

    log "INFO" "从文件批量创建标签: $tag_file"

    local tags_created=0

    while IFS= read -r tag_line; do
        # 跳过空行和注释
        if [[ -z "$tag_line" ]] || [[ "$tag_line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # 格式: 标签名称|描述
        local tag_name=$(echo "$tag_line" | cut -d'|' -f1)
        local description=$(echo "$tag_line" | cut -d'|' -f2)

        # 设置默认值
        if [[ "$description" == "$tag_line" ]]; then
            description=""
        fi

        # 创建标签
        if ! tag_exists "$tag_name"; then
            log "INFO" "创建标签: $tag_name"
            if wp_create_tag "$tag_name" "$description"; then
                tags_created=$((tags_created + 1))
            fi
        else
            log "INFO" "标签已存在，跳过: $tag_name"
        fi
    done < "$tag_file"

    log "INFO" "批量创建标签完成，共创建 $tags_created 个标签"
    echo "$tags_created"
    return 0
}

# 获取分类ID
category_id() {
    local category_name=$1
    local auth_header=$(get_auth_header)

    local response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/categories?search=$(echo "$category_name" | jq -s -R -r @uri)" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    local category_id=$(echo "$response" | jq -r '.[0].id // empty')

    if [[ -n "$category_id" ]]; then
        echo "$category_id"
        return 0
    else
        log "ERROR" "分类不存在: $category_name"
        return 1
    fi
}

# 获取标签ID
tag_id() {
    local tag_name=$1
    local auth_header=$(get_auth_header)

    local response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/tags?search=$(echo "$tag_name" | jq -s -R -r @uri)" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    local tag_id=$(echo "$response" | jq -r '.[0].id // empty')

    if [[ -n "$tag_id" ]]; then
        echo "$tag_id"
        return 0
    else
        log "ERROR" "标签不存在: $tag_name"
        return 1
    fi
}

# 删除所有空分类
cleanup_empty_categories() {
    log "INFO" "清理空分类..."

    local auth_header=$(get_auth_header)
    local response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/categories?per_page=100" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    local deleted_count=0

    # 解析分类并检查文章数
    local category_count=$(echo "$response" | jq -r 'length')

    for ((i = 0; i < category_count; i++)); do
        local category=$(echo "$response" | jq -r ".[$i]")
        local category_id=$(echo "$category" | jq -r '.id')
        local category_name=$(echo "$category" | jq -r '.name')
        local post_count=$(echo "$category" | jq -r '.count')

        # 跳过默认的'未分类'
        if [[ "$category_name" == "未分类" ]] || [[ "$category_name" == "Uncategorized" ]]; then
            continue
        fi

        if [[ $post_count -eq 0 ]]; then
            log "INFO" "删除空分类: $category_name"
            if delete_category "$category_id"; then
                deleted_count=$((deleted_count + 1))
            fi
        fi
    done

    log "INFO" "清理完成，共删除 $deleted_count 个空分类"
    echo "$deleted_count"
    return 0
}

# 删除分类
delete_category() {
    local category_id=$1
    local force=${2:-false}

    local auth_header=$(get_auth_header)

    response=$(curl -s -X DELETE "$WP_SITE_URL/wp-json/wp/v2/categories/$category_id?force=$force" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    if echo "$response" | grep -q '"id"'; then
        log "INFO" "分类删除成功 (ID: $category_id)"
        return 0
    else
        log "ERROR" "分类删除失败: $response"
        return 1
    fi
}

# 初始化所有分类和标签
init_all_categories_and_tags() {
    log "INFO" "开始初始化分类和标签..."

    local categories_created=0
    local tags_created=0

    # 初始化默认分类
    if result=$(init_default_categories); then
        categories_created=$result
    fi

    # 初始化默认标签
    if result=$(init_default_tags); then
        tags_created=$result
    fi

    log "INFO" "初始化完成: $categories_created 个分类, $tags_created 个标签"
    echo "categories:$categories_created,tags:$tags_created"
    return 0
}
