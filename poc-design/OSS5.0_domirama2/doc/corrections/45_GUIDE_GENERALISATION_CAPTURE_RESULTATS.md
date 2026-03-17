# 📋 Guide : Généralisation de la Capture de Résultats pour Toutes les Démonstrations

**Date** : 2025-11-26
**Objectif** : Guide pour généraliser le processus de capture des résultats réels des requêtes CQL dans toutes les démonstrations

---

## 🎯 Objectif

Toutes les démonstrations doivent maintenant :

1. ✅ **Capturer les résultats réels** des requêtes CQL
2. ✅ **Afficher les résultats dans le terminal** pendant l'exécution
3. ✅ **Générer automatiquement la documentation** avec les résultats réels
4. ✅ **Permettre un contrôle systématique** des résultats

---

## 📝 Processus Standardisé

### Étape 1 : Structure de Capture dans le Script Python

Dans chaque script Python intégré dans un script bash, ajouter :

```python
import json
from decimal import Decimal

# Fonction pour convertir Decimal en float pour JSON
def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

# Structure pour stocker tous les résultats
all_results = []

# Pour chaque test
for i, test_case in enumerate(test_cases, 1):
    # Structure pour stocker les résultats de ce test
    test_result = {
        "test_number": i,
        "query": query_text,  # ou autre identifiant
        "description": description,
        "expected": expected,
        "cql_query": cql_query.strip(),
        "results": [],
        "success": False,
        "error": None,
        "query_time": None,
        "validation": None
    }

    # Exécuter la requête
    start_time = time.time()
    try:
        results = list(session.execute(statement))
        query_time = time.time() - start_time
        test_result["query_time"] = query_time

        # Capturer chaque résultat
        for j, row in enumerate(results, 1):
            test_result["results"].append({
                "rank": j,
                "libelle": row.libelle if row.libelle else None,
                "montant": float(row.montant) if row.montant else None,
                # ... autres colonnes
            })

        test_result["success"] = True
        test_result["validation"] = "Pertinents"  # ou autre validation

    except Exception as e:
        test_result["success"] = False
        test_result["error"] = str(e)

    # Ajouter à la liste
    all_results.append(test_result)

# Sauvegarder dans un fichier JSON
RESULTS_FILE = "RESULTS_FILE_PLACEHOLDER"
with open(RESULTS_FILE, 'w', encoding='utf-8') as f:
    json.dump(all_results, f, indent=2, ensure_ascii=False, default=decimal_default)
```

### Étape 2 : Configuration dans le Script Bash

Dans le script bash, avant d'exécuter le script Python :

```bash
# Créer un fichier temporaire pour les résultats
TEMP_SCRIPT=$(mktemp)
TEMP_RESULTS="${TEMP_SCRIPT}.results.json"

# Dans le script Python, remplacer le placeholder
sed -i '' "s|RESULTS_FILE_PLACEHOLDER|$TEMP_RESULTS|g" "$TEMP_SCRIPT"

# Exécuter le script Python
python3 "$TEMP_SCRIPT"

# Vérifier que le fichier existe
if [ ! -f "$TEMP_RESULTS" ]; then
    warn "⚠️  Fichier de résultats non trouvé"
    echo "[]" > "$TEMP_RESULTS"
fi
```

### Étape 3 : Génération du Rapport avec Résultats Réels

Dans la section de génération du rapport markdown :

```bash
cat > "$REPORT_FILE" << EOF
# Démonstration : [Titre]

## 📊 Résultats Détaillés

### Résultats Réels des Requêtes CQL

$(python3 << PYTHON_EOF
import json
import sys
import re

try:
    # Lire directement depuis le fichier
    with open('$TEMP_RESULTS', 'r', encoding='utf-8') as f:
        results = json.load(f)

    for i, test in enumerate(results, 1):
        query = test.get("query", "N/A")
        description = test.get("description", "N/A")
        expected = test.get("expected", "N/A")
        query_time = test.get("query_time", 0)
        success = test.get("success", False)
        error = test.get("error")
        validation = test.get("validation", "N/A")
        test_results = test.get("results", [])
        cql_query = test.get("cql_query", "N/A")

        print(f"#### TEST {i} : '{query}'")
        print()
        print(f"**Description** : {description}")
        print(f"**Résultat attendu** : {expected}")
        if query_time:
            print(f"**Temps d'exécution** : {query_time:.3f}s")
        print(f"**Statut** : {'✅ Succès' if success else '❌ Échec'}")
        if error:
            print(f"**Erreur** : {error}")
        if validation:
            print(f"**Validation** : {validation}")
        print()

        if cql_query and cql_query != "N/A":
            print("**Requête CQL exécutée :**")
            print()
            print("\\\`\\\`\\\`cql")
            # Tronquer les vecteurs longs pour lisibilité
            cql_query_short = re.sub(r'ANN OF \[.*?\]', 'ANN OF [...]', cql_query, flags=re.DOTALL)
            print(cql_query_short)
            print("\\\`\\\`\\\`")
            print()

        if test_results:
            print(f"**Résultats obtenus ({len(test_results)} résultat(s)) :**")
            print()
            # Déterminer les colonnes disponibles
            columns = set()
            for result in test_results:
                columns.update(result.keys())
            columns.discard("rank")

            # Créer le tableau
            header_cols = ["Rang"] + sorted([c for c in columns if c != "rank"])
            print("| " + " | ".join(header_cols) + " |")
            print("|" + "|".join(["------"] * len(header_cols)) + "|")

            for result in test_results:
                row = [str(result.get("rank", "N/A"))]
                for col in sorted([c for c in columns if c != "rank"]):
                    value = result.get(col, "N/A")
                    if isinstance(value, float):
                        value = f"{value:.2f}"
                    elif value and isinstance(value, str) and len(value) > 60:
                        value = value[:57] + "..."
                    row.append(str(value))
                print("| " + " | ".join(row) + " |")
            print()
        else:
            print("**Aucun résultat trouvé**")
            print()

        print("---")
        print()

except Exception as e:
    print("Erreur lors de la génération des résultats détaillés")
    print(f"Erreur : {str(e)}")
    import traceback
    traceback.print_exc()
PYTHON_EOF
)
EOF

# Nettoyer le fichier temporaire
rm -f "$TEMP_RESULTS"
```

