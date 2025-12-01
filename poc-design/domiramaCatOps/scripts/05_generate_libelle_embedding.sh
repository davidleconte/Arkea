#!/bin/bash
# ============================================
# Script 05c : Génération des Embeddings ByteT5 (Version Didactique)
# Génère les embeddings pour tous les libellés dans HCD
# À exécuter IMMÉDIATEMENT après le chargement des données
# ============================================
set -e

# ============================================
# SOURCE DES FONCTIONS UTILITAIRES
# ============================================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "${SCRIPT_DIR}/../utils/didactique_functions.sh" ]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/../utils/didactique_functions.sh"
else
    # Fallback si le fichier n'existe pas
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    CYAN=$'\033[0;36m'
    MAGENTA=$'\033[0;35m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
    info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
    success() { echo -e "${GREEN}✅ $1${NC}"; }
    warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
    error() { echo -e "${RED}❌ $1${NC}"; }
    demo() { echo -e "${CYAN}🎯 $1${NC}"; }
    code() { echo -e "${MAGENTA}📝 $1${NC}"; }
    section() { echo -e "${BOLD}${CYAN}$1${NC}"; }
    result() { echo -e "${GREEN}📊 $1${NC}"; }
    expected() { echo -e "${YELLOW}📋 $1${NC}"; }
fi

# ============================================
# CONFIGURATION
# ============================================
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/05c_GENERATION_EMBEDDINGS_DEMONSTRATION.md"

# Charger l'environnement POC (HCD déjà installé sur MBP)
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    # shellcheck source=/dev/null
    source "${INSTALL_DIR}/.poc-profile"
fi

# HCD_HOME peut être défini dans .poc-profile
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# ============================================
# VÉRIFICATIONS PRÉALABLES
# ============================================

# Vérifier Python
if ! command -v python3 &> /dev/null; then
    error "Python3 n'est pas installé"
    exit 1
fi

# Optional checks (if helper functions exist)
if type check_hcd_status >/dev/null 2>&1; then
    check_hcd_status || true
fi

if type check_jenv_java_version >/dev/null 2>&1; then
    check_jenv_java_version || true
fi

# ============================================
# VÉRIFICATIONS HCD / SCHEMA / COLONNE
# ============================================
cd "$HCD_DIR"

# Définit Java 11 via jenv si disponible — ne doit pas échouer si jenv absent
if command -v jenv >/dev/null 2>&1; then
    jenv local 11 || true
    eval "$(jenv init -)"
fi

info "🔍 Vérification que HCD est prêt..."

if ! "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" localhost 9042 -e 'SELECT cluster_name FROM system.local;' > /dev/null 2>&1; then
    error "HCD n'est pas prêt ou cqlsh indisponible. Assurez-vous que HCD écoute sur localhost:9042."
    exit 1
fi

# Keyspace name normalization: scripts use domiramaCatOps_poc / domiramacatops_poc inconsistently.
# We'll accept both by checking lowercase variant (Cassandra stores lowercase unless quoted).
KEYSPACE_NAME_LOWER="domiramacatops_poc"

if ! "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" localhost 9042 -e "DESCRIBE KEYSPACE ${KEYSPACE_NAME_LOWER};" > /dev/null 2>&1; then
    error "Le keyspace ${KEYSPACE_NAME_LOWER} n'existe pas. Exécutez d'abord: ./01_setup_domiramaCatOps_keyspace.sh"
    exit 1
fi

# Vérifier la colonne libelle_embedding existe dans la table operations_by_account
COLUMN_EXISTS=$("${HCD_HOME:-$HCD_DIR}/bin/cqlsh" localhost 9042 -e "DESCRIBE TABLE ${KEYSPACE_NAME_LOWER}.operations_by_account;" 2>&1 | grep -c "libelle_embedding" || true)

if [ "${COLUMN_EXISTS}" -eq 0 ]; then
    error "La colonne libelle_embedding n'existe pas dans ${KEYSPACE_NAME_LOWER}.operations_by_account. Exécutez d'abord le script de schema."
    exit 1
