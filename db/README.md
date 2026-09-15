Раздел 1 — База данных и SQL

Схема PostgreSQL, тестовые данные и 10 аналитических запросов для системы деплоя. Весь SQL-код был выполнен в PostgreSQL, и каждый запрос возвращает корректные результаты.

Файлы

schema.sql - Таблицы, типы ENUM, внешние ключи, индексы

seed_data.sql - Тестовые данные (12 пользователей, 15 серверов, 20 деплоев, 22 лога)

queries.sql - 10 аналитических запросов, каждый с комментариями

provision.sh - Одношаговая установка + создание БД + загрузка данных для чистой ВМ Ubuntu

Задача 1.1

sudo ./provision.sh # устанавливает PostgreSQL 14, создает devops_test, загружает схему и данные

Задача 1.2

sudo -u postgres psql -d devops_test -f 03_queries.sql

проверить план выполнения:
sudo -u postgres psql -d devops_test \
  -c "EXPLAIN (ANALYZE, BUFFERS) SELECT ... ;"

<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 01 25 45" src="https://github.com/user-attachments/assets/0f465fbf-1fbd-4e11-a277-c6cb34dd6dfa" />
<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 01 26 07" src="https://github.com/user-attachments/assets/5c74f7b8-bf14-4cfa-98b3-b3a5f883b51a" />
<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 01 26 20" src="https://github.com/user-attachments/assets/53140e24-5c74-4c1a-97fb-4f67c83c20bc" />
<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 01 26 25" src="https://github.com/user-attachments/assets/ff6ee930-d6db-4640-9a3f-750c3e6e4506" />






