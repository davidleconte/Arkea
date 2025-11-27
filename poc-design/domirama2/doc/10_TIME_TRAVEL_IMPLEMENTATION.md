# 🕐 Implémentation de la Logique Time Travel

## Question

**Où et comment implémenter la logique Time Travel ?**

```sql
-- Logique Time Travel (application) :
-- Si cat_date_user <= '2024-01-20 09:00' alors cat_user, sinon cat_auto
```

---

## 📍 Options d'Implémentation

### Option 1 : Application (Recommandée) ✅

**Où** : Dans le code applicatif (Java, Python, TypeScript, etc.)

**Comment** : Logique métier dans l'application après récupération des données

#### Exemple Java (Spring Boot)

```java
@Service
public class OperationService {
    
    /**
     * Détermine la catégorie valide à une date donnée (Time Travel)
     * 
     * @param operation L'opération avec cat_auto, cat_user, cat_date_user
     * @param queryDate La date pour laquelle on veut connaître la catégorie
     * @return La catégorie valide à cette date
     */
    public String getCategoryAtDate(Operation operation, LocalDateTime queryDate) {
        // Si correction client existe ET date de correction <= date de requête
        if (operation.getCatUser() != null 
            && operation.getCatDateUser() != null
            && operation.getCatDateUser().isBefore(queryDate) 
            || operation.getCatDateUser().isEqual(queryDate)) {
            return operation.getCatUser(); // Correction client était en place
        }
        
        // Sinon, utiliser la catégorie batch
        return operation.getCatAuto();
    }
    
    /**
     * Récupère une opération avec sa catégorie valide à une date donnée
     */
    public OperationWithCategory getOperationWithCategory(
            String codeSi, String contrat, 
            LocalDateTime dateOp, int numeroOp,
            LocalDateTime queryDate) {
        
        // 1. Récupérer l'opération depuis HCD
        Operation operation = operationRepository.findByKey(
            codeSi, contrat, dateOp, numeroOp);
        
        // 2. Appliquer la logique Time Travel côté application
        String categoryAtDate = getCategoryAtDate(operation, queryDate);
        
        return OperationWithCategory.builder()
            .operation(operation)
            .categoryAtDate(categoryAtDate)
            .source(categoryAtDate.equals(operation.getCatUser()) ? "CLIENT" : "BATCH")
            .build();
    }
}
```

#### Exemple Python (FastAPI)

```python
from datetime import datetime
from typing import Optional

class OperationService:
    """Service pour gérer les opérations avec Time Travel"""
    
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
    ) -> dict:
        """
        Récupère une opération avec sa catégorie valide à une date donnée
        """
        # 1. Récupérer l'opération depuis HCD
        operation = self.repository.find_by_key(
            code_si, contrat, date_op, numero_op
        )
        
        # 2. Appliquer la logique Time Travel côté application
        category_at_date = self.get_category_at_date(operation, query_date)
        
        return {
            "operation": operation,
            "category_at_date": category_at_date,
            "source": "CLIENT" if category_at_date == operation.cat_user else "BATCH"
        }
```

#### Exemple TypeScript (Node.js)

```typescript
interface Operation {
  cat_auto: string | null;
  cat_confidence: number | null;
  cat_user: string | null;
  cat_date_user: Date | null;
  cat_validee: boolean;
}

class OperationService {
  /**
   * Détermine la catégorie valide à une date donnée (Time Travel)
   */
  getCategoryAtDate(
    operation: Operation,
    queryDate: Date
  ): string {
    // Si correction client existe ET date de correction <= date de requête
    if (
      operation.cat_user &&
      operation.cat_date_user &&
      operation.cat_date_user <= queryDate
    ) {
      return operation.cat_user; // Correction client était en place
    }
    
    // Sinon, utiliser la catégorie batch
    return operation.cat_auto || '';
  }
  
  /**
   * Récupère une opération avec sa catégorie valide à une date donnée
   */
  async getOperationWithCategory(
    codeSi: string,
    contrat: string,
    dateOp: Date,
    numeroOp: number,
    queryDate: Date
  ): Promise<{
    operation: Operation;
    categoryAtDate: string;
    source: 'CLIENT' | 'BATCH';
  }> {
    // 1. Récupérer l'opération depuis HCD
    const operation = await this.repository.findByKey(
      codeSi, contrat, dateOp, numeroOp
    );
    
    // 2. Appliquer la logique Time Travel côté application
    const categoryAtDate = this.getCategoryAtDate(operation, queryDate);
    
    return {
      operation,
      categoryAtDate,
      source: categoryAtDate === operation.cat_user ? 'CLIENT' : 'BATCH'
    };
  }
}
```

