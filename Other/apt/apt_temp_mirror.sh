#!/usr/bin/env bash
# 临时切换 apt 镜像（只改镜像主机，不改发行版代号 Suites）
#
# 支持：
#   - Debian（bullseye / bookworm / trixie …）→ 路径 /debian 、/debian-security
#   - Ubuntu（jammy / noble …）            → 路径 /ubuntu
# 自动读 /etc/os-release，不写死某一个版本。
#
# 典型场景：
#   某个国内镜像同步滞后，apt update 出现 Packages 404，
#   临时切到清华 TUNA（或其它镜像）装依赖，事毕再 restore。
#
# 用法:
#   ./apt_temp_mirror.sh list
#   ./apt_temp_mirror.sh status
#   ./apt_temp_mirror.sh tuna                 # 备份 → 换清华 → apt update
#   ./apt_temp_mirror.sh ustc
#   ./apt_temp_mirror.sh official
#   ./apt_temp_mirror.sh restore
#   ./apt_temp_mirror.sh tuna --no-update
#   ./apt_temp_mirror.sh backups
#
# 备份目录: /var/backups/apt-temp-mirror/
# 第三方源（Docker 等）不动。
set -euo pipefail

BACKUP_ROOT="/var/backups/apt-temp-mirror"
ASSUME_YES=0
DO_UPDATE=1
ACTION=""
MIRROR_KEY=""

# 由 detect_os 填充
OS_ID=""
OS_CODENAME=""
OS_PRETTY=""
DISTRO=""          # debian | ubuntu
ARCHIVE_NAME=""    # debian | ubuntu

die() { echo "[x] $*" >&2; exit 1; }
info() { echo "[+] $*" >&2; }
warn() { echo "[!] $*" >&2; }

usage() {
  cat <<'EOF'
临时切换 apt 镜像（解决镜像 404 / 同步延迟）

自动识别 Debian / Ubuntu，只替换镜像 URI，保留原有 Suites（代号）。
例如 Debian 13 的 trixie、Debian 12 的 bookworm、Ubuntu 的 jammy 都不会被改掉。

用法:
  ./apt_temp_mirror.sh list
  ./apt_temp_mirror.sh status
  ./apt_temp_mirror.sh tuna|ustc|ali|huawei|bfsu|sjtu|official
  ./apt_temp_mirror.sh restore
  ./apt_temp_mirror.sh backups

选项:
  --no-update   换源后不执行 apt update
  -y, --yes     少询问
  -h, --help    显示帮助

示例:
  sudo ./apt_temp_mirror.sh tuna
  sudo ./apt_temp_mirror.sh restore
EOF
}

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    die "请用 root 运行（sudo $0 $*）"
  fi
}

detect_os() {
  # shellcheck source=/dev/null
  [[ -r /etc/os-release ]] || die "找不到 /etc/os-release"
  . /etc/os-release
  OS_ID="${ID:-}"
  OS_CODENAME="${VERSION_CODENAME:-unknown}"
  OS_PRETTY="${PRETTY_NAME:-unknown}"
  local like="${ID_LIKE:-}"

  case "$OS_ID" in
    debian)
      DISTRO=debian
      ARCHIVE_NAME=debian
      ;;
    ubuntu)
      DISTRO=ubuntu
      ARCHIVE_NAME=ubuntu
      ;;
    *)
      if [[ " $like " == *" ubuntu "* ]]; then
        DISTRO=ubuntu
        ARCHIVE_NAME=ubuntu
        warn "按 Ubuntu 路径处理衍生版: $OS_ID"
      elif [[ " $like " == *" debian "* ]]; then
        DISTRO=debian
        ARCHIVE_NAME=debian
        warn "按 Debian 路径处理衍生版: $OS_ID（若源格式特殊请手动检查）"
      else
        die "不支持的系统: $OS_PRETTY（ID=$OS_ID）。仅支持 Debian / Ubuntu。"
      fi
      ;;
  esac
}

