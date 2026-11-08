# 生成出的 once-*.sh 怎样找到 VeraCrypt，从而调用里面的挂载脚本。
# 这是相对 once-*.sh 自己所在目录的路径，不是相对本文件。
# 脚本放在 Once 目录里、VeraCrypt 在旁边：../VeraCrypt
# 脚本直接放进 VeraCrypt 目录：.
# veraRel="../VeraCrypt"
veraRel="./VeraCrypt"

# 生成默认。命令行 --days / --digits / --manual 可以覆盖。
expireDays=15
pinDigits=16
# 1=自动生成纯数字 PIN，0=自动生成字母数字（Crockford）
pinNumeric=1

# 对时网址，一行一家。不是 NTP，读的是 HTTPS 响应里的日期。
# 慢的就删掉或改成别的。至少留两家。前面加 # 就是停用。
timeUrl=https://www.baidu.com/
timeUrl=https://www.qq.com/
timeUrl=https://www.aliyun.com/
timeUrl=https://www.bing.com/
# timeUrl=https://www.cloudflare.com/
# 每一家最多等几秒，全部最多等几秒。两家已经对上就提前结束。
timeTimeout=3
timeWait=4
# 本机时钟已过期时是否粉碎。1=粉碎（默认，没网也能过期自毁），0=只停止不删（防本机被拨快误删）。
# 网络已过期一定会粉碎。
localExpireDestroy=1
# 本机已过期且上面为 1 时，是否优先于网络、立刻粉碎（不等对时）。1=立刻删（默认），0=先对网络再决定。
localExpirePriority=1
