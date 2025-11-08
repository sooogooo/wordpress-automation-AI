#!/bin/bash

# 文章内容生成模块
# 从指定的URL读取文章标题和内容概要，生成WordPress文章

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/wordpress.conf"
source "${SCRIPT_DIR}/wordpress-api.sh"

# 从URL获取内容（支持RSS和普通网页）
fetch_content() {
    local url=$1
    local content_type=${2:-"auto"}

    log "INFO" "从URL获取内容: $url"

    # 检测内容类型
    if [[ "$content_type" == "auto" ]]; then
        if [[ "$url" =~ \.(rss|xml|feed)$ ]]; then
            content_type="rss"
        else
            content_type="html"
        fi
    fi

    case "$content_type" in
        rss)
            fetch_rss_content "$url"
            ;;
        html)
            fetch_html_content "$url"
            ;;
        *)
            log "ERROR" "不支持的内容类型: $content_type"
            return 1
            ;;
    esac
}

# 从RSS Feed获取内容
fetch_rss_content() {
    local rss_url=$1

    local temp_file=$(mktemp)

    if curl -s -L -o "$temp_file" "$rss_url"; then
        # 使用xmllint或xmlstarlet解析RSS（如果可用）
        if command -v xmlstarlet >/dev/null 2>&1; then
            local items=$(xmlstarlet sel -t -m "/rss/channel/item" \
                -v "title" -o "|||" \
                -v "description" -o "|||" \
                -v "link" -n \
                "$temp_file")

            echo "$items"
            rm -f "$temp_file"
            return 0
        else
            log "WARN" "xmlstarlet未安装，尝试使用sed/awk解析"
            # 简单解析（不推荐用于生产）
            local rss_content=$(cat "$temp_file")
            rm -f "$temp_file"

            # 提取前5个item
            local items=""
            local item_count=0

            while IFS= read -r line; do
                if [[ "$line" =~ <item> ]]; then
                    item_count=$((item_count + 1))
                    if [[ $item_count -le 5 ]]; then
                        items="${items}$line
"
                    fi
                fi
            done <<< "$rss_content"

            echo "$items"
            return 0
        fi
    else
        log "ERROR" "无法下载RSS内容: $rss_url"
        rm -f "$temp_file"
        return 1
    fi
}

# 从HTML页面获取内容
fetch_html_content() {
    local html_url=$1

    local temp_file=$(mktemp)

    if curl -s -L -o "$temp_file" "$html_url"; then
        # 尝试提取标题
        local title=$(grep -o '<title>[^<]*</title>' "$temp_file" | sed 's/<\/\?title>//g' | head -1)

        # 尝试提取meta description
        local description=$(grep -o '<meta name="description" content="[^"]*"' "$temp_file" | sed 's/.*content="\([^"]*\)".*/\1/' | head -1)

        # 如果没有description，尝试提取第一段文字
        if [[ -z "$description" ]]; then
            description=$(grep -A 5 '<p>' "$temp_file" | sed 's/<[^>]*>//g' | tr '\n' ' ' | cut -c1-200)
        fi

        rm -f "$temp_file"

        if [[ -n "$title" ]]; then
            echo "$title|||$description|||$html_url"
            return 0
        fi
    else
        log "ERROR" "无法下载HTML内容: $html_url"
        rm -f "$temp_file"
        return 1
    fi

    return 1
}

# 生成WordPress文章
generate_article() {
    local title=$1
    local excerpt=$2
    local source_url=$3
    local category=$4
    local tags=$5

    log "INFO" "生成文章: $title"

    # 构建文章内容
    local content=$(cat <<EOF
$excerpt

<p><strong>原文链接:</strong> <a href="$source_url" target="_blank" rel="noopener">$source_url</a></p>

<p>本文内容由自动化工具生成，内容来源于互联网。</p>
EOF
)

    # HTML encode
    content=$(echo "$content" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/<br\/>/g')

    # 创建文章
    local category_ids=$(wp_get_category_id "$category")
    local tag_ids=$(wp_get_tag_ids "$tags")

    local featured_media=""
    if [[ "$FEATURED_IMAGE_ENABLED" == "true" ]]; then
        featured_media=$(auto_featured_image "$category")
    fi

    if wp_create_post "$title" "$content" "$category_ids" "$tag_ids" "$featured_media"; then
        log "INFO" "文章发布成功: $title"
        return 0
    else
        log "ERROR" "文章发布失败: $title"
        return 1
    fi
}

# 批量生成文章
batch_generate_articles() {
    local content_source=$1
    local max_articles=${2:-3}

    log "INFO" "开始批量生成文章，来源: $content_source"

    local fetched_content
    if ! fetched_content=$(fetch_content "$content_source"); then
        log "ERROR" "无法获取内容源"
        return 1
    fi

    local article_count=0
    local IFS=$'\n'

    # 处理RSS内容
    if [[ "$content_source" =~ \.(rss|xml|feed)$ ]]; then
        while IFS='|||' read -r title description link; do
            if [[ $article_count -ge $max_articles ]]; then
                break
            fi

            if [[ -n "$title" ]]; then
                generate_article "$title" "$description" "$link" "news" "WordPress"
                article_count=$((article_count + 1))
                sleep 2  # 避免频繁请求
            fi
        done <<< "$fetched_content"
    else
        # 处理单个HTML内容
        while IFS='|||' read -r title description link; do
            if [[ -n "$title" ]]; then
                generate_article "$title" "$description" "$link" "news" "WordPress"
                article_count=$((article_count + 1))
                break
            fi
        done <<< "$fetched_content"
    fi

    log "INFO" "批量生成文章完成，共生成 $article_count 篇文章"
    echo "$article_count"
    return 0
}

# 获取或创建分类ID
wp_get_category_id() {
    local category_name=$1
    local auth_header=$(get_auth_header)

    # 搜索分类
    local response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/categories?search=$(echo "$category_name" | jq -s -R -r @uri)" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    local category_id=$(echo "$response" | jq -r '.[0].id // empty')

    if [[ -z "$category_id" ]]; then
        # 创建新分类
        if category_id=$(wp_create_category "$category_name"); then
            echo "$category_id"
        else
            echo "1"  # 默认分类
        fi
    else
        echo "$category_id"
    fi
}

# 获取或创建标签ID
wp_get_tag_ids() {
    local tag_names=$1
    local tag_ids=""

    IFS=',' read -ra TAGS <<< "$tag_names"
    for tag in "${TAGS[@]}"; do
        tag=$(echo "$tag" | xargs)  # trim whitespace
        local auth_header=$(get_auth_header)

        local response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/tags?search=$(echo "$tag" | jq -s -R -r @uri)" \
            -H "$auth_header" \
            -H "Content-Type: application/json")

        local tag_id=$(echo "$response" | jq -r '.[0].id // empty')

        if [[ -z "$tag_id" ]]; then
            if tag_id=$(wp_create_tag "$tag"); then
                tag_ids="${tag_ids}${tag_id},"
            fi
        else
            tag_ids="${tag_ids}${tag_id},"
        fi
    done

    echo "${tag_ids%,}"
}
