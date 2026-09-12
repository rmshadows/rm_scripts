#!/bin/bash
# ngx-site：启用 / 禁用 /etc/nginx/sites-available 里的站点。
# 本脚本部署后安装为 /usr/local/bin/ngx-site
#
# 本仓库约定：
#   acme.conf  80  — ACME 校验 + 测试页（默认已启用，续期需要，不要关）
#   ssl.conf   443 — 正式站点（证书好了再启用）
#
# 用法: sudo ngx-site

AVAILABLE_DIR="/etc/nginx/sites-available"
ENABLED_DIR="/etc/nginx/sites-enabled"

if [ "$EUID" -ne 0 ]; then
    echo "请用 sudo 运行: sudo ngx-site"
    exit 1
fi

if [ ! -d "$AVAILABLE_DIR" ]; then
    echo "没有 $AVAILABLE_DIR"
    exit 1
fi

echo
echo "约定：acme.conf = 80（ACME，默认开着）；ssl.conf = 443（正式站，证书后再开）"
echo

mapfile -t FILES < <(ls -1 "$AVAILABLE_DIR" | grep -v '^README')
if [ "${#FILES[@]}" -eq 0 ]; then
    echo "$AVAILABLE_DIR 是空的"
    exit 1
fi

enabled_mark() {
    if [ -e "$ENABLED_DIR/$1" ]; then
        echo "已启用"
    else
        echo "未启用"
    fi
}

echo "sites-available："
for i in "${!FILES[@]}"; do
    echo "  $((i + 1))) ${FILES[$i]}  ($(enabled_mark "${FILES[$i]}"))"
done
echo

echo "1) 启用  2) 禁用  3) 看已启用  4) 退出"
read -r -p "选 [1-4]: " ACTION
case "$ACTION" in
1)
    read -r -p "要启用的编号: " CHOICE
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#FILES[@]}" ]; then
        echo "无效编号"
        exit 1
    fi
    SELECTED_FILE="${FILES[$((CHOICE - 1))]}"
    if [ -e "$ENABLED_DIR/$SELECTED_FILE" ]; then
        echo "已经启用：$SELECTED_FILE"
        exit 0
    fi
    ln -s "$AVAILABLE_DIR/$SELECTED_FILE" "$ENABLED_DIR/$SELECTED_FILE"
    if nginx -t; then
        systemctl reload nginx
        echo "已启用 $SELECTED_FILE 并 reload"
    else
        rm -f "$ENABLED_DIR/$SELECTED_FILE"
        echo "nginx -t 失败，已撤回启用。先改配置再试。"
        exit 1
    fi
    ;;
2)
    mapfile -t ENABLED_FILES < <(ls -1 "$ENABLED_DIR")
    if [ "${#ENABLED_FILES[@]}" -eq 0 ]; then
        echo "当前没有已启用站点"
        exit 0
    fi
    echo "已启用："
    for i in "${!ENABLED_FILES[@]}"; do
        echo "  $((i + 1))) ${ENABLED_FILES[$i]}"
    done
    read -r -p "要禁用的编号: " CHOICE
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#ENABLED_FILES[@]}" ]; then
        echo "无效编号"
        exit 1
    fi
    SELECTED_FILE="${ENABLED_FILES[$((CHOICE - 1))]}"
    if [ "$SELECTED_FILE" = "acme.conf" ]; then
        echo "警告：关掉 acme.conf 后证书续期的 HTTP-01 会失败。"
        read -r -p "仍要禁用？[y/N] " yn
        case "$yn" in
        y | Y) ;;
        *) echo "已取消"; exit 0 ;;
        esac
    fi
    rm -f "$ENABLED_DIR/$SELECTED_FILE"
    if nginx -t; then
        systemctl reload nginx
        echo "已禁用 $SELECTED_FILE"
    else
        echo "nginx -t 失败。符号链接已删，请检查配置后 reload。"
        exit 1
    fi
    ;;
3)
    echo "已启用："
    ls -1 "$ENABLED_DIR" || echo "（无）"
    ;;
4)
    exit 0
    ;;
*)
    echo "无效选择"
    exit 1
    ;;
esac
