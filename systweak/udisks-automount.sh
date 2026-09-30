#!/usr/bin/env bash
# 交互控制「哪些分区/磁盘」被 GNOME/udisks 自动挂载：读写 / 只读 / 不自动 / 忽略
#
# 原理：
#   - udev: UDISKS_AUTO=0（不自动挂，侧栏仍可见）
#           UDISKS_IGNORE=1（忽略，一般不显示也不自动挂）
#   - /etc/udisks2/mount_options.conf：按 UUID 强制 defaults=ro（自动只读）
#   - 可选：开关 GNOME 全局 automount / automount-open
#
# 用法:
#   sudo ./udisks-automount.sh              # 交互菜单
#   sudo ./udisks-automount.sh --status
#   sudo ./udisks-automount.sh --undo       # 去掉本脚本写的规则
#   ./udisks-automount.sh --help
#
# 匹配键优先用文件系统 UUID；没有则用 PARTUUID；整盘用磁盘序列号 ID_SERIAL。
set -euo pipefail

NAME="udisks-automount"
# sudo 时策略仍落在真实用户家目录，避免写到 /root/.systweak-backup
_OWNER_HOME="$HOME"
if [[ -n "${SUDO_USER:-}" ]]; then
  _h="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  [[ -n "$_h" ]] && _OWNER_HOME="$_h"
fi
BACKUP_DIR="${SYSTWEAK_BACKUP:-$_OWNER_HOME/.systweak-backup}/${NAME}"
POLICY_FILE="$BACKUP_DIR/policy.tsv"
UDEV_RULES="/etc/udev/rules.d/99-systweak-udisks-automount.rules"
MOUNT_OPTS="/etc/udisks2/mount_options.conf"
MARKER_BEGIN="# BEGIN-SYSTWEAK-udisks-automount"
MARKER_END="# END-SYSTWEAK-udisks-automount"

log()  { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[x] $*" >&2; exit 1; }

need_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "写 udev/udisks 配置需要 root：sudo $0"
}

need_tools() {
  command -v lsblk >/dev/null 2>&1 || die "需要 lsblk"
  command -v udevadm >/dev/null 2>&1 || die "需要 udevadm"
}

# 在目标用户会话里跑 gsettings（带上 DBus）
run_as_user() {
  local u="$1"; shift
  local uid dbus
  uid="$(id -u "$u" 2>/dev/null)" || return 1
  dbus="/run/user/${uid}/bus"
  if [[ "$(id -un)" == "$u" ]]; then
    if [[ -S "$dbus" ]]; then
      env DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus" "$@"
    else
      "$@"
    fi
  elif [[ "$(id -u)" -eq 0 ]]; then
    if [[ -S "$dbus" ]]; then
      sudo -u "$u" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus" "$@"
    else
      sudo -u "$u" -- "$@"
    fi
  else
    return 1
  fi
}

ensure_backup_dir() {
  mkdir -p "$BACKUP_DIR"
  [[ -f "$POLICY_FILE" ]] || : >"$POLICY_FILE"
}

# ---------- 设备枚举 ----------
# 输出行: kind|name|size|fstype|label|uuid|partuuid|serial|model|mount|hint
# kind=disk|part
list_devices() {
  local -A DISK_SERIAL=() DISK_MODEL=()
  local line name pkname type size fstype label uuid partuuid mount model serial hotplug rm

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    eval "$line"
    [[ "${TYPE:-}" == disk ]] || continue
    DISK_SERIAL["$NAME"]="${SERIAL:-}"
    DISK_MODEL["$NAME"]="${MODEL:-}"
  done < <(lsblk -P -o NAME,TYPE,SERIAL,MODEL)

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    # 清空，避免上一轮残留
    NAME=""; PKNAME=""; TYPE=""; SIZE=""; FSTYPE=""; LABEL=""
    UUID=""; PARTUUID=""; MOUNTPOINT=""; MODEL=""; SERIAL=""; HOTPLUG=""; RM=""
    eval "$line"
    [[ -n "${NAME:-}" ]] || continue
    # lsblk -P 对非 ASCII 用 \xNN 转义，还原显示
    LABEL="$(printf '%b' "${LABEL:-}")"
    MODEL="$(printf '%b' "${MODEL:-}")"
    case "${TYPE:-}" in
      disk)
        printf 'disk|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
          "$NAME" "${SIZE:-}" "" "" "" "" \
          "${SERIAL:-}" "${MODEL:-}" "" "${HOTPLUG:-0}/${RM:-0}"
        ;;
      part)
        serial="${SERIAL:-}"
        model="${MODEL:-}"
        if [[ -z "$serial" && -n "${PKNAME:-}" ]]; then
          serial="${DISK_SERIAL[$PKNAME]:-}"
        fi
        if [[ -z "$model" && -n "${PKNAME:-}" ]]; then
          model="${DISK_MODEL[$PKNAME]:-}"
        fi
        printf 'part|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
          "$NAME" "${SIZE:-}" "${FSTYPE:-}" "${LABEL:-}" "${UUID:-}" "${PARTUUID:-}" \
          "$serial" "$model" "${MOUNTPOINT:-}" "${HOTPLUG:-0}/${RM:-0}"
        ;;
    esac
  done < <(lsblk -P -o NAME,PKNAME,TYPE,SIZE,FSTYPE,LABEL,UUID,PARTUUID,MOUNTPOINT,MODEL,SERIAL,HOTPLUG,RM)
}

