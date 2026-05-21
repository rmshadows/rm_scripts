# 应用安装模板

本目录作为「应用安装」脚本的模板，新应用可复制本目录后按下面步骤改为自己的服务。

## 使用步骤

1. **复制并重命名**  
   将整目录复制一份，目录名改为你的应用名（如 `my_real_app`）。

2. **改 CONF**  
   在主安装脚本（如改名为 `my_real_app.sh`）中修改：
   - `SRV_NAME`：服务名（与 systemd 单元名、Services 子目录名一致）
   - `RUN_PORT`：应用监听端口
   - `REVERSE_PROXY_URL`：Nginx 反代路径（如 `/myapp/`）

3. **改 Nginx 片段与 setup 脚本的命名**  
   - 将 `myapp-snippet.conf` 重命名为 `你的服务名-snippet.conf`
   - 将 `setupNginxForMyapp.sh` 重命名为 `setupNginxFor你的服务名.sh`（如 `setupNginxForRsshub.sh`）
   - 在上述两个文件内部，把 `myapp` 全部替换为你的服务名（含 `/etc/nginx/snippets/myapp.conf` 等路径）
   - 在主安装脚本中，把对 `setupNginxForMyapp.sh` 的调用、以及提示里的 `include /etc/nginx/snippets/myapp.conf;` 改为你的服务名

4. **填写安装逻辑**  
   在「### 安装软件」段落中填写：依赖检查、下载、解压、编译、复制等；如需占位符，使用 `srv.service.src`、`reverse_proxy.txt.src` 中的 `【$变量名】` 与 `ServiceInit.sh` 的 `replace_placeholders_with_values`。

5. **启动/停止脚本**  
   按需编辑 `start.sh`、`stop.sh`，并确保 `srv.service.src` 中的 `ExecStart`/`ExecStop` 路径与 `$SRV_NAME` 一致。

完成后，在应用目录下执行主安装脚本即可完成安装、服务注册与 Nginx 片段写入；用户只需在对应 site 的 `server { }` 内加一行 `include /etc/nginx/snippets/你的服务名.conf;` 并重载 Nginx。
