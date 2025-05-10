#!/bin/bash
# ======== 配置区域 ========
# 可选值: builtin / system / custom
DISLOCKER_MODE="system"
# DISLOCKER_MODE="custom"
CUSTOM_DISLOCKER_PATH="./amd64/dislocker"  # 如果选择 custom，这里填路径
NEED_DISLOCKER=0  # 是否强制依赖 dislocker（设为 1 表示必须有）

# ======== 选择 dislocker 实际路径 ========
resolve_dislocker() {
    case "$DISLOCKER_MODE" in
        builtin)
            DISLOCKER_PATH="./UOS-arm64/dislocker"
            ;;
        system)
            DISLOCKER_PATH="$(command -v dislocker)"
            ;;
        custom)
            DISLOCKER_PATH="$CUSTOM_DISLOCKER_PATH"
            ;;
        *)
            echo "❌ 无效的 DISLOCKER_MODE 设置：$DISLOCKER_MODE"
            exit 1
            ;;
    esac
}

# ======== 检查 dislocker 是否可用 ========
check_dislocker() {
    echo "🔍 检查 dislocker..."

    resolve_dislocker

    if [[ -x "$DISLOCKER_PATH" ]]; then
        echo "✅ 使用 dislocker：$DISLOCKER_PATH"
        return 0
    fi

    echo "⚠️ 找不到有效的 dislocker（路径：$DISLOCKER_PATH）"

    if [[ "$DISLOCKER_MODE" == "system" ]]; then
        read -p "是否尝试通过 apt 安装 dislocker？(y/N): " install_choice
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            sudo apt update && sudo apt install -y dislocker
            DISLOCKER_PATH="$(command -v dislocker)"
            if [[ -x "$DISLOCKER_PATH" ]]; then
                echo "✅ 安装并检测到 dislocker：$DISLOCKER_PATH"
                return 0
            fi
        fi
    fi

    if [[ $NEED_DISLOCKER -eq 1 ]]; then
        echo "❌ dislocker 是必须项，脚本退出。"
        exit 1
    else
        echo "ℹ️ 跳过 dislocker，继续脚本流程。"
    fi
}

# ===== 挂载点选择 =====
select_mount_point() {
    echo "🔍 正在列出挂载中的外部设备..."
    MOUNT_POINTS=$(lsblk -rpo NAME,MOUNTPOINT | grep -v "^loop" | awk '$2!="" {print $1, $2}')

    if [[ -z "$MOUNT_POINTS" ]]; then
        echo "⚠️ 未检测到任何挂载设备。"
        exit 1
    fi

    echo "📂 请选择要检查的挂载点："
    select ENTRY in $MOUNT_POINTS; do
        if [[ -n "$ENTRY" ]]; then
            DEVICE=$(echo "$ENTRY" | awk '{print $1}')
            MOUNT_POINT=$(echo "$ENTRY" | awk '{print $2}')
            echo "✅ 你选择了 $DEVICE ($MOUNT_POINT)"
            break
        else
            echo "⚠️ 请输入有效编号。"
        fi
    done
}

# ===== 检查进程占用 =====
check_and_kill_processes() {
    echo -e "\n=== 使用 lsof 检测占用 ==="
    lsof +f -- "$MOUNT_POINT" 2>/dev/null || true

    echo -e "\n=== 使用 fuser 检测占用 ==="
    fuser -vm "$MOUNT_POINT" || true

    PIDS=$(fuser "$MOUNT_POINT" 2>/dev/null)

    if [[ -z "$PIDS" ]]; then
        echo "🎉 没有程序占用，准备卸载..."
    else
        echo -e "\n⚠️ 以下进程正在使用该磁盘："
        ps -fp $PIDS
        read -p "是否强制杀死这些进程？(y/N): " kill_choice
        if [[ "$kill_choice" =~ ^[Yy]$ ]]; then
            echo "⚠️ 正在强制杀死进程..."
            sudo kill -9 $PIDS
        else
            echo "❌ 未杀死占用进程，不能安全卸载。"
            exit 1
        fi
    fi
}

# ===== 卸载磁盘 =====
unmount_disk() {
    read -p "是否现在卸载该磁盘？(y/N): " unmount_choice
    if [[ "$unmount_choice" =~ ^[Yy]$ ]]; then
        echo "📤 正在卸载..."
        if sudo umount "$MOUNT_POINT"; then
            echo "✅ 卸载成功！"
        else
            echo "❌ 卸载失败，请检查。"
        fi
    else
        echo "ℹ️ 未执行卸载操作。"
    fi
}

# ===== 主流程 =====
check_dislocker
select_mount_point
check_and_kill_processes
unmount_disk

