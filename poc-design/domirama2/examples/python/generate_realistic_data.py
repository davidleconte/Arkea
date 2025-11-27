#!/usr/bin/env python3
"""
Génération de 10 000 lignes de données réalistes pour le POC Domirama2
Libellés complexes et variés pour démontrer le full-text search
"""

import csv
import random
import uuid
from datetime import datetime, timedelta
from decimal import Decimal

# Libellés réalistes et complexes pour opérations bancaires françaises
LIBELLES = [
    # Loyers et charges
    "LOYER MENSUEL APPARTEMENT PARIS 15EME",
    "LOYER JANVIER 2024 PARIS",
    "LOYER FEVRIER 2024 PARIS",
    "LOYER MARS 2024 PARIS",
    "LOYER AVRIL 2024 PARIS",
    "LOYER MAI 2024 PARIS",
    "LOYER JUIN 2024 PARIS",
    "LOYER JUILLET 2024 PARIS",
    "LOYER AOUT 2024 PARIS",
    "LOYER SEPTEMBRE 2024 PARIS",
    "LOYER OCTOBRE 2024 PARIS",
    "LOYER NOVEMBRE 2024 PARIS",
    "LOYER DECEMBRE 2024 PARIS",
    "LOYER IMPAYE PARIS 15EME",
    "LOYER IMPAYE REGULARISATION",
    "REGULARISATION LOYER IMPAYE",
    "CHARGES COPROPRIETE TRIMESTRE 1",
    "CHARGES COPROPRIETE TRIMESTRE 2",
    "CHARGES COPROPRIETE TRIMESTRE 3",
    "CHARGES COPROPRIETE TRIMESTRE 4",
    "TAXE FONCIERE ANNEE 2024",
    "ASSURANCE HABITATION ANNUELLE",
    
    # Alimentation
    "CB CARREFOUR CITY PARIS 15",
    "CB CARREFOUR MARKET RUE DE VAUGIRARD",
    "CB SUPERMARCHE MONOPRIX PARIS",
    "CB LECLERC DRIVE PARIS SUD",
    "CB INTERMARCHE PARIS 15EME",
    "CB CASINO SUPERMARCHE PARIS",
    "CB FRANPRIX PARIS 15",
    "CB ALDI PARIS 15EME",
    "CB LIDL PARIS 15EME",
    "CB BIOMONDE PARIS ORGANIC",
    "CB NATURALIA PARIS BIO",
    "CB GRAND FRAIS PARIS",
    "CB MARCHE DE NEUILLY",
    "CB BOUCHERIE CHARAL PARIS",
    "CB POISSONNERIE PARIS 15",
    "CB FROMAGERIE PARIS 15EME",
    "CB BOULANGERIE PAUL PARIS",
    "CB BOULANGERIE ERIC KAYSER",
    "CB BOULANGERIE MAISON KAYSER",
    
    # Restaurants
    "CB RESTAURANT LE COMPTOIR PARIS",
    "CB RESTAURANT ITALIEN PARIS 15",
    "CB RESTAURANT JAPONAIS SUSHI PARIS",
    "CB RESTAURANT CHINOIS PARIS 15EME",
    "CB RESTAURANT THAI PARIS",
    "CB RESTAURANT INDIEN PARIS 15",
    "CB RESTAURANT FRANCAIS TRADITIONNEL",
    "CB BRASSERIE PARIS 15EME",
    "CB CAFE RESTAURANT PARIS",
    "CB PIZZERIA PARIS 15",
    "CB FAST FOOD MC DONALDS PARIS",
    "CB FAST FOOD BURGER KING PARIS",
    "CB FAST FOOD KFC PARIS 15",
    "CB DELIVEROO PARIS LIVRAISON",
    "CB UBER EATS PARIS LIVRAISON",
    "CB JUST EAT PARIS LIVRAISON",
    
    # Transports
    "CB RATP NAVIGO MOIS JANVIER",
    "CB RATP NAVIGO MOIS FEVRIER",
    "CB RATP NAVIGO MOIS MARS",
    "CB RATP NAVIGO MOIS AVRIL",
    "CB RATP NAVIGO MOIS MAI",
    "CB RATP NAVIGO MOIS JUIN",
    "CB RATP NAVIGO MOIS JUILLET",
    "CB RATP NAVIGO MOIS AOUT",
    "CB RATP NAVIGO MOIS SEPTEMBRE",
    "CB RATP NAVIGO MOIS OCTOBRE",
    "CB RATP NAVIGO MOIS NOVEMBRE",
    "CB RATP NAVIGO MOIS DECEMBRE",
    "CB UBER PARIS TRAJET",
    "CB UBER PARIS COURSE",
    "CB BOLT PARIS TRAJET",
    "CB HEETCH PARIS TRAJET",
    "CB SNCF BILLET TGV PARIS LYON",
    "CB SNCF BILLET TGV PARIS MARSEILLE",
    "CB SNCF BILLET TGV PARIS BORDEAUX",
    "CB SNCF BILLET TER PARIS VERSAILLES",
    "CB AIR FRANCE BILLET PARIS NICE",
    "CB AIR FRANCE BILLET PARIS TOULOUSE",
    "CB TOTAL STATION ESSENCE PARIS",
    "CB SHELL STATION ESSENCE PARIS",
    "CB ESSO STATION ESSENCE PARIS",
    "CB PARKING PARIS 15EME",
    "CB PARKING INDIGO PARIS",
    "CB PARKING QPARK PARIS",
    
    # Utilitaires
    "PRELEVEMENT EDF FACTURE ELECTRICITE",
    "PRELEVEMENT EDF FACTURE JANVIER 2024",
    "PRELEVEMENT EDF FACTURE FEVRIER 2024",
    "PRELEVEMENT EDF FACTURE MARS 2024",
    "PRELEVEMENT ENGIE FACTURE GAZ",
    "PRELEVEMENT ENGIE FACTURE JANVIER 2024",
    "PRELEVEMENT ENGIE FACTURE FEVRIER 2024",
    "PRELEVEMENT ORANGE FACTURE TELEPHONE",
    "PRELEVEMENT ORANGE FACTURE INTERNET",
    "PRELEVEMENT ORANGE FACTURE MOBILE",
    "PRELEVEMENT SFR FACTURE TELEPHONE",
    "PRELEVEMENT SFR FACTURE INTERNET",
    "PRELEVEMENT BOUYGUES FACTURE MOBILE",
    "PRELEVEMENT FREE FACTURE INTERNET",
    "PRELEVEMENT FREE FACTURE MOBILE",
    "PRELEVEMENT VEOLIA FACTURE EAU",
    "PRELEVEMENT SUEZ FACTURE EAU",
    "PRELEVEMENT CANAL PLUS ABONNEMENT",
    "PRELEVEMENT NETFLIX ABONNEMENT",
    "PRELEVEMENT AMAZON PRIME ABONNEMENT",
    "PRELEVEMENT SPOTIFY ABONNEMENT",
    "PRELEVEMENT APPLE MUSIC ABONNEMENT",
    "PRELEVEMENT DISNEY PLUS ABONNEMENT",
    
    # Revenus
    "SALAIRE MENSUEL JANVIER 2024",
    "SALAIRE MENSUEL FEVRIER 2024",
    "SALAIRE MENSUEL MARS 2024",
    "SALAIRE MENSUEL AVRIL 2024",
    "SALAIRE MENSUEL MAI 2024",
    "SALAIRE MENSUEL JUIN 2024",
    "SALAIRE MENSUEL JUILLET 2024",
    "SALAIRE MENSUEL AOUT 2024",
    "SALAIRE MENSUEL SEPTEMBRE 2024",
    "SALAIRE MENSUEL OCTOBRE 2024",
    "SALAIRE MENSUEL NOVEMBRE 2024",
    "SALAIRE MENSUEL DECEMBRE 2024",
    "PRIME ANNUELLE 2024",
    "PRIME EXCEPTIONNELLE 2024",
    "REMBOURSEMENT FRAIS PROFESSIONNELS",
    "ALLOCATION FAMILIALE CAF",
    "PRESTATION ACCUEIL JEUNE ENFANT PAJE",
    "ALLOCATION LOGEMENT APL",
    
    # Virements
    "VIREMENT SEPA VERS COMPTE EPARGNE",
    "VIREMENT SEPA VERS COMPTE COURANT",
    "VIREMENT SEPA REMBOURSEMENT AMI",
    "VIREMENT SEPA REMBOURSEMENT COLLOC",
    "VIREMENT SEPA REMBOURSEMENT FAMILLE",
    "VIREMENT SEPA PAIEMENT FACTURE",
    "VIREMENT SEPA PAIEMENT PRESTATAIRE",
    "VIREMENT SEPA PAIEMENT ASSOCIATION",
    "VIREMENT SEPA VERS ASSURANCE VIE",
    "VIREMENT SEPA VERS PEL",
    "VIREMENT SEPA VERS LIVRET A",
    "VIREMENT SEPA VERS LDDS",
    "VIREMENT IMPAYE RETOUR",
    "VIREMENT IMPAYE REFUSE",
    "VIREMENT IMPAYE INSUFFISANCE FONDS",
    "VIREMENT IMPAYE COMPTE CLOS",
    "VIREMENT IMPAYE REGULARISATION",
    "VIREMENT IMPAYE PARIS BANQUE",
    "VIREMENT IMPAYE REMBOURSEMENT",
    
    # Loisirs
    "CB AMAZON FR ACHAT EN LIGNE",
    "CB AMAZON FR LIVRAISON PRIME",
    "CB FNAC PARIS ACHAT",
    "CB DARTY PARIS ACHAT",
    "CB BOULANGER PARIS ACHAT",
    "CB CULTURE PARIS LIVRES",
    "CB DECATHLON PARIS SPORT",
    "CB GO SPORT PARIS EQUIPEMENT",
    "CB ZARA PARIS VETEMENTS",
    "CB H&M PARIS VETEMENTS",
    "CB UNIQLO PARIS VETEMENTS",
    "CB CINEMA UGC PARIS",
    "CB CINEMA PATHE PARIS",
    "CB CINEMA MK2 PARIS",
    "CB THEATRE PARIS BILLET",
    "CB CONCERT PARIS BILLET",
    "CB SPECTACLE PARIS BILLET",
    "CB MUSEE PARIS ENTREE",
    "CB PARC ATTRACTIONS DISNEYLAND",
    "CB PARC ASTRIX ENTREE",
    "CB SPORT CLUB FITNESS PARIS",
    "CB PISCINE PARIS ABONNEMENT",
    "CB TENNIS CLUB PARIS ABONNEMENT",
    "CB GOLF CLUB PARIS ABONNEMENT",
    
    # Santé
    "CB PHARMACIE PARIS 15EME",
    "CB PHARMACIE PARIS MEDICAMENTS",
    "CB OPTICIEN PARIS LUNETTES",
    "CB DENTISTE PARIS CONSULTATION",
    "CB MEDECIN PARIS CONSULTATION",
    "CB KINE PARIS SEANCE",
    "CB LABORATOIRE ANALYSES PARIS",
    "CB HOPITAL PARIS FRAIS",
    "CB MUTUELLE REMBOURSEMENT",
    
    # Assurances
    "PRELEVEMENT ASSURANCE AUTO",
    "PRELEVEMENT ASSURANCE HABITATION",
    "PRELEVEMENT ASSURANCE SANTE",
    "PRELEVEMENT ASSURANCE VIE",
    "PRELEVEMENT ASSURANCE PREVOYANCE",
    
    # Banque
    "FRAIS BANCAIRES TENUE DE COMPTE",
    "FRAIS BANCAIRES CARTE BLEUE",
    "FRAIS BANCAIRES DECOUVERT",
    "AGIOS DECOUVERT AUTORISE",
    "COMMISSION INTERVENTION",
    "REMBOURSEMENT FRAIS BANCAIRES",
    
    # Divers
    "CB COIFFEUR PARIS COUPE",
    "CB COIFFEUR PARIS COLORATION",
    "CB ESTHETICIENNE PARIS SOIN",
    "CB MANUCURE PARIS ONGLES",
    "CB PRESSING PARIS NETTOYAGE",
    "CB LAVERIE PARIS LAVAGE",
    "CB BUREAU DE TABAC PARIS",
    "CB LIBRAIRIE PARIS LIVRES",
    "CB FLEURISTE PARIS FLEURS",
    "CB JARDINERIE PARIS PLANTES",
    
    # Virements avec accents et termes complexes
    "VIREMENT IMPAYE PARIS",
    "VIREMENT IMPAYE REGULARISATION",
    "VIREMENT IMPAYE RETOUR",
    "VIREMENT IMPAYE REFUSE",
    "VIREMENT IMPAYE INSUFFISANCE",
    "VIREMENT IMPAYE COMPTE CLOS",
    "VIREMENT IMPAYE REMBOURSEMENT",
    "VIREMENT IMPAYE PARIS BANQUE",
    
    # Loyers avec localisation
    "LOYER IMPAYE PARIS 15EME",
    "LOYER IMPAYE PARIS 16EME",
    "LOYER IMPAYE PARIS 17EME",
    "LOYER IMPAYE REGULARISATION",
    "LOYER PARIS APPARTEMENT",
    "LOYER PARIS STUDIO",
    "LOYER PARIS MAISON",
]

