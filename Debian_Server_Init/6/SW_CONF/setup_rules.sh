#!/bin/bash
# sw-rules：从 /etc/shorewall/crules 选一份模板覆盖 /etc/shorewall/rules
# 安装后：sudo sw-rules

set -euo pipefail

CRULES_DIR="/etc/shorewall/crules"
RULE_FILE="/etc/shorewall/rules"
LAST_FILE="/etc/shorewall/last"

if [ "$EUID" -ne 0 ]; then
    echo "请用 sudo 运行: sudo sw-rules"
    exit 1
fi

if [ ! -d "$CRULES_DIR" ]; then
    echo "错误: $CRULES_DIR 不存在。"
    exit 1
fi

mapfile -t FILES < <(find "$CRULES_DIR" -maxdepth 1 -type f ! -name 'README.txt' ! -name 'backup_*' -printf '%f\n' | sort)
if [ ${#FILES[@]} -eq 0 ]; then
    echo "错误: $CRULES_DIR 里没有模板。"
    exit 1
fi

if [ -f "$LAST_FILE" ]; then
    LAST_SELECTED_FILE=$(cat "$LAST_FILE")
else
    LAST_SELECTED_FILE=""
fi

if [ -n "$LAST_SELECTED_FILE" ] && [ -f "$CRULES_DIR/$LAST_SELECTED_FILE" ]; then
    echo "上次模板: $LAST_SELECTED_FILE"
    read -r -p "把当前 rules 写回该模板？(y/N) " RESTORE_CHOICE
    if [[ "$RESTORE_CHOICE" =~ ^[Yy]$ ]]; then
        cp "$RULE_FILE" "$CRULES_DIR/$LAST_SELECTED_FILE"
        echo "已同步 $RULE_FILE → crules/$LAST_SELECTED_FILE"
    fi
fi

echo
echo "模板（覆盖 /etc/shorewall/rules）："
for i in "${!FILES[@]}"; do
    name=$(sed -n '1s/^# 模板：//p' "$CRULES_DIR/${FILES[$i]}")
    blurb=$(sed -n '2s/^# //p' "$CRULES_DIR/${FILES[$i]}")
    echo "  $((i + 1))) ${name:-${FILES[$i]}}    $blurb"
done
echo
read -r -p "输入编号: " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#FILES[@]} ]; then
    echo "错误: 无效编号。"
    exit 1
fi

SELECTED_FILE="${FILES[$((CHOICE - 1))]}"

if [ -f "$RULE_FILE" ]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="${CRULES_DIR}/backup_${TIMESTAMP}_rules"
    cp "$RULE_FILE" "$BACKUP_FILE"
    echo "已备份当前 rules → $BACKUP_FILE"
fi

cp "$CRULES_DIR/$SELECTED_FILE" "$RULE_FILE"
echo "$SELECTED_FILE" > "$LAST_FILE"

echo
echo "已套用: $SELECTED_FILE → $RULE_FILE"
echo "按需编辑（取消注释即可）: sudo nano $RULE_FILE"
echo "检查并重载: sudo shorewall check && sudo shorewall reload"
echo "尚未启用时: sudo systemctl enable --now shorewall"
