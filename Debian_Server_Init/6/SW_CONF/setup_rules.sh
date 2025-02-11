#!/bin/bash
# 脚本名称: setup_rules.sh
# 需要管理员权限!
# 功能: 从 crules 目录读取文件供用户选择，然后将所选文件复制到 rules 文件，覆盖原有文件

CRULES_DIR="/etc/shorewall/crules"  # 存放配置文件的目录
RULE_FILE="/etc/shorewall/rules"     # 目标文件
LAST_FILE="/etc/shorewall/last"      # 存储上次使用的配置文件

# 检查是否具有管理员权限
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用管理员权限运行此脚本 (sudo)。"
    exit 1
fi

# 检查 crules 目录是否存在
if [ ! -d "$CRULES_DIR" ]; then
    echo "错误: $CRULES_DIR 目录不存在。"
    exit 1
fi

# 检查 last 文件是否存在并读取内容
if [ -f "$LAST_FILE" ]; then
    LAST_SELECTED_FILE=$(cat "$LAST_FILE")
else
    LAST_SELECTED_FILE=""
fi

# 如果上次选择的配置文件存在，提示用户恢复该文件
if [ -n "$LAST_SELECTED_FILE" ] && [ -f "$CRULES_DIR/$LAST_SELECTED_FILE" ]; then
    echo "上次使用的配置文件是: $LAST_SELECTED_FILE"
    read -p "是否同步上次的配置文件? (y/n): " RESTORE_CHOICE
    if [[ "$RESTORE_CHOICE" =~ ^[Yy]$ ]]; then
        cp "$RULE_FILE" "$CRULES_DIR/$LAST_SELECTED_FILE"
        echo "已同步 $RULE_FILE 到 $LAST_SELECTED_FILE。"
    fi
fi

# 列出 crules 目录中的文件
FILES=($(ls -1 "$CRULES_DIR"))
if [ ${#FILES[@]} -eq 0 ]; then
    echo "错误: $CRULES_DIR 目录中没有任何文件。"
    exit 1
fi

# 显示文件列表供用户选择
echo "可用的配置文件："
for i in "${!FILES[@]}"; do
    echo "$((i + 1))) ${FILES[$i]}"
done

# 提示用户选择
read -p "请输入要选择的文件编号: " CHOICE

# 校验用户输入
if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#FILES[@]} ]; then
    echo "错误: 无效的选择。"
    exit 1
fi

# 获取用户选择的文件名
SELECTED_FILE="${FILES[$((CHOICE - 1))]}"

# 如果没有上次配置文件，则备份当前规则文件
if [ ! -f "$LAST_FILE" ] && [ -f "$RULE_FILE" ]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="${CRULES_DIR}/backup_${TIMESTAMP}_rules"
    cp "$RULE_FILE" "$BACKUP_FILE"
    echo "没有上次配置文件，已将当前规则备份到 $BACKUP_FILE"
fi

# 复制文件覆盖 rules
echo "注意: $RULE_FILE 将被覆盖。"
cp "$CRULES_DIR/$SELECTED_FILE" "$RULE_FILE"

# 记录此次选择的配置文件到 last 文件
echo "$SELECTED_FILE" > "$LAST_FILE"

echo "已将 $SELECTED_FILE 复制到 $RULE_FILE，并记录在 $LAST_FILE 中。"
