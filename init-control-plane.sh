#!/usr/bin/env bash
set -euo pipefail

POD_CIDR="${POD_CIDR:-10.32.0.0/12}"
APISERVER_ADVERTISE_ADDRESS="${APISERVER_ADVERTISE_ADDRESS:-}"

INIT_ARGS=(
  --pod-network-cidr="${POD_CIDR}"
)

if [[ -n "${APISERVER_ADVERTISE_ADDRESS}" ]]; then
  INIT_ARGS+=(--apiserver-advertise-address="${APISERVER_ADVERTISE_ADDRESS}")
fi

echo "[1/6] kubeadm init"
sudo kubeadm init "${INIT_ARGS[@]}"

echo "[2/6] Configure kubectl for current user"
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

echo "[3/6] Install Weave Net"
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml"

echo "[4/6] Wait a bit for node network to settle"
sleep 15

echo "[5/6] Optional: allow scheduling on control-plane for single-node labs"
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
kubectl taint nodes --all node-role.kubernetes.io/master- || true

echo "[6/6] Show status"
kubectl get nodes -o wide
kubectl get pods -A
