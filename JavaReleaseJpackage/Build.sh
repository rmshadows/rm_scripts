#!/bin/bash
# 输出文件夹名称 (Textsend-4.0.5)
OUTPUT_NAME=""
# 可执行的Jar文件名称(如：Textsend-4.0.5.jar)
JAR_FILENAME=".jar"
# 主类（如：application.TextSendMain）
MAIN_CLASS=""
# 图标
ICON=""

# RunnableJarFile文件夹中要放入所有要打包的执行相关资源
jpackage --input ./RunnableJarFile --name "$OUTPUT_NAME" --main-jar "$JAR_FILENAME" --main-class "$MAIN_CLASS" --type app-image --icon "$ICON"

