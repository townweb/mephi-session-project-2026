#!/usr/bin/env bash
set -euo pipefail

DENY_FILE=/etc/ssh/denied_users
PAM_RULE='auth required pam_listfile.so item=user sense=deny file=/etc/ssh/denied_users onerr=fail'

exec > >(tee /var/log/mephi-setup-pam.log) 2>&1
set -x

test -f /usr/lib64/security/pam_listfile.so

install -o root -g root -m 0600 /dev/null "$DENY_FILE"
printf '%s\n' root > "$DENY_FILE"

for pam_file in /etc/pam.d/login /etc/pam.d/sshd; do
  cp -a "$pam_file" "${pam_file}.before-mephi"
  if ! grep -Fq 'pam_listfile.so' "$pam_file"; then
    sed -i "1a ${PAM_RULE}" "$pam_file"
  fi
done

restorecon -v "$DENY_FILE" /etc/pam.d/login /etc/pam.d/sshd
sshd -t

grep -Hn 'pam_listfile.so' /etc/pam.d/login /etc/pam.d/sshd
cat "$DENY_FILE"
