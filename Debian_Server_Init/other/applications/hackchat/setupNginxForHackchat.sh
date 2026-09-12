#!/bin/bash
# 写入 /etc/nginx/snippets/hackchat.conf（子路径反代片段，Web + WS）。
# 不改 acme.conf / ssl.conf；用户在主站 server { } 里 include 一行即可。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../GlobalVariables.sh"
source "$SCRIPT_DIR/../Lib.sh"

RUN_PORT="${RUN_PORT:-3000}"
WS_PORT="${WS_PORT:-6060}"
REVERSE_PROXY_PATH="${REVERSE_PROXY_PATH:-/hc/}"
WS_PATH="${WS_PATH:-/hc-wss}"

write_nginx_snippet "$SCRIPT_DIR/hackchat.conf.src" "hackchat.conf"
