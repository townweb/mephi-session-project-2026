#!/usr/bin/env bash
set -euo pipefail

P=/home/yar/mephi-session-project-2026

{
  echo '=== OS/HOSTNAME ==='
  cat /etc/fedora-release
  hostnamectl --static
  echo '=== NETWORK ==='
  ip -4 addr show enp0s2
  ip route
  nmcli -g IP4.DNS device show enp0s2
  ping -c 4 192.168.1.1
  ping -c 4 8.8.8.8
  echo '=== DISK/FSTAB ==='
  lsblk -f
  findmnt /data/mephi-web
  grep 'LABEL=MEPHI_DATA' /etc/fstab
  echo '=== NGINX ==='
  systemctl is-enabled nginx
  systemctl is-active nginx
  curl -fsS http://localhost
  curl -fsS http://192.168.1.100
  echo '=== SELINUX ==='
  getenforce
  ls -Zd /data/mephi-web /data/mephi-web/index.html
  echo '=== DAC ==='
  stat -c '%A %a %U:%G %n' /data/mephi-web
  id mephi-admin
  getent group mephi-devs
  echo '=== CAPABILITIES ==='
  getcap /usr/sbin/tcpdump
  sudo -u mephi-admin /usr/sbin/tcpdump --help >/dev/null
  echo TCPDUMP_USER_TEST=OK
  echo '=== PAM ==='
  grep -Hn pam_listfile.so /etc/pam.d/login /etc/pam.d/sshd
  cat /etc/ssh/denied_users
  echo '=== PACKAGES ==='
  rpm -q nginx tcpdump libcap-ng-utils
} | tee "$P/final_verification.txt"

ping -c 4 192.168.1.1 > "$P/network_check.txt"
ping -c 4 8.8.8.8 >> "$P/network_check.txt"
journalctl -u nginx --since '5 minutes ago' --no-pager \
  > "$P/nginx_recent_logs.txt"
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
