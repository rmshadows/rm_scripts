#!/bin/bash
cd changeme_path/changeme_dir
conff="repost_live.txt"
sed -i '3d' "$conff"
sed -i '2a RTMP_D=""' "$conff"
