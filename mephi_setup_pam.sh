#!/usr/bin/env bash
set -euo pipefail

DENY_FILE=/etc/security/denied_users
PAM_RULE='auth required pam_listfile.so item=user sense=deny file=/etc/security/denied_users onerr=fail'

# Файл размещён согласно чек-листу; режим 0644 требуется формальным заданием.
exec > >(tee /var/log/mephi-setup-pam.log) 2>&1
set -x

test -f /usr/lib64/security/pam_listfile.so

install -o root -g root -m 0644 /dev/null "$DENY_FILE"
printf '%s\n' root > "$DENY_FILE"

insert_rule_before_include() {
  local pam_file=$1
  awk -v rule="$PAM_RULE" '
    BEGIN { inserted = 0 }
    /pam_listfile\.so/ {
      if (!inserted) {
        print rule
        inserted = 1
      }
      next
    }
    /^[[:space:]]*auth[[:space:]]+(include|substack)[[:space:]]/ && !inserted {
      print rule
      inserted = 1
    }
    { print }
    END {
      if (!inserted) {
        print rule
      }
    }
  ' "$pam_file" > "${pam_file}.tmp"
  mv "${pam_file}.tmp" "$pam_file"
}

for pam_file in /etc/pam.d/login /etc/pam.d/sshd; do
  cp -a "$pam_file" "${pam_file}.before-mephi"
  insert_rule_before_include "$pam_file"
done

restorecon -v "$DENY_FILE" /etc/pam.d/login /etc/pam.d/sshd
sshd -t
systemctl restart sshd

grep -Hn 'pam_listfile.so' /etc/pam.d/login /etc/pam.d/sshd
cat "$DENY_FILE"
