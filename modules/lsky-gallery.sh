#!/bin/bash

# Lsky 图床集成模块
# 提供从Lsky图床读取图片并上传到WordPress的功能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/wordpress.conf"
source "${SCRIPT_DIR}/wordpress-api.sh"

# 从Lsky图床获取图片列表
lsky_get_images() {
    local album_id=${1:-""}
    local page=${2:-1}
    local per_page=${3:-20}

    local url="${LSKY_BASE_URL}/api/v1/images"

    # 构建查询参数
    local params="page=${page}&per_page=${per_page}"
    if [[ -n "$album_id" ]]; then
        params="${params}&album_id=${album_id}"
    fi

    response=$(curl -s -X GET "${url}?${params}" \
        -H "Authorization: Bearer ${LSKY_API_TOKEN}" \
        -H "Accept: application/json")

    if echo "$response" | grep -q '"data"'; then
        echo "$response"
        return 0
    else
        log "ERROR" "获取Lsky图片失败: $response"
        return 1
    fi
}

# 下载Lsky图片
lsky_download_image() {
    local image_url=$1
    local save_path=$2

    if [[ -z "$image_url" ]]; then
        log "ERROR" "图片URL不能为空"
        return 1
    fi

    # 创建保存目录
    mkdir -p "$(dirname "$save_path")"

    # 下载图片
    if curl -s -L -o "$save_path" "$image_url"; then
        log "INFO" "图片下载成功: $save_path"
        return 0
    else
        log "ERROR" "图片下载失败: $image_url"
        return 1
    fi
}

# 从Lsky获取图片并上传到WordPress
lsky_to_wordpress() {
    local album_id=${1:-""}
    local max_images=${2:-5}
    local temp_dir=$(mktemp -d)

    log "INFO" "开始从Lsky图床获取图片..."

    # 获取图片列表
    local images_response
    if ! images_response=$(lsky_get_images "$album_id" 1 "$max_images"); then
        rm -rf "$temp_dir"
        return 1
    fi

    local uploaded_images=()

    # 解析并处理每张图片
    local image_count=$(echo "$images_response" | jq -r '.data | length')

    for ((i = 0; i < image_count; i++)); do
        local image_data=$(echo "$images_response" | jq -r ".data[$i]")
        local image_url=$(echo "$image_data" | jq -r '.url')
        local image_name=$(echo "$image_data" | jq -r '.name // "image"')

        # 生成文件名
        local file_ext="${image_url##*.}"
        if [[ "$file_ext" =~ ^(jpg|jpeg|png|gif|webp)$ ]]; then
            local save_path="${temp_dir}/${image_name}.${file_ext}"
        else
            local save_path="${temp_dir}/${image_name}.jpg"
        fi

        # 下载图片
        if lsky_download_image "$image_url" "$save_path"; then
            # 上传到WordPress
            local media_id
            if media_id=$(wp_upload_media "$save_path" "$image_name"); then
                uploaded_images+=("$media_id")
                log "INFO" "图片已上传到WordPress (ID: $media_id)"
            fi
        fi
    done

    # 清理临时文件
    rm -rf "$temp_dir"

    # 返回上传的图片ID列表（用逗号分隔）
    if [[ ${#uploaded_images[@]} -gt 0 ]]; then
        echo "$(IFS=','; echo "${uploaded_images[*]}")"
        return 0
    else
        log "WARN" "没有图片成功上传到WordPress"
        return 1
    fi
}

# 搜索Lsky图床中的图片
lsky_search_images() {
    local keyword=$1
    local page=${2:-1}
    local per_page=${3:-20}

    local url="${LSKY_BASE_URL}/api/v1/search"

    response=$(curl -s -X GET "${url}?keyword=${keyword}&page=${page}&per_page=${per_page}" \
        -H "Authorization: Bearer ${LSKY_API_TOKEN}" \
        -H "Accept: application/json")

    if echo "$response" | grep -q '"data"'; then
        echo "$response"
        return 0
    else
        log "ERROR" "搜索Lsky图片失败: $response"
        return 1
    fi
}

# 自动为文章选择特色图片
auto_featured_image() {
    local category=${1:-"default"}
    local max_retry=3

    log "INFO" "正在为主题为'$category'的文章选择特色图片..."

    for ((i = 1; i <= max_retry; i++)); do
        local images_response
        if images_response=$(lsky_search_images "$category" 1 5); then
            local image_count=$(echo "$images_response" | jq -r '.data | length')

            if [[ $image_count -gt 0 ]]; then
                # 随机选择一张图片
                local random_index=$((RANDOM % image_count))
                local image_url=$(echo "$images_response" | jq -r ".data[$random_index].url")
                local image_name=$(echo "$images_response" | jq -r ".data[$random_index].name // \"featured_image\"")

                local temp_file=$(mktemp).jpg

                if lsky_download_image "$image_url" "$temp_file"; then
                    local media_id
                    if media_id=$(wp_upload_media "$temp_file" "$image_name"); then
                        rm -f "$temp_file"
                        log "INFO" "特色图片已设置 (ID: $media_id)"
                        echo "$media_id"
                        return 0
                    fi
                    rm -f "$temp_file"
                fi
            fi
        fi

        log "WARN" "第 $i 次尝试获取特色图片失败，重试中..."
        sleep 2
    done

    log "ERROR" "无法为文章设置特色图片"
    return 1
}
