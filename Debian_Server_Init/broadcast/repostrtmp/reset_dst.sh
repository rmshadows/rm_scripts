#!/bin/bash
cd changeme1
conff="repost_live.txt"
sed -i '3d' "$conff"
sed -i '2a RTMP_D=""' "$conff"
