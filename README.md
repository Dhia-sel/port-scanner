PScanner : Port Scanner conteneurisé

Application web de scan de ports et de vulnérabilités basée sur Nmap. Un serveur Nginx sert de point d'entrée, une API Flask sécurisée contre les attaques basiques exécute les scans, et une page web permet de choisir le type de scan : Fast, Deep ou Vuln. Chaque scan est enregistré automatiquement. Tout le programme se lance avec un seul script (deploy.sh) via Docker Compose, et des scripts indépendants gèrent la sauvegarde, l'archivage et la supervision.

Usage légal uniquement. Ne scannez que des machines et des réseaux qui vous appartiennent ou pour lesquels vous avez une autorisation écrite. Pour tester, utilisez vos propres machines de laboratoire ou scanme.nmap.org (cible mise à disposition par le projet Nmap). L'auteur décline toute responsabilité en cas d'usage abusif.

Sommaire
Fonctionnalités
Architecture
Structure du projet
Prérequis
Lancement
Utilisation
API REST
Scripts
Sauvegardes et archives
Supervision et logs
CI/CD
Sécurité
Auteur
Fonctionnalités
Page web : saisie de la cible (IP ou domaine) et choix du type de scan
3 types de scan, tous gérés par scan.sh :
Fast : ports les plus courants + détection de versions
Deep : tous les ports (1-65535) + détection de versions
Vuln : détection de vulnérabilités connues (scripts NSE de Nmap)
Résultats lisibles : ports ouverts et vulnérabilités mis en évidence, sortie Nmap brute disponible
Nginx en reverse proxy devant l'API
API Flask sécurisée contre les attaques basiques (voir Sécurité)
Un scan = un rapport enregistré dans backups/
Rotation automatique : les rapports de plus de 30 jours sont compressés et envoyés dans archives/
Supervision : logs de la machine hôte (CPU, mémoire) et des conteneurs enregistrés dans logs/
Déploiement en une commande : deploy.sh lance Docker Compose, suit le déploiement et le teste
CI GitHub Actions : ShellCheck, Flake8, build Docker et test d'intégration
Architecture
text
  Navigateur
      |
      |  HTTP :80
      v
 +---------------+      proxy_pass :5000      +--------------------------+
 |  nexus_nginx  | -------------------------> |  nexus_api               |
 |  (Nginx)      |                            |  Flask + scan.sh + Nmap  |
 +---------------+                            +------------+-------------+
                                                           |
                                          scan             |  rapport
                                    +---------------+      |  scan_*.txt
                                    | Cible         | <----+------> backups/
                                    | autorisée     |
                                    +---------------+
Service	Rôle
nexus_nginx	Point d'entrée HTTP (port 80), reverse proxy vers l'API, timeouts de 600 s pour les scans longs
nexus_api	API Flask (port interne 5000), exécute scan.sh (Nmap), écrit les rapports dans backups/
Structure du projet
text
.
├── app/
│   ├── Dockerfile              # Image de l'API (Python 3.11 + Nmap)
│   └── src/
│       ├── app.py              # API Flask
│       ├── scan.sh             # Scans Fast / Deep / Vuln + rapport
│       ├── requirements.txt    # Dépendances Python
│       └── templates/
│           └── index.html      # Page web du scanner
├── nginx/
│   └── conf.d/
│       └── default.conf        # Configuration du reverse proxy
├── scripts/
│   ├── install_docker.sh       # Installation de Docker
│   ├── deploy.sh               # Lance, suit et teste tout le déploiement
│   ├── backup.sh               # Suivi des backups, archivage après 30 jours
│   └── monitor.sh              # Logs hôte (CPU, mémoire) et conteneurs
├── .github/workflows/ci.yml    # Pipeline CI
├── backups/                    # Un rapport par scan
├── archives/                   # Rapports de plus de 30 jours (compressés)
├── logs/                       # Logs de supervision
├── docker-compose.yml
├── .env
├── .dockerignore
├── .gitignore
└── README.md
Prérequis
Linux (Debian / Ubuntu pour install_docker.sh)
Docker et Docker Compose (plugin docker compose)
Git

Si Docker n'est pas installé :

