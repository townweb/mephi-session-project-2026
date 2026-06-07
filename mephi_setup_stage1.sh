#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=/home/yar/mephi-session-project-2026
DATA_DISK=/dev/vdb
DATA_PART=/dev/vdb1
WEB_ROOT=/data/mephi-web

exec > >(tee /var/log/mephi-setup-stage1.log) 2>&1
set -x

hostnamectl set-hostname mephi-2026.domain.local

dnf install -y \
  nginx \
  libcap \
  libcap-ng-utils \
  policycoreutils-python-utils

rm -f /tmp/tcpdump-*.rpm
dnf download --destdir /tmp tcpdump
rpm -Uvh --replacepkgs /tmp/tcpdump-*.rpm

if lsblk -nr -o NAME "$DATA_DISK" | grep -q '^vdb[0-9]'; then
  echo "$DATA_DISK already has partitions; refusing to repartition" >&2
  exit 1
fi

parted -s "$DATA_DISK" mklabel gpt
parted -s "$DATA_DISK" mkpart primary ext4 1MiB 100%
partprobe "$DATA_DISK"
udevadm settle
mkfs.ext4 -F -L MEPHI_DATA "$DATA_PART"

mkdir -p "$WEB_ROOT"
if ! grep -qE '^[[:space:]]*LABEL=MEPHI_DATA[[:space:]]' /etc/fstab; then
  printf 'LABEL=MEPHI_DATA %s ext4 defaults 0 2\n' "$WEB_ROOT" >> /etc/fstab
fi
systemctl daemon-reload
mount -a

getent group mephi-devs >/dev/null || groupadd mephi-devs
id mephi-admin >/dev/null 2>&1 || useradd -m -s /bin/bash mephi-admin
usermod -aG mephi-devs mephi-admin
printf '%s\n' 'mephi-admin:P@ssw0rd2026' | chpasswd

chown mephi-admin:mephi-devs "$WEB_ROOT"
chmod 2775 "$WEB_ROOT"

printf '%s\n' 'Hello from Student: <ВАШ_НОМЕР>' > "$WEB_ROOT/index.html"
chown mephi-admin:mephi-devs "$WEB_ROOT/index.html"
chmod 0664 "$WEB_ROOT/index.html"

cp -a /etc/nginx/nginx.conf /etc/nginx/nginx.conf.before-mephi
sed -i 's#root[[:space:]]\+/usr/share/nginx/html;#root         /data/mephi-web;#' \
  /etc/nginx/nginx.conf

semanage fcontext -a -t httpd_sys_content_t "${WEB_ROOT}(/.*)?" 2>/dev/null ||
  semanage fcontext -m -t httpd_sys_content_t "${WEB_ROOT}(/.*)?"
restorecon -RFv "$WEB_ROOT"

TCPDUMP_PATH=$(command -v tcpdump)
chmod u-s "$TCPDUMP_PATH"
setcap cap_net_raw,cap_net_admin+ep "$TCPDUMP_PATH"

systemctl enable --now nginx
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

install -d -o yar -g yar -m 0755 "$PROJECT_DIR"
cp /var/log/mephi-setup-stage1.log "$PROJECT_DIR/project_history.txt"
cp /etc/fstab "$PROJECT_DIR/fstab.txt"
getenforce > "$PROJECT_DIR/selinux_status.txt"
ls -Zd "$WEB_ROOT" > "$PROJECT_DIR/file_contexts.txt"
getcap "$TCPDUMP_PATH" > "$PROJECT_DIR/tcpdump_capabilities.txt"
stat "$WEB_ROOT" > "$PROJECT_DIR/permissions.txt"
id mephi-admin > "$PROJECT_DIR/users_groups.txt"
getent group mephi-devs >> "$PROJECT_DIR/users_groups.txt"
cp "$WEB_ROOT/index.html" "$PROJECT_DIR/index.html"

curl -fsS http://localhost > "$PROJECT_DIR/curl_output.txt"
journalctl -u nginx --since "5 minutes ago" --no-pager \
  > "$PROJECT_DIR/nginx_recent_logs.txt"

cp /tmp/tcpdump-*.rpm "$PROJECT_DIR/"
cp "$0" "$PROJECT_DIR/"
chown -R yar:yar "$PROJECT_DIR"

findmnt "$WEB_ROOT"
systemctl --no-pager --full status nginx
curl -fsS http://localhost
getcap "$TCPDUMP_PATH"
sudo -u mephi-admin "$TCPDUMP_PATH" --help >/dev/null
