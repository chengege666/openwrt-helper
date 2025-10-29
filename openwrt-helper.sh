#!/bin/sh
# OpenWrt Helper 安装脚本

set -e

GITHUB_URL="https://raw.githubusercontent.com/你的用户名/openwrt-helper/main"
SCRIPT_NAME="openwrt-helper"
INSTALL_PATH="/usr/local/bin"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查root权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
}

# 下载文件
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    else
        log_error "需要 wget 或 curl，请先安装其中一个"
        exit 1
    fi
}

# 安装主脚本
install_script() {
    log_info "正在下载 OpenWrt Helper..."
    
    # 创建安装目录
    mkdir -p "$INSTALL_PATH"
    
    # 下载主脚本
    download_file "${GITHUB_URL}/openwrt-helper.sh" "${INSTALL_PATH}/${SCRIPT_NAME}"
    
    # 设置执行权限
    chmod +x "${INSTALL_PATH}/${SCRIPT_NAME}"
    
    # 创建符号链接
    if [ ! -L "/usr/bin/${SCRIPT_NAME}" ]; then
        ln -sf "${INSTALL_PATH}/${SCRIPT_NAME}" "/usr/bin/${SCRIPT_NAME}"
    fi
}

# 验证安装
verify_installation() {
    if command -v "$SCRIPT_NAME" >/dev/null 2>&1; then
        log_info "安装成功！"
        echo
        log_info "使用方法:"
        echo "  $SCRIPT_NAME          # 运行脚本"
        echo "  openwrt-helper        # 同上"
        echo
        log_info "现在可以运行: $SCRIPT_NAME"
    else
        log_error "安装失败"
        exit 1
    fi
}

# 主函数
main() {
    echo
    echo "========================================"
    echo "    OpenWrt Helper 安装程序"
    echo "========================================"
    echo
    
    check_root
    install_script
    verify_installation
}

main "$@"
