#!/bin/bash
# 写入 /etc/nginx/snippets/artalk.conf（子路径反代片段）。
# 不改 acme.conf / ssl.conf；用户在主站 server { } 里 include 一行即可。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../GlobalVariables.sh"
source "$SCRIPT_DIR/../Lib.sh"

RUN_PORT="${RUN_PORT:-23366}"
REVERSE_PROXY_PATH="${REVERSE_PROXY_PATH:-/artalk/}"

write_nginx_snippet "$SCRIPT_DIR/artalk.conf.src" "artalk.conf"
