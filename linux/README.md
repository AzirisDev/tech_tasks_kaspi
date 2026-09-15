Раздел 2 — Bash-скрипты

Два скрипта мониторинга уровня. В обоих установлена опция set -euo pipefail, они успешно проходят shellcheck без предупреждений, логируют события с временными метками, корректно обрабатывают ошибки и завершаются с ненулевым кодом при превышении порогов, чтобы cron или CI могли отреагировать.

Файлы

system_monitor.sh - Мониторинг CPU / памяти / диска / количества процессов с пороговыми значениями + оповещения в Slack
ssl_check.sh - Проверка срока действия TLS-сертификатов для одного или нескольких доменов + оповещения в Slack
crontab.example - Готовые к установке записи cron для обоих скриптов
domains.txt.example - Пример списка доменов для запуска ssl_check.sh -f


<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 09 27 48" src="https://github.com/user-attachments/assets/d3c66e3f-329f-495a-bf06-da97d809103f" />
<img width="645" height="1398" alt="IMG_0473" src="https://github.com/user-attachments/assets/3a797bf5-d5f5-4acc-a10a-e81e6ef6065e" />
