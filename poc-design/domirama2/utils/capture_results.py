#!/usr/bin/env python3
"""
Module réutilisable pour capturer les résultats des requêtes CQL
et les sauvegarder dans un format JSON structuré pour documentation.
"""

import json
import sys
from decimal import Decimal
from datetime import datetime
from typing import List, Dict, Any, Optional


def decimal_default(obj):
    """Convertit Decimal en float pour JSON."""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Type {type(obj)} not serializable")


class ResultCapture:
    """Classe pour capturer et structurer les résultats de tests."""
    
    def __init__(self, output_file: str):
        """
        Initialise le captureur de résultats.
        
        Args:
            output_file: Chemin du fichier JSON de sortie
        """
        self.output_file = output_file
        self.tests: List[Dict[str, Any]] = []
        self.metadata = {
            "generated_at": datetime.now().isoformat(),
            "script": sys.argv[0] if sys.argv else "unknown"
        }
    
    def start_test(self, 
                   test_number: int,
                   query: str,
                   description: str,
                   expected: str,
                   cql_query: Optional[str] = None,
                   **kwargs) -> Dict[str, Any]:
        """
        Démarre un nouveau test et retourne la structure de données.
        
        Args:
            test_number: Numéro du test
            query: Requête de recherche
            description: Description du test
            expected: Résultat attendu
            cql_query: Requête CQL (optionnelle)
            **kwargs: Autres métadonnées du test
        
        Returns:
            Dictionnaire de structure de test
        """
        test_structure = {
            "test_number": test_number,
            "query": query,
            "description": description,
            "expected": expected,
            "cql_query": cql_query,
            "results": [],
            "success": False,
            "error": None,
            "query_time": None,
            "encoding_time": None,
            "validation": None,
            **kwargs
        }
        self.tests.append(test_structure)
        return test_structure
    
    def add_result(self, 
                   test_structure: Dict[str, Any],
                   rank: int,
                   **row_data):
        """
        Ajoute un résultat à un test.
        
        Args:
            test_structure: Structure de test retournée par start_test
            rank: Rang du résultat
            **row_data: Données de la ligne (libelle, montant, etc.)
        """
        result = {
            "rank": rank,
            **row_data
        }
        # Convertir Decimal en float
        for key, value in result.items():
            if isinstance(value, Decimal):
                result[key] = float(value)
        
        test_structure["results"].append(result)
    
    def finalize_test(self,
                     test_structure: Dict[str, Any],
                     success: bool = True,
                     query_time: Optional[float] = None,
                     encoding_time: Optional[float] = None,
                     validation: Optional[str] = None,
                     error: Optional[str] = None):
        """
        Finalise un test avec les métriques.
        
        Args:
            test_structure: Structure de test
            success: Succès ou échec
            query_time: Temps d'exécution de la requête
            encoding_time: Temps d'encodage (si applicable)
            validation: Message de validation
            error: Message d'erreur (si applicable)
        """
        test_structure["success"] = success
        if query_time is not None:
            test_structure["query_time"] = query_time
        if encoding_time is not None:
            test_structure["encoding_time"] = encoding_time
        if validation:
            test_structure["validation"] = validation
        if error:
            test_structure["error"] = error
    
    def save(self):
        """Sauvegarde tous les résultats dans le fichier JSON."""
        output = {
            "metadata": self.metadata,
            "tests": self.tests
        }
        
        with open(self.output_file, 'w', encoding='utf-8') as f:
            json.dump(output, f, indent=2, ensure_ascii=False, default=decimal_default)
    
    @staticmethod
    def load_from_file(file_path: str) -> Dict[str, Any]:
        """
        Charge les résultats depuis un fichier JSON.
        
        Args:
            file_path: Chemin du fichier JSON
        
        Returns:
            Dictionnaire avec metadata et tests
        """
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)


def generate_markdown_results(results_file: str) -> str:
    """
    Génère la section markdown des résultats à partir d'un fichier JSON.
    
    Args:
        results_file: Chemin du fichier JSON de résultats
    
    Returns:
        Chaîne markdown formatée
    """
    try:
        data = ResultCapture.load_from_file(results_file)
        tests = data.get("tests", [])
        
        markdown = "### Résultats Réels des Requêtes CQL\n\n"
        
        for test in tests:
            test_num = test.get("test_number", 0)
            query = test.get("query", "N/A")
            description = test.get("description", "N/A")
            expected = test.get("expected", "N/A")
            strategy_used = test.get("strategy_used", test.get("strategy", "N/A"))
            query_time = test.get("query_time", 0)
            encoding_time = test.get("encoding_time", 0)
            success = test.get("success", False)
            error = test.get("error")
            validation = test.get("validation", "N/A")
            test_results = test.get("results", [])
            cql_query = test.get("cql_query_hybrid") or test.get("cql_query_vector") or test.get("cql_query", "N/A")
            
            markdown += f"#### TEST {test_num} : '{query}'\n\n"
            markdown += f"**Description** : {description}\n"
            markdown += f"**Résultat attendu** : {expected}\n"
            if strategy_used != "N/A":
                markdown += f"**Stratégie utilisée** : {strategy_used}\n"
            if encoding_time:
                markdown += f"**Temps d'encodage** : {encoding_time:.3f}s\n"
            if query_time:
                markdown += f"**Temps d'exécution** : {query_time:.3f}s\n"
            markdown += f"**Statut** : {'✅ Succès' if success else '❌ Échec'}\n"
            if error:
                markdown += f"**Erreur** : {error}\n"
            if validation:
                markdown += f"**Validation** : {validation}\n"
            markdown += "\n"
            
            if cql_query and cql_query != "N/A":
                markdown += "**Requête CQL exécutée :**\n\n"
                markdown += "\\`\\`\\`cql\n"
                # Tronquer les vecteurs longs pour lisibilité
                import re
                cql_query_short = re.sub(r'ANN OF \[.*?\]', 'ANN OF [...]', cql_query, flags=re.DOTALL)
                markdown += cql_query_short + "\n"
                markdown += "\\`\\`\\`\n\n"
            
            if test_results:
                markdown += f"**Résultats obtenus ({len(test_results)} résultat(s)) :**\n\n"
                # Déterminer les colonnes disponibles
                columns = set()
                for result in test_results:
                    columns.update(result.keys())
                columns.discard("rank")
                
                # Créer le tableau
                header_cols = ["Rang"] + sorted([c for c in columns if c != "rank"])
                markdown += "| " + " | ".join(header_cols) + " |\n"
                markdown += "|" + "|".join(["------"] * len(header_cols)) + "|\n"
                
                for result in test_results:
                    row = [str(result.get("rank", "N/A"))]
                    for col in sorted([c for c in columns if c != "rank"]):
                        value = result.get(col, "N/A")
                        if isinstance(value, float):
                            value = f"{value:.2f}"
                        elif value and isinstance(value, str) and len(value) > 60:
                            value = value[:57] + "..."
                        row.append(str(value))
                    markdown += "| " + " | ".join(row) + " |\n"
                markdown += "\n"
            else:
                markdown += "**Aucun résultat trouvé**\n\n"
            
            markdown += "---\n\n"
        
        return markdown
        
    except Exception as e:
        return f"**Erreur lors de la génération des résultats détaillés**\n\nErreur : {str(e)}\n"


if __name__ == "__main__":
    # Exemple d'utilisation
    if len(sys.argv) < 2:
        print("Usage: python capture_results.py <results_file.json>")
        sys.exit(1)
    
    results_file = sys.argv[1]
    markdown = generate_markdown_results(results_file)
    print(markdown)