**Avantages** :
- ✅ Flexibilité maximale (logique métier complexe)
- ✅ Testable unitairement
- ✅ Pas de dépendance aux limitations CQL
- ✅ Peut être mise en cache côté application
- ✅ Logique centralisée et maintenable

**Inconvénients** :
- ⚠️ Nécessite de récupérer toutes les colonnes (cat_auto, cat_user, cat_date_user)
- ⚠️ Logique dupliquée si plusieurs applications

---

### Option 2 : CQL avec CASE (Limité) ⚠️

**Où** : Dans la requête CQL directement

**Problème** : CQL ne supporte pas CASE dans SELECT (limitation Cassandra)

**Tentative (ne fonctionne pas)** :
```cql
-- ❌ NE FONCTIONNE PAS en CQL
SELECT
    cat_auto,
    cat_user,
    cat_date_user,
    CASE
        WHEN cat_user IS NOT NULL AND cat_date_user <= '2024-01-20 09:00:00'
        THEN cat_user
        ELSE cat_auto
    END as categorie_a_la_date
FROM operations_by_account
WHERE ...
```

**Alternative CQL (si supporté dans futures versions)** :
- Cassandra 5.x+ pourrait supporter CASE dans SELECT
- HCD 1.2+ pourrait ajouter cette fonctionnalité

**Avantages** :
- ✅ Logique côté base de données
- ✅ Pas de traitement applicatif

**Inconvénients** :
- ❌ Non supporté actuellement en CQL
- ❌ Limite la flexibilité de la logique

---

### Option 3 : Vue Matérialisée (Alternative) 💡

**Où** : Créer une vue matérialisée avec la logique

**Note** : Cassandra ne supporte pas les vues matérialisées avec logique complexe

**Alternative** : Table dérivée avec colonne calculée (à maintenir)

```cql
-- Table dérivée (à maintenir via triggers ou batch)
CREATE TABLE operations_by_account_with_category (
    code_si TEXT,
    contrat TEXT,
    date_op TIMESTAMP,
    numero_op INT,
    cat_auto TEXT,
    cat_user TEXT,
    cat_date_user TIMESTAMP,
    categorie_finale TEXT,  -- Calculée par batch/trigger
    PRIMARY KEY ((code_si, contrat), date_op DESC, numero_op ASC)
);
```

**Avantages** :
- ✅ Catégorie pré-calculée (performance)

**Inconvénients** :
- ❌ Complexité de maintenance
- ❌ Pas de time travel dynamique (nécessite une colonne par date)

---

### Option 4 : Stored Procedures (Non disponible) ❌

**Où** : Procédures stockées dans Cassandra

**Problème** : Cassandra ne supporte pas les stored procedures

**Alternative** : Utiliser des User-Defined Functions (UDF) si disponibles

```cql
-- ❌ NON DISPONIBLE en Cassandra
CREATE FUNCTION get_category_at_date(
    cat_auto TEXT,
    cat_user TEXT,
    cat_date_user TIMESTAMP,
    query_date TIMESTAMP
) RETURNS TEXT AS $$
    IF cat_user IS NOT NULL AND cat_date_user <= query_date THEN
        RETURN cat_user;
    ELSE
        RETURN cat_auto;
    END IF;
$$;
```

