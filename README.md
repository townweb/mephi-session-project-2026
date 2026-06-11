# Сессионный проект по курсу «Операционные системы семейства Unix»

## Студент

ФИО: Годияк Ярослав Андреевич  
Номер: `M255948`

## Кратко о проекте

В этом репозитории собраны финальные артефакты по настройке Fedora VM для сессионного проекта по Linux/Unix.

Я сделал отдельную виртуальную машину, настроил сеть, диск, nginx, права, SELinux, PAM, firewall и отдельно сохранил выводы проверочных команд. То есть здесь не просто описание «что должно быть», а файлы с фактическими проверками после настройки.

Основная страница nginx отдаёт текст:

```text
Hello from Student: M255948
```

---

## Основные параметры системы

| Параметр | Значение |
|---------|----------|
| Hostname | `mephi-2026.domain.local` |
| ОС | `Fedora Linux 44 Workstation Edition` |
| Архитектура | `aarch64 / arm64` |
| Виртуализация | `QEMU` |
| IPv4 | `192.168.1.100/24` |
| Gateway | `192.168.1.1` |
| DNS | `8.8.8.8` |
| Метод IPv4 | `manual` |
| Дополнительный диск | `/dev/sdb` |
| Раздел | `/dev/sdb1` |
| Файловая система | `ext4` |
| Метка ФС | `MEPHI_DATA` |
| Точка монтирования | `/data/mephi-web` |
| Веб-сервер | `nginx` |
| Корень сайта | `/data/mephi-web` |
| Пользователь | `mephi-admin` |
| Группа | `mephi-devs` |
| SELinux | `Enforcing` |
| Контекст SELinux | `httpd_sys_content_t` |
| Capabilities tcpdump | `cap_net_admin,cap_net_raw=ep` |
| Firewall | `firewalld`, HTTP разрешён |

---

## Содержание репозитория

| Файл | Что внутри |
|------|------------|
| `README.md` | Общее описание проекта и краткая сводка по настройкам |
| `project_history.txt` | История основных команд, которые выполнялись при настройке |
| `network_check.txt` | Проверка сети: hostname, `nmcli`, IP-адреса, маршруты, DNS, ping и curl |
| `filesystem_check.txt` | Проверка дисков, разделов, файловой системы и монтирования |
| `fstab.txt` | Содержимое `/etc/fstab` |
| `software_check.txt` | Проверка установленных пакетов и версий nginx/tcpdump |
| `nginx_check.txt` | Конфигурация nginx, статус сервиса и curl-проверки |
| `nginx_recent_logs.txt` | Последние логи nginx |
| `curl_output.txt` | Вывод curl-запросов к веб-серверу |
| `selinux_status.txt` | Режим работы SELinux |
| `file_contexts.txt` | SELinux-контекст директории `/data/mephi-web` и файла `index.html` |
| `permissions.txt` | Права доступа и владельцы директории `/data/mephi-web` |
| `users_groups.txt` | Информация о пользователе `mephi-admin` и группе `mephi-devs` |
| `tcpdump_capabilities.txt` | Проверка capabilities для `/usr/sbin/tcpdump` |
| `tcpdump_rpm_check.txt` | Проверка сохранённого RPM-пакета tcpdump |
| `pam_root_check.txt` | Проверка запрета root через PAM |
| `root_block_check.txt` | Дополнительная проверка блокировки root |
| `firewall_check.txt` | Проверка `firewalld` и разрешённого HTTP |
| `final_verification.txt` | Общая итоговая проверка основных пунктов проекта |
| `index.html` | Страница, которую отдаёт nginx |
| `tcpdump.rpm` | Сохранённый RPM-пакет tcpdump |
| `mephi-nginx-screenshot.png` | Скриншот работающей страницы nginx |

---

## 1. Управление сетью

Для виртуальной машины задан hostname:

```text
mephi-2026.domain.local
```

Настроены сетевые параметры:

```text
IPv4:    192.168.1.100/24
Gateway: 192.168.1.1
DNS:     8.8.8.8
Method:  manual
```

В `network_check.txt` сохранены выводы:

```bash
hostnamectl
nmcli connection show --active
nmcli connection show mephi-project-net
ip addr
ip route
resolvectl dns
ping -c 4 192.168.1.1
ping -c 4 8.8.8.8
curl http://localhost
curl http://127.0.0.1
curl http://192.168.1.100
```

