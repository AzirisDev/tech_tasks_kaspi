Раздел 6 — Terraform (инфраструктура AWS как код)

Модульный Terraform для полного стека AWS: VPC + сетевая инфраструктура, группы безопасности (security groups), EKS, RDS PostgreSQL и ECR. Состояние (state) хранится удаленно в S3.

```
section6-terraform/
├── main.tf                 # главный файл: связывает все модули воедино
├── providers.tf            # провайдер AWS + теги по умолчанию
├── versions.tf             # требуемые версии + S3-бэкенд
├── variables.tf            # корневые переменные
├── outputs.tf              # eks_cluster_endpoint, rds_endpoint, ecr_repository_url, ...
├── terraform.tfvars.example
└── modules/
    ├── vpc/                # VPC, подсети, IGW, NAT, таблицы маршрутизации
    ├── security/          # группы безопасности для приложения и БД
    ├── eks/               # управляющий слой (control plane) + управляемая группа нод (managed node group)
    ├── rds/               # PostgreSQL 14, Multi-AZ
    └── ecr/               # репозиторий flask-app (IMMUTABLE)
```

Each module has `main.tf`, `variables.tf`, and `outputs.tf` (Task 6.5).