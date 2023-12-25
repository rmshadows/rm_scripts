#!/bin/bash 
## 搜索word文档
## Manual 搜索词 可以不启用，注释掉
response="加强组织领导"

cmdToCheck="catdoc"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: "$cmdToCheck" is not installed." >&2
    sudo apt install "$cmdToCheck"
fi
cmdToCheck="docx2txt"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
    echo "Error: "$cmdToCheck" is not installed." >&2
    sudo apt install "$cmdToCheck"
fi

   echo -e "\n 
Welcome to scandocs. This will search .doc AND .docx files in this directory for a given string. \n 
Type in the text string you want to find... \n" 
   if [ "$response" == "" ];then
      read response 
   fi
   find . -name "*.doc" |  
       while read i; do catdoc "$i" | grep --color=auto -iH --label="$i" "$response" ; done 2>>searchDocxerr.err
   find . -name "*.docx" |  
       while read i; do docx2txt < "$i" | grep --color=auto -iH --label="$i" "$response" ; done 2>>searchDocx2txt.err

