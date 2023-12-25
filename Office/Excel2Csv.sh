#!/bin/bash
# 将目录下的Excel表格转换为CSV文件
fexts=("xls" "xlsx" "XLS" "XLSX")
outputf="./Excel2CSV"

cmdToCheck="libreoffice"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: "$cmdToCheck" is not installed." >&2
    sudo apt-get install libreoffice
    sudo apt-get install libreoffice-java-common
fi

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
for ele in ${flist[@]}; do
    echo "Convert $ele"
    libreoffice --headless --infilter=CSV:44,34,76,1 --convert-to csv --outdir "$outputf" "$ele"
    if [ "$?" -ne 0 ]; then
        echo "$ele" >>Excel2CsvErr.txt
    fi
done