fi

# ============================================
# Vérifier et installer dépendances Python si nécessaire
# ============================================
info "🔍 Vérification des dépendances Python (transformers, torch, cassandra-driver)..."

MISSING_PKGS=()
python3 - <<'PY' || true
import sys
missing=[]
try:
    import transformers  # noqa
except Exception:
    missing.append('transformers')
try:
    import torch  # noqa
except Exception:
    missing.append('torch')
try:
    import cassandra  # noqa
except Exception:
    missing.append('cassandra-driver')
if missing:
    print("MISSING:" + ",".join(missing))
    sys.exit(2)
else:
    print("OK")
PY

PY_EXIT=$?

if [ $PY_EXIT -eq 2 ]; then
    warn "⚠️  Certaines dépendances Python sont manquantes. Installation automatique..."
    pip3 install --upgrade pip
    pip3 install transformers torch cassandra-driver --quiet
    success "✅ Dépendances Python installées"
else
    info "✅ Dépendances Python OK"
fi

# ============================================
# EN-TÊTE DIDACTIQUE
# ============================================
echo ""
section "🎯 DÉMONSTRATION DIDACTIQUE : Génération des Embeddings ByteT5"
echo ""
info "📚 Script : génération des embeddings ByteT5 (google/byt5-small)"
echo ""

# ============================================
# GÉNÉRATION DU SCRIPT PYTHON (robuste)
# ============================================
mkdir -p "${SCRIPT_DIR}/../examples/python/embeddings"
PYTHON_SCRIPT="${SCRIPT_DIR}/../examples/python/embeddings/generate_embeddings_domiramaCatOps.py"

info "📝 Création du script Python pour génération des embeddings..."

cat > "$PYTHON_SCRIPT" << 'PYCODE'
#!/usr/bin/env python3
"""
Génère les embeddings ByteT5 (google/byt5-small) pour les lignes de operations_by_account
et met à jour la colonne libelle_embedding.

Usage:
  python3 generate_embeddings_domiramaCatOps.py [--force]

Pré requis:
  - HF_API_KEY dans l'environnement (optionnel si modèle public accessible)
  - transformers, torch et cassandra-driver installés
"""
import os
import sys
import time
import math
import torch
from transformers import AutoTokenizer, AutoModel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from cassandra import ConsistencyLevel

MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
BATCH_SIZE = 100
HF_API_KEY = os.environ.get("HF_API_KEY", None)
FORCE_REGENERATE = "--force" in sys.argv

def load_model():
    print(f'📥 Chargement du modèle {MODEL_NAME}...')
    kwargs = {}
    if HF_API_KEY:
        kwargs["use_auth_token"] = HF_API_KEY
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, **kwargs)
    model = AutoModel.from_pretrained(MODEL_NAME, **kwargs)
    model.eval()
    print(f'✅ Modèle chargé (dimension attendue ~{VECTOR_DIMENSION})')
    return tokenizer, model

def build_text_for_embedding(row):
    parts = []
    lib = getattr(row, "libelle", None)
    if lib:
        lib = lib.strip()
        if lib:
            parts.append(lib)
    cat = getattr(row, "cat_auto", None)
    if cat:
        cat = cat.strip()
        if cat:
            parts.append(f"Catégorie: {cat}")
    typ = getattr(row, "type_operation", None)
    if typ:
        typ = typ.strip()
        if typ:
            parts.append(f"Type: {typ}")
    devise = getattr(row, "devise", None)
    if devise:
        dv = devise.strip().upper()
        if dv and dv != "EUR":
            parts.append(f"Devise: {devise.strip()}")
    if parts:
        return " | ".join(parts)
    return lib if lib else ""

