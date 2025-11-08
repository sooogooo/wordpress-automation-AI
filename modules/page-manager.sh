#!/bin/bash

# WordPress 页面管理模块
# 创建和管理WordPress网站的必要页面

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/wordpress.conf"
source "${SCRIPT_DIR}/wordpress-api.sh"

# 创建关于页面
create_about_page() {
    log "INFO" "创建关于页面..."

    local title="关于我们"
    local content=$(cat <<'EOF'
<h2>欢迎来到我们的网站</h2>

<p>这是一个使用WordPress自动维护系统管理的网站。</p>

<h3>我们的使命</h3>
<p>通过自动化工具，我们致力于提供高质量的内容，帮助用户获取最新资讯和实用知识。</p>

<h3>联系方式</h3>
<ul>
<li>邮箱: contact@example.com</li>
<li>电话: 123-456-7890</li>
</ul>

<p>感谢您的访问！</p>
EOF
)

    if wp_create_page "$title" "$content"; then
        log "INFO" "关于页面创建成功"
        return 0
    else
        log "ERROR" "关于页面创建失败"
        return 1
    fi
}

# 创建联系页面
create_contact_page() {
    log "INFO" "创建联系页面..."

    local title="联系我们"
    local content=$(cat <<'EOF'
<h2>联系我们</h2>

<p>如果您有任何问题、建议或合作意向，请通过以下方式联系我们：</p>

<h3>联系信息</h3>
<ul>
<li><strong>电子邮箱:</strong> contact@example.com</li>
<li><strong>联系电话:</strong> 123-456-7890</li>
<li><strong>工作时间:</strong> 周一至周五 9:00-18:00</li>
</ul>

<h3>在线留言</h3>
<p>您也可以使用网站底部的评论区给我们留言，我们会尽快回复。</p>

<p>感谢您对网站的关注和支持！</p>
EOF
)

    if wp_create_page "$title" "$content"; then
        log "INFO" "联系页面创建成功"
        return 0
    else
        log "ERROR" "联系页面创建失败"
        return 1
    fi
}

# 创建隐私政策页面
create_privacy_page() {
    log "INFO" "创建隐私政策页面..."

    local title="隐私政策"
    local content=$(cat <<'EOF'
<h2>隐私政策</h2>

<p>最后更新时间: $(date +%Y年%m月%d日)</p>

<h3>1. 信息收集</h3>
<p>我们收集您在使用网站时提供的信息，包括评论、联系方式等。</p>

<h3>2. 信息使用</h3>
<p>我们使用收集的信息来改善网站内容、提升用户体验和回复您的咨询。</p>

<h3>3. 信息保护</h3>
<p>我们采取适当的安全措施来保护您的个人信息不被未经授权的访问或使用。</p>

<h3>4. Cookies</h3>
<p>网站可能使用Cookies来提升用户体验，您可以在浏览器设置中管理Cookies。</p>

<h3>5. 第三方链接</h3>
<p>网站可能包含指向第三方网站的链接，我们对这些网站的隐私政策不承担责任。</p>

<h3>6. 联系我们</h3>
<p>如果您对我们的隐私政策有任何疑问，请联系我们。</p>
EOF
)

    if wp_create_page "$title" "$content"; then
        log "INFO" "隐私政策页面创建成功"
        return 0
    else
        log "ERROR" "隐私政策页面创建失败"
        return 1
    fi
}

# 创建服务条款页面
create_terms_page() {
    log "INFO" "创建服务条款页面..."

    local title="服务条款"
    local content=$(cat <<'EOF'
<h2>服务条款</h2>

<p>欢迎使用我们的网站。访问和使用本网站即表示您同意遵守以下服务条款。</p>

<h3>1. 使用许可</h3>
<p>我们授予您有限的、非排他性的访问和使用网站内容的许可。</p>

<h3>2. 用户责任</h3>
<p>用户在使用网站时应遵守相关法律法规，不得发布违法或不当内容。</p>

<h3>3. 内容所有权</h3>
<p>网站上的所有内容受版权保护，未经许可不得复制或分发。</p>

<h3>4. 免责声明</h3>
<p>网站内容仅供参考，我们不对信息的准确性、完整性或及时性作出保证。</p>

<h3>5. 条款修改</h3>
<p>我们保留随时修改这些服务条款的权利，修改后将在网站上公布。</p>

<h3>6. 适用法律</h3>
<p>本条款受相关法律管辖并按其解释。</p>
EOF
)

    if wp_create_page "$title" "$content"; then
        log "INFO" "服务条款页面创建成功"
        return 0
    else
        log "ERROR" "服务条款页面创建失败"
        return 1
    fi
}

