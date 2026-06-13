#!/bin/bash
# WSL2 Ubuntu 内でセットアップするスクリプト
# setup.ps1 から自動的に呼ばれます。手動実行も可能。
# 引数: docker（デフォルト）または k8s
set -euo pipefail

MODE="${1:-docker}"

echo ""
echo ">>> Docker Engine のインストール"

sudo apt-get update -q
sudo apt-get install -y -q ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -q
sudo apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker "$USER"
echo "    OK: Docker Engine インストール完了"

echo ""
echo ">>> systemd の有効化"

if ! grep -q "\[boot\]" /etc/wsl.conf 2>/dev/null; then
    printf '\n[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf > /dev/null
elif ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
    sudo sed -i '/\[boot\]/a systemd=true' /etc/wsl.conf
fi

sudo systemctl daemon-reload
sudo systemctl enable docker
echo "    OK: systemd 有効化・Docker 自動起動 設定完了"

if [ "$MODE" = "k8s" ]; then
    echo ""
    echo ">>> kubectl のインストール"
    KUBE_MINOR=$(curl -sSL https://dl.k8s.io/release/stable.txt | grep -oP 'v\K[0-9]+\.[0-9]+')
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBE_MINOR}/deb/Release.key" \
        | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v${KUBE_MINOR}/deb/ /" \
        | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    sudo apt-get update -q
    sudo apt-get install -y -q kubectl
    echo "    OK: kubectl インストール完了"

    echo ""
    echo ">>> helm のインストール"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "    OK: helm インストール完了"

    echo ""
    echo ">>> k3d のインストール"
    curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "    OK: k3d インストール完了"

    echo ""
    echo ">>> k9s のインストール"
    wget -q https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb
    sudo apt install -y -q ./k9s_linux_amd64.deb
    rm k9s_linux_amd64.deb
    echo "    OK: k9s インストール完了"
fi

echo ""
echo ">>> WSL 内セットアップ完了"