parent_serial() {
  local part="$1" disk
  disk="$(lsblk -no PKNAME "/dev/$part" 2>/dev/null | head -1)"
  [[ -n "$disk" ]] || return 1
  lsblk -no SERIAL "/dev/$disk" 2>/dev/null | head -1
}

is_critical_mount() {
  case "$1" in
    /|/boot|/boot/efi|/usr|/var|/home) return 0 ;;
    *) return 1 ;;
  esac
}

policy_get() {
  local key="$1"
  [[ -f "$POLICY_FILE" ]] || return 1
  awk -F'\t' -v k="$key" '$1==k { print $2; exit }' "$POLICY_FILE"
}

policy_set() {
  local key="$1" mode="$2" note="${3:-}"
  ensure_backup_dir
  local tmp
  tmp="$(mktemp)"
  awk -F'\t' -v k="$key" '$1!=k { print }' "$POLICY_FILE" >"$tmp" 2>/dev/null || true
  printf '%s\t%s\t%s\n' "$key" "$mode" "$note" >>"$tmp"
  mv -f "$tmp" "$POLICY_FILE"
}

policy_del() {
  local key="$1" tmp
  [[ -f "$POLICY_FILE" ]] || return 0
  tmp="$(mktemp)"
  awk -F'\t' -v k="$key" '$1!=k { print }' "$POLICY_FILE" >"$tmp"
  mv -f "$tmp" "$POLICY_FILE"
}

mode_label() {
  case "$1" in
    auto-rw) echo "自动挂载·读写" ;;
    auto-ro) echo "自动挂载·只读" ;;
    noauto)  echo "不自动挂载（侧栏仍可见）" ;;
    ignore)  echo "忽略（不显示/不自动）" ;;
    *)       echo "默认(系统)" ;;
  esac
}

# 表格里用短标签
mode_label_short() {
  case "$1" in
    auto-rw) echo "读写" ;;
    auto-ro) echo "只读" ;;
    noauto)  echo "不自动" ;;
    ignore)  echo "忽略" ;;
    *)       echo "默认" ;;
  esac
}

# ---------- udisks 实时 Hint（插盘会不会自动挂） ----------
# 关联数组: U_AUTO / U_IGN / U_SYS / U_MP  （键=sda1）
declare -A U_AUTO=() U_IGN=() U_SYS=() U_MP=()

