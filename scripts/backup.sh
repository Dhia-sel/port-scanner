#!/usr/bin/env bash
set -e

# Localisation du dossier racine du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backups"
ARCHIVE_DIR="$PROJECT_DIR/archives"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="old_scans_${TIMESTAMP}.tar.gz"

echo "=========================================="
echo "   ROTATION & NETTOYAGE DES RAPPORTS      "
echo "=========================================="

OLD_COUNT=$(find "$BACKUP_DIR" -type f -mtime +30 | wc -l)

if [ "$OLD_COUNT" -gt 0 ]; then
    echo " $OLD_COUNT rapport(s) de plus de 30 jours détecté(s)."
    find "$BACKUP_DIR" -type f -mtime +30 -print0 | tar -czf "$ARCHIVE_DIR/$ARCHIVE_NAME" --null -T -
    echo "[+] Fichiers archivés dans : $ARCHIVE_DIR/$ARCHIVE_NAME"
    find "$BACKUP_DIR" -type f -mtime +30 -delete
    echo " Fichiers anciens supprimés du dossier backups/."
else
    echo " Tous les rapports dans backups/ ont moins de 30 jours. Aucune action requise."
fi

echo "=========================================="
