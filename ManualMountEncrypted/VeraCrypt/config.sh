# VeraCrypt 挂载参数。mountV.sh、rmount.sh、urmount.sh 都会读取本文件。
#
# 查看分区 PARTUUID：
#   lsblk -o NAME,PARTUUID,SIZE,FSTYPE,TYPE
#
# 卷来源  0:分区（按 PARTUUID）  1:容器文件
volMode=0
# 分区的 PARTUUID。volMode=0 时必填。
puid="8a865e76-96e7-409b-b78e-682c0954779a"
# 容器文件路径。volMode=1 时必填，建议写绝对路径。
containerPath=""

# 可访问的挂载点。默认放在 /media/用户名/ 下，Nautilus 侧栏才容易出现。
# 别跟 GUI 默认的 /media/veracrypt1、veracrypt2… 撞车。
_MEDIA_USER="${SUDO_USER:-${USER:-$(id -un)}}"
# fixed=固定名 | label=必须用卷标 | label-or-fixed=有卷标用卷标，否则回退
mountNameMode=label-or-fixed
# 固定名 / 无卷标时的回退名
mountName="rveracrypt"
# 实际路径由脚本在解密后写入 readMount；也可手动写死绝对路径覆盖：
# readMount="/media/${_MEDIA_USER}/rveracrypt"
readMount="/media/${_MEDIA_USER}/${mountName}"

# 密码留空则运行时询问，只问一次。写在这里会进入进程列表，交互输入更安全。
keyPass=""
# 使用上面的密码时，超过这么多秒还没解开就停止。
# 有的 veracrypt（银河麒麟上遇到过）密码错误会一直等，只能 Ctrl+C。
# 0 表示不限制。正确密码一般几秒；PIM 很大时再加大。
decryptTimeout=60
# PIM，0 表示默认迭代次数
pim=0
# 密钥文件。留空表示不使用，也不会再交互询问密钥文件。
keyFile=""

# 0: VeraCrypt 卷    1: 旧 TrueCrypt 卷
# VeraCrypt 1.26 起已移除 TrueCrypt 兼容，打开后若当前版本不支持会直接退出。
truecryptMode=0
# uid/gid 挂载选项：auto（默认）| 1（强制开）| 0（强制关）
# auto：NTFS/FAT/exFAT 加 uid/gid；ext4 等原生 Linux 文件系统不加（它们认卷内属主）。
useOwnerOptions=auto
# ext4/xfs 等：卷根 uid 和当前用户不同时怎么处理。
# ask         挂载时询问（默认）
# map         不询问。内核 5.12+ 且 stat 确认属主变了才用 idmap，否则 bindfs。不改卷内属主。
#             idmap 是内核功能，没有单独的离线包。低于 5.12 只能走 bindfs。
# bindfs      不询问，直接 bindfs（给 Debian 10 / 内核 4.19 用）
# chown-root  不询问，只把卷根 chown 给当前用户（会写入卷，子目录可能仍不可写）
# skip        不询问，按卷内权限挂着
ownerMismatch=ask
# 要映射的是磁盘上的 uid/gid，不是映射之后希望看到的号。
# 留空：自动取卷里一层子项出现最多的非 0 uid（1000、1002 或其他都行）。
# 自动认错时再写数字，例如卷是在 uid=1002 的机器上做的：volumeUid=1002
volumeUid=
volumeGid=
# 1: NTFS 走内核驱动（ntfs3），避免 ntfs-3g 在休眠时卡住。
kernelNtfs=0
# 1: 只读挂载
readOnly=0

# 留空则：优先系统 veracrypt；apt 源里有包才安装。
# Debian 官方源通常没有 veracrypt。找不到时脚本会问要不要改用 tcplay。
# 系统自带版本有问题，或要用离线打包的二进制时再指定，例如：
# VERACRYPT_CUSTOM="./Debian12-amd64/veracrypt"
# VERACRYPT_CUSTOM="./UOS-arm64/veracrypt"
# VERACRYPT_CUSTOM="/usr/bin/veracrypt"
VERACRYPT_CUSTOM=""
# 离线 bindfs。留空则用系统里的 bindfs。
# 没网、apt 装不了时，把对应架构的 bindfs 放进来再写路径，例如：
# BINDFS_CUSTOM="./Kylin_V10_SP1_arm64/bindfs"
# 可在有网的机器上用 Other/apt/collect_binary_with_deps.sh 打包。
BINDFS_CUSTOM=""
# BINDFS_CUSTOM="./Kylin_V10_SP1_arm64/bindfs"
# 系统没有 bindfs 时要不要 apt：
# ask  询问，直接回车是不装（没网的机器用这个）
# 1    直接 apt install（最多等 aptTimeout 秒，避免没网一直卡着）
# 0    从不 apt。没有 bindfs 就按卷内权限挂上，可以读，写入可能不行。
allowAptInstall=ask
aptTimeout=90
