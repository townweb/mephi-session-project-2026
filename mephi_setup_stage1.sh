#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=/home/yar/mephi-session-project-2026
TARGET_HOSTNAME=mephi-2026.domain.local
STUDENT_ID='М255948'
TARGET_IP=192.168.1.100/24
TARGET_GW=192.168.1.1
TARGET_DNS=8.8.8.8
TARGET_IFACE=${TARGET_IFACE:-enp0s2}
DATA_DISK=${DATA_DISK:-/dev/sdb}
DATA_PART=${DATA_PART:-/dev/sdb1}
WEB_ROOT=/data/mephi-web
NGINX_CONF=/etc/nginx/conf.d/mephi-web.conf
SUDOERS_FILE=/etc/sudoers.d/mephi-admin

# Полный вывод и трассировка команд сохраняются как история выполнения проекта.
exec > >(tee /var/log/mephi-setup-stage1.log) 2>&1
set -x

hostnamectl set-hostname "$TARGET_HOSTNAME"
hostnamectl

dnf makecache
dnf install -y nginx tcpdump libcap-ng-utils policycoreutils-python-utils sudo

rpm -qa | grep -E 'nginx|tcpdump|libcap-ng'
rm -f /tmp/tcpdump-*.rpm
dnf download --destdir=/tmp tcpdump
rpm -Uvh /tmp/tcpdump-*.rpm
tcpdump --version

nmcli connection show
nmcli -f NAME,UUID,TYPE,DEVICE connection show

ACTIVE_CONNECTION=$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v iface="$TARGET_IFACE" '$2 == iface {print $1; exit}')
if [ -z "${ACTIVE_CONNECTION:-}" ]; then
  ACTIVE_CONNECTION=$(nmcli -t -f NAME,DEVICE connection show | awk -F: -v iface="$TARGET_IFACE" '$2 == iface {print $1; exit}')
fi
if [ -z "${ACTIVE_CONNECTION:-}" ]; then
  echo "No NetworkManager connection found for ${TARGET_IFACE}" >&2
  exit 1
fi

nmcli connection modify "$ACTIVE_CONNECTION" \
  ipv4.addresses "$TARGET_IP" \
  ipv4.gateway "$TARGET_GW" \
  ipv4.dns "$TARGET_DNS" \
  ipv4.method manual \
  ipv4.ignore-auto-dns yes
nmcli connection down "$ACTIVE_CONNECTION" || true
nmcli connection up "$ACTIVE_CONNECTION"
nmcli connection show "$ACTIVE_CONNECTION"
nmcli -f ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.method,ipv4.ignore-auto-dns connection show "$ACTIVE_CONNECTION"
hostnamectl status
ip addr show "$TARGET_IFACE"
ip route
ping -c 4 "$TARGET_GW"
ping -c 4 "$TARGET_DNS"

lsblk -f
DISK_NAME=$(lsblk -dn -o NAME "$DATA_DISK" 2>/dev/null || true)
if [ -z "$DISK_NAME" ]; then
  echo "Required disk ${DATA_DISK} is not present. Reattach the data disk so it is detected as /dev/sdb." >&2
  exit 1
fi

if [ "$DISK_NAME" != "sdb" ]; then
  echo "The data disk is present, but it is not enumerated as /dev/sdb. Reattach it so the formal checklist can be satisfied." >&2
  exit 1
fi

if lsblk -nr -o NAME "$DATA_DISK" | grep -q '^sdb[0-9]'; then
  echo "$DATA_DISK already has partitions; refusing to repartition without a clean disk." >&2
  exit 1
fi

parted -s "$DATA_DISK" mklabel gpt
parted -s "$DATA_DISK" mkpart primary ext4 1MiB 100%
partprobe "$DATA_DISK"
udevadm settle
mkfs.ext4 -F -L MEPHI_DATA "$DATA_PART"

mkdir -p "$WEB_ROOT"
if ! grep -qE '^[[:space:]]*LABEL=MEPHI_DATA[[:space:]]' /etc/fstab; then
  printf 'LABEL=MEPHI_DATA /data/mephi-web ext4 defaults 0 2\n' >> /etc/fstab
fi
systemctl daemon-reload
mount -a
findmnt "$WEB_ROOT"
df -h "$WEB_ROOT"

getent group mephi-devs >/dev/null || groupadd mephi-devs
id mephi-admin >/dev/null 2>&1 || useradd -m -s /bin/bash mephi-admin
usermod -aG mephi-devs mephi-admin
printf '%s\n' 'mephi-admin:P@ssw0rd2026' | chpasswd

install -d -o mephi-admin -g mephi-devs -m 2775 "$WEB_ROOT"
chown mephi-admin:mephi-devs "$WEB_ROOT"
chmod 2775 "$WEB_ROOT"

cat > "$WEB_ROOT/index.html" <<EOF
<!doctype html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>MEPHI</title>
</head>
<body>
  <h1>Hello from Student: ${STUDENT_ID}</h1>
</body>
</html>
EOF
chown mephi-admin:mephi-devs "$WEB_ROOT/index.html"
chmod 0644 "$WEB_ROOT/index.html"

cat > "$NGINX_CONF" <<'EOF'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;
  root /data/mephi-web;
  index index.html;

  location / {
    try_files $uri $uri/ =404;
  }
}
EOF
if [ -f /etc/nginx/conf.d/default.conf ]; then
  mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled
fi
nginx -t
systemctl start nginx
systemctl enable nginx
systemctl status nginx --no-pager --full
systemctl restart nginx
systemctl reload nginx

semanage fcontext -a -t httpd_sys_content_t "${WEB_ROOT}(/.*)?" 2>/dev/null || \
  semanage fcontext -m -t httpd_sys_content_t "${WEB_ROOT}(/.*)?"
restorecon -Rv "$WEB_ROOT"
getenforce
sestatus
ls -Zd "$WEB_ROOT"
ls -Zd "$WEB_ROOT/index.html"

TCPDUMP_PATH=/usr/sbin/tcpdump
chmod u-s "$TCPDUMP_PATH"
setcap cap_net_raw,cap_net_admin+ep "$TCPDUMP_PATH"
getcap "$TCPDUMP_PATH"
sudo -u mephi-admin "$TCPDUMP_PATH" --help >/dev/null

install -o root -g root -m 0644 /dev/null "$SUDOERS_FILE"
printf '%s\n' 'mephi-admin ALL=(ALL) ALL' > "$SUDOERS_FILE"
visudo -cf "$SUDOERS_FILE"
sudo -l -U mephi-admin

firewall-cmd --permanent --add-service=http
firewall-cmd --reload
firewall-cmd --list-all

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
journalctl -u nginx --since "5 minutes ago" --no-pager > "$PROJECT_DIR/nginx_recent_logs.txt"
cp /tmp/tcpdump-*.rpm "$PROJECT_DIR/tcpdump.rpm"
cp "$0" "$PROJECT_DIR/"
chown -R yar:yar "$PROJECT_DIR"

rpm -q nginx tcpdump libcap-ng-utils
tcpdump --version
findmnt "$WEB_ROOT"
systemctl --no-pager --full status nginx
curl -fsS http://localhost
curl -fsS http://192.168.1.100
getcap "$TCPDUMP_PATH"
sudo -u mephi-admin "$TCPDUMP_PATH" --help >/dev/null