# 创建归档页面
create_archives_page() {
    log "INFO" "创建文章归档页面..."

    local title="文章归档"
    local content=$(cat <<'EOF'
<h2>文章归档</h2>

<p>您可以在此浏览所有已发布的文章。使用搜索功能可以快速找到感兴趣的内容。</p>

<h3>按分类浏览</h3>
<p>点击侧边栏的分类链接可以查看特定主题的文章。</p>

<h3>按日期浏览</h3>
<p>使用日期归档可以查看特定时间段发布的文章。</p>

<h3>按标签浏览</h3>
<p>点击文章标签可以找到相关内容。</p>

<p>我们会定期更新网站内容，欢迎经常访问查看最新文章。</p>
EOF
)

    if wp_create_page "$title" "$content"; then
        log "INFO" "文章归档页面创建成功"
        return 0
    else
        log "ERROR" "文章归档页面创建失败"
        return 1
    fi
}

# 检查页面是否存在
page_exists() {
    local page_title=$1
    local auth_header=$(get_auth_header)

    local response=$(curl -s -X GET "$WP_SITE_URL/wp-json/wp/v2/pages?search=$(echo "$page_title" | jq -s -R -r @uri)" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    local page_count=$(echo "$response" | jq -r 'length')

    if [[ $page_count -gt 0 ]]; then
        return 0  # 页面存在
    else
        return 1  # 页面不存在
    fi
}

# 初始化所有必要页面
init_required_pages() {
    log "INFO" "开始初始化WordPress必要页面..."

    local pages_created=0

    # 页面列表和创建函数映射
    declare -A pages_to_create=(
        ["关于我们"]=create_about_page
        ["联系我们"]=create_contact_page
        ["隐私政策"]=create_privacy_page
        ["服务条款"]=create_terms_page
        ["文章归档"]=create_archives_page
    )

    for page_title in "${!pages_to_create[@]}"; do
        if page_exists "$page_title"; then
            log "INFO" "页面已存在，跳过: $page_title"
        else
            log "INFO" "创建页面: $page_title"
            if "${pages_to_create[$page_title]}"; then
                pages_created=$((pages_created + 1))
            fi
        fi
    done

    log "INFO" "页面初始化完成，共创建 $pages_created 个新页面"
    echo "$pages_created"
    return 0
}

# 设置页面为首页
set_homepage() {
    local page_id=$1

    if [[ -z "$page_id" ]]; then
        log "ERROR" "页面ID不能为空"
        return 1
    fi

    local auth_header=$(get_auth_header)

    # 设置显示首页为静态页面
    response=$(curl -s -X POST "$WP_SITE_URL/wp-json/wp/v2/settings" \
        -H "$auth_header" \
        -H "Content-Type: application/json" \
        -d "{\"show_on_front\":\"page\",\"page_on_front\":$page_id}")

    if echo "$response" | grep -q '"show_on_front"'; then
        log "INFO" "首页设置成功，页面ID: $page_id"
        return 0
    else
        log "ERROR" "首页设置失败: $response"
        return 1
    fi
}

# 删除页面
delete_page() {
    local page_id=$1
    local force=${2:-false}

    if [[ -z "$page_id" ]]; then
        log "ERROR" "页面ID不能为空"
        return 1
    fi

    local auth_header=$(get_auth_header)

    response=$(curl -s -X DELETE "$WP_SITE_URL/wp-json/wp/v2/pages/$page_id?force=$force" \
        -H "$auth_header" \
        -H "Content-Type: application/json")

    if echo "$response" | grep -q '"id"'; then
        log "INFO" "页面删除成功 (ID: $page_id)"
        return 0
    else
        log "ERROR" "页面删除失败: $response"
        return 1
    fi
}
