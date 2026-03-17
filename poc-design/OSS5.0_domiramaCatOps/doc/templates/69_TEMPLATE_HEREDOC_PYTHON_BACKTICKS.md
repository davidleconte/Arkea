# Template 69 : Gestion des Backticks dans Heredoc Python

## Problème

Lors de l'utilisation d'un heredoc Python dans un script shell pour générer du markdown avec des blocs de code (```cql, ```python, etc.), le shell interprète les backticks comme des command substitutions, ce qui provoque des erreurs.

### Symptômes

- Erreur : `bad substitution: no closing "`" in `cql')`
- Erreur : `syntax error near unexpected token`
- Les blocs de code markdown (```cql) n'apparaissent pas dans le rapport généré
- Le rapport contient "**Requête CQL exécutée :**" mais pas le bloc ```cql

### Exemple de code problématique

```bash
# ❌ PROBLÈME : Le shell interprète les backticks
python3 << PYEOF > "$REPORT_FILE"
import json

report = ""
report += "**Requête CQL exécutée :**\n\n"
report += "```cql\n"  # ❌ Le shell essaie d'exécuter une commande
report += "SELECT * FROM table;"
report += "\n```\n\n"
print(report, end='')
PYEOF
```

## Solution

### Méthode 1 : Heredoc avec quotes simples + Variables d'environnement (RECOMMANDÉE)

Utiliser un heredoc avec des quotes simples (`'PYEOF'`) pour empêcher l'interprétation par le shell, et passer les variables shell comme variables d'environnement.

```bash
# ✅ SOLUTION : Heredoc avec quotes simples + variables d'environnement
TEMP_RESULTS_FILE="$TEMP_RESULTS" python3 << 'PYEOF' > "$REPORT_FILE"
import json
import os
from datetime import datetime

# Lire les variables d'environnement
results_file = os.environ.get('TEMP_RESULTS_FILE', '')

# Construire les backticks avec chr(96)
backtick = chr(96)
code_block_start = backtick + backtick + backtick + "cql\n"
code_block_end = "\n" + backtick + backtick + backtick + "\n"

report = ""
report += "**Requête CQL exécutée :**\n\n"
report += code_block_start
report += "SELECT * FROM table;"
report += code_block_end + "\n"

print(report, end='')
PYEOF
```

### Méthode 2 : Variables Python pour les backticks

Si vous devez utiliser un heredoc sans quotes (pour la substitution de variables shell), construire les backticks avec `chr(96)` en Python.

```bash
# ✅ SOLUTION : Utiliser chr(96) pour construire les backticks
python3 << PYEOF > "$REPORT_FILE"
import json

# Construire les backticks avec chr(96)
backtick = chr(96)
code_block_start = backtick + backtick + backtick + "cql\n"
code_block_end = "\n" + backtick + backtick + backtick + "\n"

report = ""
report += "**Requête CQL exécutée :**\n\n"
report += code_block_start
report += "SELECT * FROM table;"
report += code_block_end + "\n"

print(report, end='')
PYEOF
```

## Exemple Complet : Script 30

### Structure du script

```bash
#!/bin/bash

# Variables
TEMP_RESULTS="/tmp/script_30_results_$$.json"
REPORT_FILE="doc/demonstrations/30_DEMONSTRATION.md"

# ... exécution des requêtes et stockage dans TEMP_RESULTS ...

# Génération du rapport
info "Génération du rapport markdown structuré..."

# ✅ SOLUTION : Heredoc avec quotes simples + variables d'environnement
TEMP_RESULTS_FILE="$TEMP_RESULTS" python3 << 'PYEOF' > "$REPORT_FILE"
import json
import sys
import os
from datetime import datetime

# Lire les résultats depuis le fichier JSON
results = []
try:
    results_file = os.environ.get('TEMP_RESULTS_FILE', '')
    if os.path.exists(results_file):
        with open(results_file, 'r', encoding='utf-8') as f:
            content = f.read()
            if content.strip():
                results = json.loads(content)
except Exception as e:
    print(f"Erreur lors de la lecture du JSON : {e}", file=sys.stderr)
    sys.exit(1)

# Construire le rapport
report = ""

for r in results:
    report += f"### Requête {r.get('query_num', '?')}\n\n"

    # Afficher la requête CQL avec backticks
    query_cql = r.get('query_cql', '')
    if query_cql:
        query_cql_str = str(query_cql).strip()
        if query_cql_str:
            # ✅ Utiliser chr(96) pour construire les backticks
            backtick = chr(96)
            code_block_start = backtick + backtick + backtick + "cql\n"
            code_block_end = "\n" + backtick + backtick + backtick + "\n"

            report += "**Requête CQL exécutée :**\n\n"
            report += code_block_start
            report += query_cql_str
            report += code_block_end + "\n"

    # Afficher les résultats
    if r.get('query_output'):
        report += "**Lignes retournées :**\n\n"
        report += "```\n"
        # Filtrer et formater les lignes
        lines = [l.strip() for l in r.get('query_output', '').split('\n') if l.strip()]
        for line in lines[:10]:  # Limiter à 10 lignes
            report += line + "\n"
        if len(lines) > 10:
            report += f"... (affichage limité à 10 lignes sur {len(lines)})\n"
        report += "```\n\n"

# Écrire le rapport
print(report, end='')
PYEOF
```

## Points Clés

1. **Heredoc avec quotes simples** : Utiliser `'PYEOF'` au lieu de `PYEOF` pour empêcher l'interprétation des backticks par le shell
2. **Variables d'environnement** : Passer les variables shell comme variables d'environnement avant le heredoc : `VAR="$value" python3 << 'PYEOF'`
3. **chr(96) pour les backticks** : Utiliser `chr(96)` en Python pour construire les backticks au lieu de les écrire directement
4. **os.environ.get()** : Lire les variables d'environnement dans le script Python avec `os.environ.get('VAR_NAME', '')`

## Vérification

Pour vérifier que la solution fonctionne :

```bash
# Test simple
python3 << 'PYEOF'
backtick = chr(96)
code_block = backtick + backtick + backtick + "cql\nSELECT * FROM table;\n" + backtick + backtick + backtick
print(code_block)
print("Contains ```cql:", "```cql" in code_block)
PYEOF
```

Résultat attendu :
```
```cql
SELECT * FROM table;
```
Contains ```cql: True
```

## Références

- Script 30 : `30_demo_requetes_startrow_stoprow_v2_didactique.sh`
- Rapport généré : `doc/demonstrations/30_STARTROW_STOPROW_REQUETES_DEMONSTRATION.md`
- Date de création : 2024-11-27
