#!/bin/bash
set -e

NAMESPACE="qatra"
K3S_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  Qatra k3s Deployment"
echo "============================================"

if ! command -v helm &> /dev/null; then
    echo "ERROR: helm not found. Install with:"
    echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi

if ! command -v k3s &> /dev/null; then
    echo "ERROR: k3s not found. Install with:"
    echo "  curl -sfL https://get.k3s.io | sh -"
    exit 1
fi

if ! k3s kubectl get nodes &> /dev/null; then
    echo "ERROR: k3s not accessible. Check k3s status."
    exit 1
fi

echo ""
echo "[1/8] Installing cert-manager..."


if ! k3s kubectl get namespace cert-manager &> /dev/null 2>&1; then
    k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.yaml
    echo "  -> Waiting for cert-manager pods..."
    k3s kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s
    k3s kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=webhook -n cert-manager --timeout=120s


    cat <<EOF | k3s kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: no-reply.qatra@zayenha.app
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
      - http01:
          ingress:
            ingressClassName: traefik
EOF
    echo "  -> ClusterIssuer created (update email in manifest)"
else
    echo "  -> cert-manager already installed"
fi

echo ""
echo "[2/8] Importing Docker images into k3s..."

GHCR_OWNER=$(echo "${GHCR_OWNER:-jnayeh}" | tr '[:upper:]' '[:lower:]')

echo "  -> Pulling donation-service from ghcr.io..."
docker pull "ghcr.io/$GHCR_OWNER/qatra-donation:latest"
docker tag "ghcr.io/$GHCR_OWNER/qatra-donation:latest" qatra/donation-service:latest
docker save qatra/donation-service:latest | k3s ctr images import -

echo "  -> Pulling notification-service from ghcr.io..."
docker pull "ghcr.io/$GHCR_OWNER/qatra-notification:latest"
docker tag "ghcr.io/$GHCR_OWNER/qatra-notification:latest" qatra/notification-service:latest
docker save qatra/notification-service:latest | k3s ctr images import -

echo ""
echo "[3/8] Creating namespace..."
k3s kubectl apply -f "$K3S_DIR/00-namespace.yaml"

echo ""
echo "[4/8] Deploying infrastructure..."

echo "  -> Postgres..."
k3s kubectl apply -f "$K3S_DIR/01-postgres.yaml"
echo "  -> Waiting for Postgres..."
k3s kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=120s

echo "  -> Kafka..."
k3s kubectl apply -f "$K3S_DIR/02-kafka.yaml"
echo "  -> Waiting for Kafka..."
k3s kubectl wait --for=condition=ready pod -l app=kafka -n $NAMESPACE --timeout=120s

echo "  -> Redis..."
k3s kubectl apply -f "$K3S_DIR/03-redis.yaml"
echo "  -> Waiting for Redis..."
k3s kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=60s

echo ""
echo "[5/8] Deploying application services..."

echo "  -> Donation Service..."
k3s kubectl apply -f "$K3S_DIR/04-donation-service.yaml"
echo "  -> Waiting for Donation Service..."
k3s kubectl wait --for=condition=ready pod -l app=donation-service -n $NAMESPACE --timeout=180s

echo "  -> Notification Service..."
k3s kubectl apply -f "$K3S_DIR/05-notification-service.yaml"
echo "  -> Waiting for Notification Service..."
k3s kubectl wait --for=condition=ready pod -l app=notification-service -n $NAMESPACE --timeout=180s

echo ""
echo "[6/8] Deploying monitoring stack..."

k3s kubectl apply -f "$K3S_DIR/06-jaeger.yaml"
k3s kubectl apply -f "$K3S_DIR/07-prometheus.yaml"
k3s kubectl apply -f "$K3S_DIR/08-loki.yaml"
k3s kubectl apply -f "$K3S_DIR/09-promtail.yaml"
k3s kubectl apply -f "$K3S_DIR/10-grafana.yaml"
k3s kubectl apply -f "$K3S_DIR/11-redisinsight.yaml"

echo "  -> Waiting for monitoring pods..."
k3s kubectl wait --for=condition=ready pod -l app=jaeger -n $NAMESPACE --timeout=120s
k3s kubectl wait --for=condition=ready pod -l app=grafana -n $NAMESPACE --timeout=120s

echo ""
echo "[7/8] Configuring ingress..."
k3s kubectl apply -f "$K3S_DIR/13-auth-middleware.yaml"
k3s kubectl apply -f "$K3S_DIR/12-ingress.yaml"

echo ""
echo "[8/8] Deploying Kubernetes Dashboard..."

echo "  -> Adding Helm repo..."
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update

echo "  -> Installing dashboard via Helm..."
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --create-namespace --namespace kubernetes-dashboard \
  --set app.ingress.enabled=false

echo "  -> Applying RBAC and IngressRoute..."
k3s kubectl apply -f "$K3S_DIR/14-kubernetes-dashboard.yaml"

echo ""
echo "============================================"
echo "  Deployment Complete!"
echo "============================================"
echo ""
echo "  API:          https://qatra-api.zayenha.app"
echo "  WebSocket:    https://qatra-ws.zayenha.app"
echo "  Grafana:      https://qatra-grafana.zayenha.app  (user: admin / pass: admin)"
echo "  Jaeger:       https://qatra-jaeger.zayenha.app"
echo "  Redis:        https://qatra-redis.zayenha.app"
echo "  pgAdmin:      https://qatra-pg.zayenha.app  (user: admin@zayenha.app / pass: admin)"
echo "  Dashboard:    https://qatra-k8s.zayenha.app"
echo ""
echo "  Dashboard login token:"
echo "    kubectl -n kubernetes-dashboard create token admin-user"
echo ""
echo "  Prometheus (internal):"
echo "    kubectl port-forward -n qatra svc/prometheus 9090:9090"
echo ""
echo "  DNS Setup (DigitalOcean):"
echo "    A records → $(curl -s ifconfig.me):"
echo "    - qatra-api.zayenha.app"
echo "    - qatra-ws.zayenha.app"
echo "    - qatra-grafana.zayenha.app"
echo "    - qatra-jaeger.zayenha.app"
echo "    - qatra-redis.zayenha.app"
echo "    - qatra-pg.zayenha.app"
echo "    - qatra-k8s.zayenha.app"
echo ""
echo "  Check status:"
echo "    kubectl get pods -n qatra"
echo "    kubectl get ingressroute -n qatra"
echo "============================================"
