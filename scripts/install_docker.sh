#!/usr/bin/env bash
echo "--- Verification Docker ---"
if command -v docker >/dev/null 2>&1; then
    echo "Docker est deja la."
else
    echo "Installation de Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose-plugin
    sudo usermod -aG docker $USER
    echo "Installation finie."
fi
