# COMMON_MISTAKES.md

**Date** : 2026-03-20
**POC** : Arkea — Guide anti-erreurs
**TL;DR** : La majorité des erreurs vient d’un mélange Active/Legacy et d’un mauvais usage des ports hôte vs conteneur.

---

## ✅ Do

- Utiliser `ARKEA_LEG=podman` (par défaut)
- Utiliser les ports hôte : `9102` (CQL), `9192` (Kafka), `9280` (Spark UI)
- Exécuter `make audit-active` avant de valider un changement
- Utiliser `make start/stop/status/check`

## ❌ Don’t

- Ne pas utiliser `localhost:9042` ou `localhost:9092` côté hôte sur le leg actif
- Ne pas démarrer le leg binaire sans `ARKEA_ENABLE_BINARY_LEG=1`
- Ne pas mélanger scripts legacy et runtime actif dans le même run

---

## Erreurs fréquentes

### 1) Connection refused sur Cassandra

- Cause probable : utilisation de `9042` côté hôte
- Fix : utiliser `cqlsh localhost 9102`

### 2) Kafka inaccessible

- Cause probable : utilisation de `9092` côté hôte
- Fix : utiliser `localhost:9192` dans les clients hôte

### 3) Dérive documentaire

- Cause probable : copier un exemple legacy dans un doc actif
- Fix : relancer `make audit-active` et corriger les références host-side
