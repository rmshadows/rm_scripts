#!/usr/bin/env bash
# 精简软件语言包：只保留指定语言（firefox-esr / thunderbird / libreoffice 等一起处理）
# 同时去掉会把语言包再推荐回来的 task-*-desktop。
#
# 用法:
#   sudo ./trim-l10n.sh                     # 交互：看哪些软件装了多种语言，选保留语言
#   sudo ./trim-l10n.sh --apply zh-cn
#   sudo ./trim-l10n.sh --apply zh-cn zh-tw --yes
#   ./trim-l10n.sh --status
#   sudo ./trim-l10n.sh --undo
# 环境变量: KEEP_LANGS='zh-cn zh-tw'  YES=1
set -euo pipefail

NAME="trim-l10n"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"

log()  { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[x] $*" >&2; exit 1; }

need_root() {
  [[ $EUID -eq 0 ]] || die "请用 sudo 运行（要 apt purge / install）"
}

need_tty() {
  [[ -t 0 && -t 1 ]] || die "交互模式需要终端。非交互: sudo $0 --apply zh-cn --yes"
}

command -v dpkg-query >/dev/null 2>&1 || die "需要 dpkg（Debian/Ubuntu）"
command -v apt-get >/dev/null 2>&1 || die "需要 apt-get"

# stem -> "lang lang ..."
declare -A STEM_LANGS=()
declare -A STEM_COUNT=()
declare -a ALL_LANGS=()
declare -a META_ALL=()          # *-l10n-all
declare -a HELP_PKGS=()         # libreoffice-help-LANG
declare -A HELP_LANG=()
declare -a TASK_PKGS=()
declare -A TASK_LANGS=()        # task pkg -> "lang lang"
declare -a REMOVE_PKGS=()
declare -a KEEP_PKGS=()

lang_label() {
  case "$1" in
    zh-cn) echo "简体中文" ;;
    zh-tw) echo "繁体中文" ;;
    zh-hk) echo "中文(香港)" ;;
    en-gb) echo "英语(英)" ;;
    en-us) echo "英语(美)" ;;
    en-ca) echo "英语(加)" ;;
    ja) echo "日语" ;;
    ko) echo "韩语" ;;
    de) echo "德语" ;;
    fr) echo "法语" ;;
    es-es|es) echo "西班牙语" ;;
    ru) echo "俄语" ;;
    pt-br) echo "葡萄牙语(巴西)" ;;
    pt-pt) echo "葡萄牙语" ;;
    *) echo "" ;;
  esac
}

normalize_lang() {
  local s="${1,,}"
  s="${s//_/-}"
  s="${s%%.*}"
  printf '%s\n' "$s"
}

locale_langs() {
  local raw=() x n
  raw+=("${LANG:-}" "${LC_MESSAGES:-}" "${LC_ALL:-}")
  if [[ -n "${LANGUAGE:-}" ]]; then
    IFS=': ' read -ra x <<<"$LANGUAGE"
    raw+=("${x[@]}")
  fi
  for x in "${raw[@]}"; do
    [[ -n "$x" && "$x" != "C" && "$x" != "POSIX" ]] || continue
    n="$(normalize_lang "$x")"
    [[ -n "$n" ]] && printf '%s\n' "$n"
    # zh-cn from zh-cn, also accept zh_CN already normalized
  done
}

installed_packages() {
  dpkg-query -W -f='${db:Status-Abbrev}|${Package}\n' 2>/dev/null | awk -F'|' '$1 ~ /^ii/ {print $2}'
}

extract_l10n_codes() {
  # 从 Depends/Recommends 文本里抽出语言代码
  grep -oE '[a-zA-Z0-9.+-]+-l10n-[a-zA-Z0-9-]+' <<<"${1:-}" | sed 's/.*-l10n-//' | grep -v '^all$' || true
}

