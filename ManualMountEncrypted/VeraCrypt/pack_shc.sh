#!/usr/bin/env bash
# 将 VeraCrypt 脚本 + 当前 config 打成「单个临时 .sh」，核对后再用 shc 编译。
#
# 用法:
#   ./pack_shc.sh              # 生成临时脚本 → 展示 config → 确认 → shc
#   ./pack_shc.sh --no-shc     # 只生成合并脚本，不调用 shc
#   ./pack_shc.sh --yes        # 不询问，直接 shc（仍会打印 config 摘要）
#
# 产物目录: ./build-shc/
#   mountV-packed.sh   合并后的 shell（可人工检查）
#   mountV             shc 生成的可执行文件（若本机有 shc）
#
# 二进制用法:
#   ./build-shc/mountV           # 交互挂/卸（同 mountV.sh）
#   ./build-shc/mountV --mount   # 直接挂（同 rmount.sh）
#   ./build-shc/mountV --umount  # 直接卸（同 urmount.sh）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

DO_SHC=1
ASSUME_YES=0
BUILD_DIR="$SCRIPT_DIR/build-shc"
OUT_SH="$BUILD_DIR/mountV-packed.sh"
OUT_BIN="$BUILD_DIR/mountV"

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
[[ -f lib.sh ]] || die "缺少 lib.sh"

mkdir -p "$BUILD_DIR"

# 从 lib.sh 去掉 shebang / source，只保留函数体（从 VERACRYPT_BIN= 起）
lib_body() {
  awk '
    BEGIN { skip = 1 }
    /^VERACRYPT_BIN=/ { skip = 0 }
    skip == 0 { print }
  ' lib.sh
}

strip_shebang() {
  local f="$1"
  awk 'NR==1 && /^#!/ { next } { print }' "$f"
}

info "生成合并脚本: $OUT_SH"

{
  cat <<'HDR'
#!/bin/bash
# =============================================================================
# 本文件由 pack_shc.sh 自动生成，请勿手改长期维护。
# 内含：Profile + config（打包时快照）+ lib + 统一入口
# 注：须用 #!/bin/bash（勿用 env）；shc 不认 #!/usr/bin/env bash。
# 勿加 set -e：comfirmy 用返回值 1/2 表示是/否，与 mountV.sh 一致。
# =============================================================================

# shc 运行时脚本可能在临时目录；状态文件放到用户目录。
# 相对路径的 VERACRYPT_CUSTOM 按「可执行文件所在目录」解析。
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
  STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ManualMountEncrypted-VeraCrypt"
  mkdir -p "$STATE_DIR"
  LIB_DIR="$STATE_DIR"
}

resolve_runtime_dirs

HDR

  echo "# ---- Profile.sh ----"
  strip_shebang Profile.sh
  echo
  echo "# ---- config.sh（打包快照，改配置请改源码旁 config.sh 后重新打包）----"
  strip_shebang config.sh
  echo
  echo "# ---- lib.sh（函数）----"
  lib_body
  cat <<'MAIN'

# 打包后：相对 VERACRYPT_CUSTOM 按二进制目录解析
resolve_veracrypt_bin() {
  if [ -n "${VERACRYPT_BIN:-}" ] && [ -x "$VERACRYPT_BIN" ]; then
    return 0
  fi
  local custom="$VERACRYPT_CUSTOM"
  if [ -n "$custom" ] && [[ "$custom" != /* ]]; then
    custom="$PACK_BIN_DIR/$custom"
  fi
  if [ -n "${VERACRYPT_CUSTOM:-}" ]; then
    if [ -x "$custom" ]; then
      VERACRYPT_BIN="$custom"
      prompt -i "使用指定的 veracrypt: $VERACRYPT_BIN"
      return 0
    fi
    prompt -e "VERACRYPT_CUSTOM 不可执行: ${VERACRYPT_CUSTOM}"
    return 1
  fi
  if command -v veracrypt >/dev/null 2>&1; then
    VERACRYPT_BIN="$(command -v veracrypt)"
    prompt -i "使用系统 veracrypt: $VERACRYPT_BIN"
    return 0
  fi
  prompt -w "未找到 veracrypt，尝试 apt install..."
  if sudo apt install veracrypt -y; then
    if command -v veracrypt >/dev/null 2>&1; then
      VERACRYPT_BIN="$(command -v veracrypt)"
      prompt -i "安装成功，使用系统 veracrypt: $VERACRYPT_BIN"
      return 0
    fi
  fi
  prompt -e "仍未找到 veracrypt。"
  return 1
}

# 覆盖：状态写到 STATE_DIR
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
VeraCrypt 挂载工具（pack_shc 打包版）

用法:
  $(basename "$0")              交互：已挂载问卸载；已解密未挂载问挂载或取消解密；否则问挂载
  $(basename "$0") --mount|-m   直接挂载（同 rmount.sh）
  $(basename "$0") --umount|-u  直接卸载（同 urmount.sh）
  $(basename "$0") -h|--help    帮助
EOF
}

main() {
  case "${1:-}" in
    -h|--help)
      packed_usage
      exit 0
      ;;
    --mount|-m)
      if detect_existing_veracrypt_mount; then
        prompt -w "已经挂载: $readMount"
        exit 1
      fi
      mount_veracrypt
      exit $?
      ;;
    --umount|-u)
      umount_veracrypt
      exit $?
      ;;
    "")
      interactive_veracrypt
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
  /^# ---- lib\.sh/ { exit }
  show { print }
' "$OUT_SH"
echo
echo "=========================================================="
echo
info "完整合并脚本: $OUT_SH"
info "（可另开编辑器再看一遍再决定是否 shc）"

# keyPass 非空会进 packed.sh 明文，强烈不建议
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
# -r 放松安全（允许其它用户执行）；按需可去掉
rm -f "$OUT_BIN" "${OUT_SH}.x.c" "${OUT_SH}.x" 2>/dev/null || true
if ! shc -r -f "$OUT_SH" -o "$OUT_BIN"; then
  die "shc 失败。合并脚本仍在: $OUT_SH"
fi
chmod 775 "$OUT_BIN" 2>/dev/null || true
# shc 有的版本输出名为 xxx.sh.x
if [[ ! -x "$OUT_BIN" && -x "${OUT_SH}.x" ]]; then
  mv -f "${OUT_SH}.x" "$OUT_BIN"
fi
rm -f "${OUT_SH}.x.c" 2>/dev/null || true
[[ -x "$OUT_BIN" ]] || die "shc 未生成可执行文件。合并脚本仍在: $OUT_SH"
info "完成: $OUT_BIN"
info "试运行: $OUT_BIN --help"
