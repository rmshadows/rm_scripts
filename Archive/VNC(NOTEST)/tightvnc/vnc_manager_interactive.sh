#!/bin/bash

VNC_DIR="$HOME/.vnc"
CONFIG_FILE="$VNC_DIR/vnc_env.cfg"
DEFAULT_DISPLAY=2
DEFAULT_RESOLUTION="1365x768"

# 读取当前默认环境
load_default_env() {
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  else
    VNC_DEFAULT_ENV="fluxbox"
    echo "VNC_DEFAULT_ENV=fluxbox" > "$CONFIG_FILE"
  fi
}

# 保存默认环境到配置文件
save_default_env() {
  echo "VNC_DEFAULT_ENV=$1" > "$CONFIG_FILE"
}

get_xstartup_file() {
  local env=$1
  case $env in
    fluxbox)
      echo "$VNC_DIR/xstartup.fluxbox"
      ;;
    gnome)
      echo "$VNC_DIR/xstartup.gnome"
      ;;
    kde)
      echo "$VNC_DIR/xstartup.kde"
      ;;
    xfce4)
      echo "$VNC_DIR/xstartup.xfce4"
      ;;
    *)
      echo ""
      ;;
  esac
}

list_vnc() {
  echo "当前运行的 VNC 服务器实例（根据 PID 文件检测）："
  shopt -s nullglob
  pidfiles=($VNC_DIR/*.pid)
  if [ ${#pidfiles[@]} -eq 0 ]; then
    echo "无正在运行的 VNC 实例。"
    return
  fi

  for pf in "${pidfiles[@]}"; do
    filename=$(basename "$pf")
    display=$(echo "$filename" | grep -oE ':[0-9]+')
    pid=$(cat "$pf")
    if ps -p "$pid" > /dev/null 2>&1; then
      echo "Display $display - PID $pid - 运行中"
    else
      echo "Display $display - PID $pid - 进程不存在，可能已退出"
    fi
  done
}

start_vnc() {
  local env=$1
  local display=$2
  local xstartup_file
  xstartup_file=$(get_xstartup_file "$env")

  if [ -z "$xstartup_file" ] || [ ! -f "$xstartup_file" ]; then
    echo "错误: 找不到 $env 桌面的 xstartup 文件 ($xstartup_file)"
    return 1
  fi

  echo "配置 $env 桌面环境的 xstartup 文件..."
  cp "$xstartup_file" "$VNC_DIR/xstartup"
  chmod +x "$VNC_DIR/xstartup"

  echo "启动 VNC server :$display 分辨率 $DEFAULT_RESOLUTION ..."
  tightvncserver ":$display" -geometry "$DEFAULT_RESOLUTION"
}

stop_vnc() {
  local display=$1
  local pidfile="$VNC_DIR/$(hostname)$display.pid"

  if [ ! -f "$pidfile" ]; then
    echo "找不到显示号 $display 对应的 PID 文件：$pidfile"
    echo "尝试使用 tightvncserver -kill :$display"
    tightvncserver -kill ":$display"
    return
  fi

  pid=$(cat "$pidfile")
  if ps -p "$pid" > /dev/null 2>&1; then
    echo "杀死 PID $pid 对应的 VNC 服务，显示号 $display ..."
    tightvncserver -kill ":$display"
  else
    echo "PID $pid 对应的进程不存在，可能已经停止。"
  fi
}

restart_vnc() {
  local display=$1
  local env=$2
  echo "重启 VNC :$display，环境 $env ..."
  stop_vnc "$display"
  sleep 1
  start_vnc "$env" "$display"
}

manage_env_configs() {
  while true; do
    echo
    echo "===== 桌面环境配置管理 ====="
    echo "当前默认桌面环境：$VNC_DEFAULT_ENV"
    echo "1) 查看所有环境配置文件"
    echo "2) 切换默认环境"
    echo "3) 删除环境配置文件"
    echo "4) 返回主菜单"
    echo -n "请输入选项（1-4）："
    read -r env_choice
    case $env_choice in
      1)
        echo "现有桌面环境配置文件："
        ls "$VNC_DIR"/xstartup.* 2>/dev/null | xargs -n1 basename | sed 's/xstartup\.//'
        ;;
      2)
        echo -n "请输入要设为默认的环境名（fluxbox/gnome/kde/xfce4）："
        read -r newenv
        if [ -f "$(get_xstartup_file "$newenv")" ]; then
          save_default_env "$newenv"
          VNC_DEFAULT_ENV="$newenv"
          echo "默认环境已切换为：$newenv"
        else
          echo "找不到对应的 xstartup 文件，切换失败。"
        fi
        ;;
      3)
        echo -n "请输入要删除的环境名（fluxbox/gnome/kde/xfce4）："
        read -r delenv
        f=$(get_xstartup_file "$delenv")
        if [ -f "$f" ]; then
          rm -i "$f"
        else
          echo "找不到对应的 xstartup 文件，删除失败。"
        fi
        ;;
      4)
        break
        ;;
      *)
        echo "无效选项，请重新输入。"
        ;;
    esac
  done
}

load_default_env
while true; do
  echo
  echo "===== TightVNC 管理脚本 ====="
  echo "当前默认桌面环境：$VNC_DEFAULT_ENV"
  echo "1) 列出当前运行的 VNC 实例"
  echo "2) 启动 VNC (默认环境 $VNC_DEFAULT_ENV)"
  echo "3) 停止 VNC"
  echo "4) 重启 VNC (默认环境 $VNC_DEFAULT_ENV)"
  echo "5) 管理桌面环境配置"
  echo "6) 退出"
  echo -n "请输入选项（1-6）："
  read -r choice

  case $choice in
    1)
      list_vnc
      ;;
    2)
      echo -n "请输入显示号（默认$DEFAULT_DISPLAY）："
      read -r display
      display=${display:-$DEFAULT_DISPLAY}
      start_vnc "$VNC_DEFAULT_ENV" "$display"
      ;;
    3)
      echo -n "请输入要停止的显示号（默认$DEFAULT_DISPLAY）："
      read -r display
      display=${display:-$DEFAULT_DISPLAY}
      stop_vnc "$display"
      ;;
    4)
      echo -n "请输入要重启的显示号（默认$DEFAULT_DISPLAY）："
      read -r display
      display=${display:-$DEFAULT_DISPLAY}
      restart_vnc "$display" "$VNC_DEFAULT_ENV"
      ;;
    5)
      manage_env_configs
      ;;
    6)
      echo "退出。"
      exit 0
      ;;
    *)
      echo "无效选项，请重新输入。"
      ;;
  esac
done

