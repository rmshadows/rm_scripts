#!/bin/bash
# hackchat 启动脚本（由 hackchat.sh 生成，NODE_BIN 会被替换为 node 所在目录）
export PATH="【$NODE_BIN】:$PATH"
cd "$HOME/Applications/hackchat"
export PORT=【$RUN_PORT】
exec npm start
