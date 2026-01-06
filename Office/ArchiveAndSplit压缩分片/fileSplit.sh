#!/usr/bin/env bash
set -u  # 不用 -e：可选步骤失败不影响主流程

# ---------------------------
# Defaults
# ---------------------------
default_file="1.zip"
split_size="450M"

gen_sh=1
gen_bat_merge=1          # 是否生成 merge_parts.bat
gen_bat_hash=1           # 是否生成 show_sha256.bat
gen_hash_txt=1           # 是否生成 checksums_sha256.txt（并终端输出）

bat_require_unix2dos=0   # 1: 没有 unix2dos 就跳过 bat；0: 仍生成 bat（默认）
bat_try_unix2dos=1       # 有 unix2dos 就尝试转 CRLF

# 输出文件名
hash_txt="checksums_sha256.txt"

# ---------------------------
# Helpers
# ---------------------------
log()  { printf "✅ %s\n" "$*"; }
info() { printf "ℹ️  %s\n" "$*"; }
warn() { printf "⚠️  %s\n" "$*" >&2; }
die()  { printf "❌ %s\n" "$*" >&2; exit 1; }

need_cmd_or_die() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# 可选步骤：失败只警告
try_run() {
  local desc="$1"; shift
  if "$@"; then
    log "$desc"
    return 0
  else
    local ec=$?
    warn "$desc failed (exit=$ec), skipping.\n"
    return $ec
  fi
}

usage() {
  cat <<'EOF'
Usage:
  split_zip.sh [file] [options]

Options:
  -s, --size <SIZE>           split chunk size (default: 200M)
  --no-sh                     do not generate merge_parts.sh
  --no-merge-bat              do not generate merge_parts.bat
  --no-hash-bat               do not generate show_sha256.bat
  --no-hash                   do not generate checksums_sha256.txt
  --bat-require-unix2dos      if unix2dos missing -> skip .bat files
  --bat-allow-no-unix2dos     generate .bat even if unix2dos missing (default)
  -h, --help                  show help

Examples:
  ./split_zip.sh big.zip
  ./split_zip.sh big.zip -s 500M
  ./split_zip.sh big.zip --no-hash
EOF
}

# ---------------------------
# Args
# ---------------------------
input_file="${1:-$default_file}"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--size)
      [[ $# -ge 2 ]] || die "Missing value for $1"
      split_size="$2"
      shift 2
      ;;
    --no-sh) gen_sh=0; shift ;;
    --no-merge-bat) gen_bat_merge=0; shift ;;
    --no-hash-bat) gen_bat_hash=0; shift ;;
    --no-hash) gen_hash_txt=0; shift ;;
    --bat-require-unix2dos) bat_require_unix2dos=1; shift ;;
    --bat-allow-no-unix2dos) bat_require_unix2dos=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
done

# ---------------------------
# Mandatory checks & split (MUST succeed)
# ---------------------------
need_cmd_or_die split
need_cmd_or_die sort

[[ -f "$input_file" ]] || die "File not found: $input_file"

prefix="${input_file}_part_"

info "Splitting '$input_file' into $split_size chunks..."
if ! split -d -a 2 -b "$split_size" -- "$input_file" "$prefix"; then
  die "Split failed. Aborting."
fi
log "Splitting done."

# ---------------------------
# Collect parts safely
# ---------------------------
shopt -s nullglob
parts=( "${prefix}"* )
shopt -u nullglob

