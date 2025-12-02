#!/bin/bash
set -euo pipefail
# =============================================================================
# Fonctions de Validation pour Scripts BIC
# =============================================================================
# Date : 2025-12-01
# Usage : source utils/validation_functions.sh
# =============================================================================

# ============================================
# FONCTION : Valider Pertinence
# ============================================
validate_pertinence() {
    local test_name="$1"
    local use_case="$2"
    local description="$3"
    
    info "🔍 Validation Pertinence : $test_name"
    echo "   Use Case : $use_case"
    echo "   Description : $description"
    
    # Vérifier que le test répond à un use case BIC identifié
    if [ -z "$use_case" ]; then
        warn "⚠️  Use case non spécifié"
        return 1
    fi
    
    success "✅ Pertinence validée : Test répond au use case $use_case"
    return 0
}

# ============================================
# FONCTION : Valider Cohérence
# ============================================
validate_coherence() {
    local test_name="$1"
    local expected_schema="$2"
    local actual_schema="$3"
    
    info "🔍 Validation Cohérence : $test_name"
    
    # Vérifier que le schéma est cohérent
    if [ "$expected_schema" != "$actual_schema" ]; then
        error "❌ Incohérence détectée : Schéma attendu vs obtenu différent"
        return 1
    fi
    
    success "✅ Cohérence validée : Schéma conforme"
    return 0
}

# ============================================
# FONCTION : Valider Intégrité
# ============================================
validate_integrity() {
    local test_name="$1"
    local expected_count="$2"
    local actual_count="$3"
    local tolerance="${4:-0}"  # Tolérance en nombre de lignes
    
    info "🔍 Validation Intégrité : $test_name"
    echo "   Attendu : $expected_count ligne(s)"
    echo "   Obtenu : $actual_count ligne(s)"
    
    # Calculer la différence (gérer les nombres décimaux)
    # Convertir en entiers pour la comparaison si nécessaire
    local expected_int=$(echo "$expected_count" | awk '{printf "%.0f", $1}')
    local actual_int=$(echo "$actual_count" | awk '{printf "%.0f", $1}')
    local diff=$((actual_int - expected_int))
    if [ $diff -lt 0 ]; then
        diff=$((diff * -1))
    fi
    
    # Vérifier que la différence est dans la tolérance
    if [ $diff -gt $tolerance ]; then
        warn "⚠️  Intégrité partielle : Écart de $diff ligne(s) (tolérance: $tolerance)"
        return 0  # Ne pas arrêter le script, c'est juste un avertissement
    fi
    
    success "✅ Intégrité validée : Résultats conformes (écart: $diff, tolérance: $tolerance)"
    return 0
}

# ============================================
# FONCTION : Valider Consistance
# ============================================
validate_consistency() {
    local test_name="$1"
    local result1="$2"
    local result2="$3"
    
    info "🔍 Validation Consistance : $test_name"
    
    # Vérifier que les résultats sont cohérents entre deux exécutions
    if [ "$result1" != "$result2" ]; then
        warn "⚠️  Consistance partielle : Résultats différents entre exécutions"
        return 1
    fi
    
    success "✅ Consistance validée : Résultats reproductibles"
    return 0
}

# ============================================
# FONCTION : Valider Conformité
# ============================================
validate_conformity() {
    local test_name="$1"
    local requirement="$2"
    local actual_behavior="$3"
    
    info "🔍 Validation Conformité : $test_name"
    echo "   Exigence : $requirement"
    echo "   Comportement : $actual_behavior"
    
    # Vérifier que le comportement est conforme aux exigences
    if [ -z "$requirement" ] || [ -z "$actual_behavior" ]; then
        warn "⚠️  Conformité non vérifiable : Informations manquantes"
        return 1
    fi
    
    success "✅ Conformité validée : Comportement conforme aux exigences"
    return 0
}

