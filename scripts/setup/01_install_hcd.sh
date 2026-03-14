#!/bin/bash
set -euo pipefail

# Script d'installation HCD 1.2.3 (Cross-Platform)
# Basé sur : https://docs.datastax.com/en/hyper-converged-database/1.2/install/install-tarball.html

# Charger la configuration centralisée
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
if [ -f "${ARKEA_HOME}/.poc-config.sh" ]; then
    # shellcheck source=/dev/null
    source "${ARKEA_HOME}/.poc-config.sh"
fi

# Charger les fonctions portables
if [ -f "${ARKEA_HOME}/scripts/utils/portable_functions.sh" ]; then
    # shellcheck source=/dev/null
    source "${ARKEA_HOME}/scripts/utils/portable_functions.sh"
fi

echo "=========================================="
echo "Installation HCD 1.2.3 (Cross-Platform)"
echo "=========================================="
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables (utiliser .poc-config.sh ou fallback)
INSTALL_DIR="${ARKEA_HOME:-${INSTALL_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}}"
export ARKEA_HOME="$INSTALL_DIR"
HCD_VERSION="${HCD_VERSION:-1.2.3}"
HCD_TARBALL="hcd-${HCD_VERSION}-bin.tar.gz"
HCD_DIR="hcd-${HCD_VERSION}"
BINAIRE_DIR="${BINAIRE_DIR:-${INSTALL_DIR}/binaire}"
DATA_DIR="${HCD_DATA_DIR:-${INSTALL_DIR}/hcd-data}"

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier qu'on est dans le bon répertoire
SOFTWARE_DIR="${INSTALL_DIR}/software"
if [ ! -f "${SOFTWARE_DIR}/${HCD_TARBALL}" ]; then
    error "Fichier ${HCD_TARBALL} non trouvé dans ${SOFTWARE_DIR}"
    exit 1
fi

info "Fichier HCD trouvé : ${SOFTWARE_DIR}/${HCD_TARBALL}"

# Étape 1 : Vérifier et configurer Java 11
info "Vérification de Java 11..."

# Vérifier si jenv est installé
JENV_AVAILABLE=false
if command -v jenv &> /dev/null; then
    JENV_AVAILABLE=true
    info "jenv détecté. Configuration Java 11 via jenv..."

    # Initialiser jenv si nécessaire
    eval "$(jenv init -)" 2>/dev/null || true

    # Vérifier si Java 11 est disponible dans jenv
    if jenv versions | grep -q "11"; then
        info "Java 11 trouvé dans jenv. Activation..."
        cd "$INSTALL_DIR"
        jenv local 11
        eval "$(jenv init -)"
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_VERSION" = "11" ]; then
            info "✅ Java 11 activé via jenv : $(java -version 2>&1 | head -n 1)"
            JAVA_HOME=$(jenv prefix 11)
            export JAVA_HOME
        else
            warn "jenv local 11 n'a pas fonctionné. Tentative alternative..."
            JENV_AVAILABLE=false
        fi
    else
        warn "Java 11 non trouvé dans jenv. Vérification Homebrew..."
        JENV_AVAILABLE=false
    fi
fi

