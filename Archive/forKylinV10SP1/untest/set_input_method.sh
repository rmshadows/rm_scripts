#!/bin/bash
# 设置输入法环境变量：GTK/QT/XMODIFIERS
# 支持 /etc/environment（全局）和 ~/.xprofile（用户）

set -e

# ---- 全局环境变量 ----
ENV_FILE="/etc/environment"

# 需要添加/修改的变量
declare -A env_vars=(
  ["GTK_IM_MODULE"]="fcitx"
  ["QT_IM_MODULE"]="fcitx"
  ["XMODIFIERS"]="@im=fcitx"
)

echo "正在修改 $ENV_FILE …"

# 逐个变量检查，如果不存在就添加，如果存在就替换
for key in "${!env_vars[@]}"; do
    if grep -q "^$key=" "$ENV_FILE"; then
        sudo sed -i "s|^$key=.*|$key=${env_vars[$key]}|" "$ENV_FILE"
        echo "已更新 $key=${env_vars[$key]}"
    else
        echo "$key=${env_vars[$key]}" | sudo tee -a "$ENV_FILE" > /dev/null
        echo "已添加 $key=${env_vars[$key]}"
    fi
done

echo "/etc/environment 设置完成。"

# ---- 用户 ~/.xprofile ----
XPROFILE="$HOME/.xprofile"
echo "正在修改 $XPROFILE …"

for key in "${!env_vars[@]}"; do
    # 如果文件中已有 export 行，替换；否则追加
    if grep -q "^export $key=" "$XPROFILE" 2>/dev/null; then
        sed -i "s|^export $key=.*|export $key=${env_vars[$key]}|" "$XPROFILE"
        echo "已更新 export $key=${env_vars[$key]}"
    else
        echo "export $key=${env_vars[$key]}" >> "$XPROFILE"
        echo "已添加 export $key=${env_vars[$key]}"
    fi
done

echo "~/.xprofile 设置完成。请重新登录或 source ~/.xprofile 使其生效。"