---

## 🔧 Utilisation du Module `capture_results.py`

Pour simplifier, vous pouvez utiliser le module `utils/capture_results.py` :

```python
from utils.capture_results import ResultCapture, generate_markdown_results

# Dans le script Python
capture = ResultCapture("results.json")

# Pour chaque test
test_structure = capture.start_test(
    test_number=i,
    query=query_text,
    description=description,
    expected=expected,
    cql_query=cql_query
)

# Ajouter des résultats
for j, row in enumerate(results, 1):
    capture.add_result(
        test_structure,
        rank=j,
        libelle=row.libelle,
        montant=row.montant,
        cat_auto=row.cat_auto
    )

# Finaliser le test
capture.finalize_test(
    test_structure,
    success=True,
    query_time=query_time,
    validation="Pertinents"
)

# Sauvegarder
capture.save()
```

Puis dans le bash :

```bash
# Générer la section markdown
MARKDOWN_RESULTS=$(python3 utils/capture_results.py "$TEMP_RESULTS")

# L'inclure dans le rapport
cat > "$REPORT_FILE" << EOF
# Démonstration

## Résultats Réels

$MARKDOWN_RESULTS
EOF
```

---

## 📋 Checklist pour Généraliser une Démonstration

### Script Python

- [ ] Importer `json` et `Decimal`
- [ ] Ajouter fonction `decimal_default`
- [ ] Créer liste `all_results = []`
- [ ] Pour chaque test :
  - [ ] Créer structure `test_result`
  - [ ] Capturer `query_time`
  - [ ] Capturer chaque résultat dans `test_result["results"]`
  - [ ] Définir `success`, `validation`, `error`
  - [ ] Ajouter à `all_results`
- [ ] Sauvegarder dans fichier JSON avec placeholder

### Script Bash

- [ ] Créer `TEMP_RESULTS="${TEMP_SCRIPT}.results.json"`
- [ ] Remplacer placeholder `RESULTS_FILE_PLACEHOLDER`
- [ ] Vérifier existence du fichier après exécution
- [ ] Dans la génération du rapport :
  - [ ] Ajouter section "Résultats Réels des Requêtes CQL"
  - [ ] Utiliser script Python inline pour générer markdown
  - [ ] Inclure requêtes CQL, métriques, tableaux de résultats
- [ ] Nettoyer `$TEMP_RESULTS` après génération

---

## 📝 Scripts à Améliorer

### Priorité Haute (Déjà améliorés)

- ✅ `25_test_hybrid_search_v2_didactique.sh`
- ✅ `23_test_fuzzy_search_v2_didactique.sh`

### Priorité Moyenne (À améliorer)

- `32_demo_performance_comparison.sh`
- `33_demo_colonnes_dynamiques_v2.sh`
- `34_demo_replication_scope_v2.sh`
- `31_demo_bloomfilter_equivalent_v2.sh`
- `29_demo_requetes_fenetre_glissante.sh`
- `30_demo_requetes_startrow_stoprow.sh`

### Priorité Basse (Optionnel)

- `35_demo_dsbulk_v2.sh`
- `37_demo_data_api.sh`
- `40_demo_data_api_complete.sh`
- `41_demo_complete_podman.sh`

---

## 💡 Exemple Complet

Voir les scripts suivants comme exemples complets :

- `25_test_hybrid_search_v2_didactique.sh` (Recherche hybride)
- `23_test_fuzzy_search_v2_didactique.sh` (Fuzzy search)

---

## ✅ Avantages de cette Approche

1. **Traçabilité** : Tous les résultats sont documentés
2. **Vérifiabilité** : Les résultats réels sont visibles dans la documentation
3. **Reproductibilité** : Les requêtes CQL sont documentées
4. **Contrôle qualité** : Validation systématique des résultats
5. **Livrable professionnel** : Documentation complète et structurée

---

**✅ Avec ce guide, vous pouvez généraliser la capture de résultats à toutes les démonstrations !**