# Si jenv n'est pas disponible ou n'a pas fonctionné, utiliser détection automatique
if [ "$JENV_AVAILABLE" = false ]; then
    # Utiliser JAVA_HOME de .poc-config.sh si disponible
    if [ -n "${JAVA_HOME:-}" ] && [ -d "${JAVA_HOME}" ]; then
        info "Java 11 trouvé via configuration : $JAVA_HOME"
        export PATH="$JAVA_HOME/bin:$PATH"
    # macOS : Vérifier Java 11 via Homebrew
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
        if [ -f "${HOMEBREW_PREFIX}/opt/openjdk@11/bin/java" ]; then
            info "Java 11 trouvé via Homebrew : $(${HOMEBREW_PREFIX}/opt/openjdk@11/bin/java -version 2>&1 | head -n 1)"
            if [ -d "${HOMEBREW_PREFIX}/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
                export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
            else
                export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@11"
            fi
            export PATH="$JAVA_HOME/bin:$PATH"
        elif [ -f "/usr/local/opt/openjdk@11/bin/java" ]; then
            info "Java 11 trouvé via Homebrew (Intel) : $(/usr/local/opt/openjdk@11/bin/java -version 2>&1 | head -n 1)"
            if [ -d "/usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
                export JAVA_HOME=/usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home
            else
                export JAVA_HOME=/usr/local/opt/openjdk@11
            fi
            export PATH="$JAVA_HOME/bin:$PATH"
        fi
    fi

    # Vérifier la version Java actuelle
    if [ -z "${JAVA_HOME:-}" ] || ! java -version 2>&1 | grep -q "11"; then
        if command -v java &> /dev/null; then
            JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
            if [ "$JAVA_VERSION" = "11" ]; then
                info "Java 11 déjà actif : $(java -version 2>&1 | head -n 1)"
            else
                warn "Java 11 non détecté. Version actuelle : Java $JAVA_VERSION"
                warn "Installation de Java 11 requise..."

                # macOS : Installer via Homebrew
                if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
                    info "Installation de Java 11 via Homebrew..."
                    brew install openjdk@11
                    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
                    if [ -d "${HOMEBREW_PREFIX}/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
                        export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
                    else
                        export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@11"
                    fi
                    export PATH="$JAVA_HOME/bin:$PATH"
                    info "Java 11 installé. Vérification..."
                    $JAVA_HOME/bin/java -version
                else
                    error "Java 11 non trouvé. Veuillez installer Java 11 manuellement."
                    error "Guide : https://docs.datastax.com/en/hyper-converged-database/1.2/install/install-tarball.html"
                    exit 1
                fi
            fi
        else
            error "Java non installé. Veuillez installer Java 11."
            exit 1
        fi
    fi
fi

# Vérification finale
info "Vérification finale de Java 11..."
java -version
info "JAVA_HOME : $JAVA_HOME"

# Étape 2 : Vérifier Python
info "Vérification de Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    info "Python détecté : $(python3 --version)"

    # Vérifier version Python (3.8-3.11)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

    if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ] && [ "$PYTHON_MINOR" -le 11 ]; then
        info "Version Python compatible (3.8-3.11)"
    else
        warn "Version Python peut-être incompatible (requis: 3.8-3.11)"
    fi
else
    error "Python 3 non installé"
    exit 1
fi

# Étape 3 : Extraire HCD
cd "$INSTALL_DIR"
mkdir -p "$BINAIRE_DIR"

if [ -d "$BINAIRE_DIR/$HCD_DIR" ]; then
    warn "Répertoire $BINAIRE_DIR/$HCD_DIR existe déjà. Suppression..."
    rm -rf "${BINAIRE_DIR:?}/${HCD_DIR:?}"
fi

info "Extraction de ${HCD_TARBALL}..."
tar xvzf "${SOFTWARE_DIR}/${HCD_TARBALL}" -C "$BINAIRE_DIR"

if [ ! -d "$BINAIRE_DIR/$HCD_DIR" ]; then
    error "Échec de l'extraction"
    exit 1
fi

info "HCD extrait dans : ${BINAIRE_DIR}/${HCD_DIR}"

# Étape 4 : Créer les répertoires de données
info "Création des répertoires de données..."
mkdir -p "${DATA_DIR}"/{data,commitlog,saved_caches,hints,cdc_raw}
info "Répertoires créés dans : ${DATA_DIR}"

# Étape 5 : Configurer cassandra.yaml (optionnel)
CASSANDRA_YAML="${BINAIRE_DIR}/${HCD_DIR}/resources/cassandra/conf/cassandra.yaml"
if [ -f "$CASSANDRA_YAML" ]; then
    info "Configuration cassandra.yaml pour utiliser les répertoires personnalisés..."

    # Backup de la configuration originale
    cp "$CASSANDRA_YAML" "${CASSANDRA_YAML}.backup"

    # Mettre à jour les chemins (si l'utilisateur le souhaite)
    # Note: Cette partie nécessite une édition manuelle ou sed
    info "Configuration par défaut conservée. Vous pouvez modifier cassandra.yaml si nécessaire."
else
    warn "Fichier cassandra.yaml non trouvé"
fi

# Étape 6 : Rendre hcd exécutable
info "Configuration des permissions..."
chmod +x "${BINAIRE_DIR}/${HCD_DIR}/bin/hcd"

# Étape 7 : Créer répertoire de logs
mkdir -p "${BINAIRE_DIR}/${HCD_DIR}/logs"
info "Répertoire de logs créé : ${BINAIRE_DIR}/${HCD_DIR}/logs"

# Résumé
echo ""
echo "=========================================="
info "Installation terminée avec succès !"
echo "=========================================="
echo ""
echo "Répertoires créés :"
echo "  - HCD : ${BINAIRE_DIR}/${HCD_DIR}"
echo "  - Données : ${DATA_DIR}"
echo "  - Logs : ${BINAIRE_DIR}/${HCD_DIR}/logs"
echo ""
echo "Pour démarrer HCD :"
echo "  cd ${BINAIRE_DIR}/${HCD_DIR}"
echo "  bin/hcd cassandra"
echo ""
echo "Pour démarrer en arrière-plan :"
echo "  cd ${INSTALL_DIR}/${HCD_DIR}"
echo "  nohup bin/hcd cassandra > hcd.log 2>&1 &"
echo ""
echo "Pour se connecter avec cqlsh :"
echo "  cqlsh localhost 9042"
echo ""
warn "⚠️  IMPORTANT : Changez l'utilisateur cassandra par défaut avant la production !"
echo ""
info "Voir GUIDE_INSTALLATION_HCD_MAC.md pour plus de détails."
