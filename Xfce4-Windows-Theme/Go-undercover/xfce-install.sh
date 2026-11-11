#!/bin/bash
# 旧入口。软件包、主题、快捷键都由 deploy.sh 按 config.sh 处理。
exec "$(cd "$(dirname "$0")" && pwd)/deploy.sh" "$@"
