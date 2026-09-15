Раздел 5 — CI/CD пайплайн (GitHub Actions)

Полный пайплайн сборки → тестирования → отправки (push) → развертывания (deploy) с уведомлениями в Telegram и автоматическим откатом при неудачных проверках работоспособности (health checks).

section5-cicd/
├── .github/workflows/ci-cd.yml    # сам пайплайн
└── app/
    ├── app.py                     # тестируемое Flask-приложение (удобное для внедрения зависимостей / DI-friendly)
    ├── requirements.txt
    ├── requirements-dev.txt       # flake8, pytest, pytest-cov, fakeredis
    ├── Dockerfile                 # многоэтапная сборка Alpine (из Раздела 3)
    ├── .flake8
    └── tests/
        ├── test_unit.py           # 6 модульных тестов (с заглушками для зависимостей)
        └── test_integration.py    # интеграционный тест с fakeredis

Обязательные секреты GitHub (GitHub Secrets)
|Секрет|Назначение|
|---|---|
|DOCKERHUB_USERNAME / DOCKERHUB_TOKEN | Авторизация в реестре и отправка образов|
|KUBE_CONFIG | Переданный в base64 файл kubeconfig целевого кластера|
|TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID|Уведомления|
