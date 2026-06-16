#!/bin/bash
# ==========================================
# alternatives 管理脚本
# ==========================================
# 用途：
#   这个脚本用于管理 Linux 系统上的 "alternatives" 系统，
#   可以查看、添加或删除某个软件的替代项（alternatives）。
#
# 使用方法：
#   1. 运行脚本：
#        sudo ./alternatives-manager.sh
#   2. 按提示输入要管理的软件名称，例如：
#        java
#   3. 在菜单中选择操作：
#        1) 查看当前 alternatives
#        2) 添加新的 alternative
#        3) 删除已有 alternative
#        4) 退出
#
# 示例：
#   假设你要管理 java 的替代项：
#     Enter the name of the software you want to manage (e.g., java, editor, etc.):
#     java
#   然后选择 1、2 或 3 来查看、添加或删除 java 的 alternative。
# ==========================================


# 显示帮助信息
function show_help {
    echo "Usage: $0"
    echo "This script allows you to manage 'alternatives' for software on your system."
    echo "You can view the current configuration, add new alternatives, or remove existing ones."
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
}

# 显示当前的 alternatives 配置
function show_current_alternatives {
    local software=$1
    echo "Displaying current alternatives for $software..."
    sudo update-alternatives --display $software
}

# 添加替代项
function add_alternative {
    local software=$1
    echo "Enter the full path of the binary to add for $software:"
    read binary_path
    echo "Enter the priority (higher number means higher priority):"
    read priority

    # 添加替代项
    sudo update-alternatives --install /usr/bin/$software $software $binary_path $priority
    echo "$software alternative has been added successfully."
}

# 删除替代项
function remove_alternative {
    local software=$1
    echo "Enter the alternative path to remove for $software:"
    read binary_path

    # 删除替代项
    sudo update-alternatives --remove $software $binary_path
    echo "$binary_path has been removed from $software alternatives."
}

# 主菜单
function main_menu {
    echo "-----------------------------------"
    echo "Welcome to the alternatives manager"
    echo "-----------------------------------"
    echo "Enter the name of the software you want to manage (e.g., java, editor, etc.):"
    read software

    while true; do
        echo
        echo "What would you like to do?"
        echo "1) Show current alternatives for $software"
        echo "2) Add a new alternative for $software"
        echo "3) Remove an existing alternative for $software"
        echo "4) Exit"
        read -p "Choose an option (1-4): " choice

        case $choice in
            1)
                show_current_alternatives $software
                ;;
            2)
                add_alternative $software
                ;;
            3)
                remove_alternative $software
                ;;
            4)
                echo "Exiting..."
                break
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
}

# 检查是否有 sudo 权限
if sudo -v &>/dev/null; then
    main_menu
else
    echo "This script requires sudo privileges. Please run it with sudo."
    exit 1
fi