def encode_text(tokenizer, model, text):
    if not text:
        return [0.0] * VECTOR_DIMENSION
    try:
        # Tokenize single string; ensure tensors on cpu (no CUDA assumption)
        inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=512, padding=True)
        
        # ByteT5 is an encoder-decoder model, use encoder only for embeddings
        with torch.no_grad():
            # Get encoder from model (ByteT5 has encoder attribute)
            if hasattr(model, 'encoder'):
                encoder = model.encoder
            elif hasattr(model, 'get_encoder'):
                encoder = model.get_encoder()
            else:
                # Fallback: try direct model call but only with encoder inputs
                encoder = model
            
            # Use only encoder_input_ids (not decoder inputs)
            encoder_inputs = {"input_ids": inputs["input_ids"]}
            if "attention_mask" in inputs:
                encoder_inputs["attention_mask"] = inputs["attention_mask"]
            
            encoder_outputs = encoder(**encoder_inputs)
            
            # Extract embeddings from encoder outputs
            if hasattr(encoder_outputs, "last_hidden_state"):
                vec = encoder_outputs.last_hidden_state.mean(dim=1).squeeze().tolist()
            elif isinstance(encoder_outputs, tuple) and len(encoder_outputs) > 0:
                vec = encoder_outputs[0].mean(dim=1).squeeze().tolist()
            else:
                # Fallback
                vec = encoder_outputs.mean(dim=1).squeeze().tolist()
        
        # Ensure length VECTOR_DIMENSION (best-effort)
        if len(vec) != VECTOR_DIMENSION:
            # pad or truncate
            if len(vec) < VECTOR_DIMENSION:
                vec.extend([0.0] * (VECTOR_DIMENSION - len(vec)))
            else:
                vec = vec[:VECTOR_DIMENSION]
        return vec
    except Exception as e:
        print(f"⚠️ Erreur encodage pour {text[:50]}: {e}")
        return [0.0] * VECTOR_DIMENSION

def main():
    print("🔗 Connexion à HCD (localhost:9042)...")
    cluster = Cluster(['localhost'], port=9042)
    session = cluster.connect()
    # Use keyspace explicitly
    KEYSPACE = os.environ.get("KEYSPACE", "domiramacatops_poc")
    session.set_keyspace(KEYSPACE)
    session.default_consistency_level = ConsistencyLevel.LOCAL_QUORUM
    
    print("📥 Récupération des partitions (code_si, contrat)...")
    partitions = list(session.execute("SELECT DISTINCT code_si, contrat FROM operations_by_account"))
    print(f"✅ {len(partitions)} partition(s) trouvée(s)")
    
    # Prepare select and update statements
    select_prep = session.prepare("""
        SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto, type_operation, devise, libelle_embedding
        FROM operations_by_account WHERE code_si = ? AND contrat = ?
    """)
    
    update_prep = session.prepare("""
        UPDATE operations_by_account SET libelle_embedding = ? WHERE code_si = ? AND contrat = ? AND date_op = ? AND numero_op = ?
    """)
    
    # Collect rows to process
    rows_to_process = []
    for i, p in enumerate(partitions):
        if (i + 1) % 50 == 0:
            print(f"   Partition {i+1}/{len(partitions)}...")
        res = list(session.execute(select_prep, [p.code_si, p.contrat]))
        for r in res:
            if getattr(r, "libelle", None) and str(getattr(r, "libelle")).strip():
                if FORCE_REGENERATE or getattr(r, "libelle_embedding", None) in (None, []):
                    rows_to_process.append(r)
    
    total = len(rows_to_process)
    if total == 0:
        print("✅ Aucune ligne à traiter (tous les libelle_embedding sont présents).")
        session.shutdown()
        cluster.shutdown()
        return
    
    print(f"✅ {total} opération(s) à traiter")
    
    tokenizer, model = load_model()
    
    processed = 0
    updated = 0
    errors = 0
    start = time.time()
    
    # Process in batches
    for i in range(0, total, BATCH_SIZE):
        batch = rows_to_process[i:i+BATCH_SIZE]
        embeddings = []
        for row in batch:
            try:
                text = build_text_for_embedding(row)
                emb = encode_text(tokenizer, model, text)
                embeddings.append((row, emb))
            except Exception as e:
                print(f"⚠️ Erreur encodage pour {getattr(row,'code_si',None)}/{getattr(row,'contrat',None)}: {e}")
                errors += 1
        
        # Update sequentially (CQL batch could be considered but beware batch size limits)
        for row, emb in embeddings:
            try:
                # store embedding as list<float>
                session.execute(update_prep, [emb, row.code_si, row.contrat, row.date_op, row.numero_op])
                updated += 1
            except Exception as e:
                print(f"⚠️ Erreur UPDATE pour {row.code_si}/{row.contrat}: {e}")
                errors += 1
        
        processed += len(batch)
        if processed % (BATCH_SIZE * 2) == 0 or processed == total:
            elapsed = time.time() - start
            rate = processed / elapsed if elapsed > 0 else 0.0
            print(f"Progression: {processed}/{total} ({rate:.1f} op/s)")
    
    elapsed = time.time() - start
    print("✅ Génération terminée !")
    print(f"Traitées: {processed}")
    print(f"Mises à jour: {updated}")
    print(f"Erreurs: {errors}")
    print(f"Temps: {elapsed:.1f}s")
    print(f"Débit: {processed/elapsed:.1f} op/s" if elapsed > 0 else "Débit: 0 op/s")
    
    session.shutdown()
    cluster.shutdown()

