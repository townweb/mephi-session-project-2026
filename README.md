# Linux/Unix final project

This repository contains the final artifacts for the Linux/Unix administration project.

Configured system:

- hostname: `mephi-2026.domain.local`
- static IPv4 address: `192.168.1.100/24`
- gateway: `192.168.1.1`
- DNS: `8.8.8.8`
- additional disk: `/dev/sdb`
- partition: `/dev/sdb1`
- filesystem: `ext4`
- filesystem label: `MEPHI_DATA`
- mount point: `/data/mephi-web`
- web server: `nginx`
- web root: `/data/mephi-web`
- user: `mephi-admin`
- group: `mephi-devs`
- SELinux context: `httpd_sys_content_t`
- tcpdump capabilities: `cap_net_raw,cap_net_admin+ep`
- root login restriction: PAM `pam_listfile`
- firewall: HTTP service is allowed

Main files:

- `project_history.txt`
- `network_check.txt`
- `filesystem_check.txt`
- `fstab.txt`
- `nginx_check.txt`
- `nginx_recent_logs.txt`
- `curl_output.txt`
- `selinux_status.txt`
- `file_contexts.txt`
- `permissions.txt`
- `users_groups.txt`
- `tcpdump_capabilities.txt`
- `tcpdump_rpm_check.txt`
- `pam_root_check.txt`
- `root_block_check.txt`
- `firewall_check.txt`
- `final_verification.txt`
- `index.html`
- `tcpdump.rpm`
- `mephi-nginx-screenshot.png`
