#!/bin/bash
# 由 VeraCrypt/lib.sh、BitLocker/mountB.sh、rmount.sh 加载。
# 打包时 pack_shc.sh 会把本文件和 slot.py 嵌进单个脚本。

otp_slot_loaded() { :; }

otp_shred_file() {
  local f="$1"
  [ -n "$f" ] || return 0
  if [ -f "$f" ] && command -v shred >/dev/null 2>&1; then
    shred -u -n 1 -- "$f" 2>/dev/null || rm -f -- "$f"
  else
    rm -f -- "$f"
  fi
}

otp_tmp() {
  local d
  if [ -d /dev/shm ] && [ -w /dev/shm ]; then
    d=/dev/shm
  else
    d="${TMPDIR:-/tmp}"
  fi
  mktemp "$d/otp.XXXXXX"
}

# 打印 slot.py 路径。源码树里用 otp/slot.py；打包后写到 STATE_DIR。
otp_python() {
  local cand here
  if [ -n "${OTP_PY:-}" ] && [ -f "$OTP_PY" ]; then
    printf '%s\n' "$OTP_PY"
    return 0
  fi
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for cand in \
    "$here/slot.py" \
    "$here/../otp/slot.py" \
    "${LIB_DIR:-}/../otp/slot.py" \
    "${SCRIPT_DIR:-}/../otp/slot.py" \
    "${STATE_DIR:-}/slot.py"
  do
    if [ -n "$cand" ] && [ -f "$cand" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  if declare -F otp_write_embedded_py >/dev/null 2>&1; then
    otp_write_embedded_py || return 1
    printf '%s\n' "$OTP_PY"
    return 0
  fi
  return 1
}

otp_need_tools() {
  if ! command -v python3 >/dev/null 2>&1; then
    prompt -e "一次性码需要 python3。"
    return 1
  fi
  if ! command -v openssl >/dev/null 2>&1; then
    prompt -e "一次性码需要 openssl。"
    return 1
  fi
  return 0
}

# 用已经写在文件里的一次性码解开槽，结果放进 keyPass。
otp_unlock_code_file() {
  local py="$1" dir="$2" codefile="$3"
  local tmp meta slot
  tmp="$(otp_tmp)" || return 1
  meta="$(otp_tmp)" || {
    otp_shred_file "$tmp"
    return 1
  }
  chmod 600 "$tmp" "$meta" 2>/dev/null || true
  if ! python3 "$py" unlock --dir "$dir" --code-file "$codefile" --pass-file "$tmp" --slot-file "$meta" </dev/null; then
    otp_shred_file "$tmp"
    otp_shred_file "$meta"
    prompt -e "一次性码没有解开槽。"
    return 1
  fi
  keyPass=""
  IFS= read -r -d '' keyPass <"$tmp" || true
  slot="$(tr -d '\r\n' <"$meta")"
  otp_shred_file "$tmp"
  otp_shred_file "$meta"
  if [ -z "$keyPass" ] || [ -z "$slot" ] || [ ! -f "$slot" ]; then
    keyPass=""
    prompt -e "解开槽之后没有得到可用的口令。"
    return 1
  fi
  OTP_SLOT_FILE="$slot"
  OTP_ARMED=1
  prompt -i "这条码已解开成现有卷口令。卷本身的口令不会改。解密成功后只删除对应的槽。"
  prompt -k "槽" "$(basename "$slot")"
  return 0
}

otp_first_keyfile() {
  local dir="$1" f
  [ -d "$dir" ] || return 1
  for f in "$dir"/key-*; do
    if [ -f "$f" ]; then
      printf '%s\n' "$f"
      return 0
    fi
  done
  return 1
}

otp_use_keyfile() {
  local py="$1" keyfile="$2"
  local tmp meta slot
  tmp="$(otp_tmp)" || return 1
  meta="$(otp_tmp)" || {
    otp_shred_file "$tmp"
    return 1
  }
  chmod 600 "$tmp" "$meta" 2>/dev/null || true
  if ! python3 "$py" use-key --file "$keyfile" --pass-file "$tmp" --slot-file "$meta" </dev/null; then
    otp_shred_file "$tmp"
    otp_shred_file "$meta"
    prompt -e "密钥文件解不开。"
    return 1
  fi
  keyPass=""
  IFS= read -r -d '' keyPass <"$tmp" || true
  slot="$(tr -d '\r\n' <"$meta")"
  otp_shred_file "$tmp"
  otp_shred_file "$meta"
  if [ -z "$keyPass" ] || [ -z "$slot" ] || [ ! -f "$slot" ]; then
    keyPass=""
    prompt -e "密钥文件没有给出可用的口令。"
    return 1
  fi
  OTP_SLOT_FILE="$slot"
  OTP_ARMED=1
  prompt -i "密钥文件已解开成现有卷口令。卷本身的口令不会改。解密成功后只删除这一个文件。"
  prompt -k "文件" "$(basename "$slot")"
  return 0
}

# keyPass 已有内容就直接用。槽目录里有 key- 文件就用掉一个。
# 否则问一次：PIN、长码，或卷口令。
otp_accept_either() {
  local py entered tmp ident rc dir kf base any _s
  OTP_ARMED=0
  OTP_SLOT_FILE=""
  if [ -n "${keyPass:-}" ]; then
    prompt -m "使用 config.sh 里的口令。"
    return 0
  fi
  otp_need_tools || return 1
  py="$(otp_python)" || {
    prompt -e "找不到一次性码程序 slot.py。"
    return 1
  }
  if [ -n "${otpSlotDir:-}" ]; then
    kf="$(otp_first_keyfile "$otpSlotDir" || true)"
    if [ -n "$kf" ]; then
      prompt -i "使用密钥文件 $(basename "$kf")，成功后删除这一个。"
      otp_use_keyfile "$py" "$kf"
      return $?
    fi
  fi
  if [ ! -r /dev/tty ]; then
    prompt -e "没有终端。请在 config.sh 设置 keyPass，或在终端里运行。"
    return 1
  fi
  prompt -m "输入 PIN、一次性码，或直接输入卷口令。也可输入 key- 文件的路径。"
  IFS= read -rs entered </dev/tty || return 1
  printf '\n' >/dev/tty
  if [ -z "$entered" ]; then
    prompt -e "是空的，已停止。"
    return 1
  fi
  base="$(basename "$entered")"
  if [ -f "$entered" ] && [[ "$base" == key-* ]]; then
    otp_use_keyfile "$py" "$entered"
    return $?
  fi
  tmp="$(otp_tmp)" || return 1
  chmod 600 "$tmp" 2>/dev/null || true
  printf '%s' "$entered" >"$tmp" || {
    otp_shred_file "$tmp"
    return 1
  }
  entered=""
  ident="$(python3 "$py" classify --secret-file "$tmp")"
  rc=$?
  if [ "$rc" -eq 0 ] || [ "$rc" -eq 3 ]; then
    dir="${otpSlotDir:-}"
    if [ -z "$dir" ]; then
      if [ "$rc" -eq 3 ]; then
        prompt -m "这是 PIN。插入放槽文件的 U 盘，输入槽目录。"
      else
        prompt -m "这是一次性码。插入放槽文件的 U 盘，输入槽目录。"
      fi
      IFS= read -r dir </dev/tty || {
        otp_shred_file "$tmp"
        return 1
      }
    fi
    if [ ! -d "$dir" ]; then
      otp_shred_file "$tmp"
      prompt -e "槽目录不存在: $dir"
      return 1
    fi
    if [ "$rc" -eq 0 ] && [ ! -f "$dir/slot-$ident" ]; then
      otp_shred_file "$tmp"
      prompt -e "没有槽文件 slot-$ident。这串按一次性码处理，没有拿去当卷口令。"
      return 1
    fi
    if [ "$rc" -eq 3 ]; then
      any=""
      for _s in "$dir"/slot-*; do
        if [ -f "$_s" ]; then
          any=1
          break
        fi
      done
      if [ -z "$any" ]; then
        otp_shred_file "$tmp"
        prompt -e "目录里没有槽。这串数字按 PIN 处理，没有拿去当卷口令。"
        return 1
      fi
    fi
    otp_unlock_code_file "$py" "$dir" "$tmp"
    rc=$?
    otp_shred_file "$tmp"
    return "$rc"
  fi
  if [ "$rc" -eq 2 ]; then
    keyPass=""
    IFS= read -r -d '' keyPass <"$tmp" || true
    otp_shred_file "$tmp"
    if [ -z "$keyPass" ]; then
      prompt -e "口令是空的，已停止。"
      return 1
    fi
    prompt -i "按卷口令使用，不消耗一次性码。"
    return 0
  fi
  otp_shred_file "$tmp"
  prompt -e "无法判断这次输入。"
  return 1
}

# 解密成功后调用。删掉用过的槽，并清掉 shell 里的口令变量。
otp_burn_used_slot() {
  local f
  [ "${OTP_ARMED:-0}" = "1" ] || return 0
  OTP_ARMED=0
  f="${OTP_SLOT_FILE:-}"
  keyPass=""
  OTP_SLOT_FILE=""
  if [ -z "$f" ]; then
    return 0
  fi
  otp_shred_file "$f"
  if [ -e "$f" ]; then
    prompt -w "槽文件还在: $f"
    prompt -w "这条一次性码还能再解开它。拔掉 U 盘，回头手动删掉这个文件。"
    return 0
  fi
  prompt -i "已删除用过的槽 $(basename "$f")"
  return 0
}

# 口令已经在 keyPass 里。用伪终端喂给会自己读 /dev/tty 的程序（dislocker、tcplay）。
# 调用前先 sudo -v，参数里用 sudo -n，避免把卷口令写进 sudo 的密码提示。
otp_feed_tty() {
  local py tmp rc
  otp_need_tools || return 1
  py="$(otp_python)" || {
    prompt -e "找不到一次性码程序 slot.py。"
    return 1
  }
  if [ -z "${keyPass:-}" ]; then
    prompt -e "没有可送入的口令。"
    return 1
  fi
  tmp="$(otp_tmp)" || return 1
  chmod 600 "$tmp" 2>/dev/null || true
  printf '%s' "$keyPass" >"$tmp" || {
    otp_shred_file "$tmp"
    return 1
  }
  python3 "$py" feed --password-file "$tmp" --timeout "${OTP_FEED_TIMEOUT:-90}" -- "$@"
  rc=$?
  otp_shred_file "$tmp"
  return "$rc"
}

# BitLocker：otpMode=1 时走这里。卷口令和一次性码都能用。成功且用了码时删槽。
bitlocker_open_with_otp() {
  local flag rc
  case "${keyMode:-0}" in
    0) flag="-u" ;;
    1) flag="-p" ;;
    *)
      prompt -e "keyMode 只能是 0 或 1，当前是 ${keyMode:-}。"
      return 1
      ;;
  esac
  otp_accept_either || return 1
  if [ ! -r /dev/tty ]; then
    prompt -e "没有终端，不能确认 sudo。"
    return 1
  fi
  sudo -v </dev/tty || {
    prompt -e "sudo 没有通过，没法解密。"
    return 1
  }
  prompt -i "口令不放进命令行。"
  otp_feed_tty sudo -n "$DISLOCKER_BIN" "$pdev" "$flag" -- "$dislockMount"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    otp_burn_used_slot
  elif [ "${OTP_ARMED:-0}" = "1" ]; then
    prompt -w "解密没成功，槽还留着，这条码还能再用。"
  fi
  return "$rc"
}
