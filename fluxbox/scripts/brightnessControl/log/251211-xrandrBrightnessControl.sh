#!/bin/bash
# reset: xrandr --output HDMI-A-0 --brightness 1.0
# 调整亮度 用法：$ 脚本.sh 【功能：0: 减亮度 1:增亮度 2:重置亮度】

# Manual 增亮步长 (减亮是两倍！)
bstep=0.05
# 得到初始亮度 Brightness: 1.0
bsrc=`xrandr --verbose | grep Brightness | xargs`
# echo "$bsrc"
tmpArr=($(echo $bsrc | tr ":" "\n"))
# 得到亮度数值 1.0
bsrc=`echo "${tmpArr[1]}" | xargs`
# echo "$bsrc"
# 获取显示设备(可能有多个，默认一个) HDMI-A-0
odn=`xrandr --verbose | grep "connected primary" | xargs -n 1`
# HDMI-A-0
odn=`echo "$odn" | head -n 1`
# echo "$odn"
if echo "$1" | grep -q "^[0-9]*$"; then
    # 如果有给参数 且为数字
    if [ "$1" == "" ];then
        # 默认显示当前信息
        echo "Default: $odn  Brightness: $bsrc"
    elif [ "$1" -eq 0 ];then
        bdst=`echo "$bsrc - $bstep * 2" | bc`
        echo "减少亮度：$bsrc -> $bdst"
        echo "xrandr --output "$odn" --brightness "$bdst""
        xrandr --output "$odn" --brightness "$bdst"
    elif [ "$1" -eq 1 ];then
        bdst=`echo "$bsrc + $bstep" | bc` 
        echo "增加亮度：$bsrc -> $bdst"
        echo "xrandr --output "$odn" --brightness "$bdst""
        xrandr --output "$odn" --brightness "$bdst"
    elif [ "$1" -eq 2 ];then
        echo "重置亮度：1.0"
        xrandr --output "$odn" --brightness 1.0
    else
        # 默认显示当前信息
        echo "Default: $odn  Brightness: $bsrc"
    fi
else
    # 默认显示当前信息
    echo "Default: $odn  Brightness: $bsrc"
fi