CATEGORIES = {
    "LOYER": "HABITATION",
    "CHARGES": "HABITATION",
    "TAXE": "HABITATION",
    "ASSURANCE HABITATION": "HABITATION",
    "CARREFOUR": "ALIMENTATION",
    "SUPERMARCHE": "ALIMENTATION",
    "MONOPRIX": "ALIMENTATION",
    "LECLERC": "ALIMENTATION",
    "INTERMARCHE": "ALIMENTATION",
    "CASINO": "ALIMENTATION",
    "FRANPRIX": "ALIMENTATION",
    "ALDI": "ALIMENTATION",
    "LIDL": "ALIMENTATION",
    "BIO": "ALIMENTATION",
    "MARCHE": "ALIMENTATION",
    "BOUCHERIE": "ALIMENTATION",
    "POISSONNERIE": "ALIMENTATION",
    "FROMAGERIE": "ALIMENTATION",
    "BOULANGERIE": "ALIMENTATION",
    "RESTAURANT": "RESTAURANT",
    "BRASSERIE": "RESTAURANT",
    "CAFE": "RESTAURANT",
    "PIZZERIA": "RESTAURANT",
    "FAST FOOD": "RESTAURANT",
    "DELIVEROO": "RESTAURANT",
    "UBER EATS": "RESTAURANT",
    "JUST EAT": "RESTAURANT",
    "RATP": "TRANSPORT",
    "NAVIGO": "TRANSPORT",
    "UBER": "TRANSPORT",
    "BOLT": "TRANSPORT",
    "HEETCH": "TRANSPORT",
    "SNCF": "TRANSPORT",
    "TGV": "TRANSPORT",
    "TER": "TRANSPORT",
    "AIR FRANCE": "TRANSPORT",
    "ESSENCE": "TRANSPORT",
    "STATION": "TRANSPORT",
    "PARKING": "TRANSPORT",
    "EDF": "UTILITAIRES",
    "ENGIE": "UTILITAIRES",
    "ORANGE": "UTILITAIRES",
    "SFR": "UTILITAIRES",
    "BOUYGUES": "UTILITAIRES",
    "FREE": "UTILITAIRES",
    "VEOLIA": "UTILITAIRES",
    "SUEZ": "UTILITAIRES",
    "CANAL": "UTILITAIRES",
    "NETFLIX": "UTILITAIRES",
    "AMAZON PRIME": "UTILITAIRES",
    "SPOTIFY": "UTILITAIRES",
    "APPLE MUSIC": "UTILITAIRES",
    "DISNEY": "UTILITAIRES",
    "SALAIRE": "REVENUS",
    "PRIME": "REVENUS",
    "REMBOURSEMENT FRAIS": "REVENUS",
    "ALLOCATION": "REVENUS",
    "PRESTATION": "REVENUS",
    "VIREMENT": "VIREMENT",
    "AMAZON": "LOISIRS",
    "FNAC": "LOISIRS",
    "DARTY": "LOISIRS",
    "BOULANGER": "LOISIRS",
    "CULTURE": "LOISIRS",
    "DECATHLON": "LOISIRS",
    "GO SPORT": "LOISIRS",
    "ZARA": "LOISIRS",
    "H&M": "LOISIRS",
    "UNIQLO": "LOISIRS",
    "CINEMA": "LOISIRS",
    "THEATRE": "LOISIRS",
    "CONCERT": "LOISIRS",
    "SPECTACLE": "LOISIRS",
    "MUSEE": "LOISIRS",
    "PARC": "LOISIRS",
    "SPORT": "LOISIRS",
    "FITNESS": "LOISIRS",
    "PISCINE": "LOISIRS",
    "TENNIS": "LOISIRS",
    "GOLF": "LOISIRS",
    "PHARMACIE": "SANTE",
    "OPTICIEN": "SANTE",
    "DENTISTE": "SANTE",
    "MEDECIN": "SANTE",
    "KINE": "SANTE",
    "LABORATOIRE": "SANTE",
    "HOPITAL": "SANTE",
    "MUTUELLE": "SANTE",
    "ASSURANCE": "ASSURANCE",
    "FRAIS BANCAIRES": "BANQUE",
    "AGIOS": "BANQUE",
    "COMMISSION": "BANQUE",
}

