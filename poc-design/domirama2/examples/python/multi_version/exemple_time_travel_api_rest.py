# ============================================
# Exemple d'API REST avec Time Travel (FastAPI)
# ============================================

from fastapi import FastAPI, HTTPException, Query
from datetime import datetime
from typing import Optional
from pydantic import BaseModel

app = FastAPI(title="Domirama API with Time Travel")

# Modèles
class OperationResponse(BaseModel):
    """Réponse avec opération et catégorie Time Travel"""
    code_si: str
    contrat: str
    date_op: datetime
    numero_op: int
    libelle: str
    montant: float
    cat_auto: str
    cat_confidence: Optional[float]
    cat_user: Optional[str]
    cat_date_user: Optional[datetime]
    cat_validee: bool
    # Champs Time Travel
    category_at_date: str
    source: str  # "CLIENT" ou "BATCH"
    query_date: datetime

@app.get("/api/v1/operations/{code_si}/{contrat}/{date_op}/{numero_op}")
async def get_operation(
    code_si: str,
    contrat: str,
    date_op: datetime,
    numero_op: int,
    as_of: Optional[datetime] = Query(
        None, 
        description="Date pour Time Travel (défaut: maintenant)"
    )
) -> OperationResponse:
    """
    Récupère une opération avec Time Travel
    
    Exemple:
        GET /api/v1/operations/DEMO_MV/DEMO_001/2024-01-15T10:00:00/1?as_of=2024-01-20T09:00:00
    """
    from operation_service import OperationService
    from operation_repository import OperationRepository
    
    # Si as_of n'est pas fourni, utiliser la date actuelle
    query_date = as_of if as_of else datetime.now()
    
    # Service avec Time Travel
    service = OperationService(OperationRepository())
    
    try:
        result = service.get_operation_with_category(
            code_si, contrat, date_op, numero_op, query_date
        )
        
        operation = result.operation
        
        return OperationResponse(
            code_si=operation.code_si,
            contrat=operation.contrat,
            date_op=operation.date_op,
            numero_op=operation.numero_op,
            libelle=operation.libelle,
            montant=operation.montant,
            cat_auto=operation.cat_auto,
            cat_confidence=operation.cat_confidence,
            cat_user=operation.cat_user,
            cat_date_user=operation.cat_date_user,
            cat_validee=operation.cat_validee,
            category_at_date=result.category_at_date,
            source=result.source,
            query_date=query_date
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@app.get("/api/v1/operations/{code_si}/{contrat}")
async def get_operations(
    code_si: str,
    contrat: str,
    as_of: Optional[datetime] = Query(
        None,
        description="Date pour Time Travel (défaut: maintenant)"
    )
) -> list[OperationResponse]:
    """
    Récupère toutes les opérations d'un compte avec Time Travel
    
    Exemple:
        GET /api/v1/operations/DEMO_MV/DEMO_001?as_of=2024-01-20T09:00:00
    """
    query_date = as_of if as_of else datetime.now()
    
    # Implémentation similaire pour liste d'opérations
    # ...
    
    return []

