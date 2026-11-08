#!/usr/bin/env bash
# 将 BitLocker 脚本 + 当前 config 打成「单个临时 .sh」，核对后再用 shc 编译。
#
# 用法:
#   ./pack_shc.sh              # 生成临时脚本 → 展示 config → 确认 → shc
#   ./pack_shc.sh --no-shc     # 只生成合并脚本，不调用 shc
#   ./pack_shc.sh --yes        # 不询问，直接 shc（仍会打印 config 摘要）
#
# 产物目录: ./build-shc/
#   mountB-packed.sh   合并后的 shell（可人工检查）
#   mountB             shc 生成的可执行文件（若本机有 shc）
#
# 二进制用法:
#   ./build-shc/mountB           # 交互挂/卸（同 mountB.sh）
#   ./build-shc/mountB --mount   # 直接挂（同 rmount.sh）
#   ./build-shc/mountB --umount  # 直接卸（同 urmount.sh）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

DO_SHC=1
ASSUME_YES=0
BUILD_DIR="$SCRIPT_DIR/build-shc"
OUT_SH="$BUILD_DIR/mountB-packed.sh"
OUT_BIN="$BUILD_DIR/mountB"

die() { echo "[x] $*" >&2; exit 1; }
info() { echo "[+] $*" >&2; }
warn() { echo "[!] $*" >&2; }

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --no-shc) DO_SHC=0; shift ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    *) die "未知参数: $1（见 --help）" ;;
  esac
done

[[ -f Profile.sh ]] || die "缺少 Profile.sh"
[[ -f config.sh ]] || die "缺少 config.sh"
[[ -f mountB.sh ]] || die "缺少 mountB.sh"

mkdir -p "$BUILD_DIR"

strip_shebang() {
  local f="$1"
  awk 'NR==1 && /^#!/ { next } { print }' "$f"
}

