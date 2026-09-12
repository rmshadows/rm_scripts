#!/bin/bash
# 把 acme.sh 目录里的证书拷到 /etc/ssl/<域名>.pem / .key，再 reload nginx/apache2。
# 由普通用户 cron 调用：sudo -n /usr/local/sbin/acme-deploy-cert
# 配置：/etc/acme-deploy.conf

set -euo pipefail

CONF=/etc/acme-deploy.conf
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
HTTP="${HTTP:-nginx}"
if [ -z "$ACME_HOME" ] || [ ! -d "$ACME_HOME" ]; then
    echo "ACME_HOME 无效: ${ACME_HOME:-空}" >&2
    exit 1
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
    install -m 644 "$src/fullchain.cer" "/etc/ssl/${domain}.pem"
    install -m 640 "$key" "/etc/ssl/${domain}.key"
    if getent group ssl-cert >/dev/null 2>&1; then
        chown root:ssl-cert "/etc/ssl/${domain}.key"
    fi
    echo "已安装 /etc/ssl/${domain}.pem 与 .key"
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
    echo "未执行 reload（HTTP=$HTTP）。证书已拷到 /etc/ssl。"
fi
