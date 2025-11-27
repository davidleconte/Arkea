#!/bin/bash
# ============================================
# Script 34 (Version Améliorée) : Démonstration REPLICATION_SCOPE
# ============================================
#
# OBJECTIF :
#   Ce script documente l'équivalent REPLICATION_SCOPE HBase avec les consistency
#   levels HCD, permettant de contrôler la réplication et la cohérence des données
#   dans un environnement multi-cluster ou multi-datacenter.
#   
#   Fonctionnalités :
#   - Consistency levels (QUORUM, LOCAL_QUORUM, ONE, ALL, EACH_QUORUM)
#   - Load balancing policies (DatacenterAwareRoundRobinPolicy)
#   - Retry policies (DefaultRetryPolicy)
#   - Exemples Java avec DataStax Java Driver
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Java 11 configuré via jenv
#   - DataStax Java Driver disponible (pour exemples Java)
#
# UTILISATION :
#   ./34_demo_replication_scope_v2.sh
#
# EXEMPLE :
#   ./34_demo_replication_scope_v2.sh
#
# SORTIE :
#   - Documentation des consistency levels
#   - Exemples de configuration pour différents cas d'usage
#   - Exemples Java avec DataStax Driver
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 35: Démonstration DSBulk (./35_demo_dsbulk_v2.sh)
#   - Script 36: Configuration Data API (./36_setup_data_api.sh)
#
# ============================================

set -e

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

code() {
    echo -e "${BLUE}   $1${NC}"
}

highlight() {
    echo -e "${CYAN}💡 $1${NC}"
}

# ============================================
# Configuration
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source environment
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

CQLSH_BIN="/Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3/bin/cqlsh"
CQLSH="$CQLSH_BIN localhost 9042"

# Vérifier que HCD est démarré
info "Vérification que HCD est démarré..."
if ! nc -z localhost 9042 2>/dev/null; then
    error "HCD n'est pas démarré sur localhost:9042"
    error "Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

# ============================================
# Démonstration
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔄 Démonstration Améliorée : REPLICATION_SCOPE + Consistency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Documenter REPLICATION_SCOPE avec consistency levels et drivers Java"
echo ""
info "Améliorations de cette démonstration :"
code "  ✅ Consistency levels (QUORUM, LOCAL_QUORUM, etc.)"
code "  ✅ Policies des drivers (Load Balancing, Retry, etc.)"
code "  ✅ Exemples Java explicites (DataStax Driver)"
code "  ✅ Comparaison avec HBase"
code "  ✅ Cas d'usage avec différents consistency levels"
echo ""

# ============================================
# Partie 1 : REPLICATION_SCOPE HBase vs Réplication HCD
# ============================================

echo ""
info "📋 Partie 1 : REPLICATION_SCOPE HBase vs Réplication HCD"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  REPLICATION_SCOPE HBase                                    │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  Configuration : Par Column Family                          │"
echo "│  REPLICATION_SCOPE => '0' : Pas de réplication              │"
echo "│  REPLICATION_SCOPE => '1' : Réplication activée             │"
echo "│  Consistance : Asynchrone (pas de contrôle)                 │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Réplication HCD/Cassandra                                  │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  Configuration : Au niveau Keyspace                          │"
echo "│  SimpleStrategy : Single datacenter (POC)                   │"
echo "│  NetworkTopologyStrategy : Multi-datacenter (Production)   │"
echo "│  Consistance : Configurable (QUORUM, LOCAL_QUORUM, etc.)    │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "Différence clé :"
code "  ⚠️  HBase : Réplication asynchrone (pas de contrôle consistance)"
code "  ✅ HCD : Réplication avec consistency levels configurables"
echo ""

# ============================================
# Partie 2 : Consistency Levels HCD/Cassandra
# ============================================

echo ""
info "📋 Partie 2 : Consistency Levels HCD/Cassandra"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Consistency Levels (Niveaux de Consistance)                 │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"
echo "│  ONE          : 1 réplica répond                            │"
echo "│  TWO          : 2 réplicas répondent                         │"
echo "│  THREE        : 3 réplicas répondent                         │"
echo "│  QUORUM       : (RF/2 + 1) réplicas répondent                │"
echo "│  LOCAL_QUORUM : QUORUM dans le datacenter local              │"
echo "│  EACH_QUORUM  : QUORUM dans chaque datacenter                │"
echo "│  ALL          : Tous les réplicas répondent                  │"
echo "│  ANY          : N'importe quel réplica (écriture)           │"
echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

