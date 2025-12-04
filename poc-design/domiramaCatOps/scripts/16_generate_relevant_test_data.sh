#!/bin/bash
set -euo pipefail
# ============================================
# Script 16 : Génération de Données de Test Pertinentes
# Génère des opérations avec libellés pertinents pour les tests fuzzy search
# ============================================
#
# OBJECTIF :
#   Ce script génère 100-200 opérations avec des libellés pertinents pour
#   chaque requête de test, permettant d'améliorer la pertinence des résultats
#   de recherche vectorielle.
#
# PRÉREQUIS :
#   - HCD démarré
#   - Schéma créé
#   - Python 3.8+ avec cassandra-driver, sentence-transformers, torch
#
# UTILISATION :
#   ./16_generate_relevant_test_data.sh
#
# ============================================

set -euo pipefail

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

if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

PYTHON_DIR="${SCRIPT_DIR}/../examples/python/search"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  📊 Génération de Données de Test Pertinentes"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifications
if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé"
    exit 1
fi

# Créer le script Python temporaire
PYTHON_SCRIPT=$(mktemp)
cat > "$PYTHON_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
"""
Génération de données de test pertinentes pour les tests fuzzy search.
Génère des opérations avec libellés pertinents pour chaque requête de test.
"""

import sys
import random
import json
from datetime import datetime, timedelta
from decimal import Decimal
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement

# Configuration
KEYSPACE = "domiramacatops_poc"
CODE_SI = "6"
CONTRAT = "600000041"

# Libellés pertinents par requête de test
RELEVANT_LIBELLES = {
    "LOYER IMPAYE": [
        "REGULARISATION LOYER IMPAYE PARIS",
        "LOYER IMPAYE MENSUEL APPARTEMENT",
        "LOYER IMPAYE REGULARISATION",
        "LOYER IMPAYE PARIS 15EME",
        "LOYER IMPAYE MAISON",
        "LOYER IMPAYE TRIMESTRE",
        "LOYER IMPAYE APPARTEMENT PARIS",
        "LOYER IMPAYE REGULARISATION MENSUELLE",
        "LOYER IMPAYE LOCATION",
        "LOYER IMPAYE HABITATION",
    ],
    "VIREMENT SALAIRE": [
        "VIREMENT SALAIRE MARS 2024",
        "VIREMENT SALAIRE FEVRIER 2024",
        "VIREMENT SALAIRE JANVIER 2024",
        "VIREMENT SALAIRE MENSUEL",
        "VIREMENT SALAIRE ENTREPRISE",
        "VIREMENT SALAIRE DECEMBRE 2023",
        "VIREMENT SALAIRE NOVEMBRE 2023",
        "VIREMENT SALAIRE OCTOBRE 2023",
        "VIREMENT SALAIRE SEPTEMBRE 2023",
        "VIREMENT SALAIRE AOUT 2023",
    ],
    "PAIEMENT CARTE BANCAIRE": [
        "CB RESTAURANT PARIS",
        "CB SUPERMARCHE PARIS",
        "CB CARREFOUR MARKET",
        "CB PHARMACIE PARIS",
        "CB STATION SERVICE",
        "CB PARKING PARIS",
        "CB CINEMA PARIS",
        "CB SPORT PARIS",
        "CB RESTAURANT BRASSERIE",
        "CB RESTAURANT ITALIEN",
    ],
    "CARREFOUR PARIS": [
        "CB CARREFOUR MARKET PARIS",
        "CB CARREFOUR CITY PARIS 15",
        "CB CARREFOUR EXPRESS PARIS",
        "CB CARREFOUR DRIVE PARIS",
        "RETRAIT DAB CARREFOUR PARIS",
        "CB CARREFOUR HYPERMARCHE PARIS",
        "CB CARREFOUR CONTACT PARIS",
        "CB CARREFOUR MARKET RUE DE VAUGIRARD",
        "CB CARREFOUR PARIS 15EME",
        "CB CARREFOUR PARIS SUD",
    ],
    "RESTAURANT PARIS": [
        "CB RESTAURANT PARIS 15",
        "CB RESTAURANT BRASSERIE PARIS",
        "CB RESTAURANT ITALIEN PARIS",
        "CB RESTAURANT JAPONAIS PARIS",
        "CB RESTAURANT FRANCAIS PARIS",
        "CB RESTAURANT CHINOIS PARIS",
        "CB RESTAURANT THAI PARIS",
        "CB RESTAURANT INDIEN PARIS",
        "CB RESTAURANT GASTRONOMIQUE PARIS",
        "CB RESTAURANT BISTROT PARIS",
    ],
    "SUPERMARCHE": [
        "CB SUPERMARCHE MONOPRIX PARIS",
        "CB SUPERMARCHE INTERMARCHE",
        "CB SUPERMARCHE LECLERC",
        "CB SUPERMARCHE CASINO",
        "CB SUPERMARCHE FRANPRIX",
        "CB SUPERMARCHE ALDI",
        "CB SUPERMARCHE LIDL",
        "CB SUPERMARCHE BIOMONDE",
        "CB SUPERMARCHE NATURALIA",
        "CB SUPERMARCHE GRAND FRAIS",
    ],
    "ASSURANCE HABITATION": [
        "ASSURANCE HABITATION ANNUELLE",
        "PRIME ASSURANCE HABITATION",
        "ASSURANCE HABITATION MENSUELLE",
        "ASSURANCE HABITATION RENOUVELLEMENT",
        "ASSURANCE HABITATION COMPLEMENTAIRE",
        "PRIME ASSURANCE HABITATION TRIMESTRE",
        "ASSURANCE HABITATION APPARTEMENT",
        "ASSURANCE HABITATION MAISON",
        "ASSURANCE HABITATION MULTIRISQUE",
        "ASSURANCE HABITATION ANNUALISEE",
    ],
    "TAXE FONCIERE": [
        "TAXE FONCIERE ANNEE 2024",
        "TAXE FONCIERE TRIMESTRIELLE",
        "TAXE FONCIERE REGULARISATION",
        "TAXE FONCIERE APPARTEMENT",
        "TAXE FONCIERE MAISON",
        "TAXE FONCIERE 2024",
        "TAXE FONCIERE PRELEVEMENT",
        "TAXE FONCIERE MENSUELLE",
        "TAXE FONCIERE REGULARISATION 2024",
        "TAXE FONCIERE ANNUELLE",
    ],
}

