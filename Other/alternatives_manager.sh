#!/bin/bash

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
