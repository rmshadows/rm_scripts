#!/bin/bash
cd changeme_path/changeme_dir
conff="repost_live.txt"
sed -i '2d' "$conff"
sed -i '2d' "$conff"
sed -i '1a RTMP_D=""' "$conff"
sed -i '1a RTMP_S=""' "$conff"