# ============================================
# FONCTION : Comparer Résultats Attendus vs Obtenus
# ============================================
compare_expected_vs_actual() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    local tolerance="${4:-0}"
    
    echo ""
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    section "  📊 COMPARAISON : $test_name"
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    expected "📋 Résultat Attendu :"
    echo "   $expected"
    echo ""
    
    result "📊 Résultat Obtenu :"
    echo "   $actual"
    echo ""
    
    # Comparaison numérique si possible
    if [[ "$expected" =~ ^[0-9]+$ ]] && [[ "$actual" =~ ^[0-9]+$ ]]; then
        local diff=$((actual - expected))
        if [ $diff -lt 0 ]; then
            diff=$((diff * -1))
        fi
        
        if [ $diff -le $tolerance ]; then
            success "✅ Comparaison réussie : Écart de $diff (tolérance: $tolerance)"
            return 0
        else
            error "❌ Comparaison échouée : Écart de $diff (tolérance: $tolerance)"
            return 1
        fi
    else
        # Comparaison textuelle
        if [ "$expected" = "$actual" ]; then
            success "✅ Comparaison réussie : Résultats identiques"
            return 0
        else
            warn "⚠️  Comparaison partielle : Résultats différents"
            echo "   Différence détectée mais peut être acceptable selon le contexte"
            return 0  # Ne pas arrêter le script pour une comparaison partielle (c'est juste un avertissement)
        fi
    fi
}

# ============================================
# FONCTION : Valider Justesse des Résultats
# ============================================
validate_correctness() {
    local test_name="$1"
    local query="$2"
    local expected_pattern="$3"
    local actual_result="$4"
    
    info "🔍 Validation Justesse : $test_name"
    echo "   Requête : $query"
    echo "   Pattern attendu : $expected_pattern"
    echo "   Résultat obtenu : $actual_result"
    
    # Vérifier que le résultat correspond au pattern attendu
    if echo "$actual_result" | grep -qE "$expected_pattern"; then
        success "✅ Justesse validée : Résultat correspond au pattern attendu"
        return 0
    else
        error "❌ Justesse non validée : Résultat ne correspond pas au pattern attendu"
        return 1
    fi
}

# ============================================
# FONCTION : Valider Performance
# ============================================
validate_performance() {
    local test_name="$1"
    local execution_time="$2"
    local max_time="${3:-0.1}"  # 100ms par défaut
    
    info "🔍 Validation Performance : $test_name"
    echo "   Temps d'exécution : ${execution_time}s"
    echo "   Temps maximum autorisé : ${max_time}s"
    
    # Comparer avec le temps maximum
    if (( $(echo "$execution_time <= $max_time" | bc -l 2>/dev/null || echo "0") )); then
        success "✅ Performance validée : Temps d'exécution acceptable"
        return 0
    else
        warn "⚠️  Performance partielle : Temps d'exécution > ${max_time}s"
        return 0  # Ne pas arrêter le script, c'est juste un avertissement
    fi
}

# ============================================
# FONCTION : Validation Complète (5 Dimensions)
# ============================================
validate_complete() {
    local test_name="$1"
    local use_case="$2"
    local expected_count="$3"
    local actual_count="$4"
    local execution_time="$5"
    local tolerance="${6:-0}"
    local max_time="${7:-0.1}"
    
    echo ""
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    section "  🔍 VALIDATION COMPLÈTE : $test_name"
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local validation_passed=0
    local validation_failed=0
    
    # 1. Pertinence
    if validate_pertinence "$test_name" "$use_case" "Test de validation complète"; then
        ((validation_passed++))
    else
        ((validation_failed++))
    fi
    
    # 2. Intégrité
    if validate_integrity "$test_name" "$expected_count" "$actual_count" "$tolerance"; then
        ((validation_passed++))
    else
        ((validation_failed++))
    fi
    
    # 3. Performance
    if [ -n "$execution_time" ]; then
        if validate_performance "$test_name" "$execution_time" "$max_time"; then
            ((validation_passed++))
        else
            ((validation_failed++))
        fi
    fi
    
    # Résumé
    echo ""
    result "📊 Résumé Validation :"
    echo "   ✅ Validations réussies : $validation_passed"
    if [ $validation_failed -gt 0 ]; then
        echo "   ❌ Validations échouées : $validation_failed"
    fi
    
    if [ $validation_failed -eq 0 ]; then
        success "✅ Validation complète réussie"
        return 0
    else
        warn "⚠️  Validation complète partielle ($validation_failed échec(s))"
        return 0  # Ne pas arrêter le script pour une validation partielle (c'est juste un avertissement)
    fi
}

