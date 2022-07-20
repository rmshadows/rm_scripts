#!/bin/bash
cd changeme1
conff="repost_live.txt"
sed -i '2d' "$conff"
sed -i '1a RTMP_S=""' "$conff"
