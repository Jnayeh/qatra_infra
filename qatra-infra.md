# Qatra Infrastructure - Deployment & Monitoring

## Overview

Production infrastructure running on **k3s** (lightweight Kubernetes) with a complete observability stack. Domain: `zayenha.app`. Two Java/Spring Boot microservices communicate via Kafka, backed by PostgreSQL, Redis, exposed through Traefik (k3s built-in) ingress with automatic Let's Encrypt TLS.

---

## Kubernetes Cluster (k3s)

### Namespaces
- **qatra** -- primary namespace for all application and monitoring workloads
- **kubernetes-dashboard** -- separate namespace for the Kubernetes Dashboard

### Resource Manifests (applied in numeric order)

| File | Resource Type | Name | Image |
|------|--------------|------|-------|
| `00-namespace.yaml` | Namespace | qatra, kubernetes-dashboard | -- |
| `01-postgres.yaml` | ConfigMap + StatefulSet + Service | postgres | postgres:16-alpine |
| `02-kafka.yaml` | StatefulSet + Service | kafka | confluentinc/cp-kafka:7.6.0 |
| `03-redis.yaml` | StatefulSet + Service | redis | redis:7-alpine |
| `04-donation-service.yaml` | ConfigMap + Deployment + Service | donation-service | qatra/donation-service:latest |
| `05-notification-service.yaml` | ConfigMap + Secret + Deployment + Service | notification-service | qatra/notification-service:latest |
| `06-jaeger.yaml` | Deployment + Service | jaeger | jaegertracing/all-in-one:1.57 |
| `07-prometheus.yaml` | ConfigMap + PVC + Deployment + Service | prometheus | prom/prometheus:v2.53.0 |
| `08-loki.yaml` | ConfigMap + StatefulSet + Service | loki | grafana/loki:3.1.0 |
| `09-promtail.yaml` | ConfigMap + DaemonSet + ServiceAccount + RBAC | promtail | grafana/promtail:3.1.0 |
| `10-grafana.yaml` | ConfigMaps + Secret + StatefulSet + Service | grafana | grafana/grafana:11.1.0 |
| `11-redisinsight.yaml` | Deployment + Service | redisinsight | redis/redisinsight:latest |
| `12-ingress.yaml` | 5x IngressRoute (Traefik) | various | -- |
| `13-auth-middleware.yaml` | Secret + Middleware (Traefik) | monitoring-basic-auth | -- |
| `14-kubernetes-dashboard.yaml` | ServiceAccount + RBAC + IngressRoute | admin-user | -- |
| `15-pgadmin.yaml` | Deployment + Service | pgadmin | dpage/pgadmin4:latest |

---

## PostgreSQL

- **Image:** postgres:16-alpine, 1 replica
- **Credentials:** postgres/postgres (superuser), qatra/qatra (donation DB), qatra_notification/qatra_notification (notification DB)
- **Storage:** 1Gi PVC via volumeClaimTemplates
- **Init Script:** Creates users and databases via init.sql mounted to /docker-entrypoint-initdb.d
- **Health checks:** pg_isready for readiness and liveness
- **Service:** Headless (clusterIP: None), port 5432

---

## Kafka

- **Image:** confluentinc/cp-kafka:7.6.0, 1 replica
- **KRaft mode** (no Zookeeper): KAFKA_PROCESS_ROLES=broker,controller
- **Cluster ID:** lQ4nHJn3TkS1IGtmNgMn5A
- **Listeners:** PLAINTEXT on 9092, CONTROLLER on 9093
- **Advertised:** kafka-0.kafka.qatra.svc.cluster.local:9092
- **Storage:** 5Gi PVC
- **Service:** Headless, ports 9092 and 9093

---

## Redis

- **Image:** redis:7-alpine, 1 replica, no authentication
- **Storage:** 512Mi PVC
- **Service:** Headless, port 6379

---

## Application Services

### Donation Service
- **ConfigMap** key settings:
  - PostgreSQL: jdbc:postgresql://postgres:5432/qatra / user: qatra
  - Kafka bootstrap: kafka-0.kafka.qatra.svc.cluster.local:9092
  - Redis: host redis, port 6379, cache type redis
  - Kafka topics: password.reset, email.verification, notification.result, eligibility.reminder
  - JWT Secret: QatraSecretKeyMustBeAtLeast256BitsLongForHS256AlgorithmMinimum
  - CORS origins: https://qatra.zayenha.app, https://qtra-api.zayenha.app, https://qtra-ws.zayenha.app
  - OTLP tracing: sends to http://jaeger:4318 via HTTP/protobuf
- **Deployment:** imagePullPolicy: Never (pre-pulled into k3s), port 8080, health probes via /actuator/health
- **Service:** ClusterIP, port 8080

### Notification Service
- **ConfigMap** key settings:
  - PostgreSQL: jdbc:postgresql://postgres:5432/qatra_notification / user: qatra_notification
  - Kafka: same bootstrap server, topic notification.result
  - Email: provider resend
  - OTLP tracing: same Jaeger endpoint
