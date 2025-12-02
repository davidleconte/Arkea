#!/usr/bin/env bash
set -euo pipefail
# ============================================
# Script 06b : Génération des fichiers Parquet manquants
# Génère acceptation_client.parquet et opposition_categorisation.parquet
# avec des données cohérentes avec les opérations chargées
# ============================================

# Configuration - Utiliser setup_paths si disponible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi

DATA_DIR="${SCRIPT_DIR}/../data/meta-categories"
OUTPUT_DIR="$DATA_DIR"
# Charger l'environnement
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

mkdir -p "$OUTPUT_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📝 GÉNÉRATION DES FICHIERS PARQUET MANQUANTS"
echo "  acceptation_client et opposition_categorisation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Créer le script Python pour générer les fichiers Parquet
PYTHON_SCRIPT=$(mktemp)
cat > "$PYTHON_SCRIPT" << 'PYEOF'
#!/usr/bin/env python3
"""
Génération des fichiers Parquet pour acceptation_client et opposition_categorisation
avec des données cohérentes avec les opérations chargées.
"""
import pandas as pd
import random
from datetime import datetime, timedelta
import uuid

OUTPUT_DIR = "/Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/data/meta-categories"

# Utiliser les mêmes codes SI et contrats que les opérations
CODES_SI = [str(i) for i in range(1, 11)]  # 1 à 10
CONTRATS_PAR_SI = 50
PSE_PAR_CONTRAT = 2

random.seed(42)  # Pour reproductibilité

# ============================================
# TABLE 1 : acceptation_client
# ============================================
print("📝 Génération acceptation_client...")
acceptations = []

for code_si in CODES_SI:
    for i in range(CONTRATS_PAR_SI):
        contrat = f"{code_si}{i:08d}"
        for j in range(PSE_PAR_CONTRAT):
            pse = f"PSE{j+1:03d}"
            accepted = random.random() < 0.8  # 80% acceptent
            # accepted_at = date de la décision client (acceptation OU refus)
            # Toujours renseigné car le client prend une décision à une date donnée
            accepted_at = datetime(2024, 1, 1) + timedelta(days=random.randint(0, 180))
            updated_at = accepted_at + timedelta(days=random.randint(0, 30))

            acceptations.append({
                "code_efs": code_si,
                "no_contrat": contrat,
                "no_pse": pse,
                "accepted": accepted,
                "accepted_at": accepted_at,  # Date de décision (acceptation ou refus)
                "updated_at": updated_at,
                "updated_by": "SYSTEM"
            })

df_acceptations = pd.DataFrame(acceptations)
print(f"✅ {len(df_acceptations)} acceptations générées")

# Sauvegarder en Parquet
parquet_file = f"{OUTPUT_DIR}/acceptation_client.parquet"
df_acceptations.to_parquet(parquet_file, index=False, engine='pyarrow', compression='snappy')
print(f"✅ Fichier Parquet créé : {parquet_file}")

# ============================================
# TABLE 2 : opposition_categorisation
# ============================================
print("\n📝 Génération opposition_categorisation...")
oppositions = []

for code_si in CODES_SI:
    for j in range(PSE_PAR_CONTRAT):
        pse = f"PSE{j+1:03d}"
        opposed = random.random() < 0.1  # 10% opposent
        if opposed:
            opposed_at = datetime(2024, 1, 1) + timedelta(days=random.randint(0, 180))
            updated_at = opposed_at + timedelta(days=random.randint(0, 30))

            oppositions.append({
                "code_efs": code_si,
                "no_pse": pse,
                "opposed": opposed,
                "opposed_at": opposed_at,
                "updated_at": updated_at,
                "updated_by": "SYSTEM"
            })

df_oppositions = pd.DataFrame(oppositions)
print(f"✅ {len(df_oppositions)} oppositions générées")

# Sauvegarder en Parquet
parquet_file = f"{OUTPUT_DIR}/opposition_categorisation.parquet"
df_oppositions.to_parquet(parquet_file, index=False, engine='pyarrow', compression='snappy')
print(f"✅ Fichier Parquet créé : {parquet_file}")

print("\n✅ Génération terminée !")
PYEOF

chmod +x "$PYTHON_SCRIPT"

# Vérifier les dépendances Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 n'est pas installé"
    exit 1
fi

if ! python3 -c "import pandas" 2>/dev/null; then
    echo "⚠️  pandas n'est pas installé, installation..."
    pip3 install pandas pyarrow --quiet
fi

# Exécuter le script Python
echo "🚀 Exécution du script Python..."
python3 "$PYTHON_SCRIPT"

rm -f "$PYTHON_SCRIPT"

echo ""
echo "✅ Fichiers Parquet générés avec succès !"
echo ""
