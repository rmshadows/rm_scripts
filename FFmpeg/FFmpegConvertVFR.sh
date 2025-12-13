#!/usr/bin/env bash

INPUT="${1:-1.MP4}"
OUTPUT="${INPUT%.*}_EDIT_30fps_CFR_HEVC.mp4"

ffmpeg -y \
  -vaapi_device /dev/dri/renderD128 \
  -i "$INPUT" \
  -vf "fps=30,format=nv12,hwupload" \
  -fps_mode cfr \
  -c:v hevc_vaapi \
  -qp 28 \
  -c:a aac \
  -b:a 128k \
  "$OUTPUT"