refresh_udisks_hints() {
  U_AUTO=() U_IGN=() U_SYS=() U_MP=()
  command -v udisksctl >/dev/null 2>&1 || return 0
  local line name auto ign sys mp
  while IFS='|' read -r name auto ign sys mp; do
    [[ -n "$name" ]] || continue
    U_AUTO["$name"]="$auto"
    U_IGN["$name"]="$ign"
    U_SYS["$name"]="$sys"
    U_MP["$name"]="$mp"
  done < <(
    udisksctl dump 2>/dev/null | awk '
      /^\/org\/freedesktop\/UDisks2\/block_devices\// {
        if (dev != "") emit()
        wipe(); next
      }
      $1 == "Device:" { dev = $2; next }
      $1 == "HintAuto:" { auto = $2; next }
      $1 == "HintIgnore:" { ign = $2; next }
      $1 == "HintSystem:" { sys = $2; next }
      $1 == "MountPoints:" {
        mp = $0
        sub(/^[[:space:]]*MountPoints:[[:space:]]*/, "", mp)
        if (mp == "") {
          if ((getline x) > 0 && x ~ /^[[:space:]]+\//) {
            gsub(/^[[:space:]]+/, "", x); mp = x
          }
        }
        next
      }
      END { emit() }
      function wipe() { dev = ""; auto = ""; ign = ""; sys = ""; mp = "" }
      function emit() {
        if (dev == "" || dev !~ /^\/dev\//) return
        n = dev; sub(/^\/dev\//, "", n)
        printf "%s|%s|%s|%s|%s\n", n, auto, ign, sys, mp
      }
    '
  )
}

# 现状短标签：会自动 / 不自动 / 忽略 （+·系统）
live_auto_label() {
  local name="$1"
  local auto="${U_AUTO[$name]:-}" ign="${U_IGN[$name]:-}" sys="${U_SYS[$name]:-}"
  local t=""
  if [[ -z "$auto" && -z "$ign" ]]; then
    echo "?"
    return
  fi
  if [[ "$ign" == "true" ]]; then
    t="忽略"
  elif [[ "$auto" == "true" ]]; then
    t="会自动"
  else
    t="不自动"
  fi
  [[ "$sys" == "true" ]] && t+="·系统"
  echo "$t"
}

# 已挂载时附带 rw/ro
mount_rw_suffix() {
  local mp="$1"
  [[ -n "$mp" ]] || { echo ""; return; }
  local opts
  opts="$(findmnt -no OPTIONS --target "$mp" 2>/dev/null || true)"
  if [[ -z "$opts" ]]; then
    echo ""
    return
  fi
  case ",${opts}," in
    *,ro,*) echo " [ro]" ;;
    *)      echo " [rw]" ;;
  esac
}

# 磁盘行：其下有多少分区「会自动」
disk_auto_summary() {
  local disk="$1" n=0 p
  for p in "${!U_AUTO[@]}"; do
    [[ "$p" == "$disk"[0-9]* || "$p" == "$disk"p[0-9]* ]] || continue
    [[ "${U_IGN[$p]:-}" == "true" ]] && continue
    [[ "${U_AUTO[$p]:-}" == "true" ]] || continue
    n=$((n + 1))
  done
  if [[ "$n" -gt 0 ]]; then
    echo "${n}分区会自动"
  else
    live_auto_label "$disk"
  fi
}

# ---------- 生成配置 ----------
write_udev_rules() {
  local key mode note
  ensure_backup_dir
  {
    echo "# Managed by systweak/$NAME — do not edit by hand"
    echo "# Regenerated: $(date -Iseconds)"
    echo
    while IFS=$'\t' read -r key mode note; do
      [[ -n "$key" && -n "$mode" ]] || continue
      case "$mode" in
        auto-rw)
          # 不写规则 = 恢复默认；若曾设过 ignore/auto，用显式清除更稳
          ;;
        auto-ro)
          # 只读靠 mount_options.conf；这里保证仍允许自动挂载
          if [[ "$key" == serial:* ]]; then
            printf 'ENV{ID_SERIAL}=="%s", ENV{DEVTYPE}=="partition", ENV{UDISKS_AUTO}="1", ENV{UDISKS_IGNORE}="0"\n' "${key#serial:}"
          elif [[ "$key" == partuuid:* ]]; then
            printf 'ENV{ID_PART_ENTRY_UUID}=="%s", ENV{UDISKS_AUTO}="1", ENV{UDISKS_IGNORE}="0"\n' "${key#partuuid:}"
          else
            printf 'ENV{ID_FS_UUID}=="%s", ENV{UDISKS_AUTO}="1", ENV{UDISKS_IGNORE}="0"\n' "$key"
          fi
          ;;
        noauto)
          if [[ "$key" == serial:* ]]; then
            printf 'ENV{ID_SERIAL}=="%s", ENV{DEVTYPE}=="partition", ENV{UDISKS_AUTO}="0"\n' "${key#serial:}"
          elif [[ "$key" == partuuid:* ]]; then
            printf 'ENV{ID_PART_ENTRY_UUID}=="%s", ENV{UDISKS_AUTO}="0"\n' "${key#partuuid:}"
          else
            printf 'ENV{ID_FS_UUID}=="%s", ENV{UDISKS_AUTO}="0"\n' "$key"
          fi
          ;;
        ignore)
          if [[ "$key" == serial:* ]]; then
            printf 'ENV{ID_SERIAL}=="%s", ENV{DEVTYPE}=="partition", ENV{UDISKS_IGNORE}="1"\n' "${key#serial:}"
          elif [[ "$key" == partuuid:* ]]; then
            printf 'ENV{ID_PART_ENTRY_UUID}=="%s", ENV{UDISKS_IGNORE}="1"\n' "${key#partuuid:}"
          else
            printf 'ENV{ID_FS_UUID}=="%s", ENV{UDISKS_IGNORE}="1"\n' "$key"
          fi
          ;;
      esac
    done <"$POLICY_FILE"
  } >"$UDEV_RULES"
  chmod 644 "$UDEV_RULES"
  log "已写入 $UDEV_RULES"
}

