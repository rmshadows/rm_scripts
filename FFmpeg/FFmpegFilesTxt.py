#!/usr/bin/python3
"""
根据给定区间生成ffmpeg合并需要的 txt 文件
"""
from datetime import datetime
from http.client import MULTI_STATUS
import os
import random

# 处理批次序列号
PART = 2
# 文件区间
FT = [6, 13]
# 文件扩展名
EXT = "MP4"
# EXT = "MOV"

cmd = ""
for i in range(FT[0], FT[1]+1):
    cmd += "file '{}.{}'\n".format(i, EXT)
print(cmd)
with open("{}.txt".format(PART), "w", encoding="utf-8") as f:
    f.write(cmd)
print("ffmpeg -f concat -i {}.txt -c copy OUT{}.{}".format(PART, PART, EXT))
