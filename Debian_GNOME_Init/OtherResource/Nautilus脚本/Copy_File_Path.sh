#!/bin/bash

# 获取当前选中的文件或文件夹路径
FILE_PATH="$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
# 是否提醒
zVerbose=1

# 检查是否有选择的文件
if [ -n "$FILE_PATH" ]; then
    # 复制路径到剪贴板
    # echo "$FILE_PATH" | xclip -selection clipboard
    # sudo apt-get install wl-clipboard
    # echo "$FILE_PATH" | wl-copy
    # sudo apt-get install xsel
    echo "$FILE_PATH" | xsel -b 
    # 提示用户路径已复制
    if [ "$zVerbose" -eq 1 ];then
        zenity --info --text="路径已复制到剪贴板：\n$FILE_PATH"
    fi
else
    # 提示用户没有选择任何文件
    zenity --error --text="没有选择任何文件或文件夹。"
fi

