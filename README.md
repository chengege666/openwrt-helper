# OpenWrt Helper

一个功能强大的 OpenWrt 系统管理助手脚本，提供图形化菜单界面，方便管理 OpenWrt 路由器。

## 功能特性

- 📊 系统信息查看
- 🌐 网络状态监控
- 📦 软件包管理
- 🔥 防火墙配置
- 💾 系统备份恢复
- 🚀 网络诊断工具
- ⚙️ 服务管理
- 🔄 一键更新

## 一键安装

bash
方法1: 使用curl
sh -c "$(curl -fsSL https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/install.sh)"
方法2: 使用wget
sh -c "$(wget -qO- https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/install.sh)"

## 手动安装

wget https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/openwrt-helper.sh
设置权限
chmod +x openwrt-helper.sh
运行脚本
./openwrt-helper.sh

## 使用方法
一键运行命令
在您的GitHub仓库创建完成后，用户可以使用以下命令一键安装和运行：
方法1: 直接运行（不安装）
# 使用curl
sh -c "$(curl -fsSL https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/openwrt-helper.sh)"

# 使用wget
sh -c "$(wget -qO- https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/openwrt-helper.sh)"

方法2: 安装到系统
# 一键安装（推荐）
sh -c "$(curl -fsSL https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/install.sh)"

# 安装后使用
openwrt-helper


