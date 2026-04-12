#!/usr/bin/env bash
set -euo pipefail

K8S_MINOR="${K8S_MINOR:-v1.29}"

echo "[1/6] Install prerequisites"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

echo "[2/6] Prepare keyring directory"
sudo mkdir -p /etc/apt/keyrings

echo "[3/6] Add Kubernetes apt repository key"
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "[4/6] Add Kubernetes apt repository"
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

echo "[5/6] Install kubelet, kubeadm, kubectl"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[6/6] Enable kubelet"
sudo systemctl enable kubelet
sudo systemctl restart kubelet

echo
echo "Verification:"
kubeadm version
kubectl version --client
sudo systemctl --no-pager --full status kubelet | sed -n '1,12p'
