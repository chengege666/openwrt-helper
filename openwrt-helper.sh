#!/bin/sh
SCRIPT_VERSION="1.0"
SCRIPT_NAME="OpenWrt Commands Helper"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_menu() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
    echo -e "${BLUE}================================${NC}"
    echo "1. 系统信息查看"
    echo "2. 网络接口状态" 
    echo "3. 无线网络状态"
    echo "4. 进程和内存状态"
    echo "5. 磁盘空间检查"
    echo "6. 软件包管理"
    echo "7. 网络连接测试"
    echo "8. 系统服务管理"
    echo "9. 系统日志查看"
    echo "10. 重启网络服务"
    echo "11. 常用命令速查"
    echo "0. 退出脚本"
    echo -e "${BLUE}================================${NC}"
}

system_info() {
    echo -e "${GREEN}=== 系统信息 ===${NC}"
    echo "系统版本:"
    cat /etc/openwrt_release 2>/dev/null || echo "无法获取版本信息"
    echo
    echo "内核版本: $(uname -a)"
    echo "运行时间: $(uptime)"
    echo "内存使用:"
    free -h || cat /proc/meminfo | head -4
    echo
    read -p "按回车键继续..."
}

network_status() {
    echo -e "${GREEN}=== 网络接口状态 ===${NC}"
    echo "接口列表:"
    ifconfig || ip addr show
    echo
    echo "路由表:"
    route -n
    echo
    read -p "按回车键继续..."
}

wireless_status() {
    echo -e "${GREEN}=== 无线网络状态 ===${NC}"
    if command -v iwinfo >/dev/null 2>&1; then
        for radio in $(iwinfo | grep -o "phy[0-9]"); do
            echo "Radio $radio:"
            iwinfo $radio info
            echo
        done
    else
        echo "iwinfo命令不可用"
    fi
    read -p "按回车键继续..."
}

process_status() {
    echo -e "${GREEN}=== 进程和内存状态 ===${NC}"
    echo "进程列表 (前20个):"
    ps | head -20
    echo
    echo "内存使用:"
    free -h || cat /proc/meminfo | head -4
    echo
    echo "负载平均:"
    cat /proc/loadavg 2>/dev/null || echo "无法获取负载信息"
    echo
    read -p "按回车键继续..."
}

disk_space() {
    echo -e "${GREEN}=== 磁盘空间 ===${NC}"
    echo "磁盘使用情况:"
    df -h
    echo
    echo "overlayfs使用:"
    df -h | grep overlay || echo "无overlay信息"
    echo
    read -p "按回车键继续..."
}

package_management() {
    echo -e "${GREEN}=== 软件包管理 ===${NC}"
    echo "1. 查看已安装包"
    echo "2. 更新软件包列表"
    echo "3. 安装软件包"
    echo "4. 卸载软件包"
    echo -n "请选择: "
    read choice
    
    case $choice in
        1) opkg list-installed | head -30 ;;
        2) opkg update ;;
        3) 
            echo -n "输入包名: "
            read pkg
            opkg install $pkg
            ;;
        4)
            echo -n "输入包名: "
            read pkg  
            opkg remove $pkg
            ;;
        *) echo "无效选择" ;;
    esac
    read -p "按回车键继续..."
}

network_test() {
    echo -e "${GREEN}=== 网络连接测试 ===${NC}"
    echo -n "输入测试地址 (默认 8.8.8.8): "
    read target
    target=${target:-8.8.8.8}
    ping -c 4 $target
    read -p "按回车键继续..."
}

service_management() {
    echo -e "${GREEN}=== 系统服务管理 ===${NC}"
    echo "运行的服务:"
    /etc/init.d/* enabled 2>/dev/null | head -10
    echo
    echo "1. 重启网络服务"
    echo "2. 重启防火墙"
    echo -n "请选择: "
    read choice
    
    case $choice in
        1) /etc/init.d/network restart ;;
        2) /etc/init.d/firewall restart ;;
        *) echo "无效选择" ;;
    esac
    read -p "按回车键继续..."
}

system_logs() {
    echo -e "${GREEN}=== 系统日志 ===${NC}"
    echo "最近日志:"
    logread | tail -20
    echo
    echo "内核日志:"
    dmesg | tail -10
    read -p "按回车键继续..."
}

restart_network() {
    echo -e "${YELLOW}重启网络服务...${NC}"
    /etc/init.d/network restart
    echo "完成!"
    sleep 2
}

quick_commands() {
    echo -e "${GREEN}=== 常用命令速查 ===${NC}"
    echo "系统信息:"
    echo "  cat /etc/openwrt_release    # 系统版本"
    echo "  uname -a                   # 内核信息" 
    echo "  uptime                     # 运行时间"
    echo "  free -h                    # 内存使用"
    echo
    echo "网络命令:"
    echo "  ifconfig                   # 接口信息"
    echo "  route -n                   # 路由表"
    echo "  ping 8.8.8.8              # 网络测试"
    echo "  netstat -tuln              # 端口监听"
    echo
    echo "软件包:"
    echo "  opkg update                # 更新列表"
    echo "  opkg install <包名>        # 安装"
    echo "  opkg remove <包名>         # 卸载"
    echo
    echo "服务管理:"
    echo "  /etc/init.d/network restart # 重启网络"
    echo "  /etc/init.d/firewall reload # 重载防火墙"
    echo "  logread                    # 查看日志"
    echo
    read -p "按回车键继续..."
}

main() {
    # 检查root权限
    if [ "$(id -u)" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
    
    while true; do
        show_menu
        echo -n "请选择操作 [0-11]: "
        read choice
        
        case $choice in
            1) system_info ;;
            2) network_status ;;
            3) wireless_status ;;
            4) process_status ;;
            5) disk_space ;;
            6) package_management ;;
            7) network_test ;;
            8) service_management ;;
            9) system_logs ;;
            10) restart_network ;;
            11) quick_commands ;;
            0) 
                echo "感谢使用!"
                exit 0 
                ;;
            *) 
                echo "无效选择"
                sleep 2
                ;;
        esac
    done
}

# 运行主函数
main "$@"
