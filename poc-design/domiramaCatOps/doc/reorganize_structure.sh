#!/bin/bash
set -euo pipefail
# ============================================
# Script de Réorganisation : Structure /doc par Catégories
# Basé sur : 26_ANALYSE_REORGANISATION_STRUCTURE.md
# ============================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Compteurs
MOVED=0
UPDATED=0
ERRORS=0

# Créer les répertoires de catégories
info "📁 Création des répertoires de catégories..."
mkdir -p design guides implementation results corrections audits
success "Répertoires créés"

# Fonction pour déterminer la catégorie d'un fichier
get_category() {
    local file="$1"
    local basename=$(basename "$file" .md)
    
    # Audits (priorité haute - vérifier d'abord)
    if [[ "$basename" =~ ^(13|15|17|23|24|25|26)_AUDIT ]] || [[ "$basename" =~ _AUDIT ]]; then
        echo "audits"
    # Corrections
    elif [[ "$basename" =~ ^(16|20|21)_CORRECTION ]] || [[ "$basename" =~ _CORRECTION ]]; then
        echo "corrections"
    # Résultats
    elif [[ "$basename" =~ ^(20|21)_RESULTATS ]] || [[ "$basename" =~ _RESULTATS ]]; then
        echo "results"
    # Implémentations
    elif [[ "$basename" =~ ^(16|20|21)_IMPLEMENTATION ]] || [[ "$basename" =~ _IMPLEMENTATION ]]; then
        echo "implementation"
    # Guides et Index
    elif [[ "$basename" =~ ^(16|18|20)_GUIDE ]] || [[ "$basename" =~ ^18_INDEX ]] || [[ "$basename" =~ _GUIDE ]] || [[ "$basename" =~ _INDEX ]]; then
        echo "guides"
    # Design (par défaut pour analyses, data model, etc.)
    elif [[ "$basename" =~ ^(00|01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|19|26)_ ]] || \
         [[ "$basename" =~ ^(ANALYSE|DATA_MODEL|SYNTHESE|RESUME_EXECUTIF|AUDIT_MECE|MISE_A_JOUR|VERIFICATION|ENRICHISSEMENT|AMELIORATIONS) ]]; then
        echo "design"
    else
        echo "design"  # Par défaut
    fi
}

# Fonction pour mettre à jour les liens dans un fichier
update_links_in_file() {
    local file="$1"
    local old_path="$2"
    local new_path="$3"
    
    # Mettre à jour les liens markdown [texte](chemin)
    sed -i.bak \
        -e "s|(\\([^)]*\\)\\(${old_path//\//\\/}\\))|(\\1${new_path//\//\\/})|g" \
        -e "s|(\\([^)]*\\)\\.\\./doc/${old_path//\//\\/})|(\\1../doc/${new_path//\//\\/})|g" \
        -e "s|(\\([^)]*\\)doc/${old_path//\//\\/})|(\\1doc/${new_path//\//\\/})|g" \
        "$file" 2>/dev/null || true
    
    # Nettoyer les fichiers .bak
    rm -f "${file}.bak" 2>/dev/null || true
}

# Phase 1 : Déplacer les fichiers
info "📦 Phase 1 : Déplacement des fichiers .md..."

for file in *.md; do
    # Ignorer les fichiers dans demonstrations/ et templates/
    if [[ "$file" == "demonstrations" ]] || [[ "$file" == "templates" ]]; then
        continue
    fi
    
    if [ ! -f "$file" ]; then
        continue
    fi
    
    category=$(get_category "$file")
    
    if [ -n "$category" ]; then
        mv "$file" "$category/"
        success "Déplacé : $file → $category/"
        ((MOVED++))
    fi
done

# Phase 2 : Mettre à jour les liens dans tous les fichiers .md
info "🔗 Phase 2 : Mise à jour des liens..."