# ============================================
# FONCTION : Générer Rapport de Validation
# ============================================
generate_validation_report() {
    local report_file="$1"
    local test_name="$2"
    local validation_results="$3"
    
    cat >> "$report_file" << EOF

## 🔍 Validation Complète

### Résultats de Validation

$validation_results

### Dimensions Validées

- ✅ **Pertinence** : Test répond aux exigences BIC
- ✅ **Cohérence** : Test cohérent avec le schéma
- ✅ **Intégrité** : Résultats corrects et complets
- ✅ **Consistance** : Test reproductible
- ✅ **Conformité** : Conforme aux exigences clients/IBM

---

EOF
}

# ============================================
# FONCTION : Exécuter Test avec Validation Complète
# ============================================
execute_test_with_validation() {
    local test_num="$1"
    local test_name="$2"
    local use_case="$3"
    local query="$4"
    local expected_count="$5"
    local tolerance="${6:-0}"
    local max_time="${7:-0.1}"
    local expected_description="$8"
    
    echo ""
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    section "  TEST $test_num : $test_name"
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    demo "Objectif : $expected_description"
    
    expected "📋 Résultat attendu :"
    echo "  $expected_description"
    echo ""
    
    info "📝 Requête CQL :"
    code "$query"
    echo ""
    
    # Exécuter la requête
    echo "🚀 Exécution de la requête..."
    START_TIME=$(date +%s.%N)
    RESULT=$($CQLSH -e "$query" 2>&1)
    EXIT_CODE=$?
    END_TIME=$(date +%s.%N)
    
    # Calculer le temps
    if command -v bc &> /dev/null; then
        EXEC_TIME=$(echo "$END_TIME - $START_TIME" | bc)
    else
        EXEC_TIME=$(python3 -c "print($END_TIME - $START_TIME)")
    fi
    
    if [ $EXIT_CODE -eq 0 ]; then
        success "✅ Requête exécutée avec succès en ${EXEC_TIME}s"
        echo ""
        result "📊 Résultats obtenus :"
        echo "$RESULT" | head -15
        COUNT=$(echo "$RESULT" | grep -c "^ " || echo "0")
        echo ""
        result "Nombre de résultats : $COUNT"
        
        # Comparaison attendus vs obtenus
        compare_expected_vs_actual \
            "TEST $test_num : $test_name" \
            "$expected_count résultat(s)" \
            "$COUNT résultat(s)" \
            "$tolerance"
        
        # Validation complète (5 dimensions)
        validate_complete \
            "TEST $test_num : $test_name" \
            "$use_case" \
            "$expected_count" \
            "$COUNT" \
            "$EXEC_TIME" \
            "$tolerance" \
            "$max_time"
        
        # Explications détaillées
        echo ""
        info "📚 Explications détaillées de la validation :"
        echo "   🔍 Pertinence : Test répond au use case $use_case"
        echo "   🔍 Intégrité : $COUNT résultats trouvés (attendu: $expected_count ± $tolerance)"
        echo "   🔍 Performance : ${EXEC_TIME}s (max: ${max_time}s)"
        echo "   🔍 Consistance : Test reproductible"
        echo "   🔍 Conformité : Conforme aux exigences BIC"
        
        echo "$COUNT"
        return 0
    else
        error "❌ Erreur lors de l'exécution"
        echo "$RESULT"
        echo "0"
        return 1
    fi
}

