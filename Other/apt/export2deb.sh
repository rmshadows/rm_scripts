#!/usr/bin/env bash
# 从系统导出已安装软件为 .deb（需 apt/dpkg 安装的包，依赖 dpkg-repack）
#
# 用法:
#   ./export2deb.sh                         # 交互：输入时 Tab 补全已安装包名
#   ./export2deb.sh nginx                   # 非交互；前缀唯一则自动补齐为完整包名
#   ./export2deb.sh python3-re              # 同上，如唯一匹配 python3-requests
#   ./export2deb.sh 'libssl*'               # 通配（请加引号）
#   ./export2deb.sh -o ./debs pkg1 pkg2     # 指定输出目录，可多个包
#   ./export2deb.sh -y nginx                # 非交互且跳过确认
#
# 环境变量: EXPORT2DEB_OUTDIR  默认输出目录（默认当前目录）
set -euo pipefail

OUTDIR="${EXPORT2DEB_OUTDIR:-.}"
ASSUME_YES=0
QUERIES=()
TTY_DEV=""
EXPORT2DEB_PKGS=()
_TAB_MATCHES=()
_TAB_LISTED_FOR=""

usage() {
  cat <<'EOF'
从系统导出已安装软件为 .deb（需 apt/dpkg 安装的包，依赖 dpkg-repack）

用法:
  ./export2deb.sh                         # 交互：输入时按 Tab 补全包名
  ./export2deb.sh nginx                   # 非交互；前缀唯一则自动补齐为完整包名
  ./export2deb.sh python3-re              # 同上，如唯一匹配 python3-requests
  ./export2deb.sh 'libssl*'               # 通配（请加引号）
  ./export2deb.sh -o ./debs pkg1 pkg2     # 指定输出目录，可多个包
  ./export2deb.sh -y nginx                # 非交互且跳过确认

交互 Tab（类 bash）: 先补到最长公共前缀；再按 Tab 列出全部匹配。
回车后仍支持：精确名 → 通配 → 前缀 → 子串；多命中可选序号。

环境变量: EXPORT2DEB_OUTDIR  默认输出目录（默认当前目录）
EOF
  exit 0
}

die() { echo "[x] $*" >&2; exit 1; }
info() { echo "[+] $*" >&2; }
warn() { echo "[!] $*" >&2; }

# 解析到真正的控制终端（进程替换 / 管道下 -t 0/1 会失败）
resolve_tty() {
  if [[ -r /dev/tty && -w /dev/tty ]]; then
    TTY_DEV=/dev/tty
  elif [[ -t 0 && -t 1 ]]; then
    TTY_DEV=""
  else
    TTY_DEV=""
    return 1
  fi
  return 0
}

# 向用户终端输出（交互 UI）
ui() {
  printf '%s\n' "$*" >"${TTY_DEV:-/dev/tty}"
}

# 从控制终端读一行（readline + bind -x Tab）
tty_read() {
  local prompt="$1"
  local __var="$2"
  # 提示打到 tty，避免混进管道；输入必须来自已 exec 的 /dev/tty
  read -r -e -p "$prompt" "$__var" || return 1
}

cache_installed_pkgs() {
  mapfile -t EXPORT2DEB_PKGS < <(list_installed)
}

