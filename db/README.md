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

# проверить план выполнения:
sudo -u postgres psql -d devops_test \
  -c "EXPLAIN (ANALYZE, BUFFERS) SELECT ... ;"
