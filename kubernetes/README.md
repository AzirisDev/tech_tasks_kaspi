Раздел 4 — Kubernetes

Полный набор манифестов для развертывания стека Flask + Postgres + Redis в кластере Kubernetes. Все 13 ресурсов успешно проходят проверку kubeconform -strict и полную перекрестную валидацию.

Файл	                        Ресурсы	                                                        Задача
00-namespace.yaml	            Namespace devops-test	                                        —
01-configmap.yaml	            ConfigMap flask-config (LOG_LEVEL, DEBUG, APP_ENV, …)	        4.2
02-secret.yaml	                Secret flask-secret (DATABASE_PASSWORD, REDIS_PASSWORD, base64)	4.2
03-postgres-storage.yaml	    PersistentVolume + PVC, 10Gi RWO	                            4.3
04-postgres-statefulset.yaml	StatefulSet (1 реплика) + ClusterIP Service :5432	            4.1
05-redis.yaml	                Redis Deployment + ClusterIP Service	                        —
06-flask-deployment.yaml	    Deployment (3 реплики, пробы, лимиты) + LoadBalancer :80→5000	4.1
07-hpa.yaml	                    HPA min2/max5, CPU 50%	                                        4.3
08-ingress.yaml	                Ingress / → flask-app (блок TLS подготовлен)	                4.3
kustomization.yaml	            связывает ресурсы воедино для kubectl apply -k .	            —