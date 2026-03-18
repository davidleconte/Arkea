# LEGACY_TO_ACTIVE_MIGRATION_GUIDE.md

**Date** : 2026-03-18
**POC** : Arkea — Migration du leg binaire historique vers OSS 5.0 Podman
**TL;DR** : Arrêter le leg legacy, sauvegarder schéma/données, basculer sur `ARKEA_LEG=podman`, redémarrer via `make`, puis valider avec `make audit-active`.

---

## 1) Objectif

Ce guide décrit la migration opérationnelle de :

- **Legacy** : `ARKEA_LEG=binary` (HCD 1.2.3, Java 11)
- vers **Active** : `ARKEA_LEG=podman` (Cassandra OSS 5.0, Java 17)

---

## 2) Pré-requis

- Java 17 disponible (active path)
- Podman + podman-compose opérationnels
- Accès au repository et au fichier `.poc-config.sh`
- Fenêtre de maintenance (arrêt du leg legacy)

---

## 3) Étapes de migration

## Étape A — Arrêter le legacy proprement

```bash
ARKEA_LEG=binary make stop
```

Si des processus restent actifs, stopper explicitement les composants legacy encore lancés.

## Étape B — Sauvegarder schéma et données (recommandé)

Exemples (adapter au contexte réel) :

```bash
# Export schéma
cqlsh localhost 9042 -e "DESCRIBE KEYSPACES;" > backup_keyspaces.cql
```

Exporter les tables critiques via vos outils habituels (cqlsh COPY / scripts d’export / utilitaires internes).

## Étape C — Basculer vers le runtime actif

```bash
export ARKEA_LEG=podman
```

(Option permanente : ajuster la valeur dans `.poc-config.sh` selon votre politique projet.)

## Étape D — Démarrer la stack active

```bash
make podman-check
make start
make status
```

## Étape E — Réimporter (si nécessaire)

Cible host-side active :

- CQL : `localhost:9102`
- Kafka : `localhost:9192`

Exemple CQL :

```bash
cqlsh localhost 9102
```

## Étape F — Valider la conformité active

```bash
make audit-active
make check
```

---

## 4) Critères d’acceptation

- `make status` montre les services attendus sur le leg Podman
- `make audit-active` ne signale aucune fuite de ports host-side legacy (`9042/9092`) dans la surface active
- Les tests/unit checks requis passent (`make check`)

---

## 5) Rollback (si incident)

1. `make stop`
2. Restaurer la configuration legacy
3. Relancer explicitement le legacy (si autorisé) :

```bash
ARKEA_ENABLE_BINARY_LEG=1 ARKEA_LEG=binary make start
```

4. Diagnostiquer puis replanifier la migration active.

---

## 6) Notes importantes

- Le leg binary est **bloqué par défaut** (policy guard).
- Les ports `9042/9092` sont fréquemment source de confusion :
  pour le chemin actif host-side, utiliser **9102/9192**.
- Conserver ce guide aligné avec le `Makefile` et `.poc-config.sh`.
