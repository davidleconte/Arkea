# 📥 Démonstration : Génération des Données Interactions (Parquet)

**Date** : 2025-12-01 19:51:30
**Script** : `05_generate_interactions_parquet.sh`
**Use Cases** : BIC-07 (Format JSON + colonnes dynamiques), BIC-09 (Écriture batch)

---

## 📋 Objectif

Générer un fichier Parquet contenant **100 interactions** avec une diversité maximale pour valider tous les use cases du POC BIC.

---

## 🎯 Caractéristiques des Données Générées

### Volume et Distribution

- **Volume** : 100 interactions
- **Période** : 2 ans d'historique (2023-01-01 à 2024-12-31)
- **Clients** : 100-200 clients uniques
- **Interactions par client** : 50-100 interactions en moyenne

### Canaux (8 canaux)

| Canal | Pourcentage | Nombre |
|-------|-------------|--------|
| email | 25% | 25 |
| SMS | 20% | 20 |
| agence | 15% | 15 |
| telephone | 15% | 15 |
| web | 10% | 10 |
| RDV | 5% | 5 |
| agenda | 5% | 5 |
| mail | 5% | 5 |

### Types d'Interactions (7 types)

| Type | Pourcentage | Nombre |
|------|-------------|--------|
| consultation | 30% | 30 |
| conseil | 25% | 25 |
| transaction | 20% | 20 |
| reclamation | 15% | 15 |
| achat | 5% | 5 |
| demande | 3% | 3 |
| suivi | 2% | 2 |

### Résultats (4 résultats)

| Résultat | Pourcentage | Nombre |
|----------|-------------|--------|
| succès | 70% | 70 |
| échec | 15% | 15 |
| en_cours | 10% | 10 |
| annule | 5% | 5 |

---

## 📝 Structure des Données

### Colonnes du Parquet

- `code_efs` (text) - Code établissement financier
- `numero_client` (text) - Numéro client
- `date_interaction` (timestamp) - Date/heure interaction
- `canal` (text) - Canal (email, SMS, agence, etc.)
- `type_interaction` (text) - Type (consultation, conseil, etc.)
- `idt_tech` (text) - Identifiant technique unique
- `resultat` (text) - Résultat/statut (succès, échec, etc.)
- `json_data` (text) - Données JSON complètes
- `colonnes_dynamiques` (map<text, text>) - Colonnes dynamiques

### Structure JSON (`json_data`)

```json
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
  "categorie": "service_client"
}
```

---

## 🚀 Génération

---

## ✅ Résultats

**Fichier généré** : `${ARKEA_HOME}/poc-design/bic/data/parquet/interactions_100.parquet`
**Nombre d'interactions** : 101
**Taille** : N/A

**Distribution** :

- Canaux : Tous les 8 canaux couverts
- Types : Tous les 7 types couverts
- Résultats : Tous les 4 résultats couverts
- Période : 2 ans (2023-2024)

**Structure** :

- ✅ JSON complet avec détails pour recherche full-text
- ✅ Colonnes dynamiques (MAP) standardisées
- ✅ Toutes les colonnes requises présentes

---

**Date** : 2025-12-01 19:51:35
**Script** : `05_generate_interactions_parquet.sh`
