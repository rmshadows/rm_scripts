# VNC

这里以TightVNC为例:

## 安装

1. `sudo apt install tightvncserver`

2. 第一次启动vnc需要设置密码

3. 参照xstartup，根据自己实际情况书写

4. 启动和停止

   ```
   ### 启动 
   tightvncserver :2 -geometry 1365x768
   
   ### 停止
   tightvncserver -kill 【display】
   
   # 可以设置alias
   alias tvk='tightvncserver -kill'
   # 如：
   tvk :2 && tightvncserver :2 -geometry 1365x768
   ```

   

