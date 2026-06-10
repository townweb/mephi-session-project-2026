# Сессионный проект по курсу «Операционные системы семейства Unix»

## Студент

ФИО: Годияк Ярослав Андреевич  
Номер: `M255948`

## Кратко о проекте

В этом репозитории собраны результаты настройки Fedora VM для сессионного проекта по Linux/Unix.  
Я вынес в отдельные файлы основные проверки, чтобы было понятно не только что было настроено, но и как это потом проверялось.

В проекте настроены:

- статическая сеть;
- отдельный диск и файловая система;
- веб-сервер nginx;
- пользователь и группа для работы с веб-директорией;
- права доступа и SELinux-контекст;
- capabilities для tcpdump;
- ограничение входа root через PAM;
- firewall с разрешённым HTTP.

---

## Содержание репозитория

| Файл | Что внутри |
|------|------------|
| `README.md` | Общее описание проекта |
| `project_history.txt` | Краткая история выполненных действий |
| `network_check.txt` | Проверка сети: hostname, nmcli, ip, route, ping, curl |
| `filesystem_check.txt` | Проверка дисков, разделов, файловой системы и монтирования |
| `fstab.txt` | Содержимое `/etc/fstab` |
| `software_check.txt` | Проверка установленных пакетов и версий |
| `nginx_check.txt` | Конфигурация и состояние nginx |
| `nginx_recent_logs.txt` | Последние логи nginx |
| `curl_output.txt` | Проверка ответа веб-сервера через curl |
| `selinux_status.txt` | Состояние SELinux |
| `file_contexts.txt` | SELinux-контекст для `/data/mephi-web` |
| `permissions.txt` | Права и владельцы веб-директории |
| `users_groups.txt` | Проверка пользователя `mephi-admin` и группы `mephi-devs` |
| `tcpdump_capabilities.txt` | Проверка capabilities для tcpdump |
| `tcpdump_rpm_check.txt` | Проверка сохранённого RPM-пакета tcpdump |
| `pam_root_check.txt` | Проверка запрета root через PAM |
| `root_block_check.txt` | Дополнительная проверка root-блокировки |
| `firewall_check.txt` | Проверка firewalld и разрешённого HTTP |
| `final_verification.txt` | Общая итоговая проверка основных настроек |
| `index.html` | Веб-страница nginx |
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

Связность проверялась через `ping`:

```text
ping 192.168.1.1
ping 8.8.8.8
```

По результатам проверки оба адреса доступны, потерь пакетов нет:

```text
4 packets transmitted, 4 received, 0% packet loss
```

Также проверялась доступность веб-сервера по адресу:

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

Пакет `tcpdump` дополнительно скачан и сохранён в проекте как:

```text
tcpdump.rpm
```

Проверка версии tcpdump и самого RPM-пакета сохранена в файлах:

```text
software_check.txt
tcpdump_rpm_check.txt
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

```text
findmnt
df
lsblk
blkid
```

---

## 4. Настройка nginx

Веб-сервер `nginx` настроен на раздачу файлов из директории:

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

Проверка выполнялась через:

```bash
curl http://localhost
curl http://127.0.0.1
curl http://192.168.1.100
```

Во всех случаях сервер возвращает:

```text
Hello from Student: M255948
```

Скриншот работающей страницы лежит в файле:

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

Права проверены в файле:

```text
permissions.txt
```

Информация по пользователю и группе сохранена в:

```text
users_groups.txt
```

---

## 6. SELinux

SELinux работает в режиме:

```text
Enforcing
```

Для директории `/data/mephi-web` установлен контекст:

```text
httpd_sys_content_t
```

Проверки сохранены в файлах:

```text
selinux_status.txt
file_contexts.txt
```

---

## 7. Capabilities для tcpdump

Для `tcpdump` настроены capabilities:

```text
cap_net_admin,cap_net_raw=ep
```

Проверка сохранена в файле:

```text
tcpdump_capabilities.txt
```

---

## 8. Ограничение входа root

Для ограничения входа root используется файл:

```text
/etc/security/denied_users
```

В него добавлен пользователь:

```text
root
```

В PAM-файлы добавлено правило `pam_listfile`:

```text
/etc/pam.d/sshd
/etc/pam.d/login
```

Проверки сохранены в файлах:

```text
pam_root_check.txt
root_block_check.txt
```

---

## 9. Firewall

Используется `firewalld`.

HTTP разрешён:

```text
services: ... http ...
```

Проверка сохранена в файле:

```text
firewall_check.txt
```

---

## 10. Итоговая проверка

Основные итоговые проверки собраны в файле:

```text
final_verification.txt
```

В нём проверяются:

- hostname;
- IPv4, gateway и DNS;
- ping до `192.168.1.1`;
- ping до `8.8.8.8`;
- монтирование `/data/mephi-web`;
- строка в `/etc/fstab`;
- проверка `nginx -t`;
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

Репозиторий проекта:

```text
https://github.com/townweb/mephi-session-project-2026
```
