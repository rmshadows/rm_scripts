#!/usr/bin/env bash
# 从系统导出已安装软件为 .deb（需 apt/dpkg 安装的包，依赖 dpkg-repack）
#
# 用法:
#   ./export2deb.sh                         # 交互：输入关键字，自动匹配并补齐包名
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

usage() {
  cat <<'EOF'
从系统导出已安装软件为 .deb（需 apt/dpkg 安装的包，依赖 dpkg-repack）

用法:
  ./export2deb.sh                         # 交互：输入关键字，自动匹配并补齐包名
  ./export2deb.sh nginx                   # 非交互；前缀唯一则自动补齐为完整包名
  ./export2deb.sh python3-re              # 同上，如唯一匹配 python3-requests
  ./export2deb.sh 'libssl*'               # 通配（请加引号）
  ./export2deb.sh -o ./debs pkg1 pkg2     # 指定输出目录，可多个包
  ./export2deb.sh -y nginx                # 非交互且跳过确认

匹配顺序: 精确名 → 通配 → 前缀 → 子串
  唯一命中时自动补齐；多命中时交互下可选，非交互下报错并列出候选。

环境变量: EXPORT2DEB_OUTDIR  默认输出目录（默认当前目录）
EOF
  exit 0
}

die() { echo "[x] $*" >&2; exit 1; }
info() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }

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

# 已安装包列表（ii = 正常安装）
list_installed() {
  # dpkg -l 比复杂 format 更耐 status 脏数据
  dpkg -l 2>/dev/null | awk '/^ii/ { print $2 }' | sort -u
}

# 按查询解析为完整包名列表（stdout 一行一个）
# 规则: 精确 > 通配 > 前缀 > 子串；多匹配时由调用方决定
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

# 交互：从候选里选（可多选序号 / a=全部 / 唯一则直接用）
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

  echo "匹配到 $n 个包：" >&2
  local i
  for i in "${!cands[@]}"; do
    printf '  %2d) %s\n' "$((i + 1))" "${cands[$i]}" >&2
  done
  echo >&2
  local pick
  read -r -p "选序号（空格分隔可多选，a=全部，回车取消）: " pick || true
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

  # 多匹配
  if [[ "$interactive" -eq 1 ]]; then
    warn "「$q」匹配 ${#hits[@]} 个，请选择："
    pick_from_candidates "${hits[@]}"
    return $?
  fi

  # 非交互：拒绝歧义，列出候选
  warn "「$q」匹配 ${#hits[@]} 个包，请写全名或加通配；候选："
  local h
  for h in "${hits[@]}"; do
    echo "    $h" >&2
  done
  return 1
}

interactive_collect() {
  [[ -t 0 && -t 1 ]] || die "非 TTY，请直接传包名参数（见 --help）"
  echo "导出已安装包为 .deb（输入关键字即可，支持前缀/子串/通配）"
  echo "示例: nginx 、 python3-re 、 'libssl*'"
  echo "直接回车结束输入。"
  echo

  local -a selected=()
  local q
  while true; do
    read -r -e -p "包名/关键字: " q || true
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
      selected+=("$g")
      info "已加入: $g"
    done
    echo
  done

  if [[ ${#selected[@]} -eq 0 ]]; then
    die "未选择任何包"
  fi
  # 去重保序
  local -A seen=()
  local -a uniq=()
  local s
  for s in "${selected[@]}"; do
    [[ -n "${seen[$s]:-}" ]] && continue
    seen[$s]=1
    uniq+=("$s")
  done
  printf '%s\n' "${uniq[@]}"
}

repack_one() {
  local pkg="$1"
  info "正在打包: $pkg  →  $OUTDIR/"
  # dpkg-repack 把 deb 写到当前目录
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
  mapfile -t PACKAGES < <(interactive_collect)
else
  for q in "${QUERIES[@]}"; do
    _got=()
    mapfile -t _got < <(resolve_one_query "$q" 0 || true)
    if [[ ${#_got[@]} -eq 0 || -z "${_got[0]:-}" ]]; then
      die "无法解析: $q"
    fi
    PACKAGES+=("${_got[@]}")
  done
  # 去重
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

echo
info "将导出 ${#PACKAGES[@]} 个包到: $OUTDIR"
for p in "${PACKAGES[@]}"; do
  echo "  - $p"
done

if [[ "$ASSUME_YES" -eq 0 ]]; then
  if [[ -t 0 ]]; then
    read -r -p "确认打包？[Y/n] " ans || true
    ans="${ans:-Y}"
    [[ "$ans" == [Yy]* ]] || { echo "已取消"; exit 0; }
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
  ls -lh "$OUTDIR"/*.deb 2>/dev/null | awk '{print "  " $0}' || true
else
  warn "部分包失败（退出码 1）"
fi
exit "$ec"
