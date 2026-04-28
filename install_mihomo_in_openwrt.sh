#!/bin/sh

REPO="MetaCubeX/mihomo"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
INSTALL_PATH="/usr/bin/mihomo"
SERVICE_PATH="/etc/init.d/mihomo"
CONFIG_DIR="/etc/mihomo"
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

get_installed_version() {
    if [ ! -x "$INSTALL_PATH" ]; then
        return 1
    fi

    "$INSTALL_PATH" -v 2>/dev/null \
        | grep -Eo 'v[0-9]+(\.[0-9]+)+' \
        | head -n 1
}

stop_running_instances() {
    log "检测到新版本，正在停止运行中的 Mihomo..."

    if [ -x "$SERVICE_PATH" ]; then
        "$SERVICE_PATH" stop 2>/dev/null || true
    fi

    killall mihomo 2>/dev/null || true
}

write_service_file() {
    cat <<'EOF' > /etc/init.d/mihomo
#!/bin/sh /etc/rc.common

USE_PROCD=1
START=99
STOP=01

start_service() {
    if [ ! -f "/etc/mihomo/config.yaml" ]; then
        echo "Mihomo 配置文件 /etc/mihomo/config.yaml 不存在。" >&2
        return 1
    fi

    procd_open_instance "mihomo"
    procd_set_param command /usr/bin/mihomo -d /etc/mihomo
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

reload_service() {
    stop
    start
}
EOF
}

print_proxy_status

MIHOMO_ARCH="$(detect_arch)"
LATEST_VERSION="$(fetch_latest_version)"
CURRENT_VERSION="$(get_installed_version || true)"

log "检测到的架构: ${MIHOMO_ARCH}"
log "最新版本: ${LATEST_VERSION}"

if [ -n "$CURRENT_VERSION" ]; then
    log "当前已安装版本: ${CURRENT_VERSION}"
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        log "当前已经是最新版本，无需升级。"
        exit 0
    fi

    stop_running_instances
else
    log "当前未检测到已安装的 Mihomo，开始安装。"
fi

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_VERSION}/mihomo-linux-${MIHOMO_ARCH}-${LATEST_VERSION}.gz"

log "正在下载: ${DOWNLOAD_URL}"
wget -O "$TMP_ARCHIVE" "$DOWNLOAD_URL" || die "下载失败。请检查网络连通性或代理是否可用。"

log "正在解压安装包..."
gzip -d -f "$TMP_ARCHIVE" || die "解压 ${TMP_ARCHIVE} 失败。"

mv "$TMP_BINARY" "$INSTALL_PATH" || die "安装 ${INSTALL_PATH} 失败。"
chmod +x "$INSTALL_PATH" || die "设置 ${INSTALL_PATH} 可执行权限失败。"
log "已安装到 ${INSTALL_PATH}"

mkdir -p "$CONFIG_DIR" || die "创建 ${CONFIG_DIR} 目录失败。"

write_service_file
chmod +x "$SERVICE_PATH" || die "设置 ${SERVICE_PATH} 可执行权限失败。"
"$SERVICE_PATH" enable || die "启用 mihomo 开机启动失败。"

log "------------------------------------------------------"
log "部署完成。"
log "当前安装版本: ${LATEST_VERSION}"
log "请确认 ${CONFIG_DIR}/config.yaml 已存在，然后执行:"
log "${SERVICE_PATH} restart"
log "------------------------------------------------------"
