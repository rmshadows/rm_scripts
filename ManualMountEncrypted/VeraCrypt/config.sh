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

# 密码留空则运行时询问。写在这里会进入进程列表，交互输入更安全。
keyPass=""
# PIM，0 表示默认迭代次数
pim=0
# 密钥文件。留空表示不使用，也不会再交互询问密钥文件。
keyFile=""

# 0: VeraCrypt 卷    1: 旧 TrueCrypt 卷
# VeraCrypt 1.26 起已移除 TrueCrypt 兼容，打开后若当前版本不支持会直接退出。
truecryptMode=0
# uid/gid 挂载选项：auto（默认）| 1（强制开）| 0（强制关）
# auto 会先解开加密层探测卷内文件系统：NTFS/FAT/exFAT 自动加 uid/gid，ext4 等不加。
useOwnerOptions=auto
# 1: NTFS 走内核驱动（ntfs3），避免 ntfs-3g 在休眠时卡住。
kernelNtfs=0
# 1: 只读挂载
readOnly=0

# 留空则：优先系统 veracrypt，找不到再尝试 apt install。
# 系统自带版本有问题，或要用离线打包的二进制时再指定，例如：
# VERACRYPT_CUSTOM="./Debian12-amd64/veracrypt"
# VERACRYPT_CUSTOM="./UOS-arm64/veracrypt"
# VERACRYPT_CUSTOM="/usr/bin/veracrypt"
VERACRYPT_CUSTOM=""
