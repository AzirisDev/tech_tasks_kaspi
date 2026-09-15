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