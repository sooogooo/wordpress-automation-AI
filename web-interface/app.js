// Web 管理界面主要 JavaScript
// WordPress 自动维护系统 Web 界面

class WPAutoManager {
    constructor() {
        this.config = {};
        this.loggedIn = false;
        this.defaultPassword = 'admin9900';
        this.init();
    }

    init() {
        this.bindEvents();
        this.loadSavedConfig();
        this.initTabs();
        this.initSliders();
    }

    // 绑定事件
    bindEvents() {
        // 登录表单
        document.getElementById('login-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleLogin();
        });

        // 退出登录
        document.getElementById('logout-btn').addEventListener('click', () => {
            this.handleLogout();
        });

        // 导航标签
        document.querySelectorAll('.nav-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                this.switchTab(e.target.dataset.tab);
            });
        });

        // 生成按钮
        document.getElementById('save-config-btn').addEventListener('click', () => {
            this.saveAllConfig();
        });

        document.getElementById('generate-bash-btn').addEventListener('click', () => {
            this.generateBashScript();
        });

        document.getElementById('test-config-btn').addEventListener('click', () => {
            this.testConfig();
        });

        // 下载和复制按钮
        document.getElementById('download-config-btn').addEventListener('click', () => {
            this.downloadFile('config.txt', document.getElementById('config-output').value);
        });

        document.getElementById('download-bash-btn').addEventListener('click', () => {
            this.downloadFile('generate-article.sh', document.getElementById('bash-output').value);
        });

        document.getElementById('copy-config-btn').addEventListener('click', () => {
            this.copyToClipboard('config-output', '配置');
        });

        document.getElementById('copy-bash-btn').addEventListener('click', () => {
            this.copyToClipboard('bash-output', '脚本');
        });

        // 表单变化时自动保存
        const forms = ['wordpress-form', 'lsky-form', 'general-form'];
        forms.forEach(formId => {
            const form = document.getElementById(formId);
            if (form) {
                form.addEventListener('input', () => {
                    this.autoSave();
                });
            }
        });

        // AI 提供商变化时更新默认值
        document.getElementById('ai-provider').addEventListener('change', (e) => {
            this.updateAIModels();
            this.autoSave();
        });
    }

    // 处理登录
    handleLogin() {
        const username = document.getElementById('login-username').value;
        const password = document.getElementById('login-password').value;

        const savedPassword = localStorage.getItem('webAdminPassword') || this.defaultPassword;

        if (username === 'admin' && password === savedPassword) {
            this.loggedIn = true;
            document.getElementById('login-page').style.display = 'none';
            document.getElementById('main-page').style.display = 'block';
            this.showMessage('登录成功！', 'success');
        } else {
            const errorEl = document.querySelector('.login-error');
            errorEl.textContent = '用户名或密码错误';
            errorEl.style.display = 'block';
        }
    }

    // 处理退出
    handleLogout() {
        this.loggedIn = false;
        document.getElementById('login-page').style.display = 'block';
        document.getElementById('main-page').style.display = 'none';
        document.getElementById('login-form').reset();
        document.querySelector('.login-error').style.display = 'none';
    }

    // 初始化标签页
    initTabs() {
        this.switchTab('wordpress');
    }

    // 切换标签
    switchTab(tabName) {
        document.querySelectorAll('.nav-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(`${tabName}-tab`).classList.add('active');
    }

    // 初始化滑块
    initSliders() {
        const temperatureSlider = document.getElementById('temperature');
        const rangeValue = document.querySelector('.range-value');

        temperatureSlider.addEventListener('input', (e) => {
            rangeValue.textContent = e.target.value;
            this.autoSave();
        });
    }

    // 更新 AI 模型选择
    updateAIModels() {
        const provider = document.getElementById('ai-provider').value;
        // 可以在这里根据提供商显示/隐藏对应的模型选项
    }

    // 自动保存
    autoSave() {
        const config = this.collectFormData();
        localStorage.setItem('wpAutoConfig', JSON.stringify(config));
    }

    // 加载保存的配置
    loadSavedConfig() {
        const saved = localStorage.getItem('wpAutoConfig');
        if (saved) {
            this.config = JSON.parse(saved);
            this.populateFormData(this.config);
        }

        // 加载保存的密码
        const savedPassword = localStorage.getItem('webAdminPassword');
        if (savedPassword) {
            this.defaultPassword = savedPassword;
        }
    }

    // 收集表单数据
    collectFormData() {
        const data = {};

        // WordPress 设置
        const wordpressForm = document.getElementById('wordpress-form');
        if (wordpressForm) {
            data.wordpress = Object.fromEntries(new FormData(wordpressForm));
        }

        // 兰空图床设置
        const lskyForm = document.getElementById('lsky-form');
        if (lskyForm) {
            data.lsky = Object.fromEntries(new FormData(lskyForm));
        }

        // 其他设置
        const generalForm = document.getElementById('general-form');
        if (generalForm) {
            data.general = Object.fromEntries(new FormData(generalForm));
        }

        // AI 模型设置
        data.ai = {
            provider: document.getElementById('ai-provider').value,
            prompt: document.getElementById('ai-prompt').value,
            maxTokens: document.getElementById('max-tokens').value,
            temperature: document.getElementById('temperature').value,
            moonshotKey: document.getElementById('moonshot-key').value,
            moonshotUrl: document.getElementById('moonshot-url').value,
            moonshotModel: document.getElementById('moonshot-model').value,
            deepseekKey: document.getElementById('deepseek-key').value,
            deepseekUrl: document.getElementById('deepseek-url').value,
            deepseekModel: document.getElementById('deepseek-model').value,
            siliconflowKey: document.getElementById('siliconflow-key').value,
            siliconflowUrl: document.getElementById('siliconflow-url').value,
            siliconflowModel: document.getElementById('siliconflow-model').value,
            titleUrl: document.getElementById('title-url').value
        };

        return data;
    }

    // 填充表单数据
    populateFormData(config) {
        if (config.general && config.general.webAdminPassword) {
            this.defaultPassword = config.general.webAdminPassword;
            localStorage.setItem('webAdminPassword', this.defaultPassword);
        }

        for (const section in config) {
            if (config.hasOwnProperty(section)) {
                const sectionData = config[section];
                for (const key in sectionData) {
                    if (sectionData.hasOwnProperty(key)) {
                        const element = document.getElementById(key.replace(/([A-Z])/g, '-$1').toLowerCase());
                        if (element) {
                            if (element.type === 'checkbox') {
                                element.checked = sectionData[key] === 'on' || sectionData[key] === true;
                            } else {
                                element.value = sectionData[key];
                            }
                        }
                    }
                }
            }
        }

        // 触发滑块更新
        const temperatureSlider = document.getElementById('temperature');
        if (temperatureSlider) {
            const rangeValue = document.querySelector('.range-value');
            rangeValue.textContent = temperatureSlider.value;
        }
    }

    // 保存所有配置
    saveAllConfig() {
        const config = this.collectFormData();
        localStorage.setItem('wpAutoConfig', JSON.stringify(config));

        // 保存管理密码
        if (config.general && config.general.webAdminPassword) {
            localStorage.setItem('webAdminPassword', config.general.webAdminPassword);
            this.defaultPassword = config.general.webAdminPassword;
        }

        this.showMessage('配置已保存！', 'success');
    }

    // 生成配置文件
    generateConfig() {
        const config = this.collectFormData();

        let configContent = `#!/bin/bash
# WordPress 自动维护系统配置文件
# 生成时间: ${new Date().toLocaleString('zh-CN')}

# ==================== WordPress 配置 ====================
WP_SITE_URL="${config.wordpress.wpUrl || ''}"
WP_XMLRPC_URL="${config.wordpress.wpXmlrpc || ''}"
WP_ADMIN_USER="${config.wordpress.wpUsername || ''}"
WP_ADMIN_PASSWORD="${config.wordpress.wpPassword || ''}"
WP_BLOG_ID="${config.wordpress.wpBlogId || '1'}"
WP_AUTHOR_ID="${config.wordpress.wpAuthorId || '1'}"
WP_POST_STATUS="${config.wordpress.postStatus || 'publish'}"
WP_MIN_CONTENT_LENGTH="${config.wordpress.minContentLength || '200'}"

# 默认分类和标签
DEFAULT_CATEGORIES=("${(config.wordpress.defaultCategories || '').split(',').map(s => s.trim()).join('" "')}")
DEFAULT_TAGS=("${(config.wordpress.defaultTags || '').split(',').map(s => s.trim()).join('" "')}")

# ==================== 兰空图床配置 ====================
LSKY_BASE_URL="${config.lsky.lskyBaseUrl || ''}"
LSKY_AUTH="Bearer ${config.lsky.lskyAuth || ''}"
LSKY_ALBUM_NAME="${config.lsky.lskyAlbumName || 'ai'}"
LSKY_MAX_IMAGES="${config.lsky.maxImagesPerPost || '2'}"

# ==================== AI 模型配置 ====================
# AI 提供商: ${config.ai.provider || 'siliconflow'}
AI_PROVIDER="${config.ai.provider || 'siliconflow'}"
TITLE_URL="${config.ai.titleUrl || ''}"
AI_MAX_TOKENS="${config.ai.maxTokens || '4000'}"
AI_TEMPERATURE="${config.ai.temperature || '0.7'}"
AI_PROMPT="${(config.ai.prompt || '').replace(/"/g, '\"')}"

`;

        // 根据选择的提供商添加对应的配置
        if (config.ai.provider === 'moonshot' && config.ai.moonshotKey) {
            configContent += `# Moonshot (Kimi) 配置
MOONSHOT_API_KEY="${config.ai.moonshotKey}"
MOONSHOT_API_URL="${config.ai.moonshotUrl || 'https://api.moonshot.cn/v1'}"
MOONSHOT_MODEL="${config.ai.moonshotModel || 'moonshot-v1-128k'}"
`;
        } else if (config.ai.provider === 'deepseek' && config.ai.deepseekKey) {
            configContent += `# DeepSeek 配置
DEEPSEEK_API_KEY="${config.ai.deepseekKey}"
DEEPSEEK_API_URL="${config.ai.deepseekUrl || 'https://api.deepseek.com'}"
DEEPSEEK_MODEL="${config.ai.deepseekModel || 'deepseek-chat'}"
`;
        } else if (config.ai.provider === 'siliconflow' && config.ai.siliconflowKey) {
            configContent += `# SiliconFlow 配置
SILICONFLOW_API_KEY="${config.ai.siliconflowKey}"
SILICONFLOW_API_URL="${config.ai.siliconflowUrl || 'https://api.siliconflow.cn/v1'}"
SILICONFLOW_MODEL="${config.ai.siliconflowModel || 'Pro/deepseek-ai/DeepSeek-R1'}"
`;
        }

        configContent += `
# ==================== 日志设置 ====================
LOG_FILE="${config.general.logFile || '/var/log/wp-auto-maintenance.log'}"
LOG_LEVEL="${config.general.logLevel || 'INFO'}"

# ==================== 特色图片设置 ====================
FEATURED_IMAGE_QUALITY="${config.general.featuredQuality || '95'}"
FEATURED_IMAGE_MIN_SIZE="${config.general.featuredMinSize || '600'}"
FEATURED_IMAGE_SQUARE="${config.general.featuredSquare === 'on' ? 'true' : 'false'}"

# ==================== 计划任务设置 ====================
CRON_ENABLED="${config.general.cronEnabled === 'on' ? 'true' : 'false'}"
CRON_SCHEDULE="${config.general.cronSchedule || '0 9 * * *'}"
CRON_MAX_POSTS="${config.general.maxPostsCron || '3'}"
`;

        return configContent;
    }

    // 生成 Bash 脚本
    generateBashScript(cronOnly = false) {
        const config = this.collectFormData();
        const provider = config.ai.provider || 'siliconflow';

        let scriptContent = `#!/bin/bash
# WordPress 自动发布文章生成脚本
# 生成时间: ${new Date().toLocaleString('zh-CN')}
# AI 提供商: ${provider}

# ========================================
# 执行环境要求:
# - Linux/Unix 系统
# - Bash 4.0+
# - curl
# - python3
# - xmlrpc.client (Python)
# - jq (可选，推荐安装)
# - PIL/Pillow (用于图片处理)
# ========================================

# 配置文件路径
CONFIG_PATH="\${HOME}/wp-auto-config.conf"

# 检查依赖
check_dependencies() {
    echo "检查依赖..."

    local deps_missing=0

    for cmd in curl python3 sed grep awk; do
        if ! command -v \$cmd > /dev/null 2>&1; then
            echo "错误: 缺少命令: \$cmd"
            deps_missing=1
        fi
    done

    python3 -c "import xmlrpc.client" 2>/dev/null || {
        echo "错误: Python xmlrpc.client 库不可用"
        deps_missing=1
    }

    python3 -c "import PIL" 2>/dev/null || {
        echo "警告: Python PIL 库未安装，特色图片功能受限"
        echo "安装命令: pip install Pillow"
    }

    if [[ \$deps_missing -eq 1 ]]; then
        echo "请安装缺失的依赖后重试"
        exit 1
    fi

    echo "✓ 依赖检查通过"
}

# 日志函数
log() {
    local level=\$1
    shift
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] [\\\$level] \$*" | tee -a "${config.general.logFile || '/var/log/wp-auto-maintenance.log'}"
}

# 从标题源获取随机标题
get_random_title() {
    log "INFO" "从标题源获取标题..."

    local title_content=\$(curl -s --max-time 20 "${config.ai.titleUrl || ''}")

    if [ -z "\$title_content" ]; then
        log "WARN" "获取标题失败，使用默认标题"
        echo "医美新时代：自然美与科技的融合"
        return
    fi

    # 转换为数组并随机选择
    local titles=()
    while IFS= read -r line; do
        if [[ -n "\$line" ]]; then
            line=\$(echo "\$line" | sed 's/《//g; s/》//g')
            titles+=("\$line")
        fi
    done <<< "\$title_content"

    if [ \${#titles[@]} -eq 0 ]; then
        echo "医美新时代：自然美与科技的融合"
    else
        local random_index=\$((RANDOM % \${#titles[@]}))
        echo "\${titles[\$random_index]}"
    fi
}

# AI 生成文章内容
generate_article_content() {
    local title="\$1"
    log "INFO" "使用 AI 生成文章内容: \$title"

    local prompt="${(config.ai.prompt || '').replace(/"/g, '\"')}"\n标题: \$title\n内容要求:"

    local api_key=""
    local api_url=""
    local model=""

    case "${provider}" in
        moonshot)
            api_key="${config.ai.moonshotKey || ''}"
            api_url="${config.ai.moonshotUrl || 'https://api.moonshot.cn/v1'}"
            model="${config.ai.moonshotModel || 'moonshot-v1-128k'}" ;;
        deepseek)
            api_key="${config.ai.deepseekKey || ''}"
            api_url="${config.ai.deepseekUrl || 'https://api.deepseek.com'}"
            model="${config.ai.deepseekModel || 'deepseek-chat'}" ;;
        siliconflow)
            api_key="${config.ai.siliconflowKey || ''}"
            api_url="${config.ai.siliconflowUrl || 'https://api.siliconflow.cn/v1'}""\n            model="${config.ai.siliconflowModel || 'Pro/deepseek-ai/DeepSeek-R1'}""\n            ;;
        *)
            log "ERROR" "未知的 AI 提供商: ${provider}"
            return 1 ;;
    esac

    if [ -z "\$api_key" ]; then
        log "ERROR" "未配置 ${provider} 的 API Key"
        return 1
    fi

    local request="\$(cat <<EOF
{
  "model": "\$model",
  "messages": [
    {
      "role": "user",
      "content": "\$prompt"
    }
  ],
  "temperature": ${config.ai.temperature || '0.7'},
  "max_tokens": ${config.ai.maxTokens || '4000'}
}
EOF
)"

    local response=\$(curl -s --max-time 300 \
        -X POST "\$api_url" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer \$api_key" \
        -d "\$request")

    if [ -z "\$response" ]; then
        log "ERROR" "API 请求失败"
        return 1
    fi

    local content
    if command -v jq > /dev/null 2>&1; then
        content=\$(echo "\$response" | jq -r '.choices[0].message.content // empty')
    else
        content=\$(echo "\$response" | grep -o '"content":"[^"]*' | sed 's/"content":"//g' | head -1 | sed 's/\\\\n/\\n/g')
    fi

    if [ -z "\$content" ]; then
        log "ERROR" "无法从响应中提取内容"
        return 1
    fi

    echo "\$content"
}

# 处理生成的文章
process_article() {
    local raw_content="\$1"
    local timestamp=\$(date +%Y%m%d_%H%M%S)

    # 生成标题（使用简单方法）
    local title="AI生成文章_\$timestamp"

    # 提取关键词和分类
    local keywords=\$(echo "\$raw_content" | grep -E "^关键字标签[:：]" | head -n 1 | sed 's/^关键字标签[:：]\\s*//')
    local categories=\$(echo "\$raw_content" | grep -E "^建议分类[:：]" | head -n 1 | sed 's/^建议分类[:：]\\s*//')

    if [ -z "\$categories" ]; then
        categories="技术"
    fi

    # 清理内容
    local content=\$(echo "\$raw_content" | sed '/^关键字标签[:：]/d; /^建议分类[:：]/d')

    # 保存到临时文件
    local temp_file="/tmp/wp_article_\$timestamp.md"
    echo "\$content" > "\$temp_file"

    # 插入图片
    insert_images "\$temp_file" "\$categories"

    echo "TITLE:\$title"
    echo "CATEGORIES:\$categories"
    echo "KEYWORDS:\$keywords"
    echo "FILE:\$temp_file"
}

# 从兰空图床获取图片
get_lsky_images() {
    local album_name="${config.lsky.lskyAlbumName || 'ai'}"
    local max_images=${config.lsky.maxImagesPerPost || '2'}

    log "INFO" "从兰空图床获取图片，相册: \$album_name"

    # 获取相册ID
    local album_response=\$(curl -s ${config.lsky.lskyAuth} -H "Accept: application/json" \
        "${config.lsky.lskyBaseUrl}/albums?page=1&limit=100")

    local album_id=\$(echo "\$album_response" | jq -r ".data.data[] | select(.name==\"\$album_name\") | .id")

    if [ -z "\$album_id" ] || [ "\$album_id" == "null" ]; then
        log "WARN" "未找到相册 '\$album_name'"
        return 1
    fi

    log "INFO" "找到相册 '\$album_name' (ID: \$album_id)"

    # 获取图片
    local page=1
    local images=""
    while true; do
        local page_response=\$(curl -s ${config.lsky.lskyAuth} -H "Accept: application/json" \
            "${config.lsky.lskyBaseUrl}/images?album_id=\$album_id&page=\$page&limit=100")

        local new_links=\$(echo "\$page_response" | jq -r '.data.data[].links.url')

        if [ -z "\$new_links" ]; then
            break
        fi

        images="\${images}\${new_links}"

        local count=\$(echo "\$images" | grep -c '^')
        if [ \$count -ge 500 ]; then
            break
        fi

        page=\$((page + 1))
    done

    # 随机选择图片
    echo "\$images" | shuf -n \$max_images
    return 0
}

# 插入图片到内容
insert_images() {
    local file="\$1"
    local category="\$2"

    local images=\$(get_lsky_images)
    if [ -z "\$images" ]; then
        log "WARN" "未获取到图片，跳过图片插入"
        return 0
    fi

    local content=\$(cat "\$file")
    local image_markdown=""

    local count=0
    for img_url in \$images; do
        if [ -n "\$img_url" ]; then
            image_markdown="\${image_markdown}![](\$img_url)\n\n"
            count=\$((count + 1))
        fi
    done

    # 在内容前后插入图片
    content="\${image_markdown}\${content}"
    echo "\$content" > "\$file"

    log "INFO" "在文章中插入了 \$count 张图片"
}

# 设置特色图片
set_featured_image() {
    local post_id="\$1"
    local title="\$2"

    log "INFO" "为文章 '\$title' (ID: \$post_id) 设置特色图片"

    python3 <<EOF
import sys
try:
    import requests
    from PIL import Image
    from io import BytesIO
except ImportError as e:
    print(f"缺少必要的Python库: {e}")
    sys.exit(1)

try:
    # 获取图片
    import xmlrpc.client
    wp = xmlrpc.client.ServerProxy("${config.wordpress.wpXmlrpc}")
    wp_username = "${config.wordpress.wpUsername}"
    wp_password = "${config.wordpress.wpPassword}"
    blog_id = ${config.wordpress.wpBlogId}

    # 从兰空图床获取随机图片
    import subprocess
    result = subprocess.run(['bash', '-c', 'get_lsky_images'], capture_output=True, text=True)
    if result.returncode != 0:
        print("获取图片失败")
        sys.exit(1)

    img_url = result.stdout.strip().split('\n')[0]

    # 下载图片
    response = requests.get(img_url)
    img = Image.open(BytesIO(response.content))

    # 裁剪为方形
    crop_size = min(img.size)
    img = img.crop(((img.width - crop_size) // 2, (img.height - crop_size) // 2,
                   (img.width + crop_size) // 2, (img.height + crop_size) // 2))

    # 保存临时文件
    temp_file = f"/tmp/featured_\$1.jpg"
    img.save(temp_file, quality=${config.general.featuredQuality || '95'})

    # 上传并设置为特色图片
    with open(temp_file, 'rb') as f:
        data = xmlrpc.client.Binary(f.read())

    upload = wp.wordpress.uploadFile(blog_id, wp_username, wp_password, {
        'name': f'featured_{\$1}.jpg',
        'type': 'image/jpeg',
        'bits': data,
        'overwrite': True
    })

    wp.wp.editPost(blog_id, wp_username, wp_password, \$1, {
        'post_thumbnail': upload['id']
    })

    print("特色图片设置成功")

except Exception as e:
    print(f"设置特色图片失败: {e}")
    sys.exit(1)
EOF

    if [ \$? -eq 0 ]; then
        log "INFO" "特色图片设置成功"
        return 0
    else
        log "ERROR" "特色图片设置失败"
        return 1
    fi
}

# 使用 REST API 发布文章（替代方法）
wp_publish_with_rest_api() {
    local title="\$1"
    local content="\$2"
    local categories="\$3"
    local keywords="\$4"

    log "INFO" "使用 REST API 发布文章: \$title"

    # 需要 JWT 认证或应用密码
    local auth="\${WP_ADMIN_USER}:\${WP_ADMIN_PASSWORD}"

    local payload="\$(cat <<EOF
{
    "title": "\$title",
    "content": "\$content",
    "status": "\${WP_POST_STATUS}",
    "categories": ["\${categories}"],
    "tags": "\${keywords}"
}
EOF
)"

    local response=\$(curl -s -X POST "\${WP_SITE_URL}/wp-json/wp/v2/posts" \
        -u "\$auth" \
        -H "Content-Type: application/json" \
        -d "\$payload")

    if echo "\$response" | grep -q '"id"'; then
        local post_id=\$(echo "\$response" | jq -r '.id')
        log "SUCCESS" "文章发布成功，ID: \$post_id"
        return 0
    else
        log "ERROR" "发布失败: \$response"
        return 1
    fi
}

# 发布单篇文章
publish_single_article() {
    local title="\$1"

    if [ -z "\$title" ]; then
        title=\$(get_random_title)
    fi

    log "INFO" "生成文章: \$title"

    # 生成内容
    local raw_content=\$(generate_article_content "\$title")
    if [ -z "\$raw_content" ]; then
        log "ERROR" "内容生成失败"
        return 1
    fi

    # 处理文章
    local result=\$(process_article "\$raw_content")
    local article_title=\$(echo "\$result" | grep "^TITLE:" | cut -d: -f2-)
    local categories=\$(echo "\$result" | grep "^CATEGORIES:" | cut -d: -f2-)
    local keywords=\$(echo "\$result" | grep "^KEYWORDS:" | cut -d: -f2-)
    local article_file=\$(echo "\$result" | grep "^FILE:" | cut -d: -f2-)

    # 读取内容
    local content=\$(cat "\$article_file")

    # 发布文章
    if wp_publish_with_rest_api "\$article_title" "\$content" "\$categories" "\$keywords"; then
        log "SUCCESS" "文章发布完成"

        # 为特色图片延迟1秒
        sleep 1

        # 获取刚发布的文章ID并设置特色图片
        log "INFO" "正在设置特色图片..."
        set_featured_image \$(wp_last_post_id) "\$article_title"

        # 删除临时文件
        rm -f "\$article_file"

        return 0
    else
        log "ERROR" "文章发布失败"
        rm -f "\$article_file"
        return 1
    fi
}

# 获取最新文章ID
wp_last_post_id() {
    python3 <<EOF
import xmlrpc.client
try:
    wp = xmlrpc.client.ServerProxy("${config.wordpress.wpXmlrpc}")
    posts = wp.wp.getPosts(${config.wordpress.wpBlogId}, "${config.wordpress.wpUsername}", "${config.wordpress.wpPassword}", {'number': 1})
    print(posts[0]['post_id'] if posts else '', end='')
except:
    print('', end='')
EOF
}

# 批量发布文章
batch_publish() {
    local count="\$1"

    log "INFO" "开始批量发布 \$count 篇文章"

    local success=0
    local failed=0

    for ((i=1; i<=count; i++)); do
        log "INFO" "发布第 \$i/\$count 篇文章"

        if publish_single_article; then
            ((success++))
        else
            ((failed++))
        fi

        if [ \$i -lt \$count ]; then
            log "INFO" "等待 5 秒后发布下一篇..."
            sleep 5
        fi
    done

    log "INFO" "批量发布完成 - 成功: \$success, 失败: \$failed"
}

# 显示帮助
show_help() {
    cat <<EOF
WordPress 自动发布文章脚本

使用方法:
    $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -n, --number N      批量发布 N 篇文章 (默认: 1)
    -t, --title TITLE   使用指定标题生成文章
    --dry-run           试运行，不实际发布
    --set-featured      为所有文章设置特色图片

示例:
    $0                  # 发布单篇文章
    $0 -n 3             # 批量发布 3 篇文章
    $0 -t "医美新趋势"  # 使用指定标题
    $0 --dry-run        # 测试运行
    $0 --set-featured   # 为所有文章设置特色图片

配置文件:
    ~/.wp-auto-config.conf

日志文件:
    ${config.general.logFile || '/var/log/wp-auto-maintenance.log'}

EOF
}

# 主函数
main() {
    # 检查并创建配置文件
    if [ ! -f "\$CONFIG_PATH" ]; then
        echo "错误: 配置文件不存在"
        echo "请使用 Web 界面生成配置文件并保存到: \$CONFIG_PATH"
        echo "或者手动创建配置文件"
        exit 1
    fi

    # 加载配置
    source "\$CONFIG_PATH"

    # 检查依赖
    check_dependencies

    local count=1
    local dry_run=false
    local featured_only=false
    local custom_title=""

    # 解析参数
    while [[ \$# -gt 0 ]]; do
        case \$1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--number)
                count="\$2"
                shift 2
                ;;
            -t|--title)
                custom_title="\$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                log "INFO" "DRY RUN 模式，不实际发布"
                shift
                ;;
            --set-featured)
                featured_only=true
                log "INFO" "特色图片更新模式"
                shift
                ;;
            *)
                echo "未知选项: \$1"
                exit 1
                ;;
        esac
    done

    # 执行操作
    if [ "\$featured_only" = true ]; then
        # 为所有文章设置特色图片
        echo "功能开发中，敬请期待..."
    elif [ "\$dry_run" = true ]; then
        # 测试运行
        log "INFO" "测试文章生成流程..."
        title=\$(get_random_title)
        log "INFO" "标题: \$title"

        content=\$(generate_article_content "\$title")
        if [ -n "\$content" ]; then
            log "SUCCESS" "文章生成测试成功"
            echo "文章预览（前200字）:"
            echo "\$content" | head -c 200
            echo "..."
        else
            log "ERROR" "文章生成测试失败"
            exit 1
        fi
    elif [ -n "\$custom_title" ]; then
        # 使用指定标题
        publish_single_article "\$custom_title"
    else
        # 批量发布
        batch_publish \$count
    fi
}

# 执行主函数
main "$@"
`;

        return scriptContent;
    }

    // 点击生成 Bash 脚本
    generateBashScript() {
        const config = this.collectFormData();

        // 验证必填项
        if (!config.wordpress || !config.wordpress.wpUrl || !config.wordpress.wpPassword) {
            this.showMessage('请填写完整的 WordPress 配置', 'error');
            this.switchTab('wordpress');
            return;
        }

        if (!config.lsky || !config.lsky.lskyBaseUrl || !config.lsky.lskyAuth) {
            this.showMessage('请填写完整的兰空图床配置', 'error');
            this.switchTab('lsky');
            return;
        }

        if (!config.ai || !config.ai.titleUrl) {
            this.showMessage('请填写标题源 URL', 'error');
            this.switchTab('ai');
            return;
        }

        // 生成配置
        const configContent = this.generateConfig();
        document.getElementById('config-output').value = configContent;

        // 生成 Bash 脚本
        const bashContent = this.generateBashScript();
        document.getElementById('bash-output').value = bashContent;

        this.showMessage('脚本已生成！请将其保存到 ~/.wp-auto-config.conf 并执行', 'success');
    }

    // 测试配置
    testConfig() {
        const config = this.collectFormData();

        // 简单验证
        if (!config.ai || !config.ai.titleUrl) {
            this.showMessage('请填写标题源 URL', 'error');
            return;
        }

        this.showMessage('测试连接功能开发中...', 'info');
    }

    // 下载文件
    downloadFile(filename, content) {
        const blob = new Blob([content], { type: 'text/plain' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);

        this.showMessage(`已下载: ${filename}`, 'success');
    }

    // 复制到剪贴板
    copyToClipboard(elementId, name) {
        const element = document.getElementById(elementId);
        element.select();
        document.execCommand('copy');
        this.showMessage(`${name}已复制到剪贴板！`, 'success');
    }

    // 显示消息
    showMessage(message, type = 'info') {
        // 清除旧的消息
        const oldMessages = document.querySelectorAll('.message');
        oldMessages.forEach(msg => msg.remove());

        // 创建新消息
        const messageEl = document.createElement('div');
        messageEl.className = `message ${type}`;
        messageEl.textContent = message;

        // 插入到页面顶部
        const mainPage = document.getElementById('main-page');
        mainPage.insertBefore(messageEl, mainPage.firstChild);

        // 3秒后自动移除
        setTimeout(() => {
            if (messageEl.parentNode) {
                messageEl.parentNode.removeChild(messageEl);
            }
        }, 3000);
    }
}

// 初始化应用
document.addEventListener('DOMContentLoaded', () => {
    window.wpManager = new WPAutoManager();
});
