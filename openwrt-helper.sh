#!/bin/bash
# OpenWrt一键管理脚本
# 使用方法: bash <(curl -L -s https://raw.githubusercontent.com/用户名/仓库名/main/openwrt-helper.sh)

set -e

# 脚本信息
SCRIPT_NAME="OpenWrt One-Click Helper"
VERSION="1.0"
GITHUB_URL="https://github.com/你的用户名/openwrt-helper"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# 检查系统
check_system() {
    if ! grep -qi "openwrt" /etc/os-release 2>/dev/null && ! grep -qi "openwrt" /etc/openwrt_release 2>/dev/null; then
        error "这似乎不是OpenWrt系统！"
        exit 1
    fi
    
    if [ "$(id -u)" -ne 0 ]; then
        error "请使用root权限运行此脚本！"
        exit 1
    fi
}

# 显示横幅
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "   ___                      _    _           _     "
    echo "  / _ \ _ __   ___ _ __    / \  | |_ _ __ __| |___ "
    echo " | | | | '_ \ / _ \ '_ \  / _ \ | __| '__/ _' / __|"
    echo " | |_| | |_) |  __/ | | |/ ___ \| |_| | | (_| \__ \\"
    echo "  \___/| .__/ \___|_| |_/_/   \_|\__|_|  \__,_|___/"
    echo "       |_|                                         "
    echo -e "${NC}"
    echo -e "${CYAN}        $SCRIPT_NAME v$VERSION${NC}"
    echo -e "${CYAN}        GitHub: $GITHUB_URL${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo
}

# 主菜单
show_menu() {
    echo -e "${GREEN}请选择功能:${NC}"
    echo "1.  📊 系统信息总览"
    echo "2.  🌐 网络状态检查"
    echo "3.  📶 无线网络管理"
    echo "4.  🔥 防火墙状态"
    echo "5.  📦 软件包管理"
    echo "6.  💾 磁盘空间检查"
    echo "7.  🚀 网络速度测试"
    echo "8.  ⚙️  系统服务管理"
    echo "9.  📋 系统日志查看"
    echo "10. 🔄 重启网络服务"
    echo "11. 💾 备份系统配置"
    echo "12. 🛠️  高级工具"
    echo "13. 🔄 更新脚本"
    echo "14. ❌ 重启系统"
    echo "0.  🚪 退出脚本"
    echo -e "${BLUE}=================================================${NC}"
}

# 系统信息总览
system_overview() {
    log "正在获取系统信息..."
    echo
    echo -e "${CYAN}=== 系统基本信息 ===${NC}"
    cat /etc/openwrt_release 2>/dev/null || echo "无法获取系统版本"
    echo
    echo -e "${CYAN}=== 内核信息 ===${NC}"
    uname -a
    echo
    echo -e "${CYAN}=== 运行时间 ===${NC}"
    uptime
    echo
    echo -e "${CYAN}=== CPU信息 ===${NC}"
    grep -E "processor|model name|cpu MHz" /proc/cpuinfo 2>/dev/null | head -6
    echo
    echo -e "${CYAN}=== 内存使用 ===${NC}"
    free -h || cat /proc/meminfo | head -4
    echo
    echo -e "${CYAN}=== 磁盘使用 ===${NC}"
    df -h
    echo
    echo -e "${CYAN}=== 负载情况 ===${NC}"
    cat /proc/loadavg 2>/dev/null || echo "无法获取负载信息"
}

# 网络状态检查
network_check() {
    log "正在检查网络状态..."
    echo
    echo -e "${CYAN}=== 网络接口 ===${NC}"
    if command -v ip >/dev/null 2>&1; then
        ip addr show
    else
        ifconfig
    fi
    echo
    echo -e "${CYAN}=== 路由表 ===${NC}"
    route -n
    echo
    echo -e "${CYAN}=== 网络连接 ===${NC}"
    netstat -tunlp 2>/dev/null || ss -tunlp 2>/dev/null || echo "网络工具不可用"
}

# 软件包管理
package_manager() {
    echo
    echo -e "${CYAN}=== 软件包管理 ===${NC}"
    echo "1. 查看已安装包"
    echo "2. 更新软件包列表"
    echo "3. 安装软件包"
    echo "4. 卸载软件包"
    echo "5. 搜索软件包"
    echo -n "请选择: "
    read choice
    
    case $choice in
        1) opkg list-installed | head -30 ;;
        2) opkg update ;;
        3)
            echo -n "输入要安装的包名: "
            read pkg
            opkg install "$pkg"
            ;;
        4)
            echo -n "输入要卸载的包名: "
            read pkg
            opkg remove "$pkg"
            ;;
        5)
            echo -n "输入搜索关键词: "
            read keyword
            opkg list | grep -i "$keyword" | head -10
            ;;
        *) warn "无效选择" ;;
    esac
}

