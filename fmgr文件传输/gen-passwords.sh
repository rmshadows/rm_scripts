#!/usr/bin/env bash
# fmgr 用户密码管理（用户名不动，只改 bcrypt 哈希）
#
# 算法与官方工具一致：
#   https://tinyfilemanager.github.io/docs/pwd.html
#   → PHP password_hash(..., PASSWORD_BCRYPT) → $2y$...
#   → Tiny File Manager 用 password_verify() 校验
#
# 用法:
#   ./gen-passwords.sh                          # 交互：默认 /home/HTML/fmgr
#   ./gen-passwords.sh --list
#   ./gen-passwords.sh --user admin --random
#   ./gen-passwords.sh --user admin --password 'MyPass!'
#   ./gen-passwords.sh --all --random --yes
#   ./gen-passwords.sh --dir /path/to/fmgr ...
#
# 需要：php-cli
set -euo pipefail

DEFAULT_DIR="/home/HTML/fmgr"
TARGET="$DEFAULT_DIR"
ASSUME_YES=0
DO_LIST=0
MODE=""          # random | password | ""(交互选)
PASSWORD=""
USER_SPEC=""     # 空=交互；all=全部；其它=用户名
USERS_FILTER=()

usage() {
  cat <<EOF
用法: $(basename "$0") [选项]

  （无参数）              交互管理（默认目录 $DEFAULT_DIR）
  --list / -l             列出用户后退出
  --user NAME             只改该用户
  --all                   改全部用户
  --random / -r           随机密码（默认，非交互时）
  --password PASS / -p    指定明文密码
  --dir PATH              fmgr 目录（默认 $DEFAULT_DIR）
  --yes / -y              不询问直接写入
  -h / --help             帮助

例:
  $(basename "$0") --user admin --password 'S3cret!'
  $(basename "$0") --user 123456 --random --yes
  $(basename "$0") --all --random --yes
  $(basename "$0") --dir ./fmgr --list
EOF
}

