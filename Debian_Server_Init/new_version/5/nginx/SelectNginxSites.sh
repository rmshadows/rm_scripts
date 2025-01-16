#!/bin/bash
# 脚本名称: nginx_site_manager.sh
# 需要管理员权限!
# 功能: 从 sites-available 目录读取网站配置文件，用户选择启用（建立符号链接）或禁用（删除符号链接）网站，查看已启用的网站。

AVAILABLE_DIR="/etc/nginx/sites-available"  # 存放网站配置文件的目录
ENABLED_DIR="/etc/nginx/sites-enabled"      # 存放启用网站配置文件的符号链接目录

# 检查是否具有管理员权限
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用管理员权限运行此脚本 (sudo)。"
    exit 1
fi

# 检查 sites-available 目录是否存在
if [ ! -d "$AVAILABLE_DIR" ]; then
    echo "错误: $AVAILABLE_DIR 目录不存在。"
    exit 1
fi

# 列出 sites-available 目录中的文件
FILES=($(ls -1 "$AVAILABLE_DIR"))
if [ ${#FILES[@]} -eq 0 ]; then
    echo "错误: $AVAILABLE_DIR 目录中没有任何网站配置文件。"
    exit 1
fi

# 显示可用网站配置文件列表供用户选择
echo "可用的配置文件："
for i in "${!FILES[@]}"; do
    echo "$((i + 1))) ${FILES[$i]}"
done

# 主菜单函数
function main_menu {
    # 提示用户选择操作
    echo "选择操作:"
    echo "1. 启用网站"
    echo "2. 禁用网站"
    echo "3. 查看已启用的网站"
    echo "4. 退出"

    read -p "请输入操作编号: " ACTION

    # 校验用户输入
    if ! [[ "$ACTION" =~ ^[1-4]$ ]]; then
        echo "错误: 无效的选择。"
        return
    fi

    # 处理启用、禁用或查看已启用网站
    case "$ACTION" in
        1)  # 启用网站
            # 提示用户选择要启用的配置文件
            read -p "请输入要启用的配置文件编号: " CHOICE

            if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#FILES[@]} ]; then
                echo "错误: 无效的选择。"
                return
            fi

            SELECTED_FILE="${FILES[$((CHOICE - 1))]}"

            # 创建符号链接
            if [ -e "$ENABLED_DIR/$SELECTED_FILE" ]; then
                echo "该网站已启用，无需再次启用。"
            else
                ln -s "$AVAILABLE_DIR/$SELECTED_FILE" "$ENABLED_DIR/$SELECTED_FILE"
                echo "已启用网站：$SELECTED_FILE"
                # 重新加载 Nginx 配置
                nginx -s reload
            fi
            ;;
        
        2)  # 禁用网站
            # 列出已启用的站点
            ENABLED_FILES=($(ls -1 "$ENABLED_DIR"))
            if [ ${#ENABLED_FILES[@]} -eq 0 ]; then
                echo "错误: 当前没有启用的网站。"
                return
            fi

            echo "已启用的网站配置文件："
            for i in "${!ENABLED_FILES[@]}"; do
                echo "$((i + 1))) ${ENABLED_FILES[$i]}"
            done

            # 提示用户选择要禁用的配置文件
            read -p "请输入要禁用的配置文件编号: " CHOICE

            if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#ENABLED_FILES[@]} ]; then
                echo "错误: 无效的选择。"
                return
            fi

            SELECTED_FILE="${ENABLED_FILES[$((CHOICE - 1))]}"

            # 删除符号链接
            rm -f "$ENABLED_DIR/$SELECTED_FILE"
            echo "已禁用网站：$SELECTED_FILE"
            # 重新加载 Nginx 配置
            nginx -s reload
            ;;
        
        3)  # 查看已启用的网站
            # 列出已启用的网站配置文件
            ENABLED_FILES=($(ls -1 "$ENABLED_DIR"))
            if [ ${#ENABLED_FILES[@]} -eq 0 ]; then
                echo "当前没有启用的网站。"
            else
                echo "已启用的网站配置文件："
                for i in "${!ENABLED_FILES[@]}"; do
                    echo "$((i + 1))) ${ENABLED_FILES[$i]}"
                done
            fi
            # 返回主菜单
            main_menu
            ;;
        
        4)  # 退出
            echo "退出程序。"
            exit 0
            ;;
        
        *)
            echo "错误: 无效的选择。"
            return
            ;;
    esac
}

# 初始化并调用主菜单
main_menu

