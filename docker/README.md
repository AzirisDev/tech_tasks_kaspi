Раздел 3 — Docker и Docker Compose

Микросервис на Flask (Postgres + Redis), контейнеризованный с использованием многоэтапной сборки (multi-stage build), и стек из 4 сервисов в Docker Compose за Nginx.

3.1 — Особенности Dockerfile

- Multi-stage
- Non-root
- Минимальный базовый образ
- Healthcheck
- Метаданные
- Среда выполнения
- Размер образа (цель < 200 МБ)
- Объем зависимостей был измерен напрямую (pip install --prefix): Python-пакеты добавляют около 18 МБ поверх базового python:3.12-slim (~120 МБ на диске), поэтому итоговый размер образа составляет ~135–140 МБ, что полностью укладывается в лимит 200 МБ.

3.2 — Стек Compose
|Сервис|Образ||Порты|Healthcheck|
|db|postgres:14-alpine|внутренний|pg_isready|
|redis|redis:7-alpine|внутренний|redis-cli ping|
|app|сборка из ./app|внутренний|GET /health|
|nginx|nginx:1.27-alpine|80 -> хост|wget /health|

3.1
<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 10 47 41" src="https://github.com/user-attachments/assets/f5f3cc38-4d77-4f00-b929-47f76170dc26" />
<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 10 47 51" src="https://github.com/user-attachments/assets/3cc60811-4608-4a42-9674-0c31b03c4f4e" />

3.2
<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 10 49 53" src="https://github.com/user-attachments/assets/92f3618d-06e6-45f4-930c-ce2795013982" />

