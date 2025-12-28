#!/usr/bin/env bash

########################################
# 提取包含flac的链接
# Extract FLAC URLs from archive.org dir
########################################

# ====== 配置区（你只需要改这里） ======

BASE_URL="https://archive.org/download/MozartComplete9Vol44FullCD.Flac/Mozart/"
OUTPUT_FILE="urls.txt"

# 是否只匹配特定关键词（留空表示全部）
KEYWORD=""   # 例如: Symphonies / Concertos

# =====================================

echo "[INFO] Fetching page: $BASE_URL"

if [ -z "$KEYWORD" ]; then
  curl -s "$BASE_URL" \
  | grep -oE 'href="[^"]+\.flac"' \
  | sed 's/href="//;s/"$//' \
  | sed "s|^|$BASE_URL|" \
  > "$OUTPUT_FILE"
else
  curl -s "$BASE_URL" \
  | grep -oE "href=\"[^\"]*${KEYWORD}[^\"]*\.flac\"" \
  | sed 's/href="//;s/"$//' \
  | sed "s|^|$BASE_URL|" \
  > "$OUTPUT_FILE"
fi

COUNT=$(wc -l < "$OUTPUT_FILE")

echo "[OK] Extracted $COUNT FLAC URLs"
echo "[OK] Saved to $OUTPUT_FILE"

