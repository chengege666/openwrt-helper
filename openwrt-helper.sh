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
    echo -e "  ${CYAN}11. DNS 解析速度对比${NC}"
    echo -e "  ${CYAN}12. 网络速度测试${NC}"
    echo -e "  ${CYAN}13. 插件管理${NC}"
    echo -e "  ${CYAN}14. 一键安装所有依赖${NC}"
    echo -e "  ${RED}15. 重启系统${NC}"
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
    echo -e "${YELLOW}注意：测试会消耗一定流量，请谨慎使用${NC}"
    echo
    
    echo -e "${WHITE}请选择测试模式：${NC}"
    echo "1. 快速测试（约 5MB 流量）"
    echo "2. 标准测试（约 20MB 流量）"
    echo "3. 详细测试（约 50MB 流量）"
    echo "4. 自定义 URL 测试"
    echo "5. 返回主菜单"
    echo
    read -p "请选择 [1-5]: " mode_choice
    
    case $mode_choice in
        1)
            test_url="http://cachefly.cachefly.net/5mb.test"
            ;;
        2)
            test_url="http://cachefly.cachefly.net/20mb.test"
            ;;
        3)
            test_url="http://cachefly.cachefly.net/50mb.test"
            ;;
        4)
            read -p "请输入测试文件 URL: " test_url
            if [ -z "$test_url" ]; then
                warn "URL 不能为空，使用默认测试地址"
                test_url="http://cachefly.cachefly.net/10mb.test"
            fi
            ;;
        5)
            return
            ;;
        *)
            warn "无效选择，使用默认测试地址"
            test_url="http://cachefly.cachefly.net/10mb.test"
            ;;
    esac
    
    echo
    echo -e "${CYAN}=== 网络速度测试 ===${NC}"
    echo
    echo -e "测试地址：$test_url"
    echo
    
    # 检查必要工具
    if ! command -v wget >/dev/null 2>&1; then
        error "wget 命令不可用，请先安装 wget"
        return
    fi
    
    # Ping 延迟测试
    echo -e "${CYAN}=== Ping 延迟测试 ===${NC}"
    echo "测试到以下服务器的延迟："
    echo
    
    # 常用 DNS 服务器延迟
    for host in 114.114.114.114 223.5.5.5 8.8.8.8 1.1.1.1; do
        if ping -c 2 -W 1 "$host" >/dev/null 2>&1; then
            avg_time=$(ping -c 2 -W 1 "$host" 2>&1 | grep -oP 'time=\K[0-9.]+(?= ms)' | awk '{sum+=$1} END {print sum/NR}')
            if [ -n "$avg_time" ]; then
                if [ "${avg_time%.*}" -lt 50 ]; then
                    color="${GREEN}"
                elif [ "${avg_time%.*}" -lt 100 ]; then
                    color="${CYAN}"
                elif [ "${avg_time%.*}" -lt 200 ]; then
                    color="${YELLOW}"
                else
                    color="${RED}"
                fi
                printf "%-15s ${color}%8.2f ms${NC}\n" "$host" "$avg_time"
            fi
        else
            printf "%-15s ${RED}超时${NC}\n" "$host"
        fi
    done
    echo
    
    # 下载速度测试
    echo -e "${CYAN}=== 下载速度测试 ===${NC}"
    echo "开始下载测试..."
    echo
    
    # 创建临时文件
    TEMP_FILE="/tmp/speedtest_$$"
    
    # 使用 wget 测试，显示详细进度
    if wget --version | grep -q "progress"; then
        # 支持 progress 参数
        wget -O "$TEMP_FILE" --progress=bar:force "$test_url" 2>&1 | tail -5
    else
        # 不支持 progress 参数，使用简单模式
        wget -O "$TEMP_FILE" "$test_url" 2>&1 | tail -10
    fi
    
    # 计算结果
    if [ -f "$TEMP_FILE" ]; then
        file_size=$(ls -l "$TEMP_FILE" 2>/dev/null | awk '{print $5}')
        if [ -n "$file_size" ] && [ "$file_size" -gt 0 ]; then
            # 获取 wget 输出的速度信息
            speed_info=$(wget -O "$TEMP_FILE" "$test_url" 2>&1 | grep -oP '\([0-9.]+ [KMG]?B/s\)' | tail -1)
            
            # 转换文件大小为 MB
            size_mb=$((file_size / 1024 / 1024))
            
            echo
            echo -e "${CYAN}=== 测试结果 ===${NC}"
            echo "下载大小：${size_mb} MB"
            if [ -n "$speed_info" ]; then
                echo "平均速度：$speed_info"
            fi
        fi
    fi
    
    # 清理临时文件
    rm -f "$TEMP_FILE"
    
    echo
    echo -e "${YELLOW}提示：测试结果受服务器带宽、网络拥塞等因素影响${NC}"
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


