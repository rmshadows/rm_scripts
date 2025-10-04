# rm_scripts
## 正文

我自己写的一些脚本以及网上收集的、网友贡献的脚本。注意看README文件，有一部分脚本已经不再维护！

这里主要是系统搭建脚本，其他脚本见杂货铺:

[Github](https://github.com/rmshadows/whatarethese)  |  [Gitee](https://gitee.com/rmshadows/shenmedongxi)

## 脚本文件夹

- Debian_GNOME_Init——用于部署新的Debian系统
  - *Debian10_GNOME.sh——Debian 10(Buster) GNOME配置脚本(停止更新，最终版本v3.3.7)*
  - Debian11_GNOME.sh——Debian 11(Bullseye) GNOME配置脚本
- Debian_Server_Init——用于初始化新的服务器
  - *Debian10_Server_Init.sh——Debian 10服务器部署(停止更新，最终版本v0.0.4)*
  - Debian11_Server_Init.sh——Debian 11服务器部署(停止更新)
  - Debian12_Server_Init.sh——Debian 12服务器部署
  - rsshub_docker.sh——简单粗暴删除RSSHUB后重装启动
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

