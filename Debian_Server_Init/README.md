# Debian11_Server_Init.sh

>Current Version: 0.0.1

## 使用方法

适用：Debian 11

首先自定义脚本与配置，然后以`root`用户运行(`sudo`也不行，必须`root`用户)。

注意事项：

默认使用root用户运行(禁止使用sudo)，如果未指定配置某用户(没有的用户会被新建)，则全部配置root用户。

## 脚本内容

- 检查点一：更改镜像（针对国内服务器）；默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release(必选)；配置unattended-upgrades
- 检查点二：安装sudo openssh-server zsh(必选)；设置所有用户使用zsh；新建用户(包括配置sudo、是否使用zshrc、sudo免密码)
- 检查点三：安装vim-full，卸载vim-tiny；添加/usr/sbin到环境变量；添加添加HOME目录文件夹（Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service）；安装bash-completion；安装zsh-autosuggestions
- 检查点四：自定义自己的服务（运行一个shell脚本）；
- 检查点五：从apt仓库拉取常用软件
- 

## 更新日志

- 2021年9月28日——0.0.1
  - 从Debian 10迁移到Debian 11，采用预配置方式。

# Debian10_Server_Init.sh(2021年7月停止维护)

>Last Version: v0.0.4

## 使用方法

适用：Debian 10

## 脚本内容

- 检查点一：更改镜像（针对国内服务器）
- 检查点二：安装SSH zsh sudo更新系统、新建用户
- 检查点三：添加HOME目录文件夹
- 检查点四：安装vim-full，卸载vim-tiny；
- 检查点五：拷贝用户bashrc或者zshrc文件到root用户的
- 检查点六：添加/usr/sbin到环境变量
- 检查点七：自定义自己的服务（运行一个shell脚本）
- 检查点八：从apt仓库拉取常用软件
- 检查点九：设置主机名、语言支持
- 检查点十：配置自动pi登录
- 检查点十一：配置grub网卡默认命名
- 检查点十二：安装docker-ce
- 检查点十三：配置apache2
- 检查点十四：配置nginx
- 检查点十五：配置Python支持和py源为清华镜像
- 检查点十六：配置nodejs npm 自选是否安装hexo
- 检查点十七：配置SSH
- 检查点十八：安装ufw
- 最后一步：设置文件夹所属

## 更新日志

- v0.0.3
  - nginx 新增密码访问控制

- v0.0.3
  - 修复了apache配置
- v0.0.2
  - 修正了SSH配置
  - 修复了nginx配置的意外错误
- v0.0.1
  - 首次发布