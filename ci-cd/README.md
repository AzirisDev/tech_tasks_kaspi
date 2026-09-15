Раздел 5 — CI/CD пайплайн (GitHub Actions)

Полный пайплайн сборки → тестирования → отправки (push) → развертывания (deploy) с уведомлениями в Telegram и автоматическим откатом при неудачных проверках работоспособности (health checks).

```
├── .github/workflows/ci-cd.yml    # сам пайплайн
...
└── app/
    ├── app.py                     # тестируемое Flask-приложение (удобное для внедрения зависимостей / DI-friendly)
    ├── requirements.txt
    ├── requirements-dev.txt       # flake8, pytest, pytest-cov, fakeredis
    ├── Dockerfile                 # многоэтапная сборка Alpine (из Раздела 3)
    ├── .flake8
    └── tests/
        ├── test_unit.py           # 6 модульных тестов (с заглушками для зависимостей)
        └── test_integration.py    # интеграционный тест с fakeredis
```

Обязательные секреты GitHub (GitHub Secrets)
|Секрет|Назначение|
|---|---|
|DOCKERHUB_USERNAME / DOCKERHUB_TOKEN | Авторизация в реестре и отправка образов|
|KUBE_CONFIG | Переданный в base64 файл kubeconfig целевого кластера|
|TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID|Уведомления|

<img width="1721" height="992" alt="Screenshot 2026-09-15 at 15 46 08" src="https://github.com/user-attachments/assets/c4e9d6aa-cad9-4af9-ace7-c2a39593106c" />
<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 15 36 18" src="https://github.com/user-attachments/assets/f63ef0c5-e1a2-42e0-ab01-9950a2878f5c" />
<img width="645" height="1398" alt="IMG_0474" src="https://github.com/user-attachments/assets/58ad58fa-933d-470e-a286-7d0e5c211c75" />