---

### Option 5 : API Layer (Recommandée pour Microservices) ✅

**Où** : Dans une couche API (REST/GraphQL) qui encapsule la logique

#### Exemple REST API (Spring Boot)

```java
@RestController
@RequestMapping("/api/operations")
public class OperationController {
    
    @Autowired
    private OperationService operationService;
    
    /**
     * GET /api/operations/{codeSi}/{contrat}/{dateOp}/{numeroOp}?asOf=2024-01-20T09:00:00
     * 
     * Récupère une opération avec sa catégorie valide à une date donnée (Time Travel)
     */
    @GetMapping("/{codeSi}/{contrat}/{dateOp}/{numeroOp}")
    public ResponseEntity<OperationResponse> getOperation(
            @PathVariable String codeSi,
            @PathVariable String contrat,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateOp,
            @PathVariable int numeroOp,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime asOf) {
        
        // Si asOf n'est pas fourni, utiliser la date actuelle
        LocalDateTime queryDate = (asOf != null) ? asOf : LocalDateTime.now();
        
        // Récupérer l'opération avec Time Travel
        OperationWithCategory result = operationService.getOperationWithCategory(
            codeSi, contrat, dateOp, numeroOp, queryDate);
        
        return ResponseEntity.ok(OperationResponse.builder()
            .operation(result.getOperation())
            .categoryAtDate(result.getCategoryAtDate())
            .source(result.getSource())
            .queryDate(queryDate)
            .build());
    }
}
```

#### Exemple GraphQL (DataStax Data API)

```graphql
type Query {
  operation(
    codeSi: String!
    contrat: String!
    dateOp: DateTime!
    numeroOp: Int!
    asOf: DateTime  # Date pour Time Travel
  ): OperationWithCategory
}

type OperationWithCategory {
  operation: Operation
  categoryAtDate: String
  source: CategorySource  # CLIENT ou BATCH
  queryDate: DateTime
}
```

**Implémentation GraphQL Resolver** :

```java
@Component
public class OperationResolver implements GraphQLQueryResolver {
    
    @Autowired
    private OperationService operationService;
    
    public OperationWithCategory operation(
            String codeSi, String contrat, DateTime dateOp, int numeroOp,
            DateTime asOf) {
        
        LocalDateTime queryDate = (asOf != null) 
            ? asOf.toLocalDateTime() 
            : LocalDateTime.now();
        
        return operationService.getOperationWithCategory(
            codeSi, contrat, dateOp.toLocalDateTime(), numeroOp, queryDate);
    }
}
```

**Avantages** :
- ✅ Logique centralisée dans l'API
- ✅ Réutilisable par tous les clients (web, mobile, etc.)
- ✅ Cache possible au niveau API
- ✅ Versioning API possible

**Inconvénients** :
- ⚠️ Nécessite une couche API supplémentaire

---

## 🎯 Recommandation : Option 1 (Application) + Option 5 (API)

### Architecture Recommandée

```
┌─────────────────────────────────────────────────────────┐
│  Client (Web/Mobile)                                    │
└──────────────────┬──────────────────────────────────────┘
                   │ HTTP/REST ou GraphQL
                   ↓
┌─────────────────────────────────────────────────────────┐
│  API Layer (Spring Boot / FastAPI / Node.js)            │
│  - Logique Time Travel                                  │
│  - Cache (Redis)                                        │
│  - Validation                                           │
└──────────────────┬──────────────────────────────────────┘
                   │ CQL
                   ↓
┌─────────────────────────────────────────────────────────┐
│  HCD (Cassandra)                                        │
│  - Table: operations_by_account                         │
│  - Colonnes: cat_auto, cat_user, cat_date_user         │
└─────────────────────────────────────────────────────────┘
```

### Code Complet d'Exemple

#### Service Layer (Java)