# ---- Tab 补全：行为对齐 bash（LCP → 再 Tab 列出全部）----
# 注意：脚本有 set -e，bind -x 回调里任一失败都会直接把整个脚本干掉，必须全程容错。
_export2deb_rebuild_tab_matches() {
  local cur="$1"
  local p
  _TAB_MATCHES=()
  [[ -n "$cur" ]] || return 0

  for p in "${EXPORT2DEB_PKGS[@]}"; do
    [[ "$p" == "$cur"* ]] && _TAB_MATCHES+=("$p")
  done
  if [[ ${#_TAB_MATCHES[@]} -eq 0 ]]; then
    local cur_lc="${cur,,}"
    for p in "${EXPORT2DEB_PKGS[@]}"; do
      [[ "${p,,}" == *"$cur_lc"* ]] && _TAB_MATCHES+=("$p")
    done
  fi
  return 0
}

_export2deb_lcp_of_matches() {
  # 在数组上算 LCP，避免 "${arr[@]}" 传参撑爆
  local lcp="${_TAB_MATCHES[0]:-}"
  local m
  for m in "${_TAB_MATCHES[@]:1}"; do
    while [[ -n "$lcp" && "$m" != "$lcp"* ]]; do
      lcp="${lcp%?}"
    done
    [[ -n "$lcp" ]] || break
  done
  printf '%s' "$lcp"
  return 0
}

_export2deb_list_matches() {
  local n=${#_TAB_MATCHES[@]}
  local tty="${TTY_DEV:-/dev/tty}"
  local limit=120
  {
    printf '\n'
    if [[ "$n" -gt "$limit" ]]; then
      printf '（共 %d 个匹配，列出前 %d 个；请再输入字符缩小范围）\n' "$n" "$limit"
      printf '%s\n' "${_TAB_MATCHES[@]:0:$limit}"
    else
      printf '%s\n' "${_TAB_MATCHES[@]}"
    fi
  } | column -x 2>/dev/null >"$tty" || {
    if [[ "$n" -gt "$limit" ]]; then
      printf '\n（共 %d 个匹配，列出前 %d 个）\n' "$n" "$limit" >"$tty"
      printf '%s\n' "${_TAB_MATCHES[@]:0:$limit}" >"$tty"
    else
      printf '\n' >"$tty"
      printf '%s\n' "${_TAB_MATCHES[@]}" >"$tty"
    fi
  }
  return 0
}

_export2deb_on_tab() {
  # 关键关掉 -e / pipefail，避免回调失败导致「闪退」
  set +e
  set +o pipefail 2>/dev/null

  local cur="${READLINE_LINE-}"
  local tty="${TTY_DEV:-/dev/tty}"
  local n lcp

  _export2deb_rebuild_tab_matches "$cur"
  n=${#_TAB_MATCHES[@]}

  if [[ "$n" -eq 0 ]]; then
    printf '\a\n（无匹配: %s）\n' "${cur:-?}" >"$tty" 2>/dev/null
    _TAB_LISTED_FOR=""
    READLINE_LINE="$cur"
    READLINE_POINT=${#cur}
    set -e
    set -o pipefail 2>/dev/null
    return 0
  fi

  if [[ "$n" -eq 1 ]]; then
    READLINE_LINE="${_TAB_MATCHES[0]}"
    READLINE_POINT=${#READLINE_LINE}
    _TAB_LISTED_FOR=""
    set -e
    set -o pipefail 2>/dev/null
    return 0
  fi

  lcp="$(_export2deb_lcp_of_matches)"

  # 还能往公共前缀延长 → 先补前缀（bash 第一次 Tab）
  if [[ ${#lcp} -gt ${#cur} ]]; then
    READLINE_LINE="$lcp"
    READLINE_POINT=${#READLINE_LINE}
    _TAB_LISTED_FOR=""
    set -e
    set -o pipefail 2>/dev/null
    return 0
  fi

  # 匹配过多且前缀很短：不刷屏，提示继续输入
  if [[ "$n" -gt 80 && ${#cur} -lt 2 ]]; then
    printf '\a\n（%d 个匹配，请再输入几个字符后再 Tab）\n' "$n" >"$tty" 2>/dev/null
    READLINE_LINE="$cur"
    READLINE_POINT=${#cur}
    set -e
    set -o pipefail 2>/dev/null
    return 0
  fi

  # 已在公共前缀上：列出匹配（bash 第二次 Tab）
  _export2deb_list_matches
  _TAB_LISTED_FOR="$cur"
  READLINE_LINE="$cur"
  READLINE_POINT=${#cur}

  set -e
  set -o pipefail 2>/dev/null
  return 0
}

setup_tab_completion() {
  cache_installed_pkgs
  [[ ${#EXPORT2DEB_PKGS[@]} -gt 0 ]] || warn "未读到已安装包列表，Tab 补全不可用"

  set -o emacs 2>/dev/null || true
  complete -r -D 2>/dev/null || true
  bind -x '"\t": _export2deb_on_tab' 2>/dev/null || die "bash bind -x 不可用，无法 Tab 补全"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    -o|--outdir)
      [[ $# -ge 2 ]] || die "-o 需要目录参数"
      OUTDIR="$2"
      shift 2
      ;;
    --) shift; QUERIES+=("$@"); break ;;
    -*)
      die "未知参数: $1（见 --help）"
      ;;
    *)
      QUERIES+=("$1")
      shift
      ;;
  esac
done

command -v dpkg-repack >/dev/null 2>&1 || \
  die "dpkg-repack 未安装：sudo apt install dpkg-repack"
command -v dpkg >/dev/null 2>&1 || die "需要 dpkg"

list_installed() {
  dpkg -l 2>/dev/null | awk '/^ii/ { print $2 }' | sort -u
}

# stdout 只输出包名（一行一个）；提示一律 stderr / TTY
match_packages() {
  local q="$1"
  local -a all=() exact=() wild=() prefix=() substr=()
  mapfile -t all < <(list_installed)
  [[ ${#all[@]} -gt 0 ]] || return 1

  local p
  for p in "${all[@]}"; do
    [[ "$p" == "$q" ]] && exact+=("$p")
  done
  if [[ ${#exact[@]} -gt 0 ]]; then
    printf '%s\n' "${exact[@]}"
    return 0
  fi

  if [[ "$q" == *[\*\?]* ]]; then
    for p in "${all[@]}"; do
      # shellcheck disable=SC2254
      case "$p" in
        $q) wild+=("$p") ;;
      esac
    done
    if [[ ${#wild[@]} -gt 0 ]]; then
      printf '%s\n' "${wild[@]}"
      return 0
    fi
    return 1
  fi

  for p in "${all[@]}"; do
    [[ "$p" == "$q"* ]] && prefix+=("$p")
  done
  if [[ ${#prefix[@]} -gt 0 ]]; then
    printf '%s\n' "${prefix[@]}"
    return 0
  fi

  for p in "${all[@]}"; do
    [[ "$p" == *"$q"* ]] && substr+=("$p")
  done
  if [[ ${#substr[@]} -gt 0 ]]; then
    printf '%s\n' "${substr[@]}"
    return 0
  fi
  return 1
}

pick_from_candidates() {
  local -a cands=("$@")
  local n="${#cands[@]}"
  if [[ "$n" -eq 0 ]]; then
    return 1
  fi
  if [[ "$n" -eq 1 ]]; then
    echo "${cands[0]}"
    return 0
  fi

  ui "匹配到 $n 个包："
  local i
  for i in "${!cands[@]}"; do
    ui "$(printf '  %2d) %s' "$((i + 1))" "${cands[$i]}")"
  done
  ui ""

  local pick=""
  tty_read "选序号（空格分隔可多选，a=全部，回车取消）: " pick || true
  pick="${pick:-}"
  [[ -n "$pick" ]] || return 1

  if [[ "$pick" == "a" || "$pick" == "A" || "$pick" == "all" ]]; then
    printf '%s\n' "${cands[@]}"
    return 0
  fi

  local -a out=()
  local tok idx
  for tok in $pick; do
    [[ "$tok" =~ ^[0-9]+$ ]] || { warn "无效序号: $tok"; continue; }
    idx=$((tok - 1))
    if [[ "$idx" -lt 0 || "$idx" -ge "$n" ]]; then
      warn "序号越界: $tok"
      continue
    fi
    out+=("${cands[$idx]}")
  done
  [[ ${#out[@]} -gt 0 ]] || return 1
  printf '%s\n' "${out[@]}"
}

# $1=查询 $2=是否交互(1/0)；stdout 仅包名
resolve_one_query() {
  local q="$1"
  local interactive="${2:-0}"
  local -a hits=()

  mapfile -t hits < <(match_packages "$q" || true)
  if [[ ${#hits[@]} -eq 0 || -z "${hits[0]:-}" ]]; then
    warn "未找到已安装包匹配: $q"
    return 1
  fi

  if [[ ${#hits[@]} -eq 1 ]]; then
    if [[ "${hits[0]}" != "$q" ]]; then
      info "已补齐: $q  →  ${hits[0]}"
    fi
    echo "${hits[0]}"
    return 0
  fi

  if [[ "$interactive" -eq 1 ]]; then
    warn "「$q」匹配 ${#hits[@]} 个，请选择："
    pick_from_candidates "${hits[@]}"
    return $?
  fi

  warn "「$q」匹配 ${#hits[@]} 个包，请写全名或加通配；候选："
  local h
  for h in "${hits[@]}"; do
    echo "    $h" >&2
  done
  return 1
}

# 直接写入全局 PACKAGES（不用进程替换，避免假「非 TTY」）
interactive_collect() {
  resolve_tty || die "无法打开控制终端做交互；请直接传包名参数（见 --help）"
  # stdin 接到控制终端：read -e + bind -x Tab 才可靠（< /dev/tty 重定向不够）
  exec </dev/tty || die "无法打开 /dev/tty"
  TTY_DEV=/dev/tty

  setup_tab_completion

  ui "导出已安装包为 .deb（已缓存 ${#EXPORT2DEB_PKGS[@]} 个已安装包）"
  ui "Tab：先补公共前缀；再 Tab 列出全部匹配。回车确认，空行结束。"
  ui "也可输入关键字/通配后回车（多命中会列出序号）。"
  ui ""

  local -a selected=()
  local q
  while true; do
    q=""
    _TAB_MATCHES=()
    _TAB_LISTED_FOR=""
    tty_read "包名/关键字: " q || true
    q="${q#"${q%%[![:space:]]*}"}"
    q="${q%"${q##*[![:space:]]}"}"
    [[ -n "$q" ]] || break

    local -a got=()
    mapfile -t got < <(resolve_one_query "$q" 1 || true)
    if [[ ${#got[@]} -eq 0 || -z "${got[0]:-}" ]]; then
      continue
    fi
    local g
    for g in "${got[@]}"; do
      [[ -n "$g" ]] || continue
      selected+=("$g")
      info "已加入: $g"
    done
    ui ""
  done

  if [[ ${#selected[@]} -eq 0 ]]; then
    ui "未选择任何包，已退出。"
    exit 0
  fi

  local -A seen=()
  PACKAGES=()
  local s
  for s in "${selected[@]}"; do
    [[ -n "${seen[$s]:-}" ]] && continue
    seen[$s]=1
    PACKAGES+=("$s")
  done
}

repack_one() {
  local pkg="$1"
  info "正在打包: $pkg  →  $OUTDIR/"
  (
    cd "$OUTDIR"
    dpkg-repack "$pkg"
  )
}

# ---------- main ----------
mkdir -p "$OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)"

PACKAGES=()
if [[ ${#QUERIES[@]} -eq 0 ]]; then
  interactive_collect
else
  for q in "${QUERIES[@]}"; do
    _got=()
    mapfile -t _got < <(resolve_one_query "$q" 0 || true)
    if [[ ${#_got[@]} -eq 0 || -z "${_got[0]:-}" ]]; then
      die "无法解析: $q"
    fi
    PACKAGES+=("${_got[@]}")
  done
  declare -A _seen=()
  _uniq=()
  for s in "${PACKAGES[@]}"; do
    [[ -n "${_seen[$s]:-}" ]] && continue
    _seen[$s]=1
    _uniq+=("$s")
  done
  PACKAGES=("${_uniq[@]}")
fi

[[ ${#PACKAGES[@]} -gt 0 ]] || die "没有要打包的包"

echo >&2
info "将导出 ${#PACKAGES[@]} 个包到: $OUTDIR"
for p in "${PACKAGES[@]}"; do
  echo "  - $p" >&2
done

if [[ "$ASSUME_YES" -eq 0 ]]; then
  if resolve_tty; then
    ans=""
    tty_read "确认打包？[Y/n] " ans || true
    ans="${ans:-Y}"
    [[ "$ans" == [Yy]* ]] || { echo "已取消" >&2; exit 0; }
  fi
fi

ec=0
for p in "${PACKAGES[@]}"; do
  if ! repack_one "$p"; then
    warn "打包失败: $p"
    ec=1
  fi
done

if [[ "$ec" -eq 0 ]]; then
  info "完成。输出目录: $OUTDIR"
  ls -lh "$OUTDIR"/*.deb 2>/dev/null | awk '{print "  " $0}' >&2 || true
else
  warn "部分包失败（退出码 1）"
fi
exit "$ec"