TYPES_OPERATION = ["VIREMENT", "CARTE", "PRELEVEMENT", "CHEQUE"]
SENS_OPERATION = ["DEBIT", "CREDIT"]

def get_category(libelle):
    """Détermine la catégorie automatique basée sur le libellé"""
    libelle_upper = libelle.upper()
    for keyword, category in CATEGORIES.items():
        if keyword in libelle_upper:
            return category
    return "DIVERS"

def get_confidence(libelle):
    """Génère un score de confiance réaliste"""
    # Plus le libellé est spécifique, plus la confiance est élevée
    if any(keyword in libelle.upper() for keyword in ["LOYER", "SALAIRE", "EDF", "ORANGE"]):
        return round(random.uniform(0.90, 0.99), 2)
    elif any(keyword in libelle.upper() for keyword in ["CB", "PRELEVEMENT", "VIREMENT"]):
        return round(random.uniform(0.75, 0.95), 2)
    else:
        return round(random.uniform(0.60, 0.85), 2)

def generate_date(start_date, end_date):
    """Génère une date aléatoire entre start_date et end_date"""
    time_between = end_date - start_date
    days_between = time_between.days
    random_days = random.randrange(days_between)
    return start_date + timedelta(days=random_days)

def generate_amount(libelle, sens):
    """Génère un montant réaliste basé sur le libellé et le sens"""
    libelle_upper = libelle.upper()
    
    if sens == "CREDIT":
        if "SALAIRE" in libelle_upper:
            return round(random.uniform(2000, 5000), 2)
        elif "PRIME" in libelle_upper:
            return round(random.uniform(500, 2000), 2)
        elif "ALLOCATION" in libelle_upper or "PRESTATION" in libelle_upper:
            return round(random.uniform(100, 500), 2)
        elif "REMBOURSEMENT" in libelle_upper:
            return round(random.uniform(50, 300), 2)
        else:
            return round(random.uniform(100, 1000), 2)
    else:  # DEBIT
        if "LOYER" in libelle_upper:
            return round(random.uniform(-800, -1500), 2)
        elif "CHARGES" in libelle_upper:
            return round(random.uniform(-200, -500), 2)
        elif "EDF" in libelle_upper or "ENGIE" in libelle_upper:
            return round(random.uniform(-50, -150), 2)
        elif "ORANGE" in libelle_upper or "SFR" in libelle_upper or "FREE" in libelle_upper:
            return round(random.uniform(-30, -80), 2)
        elif "NAVIGO" in libelle_upper:
            return round(random.uniform(-70, -80), 2)
        elif "RESTAURANT" in libelle_upper or "BRASSERIE" in libelle_upper:
            return round(random.uniform(-20, -80), 2)
        elif "FAST FOOD" in libelle_upper:
            return round(random.uniform(-10, -30), 2)
        elif "SUPERMARCHE" in libelle_upper or "CARREFOUR" in libelle_upper:
            return round(random.uniform(-30, -150), 2)
        elif "AMAZON" in libelle_upper:
            return round(random.uniform(-10, -200), 2)
        elif "CINEMA" in libelle_upper or "THEATRE" in libelle_upper:
            return round(random.uniform(-10, -30), 2)
        elif "ESSENCE" in libelle_upper or "STATION" in libelle_upper:
            return round(random.uniform(-40, -80), 2)
        elif "PARKING" in libelle_upper:
            return round(random.uniform(-5, -20), 2)
        else:
            return round(random.uniform(-10, -100), 2)

