# rm_scripts
我自己写的一些脚本以及网上收集的、网友贡献的脚本。注意看README文件，有一部分脚本已经不再维护！

这里主要是系统搭建脚本，其他脚本见杂货铺:

[Github](https://github.com/rmshadows/whatarethese)  |  [Gitee](https://gitee.com/rmshadows/shenmedongxi) (几乎停更)

## 一键拉取（无需 git）

将下面 URL 中的 `latest` 换成具体 tag（例如 `download/v0.1.0/`）也可。

### 1. 仅拉取（不解压后不运行）

**Debian GNOME Init**

```bash
curl -fsSL -o Debian_GNOME_Init.tar.gz \
  https://github.com/rmshadows/rm_scripts/releases/latest/download/Debian_GNOME_Init.tar.gz
tar -xzf Debian_GNOME_Init.tar.gz
# 得到目录 Debian_GNOME_Init/ ，自行改 Config.sh / GlobalVariables.sh 后再运行
```

**Debian Server Init**

```bash
curl -fsSL -o Debian_Server_Init.tar.gz \
  https://github.com/rmshadows/rm_scripts/releases/latest/download/Debian_Server_Init.tar.gz
tar -xzf Debian_Server_Init.tar.gz
# 得到目录 Debian_Server_Init/ ，自行改 Config.sh 后再运行
```

可选校验：

```bash
curl -fsSL -O https://github.com/rmshadows/rm_scripts/releases/latest/download/SHA256SUMS
sha256sum -c SHA256SUMS
```

### 2. 拉取 + 运行（命令行传入必要参数）

参数通过**环境变量**覆盖配置（勿把密码写进可分享的截图/日志）。

**GNOME**（普通用户跑；若还不是免密 sudo，请提供 `ROOT_PASSWD`）

```bash
curl -fsSL \
  https://github.com/rmshadows/rm_scripts/releases/latest/download/Debian_GNOME_Init.tar.gz \
  | tar -xz
cd Debian_GNOME_Init
ROOT_PASSWD='你的root密码' bash Debian_13_GNOME_Setup.sh
# 已是免密 sudo 时可直接：
# bash Debian_13_GNOME_Setup.sh
```

**Server**（建议 root 或已有 sudo；创建用户时请改用户名/密码）

```bash
curl -fsSL \
  https://github.com/rmshadows/rm_scripts/releases/latest/download/Debian_Server_Init.tar.gz \
  | tar -xz
cd Debian_Server_Init
SET_USER_NAME='admin' SET_USER_PASSWD='你的用户密码' bash Debian_13_Server_Setup.sh
# 可选：SET_HOST_NAME='myserver' SET_USER=1
# 若 SET_USER=0 则以 root 继续，无需 SET_USER_NAME / SET_USER_PASSWD
```

更稳妥做法：先「仅拉取」，打开 `Config.sh` 确认后再跑入口脚本。

## 脚本文件夹

- **systweak**——已有系统上的单功能开关（拷哪个用哪个，支持 `--undo`）。详见 [`systweak/README.md`](systweak/README.md)
- Debian_GNOME_Init——用于部署新的Debian系统
  - *Debian10_GNOME.sh——Debian 10(Buster) GNOME配置脚本(停止更新，最终版本v3.3.7)*
  - Debian11_GNOME.sh——Debian 11(Bullseye) GNOME配置脚本
- Debian_Server_Init——用于初始化新的服务器
  - *Debian10_Server_Init.sh——Debian 10服务器部署(停止更新，最终版本v0.0.4)*
  - Debian11_Server_Init.sh——Debian 11服务器部署(停止更新)
  - Debian12_Server_Init.sh——Debian 12服务器部署
  - rsshub_docker.sh——简单粗暴删除RSSHUB后重装启动
- *forKylinV10SP1*——旧版系统微调（归档，请改用 systweak）
- FFmpeg——命令行调用FFmpeg工具处理视频
  - 详情见文件夹README
- fmgr文件传输——Nginx+Php fpm的文件共享（可上传），用于Linux主机临时局域网共享文件（直接丢进nginx根目录）
- JavaReleaseJpackage——用来的包Java程序
- Office——Office相关的脚本
- RAR——RAR相关脚本
  - 详情见文件夹README
- Windows——一些Windows的脚本(基本都是没用的东西)
  - OpenApplicationDownloadPages.bat——打开软件下载页面

## 未分类脚本

- *Docker-WeChat.sh——[Docker微信](https://github.com/huan/docker-wechat)(最后更新时间：2021.8)*

## 大事件记录

>各脚本更新日志请分别查看文件夹中的README

- 2026年8月29日——0.1.1
  - Debian_GNOME_Init：续跑、TTY 交互、精简白霜离线包入库、fcitx5 登录自启

- 2026年7月31日——0.1.0
  - 新增 systweak（单脚本系统微调，可 --undo）；forKylinV10SP1 标为归档
  - 主 README 增加 Release 一键拉取说明；Server Init 可选 acme.sh

- 2026年4月27日——0.0.9
  - Office更新了PDF模块
  
- 2026年1月31日——0.0.8
  - Debian_Server_Init 应用安装：docker_rsshub、isso 增加 Nginx 反代片段与 setupNginx 脚本，安装后自动写入 `/etc/nginx/snippets/`，用户只需在 site 内加一行 include
  - application_install-sample 作为应用安装模板：新增 myapp-snippet.conf、setupNginxForMyapp.sh、README.md，主脚本与 Nginx 片段流程与现有应用（artalk、frp、rsshub、isso 等）一致

- 2026年1月11日——0.0.7
  - 更新了Office套件

- 2025年10月4日
  - 迁移完毕（但未测试）

- 2025年9月30日——0.0.6
  - 0.0.6 准备从Debian12升级Debian13

- 2025年2月12日
  - 重构了Debian_GNOME_Init和Debian_Server_Init

- 2024年7月6日
  - 更新了Office模块

- 2024年4月17日
  - 添加了Office模块

- 2024年2月22日
  - 更新脚本：Debian 11 -> Debian 12

- 2023年10月10日
  - 新增`fmgr`文件共享

- 2023年9月13日
  - `Debian 12`中raspi-firmware可能导致系统升级失败，建议`sudo apt purge raspi-firmware`

- 2022年9月23日
  - 添加了FFmpeg、RAR辅助工具
- 2022年3月29日
  - 添加了一个简单粗暴的Docker RSSHub安装脚本(不建议直接运行，更建议作为备忘录看一看就好)
- 2022年3月11日
  - 更新了Debian 11 GNOME部署脚本0.0.7
- 2021年10月27日
  - 发布修复了BUG的Debian 11 GNOME部署脚本正式版0.0.5
  - 发布Debian 11桌面部署脚本正式版0.0.4
- 2021年9月28日
  - **停止对Debian 10 脚本的更新**
  - 开始Debian 11脚本的编写，采用**预配置的方式一键部署**
