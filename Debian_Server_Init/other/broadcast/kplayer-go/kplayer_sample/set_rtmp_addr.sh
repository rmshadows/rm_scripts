#!/bin/bash
# 此脚本用于更新、生成直播配置
source "GlobalVariables.sh"
source "Lib.sh"
source "kconfig.sh"

replace_placeholders_with_values_support_multiline "config.json.src"

