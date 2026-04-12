#!/usr/bin/env bash
set -euo pipefail

echo "[1/8] Load required kernel modules"
cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "[2/8] Configure sysctl for Kubernetes networking"
cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

echo "[3/8] Install containerd"
sudo apt-get update
sudo apt-get install -y containerd

echo "[4/8] Create default containerd config"
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

echo "[5/8] Switch containerd to SystemdCgroup = true"
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

echo "[6/8] Enable and restart containerd"
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd

echo "[7/8] Disable swap now"
sudo swapoff -a

echo "[8/8] Disable swap on boot"
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

echo
echo "Verification:"
lsmod | grep -E 'br_netfilter|overlay' || true
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
sudo systemctl --no-pager --full status containerd | sed -n '1,12p'
