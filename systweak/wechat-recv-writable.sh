#!/usr/bin/env bash
# GNOME：Alt+Shift+M 把本机微信「接收文件」目录加成可写（自动发现账号）
# 用法: ./wechat-recv-writable.sh            # 开关：未装则装，已装则卸
#       ./wechat-recv-writable.sh --apply    # 只安装
#       ./wechat-recv-writable.sh --undo     # 只卸载
#       ./wechat-recv-writable.sh --status
#       ./wechat-recv-writable.sh --chmod    # 立刻 chmod（快捷键实际调用这个）
#       ./wechat-recv-writable.sh --list     # 只列出将处理的目录
# 环境变量: SYSTWEAK_BACKUP  WECHAT_WRITABLE_EXTRA_ROOTS（空格分隔的额外搜索根）
set -euo pipefail

NAME="wechat-recv-writable"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
HELPER="${HOME}/.local/bin/wechat-recv-writable"
KB_NAME="微信接收文件可写"
KB_BIND="<Shift><Alt>m"
KB_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
KB_ITEM="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
KB_PREFIX="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

log()  { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[x] $*" >&2; exit 1; }

gset_unquote() {
  local s="${1:-}"
  if [[ "$s" == \'*\' ]]; then
    s="${s#\'}"
    s="${s%\'}"
  elif [[ "$s" == \"*\" ]]; then
    s="${s#\"}"
    s="${s%\"}"
  fi
  printf '%s' "$s"
}

# ---------- 发现微信接收文件目录 ----------

wechat_search_roots() {
  local docs extra
  docs=$(xdg-user-dir DOCUMENTS 2>/dev/null || true)
  [[ -n "$docs" ]] && printf '%s\n' "$docs"
  printf '%s\n' "$HOME/文档" "$HOME/Documents" "$HOME"
  [[ -d "/media/${USER}" ]] && printf '%s\n' "/media/${USER}"
  [[ -d "$HOME/.wine/drive_c/users" ]] && printf '%s\n' "$HOME/.wine/drive_c/users"
  [[ -d "$HOME/.deepinwine" ]] && printf '%s\n' "$HOME/.deepinwine"
  # shellcheck disable=SC2086
  for extra in ${WECHAT_WRITABLE_EXTRA_ROOTS:-}; do
    [[ -d "$extra" ]] && printf '%s\n' "$extra"
  done
}

wechat_data_roots() {
  local root depth
  wechat_search_roots | awk 'NF && !seen[$0]++' | while IFS= read -r root; do
    [[ -d "$root" ]] || continue
    case "$root" in
      "$HOME/.wine/drive_c/users"|"$HOME/.deepinwine") depth=8 ;;
      *) depth=3 ;;
    esac
    find "$root" -maxdepth "$depth" -type d \( \
      -name 'xwechat_files' -o -name 'WeChat Files' -o -name 'wechat_files' \
    \) 2>/dev/null || true
  done | awk 'NF && !seen[$0]++'
}

# 每个账号一个「接收文件」目录；跳过 xwechat 的 all_users / WMPF
wechat_file_dirs() {
  local data
  wechat_data_roots | while IFS= read -r data; do
    [[ -d "$data" ]] || continue
    case "$(basename "$data")" in
      xwechat_files|wechat_files)
        find "$data" -mindepth 2 -maxdepth 3 -type d -path '*/msg/file' \
          ! -path '*/all_users/*' ! -path '*/WMPF/*' 2>/dev/null || true
        ;;
      "WeChat Files")
        find "$data" -mindepth 2 -maxdepth 4 -type d -path '*/FileStorage/File' \
          2>/dev/null || true
        ;;
    esac
  done | awk 'NF && !seen[$0]++'
}

notify_user() {
  local title="$1" body="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="微信接收文件" "$title" "$body" || true
  fi
}

cmd_list() {
  local n=0 dir
  while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    printf '%s\n' "$dir"
    n=$((n + 1))
  done < <(wechat_file_dirs)
  if [[ "$n" -eq 0 ]]; then
    warn "未找到微信接收文件目录（xwechat_files/*/msg/file 或 WeChat Files/*/FileStorage/File）"
    return 1
  fi
  return 0
}

cmd_chmod() {
  local n=0 fail=0 dir
  local dirs=()
  while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    dirs+=("$dir")
  done < <(wechat_file_dirs)

  if [[ "${#dirs[@]}" -eq 0 ]]; then
    warn "未找到微信接收文件目录"
    notify_user "未找到微信目录" "没有 xwechat_files/*/msg/file 或 WeChat Files/*/FileStorage/File"
    return 1
  fi

  for dir in "${dirs[@]}"; do
    if chmod -R u+rwX "$dir"; then
      log "已可写: $dir"
      n=$((n + 1))
    else
      warn "失败: $dir"
      fail=$((fail + 1))
    fi
  done

  if [[ "$fail" -eq 0 ]]; then
    notify_user "已设为可写" "处理了 ${n} 个目录"
  else
    notify_user "部分失败" "成功 ${n}，失败 ${fail}"
    return 1
  fi
}

# ---------- GNOME 自定义快捷键 ----------

need_gsettings() {
  command -v gsettings >/dev/null 2>&1 || die "需要 gsettings（在目标用户的 GNOME 会话下运行）"
}

kb_paths() {
  gsettings get "$KB_SCHEMA" custom-keybindings \
    | grep -oE "${KB_PREFIX}/custom[0-9]+/" || true
}

kb_get() {
  local path="$1" key="$2"
  gset_unquote "$(gsettings get "${KB_ITEM}:${path}" "$key")"
}

kb_find_ours() {
  local p name cmd
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    name=$(kb_get "$p" name)
    cmd=$(kb_get "$p" command)
    if [[ "$name" == "$KB_NAME" || "$cmd" == *wechat-recv-writable* ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done < <(kb_paths)
  return 1
}

kb_next_path() {
  local n max=-1 p
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    n="${p##*custom}"
    n="${n%/}"
    [[ "$n" =~ ^[0-9]+$ ]] || continue
    (( n > max )) && max=$n
  done < <(kb_paths)
  printf '%s/custom%d/\n' "$KB_PREFIX" "$((max + 1))"
}

kb_list_set_from_paths() {
  local items=() p
  for p in "$@"; do
    [[ -n "$p" ]] && items+=("'$p'")
  done
  if [[ "${#items[@]}" -eq 0 ]]; then
    gsettings set "$KB_SCHEMA" custom-keybindings "@as []"
  else
    local joined
    joined=$(IFS=,; echo "${items[*]}")
    gsettings set "$KB_SCHEMA" custom-keybindings "[${joined}]"
  fi
}

kb_list_add() {
  local new="$1" p
  local paths=()
  while IFS= read -r p; do
    [[ -n "$p" ]] && paths+=("$p")
  done < <(kb_paths)
  for p in "${paths[@]}"; do
    [[ "$p" == "$new" ]] && return 0
  done
  kb_list_set_from_paths "${paths[@]}" "$new"
}

kb_list_remove() {
  local del="$1" p
  local keep=()
  while IFS= read -r p; do
    [[ -z "$p" || "$p" == "$del" ]] && continue
    keep+=("$p")
  done < <(kb_paths)
  kb_list_set_from_paths "${keep[@]+"${keep[@]}"}"
}

kb_reset_slot() {
  local path="$1"
  gsettings reset "${KB_ITEM}:${path}" name 2>/dev/null || true
  gsettings reset "${KB_ITEM}:${path}" binding 2>/dev/null || true
  gsettings reset "${KB_ITEM}:${path}" command 2>/dev/null || true
}

install_helper() {
  mkdir -p "$(dirname "$HELPER")"
  # 拷走本文件，快捷键不依赖仓库路径
  if [[ -f "${BASH_SOURCE[0]:-$0}" ]]; then
    install -m 755 "${BASH_SOURCE[0]:-$0}" "$HELPER"
  else
    install -m 755 "$0" "$HELPER"
  fi
  log "已安装执行体: $HELPER"
}

is_applied() {
  [[ -x "$HELPER" ]] || return 1
  local slot
  slot=$(kb_find_ours 2>/dev/null || true)
  [[ -n "$slot" ]] || return 1
  local cmd
  cmd=$(kb_get "$slot" command)
  [[ "$cmd" == *wechat-recv-writable* ]]
}

cmd_status() {
  echo "备份: $BACKUP_DIR"
  echo "执行体: $HELPER$([ -x "$HELPER" ] && echo '（已安装）' || echo '（未安装）')"
  echo "快捷键: ${KB_BIND}  名称: ${KB_NAME}"
  if command -v gsettings >/dev/null 2>&1; then
    local slot
    if slot=$(kb_find_ours); then
      echo "槽位: $slot"
      echo "  name=$(kb_get "$slot" name)"
      echo "  binding=$(kb_get "$slot" binding)"
      echo "  command=$(kb_get "$slot" command)"
    else
      echo "槽位: 未配置"
    fi
  else
    echo "gsettings: 不可用"
  fi
  echo
  echo "将处理的目录:"
  cmd_list || true
}

cmd_apply() {
  need_gsettings
  mkdir -p "$BACKUP_DIR"
  install_helper

  local slot created=0
  if slot=$(kb_find_ours); then
    if [[ ! -f "$BACKUP_DIR/state.env" ]]; then
      {
        echo "slot=${slot}"
        echo "created=0"
      } >"$BACKUP_DIR/state.env"
      kb_get "$slot" name >"$BACKUP_DIR/orig_name"
      kb_get "$slot" binding >"$BACKUP_DIR/orig_binding"
      kb_get "$slot" command >"$BACKUP_DIR/orig_command"
      log "已备份原快捷键 -> $BACKUP_DIR/"
    fi
  else
    slot=$(kb_next_path)
    created=1
    if [[ ! -f "$BACKUP_DIR/state.env" ]]; then
      {
        echo "slot=${slot}"
        echo "created=1"
      } >"$BACKUP_DIR/state.env"
      log "将新增槽位 $slot"
    fi
    kb_list_add "$slot"
  fi

  gsettings set "${KB_ITEM}:${slot}" name "$KB_NAME"
  gsettings set "${KB_ITEM}:${slot}" binding "$KB_BIND"
  gsettings set "${KB_ITEM}:${slot}" command "${HELPER} --chmod"
  log "已绑定 ${KB_BIND} -> ${HELPER} --chmod"
  log "按快捷键时会重新扫描账号，新登录的微信也会被覆盖"
  cmd_status
}

cmd_undo() {
  need_gsettings
  local slot created=1

  if [[ -f "$BACKUP_DIR/state.env" ]]; then
    # shellcheck disable=SC1090
    source "$BACKUP_DIR/state.env"
  else
    slot=$(kb_find_ours || true)
  fi

  if [[ -n "${slot:-}" ]]; then
    if [[ "${created:-1}" == "0" && -f "$BACKUP_DIR/orig_command" ]]; then
      gsettings set "${KB_ITEM}:${slot}" name "$(cat "$BACKUP_DIR/orig_name")"
      gsettings set "${KB_ITEM}:${slot}" binding "$(cat "$BACKUP_DIR/orig_binding")"
      gsettings set "${KB_ITEM}:${slot}" command "$(cat "$BACKUP_DIR/orig_command")"
      log "已还原原快捷键命令: $slot"
    else
      kb_list_remove "$slot"
      kb_reset_slot "$slot"
      log "已删除快捷键槽位: $slot"
    fi
  else
    log "未找到本脚本的快捷键，跳过"
  fi

  if [[ -f "$HELPER" ]]; then
    rm -f "$HELPER"
    log "已删除执行体: $HELPER"
  fi
  rm -f "$BACKUP_DIR/state.env" "$BACKUP_DIR/orig_name" \
    "$BACKUP_DIR/orig_binding" "$BACKUP_DIR/orig_command" 2>/dev/null || true
  cmd_status
}

cmd_toggle() {
  if is_applied; then
    log "已配置，改为卸掉"
    cmd_undo
  else
    log "未配置，改为安装"
    cmd_apply
  fi
}

usage() {
  cat <<EOF
用法: $(basename "$0") [选项]

  （无参数）  开关：没装就装，已装就卸
  --apply     备份后安装快捷键 + 执行体
  --undo      还原/去掉本脚本加的配置
  --status    查看快捷键与将处理的目录
  --chmod     立刻把已发现的接收文件目录设为可写
  --list      只列出将处理的目录
  --help

快捷键: Alt+Shift+M（${KB_BIND}）
每次按快捷键都会重新扫描：
  • <文档>/xwechat_files/<账号>/msg/file     （Linux 微信）
  • <文档>/WeChat Files/<账号>/FileStorage/File （Wine 微信）
额外搜索根: WECHAT_WRITABLE_EXTRA_ROOTS="路径1 路径2"
备份: $BACKUP_DIR
EOF
}

case "${1:-}" in
  "") cmd_toggle ;;
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  --chmod|--run|chmod) cmd_chmod ;;
  --list|list) cmd_list ;;
  --toggle|toggle) cmd_toggle ;;
  -h|--help|help) usage ;;
  *) die "未知参数: $1（见 --help）" ;;
esac
