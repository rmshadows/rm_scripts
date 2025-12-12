#!/bin/bash
# 用法：
#   ./xrandrBrightnessControl.sh [功能] [可选:输出名]
#   功能：0 减亮度  1 增亮度  2 重置亮度
# 示例：
#   ./xrandrBrightnessControl.sh 0
#   ./xrandrBrightnessControl.sh 1 HDMI-A-0

# 增亮步长（减亮是两倍）
bstep=0.05
# 限制亮度范围
min=0.10
max=1.00

# 1. 选输出 ------------------------------------------

# 如果用户手动指定了输出名（第二个参数），优先用它
if [ -n "$2" ]; then
    odn="$2"
else
    # 否则：优先用 HDMI-A-0（如果是 connected）
    if xrandr | grep -q "^HDMI-A-0 connected"; then
        odn="HDMI-A-0"
    else
        # 再否则：找第一个真正 connected 的输出
        odn=$(xrandr | awk '/ connected/ && $2 != "disconnected" {print $1; exit}')
    fi
fi

if [ -z "$odn" ]; then
    echo "未找到已连接的输出，请检查 xrandr 输出。"
    exit 1
fi

# 2. 获取当前亮度（针对这个输出） -----------------------

bsrc=$(xrandr --verbose --current | awk -v out="$odn" '
    $1 == out { inout=1 }
    inout && /Brightness:/ { print $2; exit }
')

# 没取到就假设 1.0
if [ -z "$bsrc" ]; then
    bsrc=1.0
fi

# 3. 按参数决定如何调整 -------------------------------

case "$1" in
    0)
        # 减亮度：两倍步长
        bdst=$(echo "$bsrc - $bstep * 2" | bc -l)
        # 下限保护
        if [ "$(echo "$bdst < $min" | bc)" -eq 1 ]; then
            bdst=$min
        fi
        echo "减少亮度：$bsrc -> $bdst"
        ;;
    1)
        # 增亮度：一步步长
        bdst=$(echo "$bsrc + $bstep" | bc -l)
        # 上限保护
        if [ "$(echo "$bdst > $max" | bc)" -eq 1 ]; then
            bdst=$max
        fi
        echo "增加亮度：$bsrc -> $bdst"
        ;;
    2)
        bdst=$max
        echo "重置亮度：$bsrc -> $bdst"
        ;;
    ""|*)
        # 没给合法参数，就显示当前状态
        echo "当前输出：$odn  Brightness: $bsrc"
        exit 0
        ;;
esac

echo "xrandr --output $odn --brightness $bdst"
xrandr --output "$odn" --brightness "$bdst"

