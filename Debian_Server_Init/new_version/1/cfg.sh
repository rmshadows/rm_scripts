:<<检查点一
配置自定义APT源
检查点一
# 你的更新源 Preset=""
SET_YOUR_APT_SOURCE="# 中科大源 from:https://mirrors.ustc.edu.cn/repogen/
# 帮助：https://mirrors.ustc.edu.cn/help/debian.html
# Tips: Remember to install package <apt-transport-https>
deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
# deb-src https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware

deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
# deb-src https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware

deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
# deb-src https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware

deb https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
# deb-src https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
"