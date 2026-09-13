#!/bin/bash
## 手动更新 GeoIP 城市库（DB-IP Lite 月更版）
## 用法：bash ~/Applications/goaccess/update_geoip.sh
## 说明：由 goaccess.sh 安装时部署到 $GOACCESS_DIR，独立于安装脚本，随时可跑
# 库路径（与 goaccess.conf 的 geoip-database 一致）
DB=/usr/local/share/GeoIP/dbip-city-lite.mmdb
MARK="$DB.edition"   # 版本标记（YYYY-MM）
YM=$(date +%Y-%m)

# 当月已更新则跳过（幂等；强制重下请删除 $MARK）
if [ -f "$MARK" ] && [ "$(cat "$MARK" 2>/dev/null)" = "$YM" ]; then
  echo "GeoIP 城市库已是当月版（$YM），无需更新（强制重下请删除 $MARK）"
  exit 0
fi

TMP=$(mktemp /tmp/dbip-city-lite.XXXXXX.gz)
echo "下载 GeoIP 城市库 $YM 版（DB-IP Lite，约 60MB）..."
curl -fsSLo "$TMP" "https://download.db-ip.com/free/dbip-city-lite-${YM}.mmdb.gz" \
  || { echo "下载失败，旧库不受影响"; rm -f "$TMP"; exit 1; }
sudo mkdir -p /usr/local/share/GeoIP
sudo sh -c "gunzip -c '$TMP' > '${DB}.new'" && sudo mv "${DB}.new" "$DB" \
  && echo "$YM" | sudo tee "$MARK" >/dev/null
rm -f "$TMP"
echo "GeoIP 城市库已更新到 $YM 版：$DB"
echo "无需重启服务，下一轮报告生成（约 1 分钟内）自动生效"
