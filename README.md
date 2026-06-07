# MEPHI Session Project 2026

Student ID: `М255948`

Configured system:

- Fedora 43 ARM64
- hostname `mephi-2026.domain.local`
- static address `192.168.1.100/24`
- gateway `192.168.1.1`
- DNS `8.8.8.8`
- ext4 volume `MEPHI_DATA` mounted at `/data/mephi-web`
- nginx enabled and serving `/data/mephi-web`
- SELinux `Enforcing`, content type `httpd_sys_content_t`
- `mephi-admin` in group `mephi-devs`, web root mode `2775`
- `tcpdump` capabilities `cap_net_admin,cap_net_raw=ep`
- root login denied by `pam_listfile.so` for local login and SSH

The complete post-reboot check is stored in `final_verification.txt`.
