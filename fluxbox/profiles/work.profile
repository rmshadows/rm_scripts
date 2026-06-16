# 工作场景 profile（switch-profile.sh 读取）
# 格式：init键=值  或  CONKY=命令

session.screen0.workspaces=4
session.screen0.windowPlacement=SmartPlacement
session.styleFile=~/.fluxbox/styles/Font-14
CONKY=bash -c '~/.fluxbox/scripts/conky/conky-Desktop; conky &'
