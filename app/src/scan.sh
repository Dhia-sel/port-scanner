#!/usr/bin/env bash

TARGET=$1
SCAN_TYPE=${2:-"fast"}

if [ -z "$TARGET" ]; then 
	echo "Erreur : aucune cible  (IP ou domaine) spécifiée."
	exit 1
fi 

BACKUP_DIR="../../backups"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CLEAN_TARGET=$(echo "$TARGET"  | sed 's/[^a-zA-Z0-9._-]/_/g')
REPORT_FILE="$BACKUP_DIR/scan_${CLEAN_TARGET}_${TIMESTAMP}.txt"


echo "==========================================" | tee "$REPORT_FILE"
echo " Lancement du scan Nmap sur : $TARGET"     | tee -a "$REPORT_FILE"
echo " Type de scan : $SCAN_TYPE"               | tee -a "$REPORT_FILE"
echo " Date : $(date)"                           | tee -a "$REPORT_FILE"
echo "==========================================" | tee -a "$REPORT_FILE"

case "$SCAN_TYPE" in
    "full")
        nmap -sV -p- -T4 "$TARGET" | tee -a "$REPORT_FILE"
        ;;
    "vuln")
        nmap -sV --script vuln -T4 "$TARGET" | tee -a "$REPORT_FILE"
        ;;
    "fast"|*)
        nmap -F -sV -T4 "$TARGET" | tee -a "$REPORT_FILE"
        ;;
esac

echo "" | tee -a "$REPORT_FILE"
echo "Scan terminé. Rapport enregistré dans : $REPORT_FILE" | tee -a "$REPORT_FILE"