die() { echo "[x] $*" >&2; exit 1; }
ok()  { echo "[✓] $*"; }
log() { echo "[+] $*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      [[ -n "${2:-}" ]] || die "--dir 需要路径"
      TARGET="$2"
      shift 2
      ;;
    --user)
      [[ -n "${2:-}" ]] || die "--user 需要用户名"
      USER_SPEC="$2"
      shift 2
      ;;
    --all)
      USER_SPEC="all"
      shift
      ;;
    --random|-r)
      MODE="random"
      shift
      ;;
    --password|-p)
      [[ -n "${2:-}" ]] || die "--password 需要密码"
      MODE="password"
      PASSWORD="$2"
      shift 2
      ;;
    --list|-l)
      DO_LIST=1
      shift
      ;;
    --yes|-y)
      ASSUME_YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      # 兼容旧用法：单独一个路径参数
      if [[ -z "$TARGET" || "$TARGET" == "$DEFAULT_DIR" ]] && [[ -d "$1" || "$1" == */* ]]; then
        TARGET="$1"
        shift
      else
        die "未知参数: $1（见 --help）"
      fi
      ;;
  esac
done

command -v php >/dev/null 2>&1 || die "需要 php-cli：sudo apt install php-cli"

INDEX="$TARGET/index.php"
UPLOADER="$TARGET/uploader.php"
[[ -f "$INDEX" ]] || die "找不到 $INDEX（可用 --dir 指定部署目录）"
[[ -f "$UPLOADER" ]] || die "找不到 $UPLOADER"

list_users() {
  php -r '
$files = [$argv[1], $argv[2]];
$seen = [];
foreach ($files as $f) {
  $src = file_get_contents($f);
  if (!preg_match("/\\\$auth_users\\s*=\\s*array\\s*\\((.*?)\\)\\s*;/s", $src, $m)) continue;
  if (preg_match_all("/'\''([^'\'']+)'\''\\s*=>/", $m[1], $mm)) {
    foreach ($mm[1] as $u) {
      if (isset($seen[$u])) continue;
      $seen[$u] = 1;
      $where = [];
      foreach ($files as $ff) {
        $s = file_get_contents($ff);
        if (preg_match("/\\\$auth_users\\s*=\\s*array\\s*\\((.*?)\\)\\s*;/s", $s, $b)
            && preg_match("/'\''".preg_quote($u, "/")."'\''\\s*=>/", $b[1])) {
          $where[] = basename($ff);
        }
      }
      echo $u, "\t", implode(",", $where), "\n";
    }
  }
}
' "$UPLOADER" "$INDEX"
}

mapfile -t ALL_USER_LINES < <(list_users)
ALL_USERS=()
declare -A USER_IN_FILES=()
for line in "${ALL_USER_LINES[@]+"${ALL_USER_LINES[@]}"}"; do
  [[ -n "$line" ]] || continue
  u="${line%%$'\t'*}"
  files="${line#*$'\t'}"
  ALL_USERS+=("$u")
  USER_IN_FILES[$u]="$files"
done
((${#ALL_USERS[@]} > 0)) || die "未能从 PHP 解析出 auth_users 用户名"

print_user_table() {
  echo "目标目录: $TARGET"
  echo
  printf "  %-4s %-16s %s\n" "#" "用户" "所在文件"
  echo "  ----------------------------------------------"
  local i=1 u
  for u in "${ALL_USERS[@]}"; do
    printf "  %-4s %-16s %s\n" "$i" "$u" "${USER_IN_FILES[$u]}"
    i=$((i + 1))
  done
  echo
}

if [[ "$DO_LIST" -eq 1 ]]; then
  print_user_table
  exit 0
fi

# ---------- 选用户 ----------
if [[ -z "$USER_SPEC" ]]; then
  [[ -t 0 && -t 1 ]] || die "非交互请指定 --user NAME 或 --all（见 --help）"
  print_user_table
  read -r -p "改哪个用户？输入序号 / 用户名 / all（回车=取消）: " pick || true
  pick="${pick:-}"
  [[ -n "$pick" ]] || { echo "已取消"; exit 0; }
  if [[ "${pick,,}" == "all" || "$pick" == "*" ]]; then
    USER_SPEC="all"
  elif [[ "$pick" =~ ^[0-9]+$ ]]; then
    if ((pick < 1 || pick > ${#ALL_USERS[@]})); then
      die "序号超出范围"
    fi
    USER_SPEC="${ALL_USERS[$((pick - 1))]}"
  else
    USER_SPEC="$pick"
  fi
fi

USERS_FILTER=()
if [[ "$USER_SPEC" == "all" ]]; then
  USERS_FILTER=("${ALL_USERS[@]}")
else
  found=0
  for u in "${ALL_USERS[@]}"; do
    if [[ "$u" == "$USER_SPEC" ]]; then
      USERS_FILTER=("$u")
      found=1
      break
    fi
  done
  [[ "$found" -eq 1 ]] || die "用户不存在: $USER_SPEC（先 --list）"
fi

# ---------- 选密码方式 ----------
if [[ -z "$MODE" ]]; then
  if [[ -t 0 && -t 1 ]]; then
    echo "用户: ${USERS_FILTER[*]}"
    echo "  1) 随机密码"
    echo "  2) 指定密码"
    read -r -p "选 [1/2，默认 1]: " m || true
    m="${m:-1}"
    case "$m" in
      2)
        MODE="password"
        if ((${#USERS_FILTER[@]} > 1)); then
          read -r -p "为全部选中用户设置同一密码: " PASSWORD || true
        else
          read -r -p "新密码 (${USERS_FILTER[0]}): " PASSWORD || true
        fi
        [[ -n "${PASSWORD:-}" ]] || die "密码不能为空"
        ;;
      *) MODE="random" ;;
    esac
  else
    MODE="random"
  fi
fi

if [[ "$MODE" == "password" ]]; then
  [[ -n "${PASSWORD:-}" ]] || die "--password 不能为空"
elif [[ "$MODE" != "random" ]]; then
  die "内部错误: MODE=$MODE"
fi

echo
echo "将修改:"
printf '  - %s\n' "${USERS_FILTER[@]}"
echo "方式: $MODE"
echo "文件: $INDEX"
echo "      $UPLOADER"
echo

if [[ "$ASSUME_YES" -ne 1 ]]; then
  if [[ ! -t 0 ]]; then
    die "非交互请加 --yes"
  fi
  read -r -p "确认写入？[y/N] " ans || true
  case "${ans:-}" in
    y|Y|yes|YES) ;;
    *) echo "已取消"; exit 0 ;;
  esac
fi

TS="$(date +%Y%m%d%H%M%S)"
cp -a "$INDEX" "${INDEX}.pwd.bak.${TS}"
cp -a "$UPLOADER" "${UPLOADER}.pwd.bak.${TS}"
ok "已备份 → *.pwd.bak.${TS}"

export INDEX UPLOADER
export USERS_CSV
USERS_CSV="$(IFS=,; echo "${USERS_FILTER[*]}")"
export MODE PASSWORD

RESULT="$(php <<'PHP'
<?php
$users = array_values(array_filter(explode(',', getenv('USERS_CSV') ?: '')));
$files = [getenv('INDEX'), getenv('UPLOADER')];
$mode = getenv('MODE') ?: 'random';
$fixed = getenv('PASSWORD') ?: '';
$alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%+-';
$passwords = [];
$hashes = [];

foreach ($users as $u) {
    if ($mode === 'password') {
        $pw = $fixed;
    } else {
        $pw = '';
        for ($i = 0; $i < 14; $i++) {
            $pw .= $alphabet[random_int(0, strlen($alphabet) - 1)];
        }
    }
    if ($pw === '') {
        fwrite(STDERR, "empty password for $u\n");
        exit(1);
    }
    $passwords[$u] = $pw;
    $hashes[$u] = password_hash($pw, PASSWORD_BCRYPT, ['cost' => 10]);
}

foreach ($files as $f) {
    $src = file_get_contents($f);
    if (!preg_match('/\$auth_users\s*=\s*array\s*\((.*?)\)\s*;/s', $src, $m, PREG_OFFSET_CAPTURE)) {
        continue; // 该文件可能没有 auth_users
    }
    $block = $m[1][0];
    $touched = false;
    $newBlock = preg_replace_callback(
        "/('([^']+)'\s*=>\s*')([^']*)(')/",
        function ($mm) use ($hashes, &$touched) {
            $user = $mm[2];
            if (!isset($hashes[$user])) {
                return $mm[0];
            }
            $touched = true;
            return $mm[1] . $hashes[$user] . $mm[4];
        },
        $block
    );
    if ($newBlock === null) {
        fwrite(STDERR, "regex failed on $f\n");
        exit(1);
    }
    if (!$touched) {
        continue;
    }
    $start = $m[1][1];
    $len = strlen($block);
    $out = substr($src, 0, $start) . $newBlock . substr($src, $start + $len);
    file_put_contents($f, $out);
}

foreach ($passwords as $u => $pw) {
    echo $u, "\t", $pw, "\n";
}
PHP
)"

ok "已写入新哈希"
echo
echo "=============================================="
echo "密码（只显示一次，请立刻保存）："
echo "----------------------------------------------"
while IFS=$'\t' read -r u p; do
  [[ -n "${u:-}" ]] || continue
  printf '  %-12s  %s  (%s)\n' "$u" "$p" "${USER_IN_FILES[$u]:-?}"
done <<<"$RESULT"
echo "----------------------------------------------"
echo "还原: cp ${INDEX}.pwd.bak.${TS} $INDEX && cp ${UPLOADER}.pwd.bak.${TS} $UPLOADER"
echo "=============================================="

VERIFY_OK=1
while IFS=$'\t' read -r u p; do
  [[ -n "${u:-}" ]] || continue
  for f in "$INDEX" "$UPLOADER"; do
    if ! grep -q "'$u'" "$f" 2>/dev/null; then
      continue
    fi
    # 只校验 auth_users 里出现的
    php -r '
      $src = file_get_contents($argv[1]);
      if (!preg_match("/\\\$auth_users\\s*=\\s*array\\s*\\((.*?)\\)\\s*;/s", $src, $m)) exit(0);
      if (!preg_match("/'\''".preg_quote($argv[2], "/")."'\''\\s*=>\\s*'\''([^'\'']*)'\''/", $m[1], $h)) exit(0);
      exit(password_verify($argv[3], $h[1]) ? 0 : 4);
    ' "$f" "$u" "$p" || { echo "[x] 校验失败: $u @ $(basename "$f")" >&2; VERIFY_OK=0; }
  done
done <<<"$RESULT"

[[ "$VERIFY_OK" -eq 1 ]] || die "写入后校验失败，请用备份还原"
ok "password_verify 自检通过"
