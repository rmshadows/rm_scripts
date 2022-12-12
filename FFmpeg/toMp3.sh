#!/bin/bash
# 转换任意格式到mp3
 
# 需要处理的扩展名
vext=("flac" "wav" "ape")
convert2="mp3"

function doFiles(){
for file in `ls $1`
do
    if [ -d $1"/"$file ] 
    then
        echo "Msg: Directory "$1"/'$file' Passed."
    else
        if [[ "$file" == *"$2" ]];  
        then 
             fin=$1"/"$file
             fout=`echo "$fin" | sed s/"$2"/"$convert2"/g`
             echo "正在转换 $fin 到 $fout"
             echo ffmpeg -i "$fin" "$fout"
        fi
    fi
done
}

for i in "${vext[@]}";do
    echo 开出处理: $i
    doFiles "." "$i"
done