# 取出 mountB.sh 里的函数段（不含开头 source、不含末尾主流程）
mountb_funcs() {
  awk '
    /^# 函数：检查单个挂载点是否挂载/ { keep = 1 }
    keep {
      if (/^# 先按记录\/固定名找回可读挂载点/) exit
      print
    }
  ' mountB.sh
}

info "生成合并脚本: $OUT_SH"

{
  cat <<'HDR'
#!/bin/bash
# =============================================================================
# 本文件由 pack_shc.sh 自动生成，请勿手改长期维护。
# 内含：Profile + config（打包时快照）+ mountB 函数 + 统一入口
# 注：须用 #!/bin/bash（勿用 env）；shc 不认 #!/usr/bin/env bash。
# 勿加 set -e：comfirmy 用返回值 1/2 表示是/否，与 mountB.sh 一致。
# =============================================================================

resolve_runtime_dirs() {
  local exe
  if [[ -r /proc/self/exe ]]; then
    exe="$(readlink -f /proc/self/exe 2>/dev/null || true)"
  fi
  if [[ -n "${exe:-}" && -e "$exe" ]]; then
    PACK_BIN_DIR="$(cd "$(dirname "$exe")" && pwd)"
  else
    PACK_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
  STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ManualMountEncrypted-BitLocker"
  mkdir -p "$STATE_DIR"
  # mountB / detect 里用 SCRIPT_DIR 写 .last-readmount
  SCRIPT_DIR="$STATE_DIR"
}

resolve_runtime_dirs
DISLOCKER_BIN=""

HDR

  echo "# ---- Profile.sh ----"
  strip_shebang Profile.sh
  echo
  echo "# ---- config.sh（打包快照，改配置请改源码旁 config.sh 后重新打包）----"
  strip_shebang config.sh
  echo
  cat <<'PATHFIX'
# 相对路径的 DISLOCKER_CUSTOM 按二进制目录解析
if [ -n "${DISLOCKER_CUSTOM:-}" ] && [[ "$DISLOCKER_CUSTOM" != /* ]]; then
  DISLOCKER_CUSTOM="$PACK_BIN_DIR/$DISLOCKER_CUSTOM"
fi

PATHFIX
  echo "# ---- mountB.sh 函数 ----"
  mountb_funcs
  cat <<'MAIN'

# 覆盖：状态目录固定用 STATE_DIR
save_last_read_mount() {
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  printf '%s\n' "$readMount" >"${STATE_DIR}/.last-readmount"
}
load_last_read_mount() {
  local f="${STATE_DIR}/.last-readmount" mp
  [ -f "$f" ] || return 1
  mp="$(tr -d '\r\n' <"$f")"
  [ -n "$mp" ] || return 1
  if is_mountpoint "$mp"; then
    readMount="$mp"
    return 0
  fi
  return 1
}

packed_usage() {
  cat <<EOF
BitLocker 挂载工具（pack_shc 打包版）

用法:
  $(basename "$0")              交互：已挂载则询问卸载，否则询问挂载
  $(basename "$0") --mount|-m   直接挂载（同 rmount.sh）
  $(basename "$0") --umount|-u  直接卸载（同 urmount.sh）
  $(basename "$0") -h|--help    帮助
EOF
}

# 非交互：自动答「是」挂载确认；清目录类危险提问仍默认否
run_mount_direct() {
  comfirmy() { return 1; }
  comfirmn() { return 2; }
  mountBitlockerDisk
}

run_umount_direct() {
  local usuccess=0
  detect_existing_bitlocker_mount || true
  if check_mount_point "$readMount"; then
    sudo umount "$readMount" || { usuccess=1; show_mount_holders "$readMount"; }
  else
    prompt -w "可读挂载点未挂载: $readMount"
  fi
  sleep 1
  if check_mount_point "$dislockMount"; then
    sudo umount "$dislockMount" || { usuccess=1; show_mount_holders "$dislockMount"; }
  else
    prompt -w "dislocker 挂载点未挂载: $dislockMount"
  fi
  if [ "$usuccess" -eq 0 ]; then
    prompt -s "Disk unmounted successfully."
    remove_empty_media_dir "$readMount"
    rm -f "${STATE_DIR}/.last-readmount" 2>/dev/null || true
    return 0
  fi
  prompt -e "WARN: An error may occur during the umount process, check manual."
  return 1
}

run_interactive() {
  detect_existing_bitlocker_mount || true
  if check_bitlocker_mount; then
    umountBitlocker
    return $?
  fi
  check_bitlocker_mount_adv
  local status=$?
  case $status in
  0)
    echo "BitLocker 磁盘已挂载：两个挂载点都已挂载"
    ;;
  1)
    echo "BitLocker 磁盘已挂载：只挂载了 $readMount ，请手动检查。"
    umountBitlocker
    return 1
    ;;
  2)
    echo "BitLocker 磁盘已挂载：只挂载了 $dislockMount ，请手动检查。"
    umountBitlocker
    return 1
    ;;
  3)
    mountBitlockerDisk
    ;;
  4)
    echo "BitLocker 磁盘状态未知"
    return 1
    ;;
  esac
}

main() {
  case "${1:-}" in
    -h|--help)
      packed_usage
      exit 0
      ;;
    --mount|-m)
      if detect_existing_bitlocker_mount && check_bitlocker_mount; then
        prompt -w "已经挂载: $readMount"
        exit 1
      fi
      run_mount_direct
      exit $?
      ;;
    --umount|-u)
      run_umount_direct
      exit $?
      ;;
    "")
      run_interactive
      exit $?
      ;;
    *)
      prompt -e "未知参数: $1"
      packed_usage
      exit 2
      ;;
  esac
}

main "$@"
MAIN
} >"$OUT_SH"

chmod 775 "$OUT_SH"
info "合并完成（$(wc -l <"$OUT_SH") 行）"

echo
echo "======== 将打进二进制的 config 快照（请仔细核对）========"
echo
awk '
  BEGIN { show=0 }
  /^# ---- config\.sh/ { show=1; print; next }
  /^# ---- mountB\.sh/ { exit }
  show { print }
' "$OUT_SH"
echo
echo "=========================================================="
echo
info "完整合并脚本: $OUT_SH"
info "（可另开编辑器再看一遍再决定是否 shc）"

if grep -Eq '^[[:space:]]*keyPass="[^"]+"' config.sh 2>/dev/null \
  || grep -Eq "^[[:space:]]*keyPass='[^']+'" config.sh 2>/dev/null; then
  warn "config.sh 里 keyPass 非空：会写进 $OUT_SH 明文。建议清空后再打包，运行时输入密码。"
fi

if [[ "$ASSUME_YES" -ne 1 ]]; then
  read -r -p "config 核对无误，继续用 shc 打包？[Y/n] " ans || true
  case "${ans:-Y}" in
    [yY]|[yY][eE][sS]|"") ;;
    *)
      info "已取消 shc。合并脚本仍保留在: $OUT_SH"
      exit 0
      ;;
  esac
fi

if [[ "$DO_SHC" -ne 1 ]]; then
  info "--no-shc：只生成了 $OUT_SH"
  exit 0
fi

if ! command -v shc >/dev/null 2>&1; then
  warn "未找到 shc（Debian 源通常无此包，见 ../README.md）。"
  warn "合并脚本已生成，装好 shc 后可执行:"
  warn "  shc -r -f \"$OUT_SH\" -o \"$OUT_BIN\""
  exit 1
fi

info "调用 shc …"
rm -f "$OUT_BIN" "${OUT_SH}.x.c" "${OUT_SH}.x" 2>/dev/null || true
if ! shc -r -f "$OUT_SH" -o "$OUT_BIN"; then
  die "shc 失败。合并脚本仍在: $OUT_SH"
fi
chmod 775 "$OUT_BIN" 2>/dev/null || true
if [[ ! -x "$OUT_BIN" && -x "${OUT_SH}.x" ]]; then
  mv -f "${OUT_SH}.x" "$OUT_BIN"
fi
rm -f "${OUT_SH}.x.c" 2>/dev/null || true
[[ -x "$OUT_BIN" ]] || die "shc 未生成可执行文件。合并脚本仍在: $OUT_SH"
info "完成: $OUT_BIN"
info "试运行: $OUT_BIN --help"
