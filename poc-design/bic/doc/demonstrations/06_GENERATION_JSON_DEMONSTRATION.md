# 📥 Démonstration : Génération des Données Interactions JSON (Kafka)

**Date** : 2025-12-01 19:52:52  
**Script** : `06_generate_interactions_json.sh`  
**Use Cases** : BIC-02 (Ingestion Kafka temps réel), BIC-07 (Format JSON)

---

## 📋 Objectif

Générer **1000 événements JSON** conformes au format Kafka `bic-event` pour ingestion temps réel.

---

## 🎯 Format Kafka 'bic-event'

Les événements générés sont conformes au format attendu par le topic Kafka `bic-event` :

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
  "categorie": "service_client",
  "metadata": {
    "source": "kafka",
    "topic": "bic-event",
    "partition": 0,
    "offset": 12345,
    "timestamp_kafka": "2024-01-15T10:30:00Z"
  }
}
```

---

## 🚀 Génération


---

## ✅ Résultats

**Fichier généré** : `/Users/david.leconte/Documents/Arkea/poc-design/bic/data/json/interactions_1000.json`  
**Nombre d'événements** : 1000  
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

**Date** : 2025-12-01 19:52:52  
**Script** : `06_generate_interactions_json.sh`
