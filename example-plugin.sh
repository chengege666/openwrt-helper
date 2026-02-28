#!/bin/bash
# 插件示例：端口扫描器
# PLUGIN_NAME="端口扫描器"
# PLUGIN_VERSION="1.0.0"
# PLUGIN_DESC="简单的端口扫描工具，用于检查主机开放端口"
# PLUGIN_AUTHOR="OpenWrt Helper"

# 插件初始化函数（可选）
plugin_init() {
    # 这里可以执行插件初始化逻辑
    :
}

# 插件主函数
plugin_main() {
    echo
    echo -e "\033[0;36m=== 端口扫描器 ===\033[0m"
    echo
    echo -e "\033[1;33m提示：用于检测主机开放了哪些端口\033[0m"
    echo
    
    read -p "请输入要扫描的 IP 地址或域名：" target_ip
    
    if [ -z "$target_ip" ]; then
        echo -e "\033[0;31m错误：目标不能为空\033[0m"
        return
    fi
    
    echo
    echo -e "\033[0;36m开始扫描 $target_ip 的常用端口...\033[0m"
    echo
    
    # 常用端口列表
    PORTS="21 22 23 25 53 80 110 143 443 445 993 995 3306 3389 8080 8443"
    
    open_ports=0
    
    for port in $PORTS; do
        # 使用 /dev/tcp 测试端口（bash 内置功能）
        if timeout 1 bash -c "echo >/dev/tcp/$target_ip/$port" 2>/dev/null; then
            echo -e "\033[0;32m✓ 端口 $port 开放\033[0m"
            open_ports=$((open_ports + 1))
        else
            echo -e "  端口 $port 关闭"
        fi
    done
    
    echo
    echo -e "\033[0;36m=== 扫描完成 ===\033[0m"
    echo "开放的端口数：$open_ports"
    echo
}

# 如果直接执行此脚本（非作为插件加载），运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    plugin_main "$@"
fi
