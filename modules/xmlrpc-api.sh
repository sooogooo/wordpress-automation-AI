#!/bin/bash

# WordPress XML-RPC API 模块
# 提供与 WordPress XML-RPC API 交互的功能
# 需要安装 Python 3 和 xmlrpc.client 模块

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查依赖
check_python_dependencies() {
    local deps_missing=0

    if ! command -v python3 >/dev/null 2>&1; then
        echo "错误: python3 未安装，请先安装 python3"
        deps_missing=1
    fi

    python3 -c "import xmlrpc.client" 2>/dev/null || {
        log "ERROR" "Python xmlrpc.client 库不可用，请检查 Python 安装"
        deps_missing=1
    }

    if [[ $deps_missing -eq 1 ]]; then
        return 1
    fi

    return 0
}

# 获取博客分类目录
wp_get_categories_xmlrpc() {
    local xmlrpc_url=$1
    local username=$2
    local password=$3
    local blog_id=$4

    log "INFO" "从 WordPress 获取分类目录 (XML-RPC)..."

    local python_script=$(cat <<END
import xmlrpc.client
import sys

try:
    wp = xmlrpc.client.ServerProxy("$xmlrpc_url")
    cats = wp.getCategories($blog_id, "$username", "$password")
    names = [cat['categoryName'] for cat in cats if 'categoryName' in cat]
    print(", ".join(names))
except Exception as e:
    print(f"获取分类时出错: {str(e)}")
    sys.exit(1)
END
)

    local result=$(python3 -c "$python_script" 2>&1)

    if [[ $? -eq 0 ]]; then
        log "INFO" "成功获取分类: $result"
        echo "$result"
        return 0
    else
        log "ERROR" "获取分类失败: $result"
        return 1
    fi
}

# 获取 WordPress 分类 ID
category_exists_xmlrpc() {
    local xmlrpc_url=$1
    local username=$2
    local password=$3
    local category_name=$4
    local blog_id=$5

    log "DEBUG" "检查分类是否存在: $category_name"

    local categories
    if ! categories=$(wp_get_categories_xmlrpc "$xmlrpc_url" "$username" "$password" "$blog_id"); then
        return 1
    fi

    # 检查分类是否存在
    if [[ "${categories,,}" =~ ${category_name,,} ]]; then
        log "DEBUG" "分类存在: $category_name"
        return 0
    else
        log "DEBUG" "分类不存在: $category_name"
        return 1
    fi
}

# 发布文章到 WordPress (XML-RPC)
wp_publish_post_xmlrpc() {
    local xmlrpc_url=$1
    local username=$2
    local password=$3
    local blog_id=$4
    local post_title=$5
    local post_content=$6
    local post_status=${7:-"publish"}
    local categories=${8:-"未分类"}
    local keywords=${9:-""}

    log "INFO" "发布文章到 WordPress (XML-RPC): $post_title"
    log "DEBUG" "分类: $categories, 标签: $keywords"

    local python_script=$(cat <<END
import xmlrpc.client
import sys

wp_url = "$xmlrpc_url"
wp_username = "$username"
wp_password = "$password"
blog_id = $blog_id

post_title = """$post_title"""
post_content = """$post_content"""

post = {
    'post_title': post_title,
    'post_content': post_content,
    'post_status': '$post_status',
    'mt_keywords': "$keywords",
}

# 添加分类
if '${categories}' and '${categories}' != '未分类':
    # 处理多个分类
    cat_list = [cat.strip() for cat in '${categories}'.split(',') if cat.strip()]
    if cat_list:
        post['categories'] = cat_list

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

    local result=$(python3 -c "$python_script" 2>&1)

    if [[ $? -eq 0 ]] && [[ "$result" =~ ^[0-9]+$ ]]; then
        log "INFO" "文章发布成功！文章ID: $result"
        return 0
    else
        log "ERROR" "文章发布失败: $result"
        return 1
    fi
}

# 批量发布文章
wp_batch_publish_xmlrpc() {
    local xmlrpc_url=$1
    local username=$2
    local password=$3
    local blog_id=$4
    shift 4

    local published_count=0

    for article_file in "$@"; do
        if [[ ! -f "$article_file" ]]; then
            log "WARN" "文件不存在，跳过: $article_file"
            continue
        fi

        # 从文件名提取信息
        local title=$(head -n 1 "$article_file")
        local content=$(tail -n +2 "$article_file")

        if wp_publish_post_xmlrpc "$xmlrpc_url" "$username" "$password" "$blog_id" \
                "$title" "$content" "publish" "未分类" ""; then
            published_count=$((published_count + 1))
            log "INFO" "成功发布: $article_file"
        else
            log "ERROR" "发布失败: $article_file"
        fi
    done

    log "INFO" "批量发布完成，共发布 $published_count 篇文章"
    echo "$published_count"
}

# 获取最新文章
wp_get_recent_posts_xmlrpc() {
    local xmlrpc_url=$1
    local username=$2
    local password=$3
    local blog_id=$4
    local num_posts=${5:-5}

    log "INFO" "获取最近的 $num_posts 篇文章..."

    local python_script=$(cat <<END
import xmlrpc.client
import sys

try:
    wp = xmlrpc.client.ServerProxy("$xmlrpc_url")
    posts = wp.getRecentPosts($blog_id, "$username", "$password", $num_posts)
    for post in posts:
        print(f"ID: {post.get('postid', 'N/A')} | Title: {post.get('title', 'N/A')} | Date: {post.get('dateCreated', 'N/A')}")
    print(f"共获取 {len(posts)} 篇文章")
except Exception as e:
    print(f"获取文章失败: {str(e)}")
    sys.exit(1)
END
)

    local result=$(python3 -c "$python_script" 2>&1)

    if [[ $? -eq 0 ]]; then
        echo "$result"
        return 0
    else
        log "ERROR" "获取文章失败: $result"
        return 1
    fi
}

# 删除文章
wp_delete_post_xmlrpc() {
    local xmlrpc_url=$1
    local username=$2
    local password=$3
    local blog_id=$4
    local post_id=$5
    local force=${6:-false}

    log "INFO" "删除文章 (ID: $post_id)"

    local python_script=$(cat <<END
import xmlrpc.client
import sys

try:
    wp = xmlrpc.client.ServerProxy("$xmlrpc_url")
    result = wp.deletePost($blog_id, "$username", "$password", $post_id)
    print(result)
except Exception as e:
    print(f"删除文章失败: {str(e)}")
    sys.exit(1)
END
)

    local result=$(python3 -c "$python_script" 2>&1)

    if [[ "$result" == "True" ]]; then
        log "INFO" "文章删除成功 (ID: $post_id)"
        return 0
    else
        log "ERROR" "文章删除失败: $result"
        return 1
    fi
}
