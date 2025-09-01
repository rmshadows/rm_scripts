# README

1. checkZerotier.sh —— 检查 Zerotier 状态

2. clamav_watchdog.sh——自动使用 ClamAV 扫描新文件，发现病毒则移动至 quarantine 隔离目录。

3. clean_trace.sh —— 清理足迹

4. collect_binary_with_deps.sh——收集可执行文件及其依赖库，打包成便于迁移和离线运行的目录

5. create_self-signed-cert.sh —— 生成 SSL 证书 示例：`./create_self-signed-cert.sh --ssl-domain=www.meet.nyj --ssl-trusted-ip=192.168.1.93 --ssl-size=2048 --ssl-date=3650`

6. delete_empty_dirs.sh —— 删除空文件夹

7. Docker-WeChat.sh —— 安装 Docker 微信（不再维护）

8. download_deb_with_deps.sh —— 下载离线安装包

9. downloadAptPackage.sh —— 下载 APT 包及其依赖

10. fix_long_filenames.sh —— 修复 NTFS 长文件名

11. generateSSLCert.sh —— 生成自签名 SSL 证书（仅 Key+PEM）

12. insert_hosts.sh —— 在 Host 添加某个主机解析

13. kill_typora_license —— 关闭Typora未激活的弹窗

14. monitor_and_kill.sh —— 每隔一段时间杀死某进程

15. monitorFileAccess.sh —— 监视文件访问（很难用）

16. ssd_smart_check.sh —— 固态硬盘 smart 数据

17. trace_file_access.sh —— 监视程序启动过程（不好用）

18. watchDirectoryChange.sh —— 监视目录文件更改

