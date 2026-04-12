#!/usr/bin/env bash
set -euo pipefail

POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
APISERVER_ADVERTISE_ADDRESS="${APISERVER_ADVERTISE_ADDRESS:-}"

INIT_ARGS=(
  --pod-network-cidr="${POD_CIDR}"
)

if [[ -n "${APISERVER_ADVERTISE_ADDRESS}" ]]; then
  INIT_ARGS+=(--apiserver-advertise-address="${APISERVER_ADVERTISE_ADDRESS}")
fi

echo "[1/6] Initialize control plane"
sudo kubeadm init "${INIT_ARGS[@]}"

echo "[2/6] Configure kubectl for current user"
mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

echo "[3/6] Install Flannel"
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "[4/6] Allow scheduling on control-plane for single-node labs"
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
kubectl taint nodes --all node-role.kubernetes.io/master- || true

echo "[5/6] Wait for pods"
kubectl wait --for=condition=Ready node --all --timeout=180s || true

echo "[6/6] Show cluster status"
kubectl get nodes -o wide
kubectl get pods -A