# 把本脚本管理的段落写进 mount_options.conf（只读策略）
write_mount_options() {
  local key mode note body="" tmp existing
  ensure_backup_dir
  mkdir -p /etc/udisks2

  while IFS=$'\t' read -r key mode note; do
    [[ "$mode" == "auto-ro" ]] || continue
    # 整盘 serial 无法直接写 by-uuid；对该盘上当前能看到的分区逐个加
    if [[ "$key" == serial:* ]]; then
      local serial="${key#serial:}" name uuid
      while IFS='|' read -r kind name size fstype label uuid partuuid serial2 model mount hot; do
        [[ "$kind" == part ]] || continue
        [[ "$serial2" == "$serial" ]] || continue
        [[ -n "$uuid" ]] || continue
        body+="[/dev/disk/by-uuid/${uuid}]"$'\n'
        body+="defaults=ro"$'\n'
        body+="# ${note:-systweak} $name"$'\n\n'
      done < <(list_devices)
      continue
    fi
    if [[ "$key" == partuuid:* ]]; then
      warn "PARTUUID ${key#partuuid:} 无文件系统 UUID，跳过只读挂载选项（仍可 noauto/ignore）"
      continue
    fi
    body+="[/dev/disk/by-uuid/${key}]"$'\n'
    body+="defaults=ro"$'\n'
    body+="# ${note:-systweak}"$'\n\n'
  done <"$POLICY_FILE"

  if [[ ! -f "$MOUNT_OPTS" ]]; then
    printf '%s\n%s\n%s\n' "$MARKER_BEGIN" "${body%$'\n'}" "$MARKER_END" >"$MOUNT_OPTS"
  else
    if ! grep -qF "$MARKER_BEGIN" "$MOUNT_OPTS" 2>/dev/null; then
      # 首次接管：备份整文件
      if [[ ! -f "$BACKUP_DIR/mount_options.conf.bak" ]]; then
        cp -a "$MOUNT_OPTS" "$BACKUP_DIR/mount_options.conf.bak"
        log "已备份 $MOUNT_OPTS"
      fi
      {
        cat "$MOUNT_OPTS"
        echo
        echo "$MARKER_BEGIN"
        printf '%s' "$body"
        echo "$MARKER_END"
      } >"$MOUNT_OPTS.tmp"
    else
      tmp="$(mktemp)"
      awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
        $0==b { skip=1; next }
        $0==e { skip=0; next }
        !skip { print }
      ' "$MOUNT_OPTS" >"$tmp"
      {
        cat "$tmp"
        echo
        echo "$MARKER_BEGIN"
        printf '%s' "$body"
        echo "$MARKER_END"
      } >"$MOUNT_OPTS.tmp"
      rm -f "$tmp"
    fi
    mv -f "$MOUNT_OPTS.tmp" "$MOUNT_OPTS"
  fi
  chmod 644 "$MOUNT_OPTS"
  log "已更新 $MOUNT_OPTS（只读段）"
}

reload_stack() {
  udevadm control --reload
  udevadm trigger --subsystem-match=block --action=change
  if systemctl is-active --quiet udisks2 2>/dev/null; then
    systemctl reload udisks2 2>/dev/null || systemctl try-restart udisks2 2>/dev/null || true
  fi
  log "已 reload udev / udisks2。若盘已插着，拔插一次或手动卸载再挂更稳。"
}

