#!/bin/bash
# 下载kplayer

# amd64="https://gitee.com/bytelang/kplayer-go/releases/download/v0.5.8/kplayer-v0.5.8-linux_amd64.tar.gz"
# arm64="https://gitee.com/bytelang/kplayer-go/releases/download/v0.5.8/kplayer-v0.5.8-linux_arm64.tar.gz"
set -e
curl --fail  http://download.bytelang.cn/kplayer-v0.5.7-$(uname -s | sed s/Linux/linux/)_$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/).tar.gz -o kplayer.tar.gz
tar zxvf kplayer.tar.gz
rm -rf kplayer.tar.gz

# cp kplayer_files/* kplayer
