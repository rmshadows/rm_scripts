#!/bin/bash
### 将当前目录下gbk编码的CSV转为utf8

fexts=("CSV" "csv")
outputf="./ConvertGBK2UTF8"

####
# Warning: failed to launch javaldx - java may not function correctly
# 解决：sudo apt-get install libreoffice-java-common // default-jre
# 返回gfr_list文件列表(递归)
function getFilesRecur() {
    unset $gfr_list
    for file in $(ls $1); do
        if [ -d $1"/"$file ]; then
            getFilesRecur $1"/"$file $2
        else
            if [[ "$file" == *"$2" ]]; then
                file="$1"/"$file"
                file_list=$file_list♨$file
            fi
        fi
    done
    OLD_IFS="$IFS"
    IFS="♨"
    gfr_list=($file_list)
    IFS="$OLD_IFS"
    gfr_list=(${gfr_list[@]})
}

for fext in ${fexts[@]}; do
    flist=()
    # echo "Getting ext: $fext"
    getFilesRecur "." "$fext"
    flist=("${flist[@]}" "${gfr_list[@]}")
done
echo "共搜索到 ${#flist[*]} 个 Excel 文件"
for ele in ${flist[@]}; do
    echo "$ele"
done
mkdir -p "$outputf"

function getFileEncoding() {
    getFileEncoding=""
    # text/plain; charset=utf-8
    tfo=$(file -bi "$ele")
    OLD_IFS="$IFS"
    # 以“charset=”为分隔符
    IFS="="
    gotArr=($tfo)
    IFS="$OLD_IFS"
    getFileEncoding=${gotArr[1]}
}

for ele in ${flist[@]}; do
    # echo "Convert $ele"
    getFileEncoding "$ele"
    if [ "$getFileEncoding" != "utf-8" ]; then
        iconv -c -f GBK -t UTF-8 "$ele" -o "$outputf"/Cv-`basename "$ele"`
    else
        cp "$ele" "$outputf"/Kp-`basename "$ele"`
    fi
    if [ "$?" -ne 0 ]; then
        echo "$ele" >>gbk2utf8Err.txt
    fi
done