apply_all() {
  need_root
  write_udev_rules
  write_mount_options
  reload_stack
}

# 按终端显示宽度左对齐（CJK 全角算 2 列；printf %-Ns 会把中文算窄导致乱列）
vis_pad() {
  local s="$1" width="$2"
  if command -v python3 >/dev/null 2>&1; then
    VIS_PAD_S="$s" VIS_PAD_W="$width" python3 - <<'PY'
import os, sys
from unicodedata import east_asian_width
s = os.environ.get("VIS_PAD_S", "")
width = int(os.environ["VIS_PAD_W"])

def vw(t: str) -> int:
    return sum(2 if east_asian_width(ch) in ("F", "W") else 1 for ch in t)

while s and vw(s) > width:
    s = s[:-1]
sys.stdout.write(s + " " * (width - vw(s)))
PY
  else
    printf '%-*s' "$width" "$s"
  fi
}

# ---------- 展示 ----------
print_device_table() {
  local i=0 live pol_s mp_show
  refresh_udisks_hints

  # 列宽（显示宽度）: #2 NAME8 SIZE8 FSTYPE11 LABEL14 LIVE14 POL8 挂载...
  printf '%2s  ' "#"
  vis_pad "NAME" 8; printf ' '
  vis_pad "SIZE" 8; printf ' '
  vis_pad "FSTYPE" 11; printf ' '
  vis_pad "LABEL" 14; printf ' '
  vis_pad "现状" 14; printf ' '
  vis_pad "策略" 8; printf ' '
  printf '%s\n' "挂载"
  printf '%s\n' "----------------------------------------------------------------------------------------------------------"

  while IFS='|' read -r kind name size fstype label uuid partuuid serial model mount hot; do
    i=$((i + 1))
    local key pol inherit=""
    mp_show="${mount:-}"
    [[ -z "$mp_show" && -n "${U_MP[$name]:-}" ]] && mp_show="${U_MP[$name]}"

    printf '%2d  ' "$i"
    vis_pad "$name" 8; printf ' '
    vis_pad "$size" 8; printf ' '

    if [[ "$kind" == disk ]]; then
      key="serial:${serial}"
      [[ -n "$serial" ]] || key="diskname:${name}"
      pol="$(policy_get "$key" || true)"
      live="$(disk_auto_summary "$name")"
      pol_s="$(mode_label_short "${pol:-}")"
      vis_pad "-" 11; printf ' '
      vis_pad "${model:-}" 14; printf ' '
      vis_pad "$live" 14; printf ' '
      vis_pad "$pol_s" 8; printf ' '
      printf 'disk %s\n' "${serial:-无序列号}"
    else
      if [[ -n "$uuid" ]]; then
        key="$uuid"
      elif [[ -n "$partuuid" ]]; then
        key="partuuid:$partuuid"
      else
        key="name:$name"
      fi
      pol="$(policy_get "$key" || true)"
      if [[ -z "$pol" && -n "$serial" ]]; then
        pol="$(policy_get "serial:$serial" || true)"
        [[ -n "$pol" ]] && inherit="·盘"
      fi
      live="$(live_auto_label "$name")"
      pol_s="$(mode_label_short "${pol:-}")${inherit}"
      vis_pad "${fstype:--}" 11; printf ' '
      vis_pad "${label:--}" 14; printf ' '
      vis_pad "$live" 14; printf ' '
      vis_pad "$pol_s" 8; printf ' '
      printf '%s%s\n' "${mp_show:-}" "$(mount_rw_suffix "$mp_show")"
    fi
  done < <(list_devices)
  echo
  echo "说明: 「现状」= udisks 当前 Hint（插上会不会自动挂）；「策略」= 本脚本已保存的覆盖。"
  echo "      会自动 / 不自动 / 忽略；·系统 = 系统盘。磁盘行「N分区会自动」= 其下有 N 个分区会自动挂。"
  echo "      若 GNOME automount=false，则即使「会自动」也不会挂。"
}

