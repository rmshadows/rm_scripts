#!/bin/bash
# 删除第一行
sed -i '1d' RTMP.txt
sed -i '1i RTMP=_ADDR""' RTMP.txt
nano RTMP.txt