code "-- Exemple : Keyspace avec replication_factor = 3"
code "  QUORUM = (3/2 + 1) = 2 réplicas"
code "  ALL = 3 réplicas"
code "  ONE = 1 réplica"
echo ""

code "-- Exemple : Multi-datacenter (paris: 3, lyon: 2)"
code "  LOCAL_QUORUM (datacenter paris) = (3/2 + 1) = 2 réplicas dans paris"
code "  EACH_QUORUM = QUORUM dans paris ET dans lyon"
code "  QUORUM = (5/2 + 1) = 3 réplicas (tous datacenters confondus)"
echo ""

highlight "Avantage vs HBase :"
code "  ✅ Contrôle de la consistance (vs asynchrone HBase)"
code "  ✅ Performance vs Consistance (trade-off configurable)"
code "  ✅ LOCAL_QUORUM pour performance locale (multi-datacenter)"
echo ""

# ============================================
# Partie 3 : Driver Java - Configuration de Base
# ============================================

echo ""
info "📋 Partie 3 : Driver Java - Configuration de Base"
echo ""

code "-- Configuration du Driver Java (DataStax Driver 4.x)"
code ""
code "import com.datastax.oss.driver.api.core.CqlSession;"
code "import com.datastax.oss.driver.api.core.ConsistencyLevel;"
code "import com.datastax.oss.driver.api.core.config.DriverConfigLoader;"
code "import com.datastax.oss.driver.api.core.config.DefaultDriverOption;"
code ""
code "// Créer la session avec consistency level par défaut"
code "CqlSession session = CqlSession.builder()"
code "    .withConfigLoader(DriverConfigLoader.programmaticBuilder()"
code "        .withString(DefaultDriverOption.REQUEST_CONSISTENCY, \"QUORUM\")"
code "        .build())"
code "    .build();"
echo ""

highlight "Configuration par défaut :"
code "  ✅ QUORUM : Bon équilibre performance/consistance"
code "  ✅ Configurable par requête ou globalement"
echo ""

# ============================================
# Partie 4 : Driver Java - Consistency Level par Requête
# ============================================

echo ""
info "📋 Partie 4 : Driver Java - Consistency Level par Requête"
echo ""

code "-- Exemple 1 : Lecture avec QUORUM (consistance forte)"
code ""
code "import com.datastax.oss.driver.api.core.ConsistencyLevel;"
code "import com.datastax.oss.driver.api.core.cql.SimpleStatement;"
code ""
code "SimpleStatement select = SimpleStatement.builder(\"SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ?\")"
code "    .addPositionalValue(\"DEMO_MV\")"
code "    .addPositionalValue(\"DEMO_001\")"
code "    .setConsistencyLevel(ConsistencyLevel.QUORUM)  // Consistance forte"
code "    .build();"
code ""
code "ResultSet result = session.execute(select);"
echo ""

code "-- Exemple 2 : Lecture avec LOCAL_QUORUM (performance locale)"
code ""
code "SimpleStatement selectLocal = SimpleStatement.builder(\"SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ?\")"
code "    .addPositionalValue(\"DEMO_MV\")"
code "    .addPositionalValue(\"DEMO_001\")"
code "    .setConsistencyLevel(ConsistencyLevel.LOCAL_QUORUM)  // Performance locale"
code "    .build();"
code ""
code "ResultSet resultLocal = session.execute(selectLocal);"
echo ""

code "-- Exemple 3 : Écriture avec QUORUM (consistance forte)"
code ""
code "SimpleStatement insert = SimpleStatement.builder(\"INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant) VALUES (?, ?, ?, ?, ?, ?)\")"
code "    .addPositionalValue(\"DEMO_MV\")"
code "    .addPositionalValue(\"DEMO_001\")"
code "    .addPositionalValue(Instant.now())"
code "    .addPositionalValue(1)"
code "    .addPositionalValue(\"VIREMENT SEPA\")"
code "    .addPositionalValue(new BigDecimal(\"1000.00\"))"
code "    .setConsistencyLevel(ConsistencyLevel.QUORUM)  // Consistance forte"
code "    .build();"
code ""
code "session.execute(insert);"
echo ""