# 插件系统配置
PLUGIN_DIR="/usr/lib/openwrt-helper/plugins"
PLUGIN_ENABLED_DIR="/usr/lib/openwrt-helper/enabled"

# 初始化插件目录
init_plugins() {
    if [ ! -d "$PLUGIN_DIR" ]; then
        mkdir -p "$PLUGIN_DIR" 2>/dev/null
        log "已创建插件目录：$PLUGIN_DIR"
    fi
    if [ ! -d "$PLUGIN_ENABLED_DIR" ]; then
        mkdir -p "$PLUGIN_ENABLED_DIR" 2>/dev/null
        log "已创建启用插件目录：$PLUGIN_ENABLED_DIR"
    fi
}

# 加载单个插件
load_plugin() {
    local plugin_file="$1"
    if [ -f "$plugin_file" ] && [ -r "$plugin_file" ]; then
        # 检查插件元数据
        if grep -q "# PLUGIN_NAME" "$plugin_file" 2>/dev/null; then
            # 执行插件初始化（如果有）
            if grep -q "plugin_init" "$plugin_file" 2>/dev/null; then
                source "$plugin_file"
                if type plugin_init >/dev/null 2>&1; then
                    plugin_init 2>/dev/null || true
                fi
            fi
            return 0
        fi
    fi
    return 1
}

