#!/bin/bash
# 旧入口。现在统一走 deploy.sh，读 config.sh。
exec "$(cd "$(dirname "$0")" && pwd)/deploy.sh" "$@"