```java
@Service
@Slf4j
public class OperationService {
    
    @Autowired
    private OperationRepository operationRepository;
    
    /**
     * Logique Time Travel : Détermine la catégorie valide à une date donnée
     */
    public String getCategoryAtDate(Operation operation, LocalDateTime queryDate) {
        if (operation.getCatUser() != null 
            && operation.getCatDateUser() != null
            && !operation.getCatDateUser().isAfter(queryDate)) {
            log.debug("Time Travel: cat_user valide à {} (correction du {})", 
                queryDate, operation.getCatDateUser());
            return operation.getCatUser();
        }
        
        log.debug("Time Travel: cat_auto valide à {} (pas de correction client avant cette date)", 
            queryDate);
        return operation.getCatAuto();
    }
    
    /**
     * Récupère une opération avec sa catégorie valide à une date donnée
     */
    public OperationWithCategory getOperationWithCategory(
            String codeSi, String contrat,
            LocalDateTime dateOp, int numeroOp,
            LocalDateTime queryDate) {
        
        // 1. Récupérer l'opération depuis HCD
        Operation operation = operationRepository.findByKey(
            codeSi, contrat, dateOp, numeroOp);
        
        if (operation == null) {
            throw new OperationNotFoundException(
                String.format("Operation not found: %s/%s/%s/%d", 
                    codeSi, contrat, dateOp, numeroOp));
        }
        
        // 2. Appliquer la logique Time Travel
        String categoryAtDate = getCategoryAtDate(operation, queryDate);
        String source = categoryAtDate.equals(operation.getCatUser()) 
            ? "CLIENT" 
            : "BATCH";
        
        return OperationWithCategory.builder()
            .operation(operation)
            .categoryAtDate(categoryAtDate)
            .source(source)
            .queryDate(queryDate)
            .build();
    }
    
    /**
     * Récupère plusieurs opérations avec Time Travel
     */
    public List<OperationWithCategory> getOperationsWithCategory(
            String codeSi, String contrat,
            LocalDateTime queryDate) {
        
        // 1. Récupérer toutes les opérations du compte
        List<Operation> operations = operationRepository.findByAccount(
            codeSi, contrat);
        
        // 2. Appliquer Time Travel à chaque opération
        return operations.stream()
            .map(op -> {
                String categoryAtDate = getCategoryAtDate(op, queryDate);
                String source = categoryAtDate.equals(op.getCatUser()) 
                    ? "CLIENT" 
                    : "BATCH";
                
                return OperationWithCategory.builder()
                    .operation(op)
                    .categoryAtDate(categoryAtDate)
                    .source(source)
                    .queryDate(queryDate)
                    .build();
            })
            .collect(Collectors.toList());
    }
}
```

#### Repository Layer (Cassandra)

```java
@Repository
public interface OperationRepository extends CassandraRepository<Operation, OperationKey> {
    
    /**
     * Récupère une opération par sa clé primaire
     */
    @Query("SELECT * FROM operations_by_account " +
           "WHERE code_si = ?0 AND contrat = ?1 " +
           "AND date_op = ?2 AND numero_op = ?3")
    Operation findByKey(String codeSi, String contrat, 
                       LocalDateTime dateOp, int numeroOp);
    
    /**
     * Récupère toutes les opérations d'un compte
     */
    @Query("SELECT * FROM operations_by_account " +
           "WHERE code_si = ?0 AND contrat = ?1")
    List<Operation> findByAccount(String codeSi, String contrat);
    
    /**
     * Récupère les opérations d'un compte dans une plage de dates
     */
    @Query("SELECT * FROM operations_by_account " +
           "WHERE code_si = ?0 AND contrat = ?1 " +
           "AND date_op >= ?2 AND date_op <= ?3")
    List<Operation> findByAccountAndDateRange(
        String codeSi, String contrat,
        LocalDateTime startDate, LocalDateTime endDate);
}
```

#### Controller (REST API)

