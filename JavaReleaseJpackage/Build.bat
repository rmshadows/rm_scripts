@echo off
REM 输出文件夹名称 (Textsend-4.0.5)
SET OUTPUT_NAME=""
REM 可执行的Jar文件名称(如：Textsend-4.0.5.jar)
SET JAR_FILENAME=".jar"
REM 主类（如：application.TextSendMain）
SET MAIN_CLASS=""
REM 图标
SET ICON=""

REM RunnableJarFile文件夹中要放入所有要打包的执行相关资源
jpackage --input .\RunnableJarFile --name "%OUTPUT_NAME%" --main-jar "%JAR_FILENAME%" --main-class "%MAIN_CLASS%" --type app-image --icon "%ICON%"