- **Secret:** notification-service-secrets (Resend API key, email from address, Gmail app password)
- **Deployment:** port 8082, loads ConfigMap and Secret via envFrom
- **Service:** ClusterIP, port 8082 (HTTP) and port 8081 mapped to 8082 (WebSocket alias)

---

## Ingress (Traefik)

### Routes

| IngressRoute | Host | Path | Backend | Port | Auth |
|---|---|---|---|---|---|
| api-ingress (priority 10) | qtra-api.zayenha.app | /api/v1/notifications | notification-service | 8082 | JWT |
| api-ingress | qtra-api.zayenha.app | /api/v1 | donation-service | 8080 | JWT |
| ws-ingress | qtra-ws.zayenha.app | /ws | notification-service | 8081 | JWT |
| grafana-ingress | qtra-grafana.zayenha.app | / | grafana | 3000 | Basic Auth |
| jaeger-ingress | qtra-jaeger.zayenha.app | / | jaeger | 16686 | Basic Auth |
| redisinsight-ingress | qtra-redis.zayenha.app | / | redisinsight | 5540 | Basic Auth |
| pgadmin-ingress | qtra-pg.zayenha.app | / | pgadmin | 5050 | Basic Auth |

All routes use Traefik IngressRoute CRD with websecure entrypoint and letsencrypt certResolver.

### Auth Middleware
- Traefik basicAuth referencing a Secret with htpasswd file
- Applied to Grafana, Jaeger, RedisInsight, and pgAdmin ingresses (not API endpoints)

### Kubernetes Dashboard
- Host: qtra-k3s.zayenha.app -> kubernetes-dashboard-kong-proxy:443
- Token-based auth (create via CLI)

---

## External URLs Summary

| URL | Service | Auth |
|-----|---------|------|
| https://qatra.zayenha.app | Frontend (nginx/static) | None |
| https://qtra-api.zayenha.app/api/v1/* | Donation Service | JWT |
| https://qtra-api.zayenha.app/api/v1/notifications/* | Notification Service | JWT |
| https://qtra-ws.zayenha.app/ws | Notification Service WebSocket | JWT |
| https://qtra-grafana.zayenha.app | Grafana | Basic Auth |
| https://qtra-jaeger.zayenha.app | Jaeger | Basic Auth |
| https://qtra-redis.zayenha.app | RedisInsight | Basic Auth |
| https://qtra-pg.zayenha.app | pgAdmin | Basic Auth |
| https://qatra-k3s.zayenha.app | Kubernetes Dashboard | Token Auth |

Internal-only (ClusterIP): PostgreSQL:5432, Kafka:9092/9093, Redis:6379, Prometheus:9090, Loki:3100, Promtail:9080

---

## Monitoring Stack

### Grafana

#### Datasources (provisioned)
1. **Prometheus** (default): http://prometheus:9090
2. **Loki**: http://loki:3100, with derived field linking trace_id regex to Jaeger
3. **Jaeger**: http://jaeger:16686

#### Dashboard: Qatra Overview (~30 panels)
| Row | Key Metrics |
|-----|-------------|
| Overview | Service UP/DOWN status, uptime, CPU usage |
| HTTP Requests | Request rate, rate by endpoint, status code breakdown, error rates (4xx+5xx) |
| Kafka | Consumer records/s, bytes/s, fetch latency, producer send rate, records lag, rebalance total |
| Database | HikariCP connections (active/idle/pending), acquire time, usage time, connection timeout rate |
| JVM | Heap/non-heap memory, threads, GC pause time, JIT compilation time |
| Logs | Log panel querying Loki with service and content filters |

#### Dashboard: Qatra Logs (7 panels)
| Row | Panel | Description |
|-----|-------|-------------|
| Volume | Log Volume by Service, by Level, Error/Warn Rate, Top Sources | Log volume metrics |
| Error Logs | Error Logs | Filtered to error/fatal/panic |
| All Logs | All Logs | Full log stream with content filter |
| Trace-Correlated | Logs with Trace ID | JSON-parsed logs with trace_id, includes Jaeger deep-link |

#### Dashboard Provisioning
- Provider "Qatra", file-based from /var/lib/grafana/dashboards, editable
- Datasource provisioning with hardcoded UIDs

---

## Nginx Reverse Proxy

### API Reverse Proxy (nginx.conf) - for local Docker Compose
| Path | Backend | Notes |
|------|---------|-------|
| /api/v1/notifications | notification-api (:8082) | Standard proxy headers |
| /ws/notifications | notification-api (:8082) | WebSocket upgrade, 24h timeouts |
| /api/ | donation-api (:8080) | Standard proxy headers |
| /health | donation-api/actuator/health | Health check alias |
| / | redirects to /health | 302 redirect |

### Frontend SPA (frontend.conf)
- Server: qatra.zayenha.app, root /var/www/qatra
- SPA fallback: try_files $uri $uri/ /index.html
- Assets cached 1 year with immutable directive

