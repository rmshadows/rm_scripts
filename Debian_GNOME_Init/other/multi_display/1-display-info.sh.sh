#!/bin/bash
# ===============================
# 显示多屏信息 + 列出共同分辨率
# ===============================

echo "🔍 正在检测显示器信息..."
echo

# 保存当前配置
BACKUP_FILE="$HOME/.xrandr_backup.txt"

echo "💾 记录当前显示配置到 $BACKUP_FILE ..."
xrandr --query > "$BACKUP_FILE"
echo "✅ 备份完成"

xrandr --listmonitors

# 获取全部连接的显示器名称
DISPLAYS=($(xrandr --query | grep " connected" | awk '{print $1}'))

if [ ${#DISPLAYS[@]} -eq 0 ]; then
    echo "❌ 未检测到任何显示器！"
    exit 1
fi

echo "✅ 检测到 ${#DISPLAYS[@]} 个显示器："
for d in "${DISPLAYS[@]}"; do
    echo "  - $d"
done
echo

# 列出每个显示器的支持分辨率
declare -A DISP_MODES
for d in "${DISPLAYS[@]}"; do
    echo "📺 $d 支持的分辨率："
    MODES=($(xrandr | awk -v D="$d" '
        $0 ~ D" connected" {p=1; next}
        /^[^ ]/ {p=0}
        p && $1 ~ /^[0-9]+x[0-9]+$/ {print $1}
    '))
    DISP_MODES["$d"]="${MODES[*]}"
    echo "  ${MODES[*]}"
    echo
done

# 计算共同分辨率
echo "🧮 正在计算共同支持的分辨率..."
COMMON=()
for d in "${!DISP_MODES[@]}"; do
    if [ ${#COMMON[@]} -eq 0 ]; then
        COMMON=(${DISP_MODES["$d"]})
    else
        TMP=()
        for m in ${DISP_MODES["$d"]}; do
            for c in ${COMMON[@]}; do
                if [ "$m" == "$c" ]; then
                    TMP+=("$m")
                fi
            done
        done
        COMMON=("${TMP[@]}")
    fi
done

if [ ${#COMMON[@]} -eq 0 ]; then
    echo "⚠️ 没有找到所有显示器都支持的共同分辨率。"
else
    echo "✅ 所有显示器共同支持的分辨率："
    for c in "${COMMON[@]}"; do
        echo "  - $c"
    done
fi

