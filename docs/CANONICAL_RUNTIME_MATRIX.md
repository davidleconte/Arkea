# CANONICAL_RUNTIME_MATRIX.md

**Date** : 2026-03-18
**POC** : Arkea — Migration HBase/HCD vers Cassandra OSS 5.0
**TL;DR** : Le chemin **actif par défaut** est `ARKEA_LEG=podman` avec ports hôte `9102` (CQL) et `9192` (Kafka). Le leg `binary` est historique et bloqué par défaut.

---

## 1) Runtime Matrix (Source de vérité)

| Dimension | Active Leg (`podman`) | Legacy Leg (`binary`) |
|---|---|---|
| Statut | ✅ Par défaut | ⚠️ Historique / bloqué par défaut |
| Variable | `ARKEA_LEG=podman` | `ARKEA_LEG=binary` |
| Garde-fou | N/A | nécessite `ARKEA_ENABLE_BINARY_LEG=1` |
| Backend | Cassandra OSS 5.0.x | HCD 1.2.3 |
| Java | **17** | **11** |
| Port hôte CQL | **9102** | 9042 |
| Port hôte Kafka | **9192** | 9092 |
| Port interne Cassandra (conteneur) | 9042 | N/A |
| Port interne Kafka (conteneur) | 9092 | N/A |

---

## 2) Mapping ports (important)

Utiliser ces ports **depuis la machine hôte** :

- Cassandra/CQL : `localhost:9102`
- Kafka : `localhost:9192`
- Spark Master UI : `localhost:9280`

Les ports `9042/9092` restent des ports **internes conteneur** sur le leg Podman.

---

## 3) Commandes canoniques (Active Path)

```bash
make setup
make start
make status
make audit-active
make check
```

### Vérification rapide

```bash
# Snapshot de config active
make audit-active

# Exemple CQL host-side (si cqlsh installé côté hôte)
cqlsh localhost 9102
```

---

## 4) Quand utiliser le leg legacy

Seulement si vous devez reproduire un scénario historique HCD 1.2.3.

```bash
ARKEA_ENABLE_BINARY_LEG=1 ARKEA_LEG=binary make start
```

> Revenir ensuite au chemin actif :
>
> ```bash
> ARKEA_LEG=podman make start
> ```

---

## 5) Règles d’usage

1. **Makefile d’abord** : préférer `make start/stop/status/check` aux scripts individuels.
2. **Un seul leg actif** : éviter les conflits de ports/ressources.
3. **Audit systématique** : exécuter `make audit-active` avant validation PR/demo.