bash
bash scripts/install_docker.sh
Lancement

Tout le programme se lance via deploy.sh :

bash
git clone https://github.com/Dhia-sel/port-scanner.git
cd port-scanner
bash scripts/deploy.sh

deploy.sh :

construit et démarre les conteneurs (docker compose up -d --build)
affiche l'état des services
teste l'API (/api/health) et confirme le succès du déploiement

Accès : http://localhost

Arrêt :

bash
docker compose down
Utilisation
Ouvrir http://localhost
Saisir une IP ou un nom de domaine autorisé
Choisir le type de scan : Fast, Deep ou Vuln
Lancer le scan et attendre la fin (jusqu'à 10 minutes maximum)
Consulter la synthèse (ports ouverts, vulnérabilités) et la sortie brute
Type	Commande Nmap	Usage
Fast	nmap -F -sV -T4	Ports courants, rapide
Deep	nmap -sV -p- -T4	Tous les ports, plus long
Vuln	nmap -sV --script vuln -T4	Recherche de vulnérabilités
API REST
Méthode	Endpoint	Description
GET	/api/health	État de l'API
POST	/api/scan	Lance un scan
GET	/api/reports	Liste des rapports (du plus récent au plus ancien)
GET	/api/reports/<filename>	Contenu d'un rapport

Valeurs du champ type : fast, full (scan Deep), vuln.

bash
curl -X POST http://localhost/api/scan \
  -H "Content-Type: application/json" \
  -d '{"target": "scanme.nmap.org", "type": "fast"}'
Code	Signification
200	Scan terminé
400	Cible invalide
504	Délai de 10 minutes dépassé
500	Erreur interne
Scripts

deploy.sh lance tout le programme. Les autres scripts s'exécutent indépendamment, à la demande ou via cron.

Script	Rôle
scripts/install_docker.sh	Installe Docker et Compose s'ils sont absents
scripts/deploy.sh	Lance Docker Compose, suit le déploiement et le teste
scripts/backup.sh	Suit les backups et archive ceux de plus de 30 jours
scripts/monitor.sh	Enregistre les logs de la machine et des conteneurs dans logs/

Exemple de planification avec cron :

cron
0 2 * * *    cd /chemin/vers/port-scanner && bash scripts/backup.sh  >> logs/backup.log 2>&1
*/15 * * * * cd /chemin/vers/port-scanner && bash scripts/monitor.sh >> logs/cron-monitor.log 2>&1
Sauvegardes et archives
Chaque scan est enregistré dans backups/ sous la forme scan_<cible>_<AAAAMMJJ_HHMMSS>.txt.
backup.sh surveille backups/ : tout rapport de plus de 30 jours est compressé (old_scans_<date>.tar.gz), envoyé dans archives/, puis supprimé de backups/.
Supervision et logs

monitor.sh produit un fichier horodaté logs/monitor_<date>.log contenant :

l'état des conteneurs Docker
l'utilisation CPU et mémoire de la machine hôte et des conteneurs
les logs système de la machine hôte
les logs des conteneurs (API, Nginx et scans)
un test de réponse de l'API et la détection automatique des erreurs récentes
CI/CD

Le workflow ci.yml s'exécute à chaque push et pull request sur main / master :

Checkout du code
Création des dossiers backups, archives, logs
ShellCheck sur les scripts
Flake8 sur le code Python
Build et lancement avec Docker Compose
Test d'intégration : /api/health doit répondre 200
Arrêt et nettoyage
Sécurité

L'API est protégée contre les attaques basiques :

Validation de la cible : seules les IPv4, noms de domaine et localhost valides sont acceptés (longueur limitée à 253 caractères)
Pas d'injection de commande : Nmap est lancé sans passer par un shell
Protection contre le path traversal : le nom de fichier des rapports est assaini
Timeout de 10 minutes par scan
Nginx comme seul point d'entrée exposé, l'API restant sur le réseau interne Docker

Recommandations d'usage :

Ne pas exposer l'application directement sur Internet (pas d'authentification intégrée)
Ne scanner que des cibles autorisées
Ne jamais committer de secrets dans .env (ignoré par Git et Docker)
Auteur

Dhia
