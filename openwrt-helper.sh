#!/bin/bash
# OpenWrt系统管理脚本
# 使用方法: bash <(curl -s https://raw.githubusercontent.com/chengege666/openwrt-helper/main/openwrt-helper.sh)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 脚本配置
SCRIPT_NAME="openwrt-helper.sh"
SCRIPT_VERSION="1.8"
SCRIPT_URL="https://raw.githubusercontent.com/chengege666/openwrt-helper/main/openwrt-helper.sh"
BACKUP_SCRIPT="/usr/local/bin/openwrt-helper.sh"

# 日志函数
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示标题
show_banner() {
    clear
    echo -e "${NC}"
    echo -e "${CYAN}            OpenWrt 系统管理助手 v1.8${NC}"
    echo -e "${CYAN}        GitHub: chengege666/openwrt-helper${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo
}

# 检查系统
check_system() {
    if [ "$(id -u)" -ne 0 ]; then
        error "请使用root权限运行此脚本！"
        exit 1
    fi
    
    if ! grep -qi "openwrt" /etc/os-release 2>/dev/null && [ ! -f /etc/openwrt_release ]; then
        warn "这似乎不是OpenWrt系统，某些功能可能不可用"
    fi
}

# 显示菜单
show_menu() {
    show_banner
    echo -e "${WHITE}请选择功能：${NC}"
    echo
    echo -e "  ${CYAN}1. 系统信息总览${NC}"
    echo -e "  ${CYAN}2. 网络状态检查${NC}"
    echo -e "  ${CYAN}3. 无线网络管理${NC}"
    echo -e "  ${CYAN}4. 防火墙状态${NC}"
    echo -e "  ${CYAN}5. 软件包管理${NC}"
    echo -e "  ${CYAN}6. 磁盘空间检查${NC}"
    echo -e "  ${CYAN}7. 系统服务管理${NC}"
    echo -e "  ${CYAN}8. 系统日志查看${NC}"
    echo -e "  ${CYAN}9. 重启网络服务${NC}"
    echo -e "  ${CYAN}10. 域名解析 (nslookup)${NC}"
    echo -e "  ${CYAN}11. 一键安装所有依赖${NC}"
    echo -e "  ${CYAN}12. 查看已安装的依赖${NC}"
    echo -e "  ${RED}13. 重启系统${NC}"
    echo -e "  ${CYAN}14. OpenWrt 一键换源${NC}"
    echo -e "  ${CYAN}15. iStoreOS 风格和应用商店切换${NC}"
    echo -e "  ${GREEN}0. 退出脚本${NC}"
    echo
    echo -e "${BLUE}=================================================${NC}"
}

# 系统信息总览
system_info() {
    log "正在获取系统信息..."
    echo
    echo -e "${CYAN}=== 系统版本信息 ===${NC}"
    if [ -f /etc/openwrt_release ]; then
        cat /etc/openwrt_release
    else
        echo "无法获取OpenWrt版本信息"
    fi
    echo
    echo -e "${CYAN}=== CPU信息 ===${NC}"
    # CPU型号信息
    if [ -f /proc/cpuinfo ]; then
        echo -e "CPU型号: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' 2>/dev/null || grep -m1 'Processor' /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' 2>/dev/null || echo '未知')"
        echo -e "CPU架构: $(uname -m)"
        echo -e "核心数量: $(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo '未知')"
        # CPU频率（如果可用）
        if [ -f /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq ]; then
            cpu_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq 2>/dev/null)
            if [ -n "$cpu_freq" ]; then
                echo -e "当前频率: $((cpu_freq / 1000)) MHz"
            fi
        fi
        # CPU温度（如果可用）
        if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
            temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
            if [ -n "$temp" ]; then
                echo -e "CPU温度: $((temp / 1000))°C"
            fi
        fi
        # 负载情况
        echo -e "负载情况: $(cat /proc/loadavg 2>/dev/null | cut -d' ' -f1-3 || echo '未知')"
    else
        echo "无法获取CPU信息"
    fi
    echo
    echo -e "${CYAN}=== 内核信息 ===${NC}"
    uname -a
    echo
    echo -e "${CYAN}=== 运行时间 ===${NC}"
    uptime
    echo
    echo -e "${CYAN}=== 内存使用 ===${NC}"
    free -h 2>/dev/null || cat /proc/meminfo | head -3
    echo
    echo -e "${CYAN}=== 系统负载详情 ===${NC}"
    echo -e "1分钟负载: $(cat /proc/loadavg 2>/dev/null | cut -d' ' -f1 || echo '未知')"
    echo -e "5分钟负载: $(cat /proc/loadavg 2>/dev/null | cut -d' ' -f2 || echo '未知')"
    echo -e "15分钟负载: $(cat /proc/loadavg 2>/dev/null | cut -d' ' -f3 || echo '未知')"
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
    if command -v netstat >/dev/null 2>&1; then
        netstat -tunlp 2>/dev/null | head -20
    else
        echo "netstat命令不可用"
    fi
}