[[ ${#parts[@]} -gt 0 ]] || die "No part files found with prefix: ${prefix}"

IFS=$'\n' parts_sorted=( $(printf "%s\n" "${parts[@]}" | sort) )
unset IFS

# ---------------------------
# Build merge commands
# ---------------------------
bat_merge_cmd="copy /b "
for p in "${parts_sorted[@]}"; do
  bat_merge_cmd+="\"$p\" + "
done
bat_merge_cmd="${bat_merge_cmd::-3} \"$input_file\""

sh_merge_cmd="cat"
for p in "${parts_sorted[@]}"; do
  sh_merge_cmd+=" \"$p\""
done
sh_merge_cmd+=" > \"$input_file\""

# ---------------------------
# Print instructions
# ---------------------------
echo ""
echo "📋 Copy-paste these commands to rejoin the file:"
echo ""
echo "🪟 Windows CMD:"
echo "$bat_merge_cmd"
echo ""
echo "🐧 Linux/macOS:"
echo "$sh_merge_cmd"
echo ""

# ---------------------------
# Optional: merge_parts.sh (merge + verify checksum AFTER merge, and print sums)
# ---------------------------
if [[ "$gen_sh" -eq 1 ]]; then
  try_run "Generated: merge_parts.sh" bash -c "
    cat > merge_parts.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

INPUT_FILE=\"$input_file\"
HASH_TXT=\"$hash_txt\"

# 1) Merge
$sh_merge_cmd
echo \"✅ Merge done: \$INPUT_FILE\"
echo

# 2) Decide hash tool
hash_tool=\"\"
if command -v sha256sum >/dev/null 2>&1; then
  hash_tool=\"sha256sum\"
elif command -v shasum >/dev/null 2>&1; then
  hash_tool=\"shasum\"
fi

if [[ -z \"\$hash_tool\" ]]; then
  echo \"⚠️  No sha256 tool (sha256sum/shasum). Skip verification.\"
  exit 0
fi

if [[ ! -f \"\$HASH_TXT\" ]]; then
  echo \"⚠️  \$HASH_TXT not found. Skip verification.\"
  exit 0
fi

# 3) Verify parts (recommended)
echo \"🔐 Verifying parts using \$HASH_TXT...\"
if [[ \"\$hash_tool\" == \"sha256sum\" ]]; then
  sha256sum -c \"\$HASH_TXT\" --quiet || { echo \"❌ Part verification failed.\"; exit 1; }
else
  shasum -a 256 -c \"\$HASH_TXT\" >/dev/null || { echo \"❌ Part verification failed.\"; exit 1; }
fi
echo \"✅ Parts verified.\"
echo

# 4) Read expected hash for merged file AT RUNTIME
expected=\$(awk -v f=\"\$INPUT_FILE\" '\$2==f {print \$1; exit}' \"\$HASH_TXT\" || true)

if [[ -z \"\${expected:-}\" ]]; then
  echo \"❌ Expected hash for \$INPUT_FILE not found in \$HASH_TXT.\"
  exit 1
fi

# 5) Compute actual hash
if [[ \"\$hash_tool\" == \"sha256sum\" ]]; then
  actual=\$(sha256sum -- \"\$INPUT_FILE\" | awk '{print \$1}')
else
  actual=\$(shasum -a 256 -- \"\$INPUT_FILE\" | awk '{print \$1}')
fi

# 6) Print sums + compare
echo \"🔐 Verifying merged file checksum...\"
echo \"Expected SHA256 : \$expected\"
echo \"Actual   SHA256 : \$actual\"

if [[ \"\$actual\" != \"\$expected\" ]]; then
  echo \"❌ Merged file hash mismatch!\"
  exit 1
fi

echo \"✅ Merged file verified OK.\"
EOF
    chmod +x merge_parts.sh
  "
fi

# ---------------------------
# Hash function selector (sha256sum preferred, fallback shasum -a 256)
# ---------------------------
hash_tool=""
hash_cmd() { :; }  # placeholder

if command -v sha256sum >/dev/null 2>&1; then
  hash_tool="sha256sum"
  hash_cmd() { sha256sum -- "$1"; }
elif command -v shasum >/dev/null 2>&1; then
  hash_tool="shasum"
  hash_cmd() { shasum -a 256 -- "$1"; }
else
  hash_tool=""
fi

# ---------------------------
# Generate SHA256 checksums (MUST try after split success; if tool missing -> warn & skip)
# ---------------------------
if [[ "$gen_hash_txt" -eq 1 ]]; then
  if [[ -z "$hash_tool" ]]; then
    warn "No sha256 tool found (sha256sum/shasum). Skipping $hash_txt.\n"
  else
    info "Generating SHA256 checksums using: $hash_tool"
    {
      # 统一成 sha256sum 风格：<hash><two spaces><filename>
      # sha256sum 输出本来就是这样；shasum 输出是 "<hash>  <file>" 也一致
      hash_cmd "$input_file"
      for p in "${parts_sorted[@]}"; do
        hash_cmd "$p"
      done
    } | awk '{
      # 防御性清洗：只取前两列（hash + filename），中间用两个空格
      # 注意：文件名含空格时，sha256sum/shasum 会把空格作为字段分隔，不完美；
      # 若你需要完全支持含空格文件名，建议统一不要给文件名加空格。
      print $1 "  " $2
    }' | tee "$hash_txt" >/dev/null

    log "Generated: $hash_txt (and printed above)"
    echo ""
    echo "🔐 SHA256 checksums ($hash_txt):"
    cat "$hash_txt"
    echo ""
  fi
fi

# ---------------------------
# Optional: Windows BAT generation (merge + show sha256)
# ---------------------------
has_unix2dos=0
if command -v unix2dos >/dev/null 2>&1; then
  has_unix2dos=1
fi

if [[ "$bat_require_unix2dos" -eq 1 && "$has_unix2dos" -eq 0 ]]; then
  warn "unix2dos not found; skipping .bat generation (require enabled).\n"
else
  # ---- merge_parts.bat ----
  if [[ "$gen_bat_merge" -eq 1 ]]; then
    try_run "Generated: merge_parts.bat" bash -c "
      utf8_bom=\$'\xEF\xBB\xBF'
      bat_filename='merge_parts.bat'
      bat_content='@echo off
chcp 65001 >nul
echo Merging parts...
$bat_merge_cmd
if errorlevel 1 (
  echo Merge failed.
  exit /b 1
)
echo Done.'
      printf '%s' \"\$utf8_bom\" > \"\$bat_filename\"
      printf '%s\r\n' \"\$bat_content\" >> \"\$bat_filename\"
    "
    if [[ "$has_unix2dos" -eq 1 && "$bat_try_unix2dos" -eq 1 ]]; then
      try_run "Converted merge_parts.bat to DOS (unix2dos)" unix2dos merge_parts.bat >/dev/null 2>&1
    fi
  fi
  # ---- show_sha256.bat (PowerShell-based, can also verify if checksums file exists) ----
  if [[ "$gen_bat_hash" -eq 1 ]]; then
    # 用 | 拼成一个安全的文件列表字符串（尽量保证文件名里不要包含 |）
    file_list="$input_file"
    for p in "${parts_sorted[@]}"; do
      file_list+="|$p"
    done

    # 直接在当前 bash 里写文件，避免 bash -c 拼接导致括号/引号解析错误
    {
      bat_filename="show_sha256.bat"
      utf8_bom=$'\xEF\xBB\xBF'

      # 写入 BOM
      printf '%s' "$utf8_bom" > "$bat_filename"

      # 写入 bat 内容（使用 heredoc，最大化稳定性）
      cat >> "$bat_filename" <<EOF
@echo off
chcp 65001 >nul
setlocal EnableExtensions

set "HASHFILE=$hash_txt"
set "FILELIST=$file_list"

echo.
echo === SHA256 (computed by PowerShell) ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "\$files = \$env:FILELIST.Split('|'); foreach(\$f in \$files){ if(Test-Path -LiteralPath \$f){ \$h=(Get-FileHash -Algorithm SHA256 -LiteralPath \$f).Hash.ToLower(); Write-Host (\"{0}  {1}\" -f \$h,\$f) } else { Write-Host (\"(missing)  {0}\" -f \$f) } }"

echo.
if exist "%HASHFILE%" (
  echo === Expected checksums from %HASHFILE% ===
  type "%HASHFILE%"
  echo.
  echo === Verify (compare expected vs computed) ===

  powershell -NoProfile -ExecutionPolicy Bypass -Command "\
\$exp=@{}; \
Get-Content -LiteralPath \$env:HASHFILE | ForEach-Object { \
  if(\$_ -match '^[0-9a-fA-F]{64}\\s\\s(.+)\$'){ \
    \$hash=\$_.Substring(0,64).ToLower(); \
    \$file=\$_.Substring(66); \
    \$exp[\$file]=\$hash \
  } \
}; \
\$ok=\$true; \
\$files=\$env:FILELIST.Split('|'); \
foreach(\$f in \$files){ \
  if(-not (Test-Path -LiteralPath \$f)){ Write-Host \"MISSING: \$f\"; \$ok=\$false; continue } \
  \$cur=(Get-FileHash -Algorithm SHA256 -LiteralPath \$f).Hash.ToLower(); \
  if(\$exp.ContainsKey(\$f)){ \
    if(\$cur -eq \$exp[\$f]){ Write-Host \"OK: \$f\" } else { Write-Host \"FAIL: \$f\"; \$ok=\$false } \
  } else { \
    Write-Host \"NO EXPECTED HASH: \$f\" \
  } \
}; \
if(-not \$ok){ exit 1 }"

  if errorlevel 1 (
    echo Verification failed.
    exit /b 1
  ) else (
    echo Verification OK.
  )
) else (
  echo (No %HASHFILE% found. Only displayed computed hashes.)
)

echo.
pause
endlocal
EOF

      # 有 unix2dos 就转一下；失败不影响主流程
      if [[ "$has_unix2dos" -eq 1 && "$bat_try_unix2dos" -eq 1 ]]; then
        unix2dos "$bat_filename" >/dev/null 2>&1 || true
      fi
    } && log "Generated: show_sha256.bat" || warn "Generated: show_sha256.bat failed, skipping.\n"
  fi
fi