highlight "Avantages :"
code "  ✅ Consistance configurable par requête"
code "  ✅ Performance vs Consistance (trade-off)"
code "  ✅ LOCAL_QUORUM pour performance locale (multi-datacenter)"
echo ""

# ============================================
# Partie 5 : Driver Java - Load Balancing Policy
# ============================================

echo ""
info "📋 Partie 5 : Driver Java - Load Balancing Policy"
echo ""

code "-- Configuration Load Balancing Policy (multi-datacenter)"
code ""
code "import com.datastax.oss.driver.api.core.loadbalancing.LoadBalancingPolicy;"
code "import com.datastax.oss.driver.internal.core.loadbalancing.DefaultLoadBalancingPolicy;"
code ""
code "CqlSession session = CqlSession.builder()"
code "    .withConfigLoader(DriverConfigLoader.programmaticBuilder()"
code "        .withString(DefaultDriverOption.LOAD_BALANCING_POLICY_CLASS,"
code "            DefaultLoadBalancingPolicy.class.getName())"
code "        .withString(DefaultDriverOption.REQUEST_CONSISTENCY, \"LOCAL_QUORUM\")"
code "        .build())"
code "    .build();"
echo ""

code "-- Load Balancing Policy : DatacenterAwareRoundRobinPolicy"
code "  → Envoie les requêtes vers le datacenter local en priorité"
code "  → Compatible avec LOCAL_QUORUM pour performance"
echo ""

highlight "Politique recommandée pour multi-datacenter :"
code "  ✅ DatacenterAwareRoundRobinPolicy : Performance locale"
code "  ✅ Compatible avec LOCAL_QUORUM : Pas de latence inter-datacenter"
code "  ✅ Fallback automatique : Si datacenter local indisponible"
echo ""

# ============================================
# Partie 6 : Driver Java - Retry Policy
# ============================================

echo ""
info "📋 Partie 6 : Driver Java - Retry Policy"
echo ""

code "-- Configuration Retry Policy (gestion des erreurs)"
code ""
code "import com.datastax.oss.driver.api.core.retry.RetryPolicy;"
code "import com.datastax.oss.driver.internal.core.retry.DefaultRetryPolicy;"
code ""
code "CqlSession session = CqlSession.builder()"
code "    .withConfigLoader(DriverConfigLoader.programmaticBuilder()"
code "        .withString(DefaultDriverOption.RETRY_POLICY_CLASS,"
code "            DefaultRetryPolicy.class.getName())"
code "        .build())"
code "    .build();"
echo ""

code "-- Retry Policy : Gestion des erreurs de consistance"
code "  → UnavailableException : Retry avec autre datacenter"
code "  → ReadTimeoutException : Retry si consistency level non atteint"
code "  → WriteTimeoutException : Retry si consistency level non atteint"
echo ""

highlight "Politique recommandée :"
code "  ✅ DefaultRetryPolicy : Gestion automatique des erreurs"
code "  ✅ Compatible avec QUORUM/LOCAL_QUORUM : Retry intelligent"
code "  ✅ Fallback automatique : Si consistency level non atteint"
echo ""

# ============================================
# Partie 7 : Cas d'Usage - Multi-Datacenter
# ============================================

echo ""
info "📋 Partie 7 : Cas d'Usage - Multi-Datacenter"
echo ""

code "-- Configuration pour production multi-datacenter"
code "CREATE KEYSPACE domirama2_prod"
code "WITH REPLICATION = {"
code "  'class': 'NetworkTopologyStrategy',"
code "  'paris': 3,   -- Cluster principal (3 réplicas)"
code "  'lyon': 2     -- Cluster secondaire (2 réplicas)"
code "};"
echo ""

