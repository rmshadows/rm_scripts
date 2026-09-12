#!/bin/bash
# 静态检查：语法 + Lib 小函数 + 模板占位符。不改系统，Ubuntu / Debian 都能跑。
# 不启 nounset：GlobalVariables.sh 会读未设置的 $HOST
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
ok() { echo "ok  $*"; }
bad() { echo "FAIL $*" >&2; fail=1; }

echo "== bash -n =="
while IFS= read -r f; do
	if ! bash -n "$f"; then
		bad "bash -n $f"
	fi
done < <(
	find . \
		-path './archive' -prune -o \
		-path './other' -prune -o \
		-type f -name '*.sh' -print | sort
)
ok "脚本语法"

echo "== 源模板不要机器专用域名 =="
if grep -RInE 'civiccccc|justaaaa' --include='*.src' --include='*.sh' --include='*.txt' \
	5/nginx 6/SW_CONF Config.sh Lib.sh 5/setup.sh 5/acme-deploy-cert.sh 2>/dev/null; then
	bad "模板/脚本里有机器专用域名或邮箱"
else
	ok "模板无机器专用域名"
fi

echo "== 加载 Lib / Config =="
# shellcheck disable=SC1091
source GlobalVariables.sh
# shellcheck disable=SC1091
source Lib.sh
SET_USER_NAME="${SET_USER_NAME:-ciinit}"
SET_USER_PASSWD="${SET_USER_PASSWD:-CiInit#Test9xQ}"
SET_DEPLOY_CI=0
# shellcheck disable=SC1091
source Config.sh

echo "== 函数 =="
if deploy_acme_domain_usable localhost; then bad "localhost 不该能签发"; else ok "拒绝 localhost"; fi
if deploy_acme_domain_usable example.com; then ok "接受 example.com"; else bad "example.com 应能签发"; fi
if deploy_acme_domain_usable 10.0.0.1; then bad "裸 IP 不该能签发"; else ok "拒绝裸 IP"; fi
if cred_username_is_weak admin; then ok "admin 判定弱"; else bad "admin 应判定弱"; fi
if cred_username_is_weak ciinit; then bad "ciinit 不应判定弱"; else ok "ciinit 可用"; fi
if cred_password_is_weak passwd admin; then ok "passwd 判定弱"; else bad "passwd 应判定弱"; fi
if cred_password_is_weak 'CiInit#Test9xQ' ciinit; then bad "测试密码不应判定弱"; else ok "测试密码可用"; fi

SET_DEPLOY_CI=1
if deploy_is_ci; then ok "SET_DEPLOY_CI=1"; else bad "deploy_is_ci"; fi
if deploy_confirm_start; then ok "CI 跳过确认"; else bad "CI 仍要求确认"; fi
SET_DEPLOY_CI=0

echo "== 渲染 nginx 模板 =="
_tmp=$(mktemp -d)
trap 'rm -rf "$_tmp"' EXIT
SET_SERVER_NAME=ci.example.test
HOME_INDEX=/home/ciinit
SET_HTTP_SERVER_ROOT=/home/ciinit/nginx
phpfpmVersion=8.4
cp 5/nginx/acme.conf.src "$_tmp/acme.conf.src"
cp 5/nginx/ssl.conf.src "$_tmp/ssl.conf.src"
replace_placeholders_with_values "$_tmp/acme.conf.src"
replace_placeholders_with_values "$_tmp/ssl.conf.src"
if grep -n '【$' "$_tmp/acme.conf" "$_tmp/ssl.conf"; then
	bad "渲染后仍有未替换占位符"
else
	ok "占位符已替换"
fi
if grep -q 'server_name ci.example.test' "$_tmp/acme.conf"; then
	ok "acme.conf server_name"
else
	bad "acme.conf 域名未写入"
fi
if grep -q 'root /home/ciinit/nginx/home_page' "$_tmp/ssl.conf"; then
	ok "ssl.conf home_page"
else
	bad "ssl.conf 缺少 home_page"
fi

echo "== Shorewall 模板 =="
for t in normal web off gov_only; do
	if [ -f "6/SW_CONF/crules/$t" ]; then
		ok "crules/$t"
	else
		bad "缺少 crules/$t"
	fi
done
if grep -q '^SSH(ACCEPT)' 6/SW_CONF/crules/normal; then
	ok "normal 已开 SSH"
else
	bad "normal 应默认开 SSH"
fi
if grep -q '^Web(ACCEPT)' 6/SW_CONF/crules/web; then
	ok "web 已开 80/443"
else
	bad "web 应默认开 Web"
fi

if [ "$fail" -ne 0 ]; then
	echo "静态检查未通过" >&2
	exit 1
fi
echo "静态检查通过"