if __name__ == "__main__":
    main()
PYCODE

chmod +x "$PYTHON_SCRIPT"
success "✅ Script Python créé : $PYTHON_SCRIPT"
echo ""

# ============================================
# EXÉCUTION DU SCRIPT PYTHON
# ============================================
section "🚀 EXÉCUTION - Génération des embeddings"
echo ""

# Ensure HF_API_KEY set, otherwise script will still attempt without it
if [ -z "${HF_API_KEY:-}" ]; then
    warn "⚠️  HF_API_KEY non définie dans l'environnement; le téléchargement de modèles privés peut échouer."
fi

LOGFILE=$(mktemp /tmp/embeddings_log.XXXXXX)

if [ "${1:-}" = "--force" ]; then
    info "⚠️  Mode régénération forcée activé"
    python3 "$PYTHON_SCRIPT" --force 2>&1 | tee "$LOGFILE"
    PYTHON_EXIT_CODE=${PIPESTATUS[0]:-0}
else
    python3 "$PYTHON_SCRIPT" 2>&1 | tee "$LOGFILE"
    PYTHON_EXIT_CODE=${PIPESTATUS[0]:-0}
fi

# ============================================
# EXTRAIRE STATISTIQUES
# ============================================
PROCESSED_COUNT=$(grep -oE "Traitées: [0-9]+" "$LOGFILE" | grep -oE "[0-9]+" | head -1 || echo "0")
UPDATED_COUNT=$(grep -oE "Mises à jour: [0-9]+" "$LOGFILE" | grep -oE "[0-9]+" | head -1 || echo "0")
ERRORS_COUNT=$(grep -oE "Erreurs: [0-9]+" "$LOGFILE" | grep -oE "[0-9]+" | head -1 || echo "0")
ELAPSED_TIME=$(grep -oE "Temps: [0-9]+(\.[0-9]+)?s" "$LOGFILE" | grep -oE "[0-9]+(\.[0-9]+)?" | head -1 || echo "0")
RATE=$(grep -oE "Débit: [0-9]+(\.[0-9]+)? op/s" "$LOGFILE" | grep -oE "[0-9]+(\.[0-9]+)?" | head -1 || echo "0")

rm -f "$LOGFILE"

