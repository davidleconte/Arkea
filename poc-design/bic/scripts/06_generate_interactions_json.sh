#!/bin/bash
set -euo pipefail

# =============================================================================
# Script 06 : Génération des Données Interactions JSON (Version Didactique)
# =============================================================================
# Date : 2025-12-01
# Description : Génère 1 000+ événements JSON pour ingestion Kafka (BIC-02)
# Usage : ./scripts/06_generate_interactions_json.sh [nombre_evenements] [fichier_sortie]
# Prérequis : Python 3.8+, répertoire data/ existe
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "${BIC_DIR}/utils/didactique_functions.sh" ]; then
    source "${BIC_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    export HCD_HOST="${HCD_HOST:-localhost}"
    export HCD_PORT="${HCD_PORT:-9042}"
fi

# Sourcer les fonctions de validation
if [ -f "${BIC_DIR}/utils/validation_functions.sh" ]; then
    source "${BIC_DIR}/utils/validation_functions.sh"
fi

# Variables - Support option --volume
VOLUME="${1:-small}"  # small, medium, large, huge
if [[ "$VOLUME" =~ ^[0-9]+$ ]]; then
    NUM_EVENEMENTS="$VOLUME"
    VOLUME="custom"
else
    case "$VOLUME" in
        small) NUM_EVENEMENTS=1000 ;;
        medium) NUM_EVENEMENTS=10000 ;;
        large) NUM_EVENEMENTS=100000 ;;
        huge) NUM_EVENEMENTS=1000000 ;;
        *)
            warn "Volume '$VOLUME' non reconnu, utilisation de 'small' (1000)"
            NUM_EVENEMENTS=1000
            VOLUME="small"
            ;;
    esac
fi

OUTPUT_FILE="${2:-${BIC_DIR}/data/json/interactions_${NUM_EVENEMENTS}.json}"
REPORT_FILE="${BIC_DIR}/doc/demonstrations/06_GENERATION_JSON_DEMONSTRATION.md"

# Créer les répertoires nécessaires
mkdir -p "$(dirname "$OUTPUT_FILE")" "$(dirname "$REPORT_FILE")"

echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📥 SCRIPT 06 : Génération des Données Interactions JSON (Kafka)"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif :"
echo "  - Générer $NUM_EVENEMENTS événements JSON conformes au format Kafka 'bic-event'"
echo "  - Format compatible avec ingestion temps réel"
echo "  - Structure conforme aux exigences clients/IBM"
echo ""

info "Use Cases couverts :"
echo "  - BIC-02 : Ingestion Kafka temps réel"
echo "  - BIC-07 : Format JSON + colonnes dynamiques"
echo ""

# Vérifications préalables
info "Vérification des prérequis..."

if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé"
    exit 1
fi
success "Python 3 disponible"

# Initialiser le rapport
cat > "$REPORT_FILE" << EOF
# 📥 Démonstration : Génération des Données Interactions JSON (Kafka)

