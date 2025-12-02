# 📊 Analyse : Jeu de Données Métier pour Tests BIC

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Objectif** : Définir les exigences pour créer un jeu de données métier complet, pertinent, cohérent, consistant, intègre et volumineux

---

## 🔍 État Actuel vs Exigences

### ✅ Ce qui existe

1. **Schéma de base** : `02_create_bic_tables.cql`
   - Table `interactions_by_client` avec colonnes de base
   - TTL 2 ans configuré
   - Clustering optimisé pour timeline

2. **Index SAI de base** : `03_create_bic_indexes.cql`
   - Index sur `canal`
   - Index sur `type_interaction`
   - Index sur `date_interaction`
   - Index full-text sur `json_data`

3. **Scripts de test** : Scripts 11, 12, 14, 16, 18
   - Utilisent des données de test
   - Valident les fonctionnalités

### ❌ Ce qui manque

#### 1. Colonne `resultat` manquante dans le schéma

**Problème** :

- Les scripts 12 et 18 utilisent `resultat` pour filtrer (BIC-11)
- La colonne n'existe pas dans `02_create_bic_tables.cql`
- L'index SAI sur `resultat` n'existe pas dans `03_create_bic_indexes.cql`

**Impact** :

- ❌ BIC-11 (Filtrage par résultat) ne peut pas être testé
- ❌ Les tests de filtrage combiné échouent

**Solution** :

- Ajouter `resultat text` dans `02_create_bic_tables.cql`
- Ajouter index SAI sur `resultat` dans `03_create_bic_indexes.cql`

#### 2. Structure JSON non définie

**Problème** :

- Le contenu exact de `json_data` n'est pas défini
- Les scripts de génération ne savent pas quelle structure créer
- La recherche full-text (BIC-12) nécessite un contenu structuré

**Exigences** :

- Doit contenir des détails textuels pour recherche full-text
- Doit être conforme aux exigences clients/IBM
- Doit supporter tous les canaux et types d'interactions

**Solution** :

- Définir la structure JSON complète
- Documenter tous les champs requis

#### 3. Colonnes dynamiques non définies

**Problème** :

- Le contenu de `colonnes_dynamiques` (MAP<text, text>) n'est pas défini
- Les scripts de génération ne savent pas quelles clés/valeurs créer

**Exigences** :

- Doit permettre flexibilité (BIC-07)
- Doit être compatible avec les filtres HBase équivalents

**Solution** :

- Définir les clés/valeurs standard
- Documenter les cas d'usage

#### 4. Scripts de génération manquants

**Problème** :

- Scripts 05, 06, 07 n'existent pas encore
- Pas de données de test volumineuses

**Exigences** :

- Au moins 10 000 interactions (plan mentionne 10 000+)
- Couvrir tous les canaux (8 canaux)
- Couvrir tous les types (5+ types)
- Couvrir tous les résultats (succès, échec, etc.)
- Période de 2 ans d'historique
- Distribution réaliste

**Solution** :

- Créer script 05 : Génération Parquet (10 000+ interactions)
- Créer script 06 : Génération JSON (1 000+ événements Kafka)
- Créer script 07 : Génération données de test ciblées

---

## 📋 Structure Complète des Données Requise

### Colonnes du Schéma

