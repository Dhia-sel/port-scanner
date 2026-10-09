import os
import re
import subprocess
from flask import Flask, jsonify, render_template, request, send_from_directory

app = Flask(__name__)
BACKUP_DIR = "../../backups" 


def is_valid_target(target):
    if not target or len(target) > 253:
        return False
    pattern = r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$|^localhost$'
    return bool(re.match(pattern, target))


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "service": "Port Scanner API"}), 200


@app.route('/api/scan', methods=['POST'])
def run_scan():
    data = request.get_json() or {}
    target = data.get('target', '').strip()
    scan_type = data.get('type', 'fast').strip()

    if not is_valid_target(target):
        return jsonify({
            "error": "Cible invalide. Fournissez une adresse IP ou un nom de domaine valide.",
            "rawText" : "La cible spécifiée n'est pas valide"
    }), 400

    if scan_type not in ['fast', 'full', 'vuln']:
        scan_type = 'fast'

    script_path = os.path.join(os.path.dirname(__file__), 'scan.sh')

    try:
        result = subprocess.run(
            [script_path, target, scan_type],
            capture_output=True,
            text=True,
            timeout=600)
        output_text = result.stdout if result.stdout else result.stderr
        if not output_text or not output_text.strip():
            output_text = " Aucun résultat retourné par le scan."
    if result.returncode != 0:
            return jsonify({
                "success": False,
                "target": target,
                "type": scan_type,
                "rawText": output_text,
                "output": output_text,
                "error": f"Le script s'est arrêté avec le code d'erreur {result.returncode}."
            }), 400
    return jsonify({
            "success": True,
            "target": target,
            "type": scan_type,
        "rawText": output_text,
            "output": output_text,
            "error": result.stderr if result.returncode != 0 else None
        }), 200

    except subprocess.TimeoutExpired:
        return jsonify({
        "rawText": "Le scan a dépassé le temps limite (10 min).",
        "error": "Timeout"  
    }), 504
    except Exception as e:
        return jsonify({
        "error": f"Erreur système : {str(e)}",
        "rawText": "une erreur interne c'est produite lors de l'exécution"
    }), 500

@app.route('/api/reports', methods=['GET'])
def list_reports():
    if not os.path.exists(BACKUP_DIR):
        return jsonify({"reports": []}), 200
    files = [f for f in os.listdir(BACKUP_DIR) if f.startswith('scan_') and f.endswith('.txt')]
    files.sort(reverse=True)
    return jsonify({"reports": files}), 200


@app.route('/api/reports/<filename>', methods=['GET'])
def get_report(filename):
    safe_filename = os.path.basename(filename)
    filepath = os.path.join(BACKUP_DIR, safe_filename)
    if not os.path.exists(filepath):
        return jsonify({"error": "Rapport non trouvé."}), 404

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        return jsonify({"filename": safe_filename, "content": content}), 200
    except Exception as e:
        return jsonify({"error": f"Erreur de lecture du fichier : {str(e)}"}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