def main():
    output_file = "poc-design/domirama2/data/operations_10000.csv"
    
    # Générer 10 000 lignes
    num_lines = 10000
    
    # Dates sur 2 ans (2023-2024)
    start_date = datetime(2023, 1, 1)
    end_date = datetime(2024, 12, 31)
    
    # Comptes variés
    codes_si = ["01", "02", "03"]
    contrats = [f"{random.randint(1000000000, 9999999999)}" for _ in range(50)]  # 50 comptes différents
    
    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        
        # En-tête
        writer.writerow([
            "code_si", "contrat", "date_iso", "seq", "libelle", "montant", 
            "devise", "type_operation", "sens_operation", "categorie_auto", 
            "categorie_client", "cat_confidence"
        ])
        
        # Générer les lignes
        seq_by_account = {}  # Suivi des séquences par compte
        
        for i in range(num_lines):
            code_si = random.choice(codes_si)
            contrat = random.choice(contrats)
            
            # Gérer la séquence par compte
            account_key = f"{code_si}_{contrat}"
            if account_key not in seq_by_account:
                seq_by_account[account_key] = 0
            seq_by_account[account_key] += 1
            seq = seq_by_account[account_key]
            
            # Générer une date aléatoire
            op_date = generate_date(start_date, end_date)
            date_iso = op_date.strftime("%Y-%m-%dT%H:%M:%SZ")
            
            # Libellé aléatoire
            libelle = random.choice(LIBELLES)
            
            # Sens et type d'opération
            if "SALAIRE" in libelle.upper() or "PRIME" in libelle.upper() or "ALLOCATION" in libelle.upper():
                sens = "CREDIT"
                type_op = "VIREMENT"
            elif "PRELEVEMENT" in libelle.upper():
                sens = "DEBIT"
                type_op = "PRELEVEMENT"
            elif "CB" in libelle:
                sens = "DEBIT"
                type_op = "CARTE"
            elif "VIREMENT" in libelle.upper():
                sens = random.choice(["DEBIT", "CREDIT"])
                type_op = "VIREMENT"
            else:
                sens = random.choice(SENS_OPERATION)
                type_op = random.choice(TYPES_OPERATION)
            
            # Montant
            montant = generate_amount(libelle, sens)
            
            # Catégorie et confiance
            categorie_auto = get_category(libelle)
            cat_confidence = get_confidence(libelle)
            
            # Écrire la ligne
            writer.writerow([
                code_si,
                contrat,
                date_iso,
                seq,
                libelle,
                f"{montant:.2f}",
                "EUR",
                type_op,
                sens,
                categorie_auto,
                "",  # categorie_client vide (batch)
                f"{cat_confidence:.2f}"
            ])
            
            if (i + 1) % 1000 == 0:
                print(f"✅ {i + 1} lignes générées...")
    
    print(f"\n✅ {num_lines} lignes générées dans {output_file}")
    print(f"📊 Statistiques:")
    print(f"   - {len(contrats)} comptes différents")
    print(f"   - {len(LIBELLES)} libellés uniques")
    print(f"   - Période: {start_date.date()} à {end_date.date()}")

if __name__ == "__main__":
    main()