| Colonne | Type | Obligatoire | Description | Source |
|---------|------|-------------|--------------|--------|
| `code_efs` | text | ✅ | Code établissement financier | Partition key |
| `numero_client` | text | ✅ | Numéro client | Partition key |
| `date_interaction` | timestamp | ✅ | Date/heure interaction | Clustering |
| `canal` | text | ✅ | Canal (email, SMS, agence, etc.) | Clustering |
| `type_interaction` | text | ✅ | Type (consultation, conseil, etc.) | Clustering |
| `idt_tech` | text | ✅ | Identifiant technique unique | Clustering |
| `resultat` | text | ✅ | Résultat/statut (succès, échec, etc.) | **MANQUANT** |
| `json_data` | text | ✅ | Données JSON complètes | Obligatoire |
| `colonnes_dynamiques` | map<text, text> | ⚠️ | Colonnes dynamiques | Optionnel |
| `created_at` | timestamp | ✅ | Date création | Métadonnées |
| `updated_at` | timestamp | ✅ | Date mise à jour | Métadonnées |
| `version` | int | ✅ | Version enregistrement | Métadonnées |

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
  "details": "Le client a signalé un problème avec son virement. Le problème a été résolu rapidement.",
  "sujet": "Problème virement",
  "contenu": "Bonjour, j'ai un problème avec mon virement du 10 janvier...",
  "id_conseiller": "CONS001",
  "nom_conseiller": "Dupont",
  "prenom_conseiller": "Jean",
  "duree_interaction": 180,
  "canal_detail": {
    "email": {
      "expediteur": "client@example.com",
      "destinataire": "conseiller@banque.fr",
      "objet": "Problème virement"
    }
  },
  "metadata": {
    "source": "kafka",
    "topic": "bic-event",
    "partition": 0,
    "offset": 12345,
    "timestamp_kafka": "2024-01-15T10:30:00Z"
  },
  "tags": ["urgent", "virement", "probleme"],
  "categorie": "service_client"
}
```

**Champs Requis pour Recherche Full-Text** :

- `details` : Texte libre pour recherche (BIC-12)
- `sujet` : Sujet de l'interaction
- `contenu` : Contenu détaillé (email, SMS, etc.)
- `tags` : Tags pour catégorisation

### Colonnes Dynamiques (`colonnes_dynamiques`)

**Clés Standard** :

- `resultat_detail` : Détail du résultat (ex: "succès - résolu en 24h")
- `priorite` : Priorité (ex: "haute", "moyenne", "basse")
- `categorie` : Catégorie métier (ex: "service_client", "vente", "conseil")
- `montant` : Montant si transaction (ex: "1500.00")
- `devise` : Devise (ex: "EUR")
- `reference` : Référence transaction (ex: "VIR-2024-001")
- `duree_secondes` : Durée en secondes (ex: "180")
- `satisfaction` : Note satisfaction (ex: "5")
- `id_conseiller` : ID conseiller (ex: "CONS001")
- `id_agence` : ID agence (ex: "AG001")

**Exemple** :

```cql
colonnes_dynamiques = {
  'resultat_detail': 'succès - résolu en 24h',
  'priorite': 'haute',
  'categorie': 'service_client',
  'duree_secondes': '180',
  'satisfaction': '5'
}
```

### Valeurs Possibles par Colonne

#### Canaux (8 canaux)

| Canal | Code | Description |
|-------|------|-------------|
| `email` | email | Email |
| `SMS` | SMS | SMS |
| `agence` | agence | Agence physique |
| `telephone` | telephone | Téléphone |
| `web` | web | Site web |
| `RDV` | RDV | Rendez-vous |
| `agenda` | agenda | Agenda |
| `mail` | mail | Courrier postal |

#### Types d'Interactions (5+ types)

| Type | Code | Description |
|------|------|-------------|
| `consultation` | consultation | Consultation |
| `conseil` | conseil | Conseil |
| `transaction` | transaction | Transaction |
| `reclamation` | reclamation | Réclamation |
| `achat` | achat | Achat |
| `demande` | demande | Demande |
| `suivi` | suivi | Suivi |

#### Résultats (3+ valeurs)

| Résultat | Code | Description |
|----------|------|-------------|
| `succès` | succès | Succès |
| `échec` | échec | Échec |
| `en_cours` | en_cours | En cours |
| `annule` | annule | Annulé |

---

## 📊 Exigences de Volume et Distribution

### Volume Minimum

- **Parquet (Batch)** : 10 000+ interactions
- **JSON (Kafka)** : 1 000+ événements
- **Données de test** : Couverture complète des scénarios

### Distribution Requise

#### Par Canal

| Canal | Pourcentage | Nombre (sur 10 000) |
|-------|-------------|---------------------|
| email | 25% | 2 500 |
| SMS | 20% | 2 000 |
| agence | 15% | 1 500 |
| telephone | 15% | 1 500 |
| web | 10% | 1 000 |
| RDV | 5% | 500 |
| agenda | 5% | 500 |
| mail | 5% | 500 |

#### Par Type

| Type | Pourcentage | Nombre (sur 10 000) |
|------|-------------|---------------------|
| consultation | 30% | 3 000 |
| conseil | 25% | 2 500 |
| transaction | 20% | 2 000 |
| reclamation | 15% | 1 500 |
| achat | 5% | 500 |
| demande | 3% | 300 |
| suivi | 2% | 200 |

#### Par Résultat

| Résultat | Pourcentage | Nombre (sur 10 000) |
|----------|-------------|---------------------|
| succès | 70% | 7 000 |
| échec | 15% | 1 500 |
| en_cours | 10% | 1 000 |
| annule | 5% | 500 |

#### Par Période (2 ans)

- **Année 1** : 50% (5 000 interactions)
- **Année 2** : 50% (5 000 interactions)
- **Distribution mensuelle** : Uniforme avec légères variations
- **Distribution quotidienne** : Légèrement plus élevée en semaine

#### Par Client

- **Nombre de clients** : 100-200 clients uniques
- **Interactions par client** : 50-100 interactions en moyenne
- **Distribution** : Certains clients avec plus d'interactions (réaliste)

---

## ✅ Plan d'Action

### Phase 1 : Ajustements Schéma (PRIORITÉ 1)

1. ✅ Ajouter colonne `resultat` dans `02_create_bic_tables.cql`
2. ✅ Ajouter index SAI sur `resultat` dans `03_create_bic_indexes.cql`
3. ✅ Mettre à jour script 03 pour créer l'index

### Phase 2 : Documentation Structure Données (PRIORITÉ 1)

1. ✅ Créer document définissant structure JSON complète
2. ✅ Créer document définissant colonnes dynamiques
3. ✅ Créer exemples de données pour chaque canal/type

### Phase 3 : Scripts de Génération (PRIORITÉ 2)

1. ✅ Créer script 05 : Génération Parquet (10 000+ interactions)
2. ✅ Créer script 06 : Génération JSON (1 000+ événements Kafka)
3. ✅ Créer script 07 : Génération données de test ciblées

### Phase 4 : Validation (PRIORITÉ 3)

1. ✅ Valider que toutes les colonnes sont présentes
2. ✅ Valider que toutes les valeurs possibles sont couvertes
3. ✅ Valider que le volume est suffisant
4. ✅ Valider que la distribution est réaliste

---

## 📝 Conclusion

**Manques Identifiés** :

1. ❌ Colonne `resultat` manquante
2. ❌ Index SAI sur `resultat` manquant
3. ❌ Structure JSON non définie
4. ❌ Colonnes dynamiques non définies
5. ❌ Scripts de génération manquants

**Actions Requises** :

1. ✅ Ajuster le schéma (ajouter `resultat`)
2. ✅ Ajuster les index (ajouter index `resultat`)
3. ✅ Documenter la structure complète des données
4. ✅ Créer les scripts de génération

**Une fois ces actions effectuées** :

- ✅ Toutes les colonnes nécessaires seront présentes
- ✅ Toutes les exigences pourront être testées
- ✅ Un jeu de données complet et volumineux pourra être généré
