#!/usr/bin/python3
"""
根据所给文件夹，生成随机音乐列表(**请保证文件夹中的音乐文件格式统一**！！)
"""
from datetime import datetime
from http.client import MULTI_STATUS
import os
import random

# 音乐文件夹名称
MUSIC_DIR = "Music"

file_lst = os.listdir(MUSIC_DIR)
# 去掉py txt 隐藏文件
for i in file_lst:
    if i.endswith("py") or i.endswith("txt"):
        file_lst.remove(i)
    if i[0:1] == ".":
        file_lst.remove(i)
# 扩展名
extn = os.path.splitext(file_lst[4])[-1]
print(extn)
random.shuffle(file_lst)
# print(file_lst)
cmd = ""
for i in file_lst:
    cmd += "file '{}'\n".format(os.path.join(MUSIC_DIR, i))
print(cmd)
txt = str(datetime.now())[-6:-1] + ".txt"
with open(txt, "w", encoding="utf8") as f:
    f.write(cmd)
cmd = "ffmpeg -f concat -i {} -c copy {}{}".format(txt, txt.replace(".txt", ""), extn)
print(cmd)
os.popen(cmd)

