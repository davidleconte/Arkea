#!/usr/bin/env python3
"""
Script de vérification de cohérence des résultats du script 24
Vérifie la présence des données attendues et la génération des embeddings
"""

from cassandra.cluster import Cluster

# Configuration
HOST = "localhost"
PORT = 9042
KEYSPACE = "domirama2_poc"
CODE_SI = "1"
CONTRAT = "5913101072"

# Connexion à HCD
print("📡 Connexion à HCD...")
cluster = Cluster([HOST], port=PORT)
session = cluster.connect(KEYSPACE)
print("✅ Connecté à HCD\n")

# 1. Vérifier le nombre total de lignes et embeddings
print("=" * 70)
print("  📊 VÉRIFICATION 1 : Nombre de lignes et embeddings")
print("=" * 70)
total_query = """
SELECT COUNT(*) as total,
       COUNT(libelle_embedding) as avec_embedding
FROM operations_by_account
WHERE code_si = '{CODE_SI}'
  AND contrat = '{CONTRAT}';
"""
result = session.execute(total_query).one()
total = result.total if result else 0
avec_embedding = result.avec_embedding if result else 0
print(f"   Total de lignes : {total}")
print(f"   Avec embeddings : {avec_embedding}")
print(f"   Pourcentage : {(avec_embedding/total*100) if total > 0 else 0:.1f}%")
print()

# 2. Récupérer tous les libellés de la partition
print("=" * 70)
print("  📊 VÉRIFICATION 2-5 : Analyse des libellés dans la partition")
print("=" * 70)
all_libelles_query = """
SELECT libelle, libelle_embedding
FROM operations_by_account
WHERE code_si = '{CODE_SI}'
  AND contrat = '{CONTRAT}';
"""
all_results = list(session.execute(all_libelles_query))
print(f"   Total de libellés récupérés : {len(all_results)}")
print()

# Filtrer les libellés pertinents et vérifier les embeddings
loyer_libelles = []
impaye_libelles = []
virement_libelles = []
paris_libelles = []

for r in all_results:
    libelle = r.libelle
    has_embedding = r.libelle_embedding is not None
    row_data = type("obj", (object,), {"libelle": libelle, "has_embedding": has_embedding})()

    if "LOYER" in libelle.upper():
        loyer_libelles.append(row_data)
    if "IMPAYE" in libelle.upper():
        impaye_libelles.append(row_data)
    if "VIREMENT" in libelle.upper():
        virement_libelles.append(row_data)
    if "PARIS" in libelle.upper():
        paris_libelles.append(row_data)

# 2. Vérifier la présence de LOYER
print("  📊 VÉRIFICATION 2 : Présence de libellés contenant 'LOYER'")
print(f"   Nombre de résultats : {len(loyer_libelles)}")
if loyer_libelles:
    print("   Exemples de libellés trouvés :")
    for i, row in enumerate(loyer_libelles[:5], 1):
        status = "✅" if row.has_embedding else "❌"
        print(f"   {status} {i}. {row.libelle}")
else:
    print("   ⚠️  Aucun libellé contenant 'LOYER' trouvé")
print()

# 3. Vérifier la présence de IMPAYE
print("  📊 VÉRIFICATION 3 : Présence de libellés contenant 'IMPAYE'")
print(f"   Nombre de résultats : {len(impaye_libelles)}")
if impaye_libelles:
    print("   Exemples de libellés trouvés :")
    for i, row in enumerate(impaye_libelles[:5], 1):
        status = "✅" if row.has_embedding else "❌"
        print(f"   {status} {i}. {row.libelle}")
else:
    print("   ⚠️  Aucun libellé contenant 'IMPAYE' trouvé")
print()

# 4. Vérifier la présence de VIREMENT
print("  📊 VÉRIFICATION 4 : Présence de libellés contenant 'VIREMENT'")
print(f"   Nombre de résultats : {len(virement_libelles)}")
if virement_libelles:
    print("   Exemples de libellés trouvés :")
    for i, row in enumerate(virement_libelles[:5], 1):
        status = "✅" if row.has_embedding else "❌"
        print(f"   {status} {i}. {row.libelle}")
else:
    print("   ⚠️  Aucun libellé contenant 'VIREMENT' trouvé")
print()

# 5. Vérifier la présence de PARIS
print("  📊 VÉRIFICATION 5 : Présence de libellés contenant 'PARIS'")
print(f"   Nombre de résultats : {len(paris_libelles)}")
if paris_libelles:
    print("   Exemples de libellés trouvés :")
    for i, row in enumerate(paris_libelles[:5], 1):
        status = "✅" if row.has_embedding else "❌"
        print(f"   {status} {i}. {row.libelle}")
else:
    print("   ⚠️  Aucun libellé contenant 'PARIS' trouvé")
print()

# 6. Liste des libellés distincts dans la partition
print("=" * 70)
print("  📊 VÉRIFICATION 6 : Liste des libellés distincts (échantillon)")
print("=" * 70)
distinct_libelles = list(set([r.libelle for r in all_results]))
print(f"   Nombre de libellés distincts : {len(distinct_libelles)}")
if distinct_libelles:
    print("   Exemples de libellés (20 premiers) :")
    for i, libelle in enumerate(distinct_libelles[:20], 1):
        print(f"   {i}. {libelle}")
print()

# Résumé
print("=" * 70)
print("  📊 RÉSUMÉ DE LA VÉRIFICATION")
print("=" * 70)
print(f"   ✅ Total de lignes : {total}")
print(
    f"   ✅ Avec embeddings : {avec_embedding} ({(avec_embedding/total*100) if total > 0 else 0:.1f}%)"
)
print()

cluster.shutdown()
print("✅ Vérification terminée")
