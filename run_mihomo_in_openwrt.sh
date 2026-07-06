#!/bin/sh

# 每次从 GitHub 下载 mihomo 二进制到 /tmp 并直接运行，不安装到硬盘。
# 配置文件固定存放在 /etc/mihomo/config.yaml。

REPO="MetaCubeX/mihomo"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
CONFIG_DIR="/etc/mihomo"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
TMP_ARCHIVE="/tmp/mihomo.gz"
TMP_BINARY="/tmp/mihomo"

log() {
    echo "$@"
}

die() {
    echo "错误: $@" >&2
    exit 1
}

print_proxy_status() {
    log "检查代理环境..."
    log "http_proxy=${http_proxy:-<未设置>}"
    log "HTTP_PROXY=${HTTP_PROXY:-<未设置>}"
    log "https_proxy=${https_proxy:-<未设置>}"
    log "HTTPS_PROXY=${HTTPS_PROXY:-<未设置>}"
}

detect_arch() {
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l)  echo "armv7" ;;
        *)
            die "不支持的架构: ${arch}。请在脚本中补充 MIHOMO_ARCH 映射。"
            ;;
    esac
}

github_token() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        printf '%s\n' "$GITHUB_TOKEN"
        return 0
    fi

    if [ -n "${GH_TOKEN:-}" ]; then
        printf '%s\n' "$GH_TOKEN"
        return 0
    fi

    return 1
}

fetch_url_without_proxy() {
    url="$1"
    token="$(github_token 2>/dev/null || true)"

    if [ -n "$token" ]; then
        wget --no-proxy -qO- --header="Authorization: Bearer ${token}" "$url"
    else
        wget --no-proxy -qO- "$url"
    fi
}

fetch_latest_version() {
    api_body="/tmp/mihomo-release-api.$$"

    if ! fetch_url_without_proxy "$API_URL" > "$api_body"; then
        rm -f "$api_body"
        die "请求 GitHub API 失败。"
    fi

    version="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$api_body" | head -n 1)"
    if [ -n "$version" ]; then
        rm -f "$api_body"
        printf '%s\n' "$version"
        return 0
    fi

    if grep -Eiq 'rate limit|secondary rate limit|abuse|temporarily blocked|forbidden' "$api_body"; then
        rm -f "$api_body"
        die "当前 IP 已被 GitHub API 限流。"
    fi

    rm -f "$api_body"
    die "GitHub API 返回结果中没有 tag_name。"
}

stop_running_instances() {
    log "正在停止运行中的 Mihomo 进程..."
    killall mihomo 2>/dev/null || true
    sleep 1
}

download_binary() {
    MIHOMO_ARCH="$(detect_arch)"
    LATEST_VERSION="$(fetch_latest_version)"

    log "检测到的架构: ${MIHOMO_ARCH}"
    log "最新版本: ${LATEST_VERSION}"

    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_VERSION}/mihomo-linux-${MIHOMO_ARCH}-${LATEST_VERSION}.gz"

    MIRROR_BASE="https://fast.digiplanetss.dpdns.org"
    MIRROR_URL=""
    log "正在检测加速镜像 ${MIRROR_BASE} 是否可用..."
    if wget --spider -q -T 5 "${MIRROR_BASE}/" 2>/dev/null; then
        MIRROR_URL="${MIRROR_BASE}/${DOWNLOAD_URL}"
        log "加速镜像可用，优先使用镜像下载。"
    else
        log "加速镜像不可用，使用 GitHub 直连下载。"
    fi

    if [ -n "$MIRROR_URL" ]; then
        log "正在下载: ${MIRROR_URL}"
        if ! wget -O "$TMP_ARCHIVE" "$MIRROR_URL"; then
            log "镜像下载失败，回退到 GitHub 直连下载..."
            rm -f "$TMP_ARCHIVE"
            wget -O "$TMP_ARCHIVE" "$DOWNLOAD_URL" || die "下载失败。请检查网络连通性或代理是否可用。"
        fi
    else
        log "正在下载: ${DOWNLOAD_URL}"
        wget -O "$TMP_ARCHIVE" "$DOWNLOAD_URL" || die "下载失败。请检查网络连通性或代理是否可用。"
    fi

    log "正在解压..."
    gzip -d -f "$TMP_ARCHIVE" || die "解压 ${TMP_ARCHIVE} 失败。"

    chmod +x "$TMP_BINARY" || die "设置 ${TMP_BINARY} 可执行权限失败。"

    log "二进制文件已准备就绪: ${TMP_BINARY}"
}

# ===================== 主逻辑 =====================

print_proxy_status

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    die "配置文件 ${CONFIG_FILE} 不存在。请先创建配置文件。"
fi

mkdir -p "$CONFIG_DIR" 2>/dev/null || true

# 停止已有实例
stop_running_instances

# 下载二进制
download_binary

log "------------------------------------------------------"
log "正在启动 Mihomo (前台模式)..."
log "配置目录: ${CONFIG_DIR}"
log "二进制路径: ${TMP_BINARY}"
log "按 Ctrl+C 停止"
log "------------------------------------------------------"

exec "$TMP_BINARY" -d "$CONFIG_DIR"
