#!/usr/bin/env bash

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR" || exit  1

LOGS_DIR="$PROJECT_DIR/logs"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MONITOR_LOG_FILE="$LOGS_DIR/monitor_$TIMESTAMP.log"

echo "=========================================="
echo "    SUPERVISION ET AUDIT DU SYSTEME      "
echo "=========================================="
echo -e "\n 1. État des conteneurs Docker..."
docker compose ps

echo -e "\n 2. Consommation des ressources (CPU / RAM / Réseau)..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo -e "\n 3. Test de réponse de l'API..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health || echo "000")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo " API opérationnelle (Statut HTTP : $HTTP_CODE)"
else
    echo " Problème détecté ! L'API répond avec le code : $HTTP_CODE"
fi

echo -e "\n 4. Rassemblement des derniers logs de l'application..."
echo "--- LOGS APPLICATION ET NGINX ($TIMESTAMP) ---" > "$MONITOR_LOG_FILE"
docker compose logs --tail=50 >> "$MONITOR_LOG_FILE"

echo " Les logs récents ont été exportés dans : $MONITOR_LOG_FILE"

echo -e "\n 5. Détection automatique des erreurs récentes..."
ERRORS=$(docker compose logs --tail=100 | grep -iE "error|critical|exception|failed" || true)

if [ -n "$ERRORS" ]; then
    echo " Des avertissements/erreurs ont été détectés dans les logs :"
    echo "$ERRORS"
else
    echo "[OK] Aucune erreur critique trouvée dans les derniers logs."
fi

echo -e "\n=========================================="