code "-- Driver Java : Configuration pour performance locale"
code ""
code "CqlSession session = CqlSession.builder()"
code "    .withConfigLoader(DriverConfigLoader.programmaticBuilder()"
code "        .withString(DefaultDriverOption.REQUEST_CONSISTENCY, \"LOCAL_QUORUM\")"
code "        .withString(DefaultDriverOption.LOAD_BALANCING_LOCAL_DATACENTER, \"paris\")"
code "        .build())"
code "    .build();"
echo ""

highlight "Stratégie recommandée :"
code "  ✅ LOCAL_QUORUM : Performance locale (pas de latence inter-datacenter)"
code "  ✅ Load Balancing : Datacenter local en priorité"
code "  ✅ Équivalent REPLICATION_SCOPE => '1' : Réplication activée"
code "  ✅ Avantage vs HBase : Contrôle de la consistance"
echo ""

# ============================================
# Partie 8 : Comparaison HBase vs HCD (Avec Consistency)
# ============================================

echo ""
info "📊 Partie 8 : Comparaison HBase vs HCD (Avec Consistency)"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Comparaison : REPLICATION_SCOPE vs Réplication HCD          │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"
echo "│  HBase :                                                      │"
echo "│    Réplication : Asynchrone (REPLICATION_SCOPE => '1')        │"
echo "│    Consistance : Pas de contrôle                              │"
echo "│    Performance : Bonne (asynchrone)                           │"
echo "│    Risque      : Données non répliquées immédiatement         │"
echo "│                                                               │"
echo "│  HCD :                                                        │"
echo "│    Réplication : Synchrone (configurable)                    │"
echo "│    Consistance : Configurable (QUORUM, LOCAL_QUORUM, etc.)  │"
echo "│    Performance : Configurable (ONE vs QUORUM vs ALL)        │"
echo "│    Avantage    : Contrôle de la consistance                  │"
echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "Avantages HCD :"
code "  ✅ Consistance configurable : QUORUM, LOCAL_QUORUM, etc."
code "  ✅ Performance vs Consistance : Trade-off configurable"
code "  ✅ LOCAL_QUORUM : Performance locale (multi-datacenter)"
code "  ✅ Contrôle fin : Par requête ou globalement"
echo ""

# ============================================
# Partie 9 : Exemple Complet Java
# ============================================

echo ""
info "📋 Partie 9 : Exemple Complet Java"
echo ""

cat > /tmp/ExempleJavaReplication.java <<'EOF'
package com.arkea.domirama;

import com.datastax.oss.driver.api.core.CqlSession;
import com.datastax.oss.driver.api.core.ConsistencyLevel;
import com.datastax.oss.driver.api.core.config.DriverConfigLoader;
import com.datastax.oss.driver.api.core.config.DefaultDriverOption;
import com.datastax.oss.driver.api.core.cql.SimpleStatement;
import com.datastax.oss.driver.api.core.cql.ResultSet;
import com.datastax.oss.driver.api.core.cql.Row;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Exemple d'utilisation du Driver Java avec consistency levels
 * Équivalent REPLICATION_SCOPE HBase avec contrôle de consistance
 */
public class ExempleJavaReplication {

    public static void main(String[] args) {
        // Configuration du driver avec consistency level par défaut
        CqlSession session = CqlSession.builder()
            .withConfigLoader(DriverConfigLoader.programmaticBuilder()
                .withString(DefaultDriverOption.REQUEST_CONSISTENCY, "QUORUM")
                .withString(DefaultDriverOption.LOAD_BALANCING_LOCAL_DATACENTER, "paris")
                .build())
            .build();

        // Exemple 1 : Lecture avec QUORUM (consistance forte)
        SimpleStatement select = SimpleStatement.builder(
                "SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ?")
            .addPositionalValue("DEMO_MV")
            .addPositionalValue("DEMO_001")
            .setConsistencyLevel(ConsistencyLevel.QUORUM)
            .build();

        ResultSet result = session.execute(select);
        for (Row row : result) {
            System.out.println("Opération: " + row.getString("libelle"));
        }

        // Exemple 2 : Lecture avec LOCAL_QUORUM (performance locale)
        SimpleStatement selectLocal = SimpleStatement.builder(
                "SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ?")
            .addPositionalValue("DEMO_MV")
            .addPositionalValue("DEMO_001")
            .setConsistencyLevel(ConsistencyLevel.LOCAL_QUORUM)  // Performance locale
            .build();

        ResultSet resultLocal = session.execute(selectLocal);

        // Exemple 3 : Écriture avec QUORUM (consistance forte)
        SimpleStatement insert = SimpleStatement.builder(
                "INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant) VALUES (?, ?, ?, ?, ?, ?)")
            .addPositionalValue("DEMO_MV")
            .addPositionalValue("DEMO_001")
            .addPositionalValue(Instant.now())
            .addPositionalValue(1)
            .addPositionalValue("VIREMENT SEPA")
            .addPositionalValue(new BigDecimal("1000.00"))
            .setConsistencyLevel(ConsistencyLevel.QUORUM)  // Consistance forte
            .build();

        session.execute(insert);

        session.close();
    }
}
EOF

