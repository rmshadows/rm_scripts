#!/bin/bash

: '
此脚本用于批量替换当前目录下指定扩展名文件中的字符串内容。
可以通过参数传入扩展名、待替换字符串和替换后的字符串；
如果未传参数，则使用脚本内置的默认值。

用法示例：
  ./replace.sh txt "旧字符串" "新字符串"
  或者直接执行 ./replace.sh 使用默认参数

注意：
  - 替换操作为就地替换，会直接修改文件。
  - 脚本不递归子目录，只处理当前目录文件。
  - 兼容字符串中包含 / 字符的情况。
'

# 默认参数（你可以在这里修改）
default_ext="txt"
default_old="被替换"
default_new="替换成"

# 如果传参了就用传参的，否则用默认值
ext="${1:-$default_ext}"
old="${2:-$default_old}"
new="${3:-$default_new}"

echo "开始替换: .$ext 文件中的 \"$old\" → \"$new\""

# 查找所有指定扩展名的文件
for file in *."$ext"; do
  [ -e "$file" ] || continue  # 如果没有匹配的文件就跳过
  echo "正在处理: $file"

  # 使用 sed 就地替换（支持 / 字符）
  sed -i "s/${old//\//\\/}/${new//\//\\/}/g" "$file"
done

echo "✅ 替换完成"
