#!/bin/bash
# 写入 /etc/nginx/snippets/rsshub.conf（子路径反代片段）。
# 不改 acme.conf / ssl.conf；用户在主站 server { } 里 include 一行即可。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../GlobalVariables.sh"
source "$SCRIPT_DIR/../Lib.sh"

RUN_PORT="${RUN_PORT:-1200}"
REVERSE_PROXY_PATH="${REVERSE_PROXY_PATH:-/rsshub/}"

write_nginx_snippet "$SCRIPT_DIR/rsshub.conf.src" "rsshub.conf"
