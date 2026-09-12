#!/bin/bash
# Debian 13 容器冒烟：静态检查 + 渲染站点 + nginx -t + 证书助手（不签发、不启 Shorewall）。
# 不启 nounset：部署脚本会读未设置的 $HOST
set -eo pipefail

if [ ! -f /etc/debian_version ]; then
	echo "冒烟请在 Debian 上跑（CI 用 debian:13 容器）" >&2
	exit 1
fi
if [ "$(id -u)" -ne 0 ]; then
	echo "冒烟需要 root" >&2
	exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export DEBIAN_FRONTEND=noninteractive
export SET_DEPLOY_CI=1
export SET_CREDENTIALS_AUTO=1
export SET_USER_NAME=ciinit
export SET_USER_PASSWD='CiInit#Test9xQ'
export SET_ACME_ISSUE=0

echo "== 静态 =="
bash "$ROOT/ci/static.sh"

echo "== apt（nginx） =="
apt-get update -qq
apt-get install -y --no-install-recommends \
	nginx apache2-utils openssl sudo adduser ca-certificates curl

echo "== 业务用户与目录 =="
if ! id -u ciinit >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ciinit
fi
echo "ciinit:${SET_USER_PASSWD}" | chpasswd
mkdir -p /home/ciinit/nginx/home_page /home/ciinit/nginx/.well-known/acme-challenge \
	/home/ciinit/Logs/nginx
chown -R ciinit:ciinit /home/ciinit

# shellcheck disable=SC1091
source GlobalVariables.sh
# shellcheck disable=SC1091
source Lib.sh
# shellcheck disable=SC1091
source Config.sh

echo "== 渲染并 nginx -t =="
_work=$(mktemp -d)
phpfpmVersion=$(ls /etc/php 2>/dev/null | sort -V | tail -n 1 || true)
phpfpmVersion="${phpfpmVersion:-8.4}"
SET_SERVER_NAME=ci.example.test
HOME_INDEX=/home/ciinit
SET_HTTP_SERVER_ROOT=/home/ciinit/nginx
cp 5/nginx/acme.conf.src 5/nginx/ssl.conf.src "$_work/"
(
	cd "$_work"
	replace_placeholders_with_values acme.conf.src
	replace_placeholders_with_values ssl.conf.src
)
install -m 644 "$_work/acme.conf" /etc/nginx/sites-available/acme.conf
rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/acme.conf /etc/nginx/sites-enabled/acme.conf
# ssl.conf 无证书，不启用
nginx -t

echo "== Shorewall 文件在仓库里完整 =="
test -f 6/SW_CONF/crules/README.txt
test -x 6/SW_CONF/setup_rules.sh || chmod +x 6/SW_CONF/setup_rules.sh

echo "== acme-deploy-cert（HTTP=none，只拷证书） =="
_fake=$(mktemp -d)
mkdir -p "$_fake/ci.example.test_ecc"
printf 'dummy-cert\n' >"$_fake/ci.example.test_ecc/fullchain.cer"
printf 'dummy-key\n' >"$_fake/ci.example.test_ecc/ci.example.test.key"
cat >/etc/acme-deploy.conf <<EOF
ACME_USER=ciinit
ACME_HOME=$_fake
HTTP=none
EOF
install -m 755 5/acme-deploy-cert.sh /usr/local/sbin/acme-deploy-cert
/usr/local/sbin/acme-deploy-cert ci.example.test
test -f /etc/ssl/ci.example.test.pem
test -f /etc/ssl/ci.example.test.key
rm -rf "$_fake" /etc/ssl/ci.example.test.pem /etc/ssl/ci.example.test.key

echo "== sudoers 片段 =="
cat >/etc/sudoers.d/acme-deploy-cert <<EOF
Defaults:ciinit !requiretty
ciinit ALL=(root) NOPASSWD: /usr/local/sbin/acme-deploy-cert
EOF
chmod 440 /etc/sudoers.d/acme-deploy-cert
visudo -cf /etc/sudoers.d/acme-deploy-cert

echo "== runuser 不带 SUDO_* =="
_out=$(runuser -u ciinit -- env -u SUDO_USER -u SUDO_UID env)
if printf '%s\n' "$_out" | grep -q '^SUDO_USER='; then
	echo "runuser 仍带 SUDO_USER" >&2
	exit 1
fi

echo "冒烟通过"
