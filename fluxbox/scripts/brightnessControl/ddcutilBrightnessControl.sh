#!/bin/bash
# 调整亮度 用法：脚本.sh 【功能：0:减亮度 1:增亮度 2:重置亮度 3:重置检测】
# 依赖：ddcutil（需要 root 权限）

# 每次调节的步长（0–100 之间）
bstep=10

# 获取脚本所在目录（绝对路径）
script_dir="$(cd "$(dirname "$0")" && pwd)"
dcf="$script_dir/ddcCheck.log"

# --------- 工具函数 ----------

die() {
    echo "$*" >&2
    exit 1
}

get_brightness() {
    sudo ddcutil getvcp 10 \
        | grep "current value" \
        | awk '{print $NF}'
}

checkDisplay() {
    echo "检查显示环境..."

    # 1. 检查 ddcutil 是否存在
    command -v ddcutil >/dev/null 2>&1 || die "ddcutil 未安装，请先安装 ddcutil"

    # 2. 检测显示器数量
    detect_output=$(sudo ddcutil detect)
    display_count=$(echo "$detect_output" | grep -c "Display")

    echo "检测到 $display_count 个连接的显示器。"
    if [ "$display_count" -gt 1 ]; then
        echo "注意：检测到多个显示器，请手动修改脚本适配具体显示器。"
        exit 1
    elif [ "$display_count" -eq 0 ]; then
        die "未检测到支持 DDC 的显示器。"
    fi

    # 3. 检查是否支持亮度调节（VCP code 10）
    capabilities_output=$(sudo ddcutil capabilities)
    if echo "$capabilities_output" | grep -q "Feature: 10"; then
        if echo "$capabilities_output" | grep "Feature: 10" | grep -q "Brightness"; then
            echo "已检测到 VCP 10 (Brightness)，环境 OK。"
            echo "ok" > "$dcf"
        else
            die "Feature: 10 存在，但似乎不是 Brightness，请检查显示器能力。"
        fi
    else
        die "不支持 Feature: 10 (亮度调节)，请检查显示器或连接方式。"
    fi
}

# --------- 主逻辑开始 ----------

# 首次运行做环境检查（有问题直接退出）
if [ ! -f "$dcf" ]; then
    checkDisplay
fi

# 读取参数（默认是空）
action="$1"

case "$action" in
    0)
        # 减亮度
        echo "减少亮度：-$bstep"
        sudo ddcutil setvcp 10 - "$bstep"
        ;;
    1)
        # 增亮度
        echo "增加亮度：+$bstep"
        sudo ddcutil setvcp 10 + "$bstep"
        ;;
    2)
        # 重置亮度到 100
        echo "重置亮度为 100"
        sudo ddcutil setvcp 10 100
        ;;
    3)
        # 删除检测标记文件，下次重跑会重新检查环境
        echo "重置脚本检测状态（删除 $dcf）"
        [ -f "$dcf" ] && rm -f "$dcf"
        ;;
    ""|*)
        # 不给或给了其他参数：显示当前亮度
        current=$(get_brightness)
        echo "当前亮度（current value）为: $current"
        ;;
esac

