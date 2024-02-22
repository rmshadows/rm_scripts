# Debian11_Server_Init.sh

>Current Version: 0.0.2

## 使用方法

适用：Debian 12

首先自定义脚本与配置，然后以`root`用户运行(`sudo`也不行，必须`root`用户)。

注意事项：

默认使用root用户运行(禁止使用sudo)，如果未指定配置某用户(没有的用户会被新建)，则全部配置root用户。

## 脚本内容

- 检查点一：
  - 更改镜像（针对国内服务器）；
  - 默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release(必选)；
  - 配置unattended-upgrades
- 检查点二：
  - 安装sudo openssh-server zsh(必选)；
  - 设置所有用户使用zsh；
  - 新建用户(包括配置sudo、是否使用zshrc、sudo免密码)
- 检查点三：
  - 安装vim-full，卸载vim-tiny；
  - 添加/usr/sbin到环境变量；
    - 添加添加HOME目录文件夹（Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service）(必选)；
  - 安装bash-completion；
  - 安装zsh-autosuggestions
- 检查点四：
  - 自定义自己的服务（运行一个shell脚本）；
  - 设置主机名
  - 配置语言
  - 配置时区
  - 配置tty1自动登录
- 检查点五：
  - 从apt仓库拉取常用软件
  - 安装Python3
  - 安装Python虚拟环境（全局）
  - 安装Git
  - 安装OpenSSH
  - 安装nodejs
  - 安装npm
- 检查点六：
  - 安装、配置HTTP服务
- 检查点七：
  - 安装docker-ce
- 检查点八：
  - 安装ufw防火墙(默认开放22、80 、443)

## 更新日志

>dev: Not available yet.

- 2024.2.22——0.0.2
  - 从Debian 11迁移到Debian 12
  - 修复# 设置主机名环节

# Debian11_Server_Init.sh

>Current Version: 0.0.8

## 使用方法

适用：Debian 11

首先自定义脚本与配置，然后以`root`用户运行(`sudo`也不行，必须`root`用户)。

注意事项：

默认使用root用户运行(禁止使用sudo)，如果未指定配置某用户(没有的用户会被新建)，则全部配置root用户。

## 脚本内容

- 检查点一：
  - 更改镜像（针对国内服务器）；
  - 默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release(必选)；
  - 配置unattended-upgrades
- 检查点二：
  - 安装sudo openssh-server zsh(必选)；
  - 设置所有用户使用zsh；
  - 新建用户(包括配置sudo、是否使用zshrc、sudo免密码)
- 检查点三：
  - 安装vim-full，卸载vim-tiny；
  - 添加/usr/sbin到环境变量；
    - 添加添加HOME目录文件夹（Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service）(必选)；
  - 安装bash-completion；
  - 安装zsh-autosuggestions
- 检查点四：
  - 自定义自己的服务（运行一个shell脚本）；
  - 设置主机名
  - 配置语言
  - 配置时区
  - 配置tty1自动登录
- 检查点五：
  - 从apt仓库拉取常用软件
  - 安装Python3
  - 安装Git
  - 安装OpenSSH
  - 安装nodejs
  - 安装npm
- 检查点六：
  - 安装、配置HTTP服务
- 检查点七：
  - 安装docker-ce
- 检查点八：
  - 安装ufw防火墙(默认开放22、80 、443)

## 更新日志

>dev: Not available yet.

- 2023.02.10——0.1.0
  - 新增`linxfilesharing`
- 2023.02.06——0.0.9
  - 新增`php-fpm`等
- 2022.07.22——0.0.8
  - 修复了直播文件夹中的小问题
- 2022.04.14——0.0.7
  - 修复了语言配置、等问题(0.0.6)
  -  去除了GRUB网卡命名规则(0.0.6)
  -  修复了`nginx`配置问题(0.0.7)
  -  修复了`HOME_INDEX`变量的赋值问题(0.0.7)
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

# Install Applications

**注意**：

1. 要求**非root**用户身份运行(**run as non-root user**)
2. 需要使用`sudo` 权限(**sudo required**)
3. 需要 **有人职守** 执行！
4. 防火墙需自行开启(除非另有说明)！

## FRP

>内网穿透

文件:`frp.sh`

## Hackchat

>匿名聊天

文件：`hackchat.sh`

- **需要交互**，需要输入管理员账户及密码，需要Websocket端口。Web界面默认运行在3000端口（支持更改）
- 需要自行打开UFW

## Jitsi-Meeting

>在线会议

### Debian

文件：`jitsi-meeting_global.sh`

注意：

- 此脚本是全局安装
- **需要交互**！

### Docker

文件：`docker_jitsi-meeting.sh`  | [文档](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker)

注意：

- 需要Docker
- 需要Docker-compose
- 需要手动配置防火墙、反向代理、域名参数等内容

## Linx-File-Sharing

> 文件共享

文件：`linxfilesharing.sh`

注意：

- 需要安装git、golang、acl
- 主页自定义请修改`templates`

## Matterbridge

>消息桥梁

文件：`matterbridge.sh`

注意：

- 需要自行配置nginx、媒体服务器等
- 需要自行配置matterbridge [仓库](https://github.com/42wim/matterbridge) [手册](https://github.com/42wim/matterbridge/wiki)

## PHP-FPM

> 文件浏览、共享

文件：`php-fpm.sh`

注意：

- 仅用于第一次安装，如非首次安装，请自行修改监听端口号`/etc/php/7.4/fpm/pool.d/www.conf`（添加listen = 9000，记得注释其他listen）

## RSS Hub

>RSS服务

文件：`docker_rsshub.sh`

## Other

- `generate_ssl_cert.sh`——生成SSL证书
- `AboutV2ray/x-ui-install.sh`——搭建`x-ui`和`vmess`

---

```
sudo ln -s /etc/nginx/sites-available/xx /etc/nginx/sites-enabled/xx
```

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