#!/usr/bin/env bash
# 需要sudo apt install qpdf
# 将当前目录下的奇数页PDF，在末尾补空白页

set -euo pipefail

ARCHIVE_DIR="source_pdfs"     # 源文件归档目录（会自动创建）
MOVE_EVEN_TOO=0               # 1=偶数页也移动；0=偶数页不动

mkdir -p "$ARCHIVE_DIR"

find . -maxdepth 1 -type f -name '*.pdf' -print0 |
while IFS= read -r -d '' f; do
  base="$(basename "$f")"

  pages="$(pdfinfo "$f" 2>/dev/null | awk -F: '/^Pages/ {gsub(/ /,"",$2); print $2}')"
  if [[ -z "${pages:-}" ]]; then
    echo "跳过（无法读取页数）：$base" >&2
    continue
  fi

  # 偶数页：按开关决定是否移动到归档目录
  if (( pages % 2 == 0 )); then
    echo "已是偶数页：$base ($pages pages)"
    if (( MOVE_EVEN_TOO == 1 )); then
      mv -n -- "$f" "$ARCHIVE_DIR/"
      echo "  已移动源文件到：$ARCHIVE_DIR/$base"
    fi
    continue
  fi

  # 读取第一页尺寸（单位 pts）
  read -r w h < <(pdfinfo "$f" 2>/dev/null | awk '
    /^Page size:/ {
      for (i=1; i<=NF; i++) if ($i=="x") {print $(i-1), $(i+1); exit}
    }'
  )

  # 兜底：A4 (595x842 pts)
  if [[ -z "${w:-}" || -z "${h:-}" ]]; then
    w="595"; h="842"
  fi

  out="./${base%.pdf}_even.pdf"
  blank="$(mktemp --suffix=.pdf)"
  tmpout="$(mktemp --suffix=.pdf)"

  # 生成 1 页空白 PDF（同尺寸）
  gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -o "$blank" \
     -c "<</PageSize [$w $h]>> setpagedevice" -c showpage

  # 先输出到临时文件，成功后再原子替换成目标文件（更稳）
  qpdf "$f" --pages "$f" 1-z "$blank" 1 -- "$tmpout"
  mv -f -- "$tmpout" "$out"

  rm -f "$blank"

  # 生成成功后再移动源文件
  mv -n -- "$f" "$ARCHIVE_DIR/"

  echo "已补空白页：$base ($pages -> $((pages+1))) => $(basename "$out")"
  echo "源文件已移动到：$ARCHIVE_DIR/$base"
done

