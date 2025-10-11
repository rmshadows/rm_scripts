# README

1. alternatives_manager.sh——交互式alternatives配置

2. check_pkgs_in_apt.sh——检查仓库中有无某软件包（虚拟软件包检测不出）

3. checkZerotier.sh —— 检查 Zerotier 状态

4. clamav_watchdog.sh——自动使用 ClamAV 扫描新文件，发现病毒则移动至 quarantine 隔离目录。

5. clean_trace.sh —— 清理足迹

6. collect_binary_with_deps.sh——收集可执行文件及其依赖库，打包成便于迁移和离线运行的目录

7. create_self-signed-cert.sh —— 生成 SSL 证书 示例：`./create_self-signed-cert.sh --ssl-domain=www.meet.nyj --ssl-trusted-ip=192.168.1.93 --ssl-size=2048 --ssl-date=3650`

8. delete_empty_dirs.sh —— 删除空文件夹

9. Docker-WeChat.sh —— 安装 Docker 微信（不再维护）

10. download_deb_with_deps.sh —— 下载离线安装包

11. downloadAptPackage.sh —— 下载 APT 包及其依赖

12. fix_long_filenames.sh —— 修复 NTFS 长文件名

13. generateSSLCert.sh —— 生成自签名 SSL 证书（仅 Key+PEM）

14. insert_hosts.sh —— 在 Host 添加某个主机解析

15. interactive-time-sync.sh——同步时间

16. kill_typora_license —— 关闭Typora未激活的弹窗

17. monitor_and_kill.sh —— 每隔一段时间杀死某进程

18. monitorFileAccess.sh —— 监视文件访问（很难用）

19. ssd_smart_check.sh —— 固态硬盘 smart 数据

20. trace_file_access.sh —— 监视程序启动过程（不好用）

21. watchDirectoryChange.sh —— 监视目录文件更改

