#!/usr/bin/env bash
set -euo pipefail

P=/home/yar/mephi-session-project-2026
TARGET_IFACE=${TARGET_IFACE:-$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2 == "ethernet" && $1 != "--" {print $1; exit}')}
if [ -z "${TARGET_IFACE:-}" ]; then
  echo "No ethernet device found" >&2
  exit 1
fi
TARGET_HOSTNAME=mephi-2026.domain.local

get_active_connection() {
  nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v iface="$TARGET_IFACE" '$2 == iface {print $1; exit}'
}

ACTIVE_CONNECTION=$(get_active_connection)

# Проверка выполняется после перезагрузки и собирает состояние всех подсистем.
{
  echo '=== HOSTNAME ==='
  hostnamectl
  hostnamectl --static
  echo '=== NETWORK ==='
  nmcli connection show
  if [ -n "${ACTIVE_CONNECTION:-}" ]; then
    nmcli -f ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.method,ipv4.ignore-auto-dns connection show "$ACTIVE_CONNECTION"
  fi
  ip addr show "$TARGET_IFACE"
  ip route
  ping -c 4 192.168.1.1
  ping -c 4 8.8.8.8
  echo '=== DISK/FSTAB ==='
  lsblk -f
  findmnt /data/mephi-web
  cat /etc/fstab
  echo '=== SOFTWARE ==='
  rpm -q nginx tcpdump libcap-ng-utils
  tcpdump --version
  echo '=== NGINX ==='
  systemctl is-enabled nginx
  systemctl is-active nginx
  nginx -t
  curl -fsS http://localhost
  curl -fsS http://192.168.1.100
  echo '=== SELINUX ==='
  getenforce
  sestatus
  ls -Zd /data/mephi-web
  ls -Zd /data/mephi-web/index.html
  echo '=== DAC ==='
  stat -c '%A %a %U:%G %n' /data/mephi-web
  stat -c '%A %a %U:%G %n' /data/mephi-web/index.html
  id mephi-admin
  getent group mephi-devs
  sudo -l -U mephi-admin
  echo '=== CAPABILITIES ==='
  getcap /usr/sbin/tcpdump
  sudo -u mephi-admin /usr/sbin/tcpdump --help >/dev/null
  echo TCPDUMP_USER_TEST=OK
  echo '=== PAM ==='
  grep -Hn pam_listfile.so /etc/pam.d/login /etc/pam.d/sshd
  cat /etc/security/denied_users
  stat -c '%a %U:%G %n' /etc/security/denied_users
  echo '=== FIREWALL ==='
  firewall-cmd --list-all
} | tee "$P/final_verification.txt"

{
  echo '=== NETWORK ==='
  hostnamectl
  nmcli connection show
  if [ -n "${ACTIVE_CONNECTION:-}" ]; then
    nmcli -f ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.method,ipv4.ignore-auto-dns connection show "$ACTIVE_CONNECTION"
  fi
  ip addr show "$TARGET_IFACE"
  ip route
  ping -c 4 8.8.8.8
  ping -c 4 192.168.1.1
} | tee "$P/network_check.txt"

journalctl -u nginx --since '5 minutes ago' --no-pager > "$P/nginx_recent_logs.txt"
ip addr show "$TARGET_IFACE" > "$P/current_addresses.txt"
ip route > "$P/current_routes.txt"
cp /etc/fstab "$P/fstab.txt"
getenforce > "$P/selinux_status.txt"
ls -Zd /data/mephi-web > "$P/file_contexts.txt"
getcap /usr/sbin/tcpdump > "$P/tcpdump_capabilities.txt"
stat /data/mephi-web > "$P/permissions.txt"
id mephi-admin > "$P/users_groups.txt"
getent group mephi-devs >> "$P/users_groups.txt"
curl -fsS http://192.168.1.100 > "$P/curl_output.txt"
cp "$0" "$P/"
chown -R yar:yar "$P"