Результат проверки связи:

```text
4 packets transmitted, 4 received, 0% packet loss
```

Веб-сервер доступен по адресу:

```text
http://192.168.1.100
```

---

## 2. Управление программным обеспечением

Установлены основные пакеты:

```text
nginx
tcpdump
libcap-ng-utils
```

Также установлен и использован `firewalld`, а для настройки SELinux-контекста установлен пакет с `semanage`.

Пакет `tcpdump` дополнительно сохранён как локальный RPM-файл:

```text
tcpdump.rpm
```

Версии проверялись через:

```bash
tcpdump --version
nginx -v
rpm -qa
```

---

## 3. Файловая система и монтирование

Для проекта использован отдельный диск:

```text
/dev/sdb
```

На нём создан раздел:

```text
/dev/sdb1
```

Раздел отформатирован в `ext4` с меткой:

```text
MEPHI_DATA
```

Точка монтирования:

```text
/data/mephi-web
```

В `/etc/fstab` добавлена строка:

```text
LABEL=MEPHI_DATA /data/mephi-web ext4 defaults 0 2
```

Монтирование проверялось через:

```bash
lsblk
blkid
findmnt /data/mephi-web
df -h /data/mephi-web
```

---

## 4. Настройка nginx

`nginx` настроен на раздачу файлов из директории:

```text
/data/mephi-web
```

Файл страницы:

```text
/data/mephi-web/index.html
```

Содержимое страницы:

```text
Hello from Student: M255948
```

Проверка конфигурации nginx:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Сервис nginx запущен и добавлен в автозапуск:

```text
active
enabled
```

Проверка страницы выполнялась так:

```bash
curl http://localhost
curl http://127.0.0.1
curl http://192.168.1.100
```

Во всех случаях ответ один и тот же:

```text
Hello from Student: M255948
```

Скриншот работающей страницы:

```text
mephi-nginx-screenshot.png
```

---

## 5. Пользователь, группа и права доступа

Создан пользователь:

```text
mephi-admin
```

Создана группа:

```text
mephi-devs
```

Пользователь `mephi-admin` добавлен в группу `mephi-devs`.

Для директории `/data/mephi-web` настроены владелец, группа и права:

```text
mephi-admin:mephi-devs
2775
```

Фактический вид прав:

```text
drwxrwsr-x
```

Это значит, что на директории установлен setgid, и новые файлы внутри наследуют группу `mephi-devs`.

---

## 6. SELinux

SELinux работает в режиме:

```text
Enforcing
```

Для директории сайта задан контекст:

```text
httpd_sys_content_t
```

Контекст применён к директории `/data/mephi-web` и к файлу `index.html`.

Проверки сохранены в файлах:

```text
selinux_status.txt
file_contexts.txt
```

---

## 7. Capabilities для tcpdump

Для `tcpdump` убран setuid и настроены capabilities:

```text
/usr/sbin/tcpdump cap_net_admin,cap_net_raw=ep
```

Работоспособность дополнительно проверялась запуском справки tcpdump от пользователя `mephi-admin`.

---

## 8. Ограничение входа root

Для ограничения входа root используется файл:

```text
/etc/security/denied_users
```

В файл добавлен пользователь:

```text
root
```

В PAM-файлы добавлено правило `pam_listfile`:

```text
/etc/pam.d/sshd
/etc/pam.d/login
```

Файл `/etc/security/denied_users` имеет права:

```text
0644
```

---

## 9. Firewall

Используется `firewalld`.

Сервис работает:

```text
running
```

HTTP разрешён:

```text
services: dhcpv6-client http samba-client ssh
```

Проверка сохранена в файле:

```text
firewall_check.txt
```

---

## 10. Итоговая проверка

Итоговая проверка собрана в файле:

```text
final_verification.txt
```

В ней проверяются:

- hostname;
- IPv4, gateway и DNS;
- ping до `192.168.1.1`;
- ping до `8.8.8.8`;
- монтирование `/data/mephi-web`;
- строка в `/etc/fstab`;
- `nginx -t`;
- ответ nginx через `curl`;
- SELinux-контекст;
- capabilities для tcpdump;
- PAM-правила;
- настройки firewalld.

Основной результат веб-проверки:

```text
Hello from Student: M255948
```

---

## Ссылка на репозиторий

```text
https://github.com/townweb/mephi-session-project-2026
```