```java
@RestController
@RequestMapping("/api/v1/operations")
@Slf4j
public class OperationController {
    
    @Autowired
    private OperationService operationService;
    
    /**
     * GET /api/v1/operations/{codeSi}/{contrat}/{dateOp}/{numeroOp}?asOf=2024-01-20T09:00:00
     * 
     * Récupère une opération avec Time Travel
     */
    @GetMapping("/{codeSi}/{contrat}/{dateOp}/{numeroOp}")
    public ResponseEntity<OperationResponse> getOperation(
            @PathVariable String codeSi,
            @PathVariable String contrat,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
                LocalDateTime dateOp,
            @PathVariable int numeroOp,
            @RequestParam(required = false) 
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
                LocalDateTime asOf) {
        
        try {
            // Si asOf n'est pas fourni, utiliser la date actuelle
            LocalDateTime queryDate = (asOf != null) 
                ? asOf 
                : LocalDateTime.now();
            
            log.info("Time Travel query: operation={}/{}/{}/{} asOf={}", 
                codeSi, contrat, dateOp, numeroOp, queryDate);
            
            // Récupérer avec Time Travel
            OperationWithCategory result = operationService.getOperationWithCategory(
                codeSi, contrat, dateOp, numeroOp, queryDate);
            
            return ResponseEntity.ok(OperationResponse.from(result));
            
        } catch (OperationNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    /**
     * GET /api/v1/operations/{codeSi}/{contrat}?asOf=2024-01-20T09:00:00
     * 
     * Récupère toutes les opérations d'un compte avec Time Travel
     */
    @GetMapping("/{codeSi}/{contrat}")
    public ResponseEntity<List<OperationResponse>> getOperations(
            @PathVariable String codeSi,
            @PathVariable String contrat,
            @RequestParam(required = false) 
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) 
                LocalDateTime asOf) {
        
        LocalDateTime queryDate = (asOf != null) 
            ? asOf 
            : LocalDateTime.now();
        
        List<OperationWithCategory> results = operationService.getOperationsWithCategory(
            codeSi, contrat, queryDate);
        
        return ResponseEntity.ok(results.stream()
            .map(OperationResponse::from)
            .collect(Collectors.toList()));
    }
}
```

---

## 📊 Comparaison des Options

| Option | Où | Avantages | Inconvénients | Recommandation |
|--------|-----|-----------|---------------|----------------|
| **Application** | Code applicatif | ✅ Flexibilité, testable | ⚠️ Logique dupliquée | ✅ **Recommandé** |
| **CQL CASE** | Requête CQL | ✅ Côté base | ❌ Non supporté | ❌ Non disponible |
| **Vue Matérialisée** | Table dérivée | ✅ Performance | ❌ Complexité maintenance | ⚠️ Si besoin performance |
| **Stored Procedures** | Base de données | ✅ Centralisé | ❌ Non disponible | ❌ Non disponible |
| **API Layer** | Couche API | ✅ Centralisé, réutilisable | ⚠️ Couche supplémentaire | ✅ **Recommandé** |

---

## 🎯 Conclusion

**Recommandation** : **Option 1 (Application) + Option 5 (API Layer)**

1. **Service Layer** : Logique Time Travel dans le service applicatif
2. **API Layer** : Exposition via REST/GraphQL avec paramètre `asOf` pour Time Travel
3. **Repository Layer** : Accès simple à HCD (sans logique complexe)

**Avantages** :
- ✅ Logique centralisée et testable
- ✅ Réutilisable par tous les clients
- ✅ Cache possible au niveau API
- ✅ Flexibilité maximale pour logique complexe
- ✅ Pas de dépendance aux limitations CQL

**Exemple d'utilisation** :
```bash
# Récupérer l'opération avec Time Travel
GET /api/v1/operations/DEMO_MV/DEMO_001/2024-01-15T10:00:00/1?asOf=2024-01-20T09:00:00

# Réponse :
{
  "operation": { ... },
  "categoryAtDate": "RESTAURANT",
  "source": "CLIENT",
  "queryDate": "2024-01-20T09:00:00"
}
```

