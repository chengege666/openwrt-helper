OpenWrt Helper

一个功能强大的 OpenWrt 系统管理助手脚本，提供图形化菜单界面，方便管理 OpenWrt 路由器。

功能特性

• 📊 系统信息查看

• 🌐 网络状态监控

• 📦 软件包管理

• 🔥 防火墙配置

• 💾 系统备份恢复

• 🚀 网络诊断工具

• ⚙️ 服务管理

• 🔄 一键更新

推荐安装命令（使用进程替换）

这种方法通常更加优雅，且避免将脚本内容直接写入历史记录。
```bash
bash <(curl -L -s https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/openwrt-helper.sh)
```

其他安装方式

一键安装到系统

# 使用curl
sh -c "$(curl -fsSL https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/install.sh)"

# 使用wget
sh -c "$(wget -qO- https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/install.sh)"


手动安装

# 下载脚本
wget https://raw.githubusercontent.com/你的用户名/openwrt-helper/main/openwrt-helper.sh

# 设置权限
chmod +x openwrt-helper.sh

# 运行脚本
./openwrt-helper.sh


使用方法

安装后直接运行：
openwrt-helper


更新脚本

脚本内置更新功能，可以在菜单中选择"更新脚本"自动更新到最新版本。

许可证

MIT License

贡献

欢迎提交 Issue 和 Pull Request！
