#!/bin/bash

# AI 内容生成模块
# 使用 SiliconFlow DeepSeek API 生成医美文章内容

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/your-website.conf"
source "${SCRIPT_DIR}/../config/wordpress.conf"

# 从 URL 获取标题列表
ai_get_titles() {
    local title_url=$1

    log "INFO" "从 $title_url 获取标题列表..."

    local title_content=$(curl -s --max-time 20 "$title_url")

    if [ -z "$title_content" ]; then
        log "WARN" "无法从 $title_url 获取标题，使用默认标题"
        echo "医美新时代：自然美与科技的融合"
        return 1
    fi

    # 将标题存入数组
    local titles=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            # 去除书名号
            line=$(echo "$line" | sed 's/《//g; s/》//g')
            titles+=("$line")
        fi
    done <<< "$title_content"

    if [ ${#titles[@]} -eq 0 ]; then
        log "WARN" "标题列表为空，使用默认标题"
        echo "医美新时代：自然美与科技的融合"
    else
        # 随机选择一个标题
        local random_index=$((RANDOM % ${#titles[@]}))
        echo "${titles[$random_index]}"
    fi

    return 0
}

# 生成文章内容
ai_generate_article() {
    local title=$1
    local max_tokens=${2:-4000}
    local temperature=${3:-0.7}

    log "INFO" "使用 AI 生成文章: $title"

    local request=$(cat <<EOF
{
  "model": "$AI_MODEL",
  "messages": [
    {
      "role": "user",
      "content": "请以以下标题写一篇1200-1500字的医美消费文章。标题： $title\n\n要求：\n1. 文章前面加一段箴言式开篇，保持美观的Markdown排版；\n2. 文章正文内容清晰有层次，分段合理；\n3. 请在文章末尾单独一行返回文章关键词，格式为 \"关键字标签: 关键词1, 关键词2, …\"；\n4. 请在文章末尾另外单独一行返回文章建议分类，格式为 \"建议分类: 分类1, 分类2, …\"。"
    }
  ],
  "temperature": $temperature,
  "max_tokens": $max_tokens
}
EOF
)

    local response=$(curl -s --max-time 300 \
        -X POST "$AI_API_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AI_API_KEY" \
        -d "$request")

    if [ -z "$response" ]; then
        log "ERROR" "API 请求超时或失败，没有收到响应"
        return 1
    fi

    local content
    if command -v jq >/dev/null 2>&1; then
        content=$(echo "$response" | jq -r '.choices[0].message.content // empty')
    else
        # 备用解析方式
        content=$(echo "$response" | grep -o '"content":"[^"]*' | sed 's/"content":"//g' | head -1)
    fi

    if [ -z "$content" ]; then
        log "ERROR" "无法从响应中提取内容"
        log "DEBUG" "API响应: $response"
        return 1
    fi

    # 解码转义字符
    content=$(echo "$content" | sed 's/\\n/\n/g; s/\\"/\"/g; s/\\t/\t/g')

    echo "$content"
    return 0
}

# 处理生成的文章内容
ai_process_content() {
    local raw_content=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local article_file="医美文章_$timestamp.md"

    log "INFO" "处理文章内容..."

    # 保存原始内容到文件
    echo "$raw_content" > "$article_file"

    # 提取标题（第一行）
    local article_title=$(head -n 1 "$article_file")
    if [[ -z "$article_title" ]]; then
        article_title="医美文章_$timestamp"
    fi

    # 读取正文（除第一行）
    local article_content=$(tail -n +2 "$article_file")

    # 保存原始内容
    local original_content="$article_content"

    # 删除不需要的行（箴言式开篇标记、一级标题、代码块标记等）
    article_content=$(echo "$article_content" | sed '/箴言式开篇/d' | sed '/^# /d' | sed '/```markdown/d; /```/d; /本文配图/d')

    # 如果处理后内容为空，回退到原始内容
    if [ -z "$article_content" ]; then
        log "WARN" "处理后的正文为空，回退到原始内容"
        article_content="$original_content"
    fi

    # 提取关键词（格式：关键字标签: xxx, xxx）
    local keywords=""
    if echo "$article_content" | grep -q "关键字标签[:：]"; then
        keywords=$(echo "$article_content" | grep -E "^关键字标签[:：]" | head -n 1 | sed 's/^关键字标签[:：]\s*//')
    fi

    # 提取建议分类（格式：建议分类: xxx, xxx）
    local categories="未分类"
    if echo "$article_content" | grep -q "建议分类[:：]"; then
        categories=$(echo "$article_content" | sed 's/^建议分类[:：]\s*//')
        if [ -z "$categories" ]; then
            categories="未分类"
        fi
    fi

    # 从正文内容中移除关键词和分类行
    article_content=$(echo "$article_content" | sed '/^关键字标签[:：]/d; /^建议分类[:：]/d')

    # 创建输出目录（如果不存在）
    mkdir -p "$OUTPUT_DIR"

    # 更新文章文件
    echo "$article_content" > "$OUTPUT_DIR/$article_file"

    # 返回结果
    echo "TITLE: $article_title"
    echo "KEYWORDS: $keywords"
    echo "CATEGORIES: $categories"
    echo "CONTENT:"
    echo "$article_content"

    return 0
}

# 生成完整文章
generate_medical_beauty_article() {
    log "INFO" "开始生成医美文章..."

    # 获取标题
    local title
    if ! title=$(ai_get_titles "$TITLE_URL"); then
        log "WARN" "获取标题失败，使用默认标题"
        title="医美新时代：自然美与科技的融合"
    fi

    log "INFO" "选定标题: $title"

    # 生成文章内容
    local raw_content
    if ! raw_content=$(ai_generate_article "$title"); then
        log "ERROR" "文章生成失败"
        return 1
    fi

    # 处理内容
    local processed
    if ! processed=$(ai_process_content "$raw_content"); then
        log "ERROR" "内容处理失败"
        return 1
    fi

    # 解析处理结果
    local article_title=$(echo "$processed" | grep "^TITLE:" | head -n 1 | sed 's/^TITLE: //')
    local keywords=$(echo "$processed" | grep "^KEYWORDS:" | head -n 1 | sed 's/^KEYWORDS: //')
    local categories=$(echo "$processed" | grep "^CATEGORIES:" | head -n 1 | sed 's/^CATEGORIES: //')
    local article_content=$(echo "$processed" | sed '1,/^CONTENT:/d')

    # 插入图片
    article_content=$(insert_images_into_content "$article_content" "$categories")

    log "INFO" "文章生成完成"

    # 返回结果
    echo "TITLE: $article_title"
    echo "KEYWORDS: $keywords"
    echo "CATEGORIES: $categories"
    echo "CONTENT:"
    echo "$article_content"

    return 0
}

# 插入图片到内容中
insert_images_into_content() {
    local content=$1
    local category=$2

    log "INFO" "从兰空图床获取图片..."

    # 获取兰空图床图片列表
    local album_id=""
    local img_list=""
    local headers="-H \"Authorization: $LSKY_AUTH\" -H \"Accept: application/json\""

    # 获取相册 ID
    local album_response=$(curl -s ${LSKY_AUTH} -H "Accept: application/json" "$LSKY_BASE_URL/albums?page=1&limit=100")
    album_id=$(echo "$album_response" | jq -r ".data.data[] | select(.name==\"$LSKY_ALBUM_NAME\") | .id")

    if [ -z "$album_id" ]; then
        log "WARN" "未找到相册 '$LSKY_ALBUM_NAME'，跳过图片插入"
        echo "$content"
        return 0
    fi

    log "INFO" "找到相册 '$LSKY_ALBUM_NAME' (ID: $album_id)"

    # 分页获取图片链接（最多获取 500 张）
    local page=1
    while true; do
        local page_response=$(curl -s ${LSKY_AUTH} -H "Accept: application/json" "$LSKY_BASE_URL/images?album_id=$album_id&page=$page&order=newest&limit=100")
        local new_links=$(echo "$page_response" | jq -r '.data.data[].links.url')

        if [ -z "$new_links" ]; then
            break
        fi

        img_list="${img_list}"
${new_links}"

        local count=$(echo "$img_list" | grep -c '^')
        if [ $count -ge 500 ]; then
            break
        fi

        page=$((page + 1))
    done

    img_list=$(echo "$img_list" | sed '/^$/d')
    local total_count=$(echo "$img_list" | wc -l | tr -d ' ')

    log "INFO" "从图床获得图片数量：$total_count"

    if [ $total_count -eq 0 ]; then
        log "WARN" "未从图床获得任何图片链接"
        echo "$content"
        return 0
    fi

    # 随机抽取 2 张图片
    local selected_img=$(echo "$img_list" | shuf -n 2)
    local begin_image=$(echo "$selected_img" | head -n 1 | awk '{print "![](" $0 ")"}')
    local end_image=$(echo "$selected_img" | tail -n 1 | awk '{print "![](" $0 ")"}')

    log "INFO" "图片 1: $begin_image"
    log "INFO" "图片 2: $end_image"

    # 在内容前后插入图片
    local final_content=$(printf "%s\n\n%s\n\n%s" "$begin_image" "$content" "$end_image")

    echo "$final_content"
    return 0
}

# 发布文章到 WordPress (XML-RPC)
wp_publish_article_xmlrpc() {
    local title=$1
    local content=$2
    local categories=$3
    local keywords=$4

    log "INFO" "发布文章到 WordPress (XML-RPC): $title"

    # 准备发布数据
    local cat_list="$categories"
    local tag_list=""

    if [ -n "$keywords" ]; then
        tag_list=$(echo "$keywords" | sed 's/,/", "/g' | sed 's/^/["/; s/$/"]/')
    else
        tag_list="[]"
    fi

    local python_script=$(cat <<END
import xmlrpc.client
import sys

wp_url = "$WP_XMLRPC_URL"
wp_username = "$WP_ADMIN_USER"
wp_password = "$WP_ADMIN_PASSWORD"
blog_id = $WP_BLOG_ID

post_title = """$title"""
post_content = """$content"""

post = {
    'post_title': post_title,
    'post_content': post_content,
    'post_status': '$PUBLISH_STATUS',
    'mt_keywords': "$keywords",
}

if "${categories}" != "未分类":
    post['categories'] = ["${categories}"]

try:
    wp = xmlrpc.client.ServerProxy(wp_url)
    post_id = wp.wp.newPost(blog_id, wp_username, wp_password, post)
    if not post_id:
        print("文章发布失败，但没有返回错误")
        sys.exit(1)
    print(post_id)
except Exception as e:
    print(f"发布文章时出错: {str(e)}")
    sys.exit(1)
END
)

    local post_id=$(python3 -c "$python_script" 2>&1)

    if [[ $? -eq 0 ]] && [[ "$post_id" =~ ^[0-9]+$ ]]; then
        log "INFO" "文章发布成功！文章ID: $post_id"
        log "INFO" "访问链接: ${WP_SITE_URL}/?p=$post_id"
        return 0
    else
        log "ERROR" "文章发布失败: $post_id"
        return 1
    fi
}

# 批量生成并发布医美文章
batch_generate_medical_articles() {
    local num_articles=${1:-1}

    log "INFO" "开始批量生成 $num_articles 篇医美文章..."

    local articles_created=0

    for ((i = 1; i <= num_articles; i++)); do
        log "INFO" "生成第 $i 篇文章..."

        local article_data
        if article_data=$(generate_medical_beauty_article); then
            local title=$(echo "$article_data" | grep "^TITLE:" | head -n 1 | sed 's/^TITLE: //')
            local keywords=$(echo "$article_data" | grep "^KEYWORDS:" | head -n 1 | sed 's/^KEYWORDS: //')
            local categories=$(echo "$article_data" | grep "^CATEGORIES:" | head -n 1 | sed 's/^CATEGORIES: //')
            local content=$(echo "$article_data" | sed '1,/^CONTENT:/d')

            if wp_publish_article_xmlrpc "$title" "$content" "$categories" "$keywords"; then
                articles_created=$((articles_created + 1))
                log "INFO" "第 $i 篇文章发布完成"

                # 每篇文章之间稍作延迟，避免频繁请求
                if [[ $i -lt $num_articles ]]; then
                    sleep 5
                fi
            else
                log "ERROR" "第 $i 篇文章发布失败，跳过"
            fi
        else
            log "ERROR" "第 $i 篇文章生成失败，跳过"
        fi
    done

    log "INFO" "批量生成完成，共成功发布 $articles_created 篇文章"

    return 0
}