# 加载所有启用的插件
load_all_plugins() {
    log "正在加载插件..."
    local count=0
    
    # 从启用目录加载插件
    if [ -d "$PLUGIN_ENABLED_DIR" ]; then
        for plugin in "$PLUGIN_ENABLED_DIR"/*.sh; do
            if [ -f "$plugin" ]; then
                if load_plugin "$plugin"; then
                    plugin_name=$(grep "# PLUGIN_NAME" "$plugin" | cut -d'"' -f2)
                    if [ -n "$plugin_name" ]; then
                        log "已加载插件：$plugin_name"
                        count=$((count + 1))
                    fi
                fi
            fi
        done
    fi
    
    if [ $count -gt 0 ]; then
        log "共加载 $count 个插件"
    else
        log "未加载任何插件"
    fi
}

# 显示插件菜单
plugin_menu() {
    echo
    echo -e "${CYAN}=== 插件管理 ===${NC}"
    echo "1. 查看已安装插件"
    echo "2. 安装插件"
    echo "3. 卸载插件"
    echo "4. 启用/禁用插件"
    echo "5. 运行插件"
    echo "6. 返回主菜单"
    echo
    read -p "请选择操作 [1-6]: " choice
    
    case $choice in
        1) list_plugins ;;
        2) install_plugin ;;
        3) uninstall_plugin ;;
        4) toggle_plugin ;;
        5) run_plugin ;;
        6) return ;;
        *) warn "无效选择" ;;
    esac
}

# 列出已安装的插件
list_plugins() {
    echo
    echo -e "${CYAN}=== 已安装的插件 ===${NC}"
    echo
    
    if [ ! -d "$PLUGIN_DIR" ] || [ -z "$(ls -A "$PLUGIN_DIR" 2>/dev/null)" ]; then
        echo "未安装任何插件"
        echo
        echo -e "${YELLOW}提示：可将插件脚本放入 $PLUGIN_DIR 目录${NC}"
        return
    fi
    
    local count=0
    for plugin in "$PLUGIN_DIR"/*.sh; do
        if [ -f "$plugin" ]; then
            plugin_name=$(grep "# PLUGIN_NAME" "$plugin" | cut -d'"' -f2)
            plugin_version=$(grep "# PLUGIN_VERSION" "$plugin" | cut -d'"' -f2)
            plugin_desc=$(grep "# PLUGIN_DESC" "$plugin" | cut -d'"' -f2)
            plugin_author=$(grep "# PLUGIN_AUTHOR" "$plugin" | cut -d'"' -f2)
            
            if [ -n "$plugin_name" ]; then
                count=$((count + 1))
                echo -e "${GREEN}[$count]${NC} $plugin_name"
                echo "    版本：${plugin_version:-未知}"
                echo "    描述：${plugin_desc:-无}"
                echo "    作者：${plugin_author:-未知}"
                
                # 检查是否启用
                if [ -f "$PLUGIN_ENABLED_DIR/$(basename "$plugin")" ]; then
                    echo -e "    状态：${GREEN}已启用${NC}"
                else
                    echo -e "    状态：${YELLOW}未启用${NC}"
                fi
                echo
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo "未找到有效的插件"
    fi
}

# 安装插件
install_plugin() {
    echo
    echo -e "${CYAN}=== 安装插件 ===${NC}"
    echo
    echo -e "${YELLOW}支持以下安装方式：${NC}"
    echo "1. 从 URL 下载"
    echo "2. 从本地文件导入"
    echo "3. 返回"
    echo
    read -p "请选择 [1-3]: " install_method
    
    case $install_method in
        1)
            read -p "请输入插件 URL: " plugin_url
            if [ -z "$plugin_url" ]; then
                warn "URL 不能为空"
                return
            fi
            
            plugin_name=$(basename "$plugin_url" .sh)
            if command -v wget >/dev/null 2>&1; then
                log "正在下载插件：$plugin_name"
                if wget -O "$PLUGIN_DIR/$plugin_name.sh" "$plugin_url" 2>/dev/null; then
                    chmod +x "$PLUGIN_DIR/$plugin_name.sh"
                    log "插件安装成功：$plugin_name"
                    
                    # 询问是否立即启用
                    read -p "是否立即启用此插件？(y/N): " enable_choice
                    if [ "$enable_choice" = "y" ] || [ "$enable_choice" = "Y" ]; then
                        ln -sf "$PLUGIN_DIR/$plugin_name.sh" "$PLUGIN_ENABLED_DIR/$plugin_name.sh"
                        log "插件已启用"
                        load_plugin "$PLUGIN_DIR/$plugin_name.sh"
                    fi
                else
                    error "下载失败"
                    rm -f "$PLUGIN_DIR/$plugin_name.sh"
                fi
            else
                error "wget 命令不可用"
            fi
            ;;
        2)
            read -p "请输入本地插件文件路径：" local_path
            if [ -f "$local_path" ]; then
                plugin_name=$(basename "$local_path" .sh)
                cp "$local_path" "$PLUGIN_DIR/$plugin_name.sh"
                chmod +x "$PLUGIN_DIR/$plugin_name.sh"
                log "插件安装成功：$plugin_name"
                
                read -p "是否立即启用此插件？(y/N): " enable_choice
                if [ "$enable_choice" = "y" ] || [ "$enable_choice" = "Y" ]; then
                    ln -sf "$PLUGIN_DIR/$plugin_name.sh" "$PLUGIN_ENABLED_DIR/$plugin_name.sh"
                    log "插件已启用"
                    load_plugin "$PLUGIN_DIR/$plugin_name.sh"
                fi
            else
                error "文件不存在：$local_path"
            fi
            ;;
        3)
            return
            ;;
        *)
            warn "无效选择"
            ;;
    esac
}

# 卸载插件
uninstall_plugin() {
    echo
    echo -e "${CYAN}=== 卸载插件 ===${NC}"
    echo
    
    if [ ! -d "$PLUGIN_DIR" ] || [ -z "$(ls -A "$PLUGIN_DIR" 2>/dev/null)" ]; then
        echo "未安装任何插件"
        return
    fi
    
    list_plugins
    echo
    read -p "请输入要卸载的插件编号： " plugin_num
    
    if [ -n "$plugin_num" ] && [ "$plugin_num" -gt 0 ]; then
        local count=0
        for plugin in "$PLUGIN_DIR"/*.sh; do
            if [ -f "$plugin" ]; then
                plugin_name=$(grep "# PLUGIN_NAME" "$plugin" | cut -d'"' -f2)
                if [ -n "$plugin_name" ]; then
                    count=$((count + 1))
                    if [ "$count" -eq "$plugin_num" ]; then
                        # 询问确认
                        read -p "确定要卸载插件 '$plugin_name' 吗？(y/N): " confirm
                        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                            # 删除启用链接
                            rm -f "$PLUGIN_ENABLED_DIR/$(basename "$plugin")"
                            # 删除插件文件
                            rm -f "$plugin"
                            log "插件 '$plugin_name' 已卸载"
                        else
                            log "取消卸载"
                        fi
                        return
                    fi
                fi
            fi
        done
        error "无效的插件编号"
    else
        error "无效的输入"
    fi
}

# 启用/禁用插件
toggle_plugin() {
    echo
    echo -e "${CYAN}=== 启用/禁用插件 ===${NC}"
    echo
    
    if [ ! -d "$PLUGIN_DIR" ] || [ -z "$(ls -A "$PLUGIN_DIR" 2>/dev/null)" ]; then
        echo "未安装任何插件"
        return
    fi
    
    list_plugins
    echo
    read -p "请输入要操作的插件编号： " plugin_num
    
    if [ -n "$plugin_num" ] && [ "$plugin_num" -gt 0 ]; then
        local count=0
        for plugin in "$PLUGIN_DIR"/*.sh; do
            if [ -f "$plugin" ]; then
                plugin_name=$(grep "# PLUGIN_NAME" "$plugin" | cut -d'"' -f2)
                if [ -n "$plugin_name" ]; then
                    count=$((count + 1))
                    if [ "$count" -eq "$plugin_num" ]; then
                        plugin_basename=$(basename "$plugin")
                        
                        # 检查当前状态
                        if [ -f "$PLUGIN_ENABLED_DIR/$plugin_basename" ]; then
                            # 已启用，询问是否禁用
                            read -p "插件 '$plugin_name' 已启用，是否禁用？(y/N): " confirm
                            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                                rm -f "$PLUGIN_ENABLED_DIR/$plugin_basename"
                                log "插件 '$plugin_name' 已禁用"
                            fi
                        else
                            # 未启用，询问是否启用
                            read -p "插件 '$plugin_name' 未启用，是否启用？(y/N): " confirm
                            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                                ln -sf "$plugin" "$PLUGIN_ENABLED_DIR/$plugin_basename"
                                log "插件 '$plugin_name' 已启用"
                                load_plugin "$plugin"
                            fi
                        fi
                        return
                    fi
                fi
            fi
        done
        error "无效的插件编号"
    else
        error "无效的输入"
    fi
}

# 运行插件
run_plugin() {
    echo
    echo -e "${CYAN}=== 运行插件 ===${NC}"
    echo
    
    if [ ! -d "$PLUGIN_DIR" ] || [ -z "$(ls -A "$PLUGIN_DIR" 2>/dev/null)" ]; then
        echo "未安装任何插件"
        return
    fi
    
    list_plugins
    echo
    read -p "请输入要运行的插件编号： " plugin_num
    
    if [ -n "$plugin_num" ] && [ "$plugin_num" -gt 0 ]; then
        local count=0
        for plugin in "$PLUGIN_DIR"/*.sh; do
            if [ -f "$plugin" ]; then
                plugin_name=$(grep "# PLUGIN_NAME" "$plugin" | cut -d'"' -f2)
                if [ -n "$plugin_name" ]; then
                    count=$((count + 1))
                    if [ "$count" -eq "$plugin_num" ]; then
                        # 检查是否启用
                        if [ ! -f "$PLUGIN_ENABLED_DIR/$(basename "$plugin")" ]; then
                            warn "插件未启用，是否先启用？(y/N): " enable_choice
                            if [ "$enable_choice" = "y" ] || [ "$enable_choice" = "Y" ]; then
                                ln -sf "$plugin" "$PLUGIN_ENABLED_DIR/$(basename "$plugin")"
                                load_plugin "$plugin"
                            else
                                return
                            fi
                        fi
                        
                        # 运行插件主函数
                        if type plugin_main >/dev/null 2>&1; then
                            plugin_main
                        else
                            # 尝试直接执行
                            source "$plugin"
                            if type plugin_main >/dev/null 2>&1; then
                                plugin_main
                            else
                                warn "插件没有定义 plugin_main 函数，尝试直接执行..."
                                bash "$plugin"
                            fi
                        fi
                        return
                    fi
                fi
            fi
        done
        error "无效的插件编号"
    else
        error "无效的输入"
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
    read -p "请输入要查询的域名 (例如：baidu.com): " domain
    if [ -z "$domain" ]; then
        warn "域名不能为空"
        return
    fi
    
    if command -v nslookup >/dev/null 2>&1; then
        nslookup "$domain"
    else
        error "nslookup 命令不可用，请尝试安装 bind-host 或 dnsutils 软件包"
    fi
}

# DNS 解析速度对比测试
dns_speed_test() {
    log "DNS 解析速度对比测试"
    echo
    echo -e "${CYAN}=== DNS 服务器解析速度对比 ===${NC}"
    echo
    echo -e "${YELLOW}提示：测试将使用不同 DNS 服务器解析常用域名，耗时越短越好${NC}"
    echo
    
    read -p "请输入要测试的域名 (默认：www.baidu.com): " test_domain
    test_domain=${test_domain:-www.baidu.com}
    
    if [ -z "$test_domain" ]; then
        warn "域名不能为空"
        return
    fi
    
    echo
    echo -e "${CYAN}测试域名：$test_domain${NC}"
    echo
    
    # 定义常用 DNS 服务器
    DNS_SERVERS="114.114.114.114 114.114.115.115 223.5.5.5 223.6.6.6 180.76.76.76 1.1.1.1 8.8.8.8 8.8.4.4 9.9.9.9 208.67.222.222"
    
    echo -e "${WHITE}开始测试...${NC}"
    echo
    
    # 创建临时文件存储结果
    RESULTS_FILE="/tmp/dns_speed_test_$$"
    > "$RESULTS_FILE"
    
    # 检查 dig 或 nslookup 是否可用
    if command -v dig >/dev/null 2>&1; then
        USE_DIG=1
    elif command -v nslookup >/dev/null 2>&1; then
        USE_DIG=0
    else
        error "dig 和 nslookup 命令都不可用，请安装 bind-host 或 dnsutils"
        rm -f "$RESULTS_FILE"
        return
    fi
    
    # 测试每个 DNS 服务器
    for dns in $DNS_SERVERS; do
        echo -ne "测试 $dns ... "
        
        if [ "$USE_DIG" -eq 1 ]; then
            # 使用 dig 测试
            start_time=$(date +%s)
            result=$(dig @"$dns" "$test_domain" +short +time=3 +tries=2 2>/dev/null | head -1)
            end_time=$(date +%s)
        else
            # 使用 nslookup 测试
            start_time=$(date +%s)
            result=$(nslookup "$test_domain" "$dns" 2>/dev/null | grep -A1 "Name:" | grep "Address:" | head -1 | awk '{print $2}')
            end_time=$(date +%s)
        fi
        
        # 计算耗时（秒转毫秒）
        elapsed=$(( (end_time - start_time) * 1000 ))
        
        if [ -n "$result" ]; then
            echo -e "${GREEN}${elapsed}ms${NC} - $result"
            echo "$elapsed|$dns|$result" >> "$RESULTS_FILE"
        else
            echo -e "${RED}超时/失败${NC}"
            echo "9999|$dns|失败" >> "$RESULTS_FILE"
        fi
    done
    
    echo
    echo -e "${CYAN}=== 测试结果排序（从快到慢）===${NC}"
    echo
    
    # 排序并显示结果
    if [ -f "$RESULTS_FILE" ]; then
        echo -e "${WHITE}DNS 服务器\t\t\t响应时间\t解析结果${NC}"
        echo "------------------------------------------------------------"
        
        sort -t'|' -k1 -n "$RESULTS_FILE" | head -10 | while IFS='|' read -r time dns result; do
            if [ "$time" -lt 100 ]; then
                color="${GREEN}"
            elif [ "$time" -lt 300 ]; then
                color="${CYAN}"
            elif [ "$time" -lt 500 ]; then
                color="${YELLOW}"
            else
                color="${RED}"
            fi
            
            if [ "$time" -eq 9999 ]; then
                echo -e "$dns\t${color}超时${NC}\t\t$result"
            else
                echo -e "$dns\t${color}${time}ms${NC}\t\t$result"
            fi
        done
        
        echo
        
        # 推荐最佳 DNS
        best_line=$(sort -t'|' -k1 -n "$RESULTS_FILE" | head -1)
        best_dns=$(echo "$best_line" | cut -d'|' -f2)
        best_time=$(echo "$best_line" | cut -d'|' -f1)
        
        if [ "$best_time" -ne 9999 ]; then
            echo -e "${GREEN}✓ 推荐 DNS: $best_dns (${best_time}ms)${NC}"
            echo
            echo -e "${YELLOW}提示：可在网络配置中设置此 DNS 以获得更快的解析速度${NC}"
        fi
    fi
    
    rm -f "$RESULTS_FILE"
    echo
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

    # 定义常用依赖包列表（已去重）
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
        "luci-base"
        "bash"
        "ca-bundle"
        "ipset"
        "ip-full"
        "ruby"
        "ruby-yaml"
        "iptables"
        "kmod-ipt-nat"
        "iptables-mod-tproxy"
        "iptables-mod-extra"
        "kmod-tun"
        "luci-compat"
        "ip6tables-mod-nat"
        "kmod-inet-diag"
        "kmod-nft-tproxy"
        "yq"
        "firewall4"
        "kmod-nft-socket"
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

# 等待按键
wait_key() {
    echo
    read -n 1 -s -r -p "按任意键继续..."
    echo
}

# 主函数
main() {
    check_system
    init_plugins
    load_all_plugins
    
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
            11) dns_speed_test ;;
            12) speed_test ;;
            13) plugin_menu ;;
            14) install_dependencies ;;
            15) reboot_system ;;
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
