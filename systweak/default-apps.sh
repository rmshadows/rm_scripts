#!/usr/bin/env bash
# 交互式查看 / 修改用户级默认应用（类似 update-alternatives，Tab 补全）
# 用法:
#   ./default-apps.sh                 # 交互：选角色 → 选应用
#   ./default-apps.sh fm              # 直接配置文件管理器
#   ./default-apps.sh --status
#   ./default-apps.sh --apply fm nautilus   # 非交互
#   ./default-apps.sh --undo
set -euo pipefail

NAME="default-apps"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"

log()  { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[x] $*" >&2; exit 1; }

if [[ $EUID -eq 0 ]]; then
  die "不要用 root/sudo。默认应用是用户级设置（写入 ~/.config/mimeapps.list）"
fi
command -v xdg-mime >/dev/null 2>&1 || die "需要 xdg-mime（包: xdg-utils）"

# ---------- 角色定义 ----------
# 输出: 短名<TAB>中文名<TAB>主 MIME<TAB>其余 MIME（空格分隔）
role_spec() {
  case "$1" in
    fm|file-manager|filemanager|文件管理器)
      printf '%s\t%s\t%s\t%s\n' fm "文件管理器" "inode/directory" "inode/mount-point"
      ;;
    browser|web|浏览器)
      printf '%s\t%s\t%s\t%s\n' browser "浏览器" "x-scheme-handler/http" "x-scheme-handler/https x-scheme-handler/about text/html application/xhtml+xml"
      ;;
    mail|email|邮件)
      printf '%s\t%s\t%s\t%s\n' mail "邮件" "x-scheme-handler/mailto" "message/rfc822"
      ;;
    editor|text|编辑器|文本编辑器)
      printf '%s\t%s\t%s\t%s\n' editor "文本编辑器" "text/plain" ""
      ;;
    image|photo|图片|图片查看器)
      printf '%s\t%s\t%s\t%s\n' image "图片查看器" "image/jpeg" "image/png image/gif image/webp image/bmp image/tiff image/svg+xml image/heif image/avif"
      ;;
    pdf|PDF)
      printf '%s\t%s\t%s\t%s\n' pdf "PDF 阅读器" "application/pdf" ""
      ;;
    video|视频|视频播放器)
      printf '%s\t%s\t%s\t%s\n' video "视频播放器" "video/mp4" "video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg video/ogg"
      ;;
    audio|music|音频|音频播放器)
      printf '%s\t%s\t%s\t%s\n' audio "音频播放器" "audio/mpeg" "audio/flac audio/ogg audio/x-wav audio/mp4 audio/aac audio/x-vorbis+ogg audio/x-opus+ogg"
      ;;
    archive|zip|压缩|压缩管理)
      printf '%s\t%s\t%s\t%s\n' archive "压缩包" "application/zip" "application/x-tar application/gzip application/x-compressed-tar application/x-xz-compressed-tar application/x-7z-compressed application/vnd.rar application/x-rar"
      ;;
    terminal|终端)
      printf '%s\t%s\t%s\t%s\n' terminal "终端" "x-scheme-handler/terminal" ""
      ;;
    *)
      return 1
      ;;
  esac
}

KNOWN_ROLES=(fm browser mail editor image pdf video audio archive terminal)

role_category() {
  case "$1" in
    fm) echo FileManager ;;
    browser) echo WebBrowser ;;
    mail) echo Email ;;
    editor) echo TextEditor ;;
    terminal) echo TerminalEmulator ;;
    *) echo "" ;;
  esac
}

normalize_role() {
  local spec
  spec="$(role_spec "$1" 2>/dev/null)" || return 1
  printf '%s\n' "${spec%%$'\t'*}"
}

# ---------- desktop 文件 ----------
app_dirs() {
  local -a raw=()
  local d
  raw+=("${XDG_DATA_HOME:-$HOME/.local/share}/applications")
  raw+=("$HOME/.local/share/flatpak/exports/share/applications")
  raw+=("/var/lib/flatpak/exports/share/applications")
  local IFS=':'
  # shellcheck disable=SC2086
  for d in ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
    raw+=("$d/applications")
  done
  unset IFS
  local -A seen=()
  for d in "${raw[@]}"; do
    [[ -n "$d" && -d "$d" ]] || continue
    [[ -n "${seen[$d]:-}" ]] && continue
    seen[$d]=1
    printf '%s\n' "$d"
  done
}

