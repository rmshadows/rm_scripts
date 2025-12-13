#!/bin/bash
# 调整亮度 用法：$ 脚本.sh 【功能：0: 减亮度 1:增亮度 2:重置亮度】
# https://wiki.archlinuxcn.org/wiki/%E8%83%8C%E5%85%89
# https://ubuntukylin.com/news/1763-cn.html

# Manual 增亮步长 (减亮是两倍！)
bstep=5

# 有这个文件就不会检查
# 获取脚本所在文件夹路径
script_dir=$(dirname "$0")
dcf="$script_dir/ddcCheck.log"
# echo "$dcf"

# 检查显示设置
function checkDisplay() {
    # 获取显示设备(可能有多个，多个会退出)
    # 运行sudo ddcutil detect并将输出保存到变量detect_output中
    detect_output=$(sudo ddcutil detect)
    # 使用grep命令来检查输出中包含的显示器数量
    display_count=$(echo "$detect_output" | grep -c "Display")
    # 输出显示器数量
    echo "检测到 $display_count 个连接的显示器。"
    # 如果显示器数量大于1，则给出相应的提示
    if [ "$display_count" -gt 1 ]; then
        echo "注意：检测到多个显示器连接，请手动修改脚本内容以适配。"
        exit 1
    fi

    # 检查是否有亮度调节功能
    # 检测是否有 Feature: 10
    capabilities_output=$(sudo ddcutil capabilities)
    if echo "$capabilities_output" | grep -q "Feature: 10"; then
        echo "Feature: 10 存在。"
        if echo "$capabilities_output" | grep "Feature: 10" | grep -q "Brightness"; then
            echo "Feature: 10 可能是亮度调节。"
            echo "0" > "$dcf"
        else
            echo "Feature: 10 可能不是亮度调节，请检查！"
            exit 2
        fi
    else
        echo "Feature: 10 不存在，请检查！"
        exit 2
    fi
}

if ! [ -f "$dcf" ];then
    # 有问题会直接退出
    echo "检查环境。。。"
    checkDisplay
fi

if echo "$1" | grep -q "^[0-9]*$"; then
    # 如果有给参数 且为数字
    if [ "$1" == "" ]; then
        # 获取初始亮度
        initial_brightness=$(sudo ddcutil getvcp 10 | grep "current value" | awk '{print $NF}')
        # 默认显示当前信息
        echo "当前亮度（current value）为: $initial_brightness"
    elif [ "$1" -eq 0 ]; then
        # bdst=$(echo "$initial_brightness - $bstep" | bc)
        # echo "减少亮度：$initial_brightness -> $bdst"
        sudo ddcutil setvcp 10 - "$bstep"
    elif [ "$1" -eq 1 ]; then
        # bdst=$(echo "$initial_brightness + $bstep" | bc)
        # echo "增加亮度：$initial_brightness -> $bdst"
        sudo ddcutil setvcp 10 + "$bstep"
    elif [ "$1" -eq 2 ]; then
        echo "重置亮度：100"
        sudo ddcutil setvcp 10 100
    elif [ "$1" -eq 3 ]; then
        echo "重置脚本。"
        if [ -f "$dcf" ];then
            rm "$dcf"
        fi
    else
        # 默认显示当前信息
        # 获取初始亮度
        initial_brightness=$(sudo ddcutil getvcp 10 | grep "current value" | awk '{print $NF}')
        echo "当前亮度（current value）为: $initial_brightness"
    fi
else
    # 获取初始亮度
    initial_brightness=$(sudo ddcutil getvcp 10 | grep "current value" | awk '{print $NF}')
    # 默认显示当前信息
    echo "当前亮度（current value）为: $initial_brightness"
fi
