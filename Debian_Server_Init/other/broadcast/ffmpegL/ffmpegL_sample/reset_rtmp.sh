#!/bin/bash
cd 【$new_srv_path】
CONFF="conf.txt"
# 只改第一行 RTMP=，保留后面的目录/编码配置
if grep -q '^RTMP=' "$CONFF"; then
	sed -i 's|^RTMP=.*|RTMP=""|' "$CONFF"
else
	sed -i '1i RTMP=""' "$CONFF"
fi
nano "$CONFF"
