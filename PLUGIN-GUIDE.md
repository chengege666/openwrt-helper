# OpenWrt Helper 插件开发指南

## 插件系统介绍

OpenWrt Helper 插件系统允许您扩展脚本的功能，无需修改主脚本代码。

## 插件目录结构

```
/usr/lib/openwrt-helper/
├── plugins/          # 插件存放目录
└── enabled/          # 已启用的插件（符号链接）
```

## 插件开发规范

### 1. 插件文件命名

- 使用 `.sh` 扩展名
- 使用小写字母和连字符，例如：`port-scanner.sh`

### 2. 插件元数据

在插件文件开头添加以下注释（必需）：

```bash
#!/bin/bash
# PLUGIN_NAME="插件名称"
# PLUGIN_VERSION="1.0.0"
# PLUGIN_DESC="插件功能描述"
# PLUGIN_AUTHOR="作者名称"
```

### 3. 插件函数

#### plugin_init() - 初始化函数（可选）

在插件加载时自动执行，用于初始化变量、检查依赖等。

```bash
plugin_init() {
    # 初始化逻辑
    :
}
```

#### plugin_main() - 主函数（必需）

插件的主要执行逻辑，通过菜单调用。

```bash
plugin_main() {
    # 插件功能实现
    echo "Hello from plugin!"
}
```

### 4. 完整示例

```bash
#!/bin/bash
# PLUGIN_NAME="示例插件"
# PLUGIN_VERSION="1.0.0"
# PLUGIN_DESC="这是一个示例插件"
# PLUGIN_AUTHOR="Your Name"

plugin_init() {
    echo "插件已初始化"
}

plugin_main() {
    echo "=== 示例插件 ==="
    echo "这是插件的功能实现"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    plugin_main "$@"
fi
```

## 插件安装方法

### 方法 1：通过插件菜单安装

1. 运行主脚本
2. 选择 `13. 插件管理`
3. 选择 `2. 安装插件`
4. 选择安装方式（URL 下载或本地导入）

### 方法 2：手动安装

```bash
# 复制插件到插件目录
cp your-plugin.sh /usr/lib/openwrt-helper/plugins/

# 添加执行权限
chmod +x /usr/lib/openwrt-helper/plugins/your-plugin.sh

# 启用插件（创建符号链接）
ln -s /usr/lib/openwrt-helper/plugins/your-plugin.sh \
      /usr/lib/openwrt-helper/enabled/your-plugin.sh
```

## 插件管理命令

### 查看已安装插件
```bash
ls -la /usr/lib/openwrt-helper/plugins/
```

### 查看已启用插件
```bash
ls -la /usr/lib/openwrt-helper/enabled/
```

### 启用插件
```bash
ln -s /usr/lib/openwrt-helper/plugins/plugin-name.sh \
      /usr/lib/openwrt-helper/enabled/plugin-name.sh
```

### 禁用插件
```bash
rm /usr/lib/openwrt-helper/enabled/plugin-name.sh
```

### 卸载插件
```bash
rm /usr/lib/openwrt-helper/plugins/plugin-name.sh
rm /usr/lib/openwrt-helper/enabled/plugin-name.sh
```

## 插件开发最佳实践

### 1. 错误处理
```bash
plugin_main() {
    # 检查必要命令
    if ! command -v some_command >/dev/null 2>&1; then
        echo "错误：需要安装 some_command"
        return 1
    fi
    
    # 检查权限
    if [ "$(id -u)" -ne 0 ]; then
        echo "错误：需要 root 权限"
        return 1
    fi
    
    # 主要逻辑
    :
}
```

### 2. 用户交互
```bash
plugin_main() {
    echo "=== 插件功能 ==="
    
    read -p "确认执行？(y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "操作已取消"
        return
    fi
    
    # 执行操作
    :
}
```

### 3. 使用主脚本的颜色定义
```bash
plugin_main() {
    # 使用主脚本定义的颜色变量
    echo -e "${GREEN}成功${NC}"
    echo -e "${RED}错误${NC}"
    echo -e "${YELLOW}警告${NC}"
    echo -e "${CYAN}信息${NC}"
}
```

### 4. 依赖检查
```bash
plugin_init() {
    REQUIRED_COMMANDS="wget curl grep"
    
    for cmd in $REQUIRED_COMMANDS; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "警告：缺少命令 $cmd"
            MISSING_DEPS="$MISSING_DEPS $cmd"
        fi
    done
    
    if [ -n "$MISSING_DEPS" ]; then
        echo "请安装以下命令：$MISSING_DEPS"
    fi
}
```

## 插件示例

### 示例 1：系统清理插件
```bash
#!/bin/bash
# PLUGIN_NAME="系统清理"
# PLUGIN_VERSION="1.0.0"
# PLUGIN_DESC="清理系统缓存和临时文件"
# PLUGIN_AUTHOR="OpenWrt Helper"

plugin_main() {
    echo "=== 系统清理 ==="
    echo
    
    read -p "清理 /tmp 目录？(y/N): " clean_tmp
    if [ "$clean_tmp" = "y" ] || [ "$clean_tmp" = "Y" ]; then
        rm -rf /tmp/*
        echo "已清理 /tmp 目录"
    fi
    
    read -p "清理软件包缓存？(y/N): " clean_cache
    if [ "$clean_cache" = "y" ] || [ "$clean_cache" = "Y" ]; then
        rm -rf /var/cache/opkg/*
        echo "已清理软件包缓存"
    fi
    
    echo "清理完成"
}
```

### 示例 2：备份插件
```bash
#!/bin/bash
# PLUGIN_NAME="配置备份"
# PLUGIN_VERSION="1.0.0"
# PLUGIN_DESC="备份 OpenWrt 配置文件"
# PLUGIN_AUTHOR="OpenWrt Helper"

plugin_main() {
    echo "=== 配置备份 ==="
    echo
    
    BACKUP_DIR="/mnt/sda1/backups"
    BACKUP_FILE="$BACKUP_DIR/config-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    echo "正在备份配置文件..."
    tar -czf "$BACKUP_FILE" /etc/config/ 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "备份成功：$BACKUP_FILE"
    else
        echo "备份失败"
    fi
}
```

## 注意事项

1. **兼容性**：确保插件兼容 BusyBox ash 和 Bash
2. **资源占用**：避免在资源受限设备上运行高负载任务
3. **安全性**：不要执行危险操作，如删除系统文件
4. **错误处理**：始终检查命令执行结果
5. **用户确认**：执行修改操作前获得用户确认

## 插件发布

如果您开发了有用的插件，可以：

1. 发布到 GitHub
2. 分享到 OpenWrt 论坛
3. 提交到主脚本仓库

## 技术支持

遇到问题？

- 查看主脚本日志
- 检查插件语法：`bash -n plugin.sh`
- 调试模式运行：`bash -x plugin.sh`