# id<TAB>path  （同一 id 只保留最先找到的，用户目录优先；进程内缓存）
_DESKTOPS_DATA=""
declare -A DESKTOP_PATH=()
all_desktops() {
  if [[ -z "$_DESKTOPS_DATA" ]]; then
    local dir f id
    local -A seen=()
    local -a lines=()
    while IFS= read -r dir; do
      while IFS= read -r -d '' f; do
        id="$(basename "$f")"
        [[ -n "${seen[$id]:-}" ]] && continue
        seen[$id]=1
        DESKTOP_PATH[$id]="$f"
        lines+=("${id}"$'\t'"${f}")
      done < <(find "$dir" -type f -name '*.desktop' -print0 2>/dev/null)
    done < <(app_dirs)
    if ((${#lines[@]})); then
      printf -v _DESKTOPS_DATA '%s\n' "${lines[@]}"
    else
      _DESKTOPS_DATA=$'\n'
    fi
  fi
  printf '%s' "$_DESKTOPS_DATA"
  [[ "$_DESKTOPS_DATA" == *$'\n' ]] || printf '\n'
}

desktop_field() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  awk -F= -v key="$key" '
    /^\[/ { ok = ($0 ~ /^\[Desktop Entry\]/) }
    !ok { next }
    {
      line=$0
      sub(/\r$/, "", line)
      eq = index(line, "=")
      if (eq == 0) next
      k = substr(line, 1, eq-1)
      v = substr(line, eq+1)
    }
    k == key "[zh_CN]" { zhcn=v }
    k == key "[zh]" { zh=v }
    k == key { def=v }
    END {
      if (zhcn != "") print zhcn
      else if (zh != "") print zh
      else print def
    }
  ' "$file"
}

desktop_hidden() {
  local v
  v="$(desktop_field "$1" Hidden)"
  [[ "${v,,}" == "true" ]]
}

desktop_nodisplay() {
  local v
  v="$(desktop_field "$1" NoDisplay)"
  [[ "${v,,}" == "true" ]]
}

desktop_has_mime() {
  local file="$1" mime="$2" mimes
  mimes="$(desktop_field "$file" MimeType)"
  [[ -n "$mimes" ]] || return 1
  local IFS=';'
  local t
  for t in $mimes; do
    [[ "$t" == "$mime" ]] && return 0
  done
  return 1
}

desktop_has_category() {
  local file="$1" catg="$2" cats
  cats="$(desktop_field "$file" Categories)"
  [[ -n "$cats" ]] || return 1
  local IFS=';'
  local t
  for t in $cats; do
    [[ "$t" == "$catg" ]] && return 0
  done
  return 1
}

find_desktop_path() {
  local id="$1" p
  [[ "$id" == *.desktop ]] || id="${id}.desktop"
  all_desktops >/dev/null
  p="${DESKTOP_PATH[$id]:-}"
  [[ -n "$p" ]] || return 1
  printf '%s\n' "$p"
}

desktop_label() {
  local id="$1" path name
  path="$(find_desktop_path "$id" 2>/dev/null || true)"
  if [[ -n "$path" ]]; then
    name="$(desktop_field "$path" Name)"
    if [[ -n "$name" ]]; then
      printf '%s  (%s)\n' "$id" "$name"
      return 0
    fi
  fi
  printf '%s\n' "$id"
}

query_mime() {
  xdg-mime query default "$1" 2>/dev/null || true
}

desktop_id_core() {
  local id="${1%.desktop}"
  printf '%s\n' "${id##*.}"
}

fold_key() {
  local s="${1,,}"
  s="${s%.desktop}"
  s="${s//-/}"
  s="${s//_/}"
  s="${s//./}"
  printf '%s\n' "$s"
}

# 短名 / 文件名 / 显示名 解析成唯一 .desktop id
resolve_desktop() {
  local hint="$1"
  [[ -n "$hint" ]] || die "未指定应用"
  local id
  if [[ -f "$hint" && "$hint" == *.desktop ]]; then
    id="$(basename "$hint")"
    find_desktop_path "$id" >/dev/null || die "找不到 desktop: $id"
    printf '%s\n' "$id"
    return 0
  fi

  local want="${hint##*/}"
  local want_id="$want"
  [[ "$want_id" == *.desktop ]] || want_id="${want_id}.desktop"
  local lwant
  lwant="$(fold_key "$want")"

  local did path name core ldid score max=0
  local -a cand=()
  local -A cand_score=()

  while IFS=$'\t' read -r did path; do
    [[ -n "$did" ]] || continue
    desktop_hidden "$path" && continue
    if [[ "$did" == "$want_id" ]]; then
      printf '%s\n' "$did"
      return 0
    fi
    desktop_nodisplay "$path" && continue

    score=0
    core="$(fold_key "$(desktop_id_core "$did")")"
    ldid="$(fold_key "$did")"
    if [[ "$core" == "$lwant" || "$ldid" == "$lwant" ]]; then
      score=100
    elif [[ "$core" == "$lwant"* ]]; then
      score=40
    elif [[ "$ldid" == *"$lwant"* || "$core" == *"$lwant"* ]]; then
      score=20
    else
      name="$(desktop_field "$path" Name)"
      if [[ -n "$name" && "${name,,}" == *"${want,,}"* ]]; then
        score=10
      fi
    fi
    ((score > 0)) || continue
    cand+=("$did")
    cand_score[$did]="$score"
    if ((score > max)); then
      max=$score
    fi
  done < <(all_desktops)

  local -a best=()
  for did in "${cand[@]}"; do
    if (( cand_score[$did] == max )); then
      best+=("$did")
    fi
  done

  if ((${#best[@]} == 1)); then
    printf '%s\n' "${best[0]}"
    return 0
  fi
  if ((${#best[@]} == 0)); then
    die "找不到应用: $hint（可 --list 查看可用项，或给出完整 foo.desktop）"
  fi
  warn "不唯一，请指定完整 id："
  local c
  for c in "${best[@]}"; do
    echo "    $(desktop_label "$c")" >&2
  done
  exit 1
}

# ---------- 备份 / 还原 ----------
ensure_backup_dir() {
  mkdir -p "$BACKUP_DIR/roles"
}

backup_mimeapps_once() {
  ensure_backup_dir
  if [[ -f "$MIMEAPPS" && ! -f "$BACKUP_DIR/mimeapps.list.bak" ]]; then
    cp -a "$MIMEAPPS" "$BACKUP_DIR/mimeapps.list.bak"
  elif [[ ! -f "$MIMEAPPS" && ! -f "$BACKUP_DIR/mimeapps.list.missing" ]]; then
    touch "$BACKUP_DIR/mimeapps.list.missing"
  fi
}

role_backup_file() {
  local key="$1"
  key="${key//\//_}"
  key="${key//+/_}"
  printf '%s\n' "$BACKUP_DIR/roles/$key"
}

backup_line_once() {
  local file="$1" line="$2"
  [[ -f "$file" ]] || { printf '%s\n' "$line" >>"$file"; return 0; }
  local key="${line%%$'\t'*}"
  # mime / xdg-settings 用第 2 列去重；gsettings 用 2+3 列
  local k2 k3
  k2="$(printf '%s\n' "$line" | cut -f2)"
  k3="$(printf '%s\n' "$line" | cut -f3)"
  if [[ "$key" == "gsettings" ]]; then
    grep -qxF "$line" "$file" 2>/dev/null && return 0
    awk -F '\t' -v a="$k2" -v b="$k3" '$1=="gsettings" && $2==a && $3==b {found=1} END{exit !found}' "$file" && return 0
  else
    awk -F '\t' -v t="$key" -v k="$k2" '$1==t && $2==k {found=1} END{exit !found}' "$file" && return 0
  fi
  printf '%s\n' "$line" >>"$file"
}

unset_mime_default() {
  local mime="$1"
  [[ -f "$MIMEAPPS" ]] || return 0
  local tmp
  tmp="$(mktemp)"
  awk -v mime="$mime" '
    /^\[/ { sec=$0 }
    sec=="[Default Applications]" && index($0, mime "=")==1 { next }
    { print }
  ' "$MIMEAPPS" >"$tmp"
  mv "$tmp" "$MIMEAPPS"
}

save_mime_prev() {
  local bfile="$1" mime="$2"
  backup_line_once "$bfile" "$(printf 'mime\t%s\t%s' "$mime" "$(query_mime "$mime")")"
}

set_mime() {
  local desktop="$1" mime="$2"
  xdg-mime default "$desktop" "$mime"
}

restore_backup_file() {
  local bfile="$1"
  [[ -f "$bfile" ]] || return 0
  local typ a b c
  while IFS=$'\t' read -r typ a b c || [[ -n "${typ:-}" ]]; do
    [[ -n "$typ" ]] || continue
    case "$typ" in
      mime)
        if [[ -n "$b" ]]; then
          xdg-mime default "$b" "$a"
          log "还原 MIME $a -> $b"
        else
          unset_mime_default "$a"
          log "还原 MIME $a（原先未设置，已从 mimeapps.list 去掉）"
        fi
        ;;
      xdg-settings)
        if command -v xdg-settings >/dev/null 2>&1 && [[ -n "$b" ]]; then
          xdg-settings set "$a" "$b" 2>/dev/null || warn "xdg-settings 还原失败: $a"
          log "还原 xdg-settings $a -> $b"
        fi
        ;;
      gsettings)
        if command -v gsettings >/dev/null 2>&1; then
          gsettings set "$a" "$b" "$c" 2>/dev/null || warn "gsettings 还原失败: $a $b"
          log "还原 gsettings $a $b"
        fi
        ;;
      xfce-helpers)
        local hr="$HOME/.config/xfce4/helpers.rc"
        if [[ -f "$hr" ]]; then
          if grep -q "^${a}=" "$hr"; then
            sed -i "s|^${a}=.*|${a}=${b}|" "$hr"
          else
            printf '%s=%s\n' "$a" "$b" >>"$hr"
          fi
          log "还原 XFCE $a=$b"
        fi
        ;;
    esac
  done <"$bfile"
}

# ---------- 交互（类似 update-alternatives） ----------
need_tty() {
  [[ -t 0 && -t 1 ]] || die "交互模式需要终端。只查看用 --status；非交互设置用 --apply 角色 应用"
}

restore_tab_complete() {
  bind '"\t": complete' 2>/dev/null || true
}

READ_COMPLETE_ARR=()
_default_apps_readline_complete() {
  local cur="${READLINE_LINE:-}"
  local -a matches=()
  local w p m lcur
  if [[ -z "$cur" ]]; then
    printf '\n先打几个字母或序号再 Tab。\n' >&2
    return
  fi
  for w in "${READ_COMPLETE_ARR[@]+"${READ_COMPLETE_ARR[@]}"}"; do
    [[ "$w" == "$cur"* ]] && matches+=("$w")
  done
  if ((${#matches[@]} == 0)); then
    lcur="${cur,,}"
    for w in "${READ_COMPLETE_ARR[@]+"${READ_COMPLETE_ARR[@]}"}"; do
      [[ "${w,,}" == "$lcur"* ]] && matches+=("$w")
    done
  fi
  if ((${#matches[@]} == 0)); then
    return
  fi
  if ((${#matches[@]} == 1)); then
    READLINE_LINE="${matches[0]}"
    READLINE_POINT=${#READLINE_LINE}
    return
  fi
  p="${matches[0]}"
  for m in "${matches[@]}"; do
    while [[ -n "$p" && "$m" != "$p"* ]]; do
      p="${p%?}"
    done
  done
  if [[ -n "$p" && "$p" != "$cur" ]]; then
    READLINE_LINE="$p"
    READLINE_POINT=${#READLINE_LINE}
  fi
  printf '\n' >&2
  printf '%s  ' "${matches[@]}" >&2
  printf '\n' >&2
}

read_with_complete() {
  local prompt="$1"
  shift
  READ_COMPLETE_ARR=("$@")
  bind -x '"\t": _default_apps_readline_complete' 2>/dev/null || true
  REPLY=""
  read -e -p "$prompt" REPLY || true
  restore_tab_complete
}

vis_pad() {
  local s="$1" target="$2" c
  local -i vis=0 i
  for ((i = 0; i < ${#s}; i++)); do
    c="${s:i:1}"
    if [[ "$c" =~ [[:ascii:]] ]]; then
      vis+=1
    else
      vis+=2
    fi
  done
  printf '%s' "$s"
  while ((vis < target)); do
    printf ' '
    vis+=1
  done
}

current_for_role() {
  local raw="$1" spec role primary cur exec_cur id path bin
  if [[ "$raw" == */* ]]; then
    query_mime "$raw"
    return 0
  fi
  spec="$(role_spec "$raw")" || return 1
  IFS=$'\t' read -r role _ primary _ <<<"$spec"
  if [[ "$role" == "terminal" ]]; then
    cur="$(query_mime "$primary")"
    if [[ -n "$cur" ]]; then
      printf '%s\n' "$cur"
      return 0
    fi
    if command -v gsettings >/dev/null 2>&1 && gsettings list-keys org.gnome.desktop.default-applications.terminal >/dev/null 2>&1; then
      exec_cur="$(gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null || true)"
      exec_cur="${exec_cur#\'}"
      exec_cur="${exec_cur%\'}"
      if [[ -n "$exec_cur" ]]; then
        while IFS=$'\t' read -r id path; do
          [[ -n "$id" ]] || continue
          desktop_has_category "$path" TerminalEmulator || continue
          bin="$(desktop_exec_bin "$path")"
          if [[ "$bin" == "$exec_cur" || "$(basename "$bin")" == "$(basename "$exec_cur")" ]]; then
            printf '%s\n' "$id"
            return 0
          fi
        done < <(all_desktops)
      fi
    fi
    printf '\n'
    return 0
  fi
  query_mime "$primary"
}

# 填 CAND_IDS / CAND_NAMES
collect_candidates() {
  local raw="$1"
  CAND_IDS=()
  CAND_NAMES=()
  local spec role primary mime catg cur id path name
  local match_cat match_mime is_cur
  local -a ids=() names=()

  if [[ "$raw" == */* ]]; then
    role=""
    primary="$raw"
    mime="$raw"
    catg=""
  else
    spec="$(role_spec "$raw")" || return 1
    IFS=$'\t' read -r role _ primary _ <<<"$spec"
    mime="$primary"
    catg="$(role_category "$role")"
    if [[ "$role" == "terminal" ]]; then
      mime=""
    fi
  fi
  cur="$(current_for_role "$raw")"

  while IFS=$'\t' read -r id path; do
    [[ -n "$id" ]] || continue
    desktop_hidden "$path" && continue
    is_cur=0
    [[ -n "$cur" && "$id" == "$cur" ]] && is_cur=1
    if [[ "$is_cur" -eq 0 ]] && desktop_nodisplay "$path"; then
      continue
    fi
    match_cat=0
    match_mime=0
    [[ -n "$catg" ]] && desktop_has_category "$path" "$catg" && match_cat=1
    [[ -n "$mime" ]] && desktop_has_mime "$path" "$mime" && match_mime=1
    if [[ -n "$catg" ]]; then
      ((match_cat == 1 || is_cur == 1)) || continue
    else
      ((match_mime == 1 || is_cur == 1)) || continue
    fi
    name="$(desktop_field "$path" Name)"
    if [[ "$is_cur" -eq 1 ]]; then
      ids=("$id" "${ids[@]+"${ids[@]}"}")
      names=("$name" "${names[@]+"${names[@]}"}")
    else
      ids+=("$id")
      names+=("$name")
    fi
  done < <(all_desktops)

  CAND_IDS=("${ids[@]+"${ids[@]}"}")
  CAND_NAMES=("${names[@]+"${names[@]}"}")
}

print_candidates() {
  local raw="$1"
  local spec role label primary n i mark cur
  if [[ "$raw" == */* ]]; then
    role="mime"
    label="$raw"
    primary="$raw"
  else
    spec="$(role_spec "$raw")" || return 1
    IFS=$'\t' read -r role label primary _ <<<"$spec"
  fi
  collect_candidates "$raw"
  n=${#CAND_IDS[@]}
  cur="$(current_for_role "$raw")"
  echo
  echo "有 ${n} 个候选项用于「${label}」(${primary})。"
  echo
  printf "  "
  vis_pad "选择" 6
  vis_pad "应用" 42
  echo "名称"
  echo "------------------------------------------------------------"
  if ((n == 0)); then
    echo "  （没有找到候选应用）"
    echo
    return 1
  fi
  for i in "${!CAND_IDS[@]}"; do
    mark=" "
    [[ "${CAND_IDS[$i]}" == "$cur" ]] && mark="*"
    printf "%s " "$mark"
    vis_pad "$((i + 1))" 6
    vis_pad "${CAND_IDS[$i]}" 42
    printf "%s\n" "${CAND_NAMES[$i]}"
  done
  echo "------------------------------------------------------------"
  echo "* 表示当前正在使用"
  echo
}

match_cand_input() {
  local input="$1"
  local n=${#CAND_IDS[@]}
  local i core
  PICKED_DESKTOP=""
  [[ -n "$input" ]] || return 1
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    if ((input >= 1 && input <= n)); then
      PICKED_DESKTOP="${CAND_IDS[$((input - 1))]}"
      return 0
    fi
    warn "序号超出范围（1-$n）。"
    return 1
  fi
  for i in "${!CAND_IDS[@]}"; do
    if [[ "${CAND_IDS[$i]}" == "$input" || "${CAND_IDS[$i]}" == "${input}.desktop" ]]; then
      PICKED_DESKTOP="${CAND_IDS[$i]}"
      return 0
    fi
  done
  for i in "${!CAND_IDS[@]}"; do
    core="$(desktop_id_core "${CAND_IDS[$i]}")"
    if [[ "${core,,}" == "${input,,}" || "$(fold_key "$core")" == "$(fold_key "$input")" ]]; then
      PICKED_DESKTOP="${CAND_IDS[$i]}"
      return 0
    fi
  done
  local -a hits=()
  for i in "${!CAND_IDS[@]}"; do
    if [[ "${CAND_IDS[$i],,}" == *"${input,,}"* || "${CAND_NAMES[$i],,}" == *"${input,,}"* ]]; then
      hits+=("${CAND_IDS[$i]}")
    fi
  done
  if ((${#hits[@]} == 1)); then
    PICKED_DESKTOP="${hits[0]}"
    return 0
  fi
  if ((${#hits[@]} > 1)); then
    warn "不唯一，请用序号或完整 id："
    for i in "${hits[@]}"; do
      echo "    $i" >&2
    done
    return 1
  fi
  # 列表外仍允许完整解析（例如手动指定）
  PICKED_DESKTOP="$(resolve_desktop "$input")"
}

PICKED_DESKTOP=""
PICKED_ROLE=""

pick_app_for() {
  local raw="$1" cur input
  local -a words=()
  local i core
  PICKED_DESKTOP=""
  print_candidates "$raw" || return 1
  cur="$(current_for_role "$raw")"
  words=()
  for i in "${!CAND_IDS[@]}"; do
    words+=("$((i + 1))" "${CAND_IDS[$i]}")
    core="$(desktop_id_core "${CAND_IDS[$i]}")"
    [[ -n "$core" ]] && words+=("$core")
    [[ -n "${CAND_NAMES[$i]}" ]] && words+=("${CAND_NAMES[$i]}")
  done
  read_with_complete "按 <回车> 保留当前[*]，输入序号或名称（Tab 补全），q 取消: " "${words[@]}"
  input="${REPLY:-}"
  if [[ -z "$input" ]]; then
    log "保留当前: ${cur:-（未设置）}"
    return 1
  fi
  if [[ "$input" == "q" || "$input" == "Q" ]]; then
    log "已取消"
    return 1
  fi
  match_cand_input "$input" || return 1
  [[ -n "$PICKED_DESKTOP" ]] || return 1
  if [[ -n "$cur" && "$PICKED_DESKTOP" == "$cur" ]]; then
    log "已是当前默认，未修改"
    return 1
  fi
  return 0
}

pick_role() {
  local r spec label primary cur i n input
  local -a roles=() labels=() words=()
  PICKED_ROLE=""
  echo
  echo "用户默认应用（类似 update-alternatives；Tab 可补全）"
  echo
  printf "  "
  vis_pad "选择" 6
  vis_pad "角色" 14
  echo "当前"
  echo "------------------------------------------------------------"
  for r in "${KNOWN_ROLES[@]}"; do
    spec="$(role_spec "$r")"
    IFS=$'\t' read -r _ label primary _ <<<"$spec"
    cur="$(current_for_role "$r")"
    if [[ -n "$cur" ]]; then
      cur="$(desktop_label "$cur")"
    elif [[ "$r" == "terminal" ]] && command -v gsettings >/dev/null 2>&1; then
      if gsettings list-keys org.gnome.desktop.default-applications.terminal >/dev/null 2>&1; then
        cur="gsettings $(gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null || true)"
      else
        cur="（未设置）"
      fi
    else
      cur="（未设置）"
    fi
    roles+=("$r")
    labels+=("$label")
    printf "  "
    vis_pad "${#roles[@]}" 6
    vis_pad "$label" 14
    printf "%s\n" "$cur"
  done
  echo "------------------------------------------------------------"
  echo
  n=${#roles[@]}
  words=()
  for i in "${!roles[@]}"; do
    words+=("$((i + 1))" "${roles[$i]}" "${labels[$i]}")
  done
  read_with_complete "输入序号或角色名（Tab 补全），回车退出: " "${words[@]}"
  input="${REPLY:-}"
  [[ -n "$input" ]] || return 1
  if [[ "$input" == "q" || "$input" == "Q" ]]; then
    return 1
  fi
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    if ((input >= 1 && input <= n)); then
      PICKED_ROLE="${roles[$((input - 1))]}"
      return 0
    fi
    warn "序号超出范围。"
    return 1
  fi
  PICKED_ROLE="$(normalize_role "$input")" && return 0
  warn "未知角色: $input"
  return 1
}

cmd_interactive() {
  local role="${1:-}" once=0 ans
  need_tty
  trap restore_tab_complete EXIT
  [[ -n "$role" ]] && once=1
  while true; do
    if [[ -z "$role" ]]; then
      pick_role || break
      role="$PICKED_ROLE"
    fi
    cmd_apply_role "$role" ""
    [[ "$once" -eq 1 ]] && break
    echo
    ans=""
    read -r -p "继续修改其它默认应用? [Y/n] " ans || true
    case "${ans:-Y}" in
      n | N | q | Q | no | NO) break ;;
    esac
    role=""
  done
}

# ---------- 应用变更 ----------
desktop_exec_bin() {
  local path="$1" exec
  exec="$(desktop_field "$path" Exec)"
  exec="${exec%% *}"
  exec="${exec#\"}"
  exec="${exec%\"}"
  printf '%s\n' "$exec"
}

apply_mimes() {
  local desktop="$1"
  shift
  local mime
  for mime in "$@"; do
    [[ -n "$mime" ]] || continue
    set_mime "$desktop" "$mime"
  done
}

mimes_to_set() {
  # stdout: mime 列表。主 MIME 必设；其余仅当 desktop 声明了该 MIME 才设。
  local path="$1" primary="$2"
  shift 2
  printf '%s\n' "$primary"
  local m
  for m in "$@"; do
    [[ -n "$m" && "$m" != "$primary" ]] || continue
    if [[ -n "$path" ]] && desktop_has_mime "$path" "$m"; then
      printf '%s\n' "$m"
    fi
  done
}

cmd_apply_role() {
  local raw="$1" app="${2:-}"
  local spec role label primary extras path desktop bfile
  local -a extra_arr=() set_list=()

  if [[ -z "$app" ]]; then
    pick_app_for "$raw" || return 0
    app="$PICKED_DESKTOP"
  fi

  if [[ "$raw" == */* ]]; then
    desktop="$(resolve_desktop "$app")"
    path="$(find_desktop_path "$desktop" || true)"
    ensure_backup_dir
    backup_mimeapps_once
    bfile="$(role_backup_file "mime_${raw}")"
    if [[ ! -f "$bfile" ]]; then
      save_mime_prev "$bfile" "$raw"
      log "已备份原默认: $raw"
    fi
    set_mime "$desktop" "$raw"
    log "已设置 $raw -> $desktop"
    echo "当前: $(desktop_label "$(query_mime "$raw")")"
    return 0
  fi

  spec="$(role_spec "$raw")" || die "未知角色: $raw（见 --help）"
  IFS=$'\t' read -r role label primary extras <<<"$spec"
  # shellcheck disable=SC2206
  extra_arr=($extras)

  if [[ "$role" == "terminal" ]]; then
    cmd_apply_terminal "$app"
    return 0
  fi

  desktop="$(resolve_desktop "$app")"
  path="$(find_desktop_path "$desktop" || true)"
  [[ -n "$path" ]] || die "找不到 desktop 文件: $desktop"

  ensure_backup_dir
  backup_mimeapps_once
  bfile="$(role_backup_file "$role")"

  mapfile -t set_list < <(mimes_to_set "$path" "$primary" "${extra_arr[@]}")

  if [[ ! -f "$bfile" ]]; then
    local m
    for m in "${set_list[@]}"; do
      save_mime_prev "$bfile" "$m"
    done
    if [[ "$role" == "browser" ]] && command -v xdg-settings >/dev/null 2>&1; then
      backup_line_once "$bfile" "$(printf 'xdg-settings\tdefault-web-browser\t%s' "$(xdg-settings get default-web-browser 2>/dev/null || true)")"
    fi
    if [[ "$role" == "mail" ]] && command -v xdg-settings >/dev/null 2>&1; then
      backup_line_once "$bfile" "$(printf 'xdg-settings\tdefault-url-scheme-handler mailto\t%s' "$(xdg-settings get default-url-scheme-handler mailto 2>/dev/null || true)")"
    fi
    log "已备份「$label」原默认"
  fi

  apply_mimes "$desktop" "${set_list[@]}"
  if [[ "$role" == "browser" ]] && command -v xdg-settings >/dev/null 2>&1; then
    xdg-settings set default-web-browser "$desktop" 2>/dev/null || warn "xdg-settings 设置浏览器失败（无图形会话时常见）"
  fi
  if [[ "$role" == "mail" ]] && command -v xdg-settings >/dev/null 2>&1; then
    xdg-settings set default-url-scheme-handler mailto "$desktop" 2>/dev/null || warn "xdg-settings 设置邮件失败"
  fi
  log "已设置 $label -> $desktop"
  echo "当前: $(desktop_label "$(query_mime "$primary")")"
}

cmd_apply_terminal() {
  local app="${1:-}"
  if [[ -z "$app" ]]; then
    pick_app_for terminal || return 0
    app="$PICKED_DESKTOP"
  fi
  local desktop path bin bfile hr
  desktop="$(resolve_desktop "$app")"
  path="$(find_desktop_path "$desktop" || true)"
  [[ -n "$path" ]] || die "找不到 desktop 文件: $desktop"
  bin="$(desktop_exec_bin "$path")"
  [[ -n "$bin" ]] || die "无法从 $desktop 读取 Exec"

  ensure_backup_dir
  backup_mimeapps_once
  bfile="$(role_backup_file terminal)"
  if [[ ! -f "$bfile" ]]; then
    if command -v gsettings >/dev/null 2>&1; then
      if gsettings list-keys org.gnome.desktop.default-applications.terminal >/dev/null 2>&1; then
        backup_line_once "$bfile" "$(printf 'gsettings\torg.gnome.desktop.default-applications.terminal\texec\t%s' "$(gsettings get org.gnome.desktop.default-applications.terminal exec)")"
        backup_line_once "$bfile" "$(printf 'gsettings\torg.gnome.desktop.default-applications.terminal\texec-arg\t%s' "$(gsettings get org.gnome.desktop.default-applications.terminal exec-arg)")"
      fi
    fi
    hr="$HOME/.config/xfce4/helpers.rc"
    if [[ -f "$hr" ]] && grep -q '^TerminalEmulator=' "$hr"; then
      backup_line_once "$bfile" "$(printf 'xfce-helpers\tTerminalEmulator\t%s' "$(sed -n 's/^TerminalEmulator=//p' "$hr" | head -n1)")"
    fi
    save_mime_prev "$bfile" "x-scheme-handler/terminal"
    log "已备份原终端设置"
  fi

  if command -v gsettings >/dev/null 2>&1; then
    if gsettings list-keys org.gnome.desktop.default-applications.terminal >/dev/null 2>&1; then
      gsettings set org.gnome.desktop.default-applications.terminal exec "'${bin}'"
      log "gsettings 终端 exec=${bin}"
    fi
  fi
  hr="$HOME/.config/xfce4/helpers.rc"
  if [[ -f "$hr" ]]; then
    local helper="${desktop%.desktop}"
    if grep -q '^TerminalEmulator=' "$hr"; then
      sed -i "s|^TerminalEmulator=.*|TerminalEmulator=${helper}|" "$hr"
    else
      printf 'TerminalEmulator=%s\n' "$helper" >>"$hr"
    fi
    log "XFCE TerminalEmulator=${helper}"
  fi
  # 该 MIME 未必存在，失败忽略
  xdg-mime default "$desktop" x-scheme-handler/terminal 2>/dev/null || true
  log "已设置终端 -> $desktop  (Exec: $bin)"
  cmd_status_one terminal
}

# ---------- 查看 ----------
mismatch_note() {
  local primary_val="$1"
  shift
  local m v extras=()
  for m in "$@"; do
    [[ -n "$m" ]] || continue
    v="$(query_mime "$m")"
    [[ "$v" == "$primary_val" ]] && continue
    extras+=("$m=${v:-未设置}")
  done
  if ((${#extras[@]})); then
    echo "  其它 MIME 不一致: ${extras[*]}"
  fi
}

cmd_status_one() {
  local raw="$1"
  local spec role label primary extras cur
  local -a extra_arr=()
  spec="$(role_spec "$raw")" || die "未知角色: $raw"
  IFS=$'\t' read -r role label primary extras <<<"$spec"
  # shellcheck disable=SC2206
  extra_arr=($extras)

  echo "[$label]  ($role)"
  if [[ "$role" == "terminal" ]]; then
    if command -v gsettings >/dev/null 2>&1 && gsettings list-keys org.gnome.desktop.default-applications.terminal >/dev/null 2>&1; then
      echo "  GNOME: exec=$(gsettings get org.gnome.desktop.default-applications.terminal exec)  arg=$(gsettings get org.gnome.desktop.default-applications.terminal exec-arg)"
    fi
    if [[ -f "$HOME/.config/xfce4/helpers.rc" ]]; then
      echo "  XFCE:  $(grep '^TerminalEmulator=' "$HOME/.config/xfce4/helpers.rc" || echo '（helpers.rc 未写 TerminalEmulator）')"
    fi
    if command -v update-alternatives >/dev/null 2>&1; then
      local alt
      alt="$(update-alternatives --query x-terminal-emulator 2>/dev/null | awk '/^Value:/{print $2; exit}')"
      [[ -n "$alt" ]] && echo "  alternatives x-terminal-emulator: $alt"
    fi
    cur="$(query_mime "$primary")"
    echo "  MIME $primary: ${cur:-（未设置）}"
    echo
    return 0
  fi

  cur="$(query_mime "$primary")"
  if [[ -n "$cur" ]]; then
    echo "  当前: $(desktop_label "$cur")"
  else
    echo "  当前: （未设置）"
  fi
  echo "  MIME: $primary"
  if [[ "$role" == "browser" ]] && command -v xdg-settings >/dev/null 2>&1; then
    echo "  xdg-settings default-web-browser: $(xdg-settings get default-web-browser 2>/dev/null || echo '（无法读取）')"
  fi
  if [[ "$role" == "mail" ]] && command -v xdg-settings >/dev/null 2>&1; then
    echo "  xdg-settings mailto: $(xdg-settings get default-url-scheme-handler mailto 2>/dev/null || echo '（无法读取）')"
  fi
  mismatch_note "$cur" "${extra_arr[@]}"
  echo
}

cmd_status() {
  local r
  echo "用户: $USER"
  echo "配置: $MIMEAPPS"
  echo "备份: $BACKUP_DIR"
  echo
  for r in "${KNOWN_ROLES[@]}"; do
    cmd_status_one "$r"
  done
}

cmd_query() {
  local mime="${1:-}"
  [[ -n "$mime" ]] || die "用法: $0 --query <MIME>（例: --query inode/directory）"
  local cur
  cur="$(query_mime "$mime")"
  echo "MIME: $mime"
  if [[ -n "$cur" ]]; then
    echo "当前: $(desktop_label "$cur")"
  else
    echo "当前: （未设置）"
  fi
}

cmd_list() {
  local raw="${1:-}"
  if [[ -z "$raw" ]]; then
    echo "可用角色:"
    local r spec label primary
    for r in "${KNOWN_ROLES[@]}"; do
      spec="$(role_spec "$r")"
      IFS=$'\t' read -r _ label primary _ <<<"$spec"
      printf '  %-12s  %s  (%s)\n' "$r" "$label" "$primary"
    done
    echo
    echo "也可用任意 MIME:  $0 --query application/pdf"
    echo "                  $0 --apply application/pdf evince.desktop"
    return 0
  fi

  local mime path cur id name mark
  if [[ "$raw" == */* ]]; then
    mime="$raw"
  else
    local spec primary extras
    spec="$(role_spec "$raw")" || die "未知角色: $raw（或给出 MIME，如 inode/directory）"
    IFS=$'\t' read -r _ _ primary extras <<<"$spec"
    mime="$primary"
  fi

  cur="$(query_mime "$mime")"
  local list_terminal=0
  if [[ "$raw" != */* ]]; then
    local nr
    nr="$(normalize_role "$raw" 2>/dev/null || true)"
    [[ "$nr" == "terminal" ]] && list_terminal=1
  fi
  if [[ "$list_terminal" -eq 1 ]]; then
    echo "终端模拟器（Categories=TerminalEmulator；* 仅当 MIME 对得上才标）:"
  else
    echo "声明了 $mime 的应用（* 为当前默认）:"
  fi
  echo
  while IFS=$'\t' read -r id path; do
    desktop_hidden "$path" && continue
    if [[ "$list_terminal" -eq 1 ]]; then
      desktop_has_category "$path" TerminalEmulator || continue
    else
      desktop_has_mime "$path" "$mime" || continue
    fi
    if desktop_nodisplay "$path" && [[ "$id" != "$cur" ]]; then
      continue
    fi
    name="$(desktop_field "$path" Name)"
    mark=" "
    [[ "$id" == "$cur" ]] && mark="*"
    printf '  %s %-42s  %s\n' "$mark" "$id" "$name"
  done < <(all_desktops)
  if [[ -z "$cur" ]]; then
    echo
    echo "  （当前未设置默认）"
  fi
}

cmd_undo() {
  local raw="${1:-}"
  ensure_backup_dir
  if [[ -n "$raw" ]]; then
    local key="$raw" bfile
    if [[ "$raw" == */* ]]; then
      key="mime_${raw}"
    else
      key="$(normalize_role "$raw" 2>/dev/null || true)"
      [[ -n "$key" ]] || key="$raw"
    fi
    bfile="$(role_backup_file "$key")"
    [[ -f "$bfile" ]] || die "无此备份: $bfile"
    restore_backup_file "$bfile"
    rm -f "$bfile"
    log "已还原 $raw"
    return 0
  fi

  local f any=0
  shopt -s nullglob
  for f in "$BACKUP_DIR/roles/"*; do
    [[ -f "$f" ]] || continue
    any=1
    restore_backup_file "$f"
    rm -f "$f"
  done
  shopt -u nullglob
  [[ "$any" -eq 1 ]] || die "无备份，无法还原: $BACKUP_DIR/roles/"
  log "已还原本脚本改过的默认应用"
}

usage() {
  cat <<EOF
用法: $(basename "$0") [角色] [--status|--apply 角色 [应用]|--undo [角色]|--help]

  （无参数）              交互：选角色 → 选应用（序号或 Tab 补全名字）
  fm / 文件管理器         直接进入该角色的候选项（像 update-alternatives --config）
  --status                只查看当前默认，不修改
  --list [角色]           列出角色或某角色的 .desktop
  --query MIME            查询任意 MIME（例: inode/directory）
  --apply fm              交互设置文件管理器
  --apply fm nautilus     非交互设置
  --apply application/pdf evince.desktop
  --undo / --undo fm      还原本脚本改过的项

角色:
  fm / 文件管理器     inode/directory
  browser / 浏览器    http/https/html
  mail / 邮件         mailto
  editor / 文本编辑器 text/plain
  image / 图片查看器  jpeg/png/gif/webp/...
  pdf                 application/pdf
  video / 视频播放器  mp4/mkv/webm/...
  audio / 音频播放器  mp3/flac/ogg/...
  archive / 压缩包    zip/tar/7z/...
  terminal / 终端     GNOME gsettings / XFCE helpers（尽力）

说明:
  - 用户级设置，不要 sudo。写入 ~/.config/mimeapps.list
  - 交互里 Tab 补全序号、desktop id、短名、显示名
  - 首次修改才备份；--undo 回到第一次之前
  - 仅把文件管理器固定为 Nautilus，仍可用 default-fm-nautilus.sh
EOF
}

# ---------- 入口 ----------
cmd="${1:-}"
if [[ -z "$cmd" ]]; then
  cmd_interactive
  exit 0
fi
shift || true
case "$cmd" in
  --status|status) cmd_status ;;
  --list|list) cmd_list "${1:-}" ;;
  --query|query) cmd_query "${1:-}" ;;
  --apply|apply|--set|set|--config|config)
    if [[ -z "${1:-}" ]]; then
      cmd_interactive
    elif [[ -n "${2:-}" ]]; then
      cmd_apply_role "$1" "$2"
    else
      cmd_interactive "$1"
    fi
    ;;
  --undo|undo) cmd_undo "${1:-}" ;;
  -h|--help|help) usage ;;
  *)
    if [[ "$cmd" == */* ]] || role_spec "$cmd" >/dev/null; then
      cmd_interactive "$cmd"
    else
      die "未知参数: $cmd（见 --help）"
    fi
    ;;
esac
