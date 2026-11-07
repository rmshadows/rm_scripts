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
# 0: 只使用卷口令 / 恢复密钥    1: 两者和一次性码都能用（默认）
# 一次性码没有种子。../otp/enroll.sh 每次随机生成一串，只显示在屏幕上。
# 槽文件里是用这串码加密后的卷口令，不含码本身。
# 1 时：keyPass 有内容就直接用，不再询问。keyPass 留空则输入一次性码或卷口令均可。
# 用掉一条就只删那一条。生成 10 条就是 10 次。
# 数字 PIN：../otp/enroll.sh --pin 8   （8 到 20 位，生成在当前文件夹）
# 密钥文件：../otp/enroll.sh --keyfile
# 槽目录里的 key- 文件会直接用掉一个并删除，不用输入。卷头里的口令不会被改掉。
# keyMode 仍决定交给 dislocker 的是口令（-u）还是恢复密钥（-p）。
otpMode=1
# 槽目录。留空则每次询问（U 盘路径不固定时用这个）。
otpSlotDir=""

# 留空则使用系统 dislocker。系统自带版本有问题时再指定，例如：
# DISLOCKER_CUSTOM="./UOS-arm64/dislocker"
# DISLOCKER_CUSTOM="./Debian12-amd64/dislocker"
# DISLOCKER_CUSTOM="./KylinV10sp1-arm64/dislocker"
DISLOCKER_CUSTOM=""
