# Debian12_Server.sh

>Current Version: 0.0.4

## 目录结构

- `0`、`1`等数字文件夹：0表示固定运行的脚本。1，2，3分别对应检查的一、二、三等，里面可能有子配置文件`cfg.sh`，同时还有一个`setup.sh`是运行的脚本。
- `Config.sh`是总配置，`Config_Templates`是配置模板。
- `Debian_12_Server_Setup.sh`，程序入口，主要运行的脚本。
- `GlobalVariables.sh`，全局变量，需要填写密码。
- `Lib.sh`脚本函数库。
- `Archive`是归档，从Debian10至今的存档。
- `other`时其他资源文件。

## 使用方法

适用：Debian 12 服务器

1. 检查是否符合脚本系统要求
2. 配置好`Config.sh`以及数字目录下的`cfg.sh`（如有必要）
3. 补充需要的资源(比如一些个人个性化配置)
4. 直接运行`Debian_12_Server_Setup.sh`脚本

## 脚本运行流程

### 初始化脚本

1. 加载变量

   ```
   # 加载全局变量
   source "GlobalVariables.sh"
   # 加载全局函数
   source "Lib.sh"
   # 加载配置(在全局变量之后)
   source "Config.sh"
   ```

2. 脚本预执行

   ```
   # 脚本开始
   source "0/0_start.sh"
   # 预执行
   source "0/init.sh"
   ```

- 加载配置文件和函数库等等
- 获取当前用户名
- 检查是否时GNOME桌面，不是则警告、退出。
- 与用户确认执行

### 检查点一

- 默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
- 更新源、更新系统。
- 配置unattended-upgrades

### 检查点二

- 新建用户
- 检查是否在sudo组中
- 是的话检查是否免密码
- 询问是否将当前用户加入sudo组, 是否sudo免密码（如果已经是sudoer且免密码则跳过）。
- 临时成为免密sudoer(必选)。
- 添加用户到sudo组。
- 设置用户sudo免密码。
- 卸载vim-tiny，安装vim-full
- 替换Bash为Zsh
- 添加/usr/sbin到环境变量
- 替换root用户shell配置文件
- 安装bash-completion
- 安装zsh-autosuggestions

### 检查点三

- 配置家目录文件夹
- 配置自定义的systemtl服务
- 配置启用NetworkManager、安装net-tools
- 配置GRUB网卡默认命名方式
- 配置主机名
- 配置语言支持
- 配置时区
- 设置TTY1自动登录

### 检查点四

- 从APT源安装常用软件

  ```
  - apt-transport-https——apt-transport-https
  - axel——axel_downloader
  - bash-completion——bash_completion
  - build-essential——build-essential
  - ca-certificates——ca-certificates
  - curl——curl
  - gnupg——GPG
  - htop——colored_top
  - httrack——website_clone
  - lsb-release——lsb-release
  - make——make
  - net-tools——ifconfig
  - screenfetch——display_system_info
  - sed——text_edit
  - silversearcher-ag——Ag_searcher
  - tcpdump——tcpdump
  - tree——ls_dir_as_tree
  - traceroute——trace_route
  - wget——wget
  - zhcon——tty_display_Chinese
  - zsh——zsh
  - zsh-autosuggestions——zsh_plugin
  - zsh-syntax-highlighting——zsh_plugin
  ```
  
- 脚本最后再安装的应用(滞后)

  ```
    - apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
    - apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
  ```

- 安装Python3

- 配置Python3源为清华大学镜像

- 配置Python3全局虚拟环境（Debian12中无法直接使用pip了）

- 安装配置Git(配置User Email)

- 安装配置SSH

- 安装配置npm(是否安装hexo)

- 安装docker-ce(滞后)

- 禁用第三方软件仓库更新(提升apt体验)(滞后)

### 检查点五

- 安装配置php-fpm
- 安装http服务器
- 配置Let's encrypt ＣｅｒｔＢｏｔ


### 检查点六

- 生成SSH　Ｋｅｙ
- 配置Shorewall防火墙(需要手动启用)

### 脚本收尾

- 滞后安装的软件
- 设置GRUB os-prober
- 设置用户目录所属

## 脚本内置函数（`Lib.sh`）

- `prompt ()`——控制台颜色输出

  ```
  -s:绿色——成功信息
  -x:绿色——日志：{}
  -e:红色——错误
  -w:黄色——警告
  -i:蓝色——一般信息
  -m:蓝色——信息：{}
  -k:蓝色&红色——格式化输出
  ```

- `onSigint`——程序中断处理方法,包含正常退出该执行的代码

- `onExit ()`——正常退出需要执行的

- `quitThis ()`——中途异常退出脚本要执行的 注意，检查点一后才能使用这个方法

- `doAsRoot ()`——以root身份运行

- `checkRootPasswd ()`——检查root密码是否正确

- `comfirm ()`——询问函数 Yes:1 No:2 其他:5。

  ```
  函数调用请使用：
  comfirm "\e[1;33m? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    yes
  elif [ $choice == 2 ];then
    prompt -i "——————————  下一项  ——————————"
  else
    prompt -e "ERROR:未知返回值!"
    exit 5
  fi
  ```

- `backupFile ()`——备份配置文件。先检查是否有bak结尾的备份文件，没有则创建，有则另外覆盖一个newbak文件。$1 :文件名

- `doApt ()`——执行apt命令 注意，检查点一后才能使用这个方法

- `addFolder ()`——新建文件夹。只能有一个参数$1

- `log_message_bg() `——后台记录日志。

- `log_message()`——记录日志(会显示再终端) log_message_bg "信息" "日志文件"

- `do_job()`——执行任务，执行脚本（日志+输出） do_job "setup.sh" "$ELOG_FILE"

- `replace_username()`——替换用户名为使用已定义的 $CURRENT_USER

- `### archive` ——旧函数存档

## 更新日志

>dev: Not available yet.

- 2025.01.18——0.1.1
  - 重构
- 2023.02.10——0.1.0
  - 新增`linxfilesharing`
- 2023.02.06——0.0.9
  - 新增`php-fpm`等
- 2022.07.22——0.0.8
  - 修复了直播文件夹中的小问题
- 2022.04.14——0.0.7
  - 修复了语言配置、等问题(0.0.6)
  - 去除了GRUB网卡命名规则(0.0.6)
  - 修复了`nginx`配置问题(0.0.7)
  - 修复了`HOME_INDEX`变量的赋值问题(0.0.7)
- 2022.04.13——0.0.5
  - 修复了部分bug
- 2022.04.11——0.0.4
  - 大体完成	
- 2022.04.10——0.0.3-dev
  - 更新了检查点六
- 2022.04.09——0.0.2-dev
  - 更新了检查点三
- 2021.09.28——0.0.1-dev
  - 从Debian 10迁移到Debian 11，采用预配置方式。

## 备忘录

```
# 无需密码：
【普通用户的用户名】	ALL=(ALL)NOPASSWD:ALL
# 需要密码：
【普通用户的用户名】	ALL=(ALL:ALL)	ALL
```

# 其他脚本——OtherScripts

- Cancel_All_Print_Task.sh——取消所有打印任务
- GNOME_Lock_Screen.sh——GNOME锁屏
