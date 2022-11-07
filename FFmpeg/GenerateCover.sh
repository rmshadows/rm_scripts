#!/bin/bash
# http://t.zoukankan.com/yuandaozhe-p-14519296.html

# 截取时间
t="00:00:04"
# 视频扩展名
vext="mp4"
function doFiles(){
for file in `ls $1`
do
    if [ -d $1"/"$file ] 
    then
        echo "Msg: Directory "$1"/'$file' Passed."
    else
        if [[ "$file" == *"$2" ]];  
        then 
             fn=$1"/"$file
             ffmpeg -ss "$t" -i $fn $file.jpg  -r 1 -frames:v 1 -an -vcodec mjpeg -y
        fi
    fi
done
}

doFiles "." "$vext"
