#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/config.sh"

DEFAULT_MOUNT_POINT="$readMount"

get_mount_points() {
    awk '
    $2 ~ "^/" &&
    $3 !~ /^(tmpfs|devtmpfs|proc|sysfs|cgroup|overlay|squashfs|autofs|fuse.gvfsd-fuse|binfmt_misc)$/ &&
    $1 !~ /^(none|tmpfs|cgroup|gvfsd-fuse)$/ {
        print $2
    }' /proc/mounts | sort -u
}

mapfile -t MOUNT_LIST < <(get_mount_points)

echo "当前挂载的设备："
echo "------------------------------------------"
for i in "${!MOUNT_LIST[@]}"; do
    printf "%2d)\t%s\n" "$((i + 1))" "${MOUNT_LIST[$i]}"
done
echo " 0) 使用默认挂载点 [$DEFAULT_MOUNT_POINT]"

echo
read -p "请选择挂载点编号 (0-${#MOUNT_LIST[@]}): " sel

if [[ "$sel" =~ ^[0-9]+$ && "$sel" -ge 1 && "$sel" -le ${#MOUNT_LIST[@]} ]]; then
    MOUNT_POINT="${MOUNT_LIST[$((sel - 1))]}"
elif [[ "$sel" == "0" || -z "$sel" ]]; then
    MOUNT_POINT="$DEFAULT_MOUNT_POINT"
else
    echo "无效选择，退出。" >&2
    exit 1
fi

echo
echo "正在检查是否有进程占用挂载点：$MOUNT_POINT"
echo "------------------------------------------"

if ! command -v lsof >/dev/null 2>&1; then
    echo "请先安装 lsof：sudo apt install lsof"
    exit 1
fi

if sudo lsof +f -- "$MOUNT_POINT"; then
    echo "上述进程正在使用 $MOUNT_POINT，请先关闭或结束它们再卸载。"
else
    echo "没有进程占用 $MOUNT_POINT，可以卸载。"
fi
