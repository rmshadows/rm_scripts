#!/bin/bash

# ======== 配置区域 ========
DEFAULT_MOUNT_POINT="/media/bitlockermount"
DISLOCKER_MODE="${1:-system}"  # 可选参数 system/manual/auto
CUSTOM_DISLOCKER_PATH="./amd64/dislocker"
NEED_DISLOCKER=0

# 仅筛选实际设备挂载点（排除系统、虚拟挂载）
echo "当前挂载的设备："
echo "------------------------------------------"
mount | grep -E '^/dev/' | awk '{print $3}' | nl -w2 -s'	'

# 获取挂载点列表（过滤虚拟文件系统）
MOUNT_LIST=($(mount | grep -E '^/dev/' | awk '{print $3}'))

echo "0) 使用默认挂载点 [$DEFAULT_MOUNT_POINT]"
echo
read -p "请选择挂载点编号 (0-${#MOUNT_LIST[@]}): " sel

if [[ "$sel" =~ ^[0-9]+$ && "$sel" -ge 1 && "$sel" -le ${#MOUNT_LIST[@]} ]]; then
    MOUNT_POINT="${MOUNT_LIST[$((sel - 1))]}"
elif [[ "$sel" == "0" || -z "$sel" ]]; then
    MOUNT_POINT="$DEFAULT_MOUNT_POINT"
else
    echo "❌ 无效选择，退出。" >&2
    exit 1
fi

echo
echo "🔍 正在检查是否有进程占用挂载点：$MOUNT_POINT"
echo "------------------------------------------"

# 检查是否安装 lsof
if ! command -v lsof &>/dev/null; then
    echo "请先安装 lsof：sudo apt install lsof"
    exit 1
fi

# 查找占用挂载点的进程
if sudo lsof +f -- "$MOUNT_POINT"; then
    echo "⚠️ 上述进程正在使用 $MOUNT_POINT，请先关闭或杀掉再卸载。"
else
    echo "✅ 没有进程占用 $MOUNT_POINT，可以安全卸载。"
fi

# ==================== dislocker 模式提示 ====================
echo
echo "🔧 当前 dislocker 模式：$DISLOCKER_MODE"
if [[ "$DISLOCKER_MODE" == "manual" ]]; then
    echo "使用手动模式，路径：$CUSTOM_DISLOCKER_PATH"
elif [[ "$DISLOCKER_MODE" == "system" ]]; then
    echo "使用系统默认 dislocker"
else
    echo "未知模式，可能出错，请检查参数。"
fi

