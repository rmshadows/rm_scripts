#!/bin/bash
# 把 acme.sh 目录里的证书拷到 ~/cert/<主域名>.pem 与 .key，再 reload nginx/apache2。
# 由普通用户 cron 调用：sudo -n /path/to/acme/acme-deploy-cert.sh
# 配置：/etc/acme-deploy.conf（DEPLOY_DIR 默认是该用户的 ~/cert）

set -euo pipefail

CONF="${ACME_CONF:-/etc/acme-deploy.conf}"
if [ ! -f "$CONF" ]; then
    echo "缺少 $CONF" >&2
    exit 1
fi
# shellcheck disable=SC1090
. "$CONF"

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "请用: sudo -n $0" >&2
    exit 1
fi

ACME_HOME="${ACME_HOME:-}"
ACME_USER="${ACME_USER:-}"
HTTP="${HTTP:-nginx}"
if [ -z "$ACME_HOME" ] || [ ! -d "$ACME_HOME" ]; then
    echo "ACME_HOME 无效: ${ACME_HOME:-空}" >&2
    exit 1
fi

if [ -z "${DEPLOY_DIR:-}" ]; then
    if [ -z "$ACME_USER" ]; then
        echo "DEPLOY_DIR 和 ACME_USER 都是空的，不知道要拷到哪" >&2
        exit 1
    fi
    _home=$(getent passwd "$ACME_USER" | cut -d: -f6)
    if [ -z "$_home" ]; then
        echo "找不到用户 $ACME_USER 的家目录" >&2
        exit 1
    fi
    DEPLOY_DIR="${_home}/cert"
fi

# nginx 主进程是 root，但家目录如果是 700，www-data 进不了 ~/cert。只给「进入」权限。
if [ -n "$ACME_USER" ]; then
    _home=$(getent passwd "$ACME_USER" | cut -d: -f6 || true)
    if [ -n "$_home" ] && [ -d "$_home" ]; then
        _other=$(stat -c '%a' "$_home" 2>/dev/null || echo 755)
        _other=${_other: -1}
        case "$_other" in
        1|3|5|7) ;;
        *) chmod o+x "$_home" || true ;;
        esac
    fi
fi
install -d -m 755 "$DEPLOY_DIR"
if [ -n "$ACME_USER" ]; then
    chown "$ACME_USER:$ACME_USER" "$DEPLOY_DIR" || true
fi
_key_group="$ACME_USER"
if getent group www-data >/dev/null 2>&1; then
    _key_group=www-data
elif getent group ssl-cert >/dev/null 2>&1; then
    _key_group=ssl-cert
fi

copy_one() {
    local domain="$1"
    local src=""
    if [ -f "$ACME_HOME/${domain}_ecc/fullchain.cer" ]; then
        src="$ACME_HOME/${domain}_ecc"
    elif [ -f "$ACME_HOME/${domain}/fullchain.cer" ]; then
        src="$ACME_HOME/${domain}"
    else
        echo "找不到证书: $domain（在 $ACME_HOME）" >&2
        return 1
    fi
    local key=""
    if [ -f "$src/${domain}.key" ]; then
        key="$src/${domain}.key"
    else
        key=$(find "$src" -maxdepth 1 -type f -name '*.key' | head -n 1)
    fi
    if [ -z "$key" ] || [ ! -f "$key" ]; then
        echo "找不到密钥: $domain" >&2
        return 1
    fi
    if [ -n "$ACME_USER" ]; then
        install -m 644 -o "$ACME_USER" -g "$ACME_USER" "$src/fullchain.cer" "$DEPLOY_DIR/${domain}.pem"
        install -m 640 -o "$ACME_USER" -g "${_key_group:-$ACME_USER}" "$key" "$DEPLOY_DIR/${domain}.key"
    else
        install -m 644 "$src/fullchain.cer" "$DEPLOY_DIR/${domain}.pem"
        install -m 640 "$key" "$DEPLOY_DIR/${domain}.key"
    fi
    echo "已安装 $DEPLOY_DIR/${domain}.pem 与 .key"
}

if [ "$#" -gt 0 ]; then
    for d in "$@"; do
        copy_one "$d"
    done
else
    found=0
    for dir in "$ACME_HOME"/*/; do
        [ -d "$dir" ] || continue
        base=$(basename "$dir")
        case "$base" in
        ca | deploy | dnsapi | notify) continue ;;
        esac
        [ -f "${dir}fullchain.cer" ] || continue
        domain=${base%_ecc}
        copy_one "$domain"
        found=1
    done
    if [ "$found" -eq 0 ]; then
        echo "在 $ACME_HOME 未找到可部署的证书" >&2
        exit 1
    fi
fi

reload_ok=0
case "$HTTP" in
nginx | both)
    if command -v nginx >/dev/null 2>&1; then
        if nginx -t; then
            systemctl reload nginx
            echo "已 reload nginx"
            reload_ok=1
        else
            echo "nginx -t 失败，未 reload" >&2
            exit 1
        fi
    fi
    ;;&
apache2 | both)
    if command -v apache2ctl >/dev/null 2>&1; then
        if apache2ctl configtest; then
            systemctl reload apache2
            echo "已 reload apache2"
            reload_ok=1
        else
            echo "apache2ctl configtest 失败，未 reload" >&2
            exit 1
        fi
    fi
    ;;
esac

if [ "$reload_ok" -eq 0 ] && [ "$HTTP" != "none" ]; then
    echo "未执行 reload（HTTP=$HTTP）。证书已拷到 $DEPLOY_DIR。"
fi
