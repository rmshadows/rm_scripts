#!/bin/bash
## 卸载 artalk
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=artalk
DATA_DIR=/home/artalk

# 1. 停止并卸载 systemd 服务（不含数据，安全）
app_remove_service "$SRV_NAME"

# 2. 删除 nginx 配置
app_remove_nginx artalk.conf

# 3. 数据目录（含数据库 artalk.db、上传图片）：删除前先确认
#    /home/artalk 里程序和数据在一起，删除会一并移除系统用户
if id artalk >/dev/null 2>&1 || [ -d "$DATA_DIR" ]; then
  if confirm_remove_data "$DATA_DIR" "artalk 数据（数据库 /home/artalk/data/artalk.db、上传图片）"; then
    sudo userdel -r artalk 2>/dev/null || sudo rm -rf "$DATA_DIR"
    sudo groupdel artalk 2>/dev/null || true
  else
    prompt -i "已保留 artalk 用户与 $DATA_DIR；如需彻底删除请之后手动处理。"
  fi
fi

# 4. 清理下载残留（无用户数据）
[ -d "$HOME/Applications/artalk" ] && rm -rf "$HOME/Applications/artalk"

prompt -s "artalk 卸载流程结束。"