# Catégories par type de libellé
CATEGORIES = {
    "LOYER": "HABITATION",
    "VIREMENT": "VIREMENT",
    "CB": "ALIMENTATION",
    "CARREFOUR": "ALIMENTATION",
    "RESTAURANT": "ALIMENTATION",
    "SUPERMARCHE": "ALIMENTATION",
    "ASSURANCE": "HABITATION",
    "TAXE": "DIVERS",
}

def get_category(libelle):
    """Détermine la catégorie à partir du libellé."""
    libelle_upper = libelle.upper()
    for keyword, category in CATEGORIES.items():
        if keyword in libelle_upper:
            return category
    return "DIVERS"

def generate_operations():
    """Génère les opérations avec libellés pertinents."""
    operations = []
    numero_op = 1
    base_date = datetime.now() - timedelta(days=180)  # 6 mois en arrière

    for query, libelles in RELEVANT_LIBELLES.items():
        for libelle in libelles:
            # Générer une date aléatoire sur 6 mois
            days_offset = random.randint(0, 180)
            date_op = base_date + timedelta(days=days_offset)

            # Générer un montant réaliste
            if "LOYER" in libelle.upper():
                montant = Decimal(str(random.uniform(500, 1500)))
            elif "VIREMENT SALAIRE" in libelle.upper():
                montant = Decimal(str(random.uniform(2000, 5000)))
            elif "CB" in libelle or "RESTAURANT" in libelle.upper():
                montant = Decimal(str(random.uniform(20, 150)))
            elif "SUPERMARCHE" in libelle.upper() or "CARREFOUR" in libelle.upper():
                montant = Decimal(str(random.uniform(30, 200)))
            elif "ASSURANCE" in libelle.upper():
                montant = Decimal(str(random.uniform(200, 800)))
            elif "TAXE" in libelle.upper():
                montant = Decimal(str(random.uniform(500, 2000)))
            else:
                montant = Decimal(str(random.uniform(10, 500)))

            operation = {
                "code_si": CODE_SI,
                "contrat": CONTRAT,
                "date_op": date_op,
                "numero_op": numero_op,
                "libelle": libelle,
                "montant": montant,
                "devise": "EUR",
                "date_valeur": date_op,
                "type_operation": "CB" if "CB" in libelle else "VIREMENT" if "VIREMENT" in libelle.upper() else "PRELEVEMENT",
                "sens_operation": "DEBIT" if "CB" in libelle or "TAXE" in libelle.upper() or "ASSURANCE" in libelle.upper() or "LOYER" in libelle.upper() else "CREDIT",
                "cat_auto": get_category(libelle),
                "cat_confidence": Decimal("0.95"),
            }

            operations.append(operation)
            numero_op += 1

    return operations

def main():
    """Fonction principale."""
    print("=" * 70)
    print("  📊 Génération de Données de Test Pertinentes")
    print("=" * 70)
    print()

    # Connexion HCD
    print("📡 Connexion à HCD...")
    cluster = Cluster(['localhost'])
    session = cluster.connect(KEYSPACE)
    print("✅ Connecté à HCD")
    print()

    # Générer les opérations
    print("🔄 Génération des opérations...")
    operations = generate_operations()
    print(f"✅ {len(operations)} opérations générées")
    print()

    # Insérer dans HCD
    print("💾 Insertion dans HCD...")
    insert_query = """
    INSERT INTO operations_by_account (
        code_si, contrat, date_op, numero_op,
        libelle, montant, devise, date_valeur,
        type_operation, sens_operation,
        cat_auto, cat_confidence
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """

    prepared = session.prepare(insert_query)
    inserted = 0

    for op in operations:
        try:
            session.execute(prepared, (
                op["code_si"], op["contrat"], op["date_op"], op["numero_op"],
                op["libelle"], op["montant"], op["devise"], op["date_valeur"],
                op["type_operation"], op["sens_operation"],
                op["cat_auto"], op["cat_confidence"]
            ))
            inserted += 1
            if inserted % 20 == 0:
                print(f"   {inserted}/{len(operations)} opérations insérées...")
        except Exception as e:
            print(f"   ⚠️  Erreur pour '{op['libelle']}': {str(e)}")

    print(f"✅ {inserted} opérations insérées avec succès")
    print()

    # Note sur les embeddings
    print("💡 Note : Les embeddings (ByteT5 et e5-large) doivent être générés séparément")
    print("   Utiliser les scripts de génération d'embeddings pour compléter les données")
    print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Génération terminée !")
    print("=" * 70)

if __name__ == "__main__":
    main()
PYTHON_EOF

# Exécuter le script Python
chmod +x "$PYTHON_SCRIPT"
if python3 "$PYTHON_SCRIPT"; then
    success "✅ Données de test générées avec succès"
else
    error "❌ Erreur lors de la génération"
    rm -f "$PYTHON_SCRIPT"
    exit 1
fi

rm -f "$PYTHON_SCRIPT"

echo ""
success "✅ Script terminé avec succès"
echo ""
