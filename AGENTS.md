# 🤖 AGENTS.md — Instructions pour les Agents IA

**Dernière mise à jour** : 2026-03-12
**Objectif** : Guider les assistants IA (Claude, GPT, Cursor, etc.) pour travailler efficacement sur ce projet.

---

## 🎯 Contexte Projet

Ce POC démontre la faisabilité de migrer une architecture HBase vers **DataStax HCD** (Hyper-Converged Database, basé sur Cassandra 4.0.11) en utilisant **Apache Spark** et **Kafka**.

### Stack Technique

| Composant | Version | Rôle |
|-----------|---------|------|
| **HCD** | 1.2.3 | Base de données cible (Cassandra 4.0.11) |
| **Spark** | 3.5.1 | Traitement distribué et streaming |
| **Kafka** | 4.1.1 | Streaming de données |
| **spark-cassandra-connector** | 3.5.0 | Intégration Spark ↔ HCD |
| **Python** | 3.9+ | Scripts utilitaires |
| **Scala** | 2.12 | Tests Spark |

### Contexte Métier

- **Client** : Arkea (institution financière française)
- **Objectif** : Migration COBOL/HBase → Python/Spark/HCD
- **Type** : Preuve de concept (POC) pour validation technique

---

## 📁 Structure Importante

### Répertoires Prioritaires

| Répertoire | Description | Priorité |
|------------|-------------|----------|
| `scripts/setup/` | Scripts d'installation (01-06) | Haute |
| `scripts/utils/` | Utilitaires maintenance (70-95) | Haute |
| `schemas/` | Schémas CQL et Kafka | Moyenne |
| `tests/` | Tests automatisés | Moyenne |
| `docs/` | Documentation technique | Moyenne |
| `poc-design/` | POCs de démonstration | Basse |

### Répertoires à Ignorer

| Répertoire | Raison |
|------------|--------|
| `binaire/` | Binaires installés (Spark, HCD, Kafka) |
| `software/` | Archives .tar.gz |
| `logs/` | Fichiers de log |
| `inputs-clients/` | Documents client (lecture seule) |
| `inputs-ibm/` | Documents IBM (lecture seule) |

---

## 🔧 Conventions de Code

### Scripts Bash

```bash
# Portabilité cross-platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    REALPATH="grealpath"
else
    REALPATH="realpath"
fi

# Utiliser les variables de configuration
source "${SCRIPT_DIR}/../.poc-config.sh"

# Chemins relatifs, jamais hardcodés
PROJECT_ROOT="$("${REALPATH}" "${SCRIPT_DIR}/..")"
```

### Nommage des Scripts

- `01_XX_YY.sh` — Scripts de setup (numérotés)
- `70_XX_YY.sh` — Utilitaires (70+)
- `90_XX_YY.sh` — Scripts de vérification/maintenance

### Documentation

- Les fichiers de synthèse sont préfixés `SYNTHESE_*.md`
- Les analyses sont préfixées `ANALYSE_*.md`
- Les guides sont préfixés `GUIDE_*.md`

---

## 🧪 Tests

```bash
# Lancer tous les tests
./tests/run_all_tests.sh

# Tests unitaires uniquement
pytest tests/unit/ -v

# Tests d'intégration
pytest tests/integration/ -v
```

---

## 📚 Documentation Clé

| Document | Emplacement | Usage |
|----------|-------------|-------|
| README principal | `/README.md` | Vue d'ensemble projet |
| Index documentation | `/docs/INDEX.md` | Navigation docs |
| Synthèse POC | `/SYNTHESE_USE_CASES_POC.md` | Résultats POC |
| Valeur métier | `/business/SYNTHESE_RESULTATS_BENEFICES_HCD_ARKEA.md` | ROI/Bénéfices |
| Preuves techniques | `/evidence/JUSTIFICATION_RESULTATS_POC_ARKEA.md` | Evidence technique |

---

## ⚠️ Points d'Attention

1. **Sécurité** : Ne jamais committer de tokens, mots de passe ou credentials
2. **Portabilité** : Toujours tester sur macOS et Linux
3. **Chemins** : Utiliser `.poc-config.sh` pour les chemins
4. **Logs** : Écrire dans `$LOG_DIR` (jamais à la racine)
5. **Documentation** : Mettre à jour `docs/INDEX.md` si nouveau doc ajouté

---

## 🚀 Commandes Utiles

```bash
# Vérifier cohérence projet
./scripts/utils/91_check_consistency.sh

# Nettoyer fichiers temporaires
./scripts/utils/95_cleanup.sh

# Démarrer environnement
./scripts/setup/03_start_hcd.sh && ./scripts/setup/04_start_kafka.sh

# Vérifier statut
./scripts/utils/80_verify_all.sh
```

---

## 📞 Contact

- **Auteur** : David LECONTE (david.leconte1@ibm.com)
- **Contexte** : IBM | Arkea POC Migration HBase → HCD