# 网络速度测试
speed_test() {
    log "正在进行网络速度测试..."
    echo
    echo -e "${YELLOW}注意: 这会消耗少量流量${NC}"
    echo
    echo -e "${CYAN}=== Ping测试 ===${NC}"
    ping -c 3 8.8.8.8
    echo
    echo -e "${CYAN}=== 下载速度测试 ===${NC}"
    if command -v wget >/dev/null 2>&1; then
        time wget -O /dev/null http://speedtest.tele2.net/1MB.zip 2>&1 | grep -oP '([0-9.]+ [KM]B/s)'
    else
        warn "wget不可用，跳过下载测试"
    fi
}

# 系统服务管理
service_manager() {
    echo
    echo -e "${CYAN}=== 系统服务管理 ===${NC}"
    echo "运行的服务:"
    /etc/init.d/* enabled 2>/dev/null | head -10
    echo
    echo "1. 重启网络服务"
    echo "2. 重启防火墙"
    echo "3. 查看所有服务"
    echo -n "请选择: "
    read choice
    
    case $choice in
        1) 
            log "重启网络服务..."
            /etc/init.d/network restart
            ;;
        2)
            log "重启防火墙..."
            /etc/init.d/firewall restart
            ;;
        3)
            echo "所有服务状态:"
            /etc/init.d/* status 2>/dev/null
            ;;
        *) warn "无效选择" ;;
    esac
}

# 备份系统配置
backup_config() {
    log "正在备份系统配置..."
    BACKUP_FILE="/tmp/openwrt_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    if command -v sysupgrade >/dev/null 2>&1; then
        sysupgrade -b "$BACKUP_FILE"
        if [ $? -eq 0 ]; then
            log "备份成功: $BACKUP_FILE"
        else
            error "备份失败"
        fi
    else
        error "sysupgrade命令不可用"
    fi
}

# 高级工具
advanced_tools() {
    echo
    echo -e "${CYAN}=== 高级工具 ===${NC}"
    echo "1. 查看UCI配置"
    echo "2. 查看内核模块"
    echo "3. 查看启动项"
    echo "4. 测试磁盘IO"
    echo -n "请选择: "
    read choice
    
    case $choice in
        1) uci show 2>/dev/null | head -30 ;;
        2) lsmod | head -20 ;;
        3) ls -la /etc/rc.d/ ;;
        4)
            if command -v dd >/dev/null 2>&1; then
                log "测试磁盘写入速度..."
                dd if=/dev/zero of=/tmp/test.io bs=1M count=16 2>&1 | tail -1
                rm -f /tmp/test.io
            else
                error "dd命令不可用"
            fi
            ;;
        *) warn "无效选择" ;;
    esac
}

# 更新脚本
update_script() {
    warn "此功能需要配置GitHub仓库URL"
    info "请在脚本中设置GITHUB_URL变量"
}

# 重启系统
reboot_system() {
    warn "即将重启系统！"
    read -p "确认重启？[y/N]: " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "系统将在5秒后重启..."
        sleep 5
        reboot
    else
        log "取消重启"
    fi
}

# 等待用户输入
wait_for_enter() {
    echo
    read -p "按回车键继续..."
}

# 主函数
main() {
    check_system
    
    while true; do
        show_banner
        show_menu
        echo -n "请选择操作 [0-14]: "
        read choice
        
        case $choice in
            1) system_overview ;;
            2) network_check ;;
            3) 
                log "无线网络信息:"
                iwinfo 2>/dev/null || warn "无线工具不可用"
                ;;
            4)
                log "防火墙状态:"
                iptables -L -n 2>/dev/null || warn "iptables不可用"
                ;;
            5) package_manager ;;
            6) 
                log "磁盘空间:"
                df -h
                ;;
            7) speed_test ;;
            8) service_manager ;;
            9)
                log "系统日志:"
                logread | tail -20
                ;;
            10)
                log "重启网络服务..."
                /etc/init.d/network restart
                ;;
            11) backup_config ;;
            12) advanced_tools ;;
            13) update_script ;;
            14) reboot_system ;;
            0)
                log "感谢使用！"
                exit 0
                ;;
            *)
                error "无效选择，请重新输入"
                sleep 2
                continue
                ;;
        esac
        
        wait_for_enter
    done
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
