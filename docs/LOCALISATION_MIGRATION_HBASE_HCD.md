# 📍 Localisation : Dossier Migration HBase → HCD

**Date** : 2025-12-02  
**Question** : Où se trouve le dossier dédié à la migration HBase → HCD ?  
**Réponse** : Le projet ARKEA entier est dédié à la migration, organisé en
plusieurs dossiers

---

## 🎯 Réponse Directe

**Il n'y a pas UN seul dossier "migration"**, mais le projet ARKEA entier
est structuré pour la migration HBase → HCD, avec plusieurs dossiers
contenant des éléments spécifiques.

---

## 📁 Structure de la Migration

### 1. **poc-design/** - Démonstrations de Migration ⭐

**Localisation** : `/Users/david.leconte/Documents/Arkea/poc-design/`

**Contenu** : 3 POCs de démonstration de migration

| POC | Description | Dossier |
|-----|-------------|---------|
| **domirama2** | Migration table Domirama (opérations bancaires) | poc-design/domirama2/ |
| **domiramaCatOps** | Migration catégorisation des opérations | poc-design/domiramaCatOps/ |
| **bic** | Migration Base d'Interaction Client | poc-design/bic/ |

**Chaque POC contient** :

- `scripts/` : Scripts de migration et démonstration
- `schemas/` : Schémas CQL (équivalents HBase)
- `doc/` : Documentation spécifique au POC
- `examples/` : Exemples de code (Python, Scala, Java)

**Guide de migration spécifique** :

- `poc-design/bic/doc/guides/05_GUIDE_MIGRATION_HBASE.md` ⭐

---

### 2. **docs/** - Documentation Migration ⭐

**Localisation** : `/Users/david.leconte/Documents/Arkea/docs/`

**Fichiers clés sur la migration** :

| Fichier | Description |
|---------|-------------|
| **ANALYSE_ETAT_ART_HBASE.md** | Analyse de l'existant HBase chez Arkéa |
| **ANALYSE_PROPOSITION_IBM_MECE.md** | Analyse de la proposition IBM MECE |
| **ANALYSE_INPUTS_CLIENTS_COMPLETE.md** | Analyse des exigences clients |
| **ARCHITECTURE_POC_COMPLETE.md** | Architecture complète du POC |
| **POC_TABLE_DOMIRAMA.md** | Détails migration table Domirama |
| **GUIDE_INGESTION_COBOL_HCD.md** | Guide ingestion COBOL → HCD |
| **ANALYSE_BLOB_VS_JSON_ARKEA.md** | Analyse format de stockage |
| **ANALYSE_COBOL_VS_PYTHON_GENERATION.md** | Analyse génération données |

**Index complet** : `docs/README.md`

---

### 3. **inputs-ibm/** - Proposition IBM MECE ⭐

**Localisation** : `/Users/david.leconte/Documents/Arkea/inputs-ibm/`

**Fichier principal** :

- **PROPOSITION_MECE_MIGRATION_HBASE_HCD.md** ⭐
  - Proposition complète IBM pour la migration
  - ~1560 lignes
  - Axes : Technologique, Données, Applicatif, Organisationnel
  - Guide POC avec code complet

**README** : `inputs-ibm/README.md`

---

### 4. **inputs-clients/** - Exigences Clients

**Localisation** : `/Users/david.leconte/Documents/Arkea/inputs-clients/`

**Fichiers** :

- **Etat de l'art HBase chez Arkéa.pdf** : Document client sur l'existant
- **groupe_2025-11-25-110250.zip** : Archives du code source HBase
- **README.md** : Description du contenu

**Analyse** : `docs/ANALYSE_INPUTS_CLIENTS_COMPLETE.md`

---

### 5. **scripts/** - Scripts de Migration

**Localisation** : `/Users/david.leconte/Documents/Arkea/scripts/`

**Organisation** :

- `scripts/setup/` : Installation HCD, Spark, Kafka
- `scripts/utils/` : Utilitaires (vérification, listing, etc.)
- `scripts/scala/` : Scripts Scala pour migration

**Documentation** : `docs/SCRIPTS_A_JOUR.md`

---

## 🗺️ Carte de Navigation

### Pour comprendre la migration

1. **Commencer par** :
   - `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md` ⭐ (Proposition IBM)
   - `docs/ANALYSE_ETAT_ART_HBASE.md` (Existant HBase)
   - `docs/ANALYSE_PROPOSITION_IBM_MECE.md` (Analyse proposition)

2. **Puis explorer les POCs** :
   - `poc-design/domirama2/README.md` (POC Domirama)
   - `poc-design/domiramaCatOps/README.md` (POC Catégorisation)
   - `poc-design/bic/README.md` (POC BIC)

3. **Guides spécifiques** :
   - `poc-design/bic/doc/guides/05_GUIDE_MIGRATION_HBASE.md` ⭐ (Guide migration BIC)
   - `docs/GUIDE_INGESTION_COBOL_HCD.md` (Guide ingestion COBOL)

### Pour exécuter la migration

1. **Setup** :
   - `scripts/setup/01_install_hcd.sh`
   - `scripts/setup/02_install_spark_kafka.sh`

2. **POCs** :
   - `poc-design/domirama2/scripts/` (Scripts Domirama)
   - `poc-design/domiramaCatOps/scripts/` (Scripts Catégorisation)
   - `poc-design/bic/scripts/` (Scripts BIC)

---

## 📊 Résumé

| Élément | Localisation | Description |
|---------|--------------|-------------|
| **Proposition IBM** | `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md` | ⭐ Document principal |
| **Guide Migration BIC** | `poc-design/bic/doc/guides/05_GUIDE_MIGRATION_HBASE.md` | ⭐ Guide spécifique |
| **POCs** | `poc-design/` | 3 démonstrations (domirama2, domiramaCatOps, bic) |
| **Documentation** | `docs/` | ~50 fichiers de documentation |
| **Exigences** | `inputs-clients/` | Documents clients |
| **Scripts** | `scripts/` | Scripts d'installation et migration |

---

## 🎯 Conclusion

**Le projet ARKEA entier est le dossier de migration HBase → HCD**, organisé en :

- **inputs-ibm/** : Proposition IBM (document principal) ⭐
- **poc-design/** : 3 POCs de démonstration
- **docs/** : Documentation complète
- **inputs-clients/** : Exigences clients
- **scripts/** : Scripts de migration

**Point d'entrée recommandé** :
inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md

---

**Dernière mise à jour** : 2025-12-02