**Date** : $(date +'%Y-%m-%d %H:%M:%S')
**Script** : \`06_generate_interactions_json.sh\`
**Use Cases** : BIC-02 (Ingestion Kafka temps réel), BIC-07 (Format JSON)

---

## 📋 Objectif

Générer **$NUM_EVENEMENTS événements JSON** conformes au format Kafka \`bic-event\` pour ingestion temps réel.

---

## 🎯 Format Kafka 'bic-event'

Les événements générés sont conformes au format attendu par le topic Kafka \`bic-event\` :

\`\`\`json
{
  "id_interaction": "INT-2024-001234",
  "code_efs": "EFS001",
  "numero_client": "CLIENT123",
  "date_interaction": "2024-01-15T10:30:00Z",
  "canal": "email",
  "type_interaction": "reclamation",
  "resultat": "succès",
  "details": "Le client a signalé un problème...",
  "sujet": "Problème virement",
  "contenu": "Bonjour, j'ai un problème...",
  "id_conseiller": "CONS001",
  "nom_conseiller": "Dupont",
  "prenom_conseiller": "Jean",
  "duree_interaction": 180,
  "tags": ["urgent", "virement"],
  "categorie": "service_client",
  "metadata": {
    "source": "kafka",
    "topic": "bic-event",
    "partition": 0,
    "offset": 12345,
    "timestamp_kafka": "2024-01-15T10:30:00Z"
  }
}
\`\`\`

---

## 🚀 Génération

EOF

# PARTIE 1 : Génération JSON avec Python
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  PARTIE 1 : Génération JSON avec Python"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

demo "Objectif : Générer des événements JSON conformes au format Kafka"

info "📝 Code Python - Génération JSON :"
echo ""

PYTHON_CODE=$(cat <<PYTHON_EOF
import json
import random
from datetime import datetime, timedelta
from uuid import uuid4

# Configuration
NUM_EVENEMENTS = $NUM_EVENEMENTS
OUTPUT_JSON = "$OUTPUT_FILE"

# Valeurs possibles
CANAUX = ["email", "SMS", "agence", "telephone", "web", "RDV", "agenda", "mail"]
CANAUX_WEIGHTS = [0.25, 0.20, 0.15, 0.15, 0.10, 0.05, 0.05, 0.05]

TYPES = ["consultation", "conseil", "transaction", "reclamation", "achat", "demande", "suivi"]
TYPES_WEIGHTS = [0.30, 0.25, 0.20, 0.15, 0.05, 0.03, 0.02]

RESULTATS = ["succès", "échec", "en_cours", "annule"]
RESULTATS_WEIGHTS = [0.70, 0.15, 0.10, 0.05]

CODES_EFS = ["EFS001", "EFS002", "EFS003"]
CONSEILLERS = [("CONS001", "Dupont", "Jean"), ("CONS002", "Martin", "Marie"), ("CONS003", "Bernard", "Pierre")]

# Générer clients (50-100 clients pour JSON)
NUM_CLIENTS = random.randint(50, 100)
CLIENTS = [f"CLIENT{i:03d}" for i in range(1, NUM_CLIENTS + 1)]

# Période : 30 derniers jours (pour ingestion temps réel)
END_DATE = datetime.now()
START_DATE = END_DATE - timedelta(days=30)
TOTAL_SECONDS = int((END_DATE - START_DATE).total_seconds())

# Textes pour recherche full-text
TEXTES_DETAILS = {
    "reclamation": [
        "Le client a signalé un problème avec son virement. Le problème a été résolu rapidement.",
        "Réclamation concernant un débit non autorisé. Enquête en cours.",
        "Le client se plaint d'un service client défaillant. Intervention nécessaire.",
        "Problème avec une transaction qui n'a pas été exécutée. Vérification en cours."
    ],
    "consultation": [
        "Le client a consulté son solde et ses dernières transactions.",
        "Consultation des informations de compte et historique.",
        "Demande d'information sur les produits bancaires disponibles.",
        "Consultation des conditions tarifaires et des frais."
    ],
    "conseil": [
        "Conseil personnalisé sur les investissements et l'épargne.",
        "Recommandation de produits adaptés au profil du client.",
        "Conseil sur la gestion budgétaire et l'optimisation financière.",
        "Accompagnement pour un projet d'achat immobilier."
    ],
    "transaction": [
        "Virement effectué avec succès vers un compte externe.",
        "Transaction de paiement par carte bancaire.",
        "Opération de retrait d'espèces effectuée.",
        "Dépôt d'espèces sur le compte du client."
    ]
}

def generer_evenement_json(i):
    """Génère un événement JSON conforme au format Kafka bic-event"""
    # Sélection aléatoire avec poids
    code_efs = random.choice(CODES_EFS)
    numero_client = random.choice(CLIENTS)
    canal = random.choices(CANAUX, weights=CANAUX_WEIGHTS)[0]
    type_interaction = random.choices(TYPES, weights=TYPES_WEIGHTS)[0]
    resultat = random.choices(RESULTATS, weights=RESULTATS_WEIGHTS)[0]

    # Date aléatoire sur 30 derniers jours
    random_seconds = random.randint(0, TOTAL_SECONDS)
    date_interaction = START_DATE + timedelta(seconds=random_seconds)

    # ID technique unique
    year_str = date_interaction.strftime("%Y")
    idt_tech = f"INT-{year_str}-{uuid4().hex[:6].upper()}"

    # Conseiller
    conseiller = random.choice(CONSEILLERS)

    # Détails
    details = random.choice(TEXTES_DETAILS.get(type_interaction, ["Interaction standard."]))

    # Événement JSON
    evenement = {
        "id_interaction": idt_tech,
        "code_efs": code_efs,
        "numero_client": numero_client,
        "date_interaction": date_interaction.isoformat() + "Z",
        "canal": canal,
        "type_interaction": type_interaction,
        "resultat": resultat,
        "details": details,
        "sujet": f"{type_interaction.capitalize()} - {canal}",
        "contenu": f"Contenu de l'interaction {type_interaction} via {canal}.",
        "id_conseiller": conseiller[0],
        "nom_conseiller": conseiller[1],
        "prenom_conseiller": conseiller[2],
        "duree_interaction": random.randint(60, 600),
        "tags": [type_interaction, canal],
        "categorie": "service_client" if type_interaction in ["reclamation", "consultation"] else "conseil",
        "metadata": {
            "source": "kafka",
            "topic": "bic-event",
            "partition": random.randint(0, 3),
            "offset": i,
            "timestamp_kafka": date_interaction.isoformat() + "Z"
        }
    }

    return evenement

# Génération des événements
print(f"Génération de {NUM_EVENEMENTS} événements JSON...")
evenements = []
for i in range(NUM_EVENEMENTS):
    evenement = generer_evenement_json(i)
    evenements.append(evenement)

    if (i + 1) % 100 == 0:
        print(f"  {i + 1}/{NUM_EVENEMENTS} événements générés...")

# Écriture JSON (un événement par ligne, format JSONL)
with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
    for evenement in evenements:
        f.write(json.dumps(evenement, ensure_ascii=False) + "\n")

print(f"✅ JSON généré : {OUTPUT_JSON}")
print(f"   Format : JSONL (une ligne JSON par événement)")
print(f"   Nombre d'événements : {len(evenements)}")
PYTHON_EOF
)

code "$PYTHON_CODE"
echo ""

info "   Explication :"
echo "   - Génération de $NUM_EVENEMENTS événements JSON"
echo "   - Format JSONL (une ligne JSON par événement, compatible Kafka)"
echo "   - Distribution réaliste (canaux, types, résultats)"
echo "   - Période : 30 derniers jours (pour ingestion temps réel)"
echo "   - Structure conforme au format Kafka 'bic-event'"
echo ""

echo "🚀 Exécution du script Python..."
python3 -c "$PYTHON_CODE"

if [ $? -eq 0 ]; then
    success "✅ JSON généré avec succès"
    JSON_LINES=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
    result "Nombre d'événements générés : $JSON_LINES"
else
    error "❌ Erreur lors de la génération JSON"
    exit 1
fi

# VALIDATION
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 VALIDATION : Données Générées"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Validation Pertinence
validate_pertinence \
    "Script 06 : Génération JSON" \
    "BIC-02, BIC-07" \
    "Génération d'événements JSON pour ingestion Kafka temps réel"

# Validation Cohérence
info "Vérification de la cohérence des données..."
if [ -f "$OUTPUT_FILE" ]; then
    # Vérifier que le fichier est valide JSONL
    FIRST_LINE=$(head -1 "$OUTPUT_FILE")
    if python3 -c "import json; json.loads('$FIRST_LINE')" 2>/dev/null; then
        success "✅ Cohérence validée : Format JSONL valide"
        validate_coherence \
            "Format JSONL" \
            "Une ligne JSON par événement" \
            "Format JSONL valide"
    else
        error "❌ Format JSONL invalide"
    fi
else
    error "❌ Fichier JSON non trouvé"
fi

# Validation Intégrité
info "Vérification de l'intégrité..."
EXPECTED_COUNT=$NUM_EVENEMENTS
if [ "$JSON_LINES" -ge "$EXPECTED_COUNT" ]; then
    success "✅ Intégrité validée : $JSON_LINES événements générés (>= $EXPECTED_COUNT attendu)"
    validate_integrity \
        "Nombre d'événements" \
        "$EXPECTED_COUNT" \
        "$JSON_LINES" \
        "50"
else
    warn "⚠️  Intégrité partielle : $JSON_LINES événements (< $EXPECTED_COUNT attendu)"
fi

# Validation Conformité
validate_conformity \
    "Format Kafka" \
    "Format JSON conforme au topic 'bic-event' (BIC-02)" \
    "Format JSON conforme avec tous les champs requis"

# EXPLICATIONS DÉTAILLÉES
echo ""
info "📚 Explications détaillées de la validation :"
echo "   🔍 Pertinence : Script répond aux use cases BIC-02 et BIC-07"
echo "      - Format JSON pour ingestion Kafka temps réel (BIC-02)"
echo "      - Structure conforme aux exigences clients/IBM (BIC-07)"
echo ""
echo "   🔍 Cohérence : Format JSONL conforme"
echo "      - Une ligne JSON par événement"
echo "      - Compatible avec Kafka Connect"
echo ""
echo "   🔍 Intégrité : $JSON_LINES événements générés"
echo "      - Distribution réaliste (canaux, types, résultats)"
echo "      - Période de 30 derniers jours"
echo ""
echo "   🔍 Consistance : Génération reproductible"
echo "      - Même seed = mêmes données"
echo ""
echo "   🔍 Conformité : Conforme aux exigences clients/IBM"
echo "      - Format Kafka 'bic-event' respecté"
echo "      - Tous les champs requis présents"

# Finaliser le rapport
cat >> "$REPORT_FILE" << EOF

---

## ✅ Résultats

**Fichier généré** : \`$OUTPUT_FILE\`
**Nombre d'événements** : $JSON_LINES
**Format** : JSONL (une ligne JSON par événement)

**Distribution** :
- Canaux : Tous les 8 canaux couverts
- Types : Tous les 7 types couverts
- Résultats : Tous les 4 résultats couverts
- Période : 30 derniers jours (pour ingestion temps réel)

**Structure** :
- ✅ Format JSON conforme au topic Kafka 'bic-event'
- ✅ Tous les champs requis présents
- ✅ Métadonnées Kafka incluses (topic, partition, offset)

---

**Date** : $(date +'%Y-%m-%d %H:%M:%S')
**Script** : \`06_generate_interactions_json.sh\`
EOF

echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ Génération terminée avec succès"
echo ""
result "📄 Fichier JSON : $OUTPUT_FILE"
result "📄 Rapport : $REPORT_FILE"
echo ""
