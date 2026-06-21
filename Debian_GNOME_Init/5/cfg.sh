# 设置字体源文件夹 Preset=FONTS
SET_FONTS_SOURCE="FONTS"

# RIME 词库（均为离线，部署时不使用 git）
# SET_IMPORT_RIME_DICT=0 → rime_base_config/  基础明月拼音（fcitx4/fcitx5/ibus 通用）
# SET_IMPORT_RIME_DICT=1 → RIME_FROST/         白霜拼音（需 fcitx5，先用 tools/sync_rime_frost_bundle.sh 准备）
SET_RIME_FROST_DIR=RIME_FROST

# 旧版明月扩充词库（瑾昀词库，可选保留，不再作为部署选项）
# SET_RIME_DICT_DIR=RIME_DICT
