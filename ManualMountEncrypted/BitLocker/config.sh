# BitLocker 挂载参数。mountB.sh、rmount.sh、urmount.sh 都会读取本文件。
#
# 银河麒麟系统关闭执行控制功能状态：
# sudo setstatus -f exectl off
# setstatus -p softmode
# 开机自动挂载需要修改 fstab（修改前记得备份）：
# <partition> /media/bitlocker fuse.dislocker user-password=<password>,nofail 0 0
# /media/bitlocker/dislocker-file /media/bitlockermount auto nofail 0 0
#
# 查看分区 PARTUUID：
#   lsblk -o NAME,PARTUUID,SIZE,FSTYPE,TYPE

# BitLocker 加密分区的 PARTUUID
puid="4463e4a8-296b-4db9-aa4d-7c83c762665e"
# /dev/sdb4: TYPE="BitLocker" PARTUUID="4463e4a8-296b-4db9-aa4d-7c83c762665e"

# dislocker 解密后的挂载点（中间层，一般不直接浏览）
dislockMount="/home/bitlocker"
# 可访问的挂载点。默认放在 /media/用户名/ 下，Nautilus 侧栏才容易出现。
_MEDIA_USER="${SUDO_USER:-${USER:-$(id -un)}}"
# fixed=固定名 | label=必须用卷标 | label-or-fixed=有卷标用卷标，否则回退
mountNameMode=label-or-fixed
# 固定名 / 无卷标时的回退名
mountName="bitlockermount"
# 实际路径由脚本在解密后写入 readMount；也可手动写死绝对路径覆盖：
# readMount="/media/${_MEDIA_USER}/bitlockermount"
readMount="/media/${_MEDIA_USER}/${mountName}"

# 解密方式  0:密码  1:恢复密钥
keyMode=0
# 没有密码就保持注释。写在这里会进入进程列表，交互输入更安全。
# keyPass=""

# 留空则使用系统 dislocker。系统自带版本有问题时再指定，例如：
# DISLOCKER_CUSTOM="./UOS-arm64/dislocker"
# DISLOCKER_CUSTOM="./Debian12-amd64/dislocker"
# DISLOCKER_CUSTOM="./KylinV10sp1-arm64/dislocker"
DISLOCKER_CUSTOM=""
