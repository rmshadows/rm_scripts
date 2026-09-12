Shorewall 规则模板（Debian_Server_Init）

选用模板（会覆盖 /etc/shorewall/rules）：

  sudo sw-rules

或手动：

  sudo cp /etc/shorewall/crules/normal /etc/shorewall/rules
  sudo shorewall check && sudo shorewall reload

模板：

  normal    默认。已开 SSH，Ping 关。Web / 邮件 / 自定义端口都在文件里，取消注释即可。
  web       同上，并已开 80/443（配合 nginx + acme）。
  off       进出全丢，应急断网。
  gov_only  只放行指定内网 IP（按文件里的注释改 IP）。

改规则：打开当前用的那份（或先 sw-rules 拷过来），找到注释条，去掉行首 # ，然后：

  sudo shorewall check && sudo shorewall reload

不要用 ufw enable 和 shorewall 一起开。本脚本不会自动 systemctl enable shorewall。
