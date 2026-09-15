Раздел 7 — Мониторинг и наблюдаемость

Prometheus + Grafana для метрик, Loki + Promtail для логов (Вариант B). В Flask-приложение добавлены эндпоинт /metrics и структурированное логирование в формате JSON.

```
├── app/
│   ├── app.py                 # Flask-приложение с метриками (/metrics) и JSON-логами
│   ├── requirements.txt
│   └── Dockerfile
├── prometheus/
│   ├── prometheus.yml         # конфигурация сбора метрик K8s (API, ноды, приложение, postgres)
│   └── prometheus-local.yml   # упрощенная конфигурация для docker-compose
├── grafana/
│   ├── dashboard.json         # дашборд из 6 панелей
│   └── datasources.yml        # источники данных Prometheus + Loki
├── loki/
│   ├── loki-config.yml
│   └── promtail-config.yml    # парсинг JSON-логов, обнаружение ресурсов K8s
├── k8s/                       # развертывание стека в Kubernetes
│   ├── 00-namespace.yaml
│   ├── 01-prometheus.yaml     # + RBAC
│   ├── 02-grafana.yaml
│   ├── 03-loki-promtail.yaml  # Deployment Loki + DaemonSet Promtail
│   └── 04-app-annotations-patch.yaml
├── kustomization.yaml         # генерирует ConfigMap с конфигурацией из файлов
└── docker-compose.yml         # локальный стек для быстрого тестирования
```

<img width="1728" height="1117" alt="Screenshot 2026-09-15 at 16 46 33" src="https://github.com/user-attachments/assets/2e618bf5-1125-4e89-83eb-ce511ec5b6ff" />
<img width="1920" height="1080" alt="Screenshot From 2026-09-15 16-46-04" src="https://github.com/user-attachments/assets/acb1ec5d-046f-4586-bd52-622d53bee0bb" />
<img width="1920" height="1080" alt="Screenshot From 2026-09-15 16-46-19" src="https://github.com/user-attachments/assets/1fe34d4c-4fbe-498e-a673-5101c006be4a" />
<img width="1920" height="1080" alt="Screenshot From 2026-09-15 16-47-38" src="https://github.com/user-attachments/assets/65e062e9-2e2b-41dd-bdd6-53cb834fbfc4" />
<img width="1920" height="1080" alt="Screenshot From 2026-09-15 16-48-47" src="https://github.com/user-attachments/assets/60436165-30ce-47bc-91d8-77457efe3dd7" />
<img width="1920" height="1080" alt="Screenshot From 2026-09-15 16-50-05" src="https://github.com/user-attachments/assets/a7e07ed5-d6f0-44f3-a182-69f39bb41162" />



