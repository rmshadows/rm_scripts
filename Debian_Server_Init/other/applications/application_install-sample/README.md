# 应用安装模板

本目录作为「应用安装」脚本的模板，新应用可复制本目录后按下面步骤改为自己的服务。

## 使用步骤

1. **复制并重命名**  
   将整目录复制一份，目录名改为你的应用名（如 `my_real_app`）。

2. **改 CONF**  
   在主安装脚本（如改名为 `my_real_app.sh`）中修改：
   - `SRV_NAME`：服务名（与 systemd 单元名、Services 子目录名一致）
   - `RUN_PORT`：应用监听端口
   - `SITE_LISTEN`：Nginx 独立站端口（不要用 80/443）
   - `SITE_NAME`：可空，空则从 ssl.conf / acme.conf 读

3. **改 Nginx 独立站与 setup 脚本的命名**  
   - 将 `myapp.conf.src` 重命名为 `你的服务名.conf.src`
   - 将 `setupNginxForMyapp.sh` 重命名为 `setupNginxFor你的服务名.sh`
   - 在上述两个文件内部，把 `myapp` 全部替换为你的服务名（含 `sites-available/myapp.conf`）
   - 在主安装脚本中，同步改对 `setupNginxForMyapp.sh` 的调用

4. **填写安装逻辑**  
   在「### 安装软件」段落中填写：依赖检查、下载、解压、编译、复制等；如需占位符，使用 `srv.service.src`、`reverse_proxy.txt.src` 中的 `【$变量名】` 与 `ServiceInit.sh` 的 `replace_placeholders_with_values`。

5. **启动/停止脚本**  
   按需编辑 `start.sh`、`stop.sh`，并确保 `srv.service.src` 中的 `ExecStart`/`ExecStop` 路径与 `$SRV_NAME` 一致。

完成后，在应用目录下执行主安装脚本即可完成安装、服务注册，并写入 `/etc/nginx/sites-available/你的服务名.conf`（默认不启用）。证书好了之后 `sudo ngx-site` 启用。http 打到独立端口会 301 到 https。
