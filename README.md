# OpenWrt Mihomo (Clash Meta) 脚本集

本仓库包含用于在 OpenWrt 设备上部署和运行 **Mihomo (原 Clash Meta)** 的 Shell 脚本。

## 脚本列表

### 1. `install_mihomo_in_openwrt.sh`
*   **功能**：在 OpenWrt 上永久安装 Mihomo 二进制程序，配置并启用开机启动自启服务 (`/etc/init.d/mihomo`)。
*   **安装路径**：`/usr/bin/mihomo`
*   **服务路径**：`/etc/init.d/mihomo`
*   **配置文件**：`/etc/mihomo/config.yaml`
*   **使用方式**：
    ```sh
    # 下载并运行安装脚本
    sh install_mihomo_in_openwrt.sh
    
    # 放置好配置文件后，启动服务
    /etc/init.d/mihomo start
    ```

### 2. `run_mihomo_in_openwrt.sh`
*   **功能**：**免安装模式**。不向 OpenWrt 的硬盘/闪存永久写入二进制程序。每次运行脚本时，会自动从网络下载最新版 Mihomo 二进制到 `/tmp` (内存) 并直接前台运行。配置文件仍保存在本地以方便持久化。退出后，二进制文件会保留在 `/tmp` 中以便下次快速使用或手动清理。
*   **镜像加速**：下载时会自动检测 `https://fast.digiplanetss.dpdns.org` 镜像，若可用则通过镜像加速下载，若失败或不可用则自动回退到 GitHub 直连下载。
*   **二进制路径**：`/tmp/mihomo`
*   **配置文件**：`/etc/mihomo/config.yaml`
*   **使用方式**：
    ```sh
    # 确保本地已创建好配置文件 /etc/mihomo/config.yaml，然后运行：
    sh run_mihomo_in_openwrt.sh
    ```

### 3. `uninstall_mihomo_in_openwrt.sh`
*   **功能**：完全卸载通过 `install_mihomo_in_openwrt.sh` 安装的 Mihomo，包括清理开机自启服务、删除二进制程序、可选清理 `/etc/mihomo` 配置文件目录及清理 `/tmp` 临时文件。
*   **使用方式**：
    ```sh
    sh uninstall_mihomo_in_openwrt.sh
    ```

---

## 配置文件准备

在启动 Mihomo 之前，请确保已在 OpenWrt 上建好配置目录并填入合法的 Clash 配置文件：
```sh
mkdir -p /etc/mihomo
# 编辑或上传您的 config.yaml 至 /etc/mihomo/config.yaml
vi /etc/mihomo/config.yaml
```

## GitHub API 速率限制说明
如果因为频繁请求触发 GitHub API 限制导致无法获取最新 tag，可以在运行脚本前设置 `GITHUB_TOKEN` 或 `GH_TOKEN` 环境变量：
```sh
export GITHUB_TOKEN="your_github_pat_token"
sh run_mihomo_in_openwrt.sh
```
