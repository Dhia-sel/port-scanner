#!/bin/bash
echo "___vérification de Docker...___"
if command -v docker >/dev/null 2>&1; then
	echo "Docker déja installé"
else
	echo "Docker n'est pas installé. Installation en cours..."
	sudo apt-get update
	sudo apt-get install -y docker.io docker-compose
	sudo usermod -aG docker $USER
	echo "Installation terminée, déconnecter." 
fi
