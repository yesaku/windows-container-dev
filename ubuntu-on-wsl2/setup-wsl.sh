#!/bin/bash
# WSL2 Ubuntu 内で Docker Engine をセットアップするスクリプト
# setup.ps1 から自動的に呼ばれます。手動実行も可能。
set -euo pipefail

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

echo ""
echo ">>> WSL 内セットアップ完了"
