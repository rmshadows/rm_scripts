#!/bin/bash
cd changeme_path/changeme_dir
# 删除第一行
sed -i '1d' inke.txt
sed -i '1i RTMP=""' inke.txt
nano inke.txt