# 输出: key|显示名|主库 URI|security URI
# 按当前 DISTRO 给出对应路径，不绑定具体代号。
mirror_table() {
  if [[ "$DISTRO" == ubuntu ]]; then
    cat <<'EOF'
tuna|清华大学 TUNA|https://mirrors.tuna.tsinghua.edu.cn/ubuntu|https://mirrors.tuna.tsinghua.edu.cn/ubuntu
ustc|中科大 USTC|https://mirrors.ustc.edu.cn/ubuntu|https://mirrors.ustc.edu.cn/ubuntu
ali|阿里云|https://mirrors.aliyun.com/ubuntu|https://mirrors.aliyun.com/ubuntu
huawei|华为云|https://mirrors.huaweicloud.com/ubuntu|https://mirrors.huaweicloud.com/ubuntu
bfsu|北京外国语 BFSU|https://mirrors.bfsu.edu.cn/ubuntu|https://mirrors.bfsu.edu.cn/ubuntu
sjtu|上海交大|https://mirror.sjtu.edu.cn/ubuntu|https://mirror.sjtu.edu.cn/ubuntu
official|Ubuntu 官方|http://archive.ubuntu.com/ubuntu|http://security.ubuntu.com/ubuntu
EOF
  else
    cat <<'EOF'
tuna|清华大学 TUNA|https://mirrors.tuna.tsinghua.edu.cn/debian|https://mirrors.tuna.tsinghua.edu.cn/debian-security
ustc|中科大 USTC|https://mirrors.ustc.edu.cn/debian|https://mirrors.ustc.edu.cn/debian-security
ali|阿里云|https://mirrors.aliyun.com/debian|https://mirrors.aliyun.com/debian-security
huawei|华为云|https://mirrors.huaweicloud.com/debian|https://mirrors.huaweicloud.com/debian-security
bfsu|北京外国语 BFSU|https://mirrors.bfsu.edu.cn/debian|https://mirrors.bfsu.edu.cn/debian-security
sjtu|上海交大|https://mirror.sjtu.edu.cn/debian|https://mirror.sjtu.edu.cn/debian-security
official|Debian 官方|https://deb.debian.org/debian|https://security.debian.org/debian-security
EOF
  fi
}

resolve_mirror() {
  local key="$1" line
  line="$(mirror_table | awk -F'|' -v k="$key" '$1==k{print; exit}')"
  [[ -n "$line" ]] || return 1
  IFS='|' read -r MIRROR_KEY MIRROR_NAME MIRROR_MAIN MIRROR_SECURITY <<<"$line"
}

list_mirrors() {
  info "当前系统: $OS_PRETTY"
  info "识别为: $DISTRO（代号 $OS_CODENAME，归档路径 /$ARCHIVE_NAME）"
  printf '%-10s  %s\n' "KEY" "镜像"
  mirror_table | while IFS='|' read -r k name main sec; do
    printf '%-10s  %s\n' "$k" "$name"
    printf '            main:     %s\n' "$main"
    printf '            security: %s\n' "$sec"
  done
}

collect_source_files() {
  [[ -f /etc/apt/sources.list ]] && printf '%s\n' /etc/apt/sources.list
  if [[ -d /etc/apt/sources.list.d ]]; then
    find /etc/apt/sources.list.d -maxdepth 1 -type f \( -name '*.list' -o -name '*.sources' \) | sort
  fi
}

# 只处理当前发行版主库/安全库相关文件
is_distro_mirror_file() {
  local f="$1"
  if [[ "$DISTRO" == ubuntu ]]; then
    grep -Eq '/ubuntu([[:space:]]|/|$)|security\.ubuntu\.com|archive\.ubuntu\.com|ports\.ubuntu\.com' "$f" 2>/dev/null
  else
    grep -Eq 'debian-security|/debian([[:space:]]|/|$)|security\.debian\.org|deb\.debian\.org' "$f" 2>/dev/null
  fi
}