cmd_status() {
  ensure_backup_dir
  echo "策略文件: $POLICY_FILE"
  echo "udev 规则: $UDEV_RULES $([ -f "$UDEV_RULES" ] && echo '[存在]' || echo '[无]')"
  echo "mount_options: $MOUNT_OPTS"
  if command -v gsettings >/dev/null 2>&1; then
    local u="${SUDO_USER:-$USER}" am ao
    am="$(run_as_user "$u" gsettings get org.gnome.desktop.media-handling automount 2>/dev/null || echo '?')"
    ao="$(run_as_user "$u" gsettings get org.gnome.desktop.media-handling automount-open 2>/dev/null || echo '?')"
    echo "GNOME automount ($am)  [用户 $u]"
    echo "GNOME automount-open ($ao)"
  fi
  echo
  if [[ -s "$POLICY_FILE" ]]; then
    echo "已保存策略:"
    awk -F'\t' '{ printf "  %-40s  %-10s  %s\n", $1, $2, $3 }' "$POLICY_FILE"
  else
    echo "尚无自定义策略（全部跟系统默认）。"
  fi
  echo
  print_device_table
}

pick_mode() {
  local cur="${1:-}"
  echo
  echo "选择策略:"
  echo "  1) 自动挂载 · 读写   (auto-rw，清除本脚本限制)"
  echo "  2) 自动挂载 · 只读   (auto-ro)"
  echo "  3) 不自动挂载         (noauto，侧栏一般仍可见，可手动挂)"
  echo "  4) 忽略               (ignore，不显示/不自动挂)"
  echo "  0) 取消"
  [[ -n "$cur" ]] && echo "  当前: $(mode_label "$cur")"
  local sel
  read -r -p "编号: " sel
  case "$sel" in
    1) echo auto-rw ;;
    2) echo auto-ro ;;
    3) echo noauto ;;
    4) echo ignore ;;
    *) echo "" ;;
  esac
}

device_by_index() {
  local want="$1" i=0
  while IFS='|' read -r kind name size fstype label uuid partuuid serial model mount hot; do
    i=$((i + 1))
    if [[ "$i" -eq "$want" ]]; then
      printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
        "$kind" "$name" "$size" "$fstype" "$label" "$uuid" "$partuuid" "$serial" "$model" "$mount" "$hot"
      return 0
    fi
  done < <(list_devices)
  return 1
}

