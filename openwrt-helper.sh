#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

echo -e "${GREEN}>>> 开始执行 x86-64 (OpenWrt 24.10) iStoreOS 风格化脚本 <<<${PLAIN}"

# 1. 更新系统原生软件包源
echo -e "${YELLOW}1. 更新系统软件包源...${PLAIN}"
opkg update

# 2. 安装基础依赖与兼容包 (luci-compat 是 24.10 跑老插件的灵魂)
echo -e "${YELLOW}2. 安装基础依赖 (luci-compat)...${PLAIN}"
# 加 || true 防止因某些极简固件缺失包导致脚本中断
opkg install luci-compat curl wget || true

# 3. 安装 iStore 商店核心
echo -e "${YELLOW}3. 下载并安装 iStore 商店组件...${PLAIN}"
if [ ! -f "/bin/is-opkg" ]; then
    curl -sSL https://raw.githubusercontent.com/linkease/istore/main/install.sh | sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}iStore 安装失败，可能是网络无法访问 GitHub！${PLAIN}"
        exit 1
    fi
else
    echo -e "${GREEN}iStore 商店已存在，跳过安装。${PLAIN}"
fi

# 4. 重点修复：使用 iStoreOS 的专属源 (is-opkg) 安装仪表盘
echo -e "${YELLOW}4. 使用 is-opkg 安装 QuickStart 首页仪表盘...${PLAIN}"
/bin/is-opkg update
# 忽略依赖报错强装，这是悟空脚本能在各种杂交固件上成功的秘诀
/bin/is-opkg install luci-i18n-quickstart-zh-cn --force-depends

# (可选) 补充首页仪表盘“网络状态”所需的底层支持包
opkg install iptables-mod-tproxy iptables-mod-socket iptables-mod-iprange >/dev/null 2>&1 || true

# 5. 确保 Design 主题已安装并设为默认
echo -e "${YELLOW}5. 应用 Design 侧边栏主题...${PLAIN}"
# 如果原生 opkg 没有，就用 is-opkg 从 iStore 源拉取
/bin/is-opkg install luci-theme-design >/dev/null 2>&1 || opkg install luci-theme-design >/dev/null 2>&1
uci set luci.main.mediaurlbase='/luci-static/design'
uci commit luci

# 6. 修改系统版本显示信息 (装X用)
echo -e "${YELLOW}6. 修改系统底层描述...${PLAIN}"
if [ -f "/etc/openwrt_release" ]; then
    sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='OpenWrt (iStoreOS Style)'/" /etc/openwrt_release
fi

# 7. 终极杀招：清理 OpenWrt 的顽固缓存并重启服务
echo -e "${YELLOW}7. 清理 LuCI 缓存以确保界面立即生效...${PLAIN}"
rm -rf /tmp/luci-modulecache/
rm -rf /tmp/luci-indexcache*
/etc/init.d/rpcd restart

echo -e "${GREEN}=================================================${PLAIN}"
echo -e "${GREEN} 安装完成！${PLAIN}"
echo -e "${YELLOW} 请务必在浏览器按下 ${RED}Ctrl + F5${YELLOW} 强制刷新！${PLAIN}"
echo -e "${GREEN}=================================================${PLAIN}"
