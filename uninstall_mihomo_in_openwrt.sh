#!/bin/sh

INSTALL_PATH="/usr/bin/mihomo"
SERVICE_PATH="/etc/init.d/mihomo"
CONFIG_DIR="/etc/mihomo"

log() {
    echo "$@"
}

die() {
    echo "错误: $@" >&2
    exit 1
}

confirm_removal() {
    printf "确定要卸载 Mihomo 吗？(y/N) "
    read -r answer
    case "$answer" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) log "已取消卸载。"; exit 0 ;;
    esac
}

# ── 主流程 ──────────────────────────────────────────────

confirm_removal

# 1. 停止服务并禁用开机启动
if [ -x "$SERVICE_PATH" ]; then
    log "正在停止 Mihomo 服务..."
    "$SERVICE_PATH" stop 2>/dev/null || true

    log "正在禁用开机启动..."
    "$SERVICE_PATH" disable 2>/dev/null || true
else
    log "未检测到 init.d 服务文件，跳过服务管理。"
fi

# 确保所有残留进程都已终止
killall mihomo 2>/dev/null || true

# 2. 删除 init.d 服务文件
if [ -f "$SERVICE_PATH" ]; then
    log "正在删除服务文件: ${SERVICE_PATH}"
    rm -f "$SERVICE_PATH" || die "删除 ${SERVICE_PATH} 失败。"
fi

# 3. 删除二进制文件
if [ -f "$INSTALL_PATH" ]; then
    log "正在删除二进制文件: ${INSTALL_PATH}"
    rm -f "$INSTALL_PATH" || die "删除 ${INSTALL_PATH} 失败。"
fi

# 4. 可选：删除配置目录
if [ -d "$CONFIG_DIR" ]; then
    printf "是否同时删除配置目录 ${CONFIG_DIR}？(y/N) "
    read -r remove_config
    case "$remove_config" in
        [Yy]|[Yy][Ee][Ss])
            log "正在删除配置目录: ${CONFIG_DIR}"
            rm -rf "$CONFIG_DIR" || die "删除 ${CONFIG_DIR} 失败。"
            ;;
        *)
            log "已保留配置目录: ${CONFIG_DIR}"
            ;;
    esac
fi

# 5. 清理可能残留的临时文件
rm -f /tmp/mihomo /tmp/mihomo.gz 2>/dev/null

log "------------------------------------------------------"
log "Mihomo 卸载完成。"
log "------------------------------------------------------"