# 无线网络管理
wireless_management() {
    log "无线网络信息"
    echo
    if command -v iwinfo >/dev/null 2>&1; then
        for radio in /sys/class/ieee80211/*; do
            if [ -d "$radio" ]; then
                radio_name=$(basename "$radio")
                echo -e "${CYAN}=== 无线接口 $radio_name ===${NC}"
                iwinfo "$radio_name" info 2>/dev/null || echo "无法获取该接口信息"
                echo
            fi
        done
    else
        echo "iwinfo命令不可用"
    fi
}

# 防火墙状态
firewall_status() {
    log "防火墙状态"
    echo
    if command -v iptables >/dev/null 2>&1; then
        echo -e "${CYAN}=== 防火墙规则 ===${NC}"
        iptables -L -n 2>/dev/null | head -30
    else
        echo "iptables命令不可用"
    fi
}

# 软件包管理
package_management() {
    echo
    echo -e "${CYAN}=== 软件包管理 ===${NC}"
    echo "1. 查看已安装包"
    echo "2. 更新软件包列表" 
    echo "3. 安装软件包"
    echo "4. 卸载软件包"
    echo "5. 返回主菜单"
    echo
    read -p "请选择操作 [1-5]: " choice
    
    case $choice in
        1) 
            if command -v opkg >/dev/null 2>&1; then
                opkg list-installed | head -30
            else
                error "opkg命令不可用"
            fi
            ;;
        2)
            if command -v opkg >/dev/null 2>&1; then
                opkg update
            else
                error "opkg命令不可用"
            fi
            ;;
        3)
            read -p "请输入要安装的包名: " pkg
            if command -v opkg >/dev/null 2>&1; then
                opkg install "$pkg"
            else
                error "opkg命令不可用"
            fi
            ;;
        4)
            read -p "请输入要卸载的包名: " pkg
            if command -v opkg >/dev/null 2>&1; then
                opkg remove "$pkg"
            else
                error "opkg命令不可用"
            fi
            ;;
        5) return ;;
        *) warn "无效选择" ;;
    esac
}

# 磁盘空间检查
disk_check() {
    log "磁盘空间检查"
    echo
    echo -e "${CYAN}=== 磁盘使用情况 ===${NC}"
    df -h
    echo
    echo -e "${CYAN}=== 内存使用情况 ===${NC}"
    free -h 2>/dev/null || cat /proc/meminfo | head -3
}

# 网络速度测试
speed_test() {
    log "网络速度测试"
    echo
    echo -e "${YELLOW}注意: 测试会消耗少量流量${NC}"
    echo
    echo -e "${CYAN}=== Ping 测试 ===${NC}"
    ping -c 3 8.8.8.8
    echo
    echo -e "${CYAN}=== 下载测试 ===${NC}"
    if command -v wget >/dev/null 2>&1; then
        time wget -O /dev/null http://cachefly.cachefly.net/10mb.test 2>&1 | grep -i "speed"
    else
        warn "wget不可用，跳过下载测试"
    fi
}

# 系统服务管理
service_management() {
    echo
    echo -e "${CYAN}=== 系统服务管理 ===${NC}"
    echo "1. 查看服务状态"
    echo "2. 重启网络服务"
    echo "3. 重启防火墙"
    echo "4. 查看所有服务"
    echo "5. 返回主菜单"
    echo
    read -p "请选择操作 [1-5]: " choice
    
    case $choice in
        1)
            echo -e "${CYAN}=== 运行的服务 ===${NC}"
            /etc/init.d/* enabled 2>/dev/null || echo "无法获取服务状态"
            ;;
        2)
            log "重启网络服务..."
            if [ -f /etc/init.d/network ]; then
                /etc/init.d/network restart
            else
                error "网络服务不可用"
            fi
            ;;
        3)
            log "重启防火墙..."
            if [ -f /etc/init.d/firewall ]; then
                /etc/init.d/firewall restart
            else
                error "防火墙服务不可用"
            fi
            ;;
        4)
            echo -e "${CYAN}=== 所有服务 ===${NC}"
            ls /etc/init.d/ 2>/dev/null | head -20
            ;;
        5) return ;;
        *) warn "无效选择" ;;
    esac
}

# 系统日志查看
log_view() {
    log "系统日志查看"
    echo
    echo -e "${CYAN}=== 最近系统日志 ===${NC}"
    if command -v logread >/dev/null 2>&1; then
        logread | tail -20
    else
        dmesg | tail -20
    fi
    echo
    echo -e "${CYAN}=== 内核日志 ===${NC}"
    dmesg | tail -10
}

# 重启网络服务
restart_network() {
    warn "即将重启网络服务..."
    if [ -f /etc/init.d/network ]; then
        /etc/init.d/network restart
        log "网络服务重启完成"
    else
        error "网络服务不可用"
    fi
}

# 备份系统配置
backup_config() {
    log "备份系统配置"
    echo
    if command -v sysupgrade >/dev/null 2>&1; then
        BACKUP_FILE="/tmp/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        sysupgrade -b "$BACKUP_FILE"
        if [ $? -eq 0 ]; then
            log "备份成功: $BACKUP_FILE"
        else
            error "备份失败"
        fi
    else
        error "sysupgrade命令不可用"
        echo "可以手动备份重要文件: /etc/config/"
    fi
}

# 高级工具
advanced_tools() {
    echo
    echo -e "${CYAN}=== 高级工具 ===${NC}"
    echo "1. 查看UCI配置"
    echo "2. 查看进程信息"
    echo "3. 查看系统信息"
    echo "4. 返回主菜单"
    echo
    read -p "请选择操作 [1-4]: " choice
    
    case $choice in
        1)
            if command -v uci >/dev/null 2>&1; then
                uci show 2>/dev/null | head -30
            else
                error "uci命令不可用"
            fi
            ;;
        2)
            echo -e "${CYAN}=== 进程信息 ===${NC}"
            ps | head -20
            ;;
        3)
            echo -e "${CYAN}=== 详细系统信息 ===${NC}"
            cat /proc/cpuinfo 2>/dev/null | grep -E "processor|model name" | head -5
            echo
            cat /proc/meminfo 2>/dev/null | head -5
            ;;
        4) return ;;
        *) warn "无效选择" ;;
    esac
}

# nslookup 工具
nslookup_tool() {
    log "域名解析工具 (nslookup)"
    echo
    read -p "请输入要查询的域名 (例如: baidu.com): " domain
    if [ -z "$domain" ]; then
        warn "域名不能为空"
        return
    fi
    
    if command -v nslookup >/dev/null 2>&1; then
        nslookup "$domain"
    else
        error "nslookup命令不可用，请尝试安装 bind-host 或 dnsutils 软件包"
    fi
}

# 更新脚本
update_script() {
    log "检查脚本更新..."
    echo
    
    # 检查是否从网络直接运行
    if [[ "$0" == *"dev/fd"* ]] || [[ "$0" == *"pipe"* ]]; then
        warn "检测到您正在从网络直接运行脚本"
        echo "建议先下载脚本到本地再使用更新功能"
        echo
        echo "下载命令示例:"
        echo "wget -O /usr/local/bin/openwrt-helper.sh $SCRIPT_URL"
        echo "chmod +x /usr/local/bin/openwrt-helper.sh"
        echo
        read -p "是否尝试自动下载到本地? (y/N): " download_choice
        
        if [ "$download_choice" = "y" ] || [ "$download_choice" = "Y" ]; then
            # 尝试下载到标准位置
            mkdir -p /usr/local/bin/
            if wget -O "$BACKUP_SCRIPT" "$SCRIPT_URL" 2>/dev/null; then
                chmod +x "$BACKUP_SCRIPT"
                log "脚本已下载到: $BACKUP_SCRIPT"
                echo "下次请使用: $BACKUP_SCRIPT 运行脚本"
            else
                error "下载失败，请检查网络连接"
            fi
        fi
        return
    fi
    
    # 检查当前脚本路径
    CURRENT_SCRIPT="$0"
    log "当前脚本: $CURRENT_SCRIPT"
    log "当前版本: $SCRIPT_VERSION"
    
    # 创建临时文件用于下载新版本
    TEMP_SCRIPT="/tmp/openwrt-helper-new.sh"
    
    # 下载最新版本
    log "正在从 $SCRIPT_URL 下载最新版本..."
    if wget -O "$TEMP_SCRIPT" "$SCRIPT_URL" 2>/dev/null; then
        # 检查下载的脚本是否有效
        if grep -q "OpenWrt系统管理脚本" "$TEMP_SCRIPT" 2>/dev/null; then
            # 获取新版本号
            NEW_VERSION=$(grep "SCRIPT_VERSION" "$TEMP_SCRIPT" 2>/dev/null | head -1 | cut -d'"' -f2)
            if [ -z "$NEW_VERSION" ]; then
                NEW_VERSION="未知"
            fi
            
            log "最新版本: $NEW_VERSION"
            
            if [ "$NEW_VERSION" != "$SCRIPT_VERSION" ] && [ "$NEW_VERSION" != "未知" ]; then
                echo
                echo -e "${GREEN}发现新版本: $NEW_VERSION${NC}"
                echo -e "当前版本: $SCRIPT_VERSION"
                echo
                read -p "是否更新到最新版本? (y/N): " update_confirm
                
                if [ "$update_confirm" = "y" ] || [ "$update_confirm" = "Y" ]; then
                    # 备份当前脚本
                    BACKUP_FILE="$CURRENT_SCRIPT.backup.$(date +%Y%m%d-%H%M%S)"
                    cp "$CURRENT_SCRIPT" "$BACKUP_FILE"
                    
                    # 替换脚本
                    cp "$TEMP_SCRIPT" "$CURRENT_SCRIPT"
                    chmod +x "$CURRENT_SCRIPT"
                    
                    log "脚本更新成功!"
                    log "旧版本已备份到: $BACKUP_FILE"
                    echo
                    echo -e "${GREEN}更新完成! 请重新运行脚本以使用新版本。${NC}"
                    exit 0
                else
                    log "更新已取消"
                fi
            else
                log "当前已是最新版本"
            fi
        else
            error "下载的脚本文件无效"
        fi
    else
        error "下载失败，请检查网络连接"
    fi
    
    # 清理临时文件
    rm -f "$TEMP_SCRIPT"
}

# 系统恢复初始状态
restore_factory() {
    echo
    echo -e "${RED}=== 警告：系统恢复初始状态 ===${NC}"
    echo
    echo -e "${YELLOW}此操作将：${NC}"
    echo -e "  • 重置所有系统配置到出厂状态"
    echo -e "  • 删除所有自定义设置"
    echo -e "  • 清除安装的软件包（可选）"
    echo -e "  • 需要重启系统生效"
    echo
    echo -e "${RED}这是一个危险操作，将丢失所有当前配置！${NC}"
    echo
    
    # 第一次确认
    read -p "确定要继续吗？(输入 'YES' 确认): " confirm1
    if [ "$confirm1" != "YES" ]; then
        log "操作已取消"
        return
    fi
    
    # 第二次确认
    echo
    echo -e "${RED}请再次确认！这将不可撤销地重置系统！${NC}"
    read -p "输入 'CONFIRM' 继续: " confirm2
    if [ "$confirm2" != "CONFIRM" ]; then
        log "操作已取消"
        return
    fi
    
    # 备份当前配置（可选）
    echo
    read -p "是否先备份当前配置？(y/N): " backup_choice
    if [ "$backup_choice" = "y" ] || [ "$backup_choice" = "Y" ]; then
        backup_config
    fi
    
    # 选择恢复模式
    echo
    echo -e "${CYAN}选择恢复模式：${NC}"
    echo "1. 仅重置配置（保留已安装软件）"
    echo "2. 完全恢复出厂（清除所有软件和配置）"
    echo "3. 取消操作"
    echo
    read -p "请选择 [1-3]: " mode_choice
    
    case $mode_choice in
        1)
            log "执行配置重置..."
            # 使用firstboot命令重置配置
            if command -v firstboot >/dev/null 2>&1; then
                firstboot -y
                if [ $? -eq 0 ]; then
                    log "配置重置成功，系统将在5秒后重启..."
                    sleep 5
                    reboot
                else
                    error "配置重置失败"
                fi
            else
                # 备用方法：删除配置文件
                warn "firstboot命令不可用，尝试手动重置..."
                rm -rf /etc/config/backup/
                mkdir -p /etc/config/backup/
                cp -r /etc/config/* /etc/config/backup/ 2>/dev/null || true
                # 这里可以添加更多重置逻辑
                warn "请手动处理或使用sysupgrade恢复"
            fi
            ;;
        2)
            log "执行完全恢复出厂..."
            # 使用sysupgrade恢复出厂设置
            if command -v sysupgrade >/dev/null 2>&1; then
                warn "这将清除所有数据和软件包！"
                read -p "确认执行完全恢复？(输入 'FACTORY' 确认): " factory_confirm
                if [ "$factory_confirm" = "FACTORY" ]; then
                    sysupgrade -r
                    if [ $? -eq 0 ]; then
                        log "系统恢复出厂设置完成，即将重启..."
                        reboot
                    else
                        error "恢复出厂设置失败"
                    fi
                else
                    log "操作已取消"
                fi
            else
                error "sysupgrade命令不可用，无法执行完全恢复"
            fi
            ;;
        3)
            log "操作已取消"
            return
            ;;
        *)
            warn "无效选择，操作已取消"
            return
            ;;
    esac
}



# 一键安装所有依赖
install_dependencies() {
    log "正在安装常用依赖包..."
    echo

    if ! command -v opkg >/dev/null 2>&1; then
        error "opkg命令不可用，无法安装依赖包。请检查您的OpenWrt系统。"
        return
    fi

    # 定义常用依赖包列表
    # 可以根据需要添加或删除这里的包
    DEPENDENCIES=(
        "wget"
        "curl"
        "unzip"
        "tar"
        "gzip"
        "bzip2"
        "coreutils"
        "findutils"
        "grep"
        "sed"
        "awk"
        "vim"
        "nano"
        "htop"
        "iftop"
        "tcpdump"
        "bind-host" # 提供nslookup
        "dnsmasq-full" # 替换dnsmasq，提供更多功能
        "luci" # 如果需要Web界面
        "luci-app-opkg" # LuCI的软件包管理界面
        "openssh-client"
        "openssh-server"
        "git"
        "svn"
        "rsync"
        "samba3-server" # 文件共享
        "vsftpd" # FTP服务器
        "nginx" # Web服务器
        "php7-cli" # PHP命令行
        "python3" # Python3
        "python3-pip" # Python3的pip
        "node" # Node.js
        "npm" # npm包管理器
    )

    INSTALLED_COUNT=0
    FAILED_COUNT=0

    for pkg in "${DEPENDENCIES[@]}"; do
        log "正在安装 $pkg ..."
        if opkg install "$pkg"; then
            log "$pkg 安装成功。"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        else
            warn "$pkg 安装失败，可能已安装或不存在。"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
        echo
    done

    log "依赖包安装完成。"
    log "成功安装: $INSTALLED_COUNT 个"
    log "失败/跳过: $FAILED_COUNT 个"
    echo
    warn "请注意：某些包可能不适用于您的OpenWrt版本或架构。"
}

# 查看已安装的依赖
view_installed_dependencies() {
    log "正在查看已安装的依赖包..."
    echo

    if command -v opkg >/dev/null 2>&1; then
        echo -e "${CYAN}=== 已安装的软件包 ===${NC}"
        opkg list-installed
    else
        error "opkg命令不可用，无法查看已安装的依赖包。请检查您的OpenWrt系统。"
    fi
    echo
}

# 重启系统
reboot_system() {
    warn "警告：这将重启系统！"
    echo
    read -p "确认要重启系统吗？(y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        log "系统将在5秒后重启..."
        sleep 5
        reboot
    else
        log "取消重启"
    fi
}

change_opkg_source() {
    log "OpenWrt 一键换源功能"
    echo "请选择要切换的源："
    echo "1. 官方源"
    echo "2. 清华大学源"
    echo "3. 中国科学技术大学源"
    echo "4. 自定义源"
    echo "0. 返回主菜单"
    read -p "请输入你的选择: " source_choice

    OPKG_CONF="/etc/opkg/distfeeds.conf"
    OFFICIAL_URL_BASE="http://downloads.openwrt.org"
    TSINGHUA_URL_BASE="https://mirrors.tuna.tsinghua.edu.cn/openwrt"
    USTC_URL_BASE="https://mirrors.ustc.edu.cn/openwrt"

    # Function to replace opkg source
    replace_opkg_source() {
        local new_base_url=$1
        # Assuming the default OpenWrt source base URL is http://downloads.openwrt.org
        # If your current source is different, this sed command might need adjustment.
        local old_base_url_pattern="http://downloads.openwrt.org"

        if [ ! -f "$OPKG_CONF" ]; then
            error "$OPKG_CONF 文件不存在，无法切换源。"
            return 1
        fi

        log "备份 $OPKG_CONF 到 $OPKG_CONF.bak..."
        cp "$OPKG_CONF" "$OPKG_CONF.bak"

        log "正在将源切换到: $new_base_url"
        # Use a temporary file for sed to avoid issues with direct in-place editing on some systems
        sed "s|$old_base_url_pattern|$new_base_url|g" "$OPKG_CONF" > "$OPKG_CONF.tmp" && mv "$OPKG_CONF.tmp" "$OPKG_CONF"

        if [ $? -eq 0 ]; then
            log "源切换成功。正在更新软件包列表..."
            opkg update
            if [ $? -eq 0 ]; then
                log "软件包列表更新成功！"
            else
                error "软件包列表更新失败，请检查网络连接或源地址。"
            fi
        else
            error "源切换失败，请检查 $OPKG_CONF 文件内容或手动修改。"
        fi
    }

    case $source_choice in
        1)
            log "切换到官方源..."
            replace_opkg_source "$OFFICIAL_URL_BASE"
            ;;
        2)
            log "切换到清华大学源..."
            replace_opkg_source "$TSINGHUA_URL_BASE"
            ;;
        3)
            log "切换到中国科学技术大学源..."
            replace_opkg_source "$USTC_URL_BASE"
            ;;
        4)
            read -p "请输入自定义源地址: " custom_url
            log "切换到自定义源: $custom_url"
            replace_opkg_source "$custom_url"
            ;;
        0)
            return
            ;;
        *)
            error "无效的选择，请重新输入。"
            ;;
    esac
    wait_key
}

change_istoreos_style() {
    log "iStoreOS 风格和应用商店切换功能"
    echo "请选择操作："
    echo "1. 切换 iStoreOS 风格"
    echo "2. 切换应用商店"
    echo "0. 返回主菜单"
    read -p "请输入你的选择: " istoreos_choice

    case $istoreos_choice in
        1)
            log "切换 iStoreOS 风格..."
            warn "此功能尚未完全实现，需要根据 iStoreOS 的具体配置进行修改。"
            ;;
        2)
            log "切换应用商店..."
            warn "此功能尚未完全实现，需要根据 iStoreOS 的具体配置进行修改。"
            ;;
        0)
            return
            ;;
        *)
            error "无效的选择，请重新输入。"
            ;;
    esac
    wait_key
}

# 等待按键
wait_key() {
    echo
    read -n 1 -s -r -p "按任意键继续..."
    echo
}

# 主函数
main() {
    check_system
    
    while true; do
        show_menu
        echo -n -e "${WHITE}请选择操作 [0-15]: ${NC}"
        read choice
        
        case $choice in
            1) system_info ;;
            2) network_check ;;
            3) wireless_management ;;
            4) firewall_status ;;
            5) package_management ;;
            6) disk_check ;;
            7) service_management ;;
            8) log_view ;;
            9) restart_network ;;
            10) nslookup_tool ;;
            11) install_dependencies ;;
            12) view_installed_dependencies ;;
            13) reboot_system ;;
            14) change_opkg_source ;;
            15) change_istoreos_style ;;
            0) 
                log "感谢使用，再见！"
                exit 0 
                ;;
            *) 
                error "无效选择，请重新输入"
                sleep 2
                continue
                ;;
        esac
        
        wait_key
    done
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