---

## Prometheus

### In-Cluster Config (ConfigMap)
- Scrape interval: 15s, evaluation interval: 15s
- 6 scrape jobs:
  1. prometheus -> localhost:9090
  2. donation-service -> donation-service:8080/actuator/prometheus
  3. notification-service -> notification-service:8082/actuator/prometheus
  4. kafka -> kafka-0.kafka.qatra.svc.cluster.local:9092
  5. redis -> redis:6379
  6. postgres -> postgres:5432
- PVC: 5Gi prometheus-data
- Retention: 30 days

---

## Loki

### Config
- Auth disabled, HTTP port 3100
- Storage: filesystem (chunks/rules)
- Schema: TSDB v13, index period 24h
- Limits: structured metadata enabled, volume enabled
- Ingestion: chunk target size 10MB, idle 30m, max age 1h, WAL at /loki/wal
- Retention: 168h (7 days)

### Promtail
- In-cluster: DaemonSet collecting from /var/log/pods/*/*/*.log with CRI pipeline
- Docker Compose: docker_sd_configs (Docker socket discovery)
- Trace correlation pipeline: regex extracts trace_id and span_id from log lines

---

## Secrets Management

### Kubernetes Secrets (in manifests)
| Secret | Contents |
|---|---|
| notification-service-secrets | Resend API key (placeholder), email from address, Gmail app password |
| grafana-admin | admin-user: admin, admin-password: admin |
| monitoring-auth | htpasswd with SHA-hashed users: salim and admin |

### ConfigMaps with Sensitive Data
| ConfigMap | Sensitive Values |
|---|---|
| donation-service-config | JWT_SECRET |
| notification-service-config | Same JWT_SECRET |
| postgres-init | Database passwords |

### CI/CD Secrets (GitHub Actions)
| Secret | Purpose |
|---|---|
| SERVER_HOST | Server IP/hostname for SSH |
| SERVER_USER | SSH username |
| SERVER_SSH_KEY | SSH private key |

---

## Credentials Reference

| Service | Credentials |
|---|---|
| Grafana | admin / admin |
| Jaeger | No built-in auth (Traefik basic auth only) |
| RedisInsight | No built-in auth |
| PostgreSQL | postgres/postgres (superuser), qatra/qatra, qatra_notification/qatra_notification |
| Redis | No auth |
| Kafka | No auth |
| pgAdmin | admin@zayenha.app / admin |

---

## Deployment Pipeline

### deploy.sh (8-step deployment)
1. **Install cert-manager**: cert-manager v1.15.1 + ClusterIssuer (letsencrypt, ACME HTTP-01)
2. **Import Docker images**: Pull from ghcr.io, tag, import into k3s containerd
3. **Create namespace**: apply 00-namespace.yaml
4. **Deploy infrastructure**: Postgres, Kafka, Redis (with kubectl wait for readiness)
5. **Deploy application services**: donation-service, notification-service
6. **Deploy monitoring stack**: Jaeger, Prometheus, Loki, Promtail, Grafana, RedisInsight
7. **Configure ingress**: auth middleware, then ingress routes
8. **Deploy Kubernetes Dashboard**: via Helm chart (v7.14.0), then RBAC + IngressRoute

### CI/CD Pipeline (.github/workflows/deploy.yml)
- Trigger: Push to master or qatra-pp branches
- Steps: SCP k3s/* to server -> SSH to run `sudo k3s kubectl apply -f /tmp/qatra-infra/k3s/`

---

## Architecture Diagram

```
Internet
  |
  v
Traefik (k3s built-in, Let's Encrypt TLS)
  |
  +-- qatra.zayenha.app ---------> Frontend (nginx static)
  +-- qtra-api.zayenha.app ------+
  |   /api/v1/notifications      +-> Notification Service (:8082)
  |   /api/v1/*                  +-> Donation Service (:8080)
  +-- qtra-ws.zayenha.app -------> Notification Service WebSocket (:8081->8082)
  +-- qtra-grafana.zayenha.app --> Grafana (:3000) [Basic Auth]
  +-- qtra-jaeger.zayenha.app ---> Jaeger (:16686) [Basic Auth]
  +-- qtra-redis.zayenha.app ----> RedisInsight (:5540) [Basic Auth]
  +-- qtra-pg.zayenha.app -------> pgAdmin (:5050) [Basic Auth]
  +-- qatra-k3s.zayenha.app -----> K8s Dashboard [Token Auth]

Inside Cluster (qatra namespace):
  Donation Service --[Kafka]--> Notification Service
  Donation Service --[JDBC]--> PostgreSQL
  Donation Service --[Redis]--> Redis (cache)
  Notification Service --[JDBC]--> PostgreSQL
  Notification Service --[OTLP]--> Jaeger (tracing)
  Donation Service --[OTLP]--> Jaeger (tracing)
  Both services --[/actuator/prometheus]--> Prometheus
  Promtail --[host logs]--> Loki --> Grafana
```