# Créer un fichier temporaire pour stocker le mapping
MAPPING_FILE=$(mktemp)
trap "rm -f $MAPPING_FILE" EXIT

for category in design guides implementation results corrections audits; do
    if [ -d "$category" ]; then
        for file in "$category"/*.md; do
            if [ -f "$file" ]; then
                old_name=$(basename "$file")
                new_path="$category/$old_name"
                echo "$old_name|$new_path" >> "$MAPPING_FILE"
            fi
        done
    fi
done

# Fonction pour mettre à jour les liens dans un fichier
update_file_links() {
    local file="$1"
    local old_name="$2"
    local new_path="$3"
    
    if [ ! -f "$file" ]; then
        return
    fi
    
    local current_dir=$(dirname "$file")
    local relative_path
    
    # Calculer le chemin relatif
    if [[ "$current_dir" == "." ]]; then
        relative_path="$new_path"
    elif [[ "$current_dir" == *"demonstrations"* ]] || [[ "$current_dir" == *"templates"* ]]; then
        relative_path="../$new_path"
    else
        # Calculer depuis la catégorie
        relative_path="../$new_path"
    fi
    
    # Mettre à jour les liens markdown [texte](chemin)
    if grep -q "$old_name" "$file" 2>/dev/null; then
        # Pattern 1: [texte](fichier.md)
        sed -i.bak "s|(\\([^)]*\\)${old_name//\//\\/})|(\\1${relative_path//\//\\/})|g" "$file" 2>/dev/null || true
        # Pattern 2: [texte](../doc/fichier.md)
        sed -i.bak "s|(\\([^)]*\\)\\.\\./doc/${old_name//\//\\/})|(\\1../doc/${relative_path//\//\\/})|g" "$file" 2>/dev/null || true
        # Pattern 3: [texte](doc/fichier.md)
        sed -i.bak "s|(\\([^)]*\\)doc/${old_name//\//\\/})|(\\1doc/${relative_path//\//\\/})|g" "$file" 2>/dev/null || true
        rm -f "${file}.bak" 2>/dev/null || true
        ((UPDATED++))
    fi
}

# Mettre à jour les liens dans tous les fichiers .md
while IFS='|' read -r old_name new_path; do
    for category in design guides implementation results corrections audits demonstrations templates; do
        if [ -d "$category" ]; then
            for file in "$category"/*.md; do
                if [ -f "$file" ]; then
                    update_file_links "$file" "$old_name" "$new_path"
                fi
            done
        fi
    done
done < "$MAPPING_FILE"

# Phase 3 : Mettre à jour le README principal
info "📝 Phase 3 : Mise à jour du README principal..."
if [ -f "../README.md" ]; then
    # Mettre à jour les références dans le README
    sed -i.bak \
        -e "s|doc/00_ANALYSE_POC|doc/design/00_ANALYSE_POC|g" \
        -e "s|doc/\\([0-9][0-9]\\)_|doc/design/\\1_|g" \
        "../README.md" 2>/dev/null || true
    rm -f "../README.md.bak" 2>/dev/null || true
    success "README mis à jour"
fi

# Phase 4 : Créer un INDEX.md à la racine de /doc
info "📋 Phase 4 : Création de INDEX.md..."
cat > INDEX.md << 'EOF'
# 📑 Index de la Documentation - DomiramaCatOps

**Date** : 2025-01-XX  
**Structure** : Organisation par catégories

---

## 📁 Structure des Catégories

### 🎨 Design et Architecture
Documents de design, analyse, architecture et data model.

**Répertoire** : [`design/`](design/)

**Fichiers principaux** :
- `00_ANALYSE_POC_DOMIRAMA_CAT_OPS.md` - Analyse MECE complète
- `04_DATA_MODEL_COMPLETE.md` - Data model complet
- `13_AUDIT_COMPLET_USE_CASES_MECE.md` - Audit use cases

[Voir tous les fichiers design →](design/)

---

### 📖 Guides et Références
Guides d'utilisation, index et références.

**Répertoire** : [`guides/`](guides/)

**Fichiers principaux** :
- `18_INDEX_USE_CASES_SCRIPTS.md` - Index complet use cases ↔ scripts
- `20_GUIDE_EXECUTION_ORDRE_SCRIPTS.md` - Guide d'exécution des scripts

[Voir tous les guides →](guides/)

---

### 🔧 Implémentations
Documents d'implémentation et de développement.

**Répertoire** : [`implementation/`](implementation/)

**Fichiers principaux** :
- `16_IMPLEMENTATION_EMBEDDINGS_MULTIPLES.md` - Implémentation embeddings
- `20_IMPLEMENTATION_TESTS_P1.md` - Implémentation tests P1

[Voir toutes les implémentations →](implementation/)

---

### 📊 Résultats
Résultats de tests et exécutions.

**Répertoire** : [`results/`](results/)

**Fichiers principaux** :
- `20_RESULTATS_REEXECUTION_TESTS_P1.md` - Résultats tests P1
- `21_RESULTATS_REEXECUTION_TESTS_P2.md` - Résultats tests P2

[Voir tous les résultats →](results/)

---

### 🔧 Corrections
Corrections appliquées.

**Répertoire** : [`corrections/`](corrections/)

**Fichiers principaux** :
- `16_CORRECTION_PAIEMENT_CARTE_CB.md` - Correction CB/Carte
- `20_CORRECTIONS_APPLIQUEES_TESTS_P1.md` - Corrections tests P1

[Voir toutes les corrections →](corrections/)

---

### 🔍 Audits
Audits et analyses complètes.

**Répertoire** : [`audits/`](audits/)

**Fichiers principaux** :
- `13_AUDIT_COMPLET_USE_CASES_MECE.md` - Audit use cases
- `15_AUDIT_SCRIPTS_COMPLET.md` - Audit scripts
- `23_AUDIT_COMPLET_MANQUANTS.md` - Audit manquants
- `24_AUDIT_FICHIERS_OBSOLETES.md` - Audit fichiers obsolètes
- `25_AUDIT_RENOMMAGE_ENRICHISSEMENT.md` - Audit renommage

[Voir tous les audits →](audits/)

---

### 🎬 Démonstrations
Rapports auto-générés des démonstrations.

**Répertoire** : [`demonstrations/`](demonstrations/)

[Voir toutes les démonstrations →](demonstrations/)

---

### 📝 Templates
Templates réutilisables pour scripts didactiques.

**Répertoire** : [`templates/`](templates/)

[Voir tous les templates →](templates/)

---

## 🔍 Navigation Rapide

### Par Type de Document

- **Commencer par** : [`design/00_ANALYSE_POC_DOMIRAMA_CAT_OPS.md`](design/00_ANALYSE_POC_DOMIRAMA_CAT_OPS.md)
- **Guides** : [`guides/18_INDEX_USE_CASES_SCRIPTS.md`](guides/18_INDEX_USE_CASES_SCRIPTS.md)
- **Résultats** : [`results/20_RESULTATS_REEXECUTION_TESTS_P1.md`](results/20_RESULTATS_REEXECUTION_TESTS_P1.md)

### Par Numéro

Les fichiers sont toujours numérotés (00_, 01_, etc.) pour préserver l'ordre chronologique dans chaque catégorie.

---

**Date de création** : 2025-01-XX  
**Version** : 1.0
EOF

success "INDEX.md créé"

# Résumé
echo ""
info "📊 Résumé de la réorganisation :"
success "Fichiers déplacés : $MOVED"
success "Liens mis à jour : $UPDATED"
if [ $ERRORS -gt 0 ]; then
    warn "Erreurs : $ERRORS"
fi

echo ""
success "✅ Réorganisation terminée avec succès !"
info "📋 Consultez INDEX.md pour la navigation"