if [ "$PYTHON_EXIT_CODE" -eq 0 ]; then
    success "✅ Génération des embeddings terminée"
    result "📊 Statistiques :"
    echo "   - Traitées : $PROCESSED_COUNT opérations"
    echo "   - Mises à jour : $UPDATED_COUNT opérations"
    echo "   - Erreurs : $ERRORS_COUNT"
    echo "   - Temps : ${ELAPSED_TIME}s"
    echo "   - Débit : ${RATE} op/s"
else
    error "❌ Erreur lors de la génération des embeddings (code: $PYTHON_EXIT_CODE)"
    exit 1
fi

# ============================================
# VÉRIFICATION SUR HCD (COMPTE)
# ============================================
section "🔍 Vérification des embeddings générés"

cd "$HCD_DIR"
if command -v jenv >/dev/null 2>&1; then
    jenv local 11 || true
    eval "$(jenv init -)"
fi

EMBEDDED_COUNT=$("${HCD_HOME:-$HCD_DIR}/bin/cqlsh" localhost 9042 -e "SELECT COUNT(*) FROM ${KEYSPACE_NAME_LOWER}.operations_by_account WHERE libelle_embedding IS NOT NULL ALLOW FILTERING;" 2>&1 | sed -n 's/[^0-9]*\([0-9]\+\).*/\1/p' | head -1 || echo "0")

if [ -n "$EMBEDDED_COUNT" ] && [ "$EMBEDDED_COUNT" -gt 0 ]; then
    success "✅ $EMBEDDED_COUNT opération(s) avec embeddings générés"
    result "📊 Vérification :"
    echo "   - Embeddings présents : $EMBEDDED_COUNT opérations"
    echo "   - Colonne : libelle_embedding"
    echo "   - Dimension : 1472"
else
    warn "⚠️  Aucun embedding trouvé (vérifiez la table / la colonne / les permissions)"
fi

# ============================================
# GÉNÉRATION DU RAPPORT MARKDOWN
# ============================================
section "📝 Génération du rapport markdown structuré..."

PROCESSED_COUNT_VAR="$PROCESSED_COUNT" \
UPDATED_COUNT_VAR="$UPDATED_COUNT" \
ERRORS_COUNT_VAR="$ERRORS_COUNT" \
ELAPSED_TIME_VAR="$ELAPSED_TIME" \
RATE_VAR="$RATE" \
EMBEDDED_COUNT_VAR="$EMBEDDED_COUNT" \
python3 <<'PYREPORT' > "$REPORT_FILE"
import os
from datetime import datetime

processed = os.environ.get('PROCESSED_COUNT_VAR', '0')
updated = os.environ.get('UPDATED_COUNT_VAR', '0')
errors = os.environ.get('ERRORS_COUNT_VAR', '0')
elapsed = os.environ.get('ELAPSED_TIME_VAR', '0')
rate = os.environ.get('RATE_VAR', '0')
embedded = os.environ.get('EMBEDDED_COUNT_VAR', '0')

report = f"""# 📝 Démonstration : Génération des Embeddings ByteT5

**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

**Script** : 05_generate_libelle_embedding.sh

**Objectif** : Générer des embeddings ByteT5 pour tous les libellés dans HCD pour la recherche vectorielle

---

## 📋 Résumé d'exécution

- **Traitées** : {processed}

- **Mises à jour** : {updated}

- **Erreurs** : {errors}

- **Temps** : {elapsed}s

- **Débit** : {rate} op/s

- **Embeddings présents (count)** : {embedded}

---

## 📚 Contexte

Modèle : google/byt5-small (embedding dimension ~1472)  

Colonnes combinées pour le texte : `libelle`, `cat_auto`, `type_operation`, `devise` (si différente de EUR)

---

## 🚀 Prochaines étapes

1. Tests de recherche vectorielle (ANN)

2. Tests de recherche hybride (full-text + vector)

3. Monitoring & ré-indexation périodique si nécessaire

---

"""

print(report)
PYREPORT

success "✅ Rapport généré : $REPORT_FILE"
echo ""

success "✅ Génération terminée avec succès !"
info "📝 Documentation générée : $REPORT_FILE"
echo ""