show_status() {
  local f hosts
  info "系统: $OS_PRETTY"
  info "识别: $DISTRO / 代号 $OS_CODENAME（只换镜像主机，不改代号）"
  info "扫描 apt 源文件中的镜像主机："
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    hosts="$(grep -Eo 'https?://[^[:space:]/]+' "$f" 2>/dev/null | sed 's#https\?://##' | sort -u | tr '\n' ' ' || true)"
    [[ -n "${hosts// /}" ]] || continue
    printf '  %s\n' "$f"
    printf '    → %s\n' "$hosts"
  done < <(collect_source_files)
}

make_backup() {
  local stamp dest f
  stamp="$(date +%Y%m%d-%H%M%S)"
  dest="${BACKUP_ROOT}/${stamp}"
  mkdir -p "$dest/sources.list.d"
  if [[ -f /etc/apt/sources.list ]]; then
    cp -a /etc/apt/sources.list "$dest/sources.list"
  fi
  while IFS= read -r f; do
    [[ "$(basename "$f")" == sources.list ]] && continue
    if [[ "$f" == /etc/apt/sources.list.d/* ]]; then
      cp -a "$f" "$dest/sources.list.d/"
    fi
  done < <(collect_source_files)

  {
    echo "time=$(date -Iseconds)"
    echo "os=$OS_ID"
    echo "codename=$OS_CODENAME"
    echo "distro=$DISTRO"
    echo "mirror=${MIRROR_KEY:-unknown}"
    echo "name=${MIRROR_NAME:-}"
  } >"$dest/meta.txt"

  ln -sfn "$stamp" "${BACKUP_ROOT}/latest"
  info "已备份当前源 → $dest"
  echo "$dest"
}

restore_backup() {
  local src="${1:-}"
  if [[ -z "$src" ]]; then
    [[ -L "${BACKUP_ROOT}/latest" || -d "${BACKUP_ROOT}/latest" ]] \
      || die "没有可恢复的备份（${BACKUP_ROOT}/latest）。先执行过 switch 才会有。"
    src="${BACKUP_ROOT}/latest"
  fi
  src="$(readlink -f "$src")"
  [[ -d "$src" ]] || die "备份目录不存在: $src"

  info "将从备份恢复: $src"
  if [[ -f "$src/sources.list" ]]; then
    cp -a "$src/sources.list" /etc/apt/sources.list
  fi
  if [[ -d "$src/sources.list.d" ]]; then
    local f base
    while IFS= read -r f; do
      base="$(basename "$f")"
      cp -a "$f" "/etc/apt/sources.list.d/$base"
      info "恢复 sources.list.d/$base"
    done < <(find "$src/sources.list.d" -maxdepth 1 -type f | sort)
  fi
}

list_backups() {
  [[ -d "$BACKUP_ROOT" ]] || { info "暂无备份"; return 0; }
  local d latest
  latest="$(readlink -f "${BACKUP_ROOT}/latest" 2>/dev/null || true)"
  find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name latest -printf '%f\n' | sort \
    | while read -r d; do
      if [[ -n "$latest" && "$(readlink -f "${BACKUP_ROOT}/$d")" == "$latest" ]]; then
        printf '* %s  (latest)\n' "$d"
      else
        printf '  %s\n' "$d"
      fi
      if [[ -f "${BACKUP_ROOT}/$d/meta.txt" ]]; then
        sed 's/^/    /' "${BACKUP_ROOT}/$d/meta.txt"
      fi
    done
}

rewrite_file_mirrors() {
  local file="$1" main_uri="$2" sec_uri="$3" tmp
  tmp="$(mktemp)"

  if [[ "$DISTRO" == ubuntu ]]; then
    # Ubuntu：主库与 security 常同为 /ubuntu；官方则是 archive / security 两个主机
    sed -E \
      -e "s#https?://security\\.ubuntu\\.com/ubuntu#${sec_uri}#g" \
      -e "s#https?://archive\\.ubuntu\\.com/ubuntu#${main_uri}#g" \
      -e "s#https?://ports\\.ubuntu\\.com/ubuntu-ports#${main_uri}#g" \
      -e "s#https?://[[:alnum:].-]+/ubuntu([[:space:]/]|\$)#${main_uri}\\1#g" \
      "$file" >"$tmp"
  else
    # Debian：先换 debian-security，再换 /debian，避免误伤
    sed -E \
      -e "s#https?://[[:alnum:].-]+/debian-security#${sec_uri}#g" \
      -e "s#https?://security\\.debian\\.org/debian-security#${sec_uri}#g" \
      -e "s#https?://security\\.debian\\.org([[:space:]])#${sec_uri}\\1#g" \
      -e "s#https?://[[:alnum:].-]+/debian([[:space:]/]|\$)#${main_uri}\\1#g" \
      "$file" >"$tmp"
  fi

  if ! cmp -s "$file" "$tmp"; then
    cp -a "$tmp" "$file"
    info "已改写: $file"
  else
    info "无需改动: $file"
  fi
  rm -f "$tmp"
}

switch_mirror() {
  local f
  resolve_mirror "$1" || die "未知镜像: $1（见: $0 list）"

  info "系统: $OS_PRETTY（$DISTRO / $OS_CODENAME）"
  info "目标镜像: $MIRROR_NAME"
  info "  main:     $MIRROR_MAIN"
  info "  security: $MIRROR_SECURITY"
  info "不会修改 Suites/代号（仍为 $OS_CODENAME）"

  local targets=()
  while IFS= read -r f; do
    if is_distro_mirror_file "$f"; then
      targets+=("$f")
    fi
  done < <(collect_source_files)

  if [[ "${#targets[@]}" -eq 0 ]]; then
    die "未找到含 ${DISTRO} 主库/安全库 URI 的源文件。"
  fi

  info "将改写以下文件:"
  for f in "${targets[@]}"; do
    printf '  - %s\n' "$f" >&2
  done

  if [[ "$ASSUME_YES" -ne 1 ]]; then
    read -r -p "备份并切换？[Y/n] " ans || true
    case "${ans:-Y}" in
      [yY]|[yY][eE][sS]|"") ;;
      *) info "已取消"; exit 0 ;;
    esac
  fi

  make_backup >/dev/null
  for f in "${targets[@]}"; do
    rewrite_file_mirrors "$f" "$MIRROR_MAIN" "$MIRROR_SECURITY"
  done

  if [[ "$DO_UPDATE" -eq 1 ]]; then
    info "执行 apt update …"
    if apt-get update; then
      info "apt update 完成"
    else
      warn "apt update 失败。可用: sudo $0 restore"
      exit 1
    fi
  else
    info "已跳过 apt update（--no-update）"
  fi

  info "切回原源: sudo $0 restore"
}

# ---- 参数 ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    --no-update) DO_UPDATE=0; shift ;;
    list|status|restore|backups)
      ACTION="$1"; shift ;;
    tuna|tsinghua|ustc|ali|aliyun|huawei|bfsu|sjtu|official|debian)
      ACTION="switch"
      case "$1" in
        tsinghua) MIRROR_KEY=tuna ;;
        aliyun) MIRROR_KEY=ali ;;
        debian) MIRROR_KEY=official ;;
        *) MIRROR_KEY="$1" ;;
      esac
      shift
      ;;
    *)
      die "未知参数: $1（见 --help）"
      ;;
  esac
done

[[ -n "$ACTION" ]] || { usage; exit 2; }

detect_os

case "$ACTION" in
  list) list_mirrors ;;
  status) show_status ;;
  backups) list_backups ;;
  restore)
    need_root
    restore_backup
    if [[ "$DO_UPDATE" -eq 1 ]]; then
      info "执行 apt update …"
      apt-get update || warn "apt update 失败，请检查源文件"
    fi
    info "已恢复备份源"
    ;;
  switch)
    need_root
    switch_mirror "$MIRROR_KEY"
    ;;
esac
