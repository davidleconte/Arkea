# ============================================
# Exemple d'Implémentation Time Travel en Python
# ============================================

from datetime import datetime
from typing import Optional
from dataclasses import dataclass

@dataclass
class Operation:
    """Modèle d'opération"""
    code_si: str
    contrat: str
    date_op: datetime
    numero_op: int
    cat_auto: str
    cat_confidence: Optional[float]
    cat_user: Optional[str]
    cat_date_user: Optional[datetime]
    cat_validee: bool

@dataclass
class OperationWithCategory:
    """Opération avec catégorie calculée (Time Travel)"""
    operation: Operation
    category_at_date: str
    source: str  # "CLIENT" ou "BATCH"
    query_date: datetime

class OperationService:
    """Service pour gérer les opérations avec Time Travel"""
    
    def __init__(self, repository):
        self.repository = repository
    
    def get_category_at_date(
        self, 
        operation: Operation, 
        query_date: datetime
    ) -> str:
        """
        Détermine la catégorie valide à une date donnée (Time Travel)
        
        Args:
            operation: L'opération avec cat_auto, cat_user, cat_date_user
            query_date: La date pour laquelle on veut connaître la catégorie
            
        Returns:
            La catégorie valide à cette date
        """
        # Si correction client existe ET date de correction <= date de requête
        if (operation.cat_user 
            and operation.cat_date_user 
            and operation.cat_date_user <= query_date):
            return operation.cat_user  # Correction client était en place
        
        # Sinon, utiliser la catégorie batch
        return operation.cat_auto
    
    def get_operation_with_category(
        self,
        code_si: str,
        contrat: str,
        date_op: datetime,
        numero_op: int,
        query_date: datetime
    ) -> OperationWithCategory:
        """
        Récupère une opération avec sa catégorie valide à une date donnée
        """
        # 1. Récupérer l'opération depuis HCD
        operation = self.repository.find_by_key(
            code_si, contrat, date_op, numero_op
        )
        
        if operation is None:
            raise ValueError(
                f"Operation not found: {code_si}/{contrat}/{date_op}/{numero_op}"
            )
        
        # 2. Appliquer la logique Time Travel
        category_at_date = self.get_category_at_date(operation, query_date)
        source = "CLIENT" if category_at_date == operation.cat_user else "BATCH"
        
        return OperationWithCategory(
            operation=operation,
            category_at_date=category_at_date,
            source=source,
            query_date=query_date
        )

