# Debian11_GNOME.sh

>Current Version: 0.0.1

## 使用方法

适用：Debian 11 GNOME

两种途径：

一、**可以**手动新建管理员用户(或者将当前用户加入管理员列表)

- 新建管理员账户(推荐，这样可以有两个账户，一个普通账户，一个管理员账户)：

- 将当前用户加入sudo用户中：`su root`后使用`visudo`修改`/etc/sudoers`文件内容。

  ```
  # 无需密码：
  【普通用户的用户名】	ALL=(ALL)NOPASSWD:ALL
  # 需要密码：
  【普通用户的用户名】	ALL=(ALL:ALL)	ALL
  ```

然后在管理员身份下使用`sudo`运行此脚本按提示操作。

二、**也可以**直接运行此脚本，脚本会自动将当前用户添加进`sudo`组。

## 脚本内容

> 检查点中如无**必选**两个字，默认为可选、可配置项目。

- 运行环境检查
  - 首先检查用户是否在`sudo`组中且免密码。如果没有，临时添加`$USER ALL=(ALL)NOPASSWD:ALL`进`/etc/sudoers`文件中(运行结束或者Ctrl+c中断会自动移除)。
  - 检查是否时GNOME桌面，不是则警告、退出。
- 检查点一
  - 临时成为免密`sudoer`(必选)。
  - 添加用户到`sudo`组。
  - 设置用户`sudo`免密码。
  - 默认源安装`apt-transport-https`、`ca-certificates`。
  - 更新源、更新系统。
- 检查点二
  - 替换vim-tiny为vim-full
  - 替换Bash为Zsh
  - 替换默认的ZSHRC文件
  - 替换root用户的SHELL配置
  - 添加/usr/sbin到用户的SHELL环境变量
- 检查点三
  - ​	

## 更新日志

- 2021年9月26日——0.0.1
  - 从Debian 10迁移到Debian 11

# Debian10_GNOME.sh(2021年7月停止维护)

>Last Version: v3.3.7

## 使用方法

适用：Debian 10 GNOME

首先新建管理员用户(或者将当前用户加入管理员列表)

- 新建管理员账户(推荐，这样可以有两个账户，一个普通账户，一个管理员账户)：

- 将当前用户加入sudo用户中：`su root`后使用`visudo`修改`/etc/sudoers`文件内容。

  ```
  # 无需密码：
  【普通用户的用户名】	ALL=(ALL)NOPASSWD:ALL
  # 需要密码：
  【普通用户的用户名】	ALL=(ALL:ALL)	ALL
  ```

然后在管理员身份下使用`sudo`运行此脚本按提示操作。

## 脚本内容

- 检查点一：读取用户输入的用户名，如果是root，则退出。如果是Bash，询问是否更改为Zsh。询问是否替换sh配置文件。
- 检查点二：更新apt镜像
- 检查点三：更新软件索引、系统
- 检查点四：生成nautilus右击菜单
- 检查点五：安装vim-full，卸载vim-tiny；
- 检查点六：拷贝用户bashrc或者zshrc文件到root用户的
- 检查点七：添加/usr/sbin到环境变量
- 检查点八：从apt仓库拉取常用软件
- 检查点九：添加Anydesk、teamviewer、sublime、docker-ce、virtualbox仓库
- 检查点十：安装docker-ce和VirtualBox并添加当前用户到docker-ce和vbox
- 检查点十一：配置networkmanager
- 检查点十二：配置grub网卡默认命名
- 检查点十三：配置apache2
- 检查点十四：配置pypi源为清华镜像并更新系统。
- 检查点十五：安装hexo、cnpm
- 检查点十六：从互联网安装第三方应用（网易云音乐、WPS等）
- 检查点十七：从第三方apt仓库安装anydesk、teamviewer和sublime
- 检查点十八：从互联网安装第三方应用[ Skype ]
- 检查点十九：用火狐浏览器(Firefox)打开推荐的仓库和第三方软件官网
- 检查点二十：systemctl禁用部分服务
- 检查点二十一：自定义自己的服务（运行一个shell脚本）
- 收尾工作：设置文件所属、用户目录所属

## 更新日志

- v 3.3.7
  - 修复VirtualBox安装步骤选择参数无效的Bug

- v 3.3.6
  - 第一步新增zshrc配置步骤

- v 3.3.5
  - 第一步询问是否更改Bash为Zsh。
  - 优化了脚本结构。
  - 合并了第二十二步和第十步

- v3.3.4
  - 第八步将apt-listchanges和apt-listbugs移入选择性安装的软件中，解决安装过程频繁询问。

- v3.3.3
  - 第八步增加了例外软件的选择性安装。

- v3.2.2
  - 第一步修改apt源，可选择3个版本：Stable testing sid
  - 第八步修改了Vbox源的可选择性。