info "Exemple Java complet créé : /tmp/ExempleJavaReplication.java"
echo ""

code "-- Points clés de l'exemple :"
code "  ✅ Configuration globale : QUORUM par défaut"
code "  ✅ Configuration par requête : LOCAL_QUORUM pour performance"
code "  ✅ Load Balancing : Datacenter local (paris)"
code "  ✅ Équivalent REPLICATION_SCOPE => '1' : Réplication activée"
code "  ✅ Avantage vs HBase : Contrôle de la consistance"
echo ""

# ============================================
# Partie 10 : Résumé et Conclusion
# ============================================

echo ""
info "📋 Partie 10 : Résumé et Conclusion"
echo ""

echo "✅ Équivalences REPLICATION_SCOPE (version améliorée) :"
echo ""
echo "   1. REPLICATION_SCOPE => '0' (Pas de réplication)"
echo "      → SimpleStrategy avec replication_factor: 1"
echo "      → Consistency Level : ONE (single-node)"
echo "      → Configuration POC actuelle"
echo ""
echo "   2. REPLICATION_SCOPE => '1' (Réplication activée)"
echo "      → NetworkTopologyStrategy avec plusieurs datacenters"
echo "      → Consistency Level : QUORUM ou LOCAL_QUORUM"
echo "      → Configuration production recommandée"
echo ""

echo "🎯 Consistency Levels et Drivers :"
echo ""
echo "   ✅ QUORUM : Consistance forte (recommandé par défaut)"
echo "   ✅ LOCAL_QUORUM : Performance locale (multi-datacenter)"
echo "   ✅ ONE : Performance maximale (risque consistance)"
echo "   ✅ ALL : Consistance maximale (performance réduite)"
echo ""

echo "🎯 Driver Java (DataStax Driver 4.x) :"
echo ""
echo "   ✅ Configuration globale : DriverConfigLoader"
echo "   ✅ Configuration par requête : setConsistencyLevel()"
echo "   ✅ Load Balancing Policy : DatacenterAwareRoundRobinPolicy"
echo "   ✅ Retry Policy : DefaultRetryPolicy"
echo ""

echo "🎯 Avantages vs REPLICATION_SCOPE HBase :"
echo ""
echo "   ✅ Consistance configurable : QUORUM, LOCAL_QUORUM, etc."
echo "   ✅ Performance vs Consistance : Trade-off configurable"
echo "   ✅ LOCAL_QUORUM : Performance locale (multi-datacenter)"
echo "   ✅ Contrôle fin : Par requête ou globalement"
echo "   ✅ Driver Java : Configuration flexible"
echo ""

# Nettoyer
rm -f /tmp/ExempleJavaReplication.java

echo ""
success "✅ Démonstration REPLICATION_SCOPE (version améliorée) terminée"
info ""
info "💡 Améliorations apportées :"
code "  ✅ Consistency levels expliqués (QUORUM, LOCAL_QUORUM, etc.)"
code "  ✅ Driver Java : Configuration et exemples"
code "  ✅ Load Balancing Policy : DatacenterAwareRoundRobinPolicy"
code "  ✅ Retry Policy : DefaultRetryPolicy"
code "  ✅ Exemple Java complet : Code fonctionnel"
code "  ✅ Comparaison avec HBase : Avantages consistance"
echo ""

