#!/usr/bin/env bash
# ============================================================
# NeuralOps — Local kind cluster bootstrap
# Run once: ./bootstrap.sh
# Requires: kind, kubectl, helm installed locally
# ============================================================
set -euo pipefail

CLUSTER_NAME="neuralops-local"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/5] Creating kind cluster (if not already present)..."
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "    Cluster '${CLUSTER_NAME}' already exists, skipping creation."
else
  kind create cluster --config "${SCRIPT_DIR}/cluster-config.yaml"
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo "==> [2/5] Installing metrics-server (needed for HPA to work locally)..."
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args={--kubelet-insecure-tls} \
  --wait

echo "==> [3/5] Installing ingress-nginx (stand-in for ALB locally)..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.hostPort.enabled=true \
  --set controller.service.type=ClusterIP \
  --set-string controller.nodeSelector."ingress-ready"="true" \
  --set-string controller.tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set-string controller.tolerations[0].operator="Exists" \
  --set-string controller.tolerations[0].effect="NoSchedule" \
  --wait

echo "==> [4/5] Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "    Waiting for ArgoCD server to become ready (this can take a couple minutes)..."
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-server

echo "==> [5/5] Fetching initial ArgoCD admin password..."
ARGOCD_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

cat <<EOF

============================================================
 Bootstrap complete.

 ArgoCD:
   Username: admin
   Password: ${ARGOCD_PW}

   Access UI:
     kubectl -n argocd port-forward svc/argocd-server 8081:443
     open https://localhost:8081

 Next steps:
   1. Point ArgoCD at the gitops/ repo (see operators/argocd/app-of-apps.yaml)
   2. Apply namespaces: kubectl apply -f ../gitops/base/namespaces.yaml
   3. Sync the local overlay via ArgoCD or:
        kubectl apply -k ../gitops/overlays/local
============================================================
EOF