interactive() {
  need_root
  need_tools
  ensure_backup_dir
  local ans key mode note line kind name size fstype label uuid partuuid serial model mount hot

  while true; do
    echo
    echo "======== udisks / GNOME 自动挂载控制 ========"
    print_device_table
    echo
    echo "操作:"
    echo "  数字) 设置该磁盘/分区策略"
    echo "  d)    对「整块磁盘」设策略（点盘符那一行的编号）"
    echo "  g)    GNOME 全局 automount 开关"
    echo "  s)    状态"
    echo "  a)    重新应用规则（写 udev 并 reload）"
    echo "  q)    保存并退出"
    read -r -p "> " ans

    case "$ans" in
      q|Q)
        apply_all
        log "完成。"
        return 0
        ;;
      s|S) cmd_status; continue ;;
      a|A) apply_all; continue ;;
      g|G)
        local u="${SUDO_USER:-$USER}"
        if ! command -v gsettings >/dev/null 2>&1; then
          warn "无 gsettings"
          continue
        fi
        echo "当前用户: $u"
        echo "  1) automount 开"
        echo "  2) automount 关（插盘不自动挂，侧栏仍可能显示）"
        echo "  3) automount-open 开（挂上后打开窗口）"
        echo "  4) automount-open 关"
        echo "  0) 返回"
        read -r -p "编号: " ans
        case "$ans" in
          1) run_as_user "$u" gsettings set org.gnome.desktop.media-handling automount true ;;
          2) run_as_user "$u" gsettings set org.gnome.desktop.media-handling automount false ;;
          3) run_as_user "$u" gsettings set org.gnome.desktop.media-handling automount-open true ;;
          4) run_as_user "$u" gsettings set org.gnome.desktop.media-handling automount-open false ;;
        esac
        continue
        ;;
      d|D)
        read -r -p "输入「磁盘」那一行的编号: " ans
        [[ "$ans" =~ ^[0-9]+$ ]] || continue
        line="$(device_by_index "$ans")" || { warn "无效编号"; continue; }
        IFS='|' read -r kind name size fstype label uuid partuuid serial model mount hot <<<"$line"
        [[ "$kind" == disk ]] || { warn "请选磁盘行（TYPE=disk），不是分区"; continue; }
        [[ -n "$serial" ]] || { warn "该盘没有 SERIAL，无法稳定匹配"; continue; }
        key="serial:$serial"
        mode="$(pick_mode "$(policy_get "$key" || true)")"
        [[ -n "$mode" ]] || continue
        if [[ "$mode" == auto-rw ]]; then
          policy_del "$key"
          log "已清除整盘策略: $name ($serial)"
        else
          policy_set "$key" "$mode" "disk:$name:$model"
          log "整盘 $name → $(mode_label "$mode")"
        fi
        apply_all
        continue
        ;;
      *)
        [[ "$ans" =~ ^[0-9]+$ ]] || continue
        line="$(device_by_index "$ans")" || { warn "无效编号"; continue; }
        IFS='|' read -r kind name size fstype label uuid partuuid serial model mount hot <<<"$line"
        if [[ "$kind" == disk ]]; then
          warn "这是磁盘行。整盘策略请按 d；或改选下面的分区编号。"
          continue
        fi
        if is_critical_mount "$mount"; then
          warn "警告: $name 当前挂在系统路径 $mount ，乱设可能导致下次进不了系统。"
          read -r -p "仍要继续？[y/N] " ans
          [[ "$ans" =~ ^[yY]$ ]] || continue
        fi
        if [[ -n "$uuid" ]]; then
          key="$uuid"
        elif [[ -n "$partuuid" ]]; then
          key="partuuid:$partuuid"
        else
          die "分区 $name 既无 UUID 也无 PARTUUID，无法写入稳定规则"
        fi
        mode="$(pick_mode "$(policy_get "$key" || true)")"
        [[ -n "$mode" ]] || continue
        if [[ "$mode" == auto-ro && -z "$uuid" ]]; then
          warn "无文件系统 UUID，无法写只读 mount_options；请改用 noauto/ignore，或先建好文件系统。"
          continue
        fi
        note="$name:${label:-}:${fstype:-}"
        if [[ "$mode" == auto-rw ]]; then
          policy_del "$key"
          log "已恢复默认: $name"
        else
          policy_set "$key" "$mode" "$note"
          log "$name → $(mode_label "$mode")"
        fi
        apply_all
        ;;
    esac
  done
}

cmd_undo() {
  need_root
  ensure_backup_dir
  if [[ -f "$UDEV_RULES" ]]; then
    rm -f "$UDEV_RULES"
    log "已删除 $UDEV_RULES"
  fi
  if [[ -f "$MOUNT_OPTS" ]] && grep -qF "$MARKER_BEGIN" "$MOUNT_OPTS" 2>/dev/null; then
    local tmp
    tmp="$(mktemp)"
    awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
      $0==b { skip=1; next }
      $0==e { skip=0; next }
      !skip { print }
    ' "$MOUNT_OPTS" >"$tmp"
    mv -f "$tmp" "$MOUNT_OPTS"
    log "已去掉 $MOUNT_OPTS 中的本脚本段落"
  fi
  if [[ -f "$BACKUP_DIR/mount_options.conf.bak" && ! -s "$MOUNT_OPTS" ]]; then
    cp -a "$BACKUP_DIR/mount_options.conf.bak" "$MOUNT_OPTS"
    log "已从备份恢复空文件前的 mount_options.conf"
  fi
  : >"$POLICY_FILE"
  reload_stack
  log "已还原为本脚本接管前的自动挂载行为（GNOME gsettings 未改）。"
}

usage() {
  cat <<EOF
用法: $(basename "$0") [--status|--undo|--help]
      sudo $(basename "$0")                 # 交互设置

策略:
  auto-rw   自动挂载，可读写（默认）
  auto-ro   自动挂载，只读
  noauto    不自动挂载，文件管理器里通常还能看见并手动挂
  ignore    忽略（一般不显示）

也可按「整块磁盘」统一设（用序列号匹配，换 /dev/sdX 字母也有效）。
EOF
}

need_tools
case "${1:-}" in
  ""|--interactive|interactive)
    interactive
    ;;
  --status|status)
    ensure_backup_dir
    cmd_status
    ;;
  --undo|undo)
    cmd_undo
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    die "未知参数: $1（见 --help）"
    ;;
esac