scan_packages() {
  STEM_LANGS=()
  STEM_COUNT=()
  ALL_LANGS=()
  META_ALL=()
  HELP_PKGS=()
  HELP_LANG=()
  TASK_PKGS=()
  TASK_LANGS=()

  local pkg stem lang rec
  local -A lang_seen=()

  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] || continue
    case "$pkg" in
      *-l10n-all)
        META_ALL+=("$pkg")
        ;;
      *-l10n-common) ;;
      *-l10n-*)
        stem="${pkg%-l10n-*}"
        lang="${pkg##*-l10n-}"
        [[ -n "$stem" && -n "$lang" && "$lang" != "$pkg" ]] || continue
        STEM_LANGS[$stem]="${STEM_LANGS[$stem]:+${STEM_LANGS[$stem]} }$lang"
        STEM_COUNT[$stem]=$((${STEM_COUNT[$stem]:-0} + 1))
        lang_seen[$lang]=1
        ;;
      libreoffice-help-common) ;;
      libreoffice-help-*)
        lang="${pkg#libreoffice-help-}"
        [[ "$lang" == "$pkg" || -z "$lang" ]] && continue
        HELP_PKGS+=("$pkg")
        HELP_LANG[$pkg]="$lang"
        lang_seen[$lang]=1
        ;;
    esac
  done < <(installed_packages)

  while IFS=$'\t' read -r pkg rec; do
    [[ -n "$pkg" ]] || continue
    lang="$(extract_l10n_codes "$rec" | sort -u | tr '\n' ' ')"
    lang="${lang%% }"
    lang="${lang%"${lang##*[![:space:]]}"}"
    [[ -n "$lang" ]] || continue
    TASK_PKGS+=("$pkg")
    TASK_LANGS[$pkg]="$lang"
  done < <(dpkg-query -W -f='${db:Status-Abbrev}|${Package}\t${Depends} ${Recommends}\n' 'task-*' 2>/dev/null | awk -F'|' '$1 ~ /^ii/ {print substr($0, index($0,"|")+1)}')

  ALL_LANGS=()
  for lang in "${!lang_seen[@]}"; do
    ALL_LANGS+=("$lang")
  done
  if ((${#ALL_LANGS[@]})); then
    local IFS=$'\n'
    ALL_LANGS=($(printf '%s\n' "${ALL_LANGS[@]}" | sort))
    unset IFS
  fi
}

stem_has_many() {
  local c
  c="${STEM_COUNT[$1]:-0}"
  ((c >= 2))
}

suggested_keep() {
  local -A want=()
  local -A installed=()
  local x
  for x in "${ALL_LANGS[@]+"${ALL_LANGS[@]}"}"; do
    installed[$x]=1
  done
  while IFS= read -r x; do
    [[ -n "$x" ]] || continue
    want[$x]=1
    # zh_CN → zh-cn already; also map short zh to zh-cn if that pack exists
    if [[ "$x" == "zh" && -n "${installed[zh-cn]:-}" ]]; then
      want[zh-cn]=1
    fi
  done < <(locale_langs)

  if [[ -n "${KEEP_LANGS:-}" ]]; then
    # shellcheck disable=SC2086
    for x in $KEEP_LANGS; do
      want["$(normalize_lang "$x")"]=1
    done
  fi

  local out=()
  for x in "${!want[@]}"; do
    [[ -n "${installed[$x]:-}" ]] && out+=("$x")
  done
  if ((${#out[@]} == 0)) && [[ -n "${installed[zh-cn]:-}" ]]; then
    out+=(zh-cn)
  fi
  if ((${#out[@]})); then
    printf '%s\n' "${out[@]}" | sort -u
  fi
}

print_overview() {
  local stem langs n lab
  echo "用户语言: ${LANG:-?}  LANGUAGE=${LANGUAGE:-}"
  echo
  echo "装了多种语言包的软件："
  echo
  printf "  %-18s %5s  %s\n" "软件" "数量" "其中已装"
  echo "  ----------------------------------------------"
  local any=0
  local -a stems=()
  for stem in "${!STEM_COUNT[@]}"; do
    stems+=("$stem")
  done
  if ((${#stems[@]})); then
    local IFS=$'\n'
    stems=($(printf '%s\n' "${stems[@]}" | sort))
    unset IFS
  fi
  for stem in "${stems[@]+"${stems[@]}"}"; do
    n="${STEM_COUNT[$stem]}"
    ((n >= 2)) || continue
    any=1
    langs="$(printf '%s\n' ${STEM_LANGS[$stem]} | sort | tr '\n' ' ')"
    printf "  %-18s %5d  %s\n" "$stem" "$n" "$langs"
  done
  if [[ "$any" -eq 0 ]]; then
    echo "  （没有发现同一软件装了 ≥2 个 *-l10n-* 包）"
  fi
  echo
  local one=0
  for stem in "${stems[@]+"${stems[@]}"}"; do
    n="${STEM_COUNT[$stem]}"
    ((n == 1)) || continue
    if [[ "$one" -eq 0 ]]; then
      echo "仅一种语言（仍按同一保留列表处理）："
      one=1
    fi
    printf "  %-18s %5d  %s\n" "$stem" "$n" "${STEM_LANGS[$stem]}"
  done
  [[ "$one" -eq 1 ]] && echo
  if ((${#META_ALL[@]})); then
    echo "元包 *-l10n-all（会拉全语言，将去掉）: ${META_ALL[*]}"
    echo
  fi
  if ((${#HELP_PKGS[@]})); then
    echo "LibreOffice 帮助语言包: ${#HELP_PKGS[@]} 个"
    echo
  fi
  if ((${#TASK_PKGS[@]})); then
    echo "会推荐语言包的 task 包: ${#TASK_PKGS[@]} 个（不保留的语言对应任务会一起删，免得下次升级又装回来）"
    echo
  fi
  if ((${#ALL_LANGS[@]})); then
    echo -n "已出现的语言代码: "
    printf '%s ' "${ALL_LANGS[@]}"
    echo
    echo
  fi
}

lang_in_keep() {
  local needle="$1" k
  for k in "${KEEP_ARR[@]+"${KEEP_ARR[@]}"}"; do
    [[ "$k" == "$needle" ]] && return 0
  done
  return 1
}

plan_from_keep() {
  KEEP_PKGS=()
  REMOVE_PKGS=()
  local stem lang pkg rec_langs r keep_this

  for stem in "${!STEM_LANGS[@]}"; do
    # shellcheck disable=SC2086
    for lang in ${STEM_LANGS[$stem]}; do
      pkg="${stem}-l10n-${lang}"
      if lang_in_keep "$lang"; then
        KEEP_PKGS+=("$pkg")
      else
        REMOVE_PKGS+=("$pkg")
      fi
    done
  done

  for pkg in "${META_ALL[@]+"${META_ALL[@]}"}"; do
    REMOVE_PKGS+=("$pkg")
  done

  for pkg in "${HELP_PKGS[@]+"${HELP_PKGS[@]}"}"; do
    lang="${HELP_LANG[$pkg]}"
    if lang_in_keep "$lang"; then
      KEEP_PKGS+=("$pkg")
    else
      REMOVE_PKGS+=("$pkg")
    fi
  done

  for pkg in "${TASK_PKGS[@]+"${TASK_PKGS[@]}"}"; do
    rec_langs="${TASK_LANGS[$pkg]}"
    keep_this=0
    # shellcheck disable=SC2086
    for r in $rec_langs; do
      if lang_in_keep "$r"; then
        keep_this=1
        break
      fi
    done
    if [[ "$keep_this" -eq 1 ]]; then
      KEEP_PKGS+=("$pkg")
    else
      REMOVE_PKGS+=("$pkg")
    fi
  done

  if ((${#REMOVE_PKGS[@]})); then
    local IFS=$'\n'
    REMOVE_PKGS=($(printf '%s\n' "${REMOVE_PKGS[@]}" | sort -u))
    unset IFS
  fi
  if ((${#KEEP_PKGS[@]})); then
    local IFS=$'\n'
    KEEP_PKGS=($(printf '%s\n' "${KEEP_PKGS[@]}" | sort -u))
    unset IFS
  fi
}

print_plan() {
  local x lab
  echo "保留语言:"
  for x in "${KEEP_ARR[@]+"${KEEP_ARR[@]}"}"; do
    lab="$(lang_label "$x")"
    if [[ -n "$lab" ]]; then
      echo "  * $x  ($lab)"
    else
      echo "  * $x"
    fi
  done
  if ((${#KEEP_ARR[@]} == 0)); then
    echo "  （无；Firefox/Thunderbird 主程序自带英文界面）"
  fi
  echo
  echo "将删除 ${#REMOVE_PKGS[@]} 个包，保留 ${#KEEP_PKGS[@]} 个语言相关包。"
  if ((${#KEEP_PKGS[@]})); then
    echo "保留:"
    for x in "${KEEP_PKGS[@]}"; do
      echo "    $x"
    done
  fi
  if ((${#REMOVE_PKGS[@]})); then
    echo "删除列表（节选）:"
    local i=0
    for x in "${REMOVE_PKGS[@]}"; do
      echo "    $x"
      i=$((i + 1))
      if ((i >= 25 && ${#REMOVE_PKGS[@]} > 28)); then
        echo "    ... 还有 $((${#REMOVE_PKGS[@]} - 25)) 个"
        break
      fi
    done
  fi
  echo
}

restore_tab_complete() {
  bind '"\t": complete' 2>/dev/null || true
}

READ_COMPLETE_ARR=()
_trim_l10n_complete() {
  local line="${READLINE_LINE:-}"
  local prefix head cur
  local -a matches=()
  local w p m
  if [[ "$line" == *" "* ]]; then
    head="${line% *} "
    cur="${line##* }"
  else
    head=""
    cur="$line"
  fi
  if [[ -z "$cur" ]]; then
    printf '\n先打语言代码再 Tab，例如 zh-c<Tab>。也可输入 none。\n' >&2
    return
  fi
  for w in "${READ_COMPLETE_ARR[@]+"${READ_COMPLETE_ARR[@]}"}"; do
    [[ "$w" == "$cur"* ]] && matches+=("$w")
  done
  if ((${#matches[@]} == 0)); then
    return
  fi
  if ((${#matches[@]} == 1)); then
    READLINE_LINE="${head}${matches[0]}"
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
    READLINE_LINE="${head}${p}"
    READLINE_POINT=${#READLINE_LINE}
  fi
  printf '\n' >&2
  printf '%s  ' "${matches[@]}" >&2
  printf '\n' >&2
}

read_langs_line() {
  local prompt="$1"
  shift
  READ_COMPLETE_ARR=("$@")
  bind -x '"\t": _trim_l10n_complete' 2>/dev/null || true
  REPLY=""
  read -e -p "$prompt" REPLY || true
  restore_tab_complete
}

parse_keep_input() {
  local input="$1"
  KEEP_ARR=()
  local -a raw=()
  local x n
  # shellcheck disable=SC2086
  read -ra raw <<<"$input"
  for x in "${raw[@]+"${raw[@]}"}"; do
    n="$(normalize_lang "$x")"
    case "$n" in
      "" | none | "-" | no | off) continue ;;
    esac
    KEEP_ARR+=("$n")
  done
  if ((${#KEEP_ARR[@]})); then
    local IFS=$'\n'
    KEEP_ARR=($(printf '%s\n' "${KEEP_ARR[@]}" | sort -u))
    unset IFS
  fi
}

KEEP_ARR=()

pick_keep_langs() {
  local sug input def
  mapfile -t KEEP_ARR < <(suggested_keep)
  def="${KEEP_ARR[*]:-none}"
  echo "Firefox / Thunderbird 主程序自带英文，不必装 en-us 语言包。"
  echo "建议保留: $def"
  echo
  read_langs_line "要保留的语言（空格分隔，Tab 补全；回车=建议；none=全删语言包）: " "${ALL_LANGS[@]}" none
  input="${REPLY:-}"
  if [[ -z "$input" ]]; then
    log "使用建议: $def"
    return 0
  fi
  parse_keep_input "$input"
}

cmd_status() {
  scan_packages
  print_overview
  mapfile -t KEEP_ARR < <(suggested_keep)
  echo "若按系统语言精简，将保留: ${KEEP_ARR[*]:-none}"
  plan_from_keep
  print_plan
  echo "备份目录: $BACKUP_DIR"
}

confirm_yes() {
  local ans
  if [[ "${YES:-}" == "1" || "${YES:-}" == "yes" ]]; then
    return 0
  fi
  need_tty
  ans=""
  read -r -p "确认执行 apt purge? [y/N] " ans || true
  case "${ans:-}" in
    y | Y | yes | YES) return 0 ;;
    *) return 1 ;;
  esac
}

backup_removed() {
  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BACKUP_DIR/removed.list" ]]; then
    printf '%s\n' "${REMOVE_PKGS[@]}" >"$BACKUP_DIR/removed.list"
    printf '%s\n' "${KEEP_ARR[@]+"${KEEP_ARR[@]}"}" >"$BACKUP_DIR/kept.langs"
    echo "applied=$(date -Iseconds)" >"$BACKUP_DIR/state.env"
    log "已记下将删除的 ${#REMOVE_PKGS[@]} 个包 → $BACKUP_DIR/removed.list"
  else
    log "已有备份，不覆盖: $BACKUP_DIR/removed.list（--undo 仍按第一次）"
  fi
}

cmd_apply() {
  need_root
  scan_packages
  print_overview

  if [[ -n "${KEEP_LANGS:-}" ]]; then
    parse_keep_input "$KEEP_LANGS"
  elif ((${#KEEP_ARR[@]} == 0)); then
    if [[ -t 0 && -t 1 ]]; then
      pick_keep_langs
    else
      mapfile -t KEEP_ARR < <(suggested_keep)
      log "非交互，使用建议语言: ${KEEP_ARR[*]:-none}"
    fi
  fi

  plan_from_keep
  print_plan

  if ((${#REMOVE_PKGS[@]} == 0)); then
    log "没有需要删除的包。"
    return 0
  fi

  confirm_yes || { log "已取消"; return 0; }

  backup_removed
  log "apt-get purge ${#REMOVE_PKGS[@]} 个包…"
  DEBIAN_FRONTEND=noninteractive apt-get purge -y "${REMOVE_PKGS[@]}"
  log "完成。以后升级不应再出现那一长串 l10n。"
  echo "还原: sudo $0 --undo"
}

cmd_undo() {
  need_root
  [[ -f "$BACKUP_DIR/removed.list" ]] || die "无备份: $BACKUP_DIR/removed.list"
  local -a pkgs=()
  mapfile -t pkgs <"$BACKUP_DIR/removed.list"
  ((${#pkgs[@]})) || die "备份列表为空"
  log "将重新安装 ${#pkgs[@]} 个包（当时删掉的语言包/任务）"
  if [[ "${YES:-}" != "1" ]]; then
    confirm_yes || { log "已取消"; return 0; }
  fi
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
  log "已按备份装回。可手动 rm $BACKUP_DIR/removed.list"
}

usage() {
  cat <<EOF
用法: $(basename "$0") [--status|--apply [语言...]|--undo|--help]

  （无参数）/--apply     交互：列出装了多种语言的软件，选要保留的语言，一起删其余
  --apply zh-cn          非交互保留简体中文（可多个）
  --apply zh-cn --yes    不再询问
  --status               只看，不删
  --undo                 把本脚本第一次删掉的包装回来

环境变量:
  KEEP_LANGS='zh-cn zh-tw'   保留这些语言代码
  YES=1                      等同 --yes
  SYSTWEAK_BACKUP            备份目录父路径

说明:
  - 扫描已装的 *-l10n-* 、libreoffice-help-* ，按软件分组
  - 多种语言的软件（firefox-esr、thunderbird、libreoffice 等）用同一套保留列表一起处理
  - 同时删除会 Recommends 那些语言包的 task-*-desktop，否则下次升级又会装回来
  - *-l10n-all 元包一律去掉
  - 主程序自带英文界面，通常不用保留 en-us
EOF
}

# ---------- 入口 ----------
YES="${YES:-}"
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) YES=1; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

cmd="${1:-}"
if [[ -z "$cmd" ]]; then
  cmd_apply
  exit 0
fi
shift || true
case "$cmd" in
  --status|status) cmd_status ;;
  --apply|apply)
    if [[ $# -gt 0 ]]; then
      KEEP_LANGS="$*"
    fi
    cmd_apply
    ;;
  --undo|undo) cmd_undo ;;
  -h|--help|help) usage ;;
  *)
    # 允许: ./trim-l10n.sh zh-cn zh-tw
    KEEP_LANGS="$cmd $*"
    cmd_apply
    ;;
esac
