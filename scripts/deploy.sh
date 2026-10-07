#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=========================================="
echo "       DÉPLOIEMENT DE L'APPLICATION       "
echo "=========================================="

echo " Construction et lancement des conteneurs via Docker Compose..."
docker compose up -d --build

echo " Statut des services en cours d'exécution :"
docker compose ps

echo " Vérification de l'accès à l'API (http://localhost/api/health)..."
sleep 3

if curl -s -f http://localhost/api/health > /dev/null; then
    echo "------------------------------------------"
    echo " Déploiement terminé avec succès !"
    echo "Interface Web accessible sur : http://localhost"
    echo "------------------------------------------"
else
    echo "------------------------------------------"
    echo "Attention : Les conteneurs tournent mais l'API n'a pas répondu à temps."
    echo "Exécutez 'docker compose logs -f' pour voir les erreurs."
    echo "------------------------------------------"
fi
